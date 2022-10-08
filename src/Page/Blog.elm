module Page.Blog exposing (Data, Model, Msg, page)

import Component
import Data.Image
import Data.Post as Post exposing (Post)
import DataSource exposing (DataSource)
import Date
import Element exposing (..)
import Element.Font as Font
import Element.Region exposing (description)
import Head
import Head.Seo as Seo
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }


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


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = "Jakob Ferdinands Blog"
    , body =
        [ column
            [ centerX
            , height fill
            , spacing 20
            , padding 30
            ]
            [ Component.heading
                { title = "Blog"
                , description = Just "Just a colleciton of projects and informations."
                }
            , column [ centerX, centerY, spacing 50 ]
                (static.data |> List.map viewBlogPost)
            ]
        ]
    }


viewBlogPost : Post -> Element Msg
viewBlogPost post =
    link []
        { url = "/blog/" ++ post.slug
        , label =
            column [ spacing 8 ]
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
