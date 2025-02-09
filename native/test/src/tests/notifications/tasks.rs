use acter::{ActerModel, UtcDateTime};
use anyhow::{bail, Result};
use chrono::{NaiveTime, Utc};
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

[objects.start_list]
type = "task-list"
name = "Onboarding list"

[objects.task_1]
type = "task"
title = "Scroll through the updates"
"m.relates_to" = { event_id = "{{ start_list.id }}" }
utc_due = "{{ now().as_rfc3339 }}"
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

    assert_eq!(notification_item.title(), "Renamed Tasklist"); // old title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{}", obj_id,)
    );
    assert_eq!(parent.object_type_str(), "task-list".to_owned());
    // assert_eq!(parent.title().unwrap(), "Renamed Tasklist".to_owned());
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn tasklist_desc_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("tasklistDescUpdate", 2, TMPL).await?;

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

#[ignore]
#[tokio::test]
async fn tasklist_redaction() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("tasklistRedaction", 2, TMPL).await?;

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

#[tokio::test]
async fn task_created() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskCreated", 2, TMPL).await?;

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

    let mut task = obj_entry.task_builder().unwrap();
    task.due_date(2025, 11, 13);
    task.title("Baby's first task".to_owned());

    let notification_ev = task.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskAdd");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    assert_eq!(notification_item.title(), "Baby's first task"); // old title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{}/{}", obj_id, notification_ev)
    );
    assert_eq!(parent.object_type_str(), "task-list".to_owned());
    assert_eq!(parent.title().unwrap(), "Onboarding list".to_owned());
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_title_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskTitleUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            let tasks = entries[0].tasks().await?;
            let Some(task) = tasks.first() else {
                bail!("task not found");
            };
            Ok((entries[0].event_id_str(), task.clone()))
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
    update.title("Renamed Task".to_owned());
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

    assert_eq!(notification_item.title(), "Renamed Task"); // old title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.object_type_str(), "task");
    // assert_eq!(parent.title().unwrap(), "Onboarding List");
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_desc_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskDescUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            let tasks = entries[0].tasks().await?;
            let Some(task) = tasks.first() else {
                bail!("task not found");
            };
            Ok((entries[0].event_id_str(), task.clone()))
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
    update.description_text("Task is complicated".to_owned());
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "descriptionChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let content = notification_item.body().expect("found content");
    assert_eq!(content.body(), "Task is complicated"); // new description
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.object_type_str(), "task".to_owned());
    assert_eq!(
        parent.title().unwrap(),
        "Scroll through the updates".to_owned()
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_due_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("tasDueUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            let tasks = entries[0].tasks().await?;
            let Some(task) = tasks.first() else {
                bail!("task not found");
            };
            Ok((entries[0].event_id_str(), task.clone()))
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
    update.due_date(2026, 1, 1);
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskDueDateChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    assert_eq!(
        notification_item.new_date(),
        chrono::NaiveDate::from_ymd_opt(2026, 1, 1).map(|d| {
            UtcDateTime::from_naive_utc_and_offset(
                d.and_time(NaiveTime::from_hms_opt(0, 0, 0).unwrap()),
                Utc,
            )
        })
    );
    assert_eq!(notification_item.title(), "2026-01-01");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.object_type_str(), "task".to_owned());
    assert_eq!(
        parent.title().unwrap(),
        "Scroll through the updates".to_owned()
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_done_and_undone() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskDoneUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            let tasks = entries[0].tasks().await?;
            let Some(task) = tasks.first() else {
                bail!("task not found");
            };
            Ok((entries[0].event_id_str(), task.clone()))
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
    update.mark_done();
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskComplete");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.object_type_str(), "task".to_owned());
    assert_eq!(
        parent.title().unwrap(),
        "Scroll through the updates".to_owned()
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    // and undone

    let mut update = obj_entry.update_builder()?;
    update.mark_undone();
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskReOpen");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.object_type_str(), "task".to_owned());
    assert_eq!(
        parent.title().unwrap(),
        "Scroll through the updates".to_owned()
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}
