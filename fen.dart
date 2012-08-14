#library('dartchess');

#import('board.dart');

class Fen {
  static final String INITIAL_POS = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  
  Fen(String this._fen) {
    _regexp = new RegExp(@"^([KkQqRrNnBbPp1-8]{1,8})\/([KkQqRrNnBbPp1-8]{1,8})\/"
        @"([KkQqRrNnBbPp1-8]{1,8})\/([KkQqRrNnBbPp1-8]{1,8})\/([KkQqRrNnBbPp1-8]{1,8})\/"
        @"([KkQqRrNnBbPp1-8]{1,8})\/([KkQqRrNnBbPp1-8]{1,8})\/([KkQqRrNnBbPp1-8]{1,8})"
        @"\s([bw])\s([-KkQq]{1,4})\s([-abcdefgh1-8]{1,2})\s(\d)*\s(\d*)$");

    // Mapping between FEN codes and board pieces.
    _fen2piece = {
      "K": Board.WHITE_KING, "Q": Board.WHITE_QUEEN, "R": Board.WHITE_ROOK, "B": Board.WHITE_BISHOP,
      "N": Board.WHITE_KNIGHT, "P": Board.WHITE_PAWN, "k": Board.BLACK_KING, "q": Board.BLACK_QUEEN,
      "r": Board.BLACK_ROOK, "b": Board.BLACK_BISHOP, "n": Board.BLACK_KNIGHT, "p": Board.BLACK_PAWN
    };
    
    // Create a reverse mapping.
    _piece2fen = {};
    _fen2piece.forEach((String key, String value) => _piece2fen[value] = key);

    _parse();
  }
  
  _parse() {
    if( (_valid = _regexp.hasMatch(_fen)) == true ) {
      _match = _regexp.firstMatch(_fen);
    }
  }
  
  bool get valid() => _valid;
  String get fen() => _fen;
  int get colorToMove() => _match[9] == "w" ? Board.WHITE : Board.BLACK;
  
  bool populateBoard(Board board) {
    RegExp notDigit = new RegExp("[^1-8]");
    if( !_valid ) return false;
    
    for( int i = 0; i < 8; i++ ) {
      int hp = 0;
      var row = _match[i + 1];
      
      for( int s = 0; s < 8; s++ ) {
        if( notDigit.hasMatch(row[hp]) ) {
          board.setSquareByIndex(s, 8 - i, _fen2piece[row[hp]]);
        } else {
          var blanks = Math.parseInt(row[hp]);
          
          for( var b = 0; b < blanks; b++ ) {
            board.setSquareByIndex(s + b, 8 - i);
          }
          
          s += blanks - 1;
        }
        
        hp++;
      }
    }
    
    return true;
  }
  
  removeCastlingRights(String type) {
    bool white_ks, white_qs, black_ks, black_qs;
    String rights = _match[10];
    
    white_ks = white_qs = black_ks = black_qs = false;
    
    if( rights.contains("K") ) white_ks = true;
    if( rights.contains("Q") ) white_qs = true;
    if( rights.contains("k") ) black_ks = true;
    if( rights.contains("q") ) black_qs = true;

    switch( type ) {
      case "K": white_ks = false; break;
      case "Q": white_qs = false; break;
      case "k": black_ks = false; break;
      case "q": black_qs = false; break;
      case "KQ": white_ks = white_qs = false; break;
      case "kq": black_ks = black_qs = false; break;
    }
    
    rights = "";
    
    if( white_ks ) rights = "${rights}K";
    if( white_qs ) rights = "${rights}Q";
    if( black_ks ) rights = "${rights}k";
    if( black_qs ) rights = "${rights}q";
    
    if( rights.length == 0 ) rights = "-";

    _fen = "${_match[1]}/${_match[2]}/${_match[3]}/${_match[4]}/"
        "${_match[5]}/${_match[6]}/${_match[7]}/${_match[8]} "
        "${_match[9]} ${rights} ${_match[11]} ${_match[12]} ${_match[13]}";
    
    _parse();
  }

  toggleColor() {
    String color = _match[9] == "w" ? "b" : "w";
    
    _fen = "${_match[1]}/${_match[2]}/${_match[3]}/${_match[4]}/"
      "${_match[5]}/${_match[6]}/${_match[7]}/${_match[8]} "
      "${color} ${_match[10]} ${_match[11]} ${_match[12]} ${_match[13]}";
      
    _parse();
  }
  
  buildFromPosition(Board board) {
    String fen;
    
    for( int rank = 8; rank > 0; rank--) {
      int spaces = 0;
      
      fen = fen != null ? "${fen}/" : "";

      for( int file = "a".charCodeAt(0); file <= "h".charCodeAt(0); file++) {
        String square = new String.fromCharCodes([file]).concat("$rank");
        String piece = board.getPiece(square);
        
        if( piece == Board.EMPTY_SQUARE ) {
          spaces++;
          
          if( file == "h".charCodeAt(0) )
            fen = "${fen}${spaces}";
            
          continue;
        }
        
        if( spaces > 0 ) {
          fen = "${fen}${spaces}${_piece2fen[piece]}";
          spaces = 0;
        } else {
          fen = "${fen}${_piece2fen[piece]}";
        }
      }
    }

    _fen = "${fen} ${_match[9]} ${_match[10]} ${_match[11]} ${_match[12]} ${_match[13]}";
    _parse();
  }

  bool _valid;
  String _fen;
  Match _match;
  RegExp _regexp;
  var _fen2piece, _piece2fen;
}
