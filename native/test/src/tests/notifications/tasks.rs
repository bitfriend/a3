use acter::ActerModel;
use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{random_users_with_random_space, random_users_with_random_space_under_template};

const TMPL: &str = r#"
version = "0.1"
name = "Task Notifications Setup Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

[objects.acter-website-tasklist]
type = "task-list"
name = "Onboarding list" 
"#;

#[tokio::test]
async fn tasklist_creation_notification() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, room_id) = random_users_with_random_space("tl_creation_notifications", 2).await?;

    let mut user = users[0].clone();
    let mut second = users[1].clone();

    second.install_default_acter_push_rules().await?;

    let sync_state1 = user.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = second.start_sync();
    sync_state2.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let main_space = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let spaces = client.spaces().await?;
            if spaces.len() != 1 {
                bail!("space not found");
            }
            Ok(spaces.first().cloned().expect("space found"))
        }
    })
    .await?;

    let space_on_second = second.room(main_space.room_id_str()).await?;
    space_on_second
        .set_notification_mode(Some("all".to_owned()))
        .await?; // we want to see push for everything;

    let mut draft = main_space.task_list_draft()?;
    draft.name("Babies first task list".to_owned());
    let event_id = draft.send().await?;
    tracing::trace!("draft sent event id: {}", event_id);

    let notifications = second
        .get_notification_item(room_id.to_string(), event_id.to_string())
        .await?;

    assert_eq!(notifications.push_style(), "creation");
    assert_eq!(notifications.target_url(), format!("/tasks/{event_id}"));
    let parent = notifications.parent().unwrap();
    assert_eq!(parent.object_type_str(), "task-list".to_owned());
    assert_eq!(parent.title().unwrap(), "Babies first task list".to_owned());
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), event_id);

    Ok(())
}

#[tokio::test]
async fn tasklist_title_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventTitleUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let mut update = obj_entry.update_builder()?;
    update.name("Renamed Tasklist".to_owned());
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "titleChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let content = notification_item.body().expect("found content");
    assert_eq!(content.body(), "Onboarding list"); // old title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{}", obj_id,)
    );
    assert_eq!(parent.object_type_str(), "task-list".to_owned());
    assert_eq!(parent.title().unwrap(), "Renamed Tasklist".to_owned());
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn tasklist_desc_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventDescUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let mut update = obj_entry.update_builder()?;
    update.description_text("Added description".to_owned());
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "descriptionChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in event"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let content = notification_item.body().expect("found content");
    assert_eq!(content.body(), "Added description"); // new description
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{}", obj_id,)
    );
    assert_eq!(parent.object_type_str(), "task-list");
    assert_eq!(parent.title().unwrap(), "Onboarding list");
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn tasklist_redaction() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventRedaction", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = first.clone();
    let event = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // we want to see push for everything;
    second_user
        .room(event.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let obj_id = event.event_id_str();
    let space = first.space(event.room_id().to_string()).await?;
    let notification_ev = space.redact(event.event_id(), None, None).await?.event_id;

    let notification_item = second_user
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "redaction");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in redaction"),
        obj_id,
    );

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(notification_item.target_url(), format!("/tasks/"));
    assert_eq!(parent.object_type_str(), "task-list");
    assert_eq!(parent.title().unwrap(), "Onboarding list");
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}
