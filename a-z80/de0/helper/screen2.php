<?php

$screen[2] = [
//             1         2         3         4         5         6         7
//   01234567890123456789012345678901234567890123456789012345678901234567890123456789
    "   CS    ED       ED+S    SS       K      ED     ED+S    SS                     ", //  0
    " 1 EDIT  BLUE     DEF FN  !      Q PLOT   SIN    ASN     <=                     ", //  1
    " 2 CAPS  RED      FN      @      W DRAW   COS    ACS     <>                     ", //  2
    " 3 TRUEV MAGENTA  LINE    #      E REM    TAN    ATN     >=                     ", //  3
    " 4 INV   GREEN    OPEN#   $      R RUN    INT    VERIFY  <                      ", //  4
    " 5 Лево  CYAN     CLOSE#  %      T RANDMZ RND    MERGE   >                      ", //  5
    " 6 Вниз  YELLOW   MOVE    &      Y RETURN STR$   [       AND                    ", //  6
    " 7 Вверх WHITE    ERASE   '      U IF     CHR$   ]       OR                     ", //  7
    " 8 Право UNBRIGHT POINT   (      I INPUT  CODE   IN      AT                     ", //  8
    " 9 GRAPH BRIGHT   CAT     )      O POKE   PEEK   OUT     ;                      ", //  9
    " 0 DEL   BLACK    FORMAT  _      P PRINT  TAB    (c)     \"                      ", // 10
    "   K     ED       ED+S    SS       K      ED     ED+S    SS                     ", // 11
    " A NEW   READ     ~       STOP   Z COPY   LN     BEEP    :                      ", // 12
    " S SAVE  RESTORE  |       NOT    X CLEAR  EXP    INK     Фунт                   ", // 13
    " D DIM   DATA     \\       STEP   C CONT   LPRINT PAPER   ?                      ", // 14
    " F FOR   SGN      {       TO     V CLS    LLIST  FLASH   /                      ", // 15
    " G GOTO  ABS      }       THEN   B BORDER BIN    BRIGHT  *                      ", // 16
    " H GOSUB SQR      CIRCLE  ^      N NEXT   INKEY$ OVER    ,                      ", // 17
    " J LOAD  VAL      VAL$    -      M PAUSE  PI     INVERSE .                      ", // 18
    " K LIST  LEN      SCREEN$ +                                                     ", // 19
    " L LET   USR      ATTR    =                                                     ", // 20
    "                                                                                ", // 21
    " CS - Левый шифт (caps)     ED = CS + SS                                        ", // 22
    " SS - Правый шифт (symbol)  ED+[0..9] Цвет фона                                 ", // 23
    "  S - Любой шифт            ED+CS+[0..9] Цвет букв                              ", // 24
];

$colors[2] = [
//             1         2         3         4         5         6         7
//   01234567890123456789012345678901234567890123456789012345678901234567890123456789
    "08888888888888888888888888888888888888888888888888888888888888888888888888888888", //  0
    " A                               A                                              ", //  1
    " A                               A                                              ", //  2
    " A                               A                                              ", //  3
    " A                               A                                              ", //  4
    " A                               A                                              ", //  5
    " A                               A                                              ", //  6
    " A                               A                                              ", //  7
    " A                               A                                              ", //  8
    " A                               A                                              ", //  9
    " A                               A                                              ", // 10
    "08888888888888888888888888888888888888888888888888888888888888888888888888888888", // 11
    " A                               A                                              ", // 12
    " A                               A                                              ", // 13
    " A                               A                                              ", // 14
    " A                               A                                              ", // 15
    " A                               A                                              ", // 16
    " A                               A                                              ", // 17
    " A                               A                                              ", // 18
    " A                               A                                              ", // 19
    " A                               A                                              ", // 20
    "                                                                                ", // 21
    " EE                         EE                                                  ", // 22
    " EE                         EEEEEEEEE                                           ", // 23
    " EE                         EEEEEEEEEEEEE                                       ", // 24
];
