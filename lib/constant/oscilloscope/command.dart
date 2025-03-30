import 'oscilloscope.dart';

String getChannelCommand(Channel channel, ChannelEnum data) {
  return 'CHAN${channel.number}:${data.string}';
}

String getTimebaseCommand() {
  return ':TIM:MAIN:SCAL?';
}

String getTriggerChannelCommand() {
  return 'TRIG:EDGE:SOUR?';
}

String getTriggerEdgeTypeCommand() {
  return 'TRIG:EDGE:SLOP?';
}

String getTriggerLevelCommand() {
  return 'TRIG:EDGE:LEV?';
}

String setModeCommand(Mode mode) {
  return ':${mode.string}';
}

String setChannelStateCommand(Channel channel, bool state) {
  return ':CHAN${channel.number}:DISP ${state.stringSwitch}';
}

String setChannelProbeScaleCommand(Channel channel, int probeScale) {
  return ':CHAN${channel.number}:PROB $probeScale';
}

String setChannelVoltsPerDivCommand(Channel channel, double voltsPerDiv) {
  return ':CHAN${channel.number}:SCAL ${voltsPerDiv.toStringAsFixed(1)}';
}

String setChannelOffsetCommand(Channel channel, double offset) {
  return ':CHAN${channel.number}:OFFS ${offset.toStringAsFixed(1)}';
}

String setChannelCouplingCommand(Channel channel, Coupling coupling) {
  return ':CHAN${channel.number}:COUP ${coupling.string}';
}

String setTimebaseCommand(double timebase) {
  final tpd = timebase < 0 ? timebase.toStringAsExponential(1) : timebase.toStringAsFixed(1);
  return ':TIM:MAIN:SCAL $tpd';
}

String setTriggerModeCommand() {
  return ':TRIG:MODE EDGE';
}

String setTriggerChannelCommand(Channel channel) {
  return ':TRIG:EDGE:SOUR CHAN${channel.number}';
}

String setTriggerEdgeTypeCommand(EdgeType edge) {
  return ':TRIG:EDGE:SLOP ${edge.string}';
}

String setTriggerLevelCommand(double level) {
  return ':TRIG:EDGE:LEV $level';
}

String setDecoderStateCommand(OscilloscopeDecoder decoder, bool isEnabled) {
  return ':DEC${decoder.number}:DISP ${isEnabled.stringSwitch}';
}

String setDecodeFormatCommand(OscilloscopeDecoder decoder, OscilloscopeDecodeFormat format) {
  return ':DEC${decoder.number}:FORM ${format.command}';
}

String setDecodeModeCommand(OscilloscopeDecoder decoder, OscilloscopeDecodeMode mode) {
  return ':DEC${decoder.number}:MODE ${mode.command}';
}