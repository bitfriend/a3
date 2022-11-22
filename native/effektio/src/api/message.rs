use log::info;
use matrix_sdk::{
    deserialized_responses::{SyncTimelineEvent, TimelineEvent},
    room::{
        timeline::{EventTimelineItem, TimelineItem, TimelineItemContent},
        Room,
    },
    ruma::events::{
        room::{
            encrypted::OriginalSyncRoomEncryptedEvent,
            message::{MessageFormat, MessageType, Relation, RoomMessageEventContent},
        },
        AnySyncMessageLikeEvent, AnySyncTimelineEvent, OriginalSyncMessageLikeEvent,
        SyncMessageLikeEvent,
    },
};
use regex::Regex;
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct RoomMessage {
    event_id: String,
    room_id: String,
    sender: String,
    origin_server_ts: Option<u64>,
    content: Option<RoomMessageContent>,
}

impl RoomMessage {
    #[allow(clippy::too_many_arguments)]
    fn new(
        event_id: String,
        room_id: String,
        sender: String,
        origin_server_ts: Option<u64>,
        content: Option<RoomMessageContent>,
    ) -> Self {
        RoomMessage {
            event_id,
            room_id,
            sender,
            origin_server_ts,
            content,
        }
    }

    pub(crate) fn from_original(
        event: &OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
        room: Room,
    ) -> Self {
        let mut fallback = event.content.body().to_string();
        let mut formatted_body: Option<String> = None;
        if let MessageType::Text(content) = &event.content.msgtype {
            if let Some(formatted) = &content.formatted {
                if formatted.format == MessageFormat::Html {
                    formatted_body = Some(formatted.body.clone());
                }
            }
        }
        let mut image_description: Option<ImageDescription> = None;
        if let MessageType::Image(content) = &event.content.msgtype {
            if let Some(info) = content.info.as_ref() {
                image_description = Some(ImageDescription {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                    width: info.width.map(u64::from),
                    height: info.height.map(u64::from),
                });
            }
        }
        let mut file_description: Option<FileDescription> = None;
        if let MessageType::File(content) = &event.content.msgtype {
            if let Some(info) = content.info.as_ref() {
                file_description = Some(FileDescription {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                });
            }
        }
        let replying = matches!(
            &event.content.relates_to,
            Some(Relation::Reply { in_reply_to }),
        );
        RoomMessage::new(
            event.event_id.to_string(),
            room.room_id().to_string(),
            event.sender.to_string(),
            Some(event.origin_server_ts.get().into()),
            Some(RoomMessageContent {
                msgtype: event.content.msgtype().to_string(),
                body: fallback,
                formatted_body,
                image_description,
                file_description,
                replying,
            }),
        )
    }

    pub(crate) fn from_timeline_event(
        event: &OriginalSyncRoomEncryptedEvent,
        decrypted: &TimelineEvent,
        room: Room,
    ) -> Self {
        let mut formatted_body: Option<String> = None;
        info!("sync room encrypted: {:?}", decrypted.event.deserialize());
        // if let MessageType::Text(content) = decrypted.event.deserialize() {
        //     if let Some(formatted) = &content.formatted {
        //         if formatted.format == MessageFormat::Html {
        //             formatted_body = Some(formatted.body.clone());
        //         }
        //     }
        // }
        RoomMessage::new(
            event.event_id.to_string(),
            room.room_id().to_string(),
            event.sender.to_string(),
            Some(event.origin_server_ts.get().into()),
            Some(RoomMessageContent {
                msgtype: "m.room.encrypted".to_string(),
                body: "OriginalSyncRoomEncryptedEvent".to_string(),
                formatted_body,
                image_description: None,
                file_description: None,
                replying: false,
            }),
        )
    }

    pub(crate) fn from_timeline_item(event: &EventTimelineItem, room: Room) -> Self {
        let event_id = match event.event_id() {
            Some(id) => id.to_string(),
            None => format!("{:?}", event.key()),
        };
        let room_id = room.room_id().to_string();
        let sender = event.sender().to_string();
        let origin_server_ts: Option<u64> = event.origin_server_ts().map(|x| x.get().into());
        match event.content() {
            TimelineItemContent::Message(msg) => {
                let msgtype = msg.msgtype();
                let mut fallback = match &msgtype {
                    MessageType::Audio(audio) => audio.body.clone(),
                    MessageType::Emote(emote) => emote.body.clone(),
                    MessageType::File(file) => file.body.clone(),
                    MessageType::Image(image) => image.body.clone(),
                    MessageType::Location(location) => location.body.clone(),
                    MessageType::Notice(notice) => notice.body.clone(),
                    MessageType::ServerNotice(service_notice) => service_notice.body.clone(),
                    MessageType::Text(text) => text.body.clone(),
                    MessageType::Video(video) => video.body.clone(),
                    _ => "Unknown timeline item".to_string(),
                };
                info!("timeline fallback: {:?}", fallback);
                let mut formatted_body: Option<String> = None;
                let mut image_description: Option<ImageDescription> = None;
                let mut file_description: Option<FileDescription> = None;
                if let MessageType::Text(content) = msgtype {
                    if let Some(formatted) = &content.formatted {
                        if formatted.format == MessageFormat::Html {
                            formatted_body = Some(formatted.body.clone());
                        }
                    }
                }
                if let MessageType::Image(content) = msgtype {
                    if let Some(info) = content.info.as_ref() {
                        image_description = Some(ImageDescription {
                            name: content.body.clone(),
                            mimetype: info.mimetype.clone(),
                            size: info.size.map(u64::from),
                            width: info.width.map(u64::from),
                            height: info.height.map(u64::from),
                        });
                    }
                }
                if let MessageType::File(content) = msgtype {
                    if let Some(info) = content.info.as_ref() {
                        file_description = Some(FileDescription {
                            name: content.body.clone(),
                            mimetype: info.mimetype.clone(),
                            size: info.size.map(u64::from),
                        });
                    }
                }
                let replying = match msg.in_reply_to() {
                    Some(in_reply_to) => true,
                    None => false,
                };
                return RoomMessage::new(
                    event_id,
                    room_id,
                    sender,
                    origin_server_ts,
                    Some(RoomMessageContent {
                        msgtype: msgtype.msgtype().to_string(),
                        body: fallback,
                        formatted_body,
                        image_description,
                        file_description,
                        replying,
                    }),
                );
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message, discarding");
            }
        }
        RoomMessage::new(
            event_id,
            room_id,
            sender,
            origin_server_ts,
            None,
        )
    }

    pub fn event_id(&self) -> String {
        self.event_id.clone()
    }

    pub fn room_id(&self) -> String {
        self.room_id.clone()
    }

    pub fn sender(&self) -> String {
        self.sender.clone()
    }

    pub fn origin_server_ts(&self) -> Option<u64> {
        self.origin_server_ts
    }

    pub fn undecrypted(&self) -> bool {
        self.content.is_none()
    }

    pub fn msgtype(&self) -> Option<String> {
        if let Some(content) = &self.content {
            return Some(content.msgtype.clone());
        }
        None
    }

    pub fn body(&self) -> Option<String> {
        if let Some(content) = &self.content {
            return Some(content.body.clone());
        }
        None
    }

    pub fn formatted_body(&self) -> Option<String> {
        if let Some(content) = &self.content {
            return content.formatted_body.clone();
        }
        None
    }

    pub fn image_description(&self) -> Option<ImageDescription> {
        if let Some(content) = &self.content {
            return content.image_description.clone();
        }
        None
    }

    pub fn file_description(&self) -> Option<FileDescription> {
        if let Some(content) = &self.content {
            return content.file_description.clone();
        }
        None
    }

    pub(crate) fn replying(&self) -> Option<bool> {
        if let Some(content) = &self.content {
            return Some(content.replying);
        }
        None
    }

    pub(crate) fn simplify_body(&mut self) {
        if let Some(content) = &mut self.content {
            if let Some(text) = &content.formatted_body {
                let re = Regex::new(r"^<mx-reply>[\s\S]+</mx-reply> ").unwrap();
                let text = re.replace(text.as_str(), "").to_string();
                content.set_body(text);
                info!("regex replaced");
            }
        }
    }
}

#[derive(Clone, Debug)]
pub(crate) struct RoomMessageContent {
    pub msgtype: String,
    pub body: String,
    pub formatted_body: Option<String>,
    pub image_description: Option<ImageDescription>,
    pub file_description: Option<FileDescription>,
    pub replying: bool,
}

impl RoomMessageContent {
    pub fn set_body(&mut self, text: String) {
        self.body = text;
    }
}

#[derive(Clone, Debug)]
pub struct ImageDescription {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
    width: Option<u64>,
    height: Option<u64>,
}

impl ImageDescription {
    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.size
    }

    pub fn width(&self) -> Option<u64> {
        self.width
    }

    pub fn height(&self) -> Option<u64> {
        self.height
    }
}

#[derive(Clone, Debug)]
pub struct FileDescription {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
}

impl FileDescription {
    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.size
    }
}

pub(crate) fn sync_event_to_message(ev: SyncTimelineEvent, room: Room) -> Option<RoomMessage> {
    info!("sync event to message: {:?}", ev);
    if let Ok(AnySyncTimelineEvent::MessageLike(evt)) = ev.event.deserialize() {
        match evt {
            AnySyncMessageLikeEvent::RoomEncrypted(SyncMessageLikeEvent::Original(m)) => {}
            AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(m)) => {
                return Some(RoomMessage::from_original(&m, room));
            }
            _ => {}
        }
    }
    None
}

pub(crate) fn timeline_item_to_message(item: Arc<TimelineItem>, room: Room) -> Option<RoomMessage> {
    if let Some(event) = item.as_event() {
        return Some(RoomMessage::from_timeline_item(event, room));
    }
    None
}
