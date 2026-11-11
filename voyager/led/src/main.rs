//! voyager-led: set ZSA Voyager LEDs over raw HID, speaking the Oryx protocol directly.
//!
//! Usage:
//!   voyager-led ping                    exit 0 if the keyboard answers
//!   voyager-led set 3=00e6f5 4=000000   set LEDs by index (rrggbb; black = transparent
//!                                       on the overlay firmware)
//!   voyager-led restore                 hand every LED back to the firmware

use hidapi::{HidApi, HidDevice};
use std::process::ExitCode;

const ZSA_VENDOR: u16 = 0x3297;
const VOYAGER_PRODUCT: u16 = 0x1977;
const RAW_USAGE_PAGE: u16 = 0xFF60;
const RAW_USAGE: u16 = 0x61;
const REPORT_SIZE: usize = 32;
const LED_COUNT: u8 = 52;

const CMD_RGB_CONTROL: u8 = 5;
const CMD_SET_RGB_LED: u8 = 6;
const CMD_GET_PROTOCOL_VERSION: u8 = 0xFE;
const EVT_GET_PROTOCOL_VERSION: u8 = 0xFE;

/// Index of one LED on the board, in Oryx key order.
struct Led(u8);

/// An RGB color as sent to the firmware.
struct Color {
    r: u8,
    g: u8,
    b: u8,
}

/// One `led=rrggbb` assignment from the command line.
struct Assignment {
    led: Led,
    color: Color,
}

/// What the user asked for.
enum Command {
    Ping,
    Set(Vec<Assignment>),
    Restore,
}

fn parse_assignment(arg: &str) -> Result<Assignment, String> {
    let Some((led, color)) = arg.split_once('=') else {
        return Err(format!("expected led=rrggbb, got {arg}"));
    };
    let Ok(led) = led.parse::<u8>() else {
        return Err(format!("bad LED index: {led}"));
    };
    if led >= LED_COUNT {
        return Err(format!("LED index out of range (0-{}): {led}", LED_COUNT - 1));
    }
    if color.len() != 6 || !color.is_ascii() {
        return Err(format!("bad color (want rrggbb): {color}"));
    }
    let Ok(r) = u8::from_str_radix(&color[0..2], 16) else {
        return Err(format!("bad color (want rrggbb): {color}"));
    };
    let Ok(g) = u8::from_str_radix(&color[2..4], 16) else {
        return Err(format!("bad color (want rrggbb): {color}"));
    };
    let Ok(b) = u8::from_str_radix(&color[4..6], 16) else {
        return Err(format!("bad color (want rrggbb): {color}"));
    };
    Ok(Assignment {
        led: Led(led),
        color: Color { r, g, b },
    })
}

fn parse_args(args: &[String]) -> Result<Command, String> {
    let usage = "usage: voyager-led ping | set LED=rrggbb... | restore";
    let Some(verb) = args.first() else {
        return Err(usage.to_string());
    };
    if verb == "ping" {
        return Ok(Command::Ping);
    }
    if verb == "restore" {
        return Ok(Command::Restore);
    }
    if verb == "set" {
        let mut assignments = Vec::new();
        for arg in &args[1..] {
            assignments.push(parse_assignment(arg)?);
        }
        if assignments.is_empty() {
            return Err(usage.to_string());
        }
        return Ok(Command::Set(assignments));
    }
    Err(usage.to_string())
}

fn open_keyboard() -> Result<HidDevice, String> {
    let Ok(api) = HidApi::new() else {
        return Err("could not start HID".to_string());
    };
    for info in api.device_list() {
        if info.vendor_id() != ZSA_VENDOR || info.product_id() != VOYAGER_PRODUCT {
            continue;
        }
        if info.usage_page() != RAW_USAGE_PAGE || info.usage() != RAW_USAGE {
            continue;
        }
        let Ok(device) = info.open_device(&api) else {
            return Err("found the keyboard but could not open it (Input Monitoring permission?)".to_string());
        };
        return Ok(device);
    }
    Err("no Voyager found".to_string())
}

fn send(device: &HidDevice, payload: &[u8]) -> Result<(), String> {
    let mut report = [0u8; REPORT_SIZE + 1];
    report[1..=payload.len()].copy_from_slice(payload);
    let Ok(_) = device.write(&report) else {
        return Err("write to the keyboard failed".to_string());
    };
    Ok(())
}

fn ping(device: &HidDevice) -> Result<(), String> {
    send(device, &[CMD_GET_PROTOCOL_VERSION])?;
    let mut reply = [0u8; REPORT_SIZE];
    for _ in 0..20 {
        let Ok(read) = device.read_timeout(&mut reply, 100) else {
            return Err("read from the keyboard failed".to_string());
        };
        if read >= 2 && reply[0] == EVT_GET_PROTOCOL_VERSION {
            println!("voyager ok, oryx protocol {}", reply[1]);
            return Ok(());
        }
    }
    Err("the keyboard did not answer".to_string())
}

fn run(command: Command) -> Result<(), String> {
    let device = open_keyboard()?;
    match command {
        Command::Ping => ping(&device),
        Command::Restore => send(&device, &[CMD_RGB_CONTROL, 0]),
        Command::Set(assignments) => {
            for assignment in assignments {
                let Assignment { led, color } = assignment;
                let Led(index) = led;
                let Color { r, g, b } = color;
                send(&device, &[CMD_SET_RGB_LED, index, r, g, b])?;
            }
            Ok(())
        }
    }
}

fn main() -> ExitCode {
    let mut args = Vec::new();
    for arg in std::env::args_os().skip(1) {
        let Ok(arg) = arg.into_string() else {
            eprintln!("voyager-led: arguments must be plain text");
            return ExitCode::from(2);
        };
        args.push(arg);
    }
    let command = match parse_args(&args) {
        Ok(command) => command,
        Err(message) => {
            eprintln!("{message}");
            return ExitCode::from(2);
        }
    };
    match run(command) {
        Ok(()) => ExitCode::SUCCESS,
        Err(message) => {
            eprintln!("voyager-led: {message}");
            ExitCode::FAILURE
        }
    }
}
