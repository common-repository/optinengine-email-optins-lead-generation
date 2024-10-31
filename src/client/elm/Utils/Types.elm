module Utils.Types exposing (..)

import Dict as Dict
import Http
import SharedTypes exposing (..)


type alias Empty =
    {}


type alias HidePromoInfo =
    { promoId : Int
    , duration : Int
    }


type alias ApiEmptyMsg a =
    Http.Response Empty -> a


type alias ApiErrorInfo =
    { errors : Dict.Dict String (List String) }


type alias ApiErrorMsg a =
    Http.Error ApiErrorInfo -> a


type alias PromoResponse =
    { promo : Maybe PromoInfo
    , affiliateId : String
    , affiliateEnabled : Bool
    }


type alias RedirectInfo =
    { url : String
    , newWindow : Bool
    }
