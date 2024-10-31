module Utils.String exposing (interpolate, isEmail, replace)

{-| String.Interpolate provides a convenient method `interpolate` for injecting
values into a string. This can be useful for i18n of apps and construction of
complex strings in views.
@docs interpolate
-}

{- https://github.com/lukewestby/elm-string-interpolate/blob/master/src/String/Interpolate.elm -}

import String exposing (dropLeft, dropRight, toInt)
import Array exposing (Array, fromList, get)
import Regex exposing (replace, regex, Match, Regex, contains, caseInsensitive)


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


isEmail : String -> Bool
isEmail email =
    let
        check =
            regex "^[-a-z0-9~!$%^&*_=+}{\\'?]+(\\.[-a-z0-9~!$%^&*_=+}{\\'?]+)*@([a-z0-9_][-a-z0-9_]*(\\.[-a-z0-9_]+)*\\.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])|([0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}))(:[0-9]{1,5})?$"
    in
        contains (caseInsensitive check) email


replace : String -> String -> String -> String
replace from to str =
    String.split from str
        |> String.join to
