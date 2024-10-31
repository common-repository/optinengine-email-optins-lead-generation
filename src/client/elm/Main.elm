module Main exposing (..)

import API
import Css
import Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Json
import Ports
import SharedTypes exposing (..)
import String
import Task exposing (..)
import Utils.Html
import Utils.String
import Utils.Types exposing (..)
import Http


type Msg
    = NoOp
    | Show
    | Hide
    | PromoResponseData (Result Http.Error PromoResponse)
    | SetPromo PromoDetails
    | AddLead
    | EmailUpdated String
    | NameUpdated String
    | LeadAdded (Result Http.Error Empty)
    | HidePromo Int
    | LastNameUpdated String
    | Redirect RedirectInfo
    | ShowThankyou Bool
    | HideSuccess
    | FocusResult (Result Dom.Error ())


type alias Model =
    { promo : Maybe PromoInfo
    , isVisible : Bool
    , api : String
    , tools : String
    , name : String
    , email : String
    , leadAdded : Bool
    , isLoading : Bool
    , pageType : String
    , lastName : String
    , pluginPath : String
    , affiliateId : String
    , affiliateEnabled : Bool
    , forceShowThankyou : Bool
    }


type alias Flags =
    { api : String
    , tools : String
    , autoLoad : Bool
    , pageType : String
    , url : String
    , pluginPath : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        cmd =
            if flags.autoLoad && False then
                API.getPromo
                    flags.api
                    PromoResponseData
                    flags.pageType
                    flags.url
            else
                Cmd.none
    in
        ( { api = flags.api
          , tools = flags.tools
          , promo = Nothing
          , isVisible = False
          , name = ""
          , email = ""
          , leadAdded = False
          , isLoading = False
          , pageType = flags.pageType
          , lastName = ""
          , pluginPath = flags.pluginPath
          , affiliateId = ""
          , affiliateEnabled = False
          , forceShowThankyou = False
          }
        , cmd
        )


expandUrlPath : Model -> String -> String
expandUrlPath model url =
    Utils.String.replace "{FLEX_PLUGIN_URL}" model.pluginPath url


focusId : String -> Cmd Msg
focusId id =
    Dom.focus id |> Task.attempt FocusResult


buttonAction : Model -> PromoInfo -> Attribute Msg
buttonAction model promo =
    let
        promoId =
            (Maybe.withDefault 0 promo.id)
    in
        case promo.goal of
            "click" ->
                onClick
                    (Redirect
                        { url = (model.tools ++ "?action=optinengine-redirect&promo=" ++ (toString promoId))
                        , newWindow = promo.openLinkNewWindow
                        }
                    )

            "email" ->
                onClick AddLead

            _ ->
                href "#"


promoContent : Model -> PromoInfo -> Html Msg
promoContent model promo =
    let
        wiggleClass =
            if promo.wiggleButton then
                "wiggle"
            else
                ""

        emailClass =
            if String.length model.email == 0 || Utils.String.isEmail model.email then
                ""
            else
                "invalid"

        formBgColor =
            if promo.promoType == "bar" then
                []
            else
                [ Css.backgroundColor (Css.hex promo.formBgColor) ]

        inputStyles =
            Utils.Html.styles
                [ Css.backgroundColor (Css.hex promo.inputBgColor)
                , Css.fontFamilies [ promo.textFont ]
                , Css.border3 (Css.px promo.inputBorderWidth) Css.solid (Css.hex (promo.inputBorderColor))
                , Css.borderRadius (Css.px promo.inputBorderRadius)
                ]

        parseBody body =
            (String.split "\n" body)
                |> List.filter (\l -> String.length l > 0)
                |> List.map (\l -> p [] [ text l ])

        zigzagSeperator =
            [ ( "background"
              , Utils.String.interpolate
                    "linear-gradient(-45deg, transparent 16px, {0} 0), linear-gradient(45deg, transparent 16px, {0} 0)"
                    [ promo.bgColor ]
              )
            , ( "background-repeat", "repeat-x" )
            , ( "background-position", "left bottom" )
            , ( "background-size", "22px 32px" )
            , ( "content", "" )
            , ( "display", "block" )
            , ( "width", "100%" )
            , ( "height", "10px" )
            , ( "position", "absolute" )
            , ( "bottom", "-10px" )
            , ( "left", "0px" )
            ]

        curvedSeperator =
            []

        carrotSeperator =
            case promo.formOrientation of
                "right" ->
                    [ ( "height", "0" )
                    , ( "position", "absolute" )
                    , ( "width", "0" )
                    , ( "top", "45%" )
                    , ( "right", "-10px" )
                    , ( "border-top", "10px solid transparent" )
                    , ( "border-bottom", "10px solid transparent" )
                    , ( "border-left", "10px solid " ++ promo.bgColor )
                    ]

                "left" ->
                    [ ( "height", "0" )
                    , ( "position", "absolute" )
                    , ( "width", "0" )
                    , ( "top", "45%" )
                    , ( "left", "-10px" )
                    , ( "border-top", "10px solid transparent" )
                    , ( "border-bottom", "10px solid transparent" )
                    , ( "border-right", "10px solid " ++ promo.bgColor )
                    ]

                _ ->
                    [ ( "height", "0" )
                    , ( "position", "absolute" )
                    , ( "width", "0" )
                    , ( "top", "100%" )
                    , ( "left", "8px" )
                    , ( "border", "8px solid transparent" )
                    , ( "border-top-color", promo.bgColor )
                    , ( "top", "100%" )
                    , ( "left", "50%" )
                    , ( "margin-left", "-8px" )
                    ]

        seperatorStyles =
            []

        bodyContent =
            [ div
                [ Utils.Html.hideIfTrue
                    (promo.imagePosition
                        == "none"
                        || String.length promo.imageUrl
                        == 0
                        || promo.promoType
                        == "bar"
                    )
                , class ("flex-promo-image")
                ]
                [ img [ src (expandUrlPath model promo.imageUrl) ] [] ]
            , div [ class "flex-body-container" ]
                [ div [ class "flex-headline", property "innerHTML" (Json.string promo.headline) ] []
                , div [ class "flex-body", property "innerHTML" (Json.string promo.body) ] []
                ]
            ]

        bodyNeedsReverse =
            case promo.imagePosition of
                "below" ->
                    True

                "right" ->
                    True

                _ ->
                    False

        showThankyou =
            model.leadAdded || model.forceShowThankyou

        wrapperContent =
            [ div
                [ class "flex-content"
                , Utils.Html.fontStyle promo.textFont
                ]
                [ if showThankyou then
                    div
                        [ class "thankyou"
                        ]
                        [ div [ class "flex-body-container" ]
                            [ div [ class "flex-headline", property "innerHTML" (Json.string promo.thankYouMessage) ] []
                            , div [ class "flex-body", property "innerHTML" (Json.string promo.thankYouBody) ] []
                            ]
                        ]
                  else
                    div
                        [ class ("flex-promo-image-" ++ promo.imagePosition)
                        ]
                        (if bodyNeedsReverse then
                            List.reverse bodyContent
                         else
                            bodyContent
                        )
                , div [ style seperatorStyles ] []
                ]
            , div
                [ class ("flex-form flex-" ++ promo.formFieldOrientation)
                , Utils.Html.styles formBgColor
                ]
                [ div
                    [ Utils.Html.hideIfFalse (promo.goal == "email")
                    , Utils.Html.hideIfTrue showThankyou
                    , class "flex-fields"
                    ]
                    [ div [ Utils.Html.hideIfFalse (promo.nameFields == "single") ]
                        [ input
                            [ type_ "text"
                            , placeholder promo.namePlaceholder
                            , onInput NameUpdated
                            , Utils.Html.disableIfTrue model.isLoading
                            , value model.name
                            , inputStyles
                            , class promo.inputTextClass
                            ]
                            []
                        ]
                    , div [ Utils.Html.hideIfFalse (promo.nameFields == "firstlast") ]
                        [ input
                            [ type_ "text"
                            , placeholder promo.firstNamePlaceholder
                            , onInput NameUpdated
                            , Utils.Html.disableIfTrue model.isLoading
                            , value model.name
                            , inputStyles
                            , class promo.inputTextClass
                            ]
                            []
                        ]
                    , div [ Utils.Html.hideIfFalse (promo.nameFields == "firstlast") ]
                        [ input
                            [ type_ "text"
                            , placeholder promo.lastNamePlaceholder
                            , onInput LastNameUpdated
                            , Utils.Html.disableIfTrue model.isLoading
                            , value model.lastName
                            , inputStyles
                            , class promo.inputTextClass
                            ]
                            []
                        ]
                    , div []
                        [ input
                            [ type_ "text"
                            , placeholder promo.emailPlaceholder
                            , class emailClass
                            , onInput EmailUpdated
                            , Utils.Html.disableIfTrue model.isLoading
                            , id "optinengine-email-input"
                            , value model.email
                            , inputStyles
                            , class promo.inputTextClass
                            ]
                            []
                        ]
                    ]
                , span
                    [ Utils.Html.hideIfTrue showThankyou
                    , class (Utils.String.interpolate "flex-button {0}" [ wiggleClass ])
                    , Utils.Html.styles
                        [ Css.backgroundColor (Css.hex promo.buttonBgColor)
                        , Css.color (Css.hex promo.buttonColor)
                        , Css.borderRadius (Css.px promo.inputBorderRadius)
                        ]
                    , Utils.Html.fontStyle promo.buttonFont
                    , Utils.Html.disableIfTrue model.isLoading
                    , buttonAction model promo
                    ]
                    [ text promo.button ]
                , a
                    [ Utils.Html.hideIfFalse showThankyou
                    , class "flex-button"
                    , Utils.Html.styles
                        [ Css.backgroundColor (Css.hex promo.buttonBgColor)
                        , Css.color (Css.hex promo.buttonColor)
                        , Css.borderRadius (Css.px promo.inputBorderRadius)
                        ]
                    , onClick HideSuccess
                    , Utils.Html.fontStyle promo.buttonFont
                    ]
                    [ text promo.close ]
                ]
            ]
    in
        div
            [ Utils.Html.styles
                [ Css.backgroundColor (Css.hex promo.bgColor)
                , Css.color (Css.hex promo.textColor)
                ]
            , class ("flex-wrapper")
            ]
            [ div
                [ Utils.Html.styles
                    (if promo.promoType /= "bar" then
                        [ borderStyle promo ]
                     else
                        []
                    )
                , class "flex-border"
                ]
                {- Reverse the contents if we should display the form on the left -}
                (if promo.formOrientation == "left" then
                    List.reverse wrapperContent
                 else
                    wrapperContent
                )
            ]


barHeight : String -> Float
barHeight size =
    case size of
        "x-small" ->
            30

        "small" ->
            35

        "medium" ->
            40

        "large" ->
            50

        "x-large" ->
            60

        _ ->
            40


renderBar : Model -> PromoInfo -> Html Msg
renderBar model promo =
    div
        [ class
            (String.join " "
                [ "optinengine-optin"
                , "flex-bar"
                , "flex-" ++ promo.placement
                , if promo.animate then
                    if promo.placement == "top" then
                        "slide-in-top"
                    else
                        "slide-in-bottom"
                  else
                    ""
                , "flex-" ++ promo.size
                , if promo.positionFixed then
                    "flex-fixed"
                  else
                    ""
                , if promo.pushPage then
                    "flex-push"
                  else
                    ""
                ]
            )
        , Utils.Html.styles
            [ Css.height (Css.px (barHeight promo.size))
            , Css.borderColor (Css.hex (promo.borderColor))
            , if promo.placement == "top" then
                Css.borderBottom3 (Css.px promo.borderWidth) Css.solid (Css.hex (promo.borderColor))
              else
                Css.borderTop3 (Css.px promo.borderWidth) Css.solid (Css.hex (promo.borderColor))
            ]
        , style
            [ ( "z-index", "200000" )
            ]
        ]
        [ promoContent model promo
        , span
            [ class "flex-close"
            , Utils.Html.styles
                [ Css.color (Css.hex promo.textColor) ]
            , onClick Hide
            ]
            []
        ]


borderStyle : PromoInfo -> Css.Mixin
borderStyle promo =
    let
        func =
            (case promo.borderPosition of
                "top" ->
                    Css.borderTop3

                "bottom" ->
                    Css.borderBottom3

                "left" ->
                    Css.borderLeft3

                "right" ->
                    Css.borderRight3

                _ ->
                    Css.border3
            )
    in
        func (Css.px promo.borderWidth) Css.solid (Css.hex (promo.borderColor))


closeButtonTop : PromoInfo -> Float
closeButtonTop promo =
    case promo.borderPosition of
        "top" ->
            -10 + (promo.borderWidth * -1)

        "all" ->
            -10 + (promo.borderWidth * -1)

        _ ->
            -10


closeButtonRight : PromoInfo -> Float
closeButtonRight promo =
    case promo.borderPosition of
        "right" ->
            -10 + (promo.borderWidth * -1)

        "all" ->
            -10 + (promo.borderWidth * -1)

        _ ->
            -10


poweredBy : Model -> Html Msg
poweredBy model =
    if not model.affiliateEnabled then
        div [] []
    else
        div
            [ class "flex-powered-by" ]
            [ text "Powered by "
            , a
                [ href ("https://optinengine.net?ref=" ++ model.affiliateId), target "_blank" ]
                [ text "OptinEngine" ]
            ]


renderSlider : Model -> PromoInfo -> Html Msg
renderSlider model promo =
    div
        [ class
            (String.join " "
                [ "optinengine-optin"
                , "flex-slider"
                , "flex-" ++ promo.size
                , if promo.animate then
                    "slide-in-right"
                  else
                    ""
                , "flex-form-" ++ promo.formOrientation
                , (if model.affiliateEnabled then
                    "flex-enable-powered-by"
                   else
                    ""
                  )
                ]
            )
        , Utils.Html.styles
            [ Css.backgroundColor (Css.hex promo.bgColor)
            , Css.color (Css.hex promo.textColor)
            ]
        ]
        [ promoContent model promo
        , span
            [ class "flex-close"
            , Utils.Html.styles
                [ Css.top (Css.px (closeButtonTop promo))
                , Css.right (Css.px (closeButtonRight promo))
                ]
            , onClick Hide
            ]
            []
        , poweredBy model
        ]


renderModal : Model -> PromoInfo -> Html Msg
renderModal model promo =
    div
        [ class "flex-modal flex-fadein"
        , style
            [ ( "z-index", "2000000" )
            ]
        , Utils.Html.styles
            [ Css.backgroundColor (Css.rgba 0 0 0 0.5)
            , Css.position Css.fixed
            , Css.top (Css.px 0)
            , Css.left (Css.px 0)
            , Css.bottom (Css.px 0)
            , Css.right (Css.px 0)
            , Css.verticalAlign (Css.middle)
            ]
        ]
        [ div
            [ class
                (String.join " "
                    [ "optinengine-optin"
                    , "flex-modal"
                    , "flex-" ++ promo.size
                    , if promo.animate then
                        "flex-slide-in-modal"
                      else
                        ""
                    , "flex-form-" ++ promo.formOrientation
                    , (if model.affiliateEnabled then
                        "flex-enable-powered-by"
                       else
                        ""
                      )
                    ]
                )
            , Utils.Html.styles
                [ Css.backgroundColor (Css.hex promo.bgColor)
                , Css.color (Css.hex promo.textColor)
                ]
            ]
            [ promoContent model promo
            , span
                [ class "flex-close"
                , Utils.Html.styles
                    [ Css.top (Css.px (closeButtonTop promo))
                    , Css.right (Css.px (closeButtonRight promo))
                    ]
                , onClick Hide
                ]
                []
            , poweredBy model
            ]
        ]


renderEmbedded : Model -> PromoInfo -> Html Msg
renderEmbedded model promo =
    div
        [ class
            (String.join " "
                [ "optinengine-optin"
                , "flex-embedded"
                , "flex-" ++ promo.size
                , "flex-form-" ++ promo.formOrientation
                , (if model.affiliateEnabled then
                    "flex-enable-powered-by"
                   else
                    ""
                  )
                ]
            )
        , Utils.Html.styles
            [ Css.backgroundColor (Css.hex promo.bgColor)
            , Css.color (Css.hex promo.textColor)
            ]
        ]
        [ promoContent model promo
        , poweredBy model
        ]


view : Model -> Html Msg
view model =
    case model.promo of
        Just promo ->
            if model.isVisible == True then
                case promo.promoType of
                    "bar" ->
                        renderBar model promo

                    "slider" ->
                        renderSlider model promo

                    "modal" ->
                        renderModal model promo

                    "before-post" ->
                        renderEmbedded model promo

                    "after-post" ->
                        renderEmbedded model promo

                    "inline" ->
                        renderEmbedded model promo

                    "widget" ->
                        renderEmbedded model promo

                    _ ->
                        div [] []
            else
                div [] []

        Nothing ->
            div [] []


hidePromo : Model -> Bool -> ( Model, Cmd Msg )
hidePromo model success =
    case model.promo of
        Just promo ->
            let
                setHiddenCmd =
                    Ports.setPromoHidden
                        (HidePromoInfo
                            (Maybe.withDefault 0 promo.id)
                            promo.hideCookieDuration
                        )

                cmds =
                    if promo.closeButtonAction == "link" then
                        [ (Ports.redirectToUrl
                            { url = promo.closeButtonUrl
                            , newWindow = promo.closeButtonNewWindow
                            }
                          )
                        , setHiddenCmd
                        ]
                    else
                        [ setHiddenCmd ]
            in
                ( { model | isVisible = False }, Cmd.batch cmds )

        Nothing ->
            ( model, Cmd.none )


loadFonts : PromoInfo -> Cmd Msg
loadFonts promo =
    Ports.loadFonts [ promo.textFont ++ ":300,400,600", promo.buttonFont ++ ":300,400,600" ]


showPromo : Model -> ( Model, Cmd Msg )
showPromo model =
    let
        insertAtBeginning promo =
            promo.promoType == "bar" && promo.placement == "top"

        showPromoCmd promo =
            case promo.promoType of
                "bar" ->
                    if promo.positionFixed == True && promo.pushPage == True then
                        case promo.placement of
                            "top" ->
                                Ports.setTopMargin (barHeight promo.size)

                            _ ->
                                Ports.setBottomMargin (barHeight promo.size)
                    else
                        Cmd.none

                _ ->
                    Cmd.none
    in
        case model.promo of
            Just promo ->
                ( { model | isVisible = True }
                , Cmd.batch
                    [ Ports.addElementToDom (insertAtBeginning promo)
                    , showPromoCmd promo
                    , loadFonts promo
                    ]
                )

            Nothing ->
                Debug.crash ("We should never get a show a promo if we don't have one!")


setPromo : Model -> Maybe PromoInfo -> ( Model, Cmd Msg )
setPromo model promo =
    showPromo { model | promo = promo }


addLead : Model -> ( Model, Cmd Msg )
addLead model =
    case model.promo of
        Just promo ->
            if
                String.length model.email
                    > 0
                    && Utils.String.isEmail model.email
            then
                ( { model | isLoading = True }
                , API.addLead
                    model.api
                    LeadAdded
                    (Maybe.withDefault 0 promo.id)
                    promo.leadListId
                    model.name
                    model.lastName
                    model.email
                )
            else
                ( model, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Show ->
            showPromo model

        Hide ->
            hidePromo model False

        PromoResponseData (Ok info) ->
            setPromo
                { model
                    | affiliateId = info.affiliateId
                    , affiliateEnabled = info.affiliateEnabled && String.length info.affiliateId > 0
                }
                info.promo

        PromoResponseData (Err err) ->
            Debug.log (toString err) ( { model | isLoading = False }, Cmd.none )

        SetPromo details ->
            setPromo
                { model
                    | affiliateId = details.affiliateId
                    , affiliateEnabled = details.affiliateEnabled
                }
                (Just details.promo)

        AddLead ->
            addLead model

        NameUpdated val ->
            ( { model | name = val }, Cmd.none )

        EmailUpdated val ->
            ( { model | email = val }, Cmd.none )

        LeadAdded res ->
            ( { model | leadAdded = True, isLoading = False }
            , hidePromoSuccess model.promo
            )

        HidePromo _ ->
            hidePromo model False

        LastNameUpdated val ->
            ( { model | lastName = val }, Cmd.none )

        Redirect url ->
            ( model, Ports.redirectToUrl url )

        ShowThankyou show ->
            ( { model | forceShowThankyou = show }, Cmd.none )

        HideSuccess ->
            hidePromo model True

        FocusResult _ ->
            ( model, Cmd.none )


hidePromoSuccess : Maybe PromoInfo -> Cmd Msg
hidePromoSuccess promo =
    case promo of
        Just p ->
            Ports.setPromoHidden
                (HidePromoInfo
                    (Maybe.withDefault 0 p.id)
                    p.successCookieDuration
                )

        Nothing ->
            Cmd.none



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.setPromo SetPromo
        , Ports.hidePromo HidePromo
        , Ports.showThankyou ShowThankyou
        ]



-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
