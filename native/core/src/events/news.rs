use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk::ruma::events::{
    macros::EventContent,
    room::message::{
        AudioMessageEventContent, FileMessageEventContent, ImageMessageEventContent,
        TextMessageEventContent, VideoMessageEventContent,
    },
};
use serde::{Deserialize, Serialize};

use super::{Colorize, ObjRef, Update};
use crate::util::deserialize_some;

// if you change the order of these enum variables, enum value will change and parsing of old content will fail
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum NewsContent {
    /// An image message.
    Image(ImageMessageEventContent),
    /// A text message.
    Text(TextMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
    /// An audio message.
    Audio(AudioMessageEventContent),
    /// A file message.
    File(FileMessageEventContent),
}

impl NewsContent {
    pub fn type_str(&self) -> String {
        match self {
            NewsContent::Audio(_) => "audio".to_owned(),
            NewsContent::File(_) => "file".to_owned(),
            NewsContent::Image(_) => "image".to_owned(),
            NewsContent::Text(_) => "text".to_owned(),
            NewsContent::Video(_) => "video".to_owned(),
        }
    }

    pub fn audio(&self) -> Option<AudioMessageEventContent> {
        match self {
            NewsContent::Audio(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn file(&self) -> Option<FileMessageEventContent> {
        match self {
            NewsContent::File(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        match self {
            NewsContent::Image(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn text(&self) -> Option<TextMessageEventContent> {
        match self {
            NewsContent::Text(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        match self {
            NewsContent::Video(content) => Some(content.clone()),
            _ => None,
        }
    }
}

/// A news slide represents one full-sized slide of news
#[derive(Clone, Debug, Builder, Deserialize, Getters, Serialize)]
pub struct NewsSlide {
    /// A slide must contain some news-worthy content
    #[serde(flatten)]
    content: NewsContent,

    /// A slide may optionally contain references to other items
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    references: Vec<ObjRef>,
}

/// The payload for our news creation event.
#[derive(Clone, Debug, Builder, Deserialize, Serialize, Getters, EventContent)]
#[ruma_event(type = "global.acter.dev.news", kind = MessageLike)]
#[builder(name = "NewsEntryBuilder", derive(Debug))]
pub struct NewsEntryEventContent {
    /// A news entry may have one or more slides of news
    /// which are scrolled through horizontally
    slides: Vec<NewsSlide>,

    /// You can define custom background and foreground colors
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    colors: Option<Colorize>,
}

/// The payload for our news update event.
#[derive(Clone, Debug, Builder, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "global.acter.dev.news.update", kind = MessageLike)]
#[builder(name = "NewsEntryUpdateBuilder", derive(Debug))]
pub struct NewsEntryUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub news_entry: Update,

    /// A news entry may have one or more slides of news
    /// which are scrolled through horizontally
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub slides: Option<Vec<NewsSlide>>,

    /// You can define custom background and foreground colors
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub colors: Option<Option<Colorize>>,
}

impl NewsEntryUpdateEventContent {
    pub fn apply(&self, task: &mut NewsEntryEventContent) -> crate::Result<bool> {
        let mut updated = false;
        if let Some(slides) = &self.slides {
            task.slides = slides.clone();
            updated = true;
        }
        if let Some(colors) = &self.colors {
            task.colors = colors.clone();
            updated = true;
        }
        Ok(updated)
    }
}
