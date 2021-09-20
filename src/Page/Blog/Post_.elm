module Page.Blog.Post_ exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import Element exposing (..)
import Element.Font as Font
import Head
import Head.Seo as Seo
import Markdown exposing (markdown)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Post
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
            , image [ centerX ] { src = static.data.imageUrl ++ "?h=200", description = static.data.title }
            , text "TODO: parse markdown!!!"
            , case markdown <| String.replace "\u{000D}" "" static.data.description of
                Ok ( toc, renderedEls ) ->
                    text "Markdown geht"

                Err errors ->
                    text "Markdown geht ned"
            , paragraph []
                [ text static.data.description
                ]
            ]
        ]
    }
