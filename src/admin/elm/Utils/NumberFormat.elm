module Utils.NumberFormat exposing (..)

{-|
https://github.com/elm-community/elm-number-format/blob/master/src/Number/Format.elm
-}

import String exposing (..)
import List


{-| Split string into smaller strings of length `k`, starting from the left.
    chunksOfLeft 3 "abcdefgh" == ["abc", "def", "gh"]
-}
chunksOfLeft : Int -> String -> List String
chunksOfLeft k s =
    let
        len =
            length s
    in
        if len > k then
            left k s :: chunksOfLeft k (dropLeft k s)
        else
            [ s ]


{-| Split string into smaller strings of length `k`, starting from the right.
    chunksOfRight 3 "abcdefgh" == ["ab", "cde", "fgh"]
-}
chunksOfRight : Int -> String -> List String
chunksOfRight k s =
    let
        len =
            length s

        k2 =
            2 * k

        chunksOfR s_ =
            if length s_ > k2 then
                right k s_ :: chunksOfR (dropRight k s_)
            else
                right k s_ :: [ dropRight k s_ ]
    in
        if len > k2 then
            List.reverse (chunksOfR s)
        else if len > k then
            dropRight k s :: [ right k s ]
        else
            [ s ]


withThousands : Float -> String
withThousands val =
    prettyInt ',' (floor val)


withThousandsIfFloat : String -> String
withThousandsIfFloat val =
    case String.toFloat val of
        Ok flt ->
            withThousands flt

        Err msg ->
            val


{-| A (de facto?) standard pretty formatting for numbers.
    pretty 2 ',' '.' 81601710123.338023  == "81,601,710,123.34"
    pretty 3 ' ' '.' 81601710123.338023  == "81 601 710 123.338"
    pretty 3 ' ' '.' -81601710123.338023 == "-81 601 710 123.34"
* Numbers are rounded to the nearest printable digit
* Digits before the decimal are grouped into spans of three and separated by a seperator character
-}
pretty : Int -> Char -> Char -> Float -> String
pretty decimals sep ds n =
    let
        decpow =
            10 ^ decimals

        nshift =
            n * Basics.toFloat decpow

        nshifti =
            round nshift

        nshifti_ =
            abs nshifti

        ni =
            nshifti_ // decpow

        nf =
            nshifti_ - ni * decpow

        nfs =
            toString nf

        nflen =
            String.length nfs
    in
        String.append
            (if nshifti < 0 then
                prettyInt sep -ni
             else
                prettyInt sep ni
            )
            (String.cons ds (String.padLeft decimals '0' nfs))


{-| A (de facto?) standard pretty formatting for numbers.
This version of the function operates on integers instead of floating point values.
In future `pretty` may be used on both integers as well as floating point values and this function
will be deprecated.
    prettyInt ',' 81601710123  == "81,601,710,123"
    prettyInt ' ' 81601710123  == "81 601 710 123"
    prettyInt ' ' -81601710123 == "-81 601 710 123"
* Digits are grouped into spans of three and separated by a seperator character
-}
prettyInt : Char -> Int -> String
prettyInt sep n =
    let
        ni =
            abs n

        nis =
            String.join (String.fromChar sep) (chunksOfRight 3 <| toString ni)
    in
        if n < 0 then
            String.cons '-' nis
        else
            nis


formatRatio : Float -> Float -> String
formatRatio val1 val2 =
    let
        rate =
            if val1 > 0 && val2 > 0 then
                ((val1) / (val2) * 100)
            else
                0
    in
        (pretty 2 ',' '.' rate) ++ " %"
