module SharedTypes exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


constructing : a -> Decoder a
constructing =
    Json.Decode.succeed


type alias FieldInfo =
    { name : String
    , fieldType : String
    , placeholder : String
    }


type alias StringKeyValue =
    { name : String
    , value : String
    }


type alias PromoDetails =
    { promo : PromoInfo
    , affiliateId : String
    , affiliateEnabled : Bool
    }


type alias PromoInfo =
    { id : Maybe Int
    , isEnabled : Bool
    , goal : String
    , promoType : String
    , placement : String
    , pushPage : Bool
    , headline : String
    , button : String
    , displayDelaySeconds : Float
    , wiggleButton : Bool
    , bgColor : String
    , textColor : String
    , textFont : String
    , buttonColor : String
    , buttonBgColor : String
    , buttonFont : String
    , hideCookieDuration : Int
    , successCookieDuration : Int
    , positionFixed : Bool
    , linkUrl : String
    , openLinkNewWindow : Bool
    , emailPlaceholder : String
    , namePlaceholder : String
    , leadListId : Int
    , thankYouMessage : String
    , conditionPage : String
    , conditionPageUrl : String
    , conditionDeviceDesktop : Bool
    , conditionDeviceTablet : Bool
    , conditionDeviceMobile : Bool
    , body : String
    , close : String
    , animate : Bool
    , size : String
    , borderColor : String
    , borderWidth : Float
    , emailProvider : String
    , customFormBody : String
    , nameFields : String
    , emailProviderListId : String
    , saveToOptinEngineLeads : Bool
    , disableDoubleOptin : Bool
    , firstNamePlaceholder : String
    , lastNamePlaceholder : String
    , name : String
    , formFieldOrientation : String
    , formOrientation : String
    , formBgColor : String
    , inputBgColor : String
    , inputBorderColor : String
    , inputBorderWidth : Float
    , inputTextClass : String
    , inputBorderRadius : Float
    , imageUrl : String
    , imagePosition : String
    , borderType : String
    , borderPosition : String
    , thankYouBody : String
    , closeButtonAction : String
    , closeButtonUrl : String
    , closeButtonNewWindow : Bool
    }


type alias FormField =
    { name : String
    , fieldType : String
    , mapping : String
    , value : String
    }


decodeFieldInfo : Decoder FieldInfo
decodeFieldInfo =
    decode FieldInfo
        |> required "name" string
        |> required "fieldType" string
        |> required "placeholder" string


decodeFormField : Decoder FormField
decodeFormField =
    decode FormField
        |> required "name" string
        |> required "fieldType" string
        |> required "mapping" string
        |> required "value" string


decodeStringKeyValue : Decoder StringKeyValue
decodeStringKeyValue =
    decode StringKeyValue
        |> required "name" string
        |> required "value" string


decodePromoInfo : Decoder PromoInfo
decodePromoInfo =
    decode PromoInfo
        |> required "id" (maybe int)
        |> optional "isEnabled" bool False
        |> optional "goal" string "email"
        |> optional "promoType" string "slider"
        |> optional "placement" string "top"
        |> optional "pushPage" bool False
        |> optional "headline" string "Signup to our newsletter"
        |> optional "button" string "SIGNUP"
        |> optional "displayDelaySeconds" float 5
        |> optional "wiggleButton" bool True
        |> optional "bgColor" string "#ffffff"
        |> optional "textColor" string "#333333"
        |> optional "textFont" string "Open Sans"
        |> optional "buttonColor" string "#fff"
        |> optional "buttonBgColor" string "#a153e0"
        |> optional "buttonFont" string "Open Sans"
        |> optional "hideCookieDuration" int 30
        |> optional "successCookieDuration" int 30
        |> optional "positionFixed" bool True
        |> optional "linkUrl" string ""
        |> optional "openLinkNewWindow" bool True
        |> optional "emailPlaceholder" string "Email"
        |> optional "namePlaceholder" string "Name"
        |> optional "leadListId" int 0
        |> optional "thankYouMessage" string "Thank you"
        |> optional "conditionPage" string "all"
        |> optional "conditionPageUrl" string "/"
        |> optional "conditionDeviceDesktop" bool True
        |> optional "conditionDeviceTablet" bool True
        |> optional "conditionDeviceMobile" bool True
        |> optional "body" string ""
        |> optional "close" string "Close"
        |> optional "animate" bool True
        |> optional "size" string "medium"
        |> optional "borderColor" string "#fff"
        |> optional "borderWidth" float 1
        |> optional "emailProvider" string "optinengine"
        |> optional "customFormBody" string ""
        |> optional "nameFields" string "single"
        |> optional "emailProviderListId" string ""
        |> optional "saveToOptinEngineLeads" bool True
        |> optional "disableDoubleOptin" bool False
        |> optional "firstNamePlaceholder" string "First name"
        |> optional "lastNamePlaceholder" string "Last name"
        |> optional "name" string ""
        |> optional "formFieldOrientation" string "stacked"
        |> optional "formOrientation" string "bottom"
        |> optional "formBgColor" string "#ededed"
        |> optional "inputBgColor" string "#ffffff"
        |> optional "inputBorderColor" string "#eee"
        |> optional "inputBorderWidth" float 1
        |> optional "inputTextClass" string "dark"
        |> optional "inputBorderRadius" float 2
        |> optional "imageUrl" string ""
        |> optional "imagePosition" string "none"
        |> optional "borderType" string "solid"
        |> optional "borderPosition" string "all"
        |> optional "thankYouBody" string ""
        |> optional "closeButtonAction" string "close"
        |> optional "closeButtonUrl" string "/"
        |> optional "closeButtonNewWindow" bool True
