use acter::testing::wait_for;
use acter_core::models::ActerModel;
use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_space;

#[tokio::test]
async fn task_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasks_smoketest").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let task_list_id = {
        let mut draft = space.task_list_draft()?;
        draft.name("Starting up".to_owned());
        draft.send().await?
    };

    let task_list_key = task_list_id.to_string();

    let wait_for_space = space.clone();
    let task_list = wait_for(move || {
        let space = wait_for_space.clone();
        let task_list_key = task_list_key.clone();
        async move {
            let result = space.task_list(task_list_key).await.ok();
            Ok(result)
        }
    })
    .await?
    .expect("freshly created Task List couldn’t be found");

    assert_eq!(task_list.name(), "Starting up");
    assert_eq!(task_list.tasks().await?.len(), 0);

    let task_list_listener = task_list.subscribe();

    let task_1_id = task_list
        .task_builder()?
        .title("Testing 1".into())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_list_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_list = task_list.refresh().await?;
    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);
    assert_eq!(tasks[0].event_id(), task_1_id);

    let task_1 = tasks[0].clone();
    assert_eq!(task_1.title(), "Testing 1");
    assert!(!task_1.is_done());

    let task_list_listener = task_list.subscribe();

    let task_2_id = task_list
        .task_builder()?
        .title("Testing 2".into())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_list_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_list = task_list.refresh().await?;
    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 2);
    assert_eq!(tasks[1].event_id(), task_2_id);

    let task_2 = tasks[1].clone();
    assert_eq!(task_2.title(), "Testing 2");
    assert!(!task_2.is_done());

    let task_1_updater = task_1.subscribe();

    task_1
        .update_builder()?
        .title("Replacement Name".into())
        .mark_done()
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_1_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_1 = task_1.refresh().await?;
    // Update has been applied properly
    assert_eq!(task_1.title(), "Replacement Name");
    assert!(task_1.is_done());

    let task_list_listener = task_list.subscribe();

    task_list
        .update_builder()?
        .name("Setup".into())
        .description_text("All done now".into())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_list_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_list = task_list.refresh().await?;

    assert_eq!(task_list.name(), "Setup");
    let description = task_list.description().expect("description needed");
    assert_eq!(description.body(), "All done now".to_owned());

    Ok(())
}

#[tokio::test]
async fn task_lists_comments_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasklist_comments_smoketest").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let task_list_id = {
        let mut draft = space.task_list_draft()?;
        draft.name("Comments test".to_owned());
        draft.send().await?
    };

    let task_list_key = task_list_id.to_string();

    let wait_for_space = space.clone();
    let task_list = wait_for(move || {
        let space = wait_for_space.clone();
        let task_list_key = task_list_key.clone();
        async move { Ok(space.task_list(task_list_key).await.ok()) }
    })
    .await?
    .expect("freshly created Task List couldn’t be found");

    let comments_manager = task_list.comments().await?;

    assert_eq!(task_list.name(), "Comments test");
    assert_eq!(task_list.tasks().await?.len(), 0);
    assert!(!comments_manager.stats().has_comments());

    // ---- let’s make a comment

    let comments_listener = comments_manager.subscribe();
    let comment_1_id = comments_manager
        .comment_draft()?
        .content_text("I think this is very important".to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    assert_eq!(comments[0].event_id(), comment_1_id);
    assert_eq!(
        comments[0].content().body,
        "I think this is very important".to_owned()
    );

    Ok(())
}

#[tokio::test]
async fn task_comment_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasks_smoketest").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let task_list_id = {
        let mut draft = space.task_list_draft()?;
        draft.name("Starting up".to_owned());
        draft.send().await?
    };

    let task_list_key = task_list_id.to_string();

    let wait_for_space = space.clone();
    let task_list = wait_for(move || {
        let space = wait_for_space.clone();
        let task_list_key = task_list_key.clone();
        async move { Ok(space.task_list(task_list_key).await.ok()) }
    })
    .await?
    .expect("freshly created Task List couldn’t be found");

    assert_eq!(task_list.name(), "Starting up");
    assert_eq!(task_list.tasks().await?.len(), 0);

    let task_list_listener = task_list.subscribe();

    let task_1_id = task_list
        .task_builder()?
        .title("Testing 1".into())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_list_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_list = task_list.refresh().await?;
    let mut tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);
    assert_eq!(tasks[0].event_id(), task_1_id);

    let task = tasks.pop().unwrap();

    // START actual comment on task

    let comments_manager = task.comments().await?;
    assert!(!comments_manager.stats().has_comments());

    // ---- let’s make a comment

    let comments_listener = comments_manager.subscribe();
    let comment_1_id = comments_manager
        .comment_draft()?
        .content_text("I updated the task".to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    assert_eq!(comments[0].event_id(), comment_1_id);
    assert_eq!(comments[0].content().body, "I updated the task".to_owned());

    Ok(())
}
