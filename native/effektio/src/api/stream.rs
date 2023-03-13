use anyhow::{bail, Result};
use eyeball_im::VectorDiff;
use futures::{Stream, StreamExt};
use futures_signals::signal_vec::{SignalVecExt, VecDiff};
use log::info;
use matrix_sdk::{
    room::{
        timeline::{PaginationOptions, Timeline, TimelineItem, VirtualTimelineItem},
        Room,
    },
    ruma::{
        events::{
            relation::Replacement,
            room::message::{MessageType, Relation, RoomMessageEvent, RoomMessageEventContent},
        },
        EventId,
    },
    Client,
};
use std::sync::Arc;

use super::{
    message::{timeline_item_to_message, RoomMessage},
    RUNTIME,
};

pub struct TimelineDiff {
    action: String,
    values: Option<Vec<RoomMessage>>,
    index: Option<usize>,
    value: Option<RoomMessage>,
    new_index: Option<usize>,
    old_index: Option<usize>,
}

impl TimelineDiff {
    pub fn action(&self) -> String {
        self.action.clone()
    }

    pub fn values(&self) -> Option<Vec<RoomMessage>> {
        if self.action == "Replace" {
            self.values.clone()
        } else {
            None
        }
    }

    pub fn index(&self) -> Option<usize> {
        if self.action == "InsertAt" || self.action == "UpdateAt" || self.action == "RemoveAt" {
            self.index
        } else {
            None
        }
    }

    pub fn value(&self) -> Option<RoomMessage> {
        if self.action == "InsertAt" || self.action == "UpdateAt" || self.action == "Push" {
            self.value.clone()
        } else {
            None
        }
    }

    pub fn old_index(&self) -> Option<usize> {
        if self.action == "Move" {
            self.old_index
        } else {
            None
        }
    }

    pub fn new_index(&self) -> Option<usize> {
        if self.action == "Move" {
            self.new_index
        } else {
            None
        }
    }
}

#[derive(Clone)]
pub struct TimelineStream {
    client: Client,
    room: Room,
    timeline: Arc<Timeline>,
}

impl TimelineStream {
    pub fn new(client: Client, room: Room, timeline: Arc<Timeline>) -> Self {
        TimelineStream {
            client,
            room,
            timeline,
        }
    }

    pub async fn diff_rx(&self) -> Result<impl Stream<Item = TimelineDiff>> {
        let timeline = self.timeline.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
                let stream = timeline_stream.map(move |diff| match diff {
                    VectorDiff::Append { values } => TimelineDiff {
                        action: "Append".to_string(),
                        values: Some(
                            values
                                .iter()
                                .map(|x| timeline_item_to_message(x.clone(), room.clone()))
                                .collect(),
                        ),
                        index: None,
                        value: None,
                        new_index: None,
                        old_index: None,
                    },
                    VectorDiff::Insert { index, value } => TimelineDiff {
                        action: "Insert".to_string(),
                        values: None,
                        index: Some(index),
                        value: Some(timeline_item_to_message(value, room.clone())),
                        new_index: None,
                        old_index: None,
                    },
                    VectorDiff::Set { index, value } => TimelineDiff {
                        action: "Set".to_string(),
                        values: None,
                        index: Some(index),
                        value: Some(timeline_item_to_message(value, room.clone())),
                        new_index: None,
                        old_index: None,
                    },
                    VectorDiff::Remove { index } => TimelineDiff {
                        action: "Remove".to_string(),
                        values: None,
                        index: Some(index),
                        value: None,
                        new_index: None,
                        old_index: None,
                    },
                    VectorDiff::PushBack { value } => TimelineDiff {
                        action: "PushBack".to_string(),
                        values: None,
                        index: None,
                        value: Some(timeline_item_to_message(value, room.clone())),
                        new_index: None,
                        old_index: None,
                    },
                    VectorDiff::PushFront { value } => TimelineDiff {
                        action: "PushFront".to_string(),
                        values: None,
                        index: None,
                        value: Some(timeline_item_to_message(value, room.clone())),
                        new_index: None,
                        old_index: None,
                    },
                    VectorDiff::PopBack => TimelineDiff {
                        action: "PopBack".to_string(),
                        values: None,
                        index: None,
                        value: None,
                        old_index: None,
                        new_index: None,
                    },
                    VectorDiff::PopFront => TimelineDiff {
                        action: "PopFront".to_string(),
                        values: None,
                        index: None,
                        value: None,
                        old_index: None,
                        new_index: None,
                    },
                    VectorDiff::Clear => TimelineDiff {
                        action: "Clear".to_string(),
                        values: None,
                        index: None,
                        value: None,
                        old_index: None,
                        new_index: None,
                    },
                    VectorDiff::Reset { values } => TimelineDiff {
                        action: "Reset".to_string(),
                        values: Some(
                            values
                                .iter()
                                .map(|x| timeline_item_to_message(x.clone(), room.clone()))
                                .collect(),
                        ),
                        index: None,
                        value: None,
                        new_index: None,
                        old_index: None,
                    },
                });
                Ok(stream)
            })
            .await?
    }

    pub async fn paginate_backwards(&self, mut count: u16) -> Result<bool> {
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
                timeline
                    .paginate_backwards(PaginationOptions::single_request(count))
                    .await?;

                let mut is_loading_indicator = false;
                if let Some(VectorDiff::Insert { index: 0, value }) = timeline_stream.next().await {
                    if let TimelineItem::Virtual(VirtualTimelineItem::LoadingIndicator) =
                        value.as_ref()
                    {
                        is_loading_indicator = true;
                    }
                }
                if !is_loading_indicator {
                    return Ok(true);
                }

                let mut is_timeline_start = false;
                if let Some(VectorDiff::Set { index: 0, value }) = timeline_stream.next().await {
                    if let TimelineItem::Virtual(VirtualTimelineItem::TimelineStart) =
                        value.as_ref()
                    {
                        is_timeline_start = true;
                    }
                }
                if !is_timeline_start {
                    return Ok(true);
                }

                Ok(false)
            })
            .await?
    }

    pub async fn next(&self) -> Result<RoomMessage> {
        let timeline = self.timeline.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
                loop {
                    if let Some(diff) = timeline_stream.next().await {
                        match (diff) {
                            VectorDiff::Append { values } => {
                                info!("stream forward timeline append");
                            }
                            VectorDiff::Insert { index, value } => {
                                info!("stream forward timeline insert");
                            }
                            VectorDiff::Set { index, value } => {
                                info!("stream forward timeline set");
                            }
                            VectorDiff::Reset { values } => {
                                info!("stream forward timeline reset");
                            }
                            VectorDiff::Remove { index } => {
                                info!("stream forward timeline remove");
                            }
                            VectorDiff::PushBack { value } => {
                                info!("stream forward timeline push_back");
                                let inner = timeline_item_to_message(value, room.clone());
                                return Ok(inner);
                            }
                            VectorDiff::PushFront { value } => {
                                info!("stream forward timeline push_front");
                                let inner = timeline_item_to_message(value, room.clone());
                                return Ok(inner);
                            }
                            VectorDiff::PopBack => {
                                info!("stream forward timeline pop_back");
                            }
                            VectorDiff::PopFront => {
                                info!("stream forward timeline pop_front");
                            }
                            VectorDiff::Clear => {
                                info!("stream forward timeline clear");
                            }
                            VectorDiff::Reset { values } => {
                                info!("stream forward timeline reset");
                            }
                        }
                    }
                }
            })
            .await?
    }

    pub async fn edit(
        &self,
        new_msg: String,
        original_event_id: String,
        txn_id: Option<String>,
    ) -> Result<bool> {
        let room = if let Room::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message from a room we are not in")
        };
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(original_event_id)?;
        let client = self.client.clone();

        RUNTIME
            .spawn(async move {
                let timeline_event = room.event(&event_id).await.expect("Couldn't find event.");
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .expect("Couldn't deserialise event");

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    info!("Can't edit an event not sent by own user");
                    return Ok(false);
                }

                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::text_markdown(new_msg.to_string()),
                );
                let mut edited_content = RoomMessageEventContent::text_markdown(new_msg);
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline
                    .send(edited_content.into(), txn_id.as_deref().map(Into::into))
                    .await;
                Ok(true)
            })
            .await?
    }
}
