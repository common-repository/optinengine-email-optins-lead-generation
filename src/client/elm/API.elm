module API exposing (..)

import Http
import HttpBuilder exposing (..)
import Time
import Utils.Decoders exposing (..)
import Utils.Types exposing (..)


getPromo : String -> (Result Http.Error PromoResponse -> a) -> String -> String -> Cmd a
getPromo api onComplete pageType url =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_get_promo" )
             , ( "page_type", pageType )
             , ( "url", url )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodePromoResponse)
        |> withCredentials
        |> send onComplete


addLead : String -> (Result Http.Error Empty -> a) -> Int -> Int -> String -> String -> String -> Cmd a
addLead api onComplete promoId listId name lastName email =
    HttpBuilder.post api
        |> withMultipartStringBody
            ([ ( "action", "optinengine_add_lead" )
             , ( "promo_id", (toString promoId) )
             , ( "list_id", (toString listId) )
             , ( "name", name )
             , ( "last_name", lastName )
             , ( "email", email )
             ]
            )
        |> withTimeout (10 * Time.second)
        |> withExpect (Http.expectJson decodeEmpty)
        |> withCredentials
        |> send onComplete
