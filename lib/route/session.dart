import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/controller/session/session.dart';

final sessionRouter =
    Router()
      ..get('/', (Request req) => Response.ok('Hello, World! Your session router is working!'))
      ..get('/<id>', (Request req) {
        final id = int.tryParse(req.params['id'] ?? '');
        if (id == null) {
          return getSessionByName(req);
        }
        return getSessionById(req);
      })
      ..get('/search', getSessions)
      ..post('/', createSession)
      ..put('/start/<id>', startSession)
      ..put('/stop', stopSession)
      ..put('/<id>', editSession)
      ..delete('/<id>', deleteSession)
      ..mount('/spi', spiRouter.call)
      ..mount('/i2c', i2cRouter.call)
      ..mount('/modbus', modbusRouter.call)
      ..mount('/oscilloscope', oscilloscopeRouter.call)
      ..mount('/log', logRouter.call);

final spiRouter =
    Router()
      ..get('/latest/<id>', getLatestSpiMsg)
      ..get('/all/<id>', getAllSpiMsg);

final i2cRouter =
    Router()
      ..get('/latest/<id>', getLatestI2cMsg)
      ..get('/all/<id>', getAllI2cMsg);
  
final modbusRouter =
    Router()
      ..get('/latest/<id>', getLatestModbusMsg)
      ..get('/all/<id>', getAllModbusMsg);

final oscilloscopeRouter =
    Router()
      ..get('/latest/<id>', getLatestOscilloscopeMsg)
      ..get('/all/<id>', getAllOscilloscopeMsg);

final logRouter =
    Router()
      ..get('/latest/<id>', getLatestLog)
      ..get('/all/<id>', getAllLog);

