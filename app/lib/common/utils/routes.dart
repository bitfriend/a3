enum Routes {
  // primary & quickjump actions
  // actionAddTask('/actions/addTask'),
  actionAddTaskList('/actions/addTaskList'),
  actionAddPin('/actions/addPin'),
  actionAddEvent('/actions/addEvent'),
  actionAddUpdate('/actions/addUpdate'),

  // --- Auth
  intro('/intro'),
  start('/start'),
  introProfile('/introProfile'),
  authLogin('/login'),
  authRegister('/register'),

  // --- profile
  myProfile('/profile'),

  // --- generic nav
  main('/'),
  dashboard('/dashboard'),
  updates('/updates'),
  search('/search'),
  activities('/activities'),

  // --- chat
  chat('/chat'),
  // show as dialog
  createChat('/chat/create'),
  chatroom('/chat/:roomId([!#][^/]+)'), // !roomId, #roomName
  chatProfile('/chat/:roomId([!#][^/]+)/profile'),
  chatInvite('/:roomId([!#][^/]+)/invite'),

  tasks('/tasks'),
  task('/tasks/:taskListId([!#][^/]+)/:taskId([!#][^/]+)'),
  taskList('/tasks/:taskListId([!#][^/]+)'),

  // -- spaces
  spaces('/spaces'),
  joinSpace('/spaces/join'),
  createSpace('/spaces/create'),
  linkSpace('/:spaceId([!#][^/]+)/linkSpace'),
  linkChat('/:spaceId([!#][^/]+)/linkChat'),
  editSpace('/:spaceId([!#][^/]+)/edit'),
  spaceInvite('/:spaceId([!#][^/]+)/invite'),
  space('/:spaceId([!#][^/]+)'), // !spaceId, #spaceName
  spaceRelatedSpaces('/:spaceId([!#][^/]+)/spaces'),
  spaceMembers('/:spaceId([!#][^/]+)/members'),
  spacePins('/:spaceId([!#][^/]+)/pins'),
  spaceEvents('/:spaceId([!#][^/]+)/events'),
  spaceChats('/:spaceId([!#][^/]+)/chats'),
  spaceTasks('/:spaceId([!#][^/]+)/tasks'),
  // -- space Settings
  spaceSettings('/:spaceId([!#][^/]+)/settings'),
  spaceSettingsApps('/:spaceId([!#][^/]+)/settings/app'),

  // -- pins
  pins('/pins'),
  pin('/pins/:pinId'),
  editPin('/pins/:pinId/edit'),

  // -- events
  calendarEvents('/events'),
  createEvent('/events/create'),
  calendarEvent('/events/:calendarId'),
  editCalendarEvent('/events/:calendarId/edit'),

  // -- settings
  settings('/settings'),
  settingsLabs('/settings/labs'),
  settingSessions('/settings/sessions'),
  settingNotifications('/settings/notifications'),
  blockedUsers('/settings/blockedUsers'),
  emailAddresses('/settings/emailAddresses'),
  info('/info'),
  licenses('/info/licenses'),

  // -- utils
  bugReport('/bug-report'),
  quickJump('/quick-jump'),
  // -- coming in from a push notification
  forward('/forward'),
  // -- fatal failure
  fatalFail('/error');

  const Routes(this.route);
  final String route;
}
