module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import Browser.Events exposing (onResize)
import Browser.Navigation
import DataSource
import Element exposing (..)
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html exposing (Html, menu)
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Just OnPageChange
    }


type Msg
    = OnPageChange
        { path : Path
        , query : Maybe String
        , fragment : Maybe String
        }
    | SharedMsg SharedMsg
    | BrowserResized Int Int


type alias Data =
    ()


type SharedMsg
    = NoOp


type MenuMode
    = Desktop
    | Mobile Bool


type alias Model =
    { menuMode : MenuMode
    }


init :
    Maybe Browser.Navigation.Key
    -> Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : Path
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Cmd Msg )
init navigationKey flags maybePagePath =
    ( { menuMode = Desktop }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange _ ->
            ( model, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )

        BrowserResized height width ->
            case classifyDevice { height = height, width = width } |> .class of
                Phone ->
                    ( { model | menuMode = Mobile False }, Cmd.none )

                _ ->
                    ( { model | menuMode = Desktop }, Cmd.none )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    onResize BrowserResized


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


view :
    Data
    ->
        { path : Path
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : Html msg, title : String }
view sharedData page model toMsg pageView =
    { body =
        layout
            [ width fill
            , height fill
            , Font.family
                [ Font.external
                    { name = "Source Code Pro"
                    , url = "https://fonts.googleapis.com/css2?family=Source+Code+Pro:wght@300&display=swap"
                    }
                ]
            ]
        <|
            column [ width fill, height fill ]
                [ header model.menuMode
                , column [ width fill, height fill ] pageView.body
                ]
    , title = pageView.title
    }


header : MenuMode -> Element msg
header menuMode =
    case menuMode of
        Desktop ->
            row
                [ Region.navigation
                , width fill
                , alignTop
                , padding 16
                , spacing 16
                ]
                [ newTabLink [ alignRight ] { url = "https://github.com/JakobFerdinand", label = text "Github" }
                , newTabLink [ alignRight ] { url = "https://elm-lang.org/", label = text "Elm" }
                ]

        Mobile isOpen ->
            column
                [ Region.navigation
                , alignLeft
                , padding 16
                , spacing 16
                ]
                [ text "🍔" ]
