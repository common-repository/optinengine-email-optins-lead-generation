port module Ports exposing (..)

import Utils.Types exposing (..)
import SharedTypes exposing (..)


port setTopMargin : Float -> Cmd msg


port setBottomMargin : Float -> Cmd msg


port setPromoHidden : HidePromoInfo -> Cmd msg


port loadFonts : List String -> Cmd msg


port setPromo : (PromoDetails -> msg) -> Sub msg


port hidePromo : (Int -> msg) -> Sub msg


port addElementToDom : Bool -> Cmd msg


port resetMargins : () -> Cmd msg


port redirectToUrl : RedirectInfo -> Cmd msg


port showThankyou : (Bool -> msg) -> Sub msg
