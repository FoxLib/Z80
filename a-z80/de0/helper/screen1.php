<?php

$screen[1] = [
//             1         2         3         4         5         6         7
//   01234567890123456789012345678901234567890123456789012345678901234567890123456789
    "         Январь              Февраль             Март              Апрель       ", //  0
    " Пн     4 11 18 25     |  1  8 15 22     |  1  8 15 22 29  |     5 12 19 26     ", //  1
    " Вт     5 12 19 26     |  2  9 16 23     |  2  9 16 23 30  |     6 13 20 27     ", //  2
    " Ср     6 13 20 27     |  3 10 17 24     |  3 10 17 24 31  |     7 14 21 28     ", //  3
    " Чт     7 14 21 28     |  4 11 18 25     |  4 11 18 25     |  1  8 15 22 29     ", //  4
    " Пт  1  8 15 22 39     |  5 12 19 26     |  5 12 19 26     |  2  9 16 23 30     ", //  5
    " Сб  2  9 16 23 30     |  6 13 20 27     |  6 13 20 27     |  3 10 17 24        ", //  6
    " Вс  3 10 17 24 31     |  7 14 21 28     |  7 14 21 28     |  4 11 18 25        ", //  7
    "           Май                Июнь                Июль             Август       ", //  8
    " Пн     3 10 17 24 31  |     7 14 21 28  |     5 12 19 26  |     2  9 16 23 30  ", //  9
    " Вт     4 11 18 25     |  1  8 15 22 29  |     6 13 20 27  |     3 10 17 24 31  ", // 10
    " Ср     5 12 19 26     |  2  9 16 23 30  |     7 14 21 28  |     4 11 18 25     ", // 11
    " Чт     6 13 20 27     |  3 10 17 24     |  1  8 15 22 29  |     5 12 19 26     ", // 12
    " Пт     7 14 21 28     |  4 11 18 25     |  2  9 16 23 30  |     6 13 20 27     ", // 13
    " Сб  1  8 15 22 29     |  5 12 19 26     |  3 10 17 24 31  |     7 14 21 28     ", // 14
    " Вс  2  9 16 23 30     |  6 13 20 27     |  4 11 18 25     |  1  8 15 22 29     ", // 15
    "         Сентябрь            Октябрь            Ноябрь             Декабрь      ", // 16
    " Пн     6 13 20 27     |     4 11 18 25  |  1  8 15 22 29  |     6 13 20 27 ^__^", // 17
    " Вт     7 14 21 28     |     5 12 19 26  |  2  9 16 23 30  |     7 14 21 28 (oo)", // 18
    " Ср  1  8 15 22 29     |     6 13 20 27  |  3 10 17 24     |  1  8 15 22 29 (__)", // 19
    " Чт  2  9 16 23 30     |     7 14 21 28  |  4 11 18 25     |  2  9 16 23 30   ||", // 20
    " Пт  3 10 17 24        |  1  8 15 22 29  |  5 12 19 26     |  3 10 17 24 31   ||", // 21
    " Сб  4 11 18 25        |  2  9 16 23 30  |  6 13 20 27     |  4 11 18 25        ", // 22
    " Вс  5 12 19 26        |  3 10 17 24 31  |  7 14 21 28     |  5 12 19 26   2021 ", // 23
    "                                                                          Корова", // 24
];

$colors[1] = [
//             1         2         3         4         5         6         7
//   01234567890123456789012345678901234567890123456789012345678901234567890123456789
    "00AAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAA", //  0
    " 33 CC CC              8          CC     8    CC           8                    ", //  1
    " 33 CC CC              8          CC     8                 8                    ", //  2
    " 33 CC CC              8                 8                 8                    ", //  3
    " 33 CC CC              8                 8                 8                    ", //  4
    " 33 CC CC              8                 8                 8                    ", //  5
    " BBCCCCCCCCCCCCCCCCCCCC8CCCCCCC  CCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCCCCC", //  6
    " BBCCCCCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCCCCC", //  7
    " AAAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAA", //  8
    " 33    CC CC           8       CC        8                 8                    ", //  9
    " 33                    8                 8                 8                    ", // 10
    " 33                    8                 8                 8                    ", // 11
    " 33                    8                 8                 8                    ", // 12
    " 33                    8                 8                 8                    ", // 13
    " BBCCCCCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCCCCC", // 14
    " BBCCCCCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCCCCC", // 15
    " AAAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAA", // 16
    " 33                    8                 8                 8                8888", // 17
    " 33                    8                 8                 8                8888", // 18
    " 33                    8                 8                 8                8888", // 19
    " 33                    8                 8 CC              8                8888", // 20
    " 33                    8                 8                 8             CC 8888", // 21
    " BBCCCCCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCCCCC", // 22
    " BBCCCCCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCCCC8CCCCCCCCCCCCCCAAAAAA", // 23
    "                                                                          222222", // 24
];
