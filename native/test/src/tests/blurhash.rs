use acter::api::RoomMessage;
use anyhow::{Context, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use std::io::Write;
use tempfile::NamedTempFile;
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn image_blurhash_support() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("image_blurhash").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let bytes = include_bytes!("./fixtures/kingfisher.jpg");
    let mut tmp_jpg = NamedTempFile::new()?;
    tmp_jpg.as_file_mut().write_all(bytes)?;
    let jpg_name = tmp_jpg // it is randomly generated by system and not kingfisher.jpg
        .path()
        .file_name()
        .expect("it is not file")
        .to_string_lossy()
        .to_string();

    let draft = user
        .image_draft(
            tmp_jpg.path().to_string_lossy().to_string(),
            "image/jpeg".to_string(),
        )
        .blurhash("KingFisher".to_owned());
    timeline.send_message(Box::new(draft)).await?;

    // image msg may reach via pushback action or reset action
    let mut i = 30;
    let mut blurhash = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(bhash) = match_media_msg(&value, "image/jpeg", &jpg_name) {
                        blurhash = Some(bhash);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(bhash) = match_media_msg(value, "image/jpeg", &jpg_name) {
                            blurhash = Some(bhash);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if blurhash.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let blurhash = blurhash.context("Even after 30 seconds, image msg not received")?;
    assert_eq!(
        blurhash,
        Some("KingFisher".to_owned()),
        "image blurhash not available",
    );

    Ok(())
}

#[tokio::test]
async fn video_blurhash_support() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("video_blurhash").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let bytes = include_bytes!("./fixtures/big_buck_bunny.mp4");
    let mut tmp_mp4 = NamedTempFile::new()?;
    tmp_mp4.as_file_mut().write_all(bytes)?;
    let mp4_name = tmp_mp4 // it is randomly generated by system and not big_buck_bunny.mp4
        .path()
        .file_name()
        .expect("it is not file")
        .to_string_lossy()
        .to_string();

    let draft = user
        .image_draft(
            tmp_mp4.path().to_string_lossy().to_string(),
            "video/mp4".to_string(),
        )
        .blurhash("Big Buck Bunny".to_owned());
    timeline.send_message(Box::new(draft)).await?;

    // image msg may reach via pushback action or reset action
    let mut i = 30;
    let mut blurhash = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(bhash) = match_media_msg(&value, "video/mp4", &mp4_name) {
                        blurhash = Some(bhash);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(bhash) = match_media_msg(value, "video/mp4", &mp4_name) {
                            blurhash = Some(bhash);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if blurhash.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let blurhash = blurhash.context("Even after 30 seconds, image msg not received")?;
    assert_eq!(
        blurhash,
        Some("Big Buck Bunny".to_owned()),
        "video blurhash not available",
    );

    Ok(())
}

fn match_media_msg(msg: &RoomMessage, content_type: &str, body: &str) -> Option<Option<String>> {
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if let Some(mimetype) = msg_content.mimetype() {
                if mimetype == content_type && msg_content.body() == body {
                    // exclude the pending msg
                    if event_item.event_id().is_some() {
                        return Some(msg_content.blurhash());
                    }
                }
            }
        }
    }
    None
}
