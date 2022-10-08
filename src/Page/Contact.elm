module Page.Contact exposing (Data, Model, Msg, page)

import Browser.Navigation
import Component
import Data.Image
import DataSource exposing (DataSource)
import Element exposing (..)
import Element.Input as Input
import Head
import Head.Seo as Seo
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.Manifest exposing (DisplayMode(..))
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path
import Route exposing (Route)
import Shared exposing (template)
import Time exposing (Month(..))
import View exposing (View)


type alias Model =
    { name : String
    , email : String
    , message : String
    }


type Msg
    = NameChanged String
    | EmailChanged String
    | MessageChanged String


type alias RouteParams =
    {}


page : PageWithState RouteParams Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithLocalState
            { init = init
            , subscriptions = subscriptions
            , update = update
            , view = view
            }


type alias Data =
    ()


data : DataSource Data
data =
    DataSource.succeed ()


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Contact"
        , image = Data.Image.profile
        , description = "Contact me"
        , locale = Nothing
        , title = "Contact" -- metadata.title -- TODO
        }
        |> Seo.website


init :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> ( Model, Cmd Msg )
init url shared static =
    ( { name = ""
      , email = ""
      , message = ""
      }
    , Cmd.none
    )


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update url key shared static msg model =
    case msg of
        NameChanged name ->
            ( { model | name = name }, Cmd.none )

        EmailChanged email ->
            ( { model | email = email }, Cmd.none )

        MessageChanged message ->
            ( { model | message = message }, Cmd.none )


subscriptions :
    Maybe PageUrl
    -> RouteParams
    -> Path.Path
    -> Model
    -> Sub Msg
subscriptions url params path model =
    Sub.none


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    { title = "Contact me"
    , body =
        [ column
            [ height fill
            , width fill
            , spacing 20
            ]
            [ Component.heading
                { title = "Contact"
                , description = Nothing
                }
            , Input.username []
                { label = Input.labelHidden "Name"
                , onChange = NameChanged
                , placeholder = Just (Input.placeholder [] (text "Your name"))
                , text = model.name
                }
            , Input.email []
                { label = Input.labelHidden "Email"
                , onChange = EmailChanged
                , placeholder = Just (Input.placeholder [] (text "Your email"))
                , text = model.email
                }
            , Input.multiline
                [ height (shrink |> minimum 400)
                , width (fill |> minimum 400)
                ]
                { label = Input.labelHidden "Message"
                , onChange = MessageChanged
                , placeholder = Just (Input.placeholder [] (text "What do you want to tell me? :)"))
                , text = model.message
                , spellcheck = True
                }
            ]
        ]
    }
