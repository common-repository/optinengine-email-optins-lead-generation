port module Ports exposing (..)

import Utils.Types exposing (..)
import SharedTypes exposing (..)


port doSomething : Float -> Cmd msg


port setPromo : PromoDetails -> Cmd msg


port updateColor : (ColorUpdate -> msg) -> Sub msg


port redirect : String -> Cmd msg


port enableBodyScroll : Bool -> Cmd msg


port parseForm : String -> Cmd msg


port parsedFormInfo : (FormInfo -> msg) -> Sub msg


port openAuthPopup : String -> Cmd msg


port setTemplates : (List PromoTemplate -> msg) -> Sub msg


port setHeadline : String -> Cmd msg


port updateBodyHtml : (String -> msg) -> Sub msg


port updateHeadlineHtml : (String -> msg) -> Sub msg


port pickImageFromMedia : () -> Cmd msg


port pickImageFromMediaResult : (String -> msg) -> Sub msg


port updateThankYouHtml : (String -> msg) -> Sub msg


port updateThankYouBodyHtml : (String -> msg) -> Sub msg


port showThankyou : Bool -> Cmd msg
