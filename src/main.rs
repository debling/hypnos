use std::{collections::HashMap, ffi::CString, ptr, sync::mpsc, thread, time};

use x11::xlib;

use chrono;
use chrono::Timelike;

use alsa;
use alsa::poll::Descriptors;

pub mod render;

pub struct XDisplay(pub *mut xlib::Display);

impl XDisplay {
    pub fn open() -> Option<Self> {
        let display = unsafe { xlib::XOpenDisplay(ptr::null()) };
        if display.is_null() {
            return None;
        }
        Some(Self(display))
    }

    fn root_window(&self) -> xlib::Window {
        unsafe { xlib::XDefaultRootWindow(self.0) }
    }

    pub fn store_root_name(&self, s: String) -> () {
        unsafe {
            xlib::XStoreName(
                self.0,
                self.root_window(),
                CString::new(s).expect("CString::new failed").into_raw(),
            );
            xlib::XSync(self.0, false as i32);
        }
    }
}

impl Drop for XDisplay {
    fn drop(&mut self) {
        unsafe { xlib::XCloseDisplay(self.0) };
    }
}

fn datetime_module(cb: impl Fn(String)) -> () {
    loop {
        let now = chrono::Local::now();
        cb(format!("{}", now.format("%H:%M %d/%m/%Y")));
        println!("date updated");

        let sleep_duration = 60 - now.time().second();
        thread::sleep(time::Duration::from_secs(sleep_duration.into()));
    }
}

fn audio_module(cb: impl Fn(String)) -> () {
    let mixer = alsa::mixer::Mixer::new("default", true)
        .expect("Error open openning mixer `default`");
    let selem = mixer
        .find_selem(&alsa::mixer::SelemId::new("Master", 0))
        .expect("Can't find `Master` in mixer");
    let cap = mixer
        .find_selem(&alsa::mixer::SelemId::new("Capture", 0))
        .expect("Can't find `Capture` in mixer");

    let (_, max) = selem.get_playback_volume_range();

    let mut res = mixer
        .get()
        .expect("Error geting pollfds for mixer `default`");
    assert_eq!(res.len(), 1, "Multiple pollfds for mixer `default`");
    let fd = &mut res[0];
    loop {
        let mic_muted = cap
            .get_capture_switch(alsa::mixer::SelemChannelId::mono())
            .map_or("ERR", |x| if x == 1 { "ON" } else { "OFF" });
        let vol = selem
            .get_playback_volume(alsa::mixer::SelemChannelId::mono())
            .map_or("ERR".into(), |x| (100 * x / max).to_string());

        cb(format!("Vol: {} | Mic: [{}]", vol, mic_muted));
        println!("audio updated");

        unsafe { libc::poll(fd, 1, -1); }
        let _ = mixer.handle_events();
    }
}

struct ModuleMessage {
    module_name: String,
    val: String,
}

fn make_cbfn(name: String, sender: mpsc::Sender<ModuleMessage>) -> impl Fn(String) -> () {
    move |x| {
        sender.send(ModuleMessage {
            module_name: name.clone(),
            val: x,
        }).unwrap()
    }
}

fn main() {
    let display = XDisplay::open().expect("Errror openning Xorg display");

    let (sender, receiver) = mpsc::channel();

    let audio_tx = sender.clone();
    thread::spawn(move || audio_module(make_cbfn(String::from("audio"), audio_tx)));

    let date_tx = sender.clone();
    thread::spawn(move || datetime_module(make_cbfn(String::from("date"), date_tx)));

    let mut states = HashMap::new();

    let loading_str = String::from("loading");

    for ModuleMessage { module_name, val } in receiver {
        states.insert(module_name, val);
        display.store_root_name(format!(
            " {} | {} ",
            states.get(&String::from("audio")).unwrap_or(&loading_str),
            states.get(&String::from("date")).unwrap_or(&loading_str)
        ));
    }
}
