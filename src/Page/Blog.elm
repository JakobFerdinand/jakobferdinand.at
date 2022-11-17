module Page.Blog exposing (Data, Model, Msg, page)

import Browser.Navigation
import Component
import Data.Image
import Data.Post as Post exposing (Post)
import DataSource exposing (DataSource)
import Date exposing (Date, Unit(..))
import Element exposing (..)
import Element.Font as Font
import Element.Region exposing (description)
import Head
import Head.Seo as Seo
import Page exposing (PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path
import Platform exposing (Task)
import Shared
import Task
import View exposing (View)


type alias Model =
    Maybe Date


type Msg
    = SetDate (Maybe Date)


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
    List Post


data : DataSource Data
data =
    Post.allPosts


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Blog"
        , image = Data.Image.profile
        , description = "Blog and Notes"
        , locale = Nothing
        , title = "Blog" -- metadata.title -- TODO
        }
        |> Seo.website


init :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> ( Model, Cmd Msg )
init url shared static =
    ( Nothing
    , Task.perform (Just >> SetDate) Date.today
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
        SetDate date ->
            ( date, Cmd.none )


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
                        (static.data
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
    case Debug.log post.title post.publishDate of
        Nothing ->
            True

        Just d ->
            (Date.diff Days
                d
                today
            )
            >= 0


viewBlogPost : Post -> Element Msg
viewBlogPost post =
    link [ width fill ]
        { url = "/blog/" ++ post.slug
        , label =
            column [ spacing 8, width fill ]
                [ image
                    [ width (fill |> maximum 1200)
                    , height (fill |> maximum 200)
                    ]
                    { src = Path.fromString post.imageUrl |> Path.toAbsolute
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
