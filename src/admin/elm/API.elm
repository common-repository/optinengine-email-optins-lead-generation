module API exposing (..)

import Http
import HttpBuilder exposing (..)
import SharedTypes exposing (..)
import Time
import Utils.Decoders exposing (..)
import Utils.Types exposing (..)


addMaybeIntParam : String -> Maybe Int -> List ( String, String ) -> List ( String, String )
addMaybeIntParam name val lst =
    case val of
        Just v ->
            ( name, (toString v) ) :: lst

        Nothing ->
            lst


addMaybeStringParam : String -> Maybe String -> List ( String, String ) -> List ( String, String )
addMaybeStringParam name val lst =
    case val of
        Just v ->
            ( name, v ) :: lst

        Nothing ->
            lst


getBootData : String -> (Result Http.Error BootData -> a) -> Cmd a
getBootData api onComplete =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_boot" ) ])
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeBootData)
        |> withCredentials
        |> send onComplete


updatePromo : String -> (Result Http.Error PromoId -> a) -> PromoInfo -> Cmd a
updatePromo api onComplete promo =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_update_promo" )
             , ( "spec", (encodePromoInfo promo) )
             ]
                |> (addMaybeIntParam "id" promo.id)
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodePromoId)
        |> withCredentials
        |> send onComplete


deletePromo : String -> (Result Http.Error Empty -> a) -> Int -> Cmd a
deletePromo api onComplete id =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_delete_promo" )
             , ( "id", (toString id) )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


emptyLeadList : String -> (Result Http.Error Empty -> a) -> Cmd a
emptyLeadList api onComplete =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_empty_lead_list" )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


listLeads : String -> (Result Http.Error LeadResults -> a) -> Maybe Int -> Cmd a
listLeads api onComplete lastId =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_get_leads" )
             , ( "last_id"
               , (case lastId of
                    Just val ->
                        (toString val)

                    _ ->
                        ""
                 )
               )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeLeadResults)
        |> withCredentials
        |> send onComplete


deleteLead : String -> (Result Http.Error Empty -> a) -> Int -> Cmd a
deleteLead api onComplete id =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_delete_lead" )
             , ( "id", (toString id) )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


registerMailChimpAccount : String -> (Result Http.Error Empty -> a) -> String -> String -> Cmd a
registerMailChimpAccount api onComplete accountName apiKey =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_register_mailchimp_account" )
             , ( "account_name", accountName )
             , ( "api_key", apiKey )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


refreshProviderLists : String -> (Result Http.Error Empty -> a) -> Int -> Cmd a
refreshProviderLists api onComplete providerId =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_refresh_provider_lists" )
             , ( "provider_id", (toString providerId) )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


deleteEmailProvider : String -> (Result Http.Error Empty -> a) -> Int -> Cmd a
deleteEmailProvider api onComplete providerId =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_delete_email_provider" )
             , ( "provider_id", (toString providerId) )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


registerGetResponseAccount : String -> (Result Http.Error Empty -> a) -> String -> String -> Cmd a
registerGetResponseAccount api onComplete accountName apiKey =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_register_getresponse_account" )
             , ( "account_name", accountName )
             , ( "api_key", apiKey )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


registerAweberAccount : String -> (Result Http.Error Empty -> a) -> String -> String -> Cmd a
registerAweberAccount api onComplete accountName apiKey =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_register_aweber_account" )
             , ( "account_name", accountName )
             , ( "api_key", apiKey )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


registerDripAccount : String -> (Result Http.Error Empty -> a) -> String -> String -> String -> Cmd a
registerDripAccount api onComplete accountName accountId apiKey =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_register_drip_account" )
             , ( "account_name", accountName )
             , ( "account_id", accountId )
             , ( "api_key", apiKey )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


registerCampaignMonitorAccount : String -> (Result Http.Error Empty -> a) -> String -> String -> Cmd a
registerCampaignMonitorAccount api onComplete accountName apiKey =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_register_campaignmonitor_account" )
             , ( "account_name", accountName )
             , ( "api_key", apiKey )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


registerIntercomAccount : String -> (Result Http.Error Empty -> a) -> String -> String -> Cmd a
registerIntercomAccount api onComplete accountName apiKey =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_register_intercom_account" )
             , ( "account_name", accountName )
             , ( "api_key", apiKey )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


registerActiveCampaignAccount : String -> (Result Http.Error Empty -> a) -> String -> String -> String -> Cmd a
registerActiveCampaignAccount api onComplete accountName apiKey apiUrl =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_register_activecampaign_account" )
             , ( "account_name", accountName )
             , ( "api_key", apiKey )
             , ( "api_url", apiUrl )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


updateAffiliateSettings : String -> (Result Http.Error Empty -> a) -> String -> Bool -> Cmd a
updateAffiliateSettings api onComplete affiliateId affiliateEnabled =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_update_affiliate_settings" )
             , ( "affiliate_id", affiliateId )
             , ( "affiliate_enabled"
               , (if affiliateEnabled == True then
                    "1"
                  else
                    "0"
                 )
               )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete


updateLoggingSettings : String -> (Result Http.Error Empty -> a) -> Bool -> Cmd a
updateLoggingSettings api onComplete enabled =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_update_logging_settings" )
             , ( "logging_enabled"
               , (if enabled == True then
                    "1"
                  else
                    "0"
                 )
               )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete
