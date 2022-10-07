module Page.Blog.Post_ exposing (Data, Model, Msg, page)

import Data.Post as Post
import DataSource exposing (DataSource)
import Element exposing (..)
import Element.Font as Font
import Element.Region exposing (heading)
import Head
import Head.Seo as Seo
import Markdown exposing (TableOfContent, markdown)
import Markdown.Block as Block
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path
import Shared
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { post : String }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    Post.allPosts
        |> DataSource.map (List.map (\post -> { post = post.slug }))


data : RouteParams -> DataSource Data
data routeParams =
    Post.postDetails routeParams.post


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = static.data.title
        , image =
            { url = Pages.Url.fromPath <| Path.fromString <| static.data.imageUrl
            , alt = static.data.title
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = static.data.title
        , locale = Nothing
        , title = static.data.title -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    Post.PostDetails


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = static.data.title
    , body =
        [ column
            [ centerX
            , spacing 20
            , padding 30
            , alignTop
            ]
            [ el [ centerX, Font.bold ] <| text static.data.title
            , case static.data.description of
                Just description ->
                    el [ Font.size 12 ] <| text description

                Nothing ->
                    Element.none
            , image
                [ centerX
                , width (fill |> maximum 1200)
                ]
                { src = Path.fromString static.data.imageUrl |> Path.toAbsolute
                , description = static.data.title
                }
            , case markdown <| String.replace "\u{000D}" "" static.data.content of
                Ok ( toc, renderedEls ) ->
                    column
                        [ spacing 30
                        , padding 10
                        , centerX
                        , width fill
                        ]
                        renderedEls

                Err errors ->
                    paragraph []
                        [ text "I´m sorry but it looks like I published invalid markdown."
                        , text "Feel free to contact me so I can updated and fix the problem."
                        ]
            ]
        ]
    }


viewToc : TableOfContent -> Element msg
viewToc toc =
    column
        [ spacing 10 ]
        (toc
            |> List.map
                (\headingBlock ->
                    link
                        [ Font.color <| rgb255 100 100 100
                        , Font.size <|
                            case headingBlock.level of
                                Block.H1 ->
                                    22

                                Block.H2 ->
                                    18

                                Block.H3 ->
                                    16

                                _ ->
                                    12
                        ]
                        { url = "#" ++ headingBlock.anchorId
                        , label = text headingBlock.name
                        }
                )
        )
