module Page.Blog exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import Element exposing (..)
import Element.Font as Font
import Head
import Head.Seo as Seo
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Post exposing (Post)
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
        , image =
            { url = Pages.Url.external "https://avatars1.githubusercontent.com/u/16666458?s=460&v=4"
            , alt = "Me hanging down the 'Himmelsleiter' on the Donnerkogel ferrata."
            , dimensions = Nothing
            , mimeType = Nothing
            }
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
            [ el [ alignTop, Font.bold ] <| text "Blog"
            , paragraph [ alignTop ]
                [ text "Just a colleciton of projects and informations." ]
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
                , el [ Font.bold ] <| text post.title
                , case post.description of
                    Just description ->
                        el [ Font.size 12 ] <| text description

                    Nothing ->
                        none
                ]
        }
