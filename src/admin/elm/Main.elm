module Main exposing (..)

import API
import Components.Alert as Alert
import Components.Confirm as Confirm
import Components.Dialog as Dialog
import Components.Loading as Loading
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (decodeString)
import Ports
import SharedTypes exposing (..)
import String
import Utils.Decoders exposing (decodeApiError)
import Utils.Html exposing (..)
import Utils.NumberFormat
import Utils.String
import Utils.Types exposing (..)


type Msg
    = NoOp
    | BootDataResults (Result Http.Error BootData)
    | AlertMsg Alert.Msg
    | EditPromo PromoInfo
    | UpdatePreview
    | ToggleCheckbox
    | OpenSection String Section
    | ColorUpdated ColorUpdate
    | ToggleWiggleButton
    | PromoSizeUpdated String
    | DelaySecondsUpdated (Maybe Float)
    | PlacementUpdated String
    | TogglePositionFixed
    | TogglePushPage
    | HeadlineUpdated String
    | ButtonTextUpdated String
    | TextFontUpdated String
    | ButtonFontUpdated String
    | HideCookieDaysUpdated (Maybe Int)
    | SuccessCookieDaysUpdated (Maybe Int)
    | SaveAndClose
    | PromosUpdated (Result Http.Error Empty)
    | PromoSaved ActionAfterSaved (Result Http.Error PromoId)
    | LeadListUpdated (Result Http.Error Empty)
    | AddPromo
    | LoadingMsg Loading.Msg
    | ConfirmMsg (Confirm.Msg ConfirmType)
    | ConfirmNo ConfirmType
    | ConfirmYes ConfirmType
    | CloseEditorWithoutConfirm
    | SetTab Tab
    | ExportLeads
    | CreateVariation PromoInfo
    | ToggleEnablePromo PromoInfo
    | LoadMoreLeads
    | LeadDeleted Lead (Result Http.Error Empty)
    | GoalUpdated String
    | TypeUpdated String
    | LinkUrlUpdated String
    | ToggleOpenInNewWindow
    | EmailPlaceholerUpdated String
    | NamePlaceholerUpdated String
    | ThankYouMessageUpdated String
    | ConditionPageUpdated String
    | ConditionPageUrlUpdated String
    | ToggleConditionDeviceDesktop
    | ToggleConditionDeviceTablet
    | ToggleConditionDeviceMobile
    | BodyUpdated String
    | CloseTextUpdated String
    | ToggleAnimate
    | BorderWidthUpdated (Maybe Float)
    | LeadListResults (Result Http.Error LeadResults)
    | EmailProvierUpdated String
    | CustomFormBodyUpdated String
    | AddEmailAccount
    | CancelAddAccount
    | AddEmailAccountProviderUpdated String
    | AddEmailAccountProviderAccountNameUpdated String
    | AddEmailAccountProviderApiKeyUpdated String
    | ConfirmAddEmailAccount
    | EmailAccountAdded (Result Http.Error Empty)
    | RefreshEmailProvider ProviderInfo
    | EmailProvidersUpdated (Result Http.Error Empty)
    | NameFieldsUpdated String
    | EmailProviderListIdUpdated String
    | ToggleSaveToOptinEngineLeads
    | ToggleDisableDoubleOptin
    | FirstNamePlaceholderUpdated String
    | LastNamePlaceholderUpdated String
    | PromoNameUpdated String
    | ReloadLeadListResults (Result Http.Error LeadResults)
    | AuthorizeEmailProvider
    | AddEmailAccountIdUpdated String
    | SubscribeNewsletterEmailUpdated String
    | SubscribeNewsletterFirstNameUpdated String
    | SubscribeNewsletterLastNameUpdated String
    | FormFieldOrientationUpdated String
    | FormOrientationUpdated String
    | InputBorderWidthUpdated (Maybe Float)
    | InputTextClassUpdated String
    | InputBorderRadiusUpdated (Maybe Float)
    | AddPromoFromTemplate PromoInfo String
    | CloseTemplatePicker
    | SetTemplates (List PromoTemplate)
    | FilterTemplates String
    | AddEmailAccountApiUrlUpdated String
    | BodyHtmlUpdated String
    | HeadlineHtmlUpdated String
    | SetPromoNameUpdated String
    | ConfirmSetPromoName
    | CancelSetPromoName
    | ChooseOptinImage
    | PickImageFromMedia
    | SelectPremadeImage String
    | CancelChooseOptinImage
    | ConfirmChooseOptinImage
    | ImagePositionUpdated String
    | PickImageFromMediaResult String
    | BorderTypeUpdated String
    | BorderPositionUpdated String
    | ToggleEnableAffiliate
    | AffiliateIdUpdated String
    | UpdateAffiliateSettings
    | SettingsUpdated (Result Http.Error Empty)
    | DownloadLogs
    | ToggleLoggingEnabld
    | ThankYouHtmlUpdated String
    | ThankYouBodyHtmlUpdated String
    | CloseButtonActionUpdated String
    | CloseButtonUrlUpdated String
    | ToggleCloseButtonNewWindow
    | ViewShortCode
    | CloseViewShortcode
    | AddPromoSelectTemplate PromoTemplate
    | CancelPickOptinType


type Tab
    = Promos
    | Leads
    | About
    | EmailAccounts
    | Affiliates


type Section
    = TypeAndGoalSection
    | IntegrationSection
    | MessageSection
    | ThankyouSection
    | FontsSection
    | ImageSection
    | PositionSection
    | ColorAndDisplaySection
    | TargetingSection


type ConfirmType
    = CloseEditor
    | DeletePromo PromoInfo
    | EmptyLeadList
    | DeleteLead Lead
    | DeleteEmailProvider ProviderInfo


type ActionAfterSaved
    = AfterSavedCloseEditor
    | AfterSavedShowShortcode
    | AfterSavedDoNothing


type alias Model =
    { api : String
    , tools : String
    , promos : List PromoInfo
    , isLoading : Bool
    , alert : Alert.Model
    , promoToEdit : Maybe PromoInfo
    , activeSection : Section
    , confirm : Confirm.Model ConfirmType
    , editorDirty : Bool
    , activeTab : Tab
    , leads : List Lead
    , hasMoreLeads : Bool
    , leadCount : Int
    , addEmailAccountDialog : Dialog.Model
    , addEmailAccountProvider : String
    , addEmailAccountName : String
    , addEmailAccountApiKey : String
    , emailProviders : List ProviderInfo
    , addEmailAccountId : String
    , subscribeNewsletterEmail : String
    , subscribeNewsletterFirstName : String
    , subscribeNewsletterLastName : String
    , addPromoWizard : Dialog.Model
    , showTemplatePicker : Bool
    , pluginPath : String
    , templates : List PromoTemplate
    , templateFilter : String
    , addEmailAccountApiUrl : String
    , promoName : String
    , setPromoNameDialog : Dialog.Model
    , chooseOptinImageDialog : Dialog.Model
    , selectedPremadeImage : String
    , affiliateId : String
    , affiliateEnabled : Bool
    , loggingEnabled : Bool
    , onSavePromoAction : ActionAfterSaved
    , viewShortcodeModal : Dialog.Model
    , pickOptinTypeModal : Dialog.Model
    , pickOptinTypePromo : Maybe PromoTemplate
    }


type alias StartFlags =
    { api : String
    , tools : String
    , pluginPath : String
    }


init : StartFlags -> ( Model, Cmd Msg )
init flags =
    ( { api = flags.api
      , tools = flags.tools
      , promos = []
      , isLoading = True
      , alert = Alert.initial
      , promoToEdit = Nothing
      , activeSection = TypeAndGoalSection
      , confirm = Confirm.initial
      , editorDirty = False
      , activeTab = Promos
      , leads = []
      , hasMoreLeads = True
      , leadCount = 0
      , addEmailAccountDialog = Dialog.initial "medium"
      , addEmailAccountProvider = "mailchimp"
      , addEmailAccountName = ""
      , addEmailAccountApiKey = ""
      , emailProviders = []
      , addEmailAccountId = ""
      , subscribeNewsletterEmail = ""
      , subscribeNewsletterFirstName = ""
      , subscribeNewsletterLastName = ""
      , addPromoWizard = Dialog.initial "large"
      , showTemplatePicker = False
      , pluginPath = flags.pluginPath
      , templates = []
      , templateFilter = ""
      , addEmailAccountApiUrl = ""
      , promoName = ""
      , setPromoNameDialog = Dialog.initial "medium"
      , chooseOptinImageDialog = Dialog.initial "large"
      , selectedPremadeImage = ""
      , affiliateId = ""
      , affiliateEnabled = False
      , loggingEnabled = False
      , onSavePromoAction = AfterSavedDoNothing
      , viewShortcodeModal = Dialog.initial "medium"
      , pickOptinTypeModal = Dialog.initial "large"
      , pickOptinTypePromo = Nothing
      }
    , loadBootData flags.api
    )


premadeImages : List String
premadeImages =
    [ "image1.png"
    , "image2.png"
    , "image3.png"
    , "image4.png"
    , "image5.png"
    , "image6.png"
    , "image7.png"
    , "image8.png"
    , "image9.png"
    , "image10.png"
    , "image11.png"
    , "image12.png"
    , "image13.png"
    ]


copyPromo : PromoInfo -> PromoInfo
copyPromo src =
    { id = Nothing
    , isEnabled = src.isEnabled
    , goal = src.goal
    , promoType = src.promoType
    , placement = src.placement
    , pushPage = src.pushPage
    , headline = src.headline
    , button = src.button
    , displayDelaySeconds = src.displayDelaySeconds
    , wiggleButton = src.wiggleButton
    , bgColor = src.bgColor
    , textColor = src.textColor
    , textFont = src.textFont
    , buttonColor = src.buttonColor
    , buttonBgColor = src.buttonBgColor
    , buttonFont = src.buttonFont
    , hideCookieDuration = src.hideCookieDuration
    , successCookieDuration = src.successCookieDuration
    , positionFixed = src.positionFixed
    , linkUrl = src.linkUrl
    , openLinkNewWindow = src.openLinkNewWindow
    , emailPlaceholder = src.emailPlaceholder
    , namePlaceholder = src.namePlaceholder
    , leadListId = src.leadListId
    , thankYouMessage = src.thankYouMessage
    , conditionPage = src.conditionPage
    , conditionPageUrl = src.conditionPageUrl
    , conditionDeviceDesktop = src.conditionDeviceDesktop
    , conditionDeviceTablet = src.conditionDeviceTablet
    , conditionDeviceMobile = src.conditionDeviceMobile
    , body = src.body
    , close = src.close
    , animate = src.animate
    , size = src.size
    , borderColor = src.borderColor
    , borderWidth = src.borderWidth
    , emailProvider = src.emailProvider
    , customFormBody = src.customFormBody
    , nameFields = src.nameFields
    , emailProviderListId = src.emailProviderListId
    , saveToOptinEngineLeads = src.saveToOptinEngineLeads
    , disableDoubleOptin = src.disableDoubleOptin
    , firstNamePlaceholder = src.firstNamePlaceholder
    , lastNamePlaceholder = src.lastNamePlaceholder
    , name = ""
    , formFieldOrientation = src.formFieldOrientation
    , formOrientation = src.formOrientation
    , formBgColor = src.formBgColor
    , inputBgColor = src.inputBgColor
    , inputBorderWidth = src.inputBorderWidth
    , inputBorderColor = src.inputBorderColor
    , inputTextClass = src.inputTextClass
    , inputBorderRadius = src.inputBorderRadius
    , imageUrl = src.imageUrl
    , imagePosition = src.imagePosition
    , borderType = src.borderType
    , borderPosition = src.borderPosition
    , thankYouBody = src.thankYouBody
    , closeButtonAction = src.closeButtonAction
    , closeButtonUrl = src.closeButtonUrl
    , closeButtonNewWindow = src.closeButtonNewWindow
    }


loadBootData : String -> Cmd Msg
loadBootData api =
    Cmd.batch
        [ API.getBootData api BootDataResults
        , API.listLeads api
            ReloadLeadListResults
            Nothing
        ]


promosTab : Model -> Html Msg
promosTab model =
    let
        rowClass promo =
            if promo.isEnabled then
                "left-border-green"
            else
                "left-border-red"

        promoName promo =
            if String.length promo.name > 0 then
                promo.name
            else
                promo.headline

        promoError promo =
            promo.id == Just -1

        row promo =
            tr
                []
                [ td [ class (rowClass promo) ] [ text (promoName promo) ]
                , td
                    [ class "text-right width-25 no-wrap" ]
                    [ div [ class "flex-icon-menu" ]
                        [ span [] [ i [ class "fa fa-cog" ] [] ]
                        , div []
                            [ ul []
                                [ li
                                    [ onClick (EditPromo promo)
                                    , Utils.Html.hideIfTrue (promoError promo)
                                    ]
                                    [ a []
                                        [ i [ class "fa fa-pencil" ] [], text "Edit" ]
                                    ]
                                , li
                                    [ Utils.Html.hideIfFalse promo.isEnabled
                                    , Utils.Html.hideIfTrue (promoError promo)
                                    , onClick (ToggleEnablePromo promo)
                                    ]
                                    [ a [] [ i [ class "fa fa-pause" ] [], text "Pause optin" ] ]
                                , li
                                    [ Utils.Html.hideIfFalse (not promo.isEnabled)
                                    , Utils.Html.hideIfTrue (promoError promo)
                                    , onClick (ToggleEnablePromo promo)
                                    ]
                                    [ a [] [ i [ class "fa fa-play" ] [], text "Enable optin" ] ]
                                , li
                                    [ onClick (CreateVariation promo)
                                    , Utils.Html.hideIfTrue (promoError promo)
                                    ]
                                    [ a [] [ i [ class "fa fa-clone" ] [], text "Create variation" ] ]
                                , li
                                    [ Confirm.askOnClick
                                        ConfirmMsg
                                        (DeletePromo promo)
                                        "Are you sure you wan't to delete this optin?"
                                    ]
                                    [ a
                                        []
                                        [ i [ class "fa fa-trash" ] [], text "Delete" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]

        emptyRow =
            tr
                []
                [ td [ colspan 5 ]
                    [ text "You have not created any optins yet" ]
                ]
    in
        div [ class "p-l-10 p-r-10" ]
            [ table
                [ class "table bold grid" ]
                [ thead
                    []
                    [ tr []
                        [ th [] [ text "Optin" ]
                        , th [] []
                        ]
                    ]
                , tbody
                    []
                    (if List.length model.promos > 0 then
                        List.map row model.promos
                     else
                        [ emptyRow ]
                    )
                ]
            , div []
                [ button
                    [ class "btn large m-t-10 m-b-10", onClick AddPromo ]
                    [ i
                        [ class "fa fa-plus-circle"
                        ]
                        []
                    , text "Create New Optin"
                    ]
                ]
            ]


leadListContents : Model -> Html Msg
leadListContents model =
    let
        row lead =
            tr
                []
                [ td [] [ text lead.email ]
                , td [] [ text lead.name ]
                , td [] [ text lead.lastName ]
                , td [ class "width-100" ] [ text lead.createdAt ]
                , td
                    [ class "width-25 text-right" ]
                    [ i
                        [ class "fa fa-trash cursor-pointer"
                        , Confirm.askOnClick
                            ConfirmMsg
                            (DeleteLead lead)
                            "Are you sure you wan't to delete this lead?"
                        ]
                        []
                    ]
                ]
    in
        div [ class "p-l-10 p-r-10" ]
            [ div [ class "p-t-20 p-l-10 relative" ]
                [ h2
                    []
                    [ text (Utils.NumberFormat.prettyInt ',' model.leadCount)
                    , text " Lead(s)"
                    ]
                , div [ class "absolute-top-right m-t-10" ]
                    [ div
                        [ class "btn m-r-5"
                        , onClick (ExportLeads)
                        , Utils.Html.disableIfFalse (model.leadCount > 0)
                        ]
                        [ i [ class "fa fa-file-excel-o" ] [], text "Export" ]
                    ]
                ]
            , table
                [ class "table bold grid" ]
                [ thead
                    []
                    [ tr []
                        [ th [] [ text "Email" ]
                        , th [] [ text "First Name" ]
                        , th [] [ text "Last Name" ]
                        , th [] [ text "Added" ]
                        , th [] []
                        ]
                    ]
                , tbody
                    []
                    (List.map row model.leads)
                ]
            , div [ class "p-t-10 p-b-10" ]
                [ button
                    [ class "btn large"
                    , onClick LoadMoreLeads
                    , Utils.Html.disableIfFalse model.hasMoreLeads
                    ]
                    [ i [ class "fa fa-chevron-down" ] []
                    , text "Load more"
                    ]
                ]
            ]


leadsTab : Model -> Html Msg
leadsTab model =
    leadListContents model


providerName : String -> String
providerName provider =
    case provider of
        "mailchimp" ->
            "MailChimp"

        "getresponse" ->
            "GetResponse"

        "aweber" ->
            "Aweber"

        "drip" ->
            "Drip"

        "campaignmonitor" ->
            "Campaign Monitor"

        "intercom" ->
            "Intercom"

        "activecampaign" ->
            "ActiveCampaign"

        _ ->
            provider


emailAccountsTab : Model -> Html Msg
emailAccountsTab model =
    let
        emptyRow =
            tr
                []
                [ td [ colspan 5 ]
                    [ text "You have not added any email accounts yet" ]
                ]

        emptyListsRow =
            tr
                []
                [ td [ colspan 5 ]
                    [ text "This email provider does not have any lists" ]
                ]

        subscriberCount provider =
            let
                subscribers =
                    List.foldl (\p a -> p.subscribers + a) 0 provider.lists
            in
                if subscribers < 0 then
                    "-"
                else
                    toString subscribers

        row provider =
            tr
                []
                [ td [ class "left-border-green" ] [ text provider.name ]
                , td [] [ text (providerName provider.provider) ]
                , td [] [ text (toString (List.length provider.lists)) ]
                , td [] [ text (subscriberCount provider) ]
                , td [ class "text-right" ]
                    [ i [ class "fa fa-refresh m-r-10 cursor-pointer", onClick (RefreshEmailProvider provider) ] []
                    , i
                        [ class "fa fa-trash cursor-pointer"
                        , Confirm.askOnClick
                            ConfirmMsg
                            (DeleteEmailProvider provider)
                            "Are you sure you want to delete this email provider?"
                        ]
                        []
                    ]
                ]
    in
        div [ class "p-l-10 p-r-10" ]
            [ table
                [ class "table bold grid" ]
                [ thead
                    []
                    [ tr []
                        [ th [] [ text "Name" ]
                        , th [] [ text "Provider" ]
                        , th [] [ text "Lists" ]
                        , th [] [ text "Total Subscribers" ]
                        , th [] []
                        ]
                    ]
                , tbody
                    []
                    (if List.length model.emailProviders > 0 then
                        List.map row model.emailProviders
                     else
                        [ emptyRow ]
                    )
                ]
            , div []
                [ button
                    [ class "btn large m-t-10 m-b-10"
                    , onClick AddEmailAccount
                    ]
                    [ i [ class "fa fa-plus-circle" ] []
                    , text "Add Account"
                    ]
                ]
            ]


aboutTab : Model -> Html Msg
aboutTab model =
    div
        [ class "p-10" ]
        [ div
            [ class "p-10 p-t-20 p-b-20" ]
            [ h3 [] [ text "OptinEngine - Email Optins & Lead Generations" ]
            , div [] [ text "For help and support and feedback please visit our website by clicking below" ]
            , div []
                [ a
                    [ class "btn m-t-10 large", href "http://optinengine.net", target "_blank" ]
                    [ i [ class "fa fa-link" ] []
                    , text "Visit OptinEngine"
                    ]
                ]
            , h3 [ class "m-t-20" ] [ text "Enable Plugin Logging" ]
            , div
                []
                [ Utils.Html.switch ToggleLoggingEnabld "" model.loggingEnabled []
                , span
                    [ class "btn m-l-5", onClick DownloadLogs ]
                    [ i [ class "fa fa-download" ] []
                    , text "Download Logs"
                    ]
                ]
            , div []
                []
            ]
        ]


affiliatesTab : Model -> Html Msg
affiliatesTab model =
    div []
        [ table
            []
            [ tbody []
                [ tr []
                    [ td [ class "p-20" ]
                        [ h3 [] [ text "Earn 35% with our Affiliate Program" ]
                        , p [] [ text "Place a small link below your optins and earn 35% from all sales that you send!" ]
                        , img [ class "border max100", width 350, src (model.pluginPath ++ "/images/affiliateExample.jpg") ] []
                        , p [] [ text "To get started click the link below to setup an affiliate account then paste your affiliate id in the settings box on the right." ]
                        , img
                            [ class "border max100"
                            , src (model.pluginPath ++ "/images/affiliateId.jpg")
                            ]
                            []
                        , a
                            [ class "btn m-t-10 large green", href "https://optinengine.net/affiliates/", target "_blank" ]
                            [ i [ class "fa fa-usd" ] []
                            , text "Join our affiliate program"
                            ]
                        ]
                    , td [ class "affiliate-setup p-20" ]
                        [ h3 [] [ text "Affiliate Settings" ]
                        , p []
                            [ text "After signing up for an "
                            , a [ href "https://optinengine.net/affiliates/", target "_blank" ] [ text "affiliate account" ]
                            , text " enter your Affiliate ID in the box below and save the settings"
                            ]
                        , div
                            [ class "form-group" ]
                            [ input
                                [ type_ "text"
                                , class "form-control"
                                , value model.affiliateId
                                , onInput AffiliateIdUpdated
                                , placeholder "Enter your Affiliate ID"
                                ]
                                []
                            ]
                        , div
                            [ class "form-group" ]
                            [ label [] [ text "Enable Affiliate Links" ]
                            , Utils.Html.switch ToggleEnableAffiliate "" model.affiliateEnabled []
                            ]
                        , span
                            [ class "btn m-t-10 large green", onClick UpdateAffiliateSettings ]
                            [ i [ class "fa fa-save" ] []
                            , text "Save Settings"
                            ]
                        ]
                    ]
                ]
            ]
        , div
            []
            []
        ]


tryFlexBarPro : Model -> Html Msg
tryFlexBarPro modle =
    div
        [ class "panel-body p-15" ]
        [ h2 [] [ text "Upgrade to OptinEngine Pro!" ]
        , label [] [ text "Convert your visitors into customers with OptinEngine Pro" ]
        , ul
            [ class "bullets" ]
            [ li [] [ text "Optin statistics - impressions, conversions, conversion rate" ]
            , li [] [ text "A/B testing - optimize your optins" ]
            , li [] [ text "Multiple email/lead lists" ]
            , li [] [ text "Premium support" ]
            ]
        , a
            [ class "btn large green", href "http://optinengine.net?utm_source=wp", target "_blank" ]
            [ i [ class "fa fa-link " ] []
            , text "Get OptinEngine Pro"
            ]
        ]


supportBox : Model -> Html Msg
supportBox modle =
    div
        [ class "panel-body p-15" ]
        [ h2 [] [ text "Questions or feedback?" ]
        , label [] [ text "If you are having problems or have a suggestion for how to make OptinEngine better we would love to hear from you!" ]
        , div [ class "m-t-10" ]
            [ a
                [ class "btn large green", href "https://optinengine.net/support/", target "_blank" ]
                [ i [ class "fa fa-envelope-o" ] []
                , text "Contact Support"
                ]
            ]
        ]


newsletterSignup : Model -> Html Msg
newsletterSignup model =
    div
        [ class "panel-body p-15" ]
        [ h2 [] [ text "Save 10% on OptinEngine Pro!" ]
        , label [] [ text "Sign up to our newsletter and get a 10% discount code in your inbox!" ]
        , Html.form
            [ method "POST"
            , action "//optinengine.us14.list-manage.com/subscribe/post?u=2fa68d187ae2ff2b87006782d&amp;id=60b50198e6"
            , target "_blank"
            , class "m-t-10"
            ]
            [ div
                [ class "form-group" ]
                [ input
                    [ type_ "text"
                    , class "form-control"
                    , name "FNAME"
                    , placeholder "First Name"
                    , onInput SubscribeNewsletterFirstNameUpdated
                    , value model.subscribeNewsletterFirstName
                    ]
                    []
                ]
            , div
                [ class "form-group" ]
                [ input
                    [ type_ "text"
                    , class "form-control"
                    , name "LNAME"
                    , placeholder "Last Name"
                    , onInput SubscribeNewsletterLastNameUpdated
                    , value model.subscribeNewsletterLastName
                    ]
                    []
                ]
            , div
                [ class "form-group" ]
                [ input
                    [ type_ "text"
                    , class "form-control"
                    , name "EMAIL"
                    , required True
                    , placeholder "Email"
                    , onInput SubscribeNewsletterEmailUpdated
                    , value model.subscribeNewsletterEmail
                    ]
                    []
                ]
            , button
                [ type_ "submit", class "btn large green" ]
                [ i [ class "fa fa-envelope-o" ] []
                , text "Signup Now"
                ]
            ]
        ]


addEmailAccountView : Model -> Html Msg
addEmailAccountView model =
    let
        needsApiKey =
            case model.addEmailAccountProvider of
                "mailchimp" ->
                    True

                "getresponse" ->
                    True

                "drip" ->
                    True

                "campaignmonitor" ->
                    True

                "intercom" ->
                    True

                "activecampaign" ->
                    True

                _ ->
                    False

        needsAuthorization =
            case model.addEmailAccountProvider of
                "aweber" ->
                    True

                _ ->
                    False

        needsAccountId =
            case model.addEmailAccountProvider of
                "drip" ->
                    True

                _ ->
                    False

        needsApiUrl =
            case model.addEmailAccountProvider of
                "activecampaign" ->
                    True

                _ ->
                    False

        accountNameAndKeyProvided =
            (String.length model.addEmailAccountName)
                > 0
                && (String.length model.addEmailAccountApiKey)
                > 0

        canAddAccount =
            case model.addEmailAccountProvider of
                "mailchimp" ->
                    accountNameAndKeyProvided

                "getresponse" ->
                    accountNameAndKeyProvided

                "aweber" ->
                    accountNameAndKeyProvided

                "campaignmonitor" ->
                    accountNameAndKeyProvided

                "drip" ->
                    (String.length model.addEmailAccountName)
                        > 0
                        && (String.length model.addEmailAccountApiKey)
                        > 0
                        && (String.length model.addEmailAccountId)
                        > 0

                "intercom" ->
                    accountNameAndKeyProvided

                "activecampaign" ->
                    accountNameAndKeyProvided && (String.length model.addEmailAccountApiUrl > 0)

                _ ->
                    False

        apiKeyName =
            case model.addEmailAccountProvider of
                "intercom" ->
                    "Access Token"

                _ ->
                    "API Key"

        providerOption provider =
            option
                [ value provider, checked (model.addEmailAccountProvider == provider) ]
                [ text (providerName provider) ]
    in
        div []
            [ h3 [] [ text "Add Email Provider" ]
            , div
                [ class "form-group" ]
                [ label [] [ text "Email Provider" ]
                , select
                    [ class "form-control"
                    , Utils.Html.onSelectChangeString AddEmailAccountProviderUpdated
                    ]
                    [ providerOption "mailchimp"
                    , providerOption "aweber"
                    , providerOption "getresponse"
                    , providerOption "drip"
                    , providerOption "campaignmonitor"
                    , providerOption "intercom"
                    , providerOption "activecampaign"
                    ]
                ]
            , div
                [ class "form-group" ]
                [ label [] [ text "Account Name" ]
                , input
                    [ type_ "text"
                    , class "form-control"
                    , value model.addEmailAccountName
                    , onInput AddEmailAccountProviderAccountNameUpdated
                    ]
                    []
                ]
            , div
                [ Utils.Html.hideIfFalse needsAccountId ]
                [ div
                    [ class "form-group" ]
                    [ label [] [ text "Account ID" ]
                    , input
                        [ type_ "text"
                        , class "form-control"
                        , value model.addEmailAccountId
                        , onInput AddEmailAccountIdUpdated
                        ]
                        []
                    ]
                ]
            , div
                [ Utils.Html.hideIfFalse needsApiUrl ]
                [ div
                    [ class "form-group" ]
                    [ label [] [ text "API Url" ]
                    , input
                        [ type_ "text"
                        , class "form-control"
                        , value model.addEmailAccountApiUrl
                        , onInput AddEmailAccountApiUrlUpdated
                        ]
                        []
                    ]
                ]
            , div
                [ Utils.Html.hideIfFalse needsApiKey ]
                [ div
                    [ class "form-group" ]
                    [ label [] [ text apiKeyName ]
                    , input
                        [ type_ "text"
                        , class "form-control"
                        , value model.addEmailAccountApiKey
                        , onInput AddEmailAccountProviderApiKeyUpdated
                        ]
                        []
                    ]
                ]
            , div
                [ Utils.Html.hideIfFalse needsAuthorization ]
                [ div
                    [ class "form-group" ]
                    [ label []
                        [ a [ href "#", class "font-bold", onClick AuthorizeEmailProvider ] [ text "Click here to authorize" ]
                        , text ", then paste authorization code below"
                        ]
                    , textarea
                        [ rows 3
                        , class "form-control"
                        , value model.addEmailAccountApiKey
                        , onInput AddEmailAccountProviderApiKeyUpdated
                        ]
                        []
                    ]
                ]
            , div [ class "m-t-10" ]
                [ div
                    [ class "btn large m-r-5"
                    , onClick ConfirmAddEmailAccount
                    , Utils.Html.disableIfFalse canAddAccount
                    ]
                    [ i [ class "fa-plus-circle fa" ] [], text "Add Account" ]
                , div
                    [ class "btn large red", onClick CancelAddAccount ]
                    [ i [ class "fa-times fa" ] [], text "Cancel" ]
                ]
            ]


addPromoWizardView : Model -> Html Msg
addPromoWizardView model =
    div
        []
        [ div [ class "template-container" ] []
        ]


setPromoNameView : Model -> Html Msg
setPromoNameView model =
    div []
        [ h3 [] [ text "Enter a name for this promo" ]
        , div
            [ class "form-group" ]
            [ input
                [ type_ "text"
                , class "form-control"
                , value model.promoName
                , onInput SetPromoNameUpdated
                ]
                []
            ]
        , div [ class "m-t-10" ]
            [ div
                [ class "btn large m-r-5"
                , onClick ConfirmSetPromoName
                , Utils.Html.disableIfFalse (String.length model.promoName > 0)
                ]
                [ i [ class "fa-save fa" ] [], text "OK" ]
            , div
                [ class "btn large red", onClick CancelSetPromoName ]
                [ i [ class "fa-times fa" ] [], text "Cancel" ]
            ]
        ]


chooseOptinImageView : Model -> Html Msg
chooseOptinImageView model =
    let
        imagePath image =
            model.pluginPath ++ "images/" ++ image

        imageView image =
            div
                [ class
                    (if model.selectedPremadeImage == image then
                        "selected"
                     else
                        ""
                    )
                , onClick (SelectPremadeImage image)
                ]
                [ img [ src (imagePath image) ] [] ]
    in
        div []
            [ h3 [] [ text "Choose an image for this optin" ]
            , div [ class "image-picker" ] (List.map imageView premadeImages)
            , div [ class "m-t-10" ]
                [ div
                    [ class "btn large m-r-5"
                    , onClick ConfirmChooseOptinImage
                    , Utils.Html.disableIfFalse (String.length model.selectedPremadeImage > 0)
                    ]
                    [ i [ class "fa-plus-circle fa" ] [], text "OK" ]
                , div
                    [ class "btn large red", onClick CancelChooseOptinImage ]
                    [ i [ class "fa-times fa" ] [], text "Cancel" ]
                , div
                    [ class "btn large pull-right", onClick PickImageFromMedia ]
                    [ i [ class "fa-upload fa" ] [], text "Upload Image" ]
                ]
            ]


viewShortcodeView : Model -> Html Msg
viewShortcodeView model =
    case model.promoToEdit of
        Just promo ->
            div []
                [ h3 [] [ text "Copy and paste the this shortcode into your posts" ]
                , div
                    [ class "shortcode" ]
                    [ pre []
                        [ text
                            (Utils.String.interpolate
                                "[optinengine_promo promo_id=\"{0}\"]"
                                [ toString (Maybe.withDefault 0 promo.id) ]
                            )
                        ]
                    ]
                , div [ class "m-t-10" ]
                    [ div
                        [ class "btn large m-r-5"
                        , onClick CloseViewShortcode
                        ]
                        [ i [ class "fa-check fa" ] [], text "OK" ]
                    ]
                ]

        Nothing ->
            div [] []


pickOptinTypeModal : Model -> Html Msg
pickOptinTypeModal model =
    case model.pickOptinTypePromo of
        Just promo ->
            let
                imagePath optinType =
                    model.pluginPath ++ "images/optin-" ++ optinType ++ ".png"

                imageView optinType =
                    div
                        [ onClick (AddPromoFromTemplate promo.promo optinType) ]
                        [ div [ class "title" ] [ text (nameFromTag optinType) ]
                        , img [ src (imagePath optinType) ] []
                        ]
            in
                div []
                    [ div [ class "optin-picker" ] (List.map imageView promo.tags)
                    , div [ class "m-t-10" ]
                        [ div
                            [ class "btn large red", onClick CancelPickOptinType ]
                            [ i [ class "fa-times fa" ] [], text "Cancel" ]
                        ]
                    ]

        Nothing ->
            div [] []


view : Model -> Html Msg
view model =
    let
        activeTab tab =
            if model.activeTab == tab then
                class "active"
            else
                class ""
    in
        div
            [ class "flexstyles" ]
            [ div [ class "m-t-20 m-r-20" ]
                [ div [ class "tab-header" ]
                    [ div [ onClick (SetTab Promos), activeTab Promos ] [ i [ class "fa fa-home m-r-5" ] [], text "Optins" ]
                    , div [ onClick (SetTab EmailAccounts), activeTab EmailAccounts ] [ i [ class "fa fa-envelope-o m-r-5" ] [], text "Email Accounts" ]
                    , div [ onClick (SetTab Leads), activeTab Leads ] [ i [ class "fa fa-address-card m-r-5" ] [], text "Leads" ]
                    , div [ Utils.Html.hideIfTrue True, onClick (SetTab Affiliates), activeTab Affiliates ] [ i [ class "fa fa-usd m-r-5" ] [], text "Affiliates" ]
                    , div [ onClick (SetTab About), activeTab About ] [ i [ class "fa fa-question-circle m-r-5" ] [], text "Support" ]
                    ]
                , div
                    [ class "tab-body" ]
                    [ div [ Utils.Html.hideIfFalse (model.activeTab == Promos) ] [ promosTab model ]
                    , div [ Utils.Html.hideIfFalse (model.activeTab == Leads) ] [ leadsTab model ]
                    , div [ Utils.Html.hideIfFalse (model.activeTab == About) ] [ aboutTab model ]
                    , div [ Utils.Html.hideIfFalse (model.activeTab == EmailAccounts) ] [ emailAccountsTab model ]
                    , div [ Utils.Html.hideIfFalse (model.activeTab == Affiliates) ] [ affiliatesTab model ]
                    ]
                , div
                    [ class "m-t-20" ]
                    [ supportBox model
                    ]
                , editor model
                , promoTemplatePicker model
                , Confirm.view model.confirm ConfirmYes ConfirmNo
                , Dialog.view model.addPromoWizard (addPromoWizardView model)
                , Dialog.view model.addEmailAccountDialog (addEmailAccountView model)
                , Dialog.view model.setPromoNameDialog (setPromoNameView model)
                , Dialog.view model.chooseOptinImageDialog (chooseOptinImageView model)
                , Dialog.view model.viewShortcodeModal (viewShortcodeView model)
                , Dialog.view model.pickOptinTypeModal (pickOptinTypeModal model)
                , Html.map AlertMsg (Alert.view model.alert)
                , loading model
                ]
            ]


providerInfo : Model -> String -> Maybe ProviderInfo
providerInfo model provider =
    let
        providerId =
            Result.withDefault 0 (String.toInt provider)
    in
        List.head (List.filter (\m -> m.id == providerId) model.emailProviders)


nameFromTag : String -> String
nameFromTag tag =
    case tag of
        "modal" ->
            "Popup"

        "slider" ->
            "Slider"

        "bar" ->
            "Info Bar"

        "inline" ->
            "Inline (Short Code)"

        "widget" ->
            "Widget"

        "before-post" ->
            "Before Post"

        "after-post" ->
            "After Post"

        _ ->
            "All"


promoTemplatePicker : Model -> Html Msg
promoTemplatePicker model =
    let
        templateView model template =
            let
                templatePreviewPath =
                    model.pluginPath ++ "images/templates/" ++ template.image

                createPromoClick =
                    if (List.length template.tags) == 1 then
                        onClick (AddPromoFromTemplate template.promo (Maybe.withDefault "" (List.head template.tags)))
                    else
                        onClick (AddPromoSelectTemplate template)
            in
                div
                    [ class ("template-preview " ++ template.image)
                    ]
                    [ div []
                        [ div
                            [ class "info" ]
                            [ div
                                [ class "buttons" ]
                                [ div
                                    [ class "btn green large"
                                    , createPromoClick
                                    ]
                                    [ i [ class "fa fa-plus-circle" ] []
                                    , text "Use this template"
                                    ]
                                ]
                            ]
                        , img [ src templatePreviewPath ] []
                        ]
                    ]

        filterTag tag =
            div
                [ class
                    (if model.templateFilter == tag then
                        "active"
                     else
                        ""
                    )
                , onClick (FilterTemplates tag)
                ]
                [ text (nameFromTag tag) ]

        filteredTemplates =
            List.sortBy .theme model.templates
                |> List.filter
                    (\t -> String.length model.templateFilter == 0 || List.member model.templateFilter t.tags)
    in
        div
            [ class "modal template-picker"
            , Utils.Html.hideIfFalse model.showTemplatePicker
            ]
            [ div
                [ class "controls" ]
                [ div [ class "p-5" ]
                    [ a
                        [ class "btn red large"
                        , onClick CloseTemplatePicker
                        ]
                        [ i [ class "fa fa-close" ] [], text "Cancel" ]
                    ]
                ]
            , div [ class "title" ] [ h1 [] [ text "Choose your template style" ] ]
            , div
                [ class "templates" ]
                [ div [ class "tags p-l-10 p-t-10" ]
                    [ filterTag ""
                    , filterTag "modal"
                    , filterTag "slider"
                    , filterTag "bar"
                    , filterTag "before-post"
                    , filterTag "after-post"
                    , filterTag "widget"
                    ]
                , div
                    [ Utils.Html.hideIfTrue (List.length filteredTemplates == 0) ]
                    (List.map (templateView model) filteredTemplates)
                , div
                    [ Utils.Html.hideIfFalse (List.length filteredTemplates == 0) ]
                    [ div [ class "none-found" ] [ text "No templates found" ] ]
                ]
            ]


expandUrlPath : Model -> String -> String
expandUrlPath model url =
    Utils.String.replace "{FLEX_PLUGIN_URL}" model.pluginPath url


isEmbedded : PromoInfo -> Bool
isEmbedded promo =
    case promo.promoType of
        "inline" ->
            True

        "before-post" ->
            True

        "after-post" ->
            True

        "widget" ->
            True

        _ ->
            False


editor : Model -> Html Msg
editor model =
    let
        floatOption currentValue val name =
            option
                [ value (toString val)
                , selected (currentValue == val)
                ]
                [ text name ]

        stringOption currentValue val name =
            option
                [ value val
                , selected (currentValue == val)
                ]
                [ text name ]

        fontOptions val =
            let
                fonts =
                    [ "Roboto"
                    , "Open Sans"
                    , "Lato"
                    , "Merriweather"
                    , "Sansita"
                    , "Pangolin"
                    , "Barrio"
                    , "Raleway"
                    , "Bahiana"
                    ]
            in
                List.map (\f -> stringOption val f f) fonts

        cookieDayOptions val =
            [ floatOption val 0 "Don't hide"
            , floatOption val 1 "Hide for 1 day"
            , floatOption val 3 "Hide for 3 days"
            , floatOption val 7 "Hide for 7 days"
            , floatOption val 15 "Hide for 15 days"
            , floatOption val 30 "Hide for 30 days"
            , floatOption val 60 "Hide for 60 days"
            , floatOption val 90 "Hide for 90 days"
            , floatOption val 180 "Hide for 180 days"
            ]

        closeEditorAction =
            if model.editorDirty then
                Confirm.askOnClick
                    ConfirmMsg
                    CloseEditor
                    "Any changes will be lost, are you sure?"
            else
                onClick CloseEditorWithoutConfirm

        hasBody type_ =
            case type_ of
                "bar" ->
                    False

                _ ->
                    True

        emailLists provider listId =
            case (providerInfo model provider) of
                Nothing ->
                    []

                Just info ->
                    List.map (\l -> stringOption listId l.identifier l.name) info.lists

        onClickRefreshLists provider =
            case (providerInfo model provider) of
                Nothing ->
                    []

                Just info ->
                    [ onClick (RefreshEmailProvider info) ]

        canDisableDoubleOptin provider =
            case provider of
                "mailchimp" ->
                    True

                _ ->
                    False

        sectionFields section contents =
            let
                show =
                    model.activeSection == section

                extraClass =
                    if show then
                        "visible"
                    else
                        ""

                activeClass =
                    if model.activeSection == section then
                        "active"
                    else
                        ""

                iconClass =
                    if model.activeSection == section then
                        "fa-chevron-down"
                    else
                        "fa-chevron-left"
            in
                div [ class "form-section-container", Utils.Html.hideIfFalse show ]
                    [ div [ class ("form-section-contents") ]
                        [ div [ class "p-t-10" ] contents ]
                    ]

        sectionButton title section show icon =
            let
                activeClass =
                    if model.activeSection == section then
                        "active"
                    else
                        ""
            in
                div
                    [ Utils.Html.hideIfFalse show, class activeClass, onClick (OpenSection title section) ]
                    [ div []
                        [ i [ class ("fa " ++ icon) ] []
                        , div [] [ text title ]
                        ]
                    ]

        enableTargetingSection promoType =
            case promoType of
                "inline" ->
                    False

                "widget" ->
                    False

                "above-post" ->
                    False

                "below-post" ->
                    False

                _ ->
                    True
    in
        case model.promoToEdit of
            Just promo ->
                div
                    [ class "modal editor" ]
                    [ div
                        [ class "controls" ]
                        [ div [ class "p-5" ]
                            [ a
                                [ class "btn m-r-5 large green", onClick SaveAndClose ]
                                [ i [ class "fa fa-save" ] [], text "Save & Publish" ]
                            , a
                                [ class "btn red large"
                                , closeEditorAction
                                ]
                                [ i [ class "fa fa-close" ] [], text "Close" ]
                            ]
                        ]
                    , div
                        [ class "sections" ]
                        [ sectionButton
                            "Setup"
                            TypeAndGoalSection
                            True
                            "fa-cog"
                        , sectionButton
                            "Position"
                            PositionSection
                            (promo.promoType == "bar")
                            "fa-window-maximize"
                        , sectionButton
                            "Message"
                            MessageSection
                            True
                            "fa-commenting-o"
                        , sectionButton
                            "Thank you"
                            ThankyouSection
                            (promo.goal == "email")
                            "fa-check"
                        , sectionButton
                            "Fonts"
                            FontsSection
                            True
                            "fa-font"
                        , sectionButton
                            "Style"
                            ColorAndDisplaySection
                            True
                            "fa-television"
                        , sectionButton
                            "Image"
                            ImageSection
                            (promo.promoType /= "bar")
                            "fa-file-image-o"
                        , sectionButton
                            "Targeting"
                            TargetingSection
                            (enableTargetingSection promo.promoType)
                            "fa-bullseye"
                        ]
                    , div
                        [ class "options" ]
                        [ sectionFields
                            TypeAndGoalSection
                            [ div
                                [ class "form-group" ]
                                [ label [] [ text "Optin Name" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control"
                                    , value promo.name
                                    , onInput PromoNameUpdated
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Type" ]
                                , select
                                    [ class "form-control", Utils.Html.onSelectChangeString TypeUpdated ]
                                    [ stringOption promo.promoType "slider" "Slider"
                                    , stringOption promo.promoType "bar" "Bar"
                                    , stringOption promo.promoType "modal" "Popup"
                                    , stringOption promo.promoType "inline" "Inline"
                                    , stringOption promo.promoType "widget" "Widget"
                                    , stringOption promo.promoType "before-post" "Before Post"
                                    , stringOption promo.promoType "after-post" "After Post"
                                    ]
                                ]
                            , div
                                [ Utils.Html.hideIfFalse (promo.promoType == "inline")
                                , class "m-l-20"
                                ]
                                [ div
                                    [ class "btn btn-green", onClick ViewShortCode ]
                                    [ text "View Shortcode" ]
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Goal" ]
                                , select
                                    [ class "form-control", Utils.Html.onSelectChangeString GoalUpdated ]
                                    [ stringOption promo.goal "email" "Collect Email"
                                    , stringOption promo.goal "click" "Click Link"
                                    ]
                                ]
                            , div
                                [ Utils.Html.hideIfFalse (promo.goal == "click") ]
                                [ div
                                    [ class "form-group" ]
                                    [ label [] [ text "Link URL" ]
                                    , input
                                        [ type_ "text"
                                        , class "form-control"
                                        , value promo.linkUrl
                                        , onInput LinkUrlUpdated
                                        ]
                                        []
                                    ]
                                , div
                                    [ class "form-group" ]
                                    [ label [] [ text "Open in new window" ]
                                    , Utils.Html.switch ToggleOpenInNewWindow "" promo.openLinkNewWindow []
                                    ]
                                ]
                            , div
                                [ Utils.Html.hideIfFalse (promo.goal == "email") ]
                                [ div
                                    [ class "form-group" ]
                                    [ label [] [ text "Email Provier" ]
                                    , select
                                        [ class "form-control"
                                        , Utils.Html.onSelectChangeString EmailProvierUpdated
                                        ]
                                        (List.concat
                                            [ [ stringOption promo.emailProvider "optinengine" "Save to OptinEngine Leads" ]
                                            , (List.map
                                                (\p -> stringOption promo.emailProvider (toString p.id) (p.name ++ " (" ++ providerName p.provider ++ ")"))
                                                (List.filter (\p -> List.length p.lists > 0) model.emailProviders)
                                              )
                                            ]
                                        )
                                    , a [ onClick AddEmailAccount ] [ i [ class "fa fa-plus-circle" ] [], text "Add Email Provider" ]
                                    ]
                                , div
                                    [ class "form-group", Utils.Html.hideIfTrue (promo.emailProvider == "optinengine") ]
                                    [ label [] [ text "Email List" ]
                                    , select
                                        [ class "form-control"
                                        , Utils.Html.onSelectChangeString EmailProviderListIdUpdated
                                        ]
                                        (emailLists promo.emailProvider promo.emailProviderListId)
                                    , a
                                        (onClickRefreshLists promo.emailProvider)
                                        [ i [ class "fa fa-plus-circle" ] [], text "Refresh Lists" ]
                                    ]
                                , div [ Utils.Html.hideIfTrue (promo.emailProvider == "optinengine") ]
                                    [ div []
                                        [ div
                                            [ class "form-group" ]
                                            [ label [] [ text "Save to OptinEngine leads" ]
                                            , Utils.Html.switch ToggleSaveToOptinEngineLeads "" promo.saveToOptinEngineLeads []
                                            ]
                                        ]
                                    , div [ Utils.Html.hideIfFalse (canDisableDoubleOptin promo.emailProvider) ]
                                        [ div
                                            [ class "form-group" ]
                                            [ label [] [ text "Disable Double Optin" ]
                                            , Utils.Html.switch ToggleDisableDoubleOptin "" promo.disableDoubleOptin []
                                            ]
                                        ]
                                    ]
                                , div
                                    [ class "form-group" ]
                                    [ label [] [ text "Name Field(s)" ]
                                    , select
                                        [ class "form-control"
                                        , Utils.Html.onSelectChangeString NameFieldsUpdated
                                        ]
                                        [ stringOption promo.nameFields "noname" "Just email address"
                                        , stringOption promo.nameFields "single" "Single name field"
                                        , stringOption promo.nameFields "firstlast" "First + last name fields"
                                        ]
                                    ]
                                , div
                                    [ Utils.Html.hideIfFalse (promo.emailProvider == "form") ]
                                    [ div
                                        [ class "form-group" ]
                                        [ label [] [ text "Form HTML" ]
                                        , textarea
                                            [ class "form-control"
                                            , onInput CustomFormBodyUpdated
                                            ]
                                            [ text promo.customFormBody ]
                                        ]
                                    ]
                                , div
                                    [ class "form-group", Utils.Html.hideIfTrue (promo.promoType == "bar") ]
                                    [ label [] [ text "Form Orientation" ]
                                    , select
                                        [ class "form-control"
                                        , Utils.Html.onSelectChangeString FormOrientationUpdated
                                        ]
                                        [ stringOption promo.formOrientation "bottom" "Form at the bottom"
                                        , stringOption promo.formOrientation "right" "Form to the right"
                                        , stringOption promo.formOrientation "left" "Form to the left"
                                        ]
                                    ]
                                , div
                                    [ class "form-group", Utils.Html.hideIfTrue (promo.promoType == "bar") ]
                                    [ label [] [ text "Form Field Orientation" ]
                                    , select
                                        [ class "form-control"
                                        , Utils.Html.onSelectChangeString FormFieldOrientationUpdated
                                        ]
                                        [ stringOption promo.formFieldOrientation "stacked" "Stacked"
                                        , stringOption promo.formFieldOrientation "inline" "Inline"
                                        ]
                                    ]
                                ]
                            ]
                        , sectionFields
                            IntegrationSection
                            []
                        , sectionFields
                            MessageSection
                            [ div
                                [ class "form-group" ]
                                [ label [] [ text "Headline Text" ]
                                , textarea
                                    [ class "form-control wp_editor"
                                    , id "headline-editor"
                                    , attribute "data-html" promo.headline
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group"
                                , Utils.Html.hideIfFalse (hasBody promo.promoType)
                                ]
                                [ label [] [ text "Body Text" ]
                                , textarea
                                    [ class "form-control wp_editor"
                                    , id "body-editor"
                                    , attribute "data-html" promo.body
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Button Text" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control"
                                    , value promo.button
                                    , onInput ButtonTextUpdated
                                    ]
                                    []
                                ]
                            , div
                                [ Utils.Html.hideIfFalse (promo.goal == "email") ]
                                [ div
                                    [ class "form-group"
                                    , Utils.Html.hideIfFalse (promo.nameFields == "single")
                                    ]
                                    [ label [] [ text "Name Placeholder" ]
                                    , input
                                        [ type_ "text"
                                        , class "form-control"
                                        , value promo.namePlaceholder
                                        , onInput NamePlaceholerUpdated
                                        ]
                                        []
                                    ]
                                , div
                                    [ Utils.Html.hideIfFalse (promo.nameFields == "firstlast") ]
                                    [ div
                                        [ class "form-group"
                                        ]
                                        [ label [] [ text "First Name Placeholder" ]
                                        , input
                                            [ type_ "text"
                                            , class "form-control"
                                            , value promo.firstNamePlaceholder
                                            , onInput FirstNamePlaceholderUpdated
                                            ]
                                            []
                                        ]
                                    , div
                                        [ class "form-group"
                                        ]
                                        [ label [] [ text "Last Name Placeholder" ]
                                        , input
                                            [ type_ "text"
                                            , class "form-control"
                                            , value promo.lastNamePlaceholder
                                            , onInput LastNamePlaceholderUpdated
                                            ]
                                            []
                                        ]
                                    ]
                                , div
                                    [ class "form-group" ]
                                    [ label [] [ text "Email Placeholder" ]
                                    , input
                                        [ type_ "text"
                                        , class "form-control"
                                        , value promo.emailPlaceholder
                                        , onInput EmailPlaceholerUpdated
                                        ]
                                        []
                                    ]
                                ]
                            ]
                        , sectionFields
                            ThankyouSection
                            [ div
                                [ class "form-group" ]
                                [ label [] [ text "Headline Text" ]
                                , textarea
                                    [ class "form-control wp_editor"
                                    , id "thank-you-headline-editor"
                                    , attribute "data-html" promo.thankYouMessage
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group"
                                , Utils.Html.hideIfFalse (hasBody promo.promoType)
                                ]
                                [ label [] [ text "Body Text" ]
                                , textarea
                                    [ class "form-control wp_editor"
                                    , id "thank-you-body-editor"
                                    , attribute "data-html" promo.thankYouBody
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Close Button Text" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control"
                                    , value promo.close
                                    , onInput CloseTextUpdated
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Close Button Action" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeString CloseButtonActionUpdated
                                    ]
                                    [ stringOption promo.closeButtonAction "close" "Hide Optin"
                                    , stringOption promo.closeButtonAction "link" "Redirect to link"
                                    ]
                                ]
                            , div [ Utils.Html.hideIfFalse (promo.closeButtonAction == "link") ]
                                [ div
                                    [ class "form-group"
                                    ]
                                    [ label [] [ text "Close Button URL" ]
                                    , input
                                        [ type_ "text"
                                        , class "form-control"
                                        , value promo.closeButtonUrl
                                        , onInput CloseButtonUrlUpdated
                                        ]
                                        []
                                    ]
                                , div
                                    [ class "form-group" ]
                                    [ label [] [ text "Open in new window" ]
                                    , Utils.Html.switch ToggleCloseButtonNewWindow "" promo.closeButtonNewWindow []
                                    ]
                                ]
                            ]
                        , sectionFields
                            FontsSection
                            [ div
                                [ class "form-group" ]
                                [ label [] [ text "Body Font" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeString TextFontUpdated
                                    ]
                                    (fontOptions promo.textFont)
                                ]
                            , hr [ Utils.Html.hideIfTrue True ] []
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Button Font" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeString ButtonFontUpdated
                                    ]
                                    (fontOptions promo.buttonFont)
                                ]
                            ]
                        , sectionFields
                            ImageSection
                            [ div
                                [ class "form-group" ]
                                [ label [] [ text "Image Position" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeString ImagePositionUpdated
                                    ]
                                    [ stringOption promo.imagePosition "none" "No Image"
                                    , stringOption promo.imagePosition "above" "Image above the text"
                                    , stringOption promo.imagePosition "below" "Image below the text"
                                    , stringOption promo.imagePosition "right" "Image right of the text"
                                    , stringOption promo.imagePosition "left" "Image left of the text"
                                    , stringOption promo.imagePosition "full" "Full Image (No text)"
                                    ]
                                ]
                            , div
                                [ class "form-group"
                                , Utils.Html.hideIfTrue (promo.imagePosition == "none")
                                ]
                                [ div
                                    [ class "image-preview m-t-20"
                                    , Utils.Html.hideIfTrue (String.length promo.imageUrl == 0)
                                    ]
                                    [ img [ src (expandUrlPath model promo.imageUrl) ] [] ]
                                , div
                                    [ onClick ChooseOptinImage, class "btn m-t-10 large green" ]
                                    [ i [ class "fa fa-picture-o" ] [], text "Choose an image..." ]
                                ]
                            ]
                        , sectionFields
                            PositionSection
                            [ div
                                [ class "form-group" ]
                                [ label [] [ text "Placement" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeString PlacementUpdated
                                    ]
                                    [ stringOption promo.placement "top" "Top"
                                    , stringOption promo.placement "bottom" "Bottom"
                                    ]
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Fixed Position" ]
                                , Utils.Html.switch TogglePositionFixed "" promo.positionFixed []
                                ]
                            , div
                                [ class "form-group"
                                , Utils.Html.disableIfFalse promo.positionFixed
                                ]
                                [ label [] [ text "Adjust page margins" ]
                                , Utils.Html.switch TogglePushPage "" promo.pushPage []
                                ]
                            ]
                        , sectionFields
                            ColorAndDisplaySection
                            [ div
                                [ class "form-group" ]
                                [ label [] [ text "Size" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeString PromoSizeUpdated
                                    ]
                                    [ stringOption promo.size "x-small" "Extra Small"
                                    , stringOption promo.size "small" "Small"
                                    , stringOption promo.size "medium" "Medium"
                                    , stringOption promo.size "large" "Large"
                                    , stringOption promo.size "x-large" "Extra Large"
                                    ]
                                ]
                            , div
                                [ class "form-group m-t-10" ]
                                [ label [] [ text "Animate Entry" ]
                                , Utils.Html.switch ToggleAnimate "" promo.animate []
                                ]
                            , div
                                [ class "form-group m-t-10" ]
                                [ label [] [ text "Wiggle Button" ]
                                , Utils.Html.switch ToggleWiggleButton "" promo.wiggleButton []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Body Bg Color" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control color-picker"
                                    , attribute "data-variable" "bgColor"
                                    , attribute "data-color" promo.bgColor
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Form Bg Color" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control color-picker"
                                    , attribute "data-variable" "formBgColor"
                                    , attribute "data-color" promo.formBgColor
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Text Color" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control color-picker"
                                    , attribute "data-variable" "textColor"
                                    , attribute "data-color" promo.textColor
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Button Text Color" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control color-picker"
                                    , attribute "data-variable" "buttonColor"
                                    , attribute "data-color" promo.buttonColor
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Button Bg Color" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control color-picker"
                                    , attribute "data-variable" "buttonBgColor"
                                    , attribute "data-color" promo.buttonBgColor
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Border Color" ]
                                , input
                                    [ type_ "text"
                                    , class "form-control color-picker"
                                    , attribute "data-variable" "borderColor"
                                    , attribute "data-color" promo.borderColor
                                    ]
                                    []
                                ]
                            , div
                                [ class "form-group", Utils.Html.hideIfTrue True ]
                                [ label [] [ text "Border Type" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeString BorderTypeUpdated
                                    ]
                                    [ stringOption promo.borderType "solid" "Solid Color"
                                    , stringOption promo.borderType "airmail" "Airmail Stripes"
                                    ]
                                ]
                            , div
                                [ class "form-group", Utils.Html.hideIfTrue (promo.promoType == "bar") ]
                                [ label [] [ text "Border Position" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeString BorderPositionUpdated
                                    ]
                                    [ stringOption promo.borderPosition "all" "All Sides"
                                    , stringOption promo.borderPosition "top" "Top"
                                    , stringOption promo.borderPosition "bottom" "Bottom"
                                    , stringOption promo.borderPosition "left" "Left"
                                    , stringOption promo.borderPosition "right" "Right"
                                    ]
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Border Width" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeMaybeFloat BorderWidthUpdated
                                    ]
                                    [ floatOption promo.borderWidth 0 "0 pixels"
                                    , floatOption promo.borderWidth 1 "1 pixel"
                                    , floatOption promo.borderWidth 2 "2 pixels"
                                    , floatOption promo.borderWidth 3 "3 pixels"
                                    , floatOption promo.borderWidth 4 "4 pixels"
                                    , floatOption promo.borderWidth 5 "5 pixels"
                                    , floatOption promo.borderWidth 6 "6 pixels"
                                    , floatOption promo.borderWidth 7 "7 pixels"
                                    , floatOption promo.borderWidth 8 "8 pixels"
                                    , floatOption promo.borderWidth 9 "9 pixels"
                                    , floatOption promo.borderWidth 10 "10 pixels"
                                    ]
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "Textbox/Button Radius" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeMaybeFloat InputBorderRadiusUpdated
                                    ]
                                    [ floatOption promo.inputBorderRadius 0 "0 pixels"
                                    , floatOption promo.inputBorderRadius 1 "1 pixel"
                                    , floatOption promo.inputBorderRadius 2 "2 pixels"
                                    , floatOption promo.inputBorderRadius 3 "3 pixels"
                                    , floatOption promo.inputBorderRadius 4 "4 pixels"
                                    , floatOption promo.inputBorderRadius 5 "5 pixels"
                                    , floatOption promo.inputBorderRadius 6 "6 pixels"
                                    , floatOption promo.inputBorderRadius 7 "7 pixels"
                                    , floatOption promo.inputBorderRadius 8 "8 pixels"
                                    , floatOption promo.inputBorderRadius 9 "9 pixels"
                                    , floatOption promo.inputBorderRadius 10 "10 pixels"
                                    ]
                                ]
                            , div [ Utils.Html.hideIfFalse (promo.goal == "email") ]
                                [ div
                                    [ class "form-group" ]
                                    [ label [] [ text "TextBox Bg Color" ]
                                    , input
                                        [ type_ "text"
                                        , class "form-control color-picker"
                                        , attribute "data-variable" "inputBgColor"
                                        , attribute "data-color" promo.inputBgColor
                                        ]
                                        []
                                    ]
                                , div
                                    [ class "form-group" ]
                                    [ label [] [ text "Textbox Border Color" ]
                                    , input
                                        [ type_ "text"
                                        , class "form-control color-picker"
                                        , attribute "data-variable" "inputBorderColor"
                                        , attribute "data-color" promo.inputBorderColor
                                        ]
                                        []
                                    ]
                                , div
                                    [ class "form-group" ]
                                    [ label [] [ text "Textbox Border Width" ]
                                    , select
                                        [ class "form-control"
                                        , Utils.Html.onSelectChangeMaybeFloat InputBorderWidthUpdated
                                        ]
                                        [ floatOption promo.inputBorderWidth 0 "0 pixels"
                                        , floatOption promo.inputBorderWidth 1 "1 pixel"
                                        , floatOption promo.inputBorderWidth 2 "2 pixels"
                                        , floatOption promo.inputBorderWidth 3 "3 pixels"
                                        , floatOption promo.inputBorderWidth 4 "4 pixels"
                                        , floatOption promo.inputBorderWidth 5 "5 pixels"
                                        ]
                                    ]
                                , div
                                    [ class "form-group" ]
                                    [ label [] [ text "Textbox Text Color" ]
                                    , select
                                        [ class "form-control"
                                        , Utils.Html.onSelectChangeString InputTextClassUpdated
                                        ]
                                        [ stringOption promo.inputTextClass "dark" "Dark"
                                        , stringOption promo.inputTextClass "light" "Light"
                                        ]
                                    ]
                                ]
                            ]
                        , sectionFields
                            TargetingSection
                            [ div []
                                [ div
                                    [ class "form-group", Utils.Html.hideIfTrue (isEmbedded promo) ]
                                    [ label [] [ text "When does it display?" ]
                                    , select
                                        [ class "form-control"
                                        , Utils.Html.onSelectChangeMaybeFloat DelaySecondsUpdated
                                        ]
                                        [ floatOption promo.displayDelaySeconds 0 "Immediately"
                                        , floatOption promo.displayDelaySeconds 0.5 "1/2 second delay"
                                        , floatOption promo.displayDelaySeconds 1 "1 second delay"
                                        , floatOption promo.displayDelaySeconds 2 "2 seconds delay"
                                        , floatOption promo.displayDelaySeconds 5 "5 seconds delay"
                                        , floatOption promo.displayDelaySeconds 10 "10 seconds delay"
                                        , floatOption promo.displayDelaySeconds 30 "30 seconds delay"
                                        , floatOption promo.displayDelaySeconds 60 "60 seconds delay"
                                        ]
                                    ]
                                , div
                                    [ class "form-group" ]
                                    [ label [] [ text "Show on pages" ]
                                    , select
                                        [ class "form-control", Utils.Html.onSelectChangeString ConditionPageUpdated ]
                                        [ stringOption promo.conditionPage "all" "All pages"
                                        , stringOption promo.conditionPage "front" "Front page"
                                        , stringOption promo.conditionPage "post" "Blog posts"
                                        , stringOption promo.conditionPage "page" "Static pages"
                                        , stringOption promo.conditionPage "archive" "Archive pages"
                                        , stringOption promo.conditionPage "custom" "Specific URL"
                                        ]
                                    ]
                                , div
                                    [ class "form-group"
                                    , Utils.Html.hideIfFalse (promo.conditionPage == "custom")
                                    ]
                                    [ label [] [ text "Specific URL" ]
                                    , input
                                        [ type_ "text"
                                        , class "form-control"
                                        , value promo.conditionPageUrl
                                        , onInput ConditionPageUrlUpdated
                                        ]
                                        []
                                    ]
                                , div
                                    [ class "form-group m-t-10" ]
                                    [ label [] [ text "Desktop devices" ]
                                    , Utils.Html.switch ToggleConditionDeviceDesktop "" promo.conditionDeviceDesktop []
                                    ]
                                , div
                                    [ class "form-group m-t-10" ]
                                    [ label [] [ text "Tablet devices" ]
                                    , Utils.Html.switch ToggleConditionDeviceTablet "" promo.conditionDeviceTablet []
                                    ]
                                , div
                                    [ class "form-group m-t-10" ]
                                    [ label [] [ text "Mobile devices" ]
                                    , Utils.Html.switch ToggleConditionDeviceMobile "" promo.conditionDeviceMobile []
                                    ]
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "When the user presses close" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeMaybeInt HideCookieDaysUpdated
                                    ]
                                    (cookieDayOptions promo.hideCookieDuration)
                                ]
                            , div
                                [ class "form-group" ]
                                [ label [] [ text "When the user completes a goal" ]
                                , select
                                    [ class "form-control"
                                    , Utils.Html.onSelectChangeMaybeInt SuccessCookieDaysUpdated
                                    ]
                                    (cookieDayOptions promo.successCookieDuration)
                                ]
                            ]
                        ]
                    , div
                        [ class "preview" ]
                        [ iframe
                            [ id "optinengine-preview"
                            , src "/?optinengine-preview"
                            ]
                            []
                        ]
                    ]

            Nothing ->
                div [] []


setPreviewPromo : Model -> PromoInfo -> Cmd Msg
setPreviewPromo model promo =
    Ports.setPromo
        { promo = promo
        , affiliateId = model.affiliateId
        , affiliateEnabled = model.affiliateEnabled
        }


updatePromo : Model -> Bool -> PromoInfo -> ( Model, Cmd Msg )
updatePromo model animate promo =
    if animate == True then
        ( { model | promoToEdit = Just promo, editorDirty = True }
        , setPreviewPromo model { promo | displayDelaySeconds = 0 }
        )
    else
        ( { model
            | promoToEdit = Just promo
            , editorDirty = True
          }
        , setPreviewPromo model
            { promo
                | displayDelaySeconds = 0
                , animate = False
            }
        )


loading : Model -> Html Msg
loading model =
    div
        [ Utils.Html.hideIfFalse model.isLoading ]
        [ Html.map LoadingMsg Loading.viewFull ]


maxId : Int
maxId =
    (2 ^ 32)


closeEditor : Model -> ( Model, Cmd Msg )
closeEditor model =
    ( { model | promoToEdit = Nothing, confirm = Confirm.close model.confirm }
    , Ports.enableBodyScroll True
    )


showError : Model -> Http.Error -> ( Model, Cmd Msg )
showError model err =
    let
        ( errorMessage, errorBody ) =
            case err of
                Http.BadStatus res ->
                    (case (decodeString decodeApiError res.body) of
                        Ok info ->
                            ( info.error, "" )

                        Err _ ->
                            ( "An unknown error occured: ", (toString err) )
                    )

                _ ->
                    ( "An unknown error occured: ", (toString err) )
    in
        Debug.log (toString err)
            ( { model
                | isLoading = False
                , alert = Alert.show model.alert errorMessage errorBody
              }
            , Cmd.none
            )


savePromo : Model -> ActionAfterSaved -> ( Model, Cmd Msg )
savePromo model action =
    case model.promoToEdit of
        Just promo ->
            if String.length promo.name > 0 then
                ( { model | isLoading = True }
                , API.updatePromo
                    model.api
                    (PromoSaved action)
                    promo
                )
            else
                ( { model
                    | setPromoNameDialog = Dialog.show model.setPromoNameDialog
                    , onSavePromoAction = action
                    , promoName = ""
                  }
                , Cmd.none
                )

        Nothing ->
            ( model, Cmd.none )


showShortcode : Model -> Model
showShortcode model =
    { model | viewShortcodeModal = Dialog.show model.viewShortcodeModal }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        BootDataResults (Ok res) ->
            ( { model
                | isLoading = False
                , promos = res.promos
                , leadCount = res.leadCount
                , emailProviders = res.emailProviders
                , subscribeNewsletterEmail = res.userEmail
                , subscribeNewsletterFirstName = res.userFirstName
                , subscribeNewsletterLastName = res.userLastName
                , affiliateId = res.affiliateId
                , affiliateEnabled = res.affiliateEnabled
                , loggingEnabled = res.loggingEnabled
              }
            , Cmd.none
            )

        BootDataResults (Err err) ->
            showError model err

        LeadListResults (Err err) ->
            showError model err

        ReloadLeadListResults (Err err) ->
            showError model err

        AlertMsg msg_ ->
            ( { model
                | alert = Alert.update msg_ model.alert
              }
            , Cmd.none
            )

        EditPromo promo ->
            ( { model
                | promoToEdit = Just promo
                , editorDirty = False
                , activeSection = TypeAndGoalSection
              }
            , Cmd.batch
                [ setPreviewPromo model { promo | displayDelaySeconds = 0 }
                , Ports.enableBodyScroll False
                ]
            )

        UpdatePreview ->
            case model.promoToEdit of
                Just promo ->
                    ( model, setPreviewPromo model promo )

                Nothing ->
                    ( model, Cmd.none )

        ToggleCheckbox ->
            ( model, Cmd.none )

        OpenSection val sectionType ->
            ( { model | activeSection = sectionType }
            , Ports.showThankyou (sectionType == ThankyouSection)
            )

        ColorUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    case val.variable of
                        "bgColor" ->
                            updatePromo model False { promo | bgColor = val.color }

                        "textColor" ->
                            updatePromo model False { promo | textColor = val.color }

                        "buttonColor" ->
                            updatePromo model False { promo | buttonColor = val.color }

                        "buttonBgColor" ->
                            updatePromo model False { promo | buttonBgColor = val.color }

                        "borderColor" ->
                            updatePromo model False { promo | borderColor = val.color }

                        "formBgColor" ->
                            updatePromo model False { promo | formBgColor = val.color }

                        "inputBgColor" ->
                            updatePromo model False { promo | inputBgColor = val.color }

                        "inputBorderColor" ->
                            updatePromo model False { promo | inputBorderColor = val.color }

                        _ ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ToggleWiggleButton ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | wiggleButton = not promo.wiggleButton }

                Nothing ->
                    ( model, Cmd.none )

        PromoSizeUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model True { promo | size = val }

                Nothing ->
                    ( model, Cmd.none )

        DelaySecondsUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    case val of
                        Just delay ->
                            updatePromo model False { promo | displayDelaySeconds = delay }

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        PlacementUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model True { promo | placement = val }

                Nothing ->
                    ( model, Cmd.none )

        TogglePositionFixed ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model True { promo | positionFixed = not promo.positionFixed }

                Nothing ->
                    ( model, Cmd.none )

        TogglePushPage ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | pushPage = not promo.pushPage }

                Nothing ->
                    ( model, Cmd.none )

        HeadlineUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | headline = val }

                Nothing ->
                    ( model, Cmd.none )

        ButtonTextUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | button = val }

                Nothing ->
                    ( model, Cmd.none )

        TextFontUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | textFont = val }

                Nothing ->
                    ( model, Cmd.none )

        ButtonFontUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | buttonFont = val }

                Nothing ->
                    ( model, Cmd.none )

        HideCookieDaysUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    case val of
                        Just days ->
                            updatePromo model False { promo | hideCookieDuration = days }

                        _ ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SuccessCookieDaysUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    case val of
                        Just days ->
                            updatePromo model False { promo | successCookieDuration = days }

                        _ ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveAndClose ->
            savePromo model AfterSavedCloseEditor

        PromosUpdated (Ok _) ->
            let
                newModel =
                    { model | isLoading = False }
            in
                ( { newModel | promoToEdit = Nothing, editorDirty = False }
                , Cmd.batch
                    [ loadBootData model.api
                    , Ports.enableBodyScroll True
                    ]
                )

        PromosUpdated (Err err) ->
            showError model err

        PromoSaved action (Ok promoId) ->
            let
                newModel =
                    { model | isLoading = False }
            in
                case action of
                    AfterSavedCloseEditor ->
                        ( { newModel | promoToEdit = Nothing, editorDirty = False }
                        , Cmd.batch
                            [ loadBootData model.api
                            , Ports.enableBodyScroll True
                            ]
                        )

                    AfterSavedShowShortcode ->
                        case model.promoToEdit of
                            Just promo ->
                                let
                                    newPromo =
                                        { promo | id = Just promoId.promoId }

                                    updatedPromoModel =
                                        { newModel | promoToEdit = Just newPromo }
                                in
                                    ( showShortcode updatedPromoModel, loadBootData model.api )

                            Nothing ->
                                ( newModel, loadBootData model.api )

                    _ ->
                        ( newModel, loadBootData model.api )

        PromoSaved action (Err err) ->
            showError model err

        AddPromo ->
            ( { model
                | showTemplatePicker = not model.showTemplatePicker
              }
            , Ports.enableBodyScroll False
            )

        LoadingMsg msg_ ->
            model ! []

        ConfirmNo type_ ->
            ( { model | confirm = Confirm.close model.confirm }, Cmd.none )

        ConfirmYes type_ ->
            let
                newModel =
                    { model | confirm = Confirm.close model.confirm }
            in
                case type_ of
                    CloseEditor ->
                        closeEditor model

                    DeletePromo promo ->
                        case promo.id of
                            Just id ->
                                ( { newModel | isLoading = True }
                                , API.deletePromo model.api
                                    PromosUpdated
                                    id
                                )

                            Nothing ->
                                ( newModel, Cmd.none )

                    EmptyLeadList ->
                        ( { newModel | isLoading = True }
                        , API.emptyLeadList model.api
                            LeadListUpdated
                        )

                    DeleteLead lead ->
                        ( { newModel | isLoading = True }
                        , API.deleteLead
                            model.api
                            (LeadDeleted lead)
                            lead.id
                        )

                    DeleteEmailProvider provider ->
                        ( { newModel | isLoading = True }
                        , API.deleteEmailProvider
                            model.api
                            EmailProvidersUpdated
                            provider.id
                        )

        ConfirmMsg msg_ ->
            ( { model
                | confirm = Confirm.update msg_ model.confirm
              }
            , Cmd.none
            )

        CloseEditorWithoutConfirm ->
            closeEditor model

        SetTab tab ->
            ( { model | activeTab = tab }, Cmd.none )

        LeadListUpdated (Ok res) ->
            ( model
            , loadBootData model.api
            )

        LeadListUpdated (Err err) ->
            showError model err

        ExportLeads ->
            let
                url =
                    model.tools ++ "?action=optinengine-export-leads"
            in
                ( model, Ports.redirect url )

        CreateVariation promo ->
            let
                duplicatePromo =
                    copyPromo promo
            in
                ( { model | promoToEdit = Just duplicatePromo }
                , Cmd.batch
                    [ setPreviewPromo model duplicatePromo
                    , Ports.enableBodyScroll False
                    ]
                )

        ToggleEnablePromo promo ->
            ( { model | isLoading = True }
            , API.updatePromo
                model.api
                (PromoSaved AfterSavedDoNothing)
                { promo | isEnabled = not promo.isEnabled }
            )

        LeadListResults (Ok res) ->
            ( { model
                | leads = List.append model.leads res.leads
                , isLoading = False
                , hasMoreLeads = res.hasMore
              }
            , Cmd.none
            )

        ReloadLeadListResults (Ok res) ->
            ( { model
                | leads = res.leads
                , isLoading = False
                , hasMoreLeads = res.hasMore
              }
            , Cmd.none
            )

        LoadMoreLeads ->
            let
                last_id =
                    List.foldr
                        (\lead current ->
                            (Basics.min current lead.id)
                        )
                        maxId
                        model.leads
            in
                ( { model | isLoading = True }
                , API.listLeads model.api
                    LeadListResults
                    (if last_id == maxId then
                        Nothing
                     else
                        Just last_id
                    )
                )

        LeadDeleted lead (Ok res) ->
            {-
               Decrement the count in the lists array and remove the lead from our results
               so we don't need to hit the server again
            -}
            ( { model
                | isLoading = False
                , leads = List.filter (\c -> c.id /= lead.id) model.leads
                , leadCount = model.leadCount - 1
              }
            , Cmd.none
            )

        LeadDeleted lead (Err err) ->
            showError model err

        GoalUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | goal = val }

                Nothing ->
                    ( model, Cmd.none )

        TypeUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model True { promo | promoType = val }

                Nothing ->
                    ( model, Cmd.none )

        LinkUrlUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | linkUrl = val }

                Nothing ->
                    ( model, Cmd.none )

        ToggleOpenInNewWindow ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | openLinkNewWindow = not promo.openLinkNewWindow }

                Nothing ->
                    ( model, Cmd.none )

        EmailPlaceholerUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | emailPlaceholder = val }

                Nothing ->
                    ( model, Cmd.none )

        NamePlaceholerUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | namePlaceholder = val }

                Nothing ->
                    ( model, Cmd.none )

        ThankYouMessageUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | thankYouMessage = val }

                Nothing ->
                    ( model, Cmd.none )

        ConditionPageUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | conditionPage = val }

                Nothing ->
                    ( model, Cmd.none )

        ConditionPageUrlUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | conditionPageUrl = val }

                Nothing ->
                    ( model, Cmd.none )

        ToggleConditionDeviceDesktop ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | conditionDeviceDesktop = not promo.conditionDeviceDesktop }

                Nothing ->
                    ( model, Cmd.none )

        ToggleConditionDeviceTablet ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | conditionDeviceTablet = not promo.conditionDeviceTablet }

                Nothing ->
                    ( model, Cmd.none )

        ToggleConditionDeviceMobile ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | conditionDeviceMobile = not promo.conditionDeviceMobile }

                Nothing ->
                    ( model, Cmd.none )

        BodyUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | body = val }

                Nothing ->
                    ( model, Cmd.none )

        CloseTextUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | close = val }

                Nothing ->
                    ( model, Cmd.none )

        ToggleAnimate ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model True { promo | animate = not promo.animate }

                Nothing ->
                    ( model, Cmd.none )

        BorderWidthUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | borderWidth = Maybe.withDefault 0 val }

                Nothing ->
                    ( model, Cmd.none )

        EmailProvierUpdated val ->
            let
                firstListId =
                    case (providerInfo model val) of
                        Nothing ->
                            ""

                        Just provider ->
                            case (List.head provider.lists) of
                                Just list ->
                                    list.identifier

                                Nothing ->
                                    ""
            in
                case model.promoToEdit of
                    Just promo ->
                        updatePromo model False { promo | emailProvider = val, emailProviderListId = firstListId }

                    Nothing ->
                        ( model, Cmd.none )

        CustomFormBodyUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | customFormBody = val }

                Nothing ->
                    ( model, Cmd.none )

        AddEmailAccount ->
            ( { model
                | addEmailAccountDialog = Dialog.show model.addEmailAccountDialog
                , addEmailAccountName = ""
                , addEmailAccountApiKey = ""
                , addEmailAccountProvider = "mailchimp"
                , addEmailAccountId = ""
                , addEmailAccountApiUrl = ""
              }
            , Cmd.none
            )

        CancelAddAccount ->
            ( { model | addEmailAccountDialog = Dialog.close model.addEmailAccountDialog }, Cmd.none )

        AddEmailAccountProviderUpdated val ->
            ( { model | addEmailAccountProvider = val }, Cmd.none )

        AddEmailAccountProviderAccountNameUpdated val ->
            ( { model | addEmailAccountName = val }, Cmd.none )

        AddEmailAccountProviderApiKeyUpdated val ->
            ( { model | addEmailAccountApiKey = val }, Cmd.none )

        ConfirmAddEmailAccount ->
            case model.addEmailAccountProvider of
                "mailchimp" ->
                    ( { model | isLoading = True }
                    , API.registerMailChimpAccount model.api
                        EmailAccountAdded
                        model.addEmailAccountName
                        model.addEmailAccountApiKey
                    )

                "getresponse" ->
                    ( { model | isLoading = True }
                    , API.registerGetResponseAccount model.api
                        EmailAccountAdded
                        model.addEmailAccountName
                        model.addEmailAccountApiKey
                    )

                "aweber" ->
                    ( { model | isLoading = True }
                    , API.registerAweberAccount model.api
                        EmailAccountAdded
                        model.addEmailAccountName
                        model.addEmailAccountApiKey
                    )

                "drip" ->
                    ( { model | isLoading = True }
                    , API.registerDripAccount model.api
                        EmailAccountAdded
                        model.addEmailAccountName
                        model.addEmailAccountId
                        model.addEmailAccountApiKey
                    )

                "campaignmonitor" ->
                    ( { model | isLoading = True }
                    , API.registerCampaignMonitorAccount model.api
                        EmailAccountAdded
                        model.addEmailAccountName
                        model.addEmailAccountApiKey
                    )

                "intercom" ->
                    ( { model | isLoading = True }
                    , API.registerIntercomAccount model.api
                        EmailAccountAdded
                        model.addEmailAccountName
                        model.addEmailAccountApiKey
                    )

                "activecampaign" ->
                    ( { model | isLoading = True }
                    , API.registerActiveCampaignAccount model.api
                        EmailAccountAdded
                        model.addEmailAccountName
                        model.addEmailAccountApiKey
                        model.addEmailAccountApiUrl
                    )

                _ ->
                    ( model, Cmd.none )

        EmailAccountAdded (Ok res) ->
            ( { model
                | isLoading = False
                , addEmailAccountDialog = Dialog.close model.addEmailAccountDialog
              }
            , loadBootData model.api
            )

        EmailAccountAdded (Err err) ->
            showError model err

        RefreshEmailProvider provider ->
            ( { model | isLoading = True }
            , API.refreshProviderLists model.api
                EmailProvidersUpdated
                provider.id
            )

        EmailProvidersUpdated (Ok res) ->
            ( { model | isLoading = False }
            , loadBootData model.api
            )

        EmailProvidersUpdated (Err err) ->
            showError model err

        NameFieldsUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | nameFields = val }

                Nothing ->
                    ( model, Cmd.none )

        EmailProviderListIdUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | emailProviderListId = val }

                Nothing ->
                    ( model, Cmd.none )

        ToggleSaveToOptinEngineLeads ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | saveToOptinEngineLeads = not promo.saveToOptinEngineLeads }

                Nothing ->
                    ( model, Cmd.none )

        ToggleDisableDoubleOptin ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | disableDoubleOptin = not promo.disableDoubleOptin }

                Nothing ->
                    ( model, Cmd.none )

        FirstNamePlaceholderUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | firstNamePlaceholder = val }

                Nothing ->
                    ( model, Cmd.none )

        LastNamePlaceholderUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | lastNamePlaceholder = val }

                Nothing ->
                    ( model, Cmd.none )

        PromoNameUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | name = val }

                Nothing ->
                    ( model, Cmd.none )

        AuthorizeEmailProvider ->
            case model.addEmailAccountProvider of
                "aweber" ->
                    ( model, Ports.openAuthPopup "https://auth.aweber.com/1.0/oauth/authorize_app/7043e809" )

                _ ->
                    ( model, Cmd.none )

        AddEmailAccountIdUpdated val ->
            ( { model | addEmailAccountId = val }, Cmd.none )

        SubscribeNewsletterEmailUpdated val ->
            ( { model | subscribeNewsletterEmail = val }, Cmd.none )

        SubscribeNewsletterFirstNameUpdated val ->
            ( { model | subscribeNewsletterFirstName = val }, Cmd.none )

        SubscribeNewsletterLastNameUpdated val ->
            ( { model | subscribeNewsletterLastName = val }, Cmd.none )

        FormFieldOrientationUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | formFieldOrientation = val }

                Nothing ->
                    ( model, Cmd.none )

        FormOrientationUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | formOrientation = val }

                Nothing ->
                    ( model, Cmd.none )

        InputBorderWidthUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | inputBorderWidth = Maybe.withDefault 0 val }

                Nothing ->
                    ( model, Cmd.none )

        InputTextClassUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | inputTextClass = val }

                Nothing ->
                    ( model, Cmd.none )

        InputBorderRadiusUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | inputBorderRadius = Maybe.withDefault 0 val }

                Nothing ->
                    ( model, Cmd.none )

        AddPromoFromTemplate promo promoType ->
            let
                newPromo =
                    { promo | promoType = promoType }
            in
                ( { model
                    | promoToEdit = Just newPromo
                    , editorDirty = False
                    , showTemplatePicker = False
                    , pickOptinTypeModal = Dialog.close model.pickOptinTypeModal
                  }
                , Cmd.batch [ setPreviewPromo model newPromo, Ports.enableBodyScroll False ]
                )

        CloseTemplatePicker ->
            ( { model | showTemplatePicker = False }
            , Ports.enableBodyScroll True
            )

        SetTemplates templates ->
            ( { model | templates = templates }
            , Cmd.none
            )

        FilterTemplates tag ->
            ( { model | templateFilter = tag }
            , Cmd.none
            )

        AddEmailAccountApiUrlUpdated value ->
            ( { model | addEmailAccountApiUrl = value }
            , Cmd.none
            )

        BodyHtmlUpdated html ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | body = html }

                Nothing ->
                    ( model, Cmd.none )

        HeadlineHtmlUpdated html ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | headline = html }

                Nothing ->
                    ( model, Cmd.none )

        SetPromoNameUpdated val ->
            ( { model | promoName = val }, Cmd.none )

        ConfirmSetPromoName ->
            case model.promoToEdit of
                Just promo ->
                    let
                        newPromo =
                            { promo | name = model.promoName }

                        newModel =
                            { model | promoToEdit = Just newPromo }
                    in
                        ( { newModel
                            | isLoading = True
                            , setPromoNameDialog = Dialog.close model.setPromoNameDialog
                          }
                        , API.updatePromo
                            model.api
                            (PromoSaved model.onSavePromoAction)
                            newPromo
                        )

                Nothing ->
                    ( model, Cmd.none )

        CancelSetPromoName ->
            ( { model | setPromoNameDialog = Dialog.close model.setPromoNameDialog }
            , Cmd.none
            )

        ChooseOptinImage ->
            ( { model
                | chooseOptinImageDialog = Dialog.show model.chooseOptinImageDialog
                , selectedPremadeImage = ""
              }
            , Cmd.none
            )

        PickImageFromMedia ->
            ( model, Ports.pickImageFromMedia () )

        SelectPremadeImage image ->
            ( { model | selectedPremadeImage = image }, Cmd.none )

        CancelChooseOptinImage ->
            ( { model | chooseOptinImageDialog = Dialog.close model.chooseOptinImageDialog }, Cmd.none )

        ConfirmChooseOptinImage ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo { model | chooseOptinImageDialog = Dialog.close model.chooseOptinImageDialog }
                        False
                        { promo | imageUrl = "{FLEX_PLUGIN_URL}/images/" ++ model.selectedPremadeImage }

                Nothing ->
                    ( model, Cmd.none )

        ImagePositionUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | imagePosition = val }

                Nothing ->
                    ( model, Cmd.none )

        PickImageFromMediaResult url ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo { model | chooseOptinImageDialog = Dialog.close model.chooseOptinImageDialog }
                        False
                        { promo | imageUrl = url }

                Nothing ->
                    ( model, Cmd.none )

        BorderTypeUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | borderType = val }

                Nothing ->
                    ( model, Cmd.none )

        BorderPositionUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | borderPosition = val }

                Nothing ->
                    ( model, Cmd.none )

        ToggleEnableAffiliate ->
            ( { model | affiliateEnabled = not model.affiliateEnabled }, Cmd.none )

        AffiliateIdUpdated val ->
            ( { model | affiliateId = val }, Cmd.none )

        UpdateAffiliateSettings ->
            ( { model | isLoading = True }
            , API.updateAffiliateSettings
                model.api
                SettingsUpdated
                model.affiliateId
                model.affiliateEnabled
            )

        SettingsUpdated (Ok res) ->
            ( { model | isLoading = False }, Cmd.none )

        SettingsUpdated (Err err) ->
            showError model err

        DownloadLogs ->
            let
                url =
                    model.tools ++ "?action=optinengine-download-logs"
            in
                ( model, Ports.redirect url )

        ToggleLoggingEnabld ->
            ( { model | isLoading = True, loggingEnabled = not model.loggingEnabled }
            , API.updateLoggingSettings
                model.api
                SettingsUpdated
                (not model.loggingEnabled)
            )

        ThankYouHtmlUpdated html ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | thankYouMessage = html }

                Nothing ->
                    ( model, Cmd.none )

        ThankYouBodyHtmlUpdated html ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | thankYouBody = html }

                Nothing ->
                    ( model, Cmd.none )

        CloseButtonActionUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | closeButtonAction = val }

                Nothing ->
                    ( model, Cmd.none )

        CloseButtonUrlUpdated val ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | closeButtonUrl = val }

                Nothing ->
                    ( model, Cmd.none )

        ToggleCloseButtonNewWindow ->
            case model.promoToEdit of
                Just promo ->
                    updatePromo model False { promo | closeButtonNewWindow = not promo.closeButtonNewWindow }

                Nothing ->
                    ( model, Cmd.none )

        ViewShortCode ->
            case model.promoToEdit of
                Just promo ->
                    if promo.id == Nothing then
                        savePromo model AfterSavedShowShortcode
                    else
                        ( showShortcode model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        CloseViewShortcode ->
            ( { model | viewShortcodeModal = Dialog.close model.viewShortcodeModal }, Cmd.none )

        AddPromoSelectTemplate promo ->
            ( { model
                | pickOptinTypeModal = Dialog.show model.pickOptinTypeModal
                , pickOptinTypePromo = Just promo
              }
            , Cmd.none
            )

        CancelPickOptinType ->
            ( { model | pickOptinTypeModal = Dialog.close model.pickOptinTypeModal }, Cmd.none )



{- load email providers -}
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.updateColor ColorUpdated
        , Ports.setTemplates SetTemplates
        , Ports.updateBodyHtml BodyHtmlUpdated
        , Ports.updateHeadlineHtml HeadlineHtmlUpdated
        , Ports.pickImageFromMediaResult PickImageFromMediaResult
        , Ports.updateThankYouHtml ThankYouHtmlUpdated
        , Ports.updateThankYouBodyHtml ThankYouBodyHtmlUpdated
        ]



-- MAIN


main : Program StartFlags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
