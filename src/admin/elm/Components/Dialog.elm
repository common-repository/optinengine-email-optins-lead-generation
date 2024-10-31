module Components.Dialog exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Css exposing (..)


styles : List Mixin -> Attribute a
styles =
    Css.asPairs >> Html.Attributes.style


type alias Model =
    { isOpen : Bool
    , size : String
    }


initial : String -> Model
initial size =
    { isOpen = False
    , size = size
    }


type Msg
    = Close


view : Model -> Html m -> Html m
view model contents =
    if model.isOpen then
        div
            [ Html.Attributes.class "modal fade in"
            , style [ ( "z-index", "200000" ) ]
            , styles
                [ display block
                , backgroundColor (rgba 0 0 0 0.4)
                ]
            ]
            [ div
                [ Html.Attributes.class ("modal-dialog " ++ model.size)
                , style
                    [ ( "max-height", "80%" )
                    , ( "overflow-y", "auto" )
                    ]
                ]
                [ div
                    [ Html.Attributes.class "modal-content" ]
                    [ contents
                    ]
                ]
            ]
    else
        div [] []


close : Model -> Model
close model =
    { model | isOpen = False }


show : Model -> Model
show model =
    { model | isOpen = True }
