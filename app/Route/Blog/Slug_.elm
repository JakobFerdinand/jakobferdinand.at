module Route.Blog.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Element exposing (..)
import Element.Font as Font
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Markdown exposing (TableOfContent, markdown)
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Post
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    Post.allPostsGlob
        |> BackendTask.map
            (List.map
                (\globData ->
                    { slug = globData.slug
                    }
                )
            )


type alias Data =
    Post.PostDetails


type alias ActionData =
    {}


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    Post.postDetails routeParams.slug


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app sharedModel =
    { title = "Placeholder - Blog.Slug_"
    , body =
        [ column
            [ centerX
            , spacing 20
            , alignTop
            ]
            [ el [ centerX, Font.bold ] <| text app.data.title
            , case app.data.description of
                Just description ->
                    el [ Font.size 12 ] <| text description

                Nothing ->
                    Element.none
            , image
                [ centerX
                , width (fill |> maximum 1200)
                ]
                { src = app.data.imageUrl
                , description = app.data.title
                }
            , case markdown <| String.replace "\u{000D}" "" app.data.content of
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
