module Utils.Decoders exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import SharedTypes exposing (..)
import Utils.Types exposing (..)


{-
   Decoding of larger objects
   https://gist.github.com/jamesmacaulay/c2badacb93b091489dd4
-}


decodeEmpty : Decoder Empty
decodeEmpty =
    (constructing Empty)


decodeApiError : Decoder ApiErrorInfo
decodeApiError =
    decode ApiErrorInfo
        |> required "error" string


decodeBootData : Decoder BootData
decodeBootData =
    decode BootData
        |> required "promos" (list decodePromoInfo)
        |> required "lead_count" int
        |> required "email_providers" (list decodeProviderInfo)
        |> required "user_email" string
        |> required "user_first_name" string
        |> required "user_last_name" string
        |> required "affiliate_id" string
        |> required "affiliate_enabled" bool
        |> required "logging_enabled" bool


decodeProviderInfo : Decoder ProviderInfo
decodeProviderInfo =
    decode ProviderInfo
        |> required "id" int
        |> required "provider" (oneOf [ string, Json.Decode.succeed "" ])
        |> required "name" (oneOf [ string, Json.Decode.succeed "" ])
        |> required "lists" (list decodeProviderList)


decodeProviderList : Decoder ProviderList
decodeProviderList =
    decode ProviderList
        |> required "identifier" string
        |> required "name" string
        |> required "subscribers" int


decodeLead : Decoder Lead
decodeLead =
    decode Lead
        |> required "id" int
        |> required "name" (oneOf [ string, Json.Decode.succeed "" ])
        |> required "email" string
        |> required "created_at" (oneOf [ string, Json.Decode.succeed "" ])
        |> required "last_name" (oneOf [ string, Json.Decode.succeed "" ])


decodeLeadResults : Decoder LeadResults
decodeLeadResults =
    decode LeadResults
        |> required "leads" (list decodeLead)
        |> required "has_more" bool


encodeStringKeyValue : StringKeyValue -> Value
encodeStringKeyValue kv =
    Encode.object
        [ ( "name", Encode.string kv.name )
        , ( "value", Encode.string kv.value )
        ]


encodeFormField : FormField -> Value
encodeFormField kv =
    Encode.object
        [ ( "name", Encode.string kv.name )
        , ( "fieldType", Encode.string kv.fieldType )
        , ( "mapping", Encode.string kv.mapping )
        , ( "value", Encode.string kv.value )
        ]


encodePromoInfo : PromoInfo -> String
encodePromoInfo promo =
    Encode.encode 2
        (Encode.object
            [ ( "isEnabled", Encode.bool promo.isEnabled )
            , ( "goal", Encode.string promo.goal )
            , ( "promoType", Encode.string promo.promoType )
            , ( "placement", Encode.string promo.placement )
            , ( "pushPage", Encode.bool promo.pushPage )
            , ( "headline", Encode.string promo.headline )
            , ( "button", Encode.string promo.button )
            , ( "displayDelaySeconds", Encode.float promo.displayDelaySeconds )
            , ( "wiggleButton", Encode.bool promo.wiggleButton )
            , ( "bgColor", Encode.string promo.bgColor )
            , ( "textColor", Encode.string promo.textColor )
            , ( "textFont", Encode.string promo.textFont )
            , ( "buttonColor", Encode.string promo.buttonColor )
            , ( "buttonBgColor", Encode.string promo.buttonBgColor )
            , ( "buttonFont", Encode.string promo.buttonFont )
            , ( "hideCookieDuration", Encode.int promo.hideCookieDuration )
            , ( "successCookieDuration", Encode.int promo.successCookieDuration )
            , ( "positionFixed", Encode.bool promo.positionFixed )
            , ( "linkUrl", Encode.string promo.linkUrl )
            , ( "openLinkNewWindow", Encode.bool promo.openLinkNewWindow )
            , ( "emailPlaceholder", Encode.string promo.emailPlaceholder )
            , ( "namePlaceholder", Encode.string promo.namePlaceholder )
            , ( "leadListId", Encode.int promo.leadListId )
            , ( "thankYouMessage", Encode.string promo.thankYouMessage )
            , ( "conditionPage", Encode.string promo.conditionPage )
            , ( "conditionPageUrl", Encode.string promo.conditionPageUrl )
            , ( "conditionDeviceDesktop", Encode.bool promo.conditionDeviceDesktop )
            , ( "conditionDeviceTablet", Encode.bool promo.conditionDeviceTablet )
            , ( "conditionDeviceMobile", Encode.bool promo.conditionDeviceMobile )
            , ( "body", Encode.string promo.body )
            , ( "close", Encode.string promo.close )
            , ( "animate", Encode.bool promo.animate )
            , ( "size", Encode.string promo.size )
            , ( "borderColor", Encode.string promo.borderColor )
            , ( "borderWidth", Encode.float promo.borderWidth )
            , ( "emailProvider", Encode.string promo.emailProvider )
            , ( "customFormBody", Encode.string promo.customFormBody )
            , ( "nameFields", Encode.string promo.nameFields )
            , ( "emailProviderListId", Encode.string promo.emailProviderListId )
            , ( "saveToOptinEngineLeads", Encode.bool promo.saveToOptinEngineLeads )
            , ( "disableDoubleOptin", Encode.bool promo.disableDoubleOptin )
            , ( "firstNamePlaceholder", Encode.string promo.firstNamePlaceholder )
            , ( "lastNamePlaceholder", Encode.string promo.lastNamePlaceholder )
            , ( "formFieldOrientation", Encode.string promo.formFieldOrientation )
            , ( "formOrientation", Encode.string promo.formOrientation )
            , ( "formBgColor", Encode.string promo.formBgColor )
            , ( "inputBgColor", Encode.string promo.inputBgColor )
            , ( "inputBorderColor", Encode.string promo.inputBorderColor )
            , ( "inputBorderWidth", Encode.float promo.inputBorderWidth )
            , ( "inputTextClass", Encode.string promo.inputTextClass )
            , ( "inputBorderRadius", Encode.float promo.inputBorderRadius )
            , ( "name", Encode.string promo.name )
            , ( "imageUrl", Encode.string promo.imageUrl )
            , ( "imagePosition", Encode.string promo.imagePosition )
            , ( "borderType", Encode.string promo.borderType )
            , ( "borderPosition", Encode.string promo.borderPosition )
            , ( "thankYouBody", Encode.string promo.thankYouBody )
            , ( "closeButtonAction", Encode.string promo.closeButtonAction )
            , ( "closeButtonUrl", Encode.string promo.closeButtonUrl )
            , ( "closeButtonNewWindow", Encode.bool promo.closeButtonNewWindow )
            ]
        )


decodePromoId : Decoder PromoId
decodePromoId =
    decode PromoId
        |> required "promo_id" int
