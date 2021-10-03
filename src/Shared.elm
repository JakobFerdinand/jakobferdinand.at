module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import Browser.Events
import Browser.Navigation
import DataSource
import Element exposing (..)
import Element.Font as Font
import Element.Region as Region
import Html exposing (Html)
import Json.Decode as Decode
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
    | WindowSizeChanged Device
    | SharedMsg SharedMsg


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    { device : Device
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
    let
        classify : Int -> Int -> Device
        classify height width =
            classifyDevice { height = height, width = width }

        decodeFlags =
            Decode.decodeValue
                (Decode.map2 classify
                    (Decode.field "height" Decode.int)
                    (Decode.field "width" Decode.int)
                )

        getDevice : Device
        getDevice =
            case flags of
                Pages.Flags.PreRenderFlags ->
                    { class = Desktop
                    , orientation = Portrait
                    }

                Pages.Flags.BrowserFlags value ->
                    case decodeFlags value of
                        Ok device ->
                            device

                        Err _ ->
                            { class = Desktop
                            , orientation = Portrait
                            }
    in
    ( { device = getDevice
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange _ ->
            ( model, Cmd.none )

        WindowSizeChanged device ->
            ( { model | device = device }, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    Browser.Events.onResize (\w h -> WindowSizeChanged <| classifyDevice { height = h, width = w })


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
                [ header
                , column
                    [ width fill
                    , height fill
                    , scrollbarY
                    ]
                    [ column [ width fill, height fill, padding 20 ]
                        pageView.body
                    , footer
                    ]
                ]
    , title = pageView.title
    }


header : Element msg
header =
    row
        [ width fill, alignTop, padding 16, spacing 16 ]
        [ link [ alignLeft ] { url = "/", label = el [ Font.bold, Font.size 36 ] <| text "JFW" }
        , link [ alignRight ] { url = "/about-me", label = text "AboutMe" }
        , link [ alignRight ] { url = "/blog", label = text "Blog" }
        , newTabLink [ alignRight ] { url = "https://github.com/JakobFerdinand", label = text "Github" }
        ]


footer : Element msg
footer =
    column
        [ alignBottom
        , width fill
        , spacing 16
        , padding 16
        ]
        [ row
            [ width fill
            ]
            [ newTabLink [ Font.size 12, alignRight ] { url = "https://elm-pages.com/", label = text "powered by elm-pages" }
            ]
        ]
