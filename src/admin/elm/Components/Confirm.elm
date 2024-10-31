module Components.Confirm exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Css


styles : List Css.Mixin -> Attribute a
styles =
    Css.asPairs >> Html.Attributes.style


type alias Question questionType =
    { type_ : questionType
    , text : String
    }


type alias Model questionType =
    { question : Maybe (Question questionType)
    }


initial : Model questionType
initial =
    { question = Nothing
    }


type Msg questionType
    = Open questionType String


view : Model questionType -> (questionType -> m) -> (questionType -> m) -> Html m
view model confirmYes confirmNo =
    case model.question of
        Just question ->
            div
                [ class "modal fade in"
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
                            [ h3 [ styles [ Css.margin Css.zero, Css.marginBottom (Css.px 5) ] ] [ Html.text question.text ]
                            , div
                                [ class "m-t-10" ]
                                [ div
                                    [ class "btn btn-success m-r-5"
                                    , onClick (confirmYes question.type_)
                                    ]
                                    [ Html.text "Yes" ]
                                , div
                                    [ class "btn btn-danger"
                                    , onClick (confirmNo question.type_)
                                    ]
                                    [ Html.text "No" ]
                                ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            div [] []


update : Msg questionType -> Model questionType -> Model questionType
update msg model =
    case msg of
        Open type_ text ->
            { model
                | question =
                    Just
                        (Question
                            type_
                            text
                        )
            }


askOnClick : (Msg questionType -> msg) -> questionType -> String -> Html.Attribute msg
askOnClick confirmMsg type_ text =
    onClick
        (confirmMsg
            (Open
                type_
                text
            )
        )


close : Model questionType -> Model questionType
close model =
    { model | question = Nothing }
