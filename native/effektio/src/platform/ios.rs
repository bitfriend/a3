use anyhow::Result;
use log::LevelFilter;
use matrix_sdk::ClientBuilder;
use oslog::OsLogger;

use super::native;

pub fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    Ok(native::new_client_config(base_path, home)?.user_agent("effektio-ios"))
}

pub fn init_logging(filter: Option<String>) -> Result<()> {
    // FIXME: not yet supported
    match filter.as_deref() {
        Some("info") => {
            OsLogger::new("effektio-sdk")
                .level_filter(LevelFilter::Info)
                .category_level_filter("Settings", LevelFilter::Trace)
                .init()
                .unwrap();
        }
        Some("debug") => {
            OsLogger::new("effektio-sdk")
                .level_filter(LevelFilter::Debug)
                .category_level_filter("Settings", LevelFilter::Trace)
                .init()
                .unwrap();
        }
        Some("warn") => {
            OsLogger::new("effektio-sdk")
                .level_filter(LevelFilter::Warn)
                .category_level_filter("Settings", LevelFilter::Trace)
                .init()
                .unwrap();
        }
        Some("error") => {
            OsLogger::new("effektio-sdk")
                .level_filter(LevelFilter::Error)
                .category_level_filter("Settings", LevelFilter::Trace)
                .init()
                .unwrap();
        }
        _ => {}
    }
    Ok(())
}
