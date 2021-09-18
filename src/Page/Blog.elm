module Page.Blog exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.Http
import Element exposing (..)
import Head
import Head.Seo as Seo
import Html.Attributes exposing (title)
import OptimizedDecoder as Decode
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Secrets as Secrets
import Pages.Url
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


type alias Post =
    { title : String
    , image : String
    }


type alias Data =
    List Post


data : DataSource Data
data =
    DataSource.Http.get
        (Secrets.succeed "https://6mpzd5sq.api.sanity.io/v1/data/query/production?query=*%5B_type%20%3D%3D%20%22post%22%5D%0A%7Btitle%2C%20%22imageUrl%22%3A%20mainImage.asset-%3Eurl%7D")
        (Decode.field "result"
            (Decode.list
                (Decode.map2 Post
                    (Decode.field "title" Decode.string)
                    (Decode.field "imageUrl" Decode.string)
                )
            )
        )


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
            [ el [ alignTop ] <| text "Yeah! That´s my freaking blog! :D"
            , column [ centerX, centerY, spacing 20 ]
                (static.data
                    |> List.map
                        (\post ->
                            column [ spacing 8 ]
                                [ image
                                    []
                                    { src = post.image ++ "?h=200"
                                    , description = post.title
                                    }
                                , text post.title
                                ]
                        )
                )
            ]
        ]
    }
