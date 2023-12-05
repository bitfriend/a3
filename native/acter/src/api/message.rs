use chrono::{DateTime, Utc};
use core::time::Duration;
use matrix_sdk::{deserialized_responses::SyncTimelineEvent, room::Room};
use matrix_sdk_ui::timeline::{
    EventSendState as SdkEventSendState, EventTimelineItem, MembershipChange, TimelineItem,
    TimelineItemContent, TimelineItemKind, VirtualTimelineItem,
};
use ruma_common::{serde::Raw, OwnedEventId, OwnedRoomId, OwnedTransactionId, OwnedUserId};
use ruma_events::{
    call::{
        answer::{OriginalCallAnswerEvent, OriginalSyncCallAnswerEvent},
        candidates::{OriginalCallCandidatesEvent, OriginalSyncCallCandidatesEvent},
        hangup::{OriginalCallHangupEvent, OriginalSyncCallHangupEvent},
        invite::{OriginalCallInviteEvent, OriginalSyncCallInviteEvent},
    },
    key::verification::{
        accept::{
            AcceptMethod, OriginalKeyVerificationAcceptEvent,
            OriginalSyncKeyVerificationAcceptEvent,
        },
        cancel::{OriginalKeyVerificationCancelEvent, OriginalSyncKeyVerificationCancelEvent},
        done::{OriginalKeyVerificationDoneEvent, OriginalSyncKeyVerificationDoneEvent},
        key::{OriginalKeyVerificationKeyEvent, OriginalSyncKeyVerificationKeyEvent},
        mac::{OriginalKeyVerificationMacEvent, OriginalSyncKeyVerificationMacEvent},
        ready::{OriginalKeyVerificationReadyEvent, OriginalSyncKeyVerificationReadyEvent},
        start::{
            OriginalKeyVerificationStartEvent, OriginalSyncKeyVerificationStartEvent, StartMethod,
        },
        VerificationMethod,
    },
    policy::rule::{
        room::{OriginalPolicyRuleRoomEvent, OriginalSyncPolicyRuleRoomEvent},
        server::{OriginalPolicyRuleServerEvent, OriginalSyncPolicyRuleServerEvent},
        user::{OriginalPolicyRuleUserEvent, OriginalSyncPolicyRuleUserEvent},
    },
    reaction::{OriginalReactionEvent, OriginalSyncReactionEvent},
    receipt::Receipt,
    room::{
        aliases::{OriginalRoomAliasesEvent, OriginalSyncRoomAliasesEvent},
        avatar::{OriginalRoomAvatarEvent, OriginalSyncRoomAvatarEvent},
        canonical_alias::{OriginalRoomCanonicalAliasEvent, OriginalSyncRoomCanonicalAliasEvent},
        create::{OriginalRoomCreateEvent, OriginalSyncRoomCreateEvent},
        encrypted::{
            EncryptedEventScheme, OriginalRoomEncryptedEvent, OriginalSyncRoomEncryptedEvent,
        },
        encryption::{OriginalRoomEncryptionEvent, OriginalSyncRoomEncryptionEvent},
        guest_access::{OriginalRoomGuestAccessEvent, OriginalSyncRoomGuestAccessEvent},
        history_visibility::{
            OriginalRoomHistoryVisibilityEvent, OriginalSyncRoomHistoryVisibilityEvent,
        },
        join_rules::{OriginalRoomJoinRulesEvent, OriginalSyncRoomJoinRulesEvent},
        member::{MembershipState, OriginalRoomMemberEvent, OriginalSyncRoomMemberEvent},
        message::{
            AudioInfo, FileInfo, MessageFormat, MessageType, OriginalRoomMessageEvent,
            OriginalSyncRoomMessageEvent, Relation, VideoInfo,
        },
        name::{OriginalRoomNameEvent, OriginalSyncRoomNameEvent},
        pinned_events::{OriginalRoomPinnedEventsEvent, OriginalSyncRoomPinnedEventsEvent},
        power_levels::{OriginalRoomPowerLevelsEvent, OriginalSyncRoomPowerLevelsEvent},
        redaction::{RoomRedactionEvent, SyncRoomRedactionEvent},
        server_acl::{OriginalRoomServerAclEvent, OriginalSyncRoomServerAclEvent},
        third_party_invite::{
            OriginalRoomThirdPartyInviteEvent, OriginalSyncRoomThirdPartyInviteEvent,
        },
        tombstone::{OriginalRoomTombstoneEvent, OriginalSyncRoomTombstoneEvent},
        topic::{OriginalRoomTopicEvent, OriginalSyncRoomTopicEvent},
        ImageInfo, MediaSource,
    },
    space::{
        child::{OriginalSpaceChildEvent, OriginalSyncSpaceChildEvent},
        parent::{OriginalSpaceParentEvent, OriginalSyncSpaceParentEvent},
    },
    sticker::{OriginalStickerEvent, OriginalSyncStickerEvent},
    AnySyncMessageLikeEvent, AnySyncStateEvent, AnySyncTimelineEvent, OriginalSyncMessageLikeEvent,
    SyncMessageLikeEvent, SyncStateEvent,
};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, ops::Deref, sync::Arc};
use tracing::info;

use super::common::{ContentDesc, ReactionRecord};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EventSendState {
    state: String,
    error: Option<String>,
    event_id: Option<OwnedEventId>,
}

impl EventSendState {
    fn new(inner: &SdkEventSendState) -> Self {
        let (state, error, event_id) = match inner {
            SdkEventSendState::NotSentYet => ("NotSentYet".to_string(), None, None),
            SdkEventSendState::Cancelled => ("Cancelled".to_string(), None, None),
            SdkEventSendState::SendingFailed { error } => (
                "SendingFailed".to_string(),
                Some(error.to_owned().to_string()),
                None,
            ),

            SdkEventSendState::Sent { event_id } => {
                ("Sent".to_string(), None, Some(event_id.clone()))
            }
        };
        EventSendState {
            state,
            error,
            event_id,
        }
    }

    pub fn state(&self) -> String {
        self.state.clone()
    }

    pub fn error(&self) -> Option<String> {
        self.error.clone()
    }

    pub fn event_id(&self) -> Option<OwnedEventId> {
        self.event_id.clone()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomEventItem {
    evt_id: Option<OwnedEventId>,
    txn_id: Option<OwnedTransactionId>,
    sender: OwnedUserId,
    send_state: Option<EventSendState>,
    origin_server_ts: u64,
    event_type: String,
    msg_type: Option<String>,
    content_desc: Option<ContentDesc>,
    in_reply_to: Option<OwnedEventId>,
    read_receipts: HashMap<String, Receipt>,
    reactions: HashMap<String, Vec<ReactionRecord>>,
    editable: bool,
    edited: bool,
}

impl RoomEventItem {
    fn new(
        evt_id: Option<OwnedEventId>,
        txn_id: Option<OwnedTransactionId>,
        sender: OwnedUserId,
        origin_server_ts: u64,
        event_type: String,
    ) -> Self {
        RoomEventItem {
            evt_id,
            txn_id,
            sender,
            send_state: None,
            origin_server_ts,
            event_type,
            msg_type: None,
            content_desc: None,
            in_reply_to: None,
            read_receipts: Default::default(),
            reactions: Default::default(),
            editable: false,
            edited: false,
        }
    }

    #[cfg(feature = "testing")]
    #[doc(hidden)]
    pub fn evt_id(&self) -> Option<OwnedEventId> {
        self.evt_id.clone()
    }

    pub fn unique_id(&self) -> String {
        if let Some(evt_id) = &self.evt_id {
            return evt_id.to_string();
        }
        self.txn_id
            .clone()
            .expect("Either event id or transaction id should be available")
            .to_string()
    }

    pub fn sender(&self) -> String {
        self.sender.to_string()
    }

    fn set_send_state(&mut self, send_state: &SdkEventSendState) {
        self.send_state = Some(EventSendState::new(send_state));
    }

    pub fn send_state(&self) -> Option<EventSendState> {
        self.send_state.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.origin_server_ts
    }

    pub fn event_type(&self) -> String {
        self.event_type.clone()
    }

    pub fn msg_type(&self) -> Option<String> {
        self.msg_type.clone()
    }

    pub(crate) fn set_msg_type(&mut self, value: String) {
        self.msg_type = Some(value);
    }

    pub fn content_desc(&self) -> Option<ContentDesc> {
        self.content_desc.clone()
    }

    pub(crate) fn set_content_desc(&mut self, value: ContentDesc) {
        self.content_desc = Some(value);
    }

    pub fn in_reply_to(&self) -> Option<String> {
        self.in_reply_to.as_ref().map(|x| x.to_string())
    }

    pub(crate) fn set_in_reply_to(&mut self, value: OwnedEventId) {
        self.in_reply_to = Some(value);
    }

    pub(crate) fn add_receipt(&mut self, seen_by: String, receipt: Receipt) {
        self.read_receipts.insert(seen_by, receipt);
    }

    pub fn read_users(&self) -> Vec<String> {
        // don't use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut users = vec![];
        for seen_by in self.read_receipts.keys() {
            users.push(seen_by.to_string());
        }
        users
    }

    pub fn receipt_ts(&self, seen_by: String) -> Option<u64> {
        if self.read_receipts.contains_key(&seen_by) {
            self.read_receipts[&seen_by].ts.map(|x| x.get().into())
        } else {
            None
        }
    }

    pub(crate) fn add_reaction(&mut self, key: String, records: Vec<ReactionRecord>) {
        self.reactions.insert(key, records);
    }

    pub fn reaction_keys(&self) -> Vec<String> {
        // don't use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut keys = vec![];
        for key in self.reactions.keys() {
            keys.push(key.to_owned());
        }
        keys
    }

    pub fn reaction_records(&self, key: String) -> Option<Vec<ReactionRecord>> {
        if self.reactions.contains_key(&key) {
            Some(self.reactions[&key].clone())
        } else {
            None
        }
    }

    pub fn is_editable(&self) -> bool {
        self.editable
    }

    pub(crate) fn set_editable(&mut self, value: bool) {
        self.editable = value;
    }

    pub fn was_edited(&self) -> bool {
        self.edited
    }

    pub(crate) fn set_edited(&mut self, value: bool) {
        self.edited = value;
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomVirtualItem {
    event_type: String,
    desc: Option<String>,
}

impl RoomVirtualItem {
    pub(crate) fn new(event_type: String, desc: Option<String>) -> Self {
        RoomVirtualItem { event_type, desc }
    }

    pub fn event_type(&self) -> String {
        self.event_type.clone()
    }

    pub fn desc(&self) -> Option<String> {
        self.desc.clone()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomMessage {
    item_type: String,
    room_id: OwnedRoomId,
    event_item: Option<RoomEventItem>,
    virtual_item: Option<RoomVirtualItem>,
}

impl RoomMessage {
    fn new_event_item(room_id: OwnedRoomId, event_item: RoomEventItem) -> Self {
        RoomMessage {
            item_type: "event".to_string(),
            room_id,
            event_item: Some(event_item),
            virtual_item: None,
        }
    }

    fn new_virtual_item(room_id: OwnedRoomId, virtual_item: RoomVirtualItem) -> Self {
        RoomMessage {
            item_type: "virtual".to_string(),
            room_id,
            event_item: None,
            virtual_item: Some(virtual_item),
        }
    }

    pub(crate) fn call_answer_from_event(
        event: OriginalCallAnswerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.call.answer".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.answer.sdp);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_answer_from_sync_event(
        event: OriginalSyncCallAnswerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.call.answer".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.answer.sdp);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_candidates_from_event(
        event: OriginalCallCandidatesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.call.candidates".to_string(),
        );
        let candidates = event
            .content
            .candidates
            .into_iter()
            .map(|x| x.candidate)
            .collect::<Vec<String>>()
            .join(", ");
        let content_desc = ContentDesc::from_text(format!("changed candidates to {candidates}"));
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_candidates_from_sync_event(
        event: OriginalSyncCallCandidatesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.call.candidates".to_string(),
        );
        let candidates = event
            .content
            .candidates
            .into_iter()
            .map(|x| x.candidate)
            .collect::<Vec<String>>()
            .join(", ");
        let content_desc = ContentDesc::from_text(format!("changed candidates to {candidates}"));
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_hangup_from_event(
        event: OriginalCallHangupEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.call.hangup".to_string(),
        );
        let body = format!("hangup this call because {}", event.content.reason);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_hangup_from_sync_event(
        event: OriginalSyncCallHangupEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.call.hangup".to_string(),
        );
        let body = format!("hangup this call because {}", event.content.reason);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_invite_from_event(
        event: OriginalCallInviteEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.call.invite".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.offer.sdp);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_invite_from_sync_event(
        event: OriginalSyncCallInviteEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.call.invite".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.offer.sdp);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_room_from_event(
        event: OriginalPolicyRuleRoomEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.policy.rule.room".to_string(),
        );
        let body = format!(
            "recommended {} about {} because {}",
            event.content.0.recommendation, event.content.0.entity, event.content.0.reason,
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_room_from_sync_event(
        event: OriginalSyncPolicyRuleRoomEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.policy.rule.room".to_string(),
        );
        let body = format!(
            "recommended {} about {} because {}",
            event.content.0.recommendation, event.content.0.entity, event.content.0.reason,
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_server_from_event(
        event: OriginalPolicyRuleServerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.policy.rule.server".to_string(),
        );
        let content_desc = ContentDesc::from_text("changed policy rule server".to_string());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_server_from_sync_event(
        event: OriginalSyncPolicyRuleServerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.policy.rule.server".to_string(),
        );
        let content_desc = ContentDesc::from_text("changed policy rule server".to_string());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_user_from_event(
        event: OriginalPolicyRuleUserEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.policy.rule.user".to_string(),
        );
        let content_desc = ContentDesc::from_text("changed policy rule user".to_string());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_user_from_sync_event(
        event: OriginalSyncPolicyRuleUserEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.policy.rule.user".to_string(),
        );
        let content_desc = ContentDesc::from_text("changed policy rule user".to_string());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn reaction_from_event(event: OriginalReactionEvent, room_id: OwnedRoomId) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.reaction".to_string(),
        );
        let body = format!("reacted by {}", event.content.relates_to.key);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn reaction_from_sync_event(
        event: OriginalSyncReactionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.reaction".to_string(),
        );
        let body = format!("reacted by {}", event.content.relates_to.key);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_aliases_from_event(
        event: OriginalRoomAliasesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.aliases".to_string(),
        );
        let aliases = event
            .content
            .aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let content_desc = ContentDesc::from_text(format!("changed room aliases to {aliases}"));
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_aliases_from_sync_event(
        event: OriginalSyncRoomAliasesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.aliases".to_string(),
        );
        let aliases = event
            .content
            .aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let content_desc = ContentDesc::from_text(format!("changed room aliases to {aliases}"));
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_avatar_from_event(
        event: OriginalRoomAvatarEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.avatar".to_string(),
        );
        let content_desc = ContentDesc::from_text("changed room avatar".to_string());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_avatar_from_sync_event(
        event: OriginalSyncRoomAvatarEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.avatar".to_string(),
        );
        let content_desc = ContentDesc::from_text("changed room avatar".to_string());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_canonical_alias_from_event(
        event: OriginalRoomCanonicalAliasEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.canonical_alias".to_string(),
        );
        let alt_aliases = event
            .content
            .alt_aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let body = format!(
            "changed canonical aliases ({}) of room alias ({:?})",
            alt_aliases,
            event.content.alias.map(|x| x.to_string()),
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_canonical_alias_from_sync_event(
        event: OriginalSyncRoomCanonicalAliasEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.canonical_alias".to_string(),
        );
        let alt_aliases = event
            .content
            .alt_aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let body = format!(
            "changed canonical aliases ({}) of room alias ({:?})",
            alt_aliases,
            event.content.alias.map(|x| x.to_string()),
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_create_from_event(
        event: OriginalRoomCreateEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.create".to_string(),
        );
        let content_desc = ContentDesc::from_text("created this room".to_string());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_create_from_sync_event(
        event: OriginalSyncRoomCreateEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.create".to_string(),
        );
        let content_desc = ContentDesc::from_text("created this room".to_string());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_encrypted_from_event(
        event: OriginalRoomEncryptedEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.encrypted".to_string(),
        );
        let scheme = match event.content.scheme {
            EncryptedEventScheme::MegolmV1AesSha2(s) => "MegolmV1AesSha2".to_string(),
            EncryptedEventScheme::OlmV1Curve25519AesSha2(s) => "OlmV1Curve25519AesSha2".to_string(),
            _ => "Unknown".to_string(),
        };
        let content_desc = ContentDesc::from_text(format!("encrypted by {scheme}"));
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_encrypted_from_sync_event(
        event: OriginalSyncRoomEncryptedEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.encrypted".to_string(),
        );
        let scheme = match event.content.scheme {
            EncryptedEventScheme::MegolmV1AesSha2(s) => "MegolmV1AesSha2".to_string(),
            EncryptedEventScheme::OlmV1Curve25519AesSha2(s) => "OlmV1Curve25519AesSha2".to_string(),
            _ => "Unknown".to_string(),
        };
        let content_desc = ContentDesc::from_text(format!("encrypted by {scheme}"));
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_encryption_from_event(
        event: OriginalRoomEncryptionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.encryption".to_string(),
        );
        let body = format!("changed encryption to {}", event.content.algorithm);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_encryption_from_sync_event(
        event: OriginalSyncRoomEncryptionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.encryption".to_string(),
        );
        let body = format!("changed encryption to {}", event.content.algorithm);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_guest_access_from_event(
        event: OriginalRoomGuestAccessEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.guest.access".to_string(),
        );
        let body = format!(
            "changed room's guest access to {}",
            event.content.guest_access,
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_guest_access_from_sync_event(
        event: OriginalSyncRoomGuestAccessEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.guest.access".to_string(),
        );
        let body = format!(
            "changed room's guest access to {}",
            event.content.guest_access,
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_history_visibility_from_event(
        event: OriginalRoomHistoryVisibilityEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.history_visibility".to_string(),
        );
        let body = format!(
            "changed room's history visibility to {}",
            event.content.history_visibility,
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_history_visibility_from_sync_event(
        event: OriginalSyncRoomHistoryVisibilityEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.history_visibility".to_string(),
        );
        let body = format!(
            "changed room's history visibility to {}",
            event.content.history_visibility,
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_join_rules_from_event(
        event: OriginalRoomJoinRulesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.join.rules".to_string(),
        );
        let body = format!(
            "changed room's join rules to {}",
            event.content.join_rule.as_str(),
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_join_rules_from_sync_event(
        event: OriginalSyncRoomJoinRulesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.join.rules".to_string(),
        );
        let body = format!(
            "changed room's join rules to {}",
            event.content.join_rule.as_str(),
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_member_from_event(
        event: OriginalRoomMemberEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id.clone()),
            None,
            event.sender.clone(),
            event.origin_server_ts.get().into(),
            "m.room.member".to_string(),
        );
        let fallback = match event.content.membership {
            MembershipState::Join => {
                event_item.set_msg_type("Joined".to_string());
                "joined".to_string()
            }
            MembershipState::Leave => {
                event_item.set_msg_type("Left".to_string());
                "left".to_string()
            }
            MembershipState::Ban => {
                event_item.set_msg_type("Banned".to_string());
                "banned".to_string()
            }
            MembershipState::Invite => {
                event_item.set_msg_type("Invited".to_string());
                "invited".to_string()
            }
            MembershipState::Knock => {
                event_item.set_msg_type("Knocked".to_string());
                "knocked".to_string()
            }
            _ => {
                event_item.set_msg_type("ProfileChanged".to_string());
                match (
                    &event.content.displayname,
                    &event.content.avatar_url,
                    event
                        .prev_content()
                        .map(|c| (c.avatar_url.as_ref(), c.displayname.as_ref()))
                        .unwrap_or_default(),
                ) {
                    (Some(display_name), Some(avatar_name), (Some(old), _)) => {
                        format!("Updated avatar & changed name to {old} -> {display_name}")
                    }
                    (Some(display_name), Some(avatar_name), (None, _)) => {
                        format!("Updated avatar & set name to {display_name}")
                    }
                    (Some(display_name), None, (Some(old), Some(_))) => {
                        format!("Changed name {old} -> {display_name}, removed avatar")
                    }
                    (Some(display_name), None, (None, Some(_))) => {
                        format!("Set name to {display_name}, removed avatar")
                    }
                    (Some(display_name), None, (Some(old), _)) => {
                        format!("Changed name {old} -> {display_name}")
                    }
                    (Some(display_name), None, (None, _)) => {
                        format!("Set name to {display_name}")
                    }
                    (None, Some(avatar), (None, _)) => "Updated avatar".to_string(),
                    (None, Some(avatar), (Some(_), _)) => {
                        "Removed name, updated avatar".to_string()
                    }
                    (None, None, (Some(_), Some(_))) => "Removed name and avatar".to_string(),
                    (None, None, (Some(_), None)) => "Removed name".to_string(),
                    (None, None, (None, Some(_))) => "Removed avatar".to_string(),
                    (None, None, (None, None)) => "Removed name".to_string(),
                }
            }
        };
        let content_desc = ContentDesc::from_text(fallback);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_member_from_sync_event(
        event: OriginalSyncRoomMemberEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id.clone()),
            None,
            event.sender.clone(),
            event.origin_server_ts.get().into(),
            "m.room.member".to_string(),
        );
        let fallback = match event.content.membership {
            MembershipState::Join => {
                event_item.set_msg_type("Joined".to_string());
                "joined".to_string()
            }
            MembershipState::Leave => {
                event_item.set_msg_type("Left".to_string());
                "left".to_string()
            }
            MembershipState::Ban => {
                event_item.set_msg_type("Banned".to_string());
                "banned".to_string()
            }
            MembershipState::Invite => {
                event_item.set_msg_type("Invited".to_string());
                "invited".to_string()
            }
            MembershipState::Knock => {
                event_item.set_msg_type("Knocked".to_string());
                "knocked".to_string()
            }
            _ => {
                event_item.set_msg_type("ProfileChanged".to_string());
                match (
                    &event.content.displayname,
                    &event.content.avatar_url,
                    event
                        .prev_content()
                        .map(|c| (c.avatar_url.as_ref(), c.displayname.as_ref()))
                        .unwrap_or_default(),
                ) {
                    (Some(display_name), Some(avatar_name), (Some(old), _)) => {
                        format!("Updated avatar & changed name to {old} -> {display_name}")
                    }
                    (Some(display_name), Some(avatar_name), (None, _)) => {
                        format!("Updated avatar & set name to {display_name}")
                    }
                    (Some(display_name), None, (Some(old), Some(_))) => {
                        format!("Changed name {old} -> {display_name}, removed avatar")
                    }
                    (Some(display_name), None, (None, Some(_))) => {
                        format!("Set name to {display_name}, removed avatar")
                    }
                    (Some(display_name), None, (Some(old), _)) => {
                        format!("Changed name {old} -> {display_name}")
                    }
                    (Some(display_name), None, (None, _)) => {
                        format!("Set name to {display_name}")
                    }
                    (None, Some(avatar), (None, _)) => "Updated avatar".to_string(),
                    (None, Some(avatar), (Some(_), _)) => {
                        "Removed name, updated avatar".to_string()
                    }
                    (None, None, (Some(_), Some(_))) => "Removed name and avatar".to_string(),
                    (None, None, (Some(_), None)) => "Removed name".to_string(),
                    (None, None, (None, Some(_))) => "Removed avatar".to_string(),
                    (None, None, (None, None)) => "Removed name".to_string(),
                }
            }
        };
        let content_desc = ContentDesc::from_text(fallback);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub fn room_message_from_event(
        event: OriginalRoomMessageEvent,
        room: Room,
        has_editable: bool,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender.clone(),
            event.origin_server_ts.get().into(),
            "m.room.message".to_string(),
        );
        if (has_editable) {
            if let Some(user_id) = room.client().user_id() {
                if *user_id == event.sender {
                    event_item.set_editable(true);
                }
            }
        }
        event_item.set_msg_type(event.content.msgtype().to_string());
        let fallback = match event.content.msgtype.clone() {
            MessageType::Audio(content) => "sent an audio.".to_string(),
            MessageType::Emote(content) => content.body,
            MessageType::File(content) => "sent a file.".to_string(),
            MessageType::Image(content) => "sent an image.".to_string(),
            MessageType::Location(content) => content.body,
            MessageType::Notice(content) => content.body,
            MessageType::ServerNotice(content) => content.body,
            MessageType::Text(content) => content.body,
            MessageType::Video(content) => "sent a video.".to_string(),
            _ => "Unknown sync item".to_string(),
        };
        match event.content.msgtype {
            MessageType::Audio(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Emote(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::File(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Image(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Location(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Text(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Video(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            _ => {}
        }
        if event_item.content_desc.is_none() {
            let content_desc = ContentDesc::from_text(fallback);
            event_item.set_content_desc(content_desc);
        }
        if let Some(Relation::Replacement(r)) = event.content.relates_to {
            event_item.set_edited(true);
        }
        RoomMessage::new_event_item(room.room_id().to_owned(), event_item)
    }

    pub(crate) fn room_message_from_sync_event(
        event: OriginalSyncRoomMessageEvent,
        room_id: OwnedRoomId,
        sent_by_me: bool,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.message".to_string(),
        );
        event_item.set_editable(sent_by_me);
        event_item.set_msg_type(event.content.msgtype().to_string());
        let fallback = match event.content.msgtype.clone() {
            MessageType::Audio(content) => "sent an audio.".to_string(),
            MessageType::Emote(content) => content.body,
            MessageType::File(content) => "sent a file.".to_string(),
            MessageType::Image(content) => "sent an image.".to_string(),
            MessageType::Location(content) => content.body,
            MessageType::Notice(content) => content.body,
            MessageType::ServerNotice(content) => content.body,
            MessageType::Text(content) => content.body,
            MessageType::Video(content) => "sent a video.".to_string(),
            _ => "Unknown sync item".to_string(),
        };
        match event.content.msgtype {
            MessageType::Audio(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Emote(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::File(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Image(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Location(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Text(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            MessageType::Video(content) => {
                let content_desc = ContentDesc::from(&content);
                event_item.set_content_desc(content_desc);
            }
            _ => {}
        }
        if event_item.content_desc.is_none() {
            let content_desc = ContentDesc::from_text(fallback);
            event_item.set_content_desc(content_desc);
        }
        if let Some(Relation::Replacement(r)) = event.content.relates_to {
            event_item.set_edited(true);
        }
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_name_from_event(event: OriginalRoomNameEvent, room_id: OwnedRoomId) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.name".to_string(),
        );
        let body = format!("changed name to {}", event.content.name);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_name_from_sync_event(
        event: OriginalSyncRoomNameEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.name".to_string(),
        );
        let body = format!("changed name to {}", event.content.name);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_pinned_events_from_event(
        event: OriginalRoomPinnedEventsEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.pinned_events".to_string(),
        );
        let body = format!("pinned {} events", event.content.pinned.len());
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_pinned_events_from_sync_event(
        event: OriginalSyncRoomPinnedEventsEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.pinned_events".to_string(),
        );
        let body = format!("pinned {} events", event.content.pinned.len());
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_power_levels_from_event(
        event: OriginalRoomPowerLevelsEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.power_levels".to_string(),
        );
        let users = event
            .content
            .users
            .iter()
            .map(|(user_id, value)| format!("power level of {user_id} to {value}"))
            .collect::<Vec<String>>()
            .join(", ");
        let content_desc = ContentDesc::from_text(format!("changed {users}"));
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_power_levels_from_sync_event(
        event: OriginalSyncRoomPowerLevelsEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.power_levels".to_string(),
        );
        let users = event
            .content
            .users
            .iter()
            .map(|(user_id, value)| format!("power level of {user_id} to {value}"))
            .collect::<Vec<String>>()
            .join(", ");
        let content_desc = ContentDesc::from_text(format!("changed {users}"));
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_redaction_from_event(
        event: RoomRedactionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id().to_owned()),
            None,
            event.sender().to_owned(),
            event.origin_server_ts().get().into(),
            "m.room.redaction".to_string(),
        );
        let reason = event.as_original().and_then(|x| x.content.reason.clone());
        let body = match reason {
            Some(reason) => format!("deleted this item because {reason}"),
            None => "deleted this item".to_string(),
        };
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_redaction_from_sync_event(
        event: SyncRoomRedactionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id().to_owned()),
            None,
            event.sender().to_owned(),
            event.origin_server_ts().get().into(),
            "m.room.redaction".to_string(),
        );
        let reason = event.as_original().and_then(|x| x.content.reason.clone());
        let body = match reason {
            Some(reason) => format!("deleted this item because {reason}"),
            None => "deleted this item".to_string(),
        };
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_server_acl_from_event(
        event: OriginalRoomServerAclEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.server_acl".to_string(),
        );
        let allow = event.content.allow.join(", ");
        let deny = event.content.deny.join(", ");
        let body = match (allow.is_empty(), deny.is_empty()) {
            (true, true) => format!("allowed {allow}, denied {deny}"),
            (true, false) => format!("allowed {allow}"),
            (false, true) => format!("denied {deny}"),
            (false, false) => "".to_string(),
        };
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_server_acl_from_sync_event(
        event: OriginalSyncRoomServerAclEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.server_acl".to_string(),
        );
        let allow = event.content.allow.join(", ");
        let deny = event.content.deny.join(", ");
        let body = match (allow.is_empty(), deny.is_empty()) {
            (true, true) => format!("allowed {allow}, denied {deny}"),
            (true, false) => format!("allowed {allow}"),
            (false, true) => format!("denied {deny}"),
            (false, false) => "".to_string(),
        };
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_third_party_invite_from_event(
        event: OriginalRoomThirdPartyInviteEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.third_party_invite".to_string(),
        );
        let body = format!("invited {}", event.content.display_name);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_third_party_invite_from_sync_event(
        event: OriginalSyncRoomThirdPartyInviteEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.third_party_invite".to_string(),
        );
        let body = format!("invited {}", event.content.display_name);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_tombstone_from_event(
        event: OriginalRoomTombstoneEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.tombstone".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.body);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_tombstone_from_sync_event(
        event: OriginalSyncRoomTombstoneEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.tombstone".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.body);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_topic_from_event(
        event: OriginalRoomTopicEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.topic".to_string(),
        );
        let body = format!("changed topic to {}", event.content.topic);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_topic_from_sync_event(
        event: OriginalSyncRoomTopicEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.room.topic".to_string(),
        );
        let body = format!("changed topic to {}", event.content.topic);
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn space_child_from_event(
        event: OriginalSpaceChildEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.space.child".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.order.unwrap_or_default());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn space_child_from_sync_event(
        event: OriginalSyncSpaceChildEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.space.child".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.order.unwrap_or_default());
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn space_parent_from_event(
        event: OriginalSpaceParentEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.space.parent".to_string(),
        );
        let body = format!(
            "changed parent to {}",
            event
                .content
                .via
                .iter()
                .map(|x| x.to_string())
                .collect::<Vec<String>>()
                .join(", "),
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn space_parent_from_sync_event(
        event: OriginalSyncSpaceParentEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.space.parent".to_string(),
        );
        let body = format!(
            "changed parent to {}",
            event
                .content
                .via
                .iter()
                .map(|x| x.to_string())
                .collect::<Vec<String>>()
                .join(", "),
        );
        event_item.set_content_desc(ContentDesc::from_text(body));
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn sticker_from_event(event: OriginalStickerEvent, room_id: OwnedRoomId) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.sticker".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.body);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn sticker_from_sync_event(
        event: OriginalSyncStickerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            Some(event.event_id),
            None,
            event.sender,
            event.origin_server_ts.get().into(),
            "m.sticker".to_string(),
        );
        let content_desc = ContentDesc::from_text(event.content.body);
        event_item.set_content_desc(content_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn from_timeline_event_item(event: &EventTimelineItem, room: Room) -> Self {
        let mut evt_id = None;
        let mut txn_id = None;
        if event.is_local_echo() {
            if let Some(SdkEventSendState::Sent { event_id }) = event.send_state() {
                evt_id = Some((*event_id).clone());
            } else {
                txn_id = event.transaction_id().map(|x| (*x).to_owned());
            }
        } else {
            evt_id = event.event_id().map(|x| (*x).to_owned());
        }

        let room_id = room.room_id().to_owned();
        let sender = event.sender().to_owned();
        let origin_server_ts: u64 = event.timestamp().get().into();
        let client = room.client();
        let my_id = client.user_id();

        let mut event_item = match event.content() {
            TimelineItemContent::Message(msg) => {
                let msg_type = msg.msgtype();
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.message".to_string(),
                );
                result.set_msg_type(msg_type.msgtype().to_string());
                for (seen_by, receipt) in event.read_receipts().iter() {
                    result.add_receipt(seen_by.to_string(), receipt.clone());
                }
                for (key, reaction) in event.reactions().iter() {
                    let records = reaction
                        .senders()
                        .map(|x| {
                            ReactionRecord::new(
                                x.sender_id.clone(),
                                x.timestamp,
                                my_id.map(|me| me == x.sender_id).unwrap_or_default(),
                            )
                        })
                        .collect::<Vec<ReactionRecord>>();
                    result.add_reaction(key.clone(), records);
                }
                let sent_by_me = my_id.map(|me| me == event.sender()).unwrap_or_default();
                let mut fallback = match msg_type {
                    MessageType::Audio(content) => "sent an audio.".to_string(),
                    MessageType::Emote(content) => content.body.clone(),
                    MessageType::File(content) => "sent a file.".to_string(),
                    MessageType::Image(content) => "sent an image.".to_string(),
                    MessageType::Location(content) => content.body.clone(),
                    MessageType::Notice(content) => content.body.clone(),
                    MessageType::ServerNotice(content) => content.body.clone(),
                    MessageType::Text(content) => content.body.clone(),
                    MessageType::Video(content) => "sent a video.".to_string(),
                    _ => "Unknown timeline item".to_string(),
                };
                if let Some(json) = event.latest_edit_json() {
                    if let Ok(AnySyncTimelineEvent::MessageLike(
                        AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(ev)),
                    )) = json.deserialize()
                    {
                        fallback = match ev.content.msgtype {
                            MessageType::Audio(content) => "sent an audio.".to_string(),
                            MessageType::Emote(content) => content.body,
                            MessageType::File(content) => "sent a file.".to_string(),
                            MessageType::Image(content) => "sent an image.".to_string(),
                            MessageType::Location(content) => content.body,
                            MessageType::Notice(content) => content.body,
                            MessageType::ServerNotice(content) => content.body,
                            MessageType::Text(content) => content.body,
                            MessageType::Video(content) => "sent a video.".to_string(),
                            _ => "Unknown timeline item".to_string(),
                        };
                    }
                }
                match msg_type {
                    MessageType::Text(content) => {
                        let content_desc = ContentDesc::from(content);
                        result.set_content_desc(content_desc);
                        if sent_by_me {
                            result.set_editable(true);
                        }
                    }
                    MessageType::Emote(content) => {
                        let content_desc = ContentDesc::from(content);
                        result.set_content_desc(content_desc);
                        if sent_by_me {
                            result.set_editable(true);
                        }
                    }
                    MessageType::Image(content) => {
                        let content_desc = ContentDesc::from(content);
                        result.set_content_desc(content_desc);
                    }
                    MessageType::Audio(content) => {
                        let content_desc = ContentDesc::from(content);
                        result.set_content_desc(content_desc);
                    }
                    MessageType::Video(content) => {
                        let content_desc = ContentDesc::from(content);
                        result.set_content_desc(content_desc);
                    }
                    MessageType::File(content) => {
                        let content_desc = ContentDesc::from(content);
                        result.set_content_desc(content_desc);
                    }
                    MessageType::Location(content) => {
                        let content_desc = ContentDesc::from(content);
                        result.set_content_desc(content_desc);
                    }
                    _ => {}
                }
                if let Some(json) = event.latest_edit_json() {
                    if let Ok(AnySyncTimelineEvent::MessageLike(
                        AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(ev)),
                    )) = json.deserialize()
                    {
                        match ev.content.msgtype {
                            MessageType::Text(content) => {
                                let content_desc = ContentDesc::from(&content);
                                result.set_content_desc(content_desc);
                            }
                            MessageType::Emote(content) => {
                                let content_desc = ContentDesc::from(&content);
                                result.set_content_desc(content_desc);
                            }
                            MessageType::Image(content) => {
                                let content_desc = ContentDesc::from(&content);
                                result.set_content_desc(content_desc);
                            }
                            MessageType::Audio(content) => {
                                let content_desc = ContentDesc::from(&content);
                                result.set_content_desc(content_desc);
                            }
                            MessageType::Video(content) => {
                                let content_desc = ContentDesc::from(&content);
                                result.set_content_desc(content_desc);
                            }
                            MessageType::File(content) => {
                                let content_desc = ContentDesc::from(&content);
                                result.set_content_desc(content_desc);
                            }
                            MessageType::Location(content) => {
                                let content_desc = ContentDesc::from(&content);
                                result.set_content_desc(content_desc);
                            }
                            _ => {}
                        }
                    }
                }
                if result.content_desc.is_none() {
                    let content_desc = ContentDesc::from_text(fallback);
                    result.set_content_desc(content_desc);
                }
                if let Some(in_reply_to) = msg.in_reply_to() {
                    result.set_in_reply_to(in_reply_to.clone().event_id);
                }
                if msg.is_edited() {
                    result.set_edited(true);
                }
                result
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.redaction".to_string(),
                )
            }
            TimelineItemContent::Sticker(s) => {
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.sticker".to_string(),
                );
                let content_desc = ContentDesc::from(s.content());
                result.set_content_desc(content_desc);
                result
            }
            TimelineItemContent::UnableToDecrypt(encrypted_msg) => {
                info!("Edit event applies to event that couldn't be decrypted, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.encrypted".to_string(),
                )
            }
            TimelineItemContent::MembershipChange(m) => {
                info!("Edit event applies to a state event, discarding");
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.member".to_string(),
                );
                let fallback = match m.change() {
                    Some(MembershipChange::None) => {
                        result.set_msg_type("None".to_string());
                        "not changed membership".to_string()
                    }
                    Some(MembershipChange::Error) => {
                        result.set_msg_type("Error".to_string());
                        "error in membership change".to_string()
                    }
                    Some(MembershipChange::Joined) => {
                        result.set_msg_type("Joined".to_string());
                        "joined".to_string()
                    }
                    Some(MembershipChange::Left) => {
                        result.set_msg_type("Left".to_string());
                        "left".to_string()
                    }
                    Some(MembershipChange::Banned) => {
                        result.set_msg_type("Banned".to_string());
                        "banned".to_string()
                    }
                    Some(MembershipChange::Unbanned) => {
                        result.set_msg_type("Unbanned".to_string());
                        "unbanned".to_string()
                    }
                    Some(MembershipChange::Kicked) => {
                        result.set_msg_type("Kicked".to_string());
                        "kicked".to_string()
                    }
                    Some(MembershipChange::Invited) => {
                        result.set_msg_type("Invited".to_string());
                        "invited".to_string()
                    }
                    Some(MembershipChange::KickedAndBanned) => {
                        result.set_msg_type("KickedAndBanned".to_string());
                        "kicked and banned".to_string()
                    }
                    Some(MembershipChange::InvitationAccepted) => {
                        result.set_msg_type("InvitationAccepted".to_string());
                        "accepted invitation".to_string()
                    }
                    Some(MembershipChange::InvitationRejected) => {
                        result.set_msg_type("InvitationRejected".to_string());
                        "rejected invitation".to_string()
                    }
                    Some(MembershipChange::InvitationRevoked) => {
                        result.set_msg_type("InvitationRevoked".to_string());
                        "revoked invitation".to_string()
                    }
                    Some(MembershipChange::Knocked) => {
                        result.set_msg_type("Knocked".to_string());
                        "knocked".to_string()
                    }
                    Some(MembershipChange::KnockAccepted) => {
                        result.set_msg_type("KnockAccepted".to_string());
                        "accepted knock".to_string()
                    }
                    Some(MembershipChange::KnockRetracted) => {
                        result.set_msg_type("KnockRetracted".to_string());
                        "retracted knock".to_string()
                    }
                    Some(MembershipChange::KnockDenied) => {
                        result.set_msg_type("KnockDenied".to_string());
                        "denied knock".to_string()
                    }
                    Some(MembershipChange::NotImplemented) => {
                        result.set_msg_type("NotImplemented".to_string());
                        "not implemented change".to_string()
                    }
                    None => "unknown error".to_string(),
                };
                let content_desc = ContentDesc::from_text(fallback);
                result.set_content_desc(content_desc);
                result
            }
            TimelineItemContent::ProfileChange(p) => {
                info!("Edit event applies to a state event, discarding");
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.member".to_string(),
                );
                result.set_msg_type("ProfileChange".to_string());
                if let Some(change) = p.displayname_change() {
                    let content_desc = match (&change.old, &change.new) {
                        (Some(old), Some(new)) => {
                            ContentDesc::from_text(format!("changed name {old} -> {new}"))
                        }
                        (None, Some(new)) => ContentDesc::from_text(format!("set name to {new}")),
                        (Some(_), None) => ContentDesc::from_text("removed name".to_string()),
                        (None, None) => {
                            // why would that ever happen?
                            ContentDesc::from_text("kept name unset".to_string())
                        }
                    };
                    result.set_content_desc(content_desc);
                }
                if let Some(change) = p.avatar_url_change() {
                    if let Some(uri) = change.new.as_ref() {
                        let content_desc =
                            ContentDesc::from_image("new_picture".to_string(), uri.clone());
                        result.set_content_desc(content_desc);
                    }
                }
                result
            }
            TimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    s.content().event_type().to_string(),
                )
            }
            TimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to message that couldn't be parsed, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    event_type.to_string(),
                )
            }
            TimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to state that couldn't be parsed, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    event_type.to_string(),
                )
            }
            TimelineItemContent::Poll(s) => {
                info!("Edit event applies to a poll state, discarding");
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.poll.start".to_string(),
                );
                if let Some(fallback) = s.fallback_text() {
                    let content_desc = ContentDesc::from_text(fallback);
                    result.set_content_desc(content_desc);
                }
                result
            }
        };
        if event.is_local_echo() {
            if let Some(send_state) = event.send_state() {
                event_item.set_send_state(send_state)
            }
        }
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn from_timeline_virtual_item(event: &VirtualTimelineItem, room: Room) -> Self {
        let room_id = room.room_id().to_owned();
        match event {
            VirtualTimelineItem::DayDivider(ts) => {
                let desc = if let Some(st) = ts.to_system_time() {
                    let dt: DateTime<Utc> = st.into();
                    Some(dt.format("%Y-%m-%d").to_string())
                } else {
                    None
                };
                let virtual_item = RoomVirtualItem::new("DayDivider".to_string(), desc);
                RoomMessage::new_virtual_item(room_id, virtual_item)
            }
            VirtualTimelineItem::ReadMarker => {
                let virtual_item = RoomVirtualItem::new("ReadMarker".to_string(), None);
                RoomMessage::new_virtual_item(room_id, virtual_item)
            }
        }
    }

    pub fn item_type(&self) -> String {
        self.item_type.clone()
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.room_id.clone()
    }

    pub fn event_item(&self) -> Option<RoomEventItem> {
        self.event_item.clone()
    }

    pub(crate) fn event_id(&self) -> Option<String> {
        self.event_item.as_ref().map(|e| e.unique_id())
    }

    pub(crate) fn event_type(&self) -> String {
        self.event_item
            .as_ref()
            .map(|e| e.event_type())
            .unwrap_or_else(|| "virtual".to_owned()) // if we can't find it, it is because we are a virtual event
    }

    pub(crate) fn origin_server_ts(&self) -> Option<u64> {
        self.event_item.as_ref().map(|e| e.origin_server_ts())
    }

    pub(crate) fn set_event_item(&mut self, event_item: Option<RoomEventItem>) {
        self.event_item = event_item;
    }

    pub fn virtual_item(&self) -> Option<RoomVirtualItem> {
        self.virtual_item.clone()
    }
}

pub(crate) fn sync_event_to_message(
    event: &Raw<AnySyncTimelineEvent>,
    room_id: OwnedRoomId,
) -> Option<RoomMessage> {
    log::debug!("raw sync event to message: {:?}", event);
    match event.deserialize() {
        Ok(s) => any_sync_event_to_message(s, room_id),
        Err(e) => {
            log::debug!("Parsing sync failed: $e");
            None
        }
    }
}
pub(crate) fn any_sync_event_to_message(
    event: AnySyncTimelineEvent,
    room_id: OwnedRoomId,
) -> Option<RoomMessage> {
    info!("sync event to message: {:?}", event);
    match event {
        AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleRoom(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::policy_rule_room_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleServer(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::policy_rule_server_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleUser(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::policy_rule_user_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomAliases(SyncStateEvent::Original(
            e,
        ))) => Some(RoomMessage::room_aliases_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomAvatar(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_avatar_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomCanonicalAlias(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_canonical_alias_from_sync_event(
            e, room_id,
        )),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomCreate(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_create_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomEncryption(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_encryption_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomGuestAccess(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_guest_access_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomHistoryVisibility(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_history_visibility_from_sync_event(
            e, room_id,
        )),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomJoinRules(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_join_rules_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomMember(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_member_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomName(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_name_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomPinnedEvents(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_pinned_events_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomPowerLevels(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_power_levels_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomServerAcl(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_server_acl_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomThirdPartyInvite(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_third_party_invite_from_sync_event(
            e, room_id,
        )),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomTombstone(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_tombstone_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomTopic(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_topic_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::SpaceChild(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::space_child_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::SpaceParent(SyncStateEvent::Original(
            e,
        ))) => Some(RoomMessage::space_parent_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallAnswer(
            SyncMessageLikeEvent::Original(a),
        )) => Some(RoomMessage::call_answer_from_sync_event(a, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallCandidates(
            SyncMessageLikeEvent::Original(c),
        )) => Some(RoomMessage::call_candidates_from_sync_event(c, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallHangup(
            SyncMessageLikeEvent::Original(h),
        )) => Some(RoomMessage::call_hangup_from_sync_event(h, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallInvite(
            SyncMessageLikeEvent::Original(i),
        )) => Some(RoomMessage::call_invite_from_sync_event(i, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::Reaction(
            SyncMessageLikeEvent::Original(r),
        )) => Some(RoomMessage::reaction_from_sync_event(r, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomEncrypted(
            SyncMessageLikeEvent::Original(e),
        )) => Some(RoomMessage::room_encrypted_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(m),
        )) => Some(RoomMessage::room_message_from_sync_event(m, room_id, false)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomRedaction(r)) => {
            Some(RoomMessage::room_redaction_from_sync_event(r, room_id))
        }
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::Sticker(
            SyncMessageLikeEvent::Original(s),
        )) => Some(RoomMessage::sticker_from_sync_event(s, room_id)),
        _ => None,
    }
}

impl From<(Arc<TimelineItem>, Room)> for RoomMessage {
    fn from(v: (Arc<TimelineItem>, Room)) -> RoomMessage {
        let (item, room) = v;

        match item.deref().deref() {
            TimelineItemKind::Event(event_item) => {
                RoomMessage::from_timeline_event_item(event_item, room)
            }
            TimelineItemKind::Virtual(virtual_item) => {
                RoomMessage::from_timeline_virtual_item(virtual_item, room)
            }
        }
    }
}
impl From<(EventTimelineItem, Room)> for RoomMessage {
    fn from(v: (EventTimelineItem, Room)) -> RoomMessage {
        let (event_item, room) = v;
        RoomMessage::from_timeline_event_item(&event_item, room)
    }
}
