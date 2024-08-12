module Route.Blog exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import Component
import Data.Image
import Date exposing (Date, Unit(..))
import Effect exposing (Effect)
import Element exposing (..)
import Element.Font as Font
import ErrorPage exposing (update)
import FatalError
import Head
import Head.Seo as Seo
import PagesMsg
import Post exposing (Post)
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Task
import UrlPath
import View


type Msg
    = SetDate (Maybe Date)


type alias RouteParams =
    {}


type alias Model =
    Maybe Date


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { data = data
        , head = head
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , update = update
            , init = init
            , subscriptions = subscriptions
            }


type alias Data =
    List Post


type alias ActionData =
    {}


init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init app shared =
    ( Nothing
    , Effect.fromCmd <| Task.perform (Just >> SetDate) Date.today
    )


subscriptions :
    RouteParams
    -> UrlPath.UrlPath
    -> Shared.Model
    -> Model
    -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none


data : BackendTask.BackendTask FatalError.FatalError Data
data =
    Post.allPosts


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Blog"
        , image = Data.Image.profile
        , description = "Blog and Notes"
        , locale = Nothing
        , title = "Blog" -- metadata.title -- TODO
        }
        |> Seo.website


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect.Effect msg )
update app shared msg model =
    case msg of
        SetDate date ->
            ( date, Effect.none )


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View.View (PagesMsg.PagesMsg Msg)
view app shared model =
    { title = "Jakob Ferdinands Blog"
    , body =
        [ column
            [ centerX
            , height fill
            , spacing 20
            ]
            [ Component.heading
                { title = "Blog"
                , description = Just "Just a colleciton of projects and informations."
                }
            , case model of
                Just date ->
                    column [ centerX, centerY, spacing 50 ]
                        (app.data
                            |> List.filter (isBlogPostPublished date)
                            |> List.map viewBlogPost
                        )

                Nothing ->
                    el [ centerX, centerY ] <| text "loading current date"
            ]
        ]
    }


isBlogPostPublished : Date -> Post -> Bool
isBlogPostPublished today post =
    case post.publishDate of
        Nothing ->
            True

        Just d ->
            Date.diff Days
                d
                today
                >= 0


viewBlogPost : Post -> Element msg
viewBlogPost post =
    link [ width fill ]
        { url = "/blog/" ++ post.slug
        , label =
            column [ spacing 8, width fill ]
                [ image
                    [ width (fill |> maximum 1200)
                    , height (fill |> maximum 200)
                    ]
                    { src = post.imageUrl
                    , description = post.title
                    }
                , row [ width fill ]
                    [ column
                        [ alignLeft
                        , spacing 8
                        ]
                        [ el [ Font.bold ] <| text post.title
                        , case post.description of
                            Just description ->
                                el [ Font.size 12 ] <| text description

                            Nothing ->
                                none
                        ]
                    , column
                        [ alignRight
                        , alignTop
                        , spacing 8
                        ]
                        [ el [ Font.size 12, alignRight ] <| text (Date.toIsoString post.date)
                        , el [ Font.size 12, alignRight ] <| text <| String.join "," post.tags
                        ]
                    ]
                ]
        }
