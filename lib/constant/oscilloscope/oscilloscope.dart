// ignore_for_file: constant_identifier_names

enum OscilloscopeData {
  timePerDiv,
  channel,
  triggerEdgeType,
  triggerLevel;

  String get command {
    switch (this) {
      case OscilloscopeData.timePerDiv:
        return 'TIME';
      case OscilloscopeData.channel:
        return 'TRIG:EDGE:SOUR CHAN';
      case OscilloscopeData.triggerEdgeType:
        return 'TRIG:EDGE:SLOP';
      case OscilloscopeData.triggerLevel:
        return 'TRIG:EDGE:LEV';
    }
  }

  T deserialize<T>(String value) {
    switch (this) {
      case OscilloscopeData.timePerDiv:
        return double.parse(value) as T;
      case OscilloscopeData.channel:
        return Channel.values.firstWhere((e) => e.string == value) as T;
      case OscilloscopeData.triggerEdgeType:
        return EdgeType.values.firstWhere((e) => e.string == value) as T;
      case OscilloscopeData.triggerLevel:
        return double.parse(value) as T;
    }
  }
}

enum Channel {
  CH1,
  CH2,
  CH3,
  CH4;

  int get number {
    switch (this) {
      case Channel.CH1:
        return 1;
      case Channel.CH2:
        return 2;
      case Channel.CH3:
        return 3;
      case Channel.CH4:
        return 4;
    }
  }

  @override
  String toString() {
    return string;
  }

  String get string {
    return 'CHAN$number';
  }
}

enum ChannelEnum {
  state,
  probeScale,
  voltsPerDiv,
  offset,
  coupling;

  String get string {
    switch (this) {
      case ChannelEnum.state:
        return 'DISP';
      case ChannelEnum.probeScale:
        return 'PROB';
      case ChannelEnum.voltsPerDiv:
        return 'SCAL';
      case ChannelEnum.offset:
        return 'OFFS';
      case ChannelEnum.coupling:
        return 'COUP';
    }
  }

  T deserialize<T>(String value) {
    switch (this) {
      case ChannelEnum.state:
        return (int.parse(value) == 1) as T;
      case ChannelEnum.probeScale:
        return double.parse(value) as T;
      case ChannelEnum.voltsPerDiv:
        return double.parse(value) as T;
      case ChannelEnum.offset:
        return double.parse(value) as T;
      case ChannelEnum.coupling:
        return Coupling.values.firstWhere((e) {
              return e.string == value;
            })
            as T;
    }
  }
}

enum Mode {
  RUN,
  STOP,
  SINGLE,
  CLEAR;

  String get string {
    switch (this) {
      case Mode.RUN:
        return 'RUN';
      case Mode.STOP:
        return 'STOP';
      case Mode.SINGLE:
        return 'SING';
      case Mode.CLEAR:
        return 'CLE';
    }
  }
}

enum CaptureFormat {
  BMP24,
  BMP8,
  PNG,
  JPEG,
  TIFF;

  String get string {
    switch (this) {
      case CaptureFormat.BMP24:
        return 'BMP24';
      case CaptureFormat.BMP8:
        return 'BMP8';
      case CaptureFormat.PNG:
        return 'PNG';
      case CaptureFormat.JPEG:
        return 'JPEG';
      case CaptureFormat.TIFF:
        return 'TIFF';
    }
  }
}

enum Coupling {
  AC,
  DC,
  GND;

  String get string {
    switch (this) {
      case Coupling.AC:
        return 'AC';
      case Coupling.DC:
        return 'DC';
      case Coupling.GND:
        return 'GND';
    }
  }
}

enum EdgeType {
  NEG,
  POS,
  RFAL;

  String get string {
    switch (this) {
      case EdgeType.NEG:
        return 'NEG';
      case EdgeType.POS:
        return 'POS';
      case EdgeType.RFAL:
        return 'RFAL';
    }
  }
}

extension SwitchBool on bool {
  String get stringSwitch {
    return this ? 'ON' : 'OFF';
  }
}

enum OscilloscopeDecoder {
  one,
  two;

  int get number {
    switch (this) {
      case OscilloscopeDecoder.one:
        return 1;
      case OscilloscopeDecoder.two:
        return 2;
    }
  }
}

enum OscilloscopeDecodeMode {
  parallel,
  uart,
  i2c,
  spi;

  String get command {
    switch (this) {
      case OscilloscopeDecodeMode.parallel:
        return 'PAR';
      case OscilloscopeDecodeMode.uart:
        return 'UART';
      case OscilloscopeDecodeMode.i2c:
        return 'IIC';
      case OscilloscopeDecodeMode.spi:
        return 'SPI';
    }
  }

  static OscilloscopeDecodeMode? tryParse(String protocol) {
    switch (protocol) {
      case 'SPI':
        return OscilloscopeDecodeMode.spi;
      case 'I2C':
        return OscilloscopeDecodeMode.i2c;
      case 'Modbus':
        return OscilloscopeDecodeMode.uart;
      case 'PAR':
        return OscilloscopeDecodeMode.parallel;
      case 'UART':
        return OscilloscopeDecodeMode.uart;
      case 'IIC':
        return OscilloscopeDecodeMode.i2c;
      default:
        return null;
    }
  }

  String convertToWireTapSessionEntity() {
    switch (this) {
      case OscilloscopeDecodeMode.parallel:
        return 'PAR';
      case OscilloscopeDecodeMode.uart:
        return 'Modbus';
      case OscilloscopeDecodeMode.i2c:
        return 'I2C';
      case OscilloscopeDecodeMode.spi:
        return 'SPI';
    }
  }
}

enum OscilloscopeDecodeFormat {
  hex,
  ascii,
  dec,
  bin,
  line;

  String get command {
    switch (this) {
      case OscilloscopeDecodeFormat.hex:
        return 'HEX';
      case OscilloscopeDecodeFormat.ascii:
        return 'ASC';
      case OscilloscopeDecodeFormat.dec:
        return 'DEC';
      case OscilloscopeDecodeFormat.bin:
        return 'BIN';
      case OscilloscopeDecodeFormat.line:
        return 'LINE';
    }
  }

  static OscilloscopeDecodeFormat? tryParse(String protocol) {
    switch (protocol) {
      case 'HEX':
        return OscilloscopeDecodeFormat.hex;
      case 'ASC':
        return OscilloscopeDecodeFormat.ascii;
      case 'DEC':
        return OscilloscopeDecodeFormat.dec;
      case 'BIN':
        return OscilloscopeDecodeFormat.bin;
      case 'LINE':
        return OscilloscopeDecodeFormat.line;
      default:
        return null;
    }
  }
}
