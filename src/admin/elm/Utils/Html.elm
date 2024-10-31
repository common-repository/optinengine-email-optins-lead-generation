module Utils.Html exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, style, type_, attribute, checked)
import Html.Events exposing (onClick, on, targetValue)
import Json.Decode as Json
import String
import Css


checkbox : msg -> String -> Bool -> List (Attribute msg) -> Html msg
checkbox msg name isChecked containerAttribs =
    let
        attribs =
            [ type_ "checkbox"
            , class "form-control"
            , onClick msg
            , Html.Attributes.checked isChecked
            ]
    in
        div
            (class "form-group" :: containerAttribs)
            [ div
                [ class "checkbox checkbox-primary" ]
                [ input
                    attribs
                    []
                , label [] [ Html.text name ]
                ]
            ]


switch : msg -> String -> Bool -> List (Attribute msg) -> Html msg
switch msg name isChecked containerAttribs =
    let
        onAttribs =
            if isChecked then
                [ class "checked" ]
            else
                [ onClick msg ]

        offAttribs =
            if isChecked then
                [ onClick msg ]
            else
                [ class "checked" ]
    in
        span
            [ class "flex-switch" ]
            [ div [ class "switcher" ]
                [ div onAttribs [ text "Yes" ]
                , div offAttribs [ text "No" ]
                ]
            , div [] [ label [] [ text name ] ]
            ]


maybeIntDecoder : Json.Decoder (Maybe Int)
maybeIntDecoder =
    targetValue
        |> Json.andThen
            (\val ->
                case String.toInt val of
                    Ok i ->
                        Json.succeed (Just i)

                    Err err ->
                        Json.succeed Nothing
            )


maybeFloatDecoder : Json.Decoder (Maybe Float)
maybeFloatDecoder =
    targetValue
        |> Json.andThen
            (\val ->
                case String.toFloat val of
                    Ok i ->
                        Json.succeed (Just i)

                    Err err ->
                        Json.succeed Nothing
            )


onSelectChangeString : (String -> msg) -> Attribute msg
onSelectChangeString onChange =
    on "change" <| Json.map onChange <| Json.at [ "target", "value" ] Json.string


onSelectChangeMaybeString : (Maybe String -> msg) -> Attribute msg
onSelectChangeMaybeString onChange =
    on "change" <| Json.map onChange <| Json.at [ "target", "value" ] (Json.maybe Json.string)


onSelectChangeMaybeInt : (Maybe Int -> msg) -> Attribute msg
onSelectChangeMaybeInt onChange =
    on "change" (Json.map onChange maybeIntDecoder)


onSelectChangeMaybeFloat : (Maybe Float -> msg) -> Attribute msg
onSelectChangeMaybeFloat onChange =
    on "change" (Json.map onChange maybeFloatDecoder)


styles : List Css.Mixin -> Attribute a
styles =
    Css.asPairs >> Html.Attributes.style


hideIfFalse : Bool -> Attribute a
hideIfFalse condition =
    if not condition then
        styles [ Css.display Css.none ]
    else
        styles []


hideIfTrue : Bool -> Attribute a
hideIfTrue condition =
    hideIfFalse (not condition)


disableIfFalse : Bool -> Attribute a
disableIfFalse condition =
    if not condition then
        style
            [ ( "opacity", "0.3" )
            , ( "pointer-events", "none" )
            ]
    else
        style []
