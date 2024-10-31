module Utils.Types exposing (..)

import Http
import SharedTypes exposing (..)


type alias Empty =
    {}


type alias ApiEmptyMsg a =
    Http.Response Empty -> a


type alias ApiErrorInfo =
    { error : String }


type alias ApiErrorMsg a =
    Http.Error ApiErrorInfo -> a


type alias BootData =
    { promos : List PromoInfo
    , leadCount : Int
    , emailProviders : List ProviderInfo
    , userEmail : String
    , userFirstName : String
    , userLastName : String
    , affiliateId : String
    , affiliateEnabled : Bool
    , loggingEnabled : Bool
    }


type alias PromoId =
    { promoId : Int }


type alias ProviderInfo =
    { id : Int
    , provider : String
    , name : String
    , lists : List ProviderList
    }


type alias ProviderList =
    { identifier : String
    , name : String
    , subscribers : Int
    }


type alias ColorUpdate =
    { variable : String
    , color : String
    }


type alias Lead =
    { id : Int
    , name : String
    , email : String
    , createdAt : String
    , lastName : String
    }


type alias LeadResults =
    { leads : List Lead
    , hasMore : Bool
    }


type alias FormInfo =
    { method : String
    , action : String
    , fields : List FormField
    }


type alias PromoTemplate =
    { image : String
    , name : String
    , description : String
    , tags : List String
    , promo : PromoInfo
    , theme : String
    }
