module Utils.Html exposing (..)

import Css exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, style, attribute)


styles : List Mixin -> Attribute a
styles =
    Css.asPairs >> Html.Attributes.style


hideIfFalse : Bool -> Attribute a
hideIfFalse condition =
    if not condition then
        styles [ display none ]
    else
        styles []


hideIfTrue : Bool -> Attribute a
hideIfTrue condition =
    hideIfFalse (not condition)


fontStyle : String -> Attribute a
fontStyle font =
    style
        [ ( "font-family", font ) ]


disableIfFalse : Bool -> Attribute a
disableIfFalse condition =
    if not condition then
        style
            [ ( "opacity", "0.5" )
            , ( "pointer-events", "none" )
            ]
    else
        style []


disableIfTrue : Bool -> Attribute a
disableIfTrue condition =
    disableIfFalse (not condition)
