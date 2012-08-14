#library('dartchess');

#import('dart:html');
#import('engine.dart');
#import('fen.dart');

class Board {
  // Define HTML for chess pieces
  static final String
    WHITE_KING  = "♔", // &#9812;
    WHITE_QUEEN = "♕", // &#9813;
    WHITE_ROOK  = "♖", // &#9814;
    WHITE_BISHOP= "♗", // &#9815;
    WHITE_KNIGHT= "♘", // &#9816;
    WHITE_PAWN  = "♙", // &#9817;
    BLACK_KING  = "♚", // &#9818;
    BLACK_QUEEN = "♛", // &#9819;
    BLACK_ROOK  = "♜", // &#9820;
    BLACK_BISHOP= "♝", // &#9821;
    BLACK_KNIGHT= "♞", // &#9822;
    BLACK_PAWN  = "♟", // &#9823;
    EMPTY_SQUARE= "&nbsp;";
  
  static final int EMPTY = -1, BLACK = 0, WHITE = 1;
  static final int HUMAN = WHITE, ENGINE = BLACK;
  
  // Construstor method.
  Board() {
    _highlightColor = "green";
    _highlighted_squares = [];
    
    Future<CSSStyleDeclaration> white_square = query("#a8").computedStyle;
    Future<CSSStyleDeclaration> black_square = query("#b8").computedStyle;
    
    white_square.then((style) => _whiteBackgroundColor = style.backgroundColor);
    black_square.then((style) => _blackBackgroundColor = style.backgroundColor);

    resetBoard();
    _makeSelectable();
  }

  String get fen() => _fen.fen;
  Map get validMoves() => _validMoves;
  set validMoves(Map valid_moves) => _validMoves = valid_moves;
  set engine(Engine e) => _engine = e;
  
  _makeSelectable() {
    // Add onSelect event handlers for each square of the chess board.
    for( int rank = 8; rank > 0; rank--) {
      for( int file = "a".charCodeAt(0); file <= "h".charCodeAt(0); file++) {
        String square = new String.fromCharCodes([file]).concat("$rank");
        query("#${square}").on.click.add((UIEvent event) => select(event));
      }
    }    
  }
  
  // Resets board to initial starting position.
  resetBoard() {
    _moves = [];
    
    _fen = new Fen(Fen.INITIAL_POS);
    _fen.populateBoard(this);
  }
  
  // Retrieves the contents of a square on the board.
  String getPiece(String square) => document.query("#${square}").innerHTML;
  
  // Sets the contents of a square on the board.
  setSquare(String square, [String value = EMPTY_SQUARE]) =>
      document.query("#${square}").innerHTML = value;
  
  // Sets contents of square referenced by X and Y coordinates.
  setSquareByIndex(int x, int y, [String value = EMPTY_SQUARE]) =>
      setSquare("${"abcdefgh"[x]}${y.toString()}", value);
  
  // Retrieve rank for a given square (1-8).
  int getRank(String square) => Math.parseInt(square[1]);
  
  // Retrieve file for a given square (a-h converted to int).
  int getFile(String square) => square.charCodeAt(0) - 96;
  
  int getSquareColor(String square) {
    int color = EMPTY;
    
    switch( square[0] ) {
      case "a": case "c": case "e": case "g":
        switch( square[1] ) {
          case "2": case "4": case "6": case "8":
            color = WHITE;
            break;
          default:
            color = BLACK;
            break;
        }
        break;
      default:
        switch( square[1] ) {
          case "2": case "4": case "6": case "8":
            color = BLACK;
            break;
          default:
            color = WHITE;
            break;
        }
    }

    return color;
  }
  
  _highlight(String square) {
    query("#$square").style.borderColor = _highlightColor;
    _highlighted_squares.add(square);
  }
  
  _unhighlight() {
    _highlighted_squares.forEach((String square) =>
        query("#$square").style.borderColor = (getSquareColor(square) == WHITE) ?
            _whiteBackgroundColor : _blackBackgroundColor);
    _highlighted_squares = [];
  }
  
  // Determine which color piece is on a given square.
  int pieceColor(String piece) {
    int color = EMPTY;
    
    switch(piece) {
      case WHITE_KING: case WHITE_QUEEN: case WHITE_ROOK:
      case WHITE_BISHOP: case WHITE_KNIGHT: case WHITE_PAWN:
        color = WHITE;
        break;
      case BLACK_KING: case BLACK_QUEEN: case BLACK_ROOK:
      case BLACK_BISHOP: case BLACK_KNIGHT: case BLACK_PAWN:
        color = BLACK;
        break;
    }
    
    return color;
  }
  
  int pieceColorOnSquare(String square) => pieceColor(getPiece(square));
  
  select(UIEvent event) {
    int piece_color;
    Element element = event.target;
    String square = element.attributes["id"];
    String piece = getPiece(square);
    
    if( _selectedPiece == null ) {
      
      if( piece == EMPTY_SQUARE )
        return;
      
      piece_color = pieceColor(piece);
      
      if( piece_color == HUMAN && piece_color == _fen.colorToMove ) {
        _selectedPiece = piece;
        _selectedSquare = square;
        
        _highlight(square);
        
        if( _validMoves != null && _validMoves[square] != null ) {
          _validMoves[square].forEach((String move) => _highlight(move));
        }
      }
    } else {

      if( _validMoves[_selectedSquare] != null &&
          _validMoves[_selectedSquare].some((String e) => e == square))
      {
        _makeCastleMove(_selectedSquare, square, getPiece(_selectedSquare));
        _makeMove(_selectedSquare, square, _selectedPiece);
        _engine.makeMove(_fen.fen, makeBestmove);
      }
      
      if( _highlighted_squares.length > 0 ) {
        _unhighlight();
      }

      _selectedPiece = _selectedSquare = null;
    }
  }
  
  _makeCastleMove(String from_square, String to_square, String piece) {
    if( piece == WHITE_KING || piece == BLACK_KING ) {
      int f1 = getFile(from_square);
      int f2 = getFile(to_square);
      int piece_color = pieceColor(piece);
      
      // Castle King side.
      if( f1 == 5 && f2 == 7 ) {
        if( piece_color == WHITE ) {
          setSquare("h1", EMPTY_SQUARE);
          setSquare("f1", WHITE_ROOK);
        } else {
          setSquare("h8", EMPTY_SQUARE);
          setSquare("f8", BLACK_ROOK);
        }
      }
      
      // Castle Queen side.
      if( f1 == 5 && f2 == 3 ) {
        if( piece_color == WHITE ) {
          setSquare("a1", EMPTY_SQUARE);
          setSquare("d1", WHITE_ROOK);
        } else {
          setSquare("a8", EMPTY_SQUARE);
          setSquare("d8", BLACK_ROOK);
        }
      }
    }    
  }
  
  _makeMove(String from_square, String to_square, String piece) {
    setSquare(from_square, EMPTY_SQUARE);
    setSquare(to_square, piece);
    
    _moves.add(_fen.fen);
    
    _fen.toggleColor();
    _fen.buildFromPosition(this);
  }

  makeBestmove(String bestmove, String ponder) {
    String from_square = bestmove.substring(0, 2);
    String to_square = bestmove.substring(2, 4);
    String piece = getPiece(from_square);
    
    _makeCastleMove(from_square, to_square, piece);
    _makeMove(from_square, to_square, piece);
    _engine.getValidMoves(_fen.fen, _run);
  }
  
  _run(Map valid_moves) {
    _validMoves = valid_moves;
  }
  
  Fen _fen;
  Engine _engine;
  String _selectedPiece, _selectedSquare;
  String _highlightColor, _whiteBackgroundColor, _blackBackgroundColor;
  List<String> _highlighted_squares, _moves;
  Map<String, List<String>> _validMoves;
}
