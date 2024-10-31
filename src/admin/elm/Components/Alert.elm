module Components.Alert exposing (..)

import Css
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Utils.Html


styles : List Css.Mixin -> Attribute a
styles =
    Css.asPairs >> Html.Attributes.style


type alias Message =
    { header : String
    , messages : List String
    , body : String
    }


type alias MessageList =
    List Message


type alias Model =
    { messages : Maybe MessageList
    }


initial : Model
initial =
    { messages = Nothing
    }


type Msg
    = Close


view : Model -> Html Msg
view model =
    case model.messages of
        Just messages ->
            let
                submessage m =
                    div [] [ Html.text m ]

                message m =
                    div []
                        [ h3
                            [ styles [ Css.margin Css.zero, Css.marginBottom (Css.px 5) ] ]
                            [ Html.text (m.header) ]
                        , p
                            [ class "alert-message"
                            , Utils.Html.hideIfTrue ((String.length m.body == 0))
                            ]
                            [ Html.text m.body ]
                        , div [ class "m-b-10" ] (List.map submessage m.messages)
                        ]
            in
                div
                    [ class "modal"
                    , style [ ( "z-index", "200000" ) ]
                    , styles
                        [ Css.display Css.block
                        , Css.backgroundColor (Css.rgba 0 0 0 0.4)
                        ]
                    ]
                    [ div
                        [ class "modal-dialog" ]
                        [ div
                            [ class "modal-content" ]
                            [ div
                                []
                                [ div [] (List.map message messages)
                                , div
                                    []
                                    [ div
                                        [ class "btn btn-success m-r-5"
                                        , onClick (Close)
                                        ]
                                        [ Html.text "OK" ]
                                    ]
                                ]
                            ]
                        ]
                    ]

        Nothing ->
            div [] []


update : Msg -> Model -> Model
update msg model =
    case msg of
        Close ->
            { model
                | messages = Nothing
            }


close : Model -> Model
close model =
    { model | messages = Nothing }


show : Model -> String -> String -> Model
show model message body =
    { model | messages = Just [ Message message [] body ] }


show2 : Model -> MessageList -> Model
show2 model messages =
    { model | messages = Just messages }
