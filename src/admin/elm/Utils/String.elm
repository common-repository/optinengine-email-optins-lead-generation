module Utils.String exposing (..)

import String exposing (dropLeft, dropRight, toInt, split, join)
import Array exposing (Array, fromList, get)
import Regex exposing (replace, regex, Match, Regex, contains, caseInsensitive)


replace : String -> String -> String -> String
replace from to str =
    split from str
        |> join to



{- https://github.com/lukewestby/elm-string-interpolate/blob/master/src/String/Interpolate.elm -}


{-| Inject other strings into a string in the order they appear in a List
  interpolate "{0} {2} {1}" ["hello", "!!", "world"]
  "{0} {2} {1}" `interpolate` ["hello", "!!", "world"]
-}
interpolate : String -> List String -> String
interpolate string args =
    let
        asArray =
            fromList args
    in
        Regex.replace Regex.All interpolationRegex (applyInterpolation asArray) string


interpolationRegex : Regex
interpolationRegex =
    regex "\\{\\d+\\}"


applyInterpolation : Array String -> Match -> String
applyInterpolation replacements match =
    let
        ordinalString =
            ((dropLeft 1) << (dropRight 1)) match.match

        ordinal =
            toInt ordinalString
    in
        case ordinal of
            Err message ->
                ""

            Ok value ->
                case get value replacements of
                    Nothing ->
                        ""

                    Just replacement ->
                        replacement
