import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum ActerIcons {
  //LIST OF ACTER ICONS
  list(PhosphorIconsRegular.list),
  pin(PhosphorIconsRegular.pushPin),
  airplane(PhosphorIconsRegular.airplane),
  addressBook(PhosphorIconsRegular.addressBook),
  airplay(PhosphorIconsRegular.airplay),
  alarm(PhosphorIconsRegular.alarm),
  amazonLogo(PhosphorIconsRegular.amazonLogo),
  ambulance(PhosphorIconsRegular.ambulance),
  anchor(PhosphorIconsRegular.anchor),
  appleLogo(PhosphorIconsRegular.appleLogo),
  aperture(PhosphorIconsRegular.aperture),
  archive(PhosphorIconsRegular.archive),
  appStoreLogo(PhosphorIconsRegular.appStoreLogo),
  baby(PhosphorIconsRegular.baby),
  bag(PhosphorIconsRegular.bag),
  backpack(PhosphorIconsRegular.backpack),
  bank(PhosphorIconsRegular.bank),
  balloon(PhosphorIconsRegular.balloon),
  barcode(PhosphorIconsRegular.barcode),
  basketball(PhosphorIconsRegular.basketball),
  bathtub(PhosphorIconsRegular.bathtub),
  batteryCharging(PhosphorIconsRegular.batteryCharging),
  beanie(PhosphorIconsRegular.beanie),
  bed(PhosphorIconsRegular.bed),
  bell(PhosphorIconsRegular.bell),
  bicycle(PhosphorIconsRegular.bicycle),
  brain(PhosphorIconsRegular.brain),
  boat(PhosphorIconsRegular.boat),
  book(PhosphorIconsRegular.book),
  bird(PhosphorIconsRegular.bird),
  browser(PhosphorIconsRegular.browser),
  bookmark(PhosphorIconsRegular.bookmark),
  bomb(PhosphorIconsRegular.bomb),
  broadcast(PhosphorIconsRegular.broadcast),
  boot(PhosphorIconsRegular.boot),
  cableCar(PhosphorIconsRegular.cableCar),
  cactus(PhosphorIconsRegular.cactus),
  cake(PhosphorIconsRegular.cake),
  calculator(PhosphorIconsRegular.calculator),
  calendar(PhosphorIconsRegular.calendar),
  callBell(PhosphorIconsRegular.callBell),
  camera(PhosphorIconsRegular.camera),
  car(PhosphorIconsRegular.car),
  cat(PhosphorIconsRegular.cat),
  chat(PhosphorIconsRegular.chat),
  check(PhosphorIconsRegular.check),
  desk(PhosphorIconsRegular.desk),
  desktop(PhosphorIconsRegular.desktop),
  detective(PhosphorIconsRegular.detective),
  deviceMobile(PhosphorIconsRegular.deviceMobile),
  devices(PhosphorIconsRegular.devices),
  diamond(PhosphorIconsRegular.diamond),
  disc(PhosphorIconsRegular.disc),
  discordLogo(PhosphorIconsRegular.discordLogo),
  dog(PhosphorIconsRegular.dog),
  door(PhosphorIconsRegular.door),
  dotOutline(PhosphorIconsRegular.dotOutline),
  dot(PhosphorIconsRegular.dot),
  dress(PhosphorIconsRegular.dress),
  drop(PhosphorIconsRegular.drop),
  drone(PhosphorIconsRegular.drone),
  dropboxLogo(PhosphorIconsRegular.dropboxLogo),
  dropSimple(PhosphorIconsRegular.dropSimple),
  ear(PhosphorIconsRegular.ear),
  egg(PhosphorIconsRegular.egg),
  eggCrack(PhosphorIconsRegular.eggCrack),
  eject(PhosphorIconsRegular.eject),
  elevator(PhosphorIconsRegular.elevator),
  empty(PhosphorIconsRegular.empty),
  engine(PhosphorIconsRegular.engine),
  envelope(PhosphorIconsRegular.envelope),
  envelopeOpen(PhosphorIconsRegular.envelopeOpen),
  equalizer(PhosphorIconsRegular.equalizer),
  equals(PhosphorIconsRegular.equals),
  eraser(PhosphorIconsRegular.eraser),
  exam(PhosphorIconsRegular.exam),
  exclude(PhosphorIconsRegular.exclude),
  export(PhosphorIconsRegular.export),
  eye(PhosphorIconsRegular.eye),
  eyeClosed(PhosphorIconsRegular.eyeClosed),
  eyes(PhosphorIconsRegular.eyes),
  faceMask(PhosphorIconsRegular.faceMask),
  factory(PhosphorIconsRegular.factory),
  facebookLogo(PhosphorIconsRegular.facebookLogo),
  faders(PhosphorIconsRegular.faders),
  fan(PhosphorIconsRegular.fan),
  farm(PhosphorIconsRegular.farm),
  fastForward(PhosphorIconsRegular.fastForward),
  feather(PhosphorIconsRegular.feather),
  figmaLogo(PhosphorIconsRegular.figmaLogo),
  file(PhosphorIconsRegular.file),
  fileArchive(PhosphorIconsRegular.fileArchive),
  fileAudio(PhosphorIconsRegular.fileAudio),
  fileCloud(PhosphorIconsRegular.fileCloud),
  fileCsv(PhosphorIconsRegular.fileCsv),
  fileCss(PhosphorIconsRegular.fileCss),
  fileDashed(PhosphorIconsRegular.fileDashed),
  fileHtml(PhosphorIconsRegular.fileHtml),
  fileDoc(PhosphorIconsRegular.fileDoc),
  filePdf(PhosphorIconsRegular.filePdf),
  fileZip(PhosphorIconsRegular.fileZip),
  fish(PhosphorIconsRegular.fish),
  flame(PhosphorIconsRegular.flame),
  flower(PhosphorIconsRegular.flower),
  gameController(PhosphorIconsRegular.gameController),
  garage(PhosphorIconsRegular.garage),
  gasCan(PhosphorIconsRegular.gasCan),
  gasPump(PhosphorIconsRegular.gasPump),
  gauge(PhosphorIconsRegular.gauge),
  gear(PhosphorIconsRegular.gear),
  ghost(PhosphorIconsRegular.ghost),
  genderMale(PhosphorIconsRegular.genderMale),
  genderFemale(PhosphorIconsRegular.genderFemale),
  genderNeuter(PhosphorIconsRegular.genderNeuter),
  gif(PhosphorIconsRegular.gif),
  gift(PhosphorIconsRegular.gift),
  gitBranch(PhosphorIconsRegular.gitBranch),
  globe(PhosphorIconsRegular.globe),
  googleLogo(PhosphorIconsRegular.googleLogo),
  gps(PhosphorIconsRegular.gps),
  golf(PhosphorIconsRegular.golf),
  goggles(PhosphorIconsRegular.goggles),
  guitar(PhosphorIconsRegular.guitar),
  hairDryer(PhosphorIconsRegular.hairDryer),
  hammer(PhosphorIconsRegular.hammer),
  hand(PhosphorIconsRegular.hand),
  handbag(PhosphorIconsRegular.handbag),
  handEye(PhosphorIconsRegular.handEye),
  hash(PhosphorIconsRegular.hash),
  heart(PhosphorIconsRegular.heart),
  hockey(PhosphorIconsRegular.hockey),
  headset(PhosphorIconsRegular.headset),
  hexagon(PhosphorIconsRegular.hexagon),
  heartbeat(PhosphorIconsRegular.heartbeat),
  hospital(PhosphorIconsRegular.hospital),
  horse(PhosphorIconsRegular.horse),
  hoodie(PhosphorIconsRegular.hoodie),
  house(PhosphorIconsRegular.house),
  highHeel(PhosphorIconsRegular.highHeel),
  yarn(PhosphorIconsRegular.yarn);
  //..

  //ICON ACCESS METHODS
  static ActerIcons? iconFor(String? name) =>
      ActerIcons.values.asNameMap()[name];

  static ActerIcons iconForTask(String? name) =>
      iconFor(name) ?? ActerIcons.list;

  static ActerIcons iconForPin(String? name) =>
      iconFor(name) ?? ActerIcons.pin;

  //ENUM DECLARATION
  final IconData data;

  const ActerIcons(this.data);
}
