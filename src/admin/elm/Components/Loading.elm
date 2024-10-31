module Components.Loading exposing (..)

import Css exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, style)


styles : List Mixin -> Attribute a
styles =
    Css.asPairs >> Html.Attributes.style


type Msg
    = Noop


view : Html Msg
view =
    div
        [ Html.Attributes.class "flex-spinner" ]
        [ div [ Html.Attributes.class "double-bounce1" ] []
        , div [ Html.Attributes.class "double-bounce2" ] []
        ]


viewFull : Html Msg
viewFull =
    div
        [ Html.Attributes.class "modal fade in"
        , style [ ( "z-index", "200000" ) ]
        , styles
            [ display block
            , backgroundColor (rgba 0 0 0 0.4)
            , paddingTop (px 200)
            ]
        ]
        [ view
        ]
