use super::native;
use anyhow::Result;
use log::LevelFilter;
use matrix_sdk::ClientBuilder;
use oslog::OsLogger;
use sanitize_filename_reader_friendly::sanitize;
use std::{fs, path};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::{fmt::format::FmtSpan, EnvFilter};

pub fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    Ok(native::new_client_config(base_path, home)?.user_agent("effektio-ios"))
}

pub fn init_logging(filter: Option<String>) -> Result<()> {
    // FIXME: not yet supported
    OsLogger::new("effektio-sdk")
        .level_filter(LevelFilter::Debug)
        .category_level_filter("Settings", LevelFilter::Trace)
        .init()
        .unwrap();
    Ok(())
}
