#import('dart:html');
#import('board.dart');
#import('engine.dart');

class Dartchess {
  Dartchess() {
    _board = new Board();
    _engine = new Engine(init);
  }
    
  Board get board() => _board;
  Engine get engine() => _engine;
    
  init(Event event) => _engine.getValidMoves(_board.fen, run);

  run(Map valid_moves) {
    _board.engine = _engine;
    _board.validMoves = valid_moves;
  }

  Board _board;
  Engine _engine;    
}

void main() {
  Dartchess chess = new Dartchess();
  
  // Prevent people from dragging the mouse to highlight text on the HTML page.
  query('html').on.mouseDown.add((e) => e.preventDefault());
}
