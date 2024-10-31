module Utils.Decoders exposing (..)

import Json.Decode exposing (..)
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
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
        |> required "errors" (dict (list string))


decodePromoResponse : Decoder PromoResponse
decodePromoResponse =
    decode PromoResponse
        |> required "promo" (maybe decodePromoInfo)
        |> required "affiliate_id" string
        |> required "affiliate_enabled" bool
