#library('dartchess');

#import('dart:html');

class Engine {
  final int VALID_MOVES = 0, BEST_MOVE = 1;
  final String _STOCKFISH = "ws://192.168.1.138:50000/stockfish";
    
  Engine(Function callback, [int multipv=1]) {
    _multipv = multipv;
    
    _ws = new WebSocket(_STOCKFISH);
    _ws.on.open.add((Event event) => callback(event));
    _ws.on.message.add((MessageEvent event) => _processUCI(event.data));
  }

  _processUCI(String data) {
    switch(_mode) {
      case VALID_MOVES:
        _validMoves(data);
        break;
      case BEST_MOVE:
        _bestMove(data);
        break;
    }
  }
  
  makeMove(String fen, Function callback) {
    _mode = BEST_MOVE;
    _callback = callback;
    
    _ws.send("position fen $fen");
    _ws.send("go movetime 2500");
  }
  
  _bestMove(String data) {
    List<String> tokens = data.split(" ");
    
    if( tokens[0] == "bestmove" ) {
      _callback(tokens[1], tokens[3]);
    }
  }
  
  getValidMoves(String fen, Function callback) {
    _mode = VALID_MOVES;
    _callback = callback;
    _valid_moves = new Set();
    
    _ws.send("position fen $fen");
    _ws.send("setoption name multipv value 500");
    _ws.send("go depth 1");
  }
  
  _validMoves(String data) {
    List<String> tokens = data.split(" ");
    
    if( tokens[0] == "info" && tokens[14] == "multipv" ) {
        _valid_moves.add(tokens[17]);
    } else if( tokens[0] == "bestmove" ) {
      Map<String, List<String>> normalized = {};
      
      _valid_moves.forEach((String move) {
        String index = move.substring(0, 2);
        List<String> value = normalized[index] == null ? [] : normalized[index];
        
        value.add(move.substring(2, 4));
        normalized[index] = value;
      });
      
      _ws.on.message.remove((MessageEvent event) => _validMoves(event.data));
      _ws.send("setoption name multipv value ${_multipv}");
      
      _callback(normalized);
    }
  }

  int _multipv, _mode;
  Set _valid_moves;
  Function _callback;
  WebSocket _ws;
}
