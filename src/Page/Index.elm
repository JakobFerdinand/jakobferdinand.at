module Page.Index exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Head
import Head.Seo as Seo
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
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


type alias Data =
    ()


data : DataSource Data
data =
    DataSource.succeed ()


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Jakob Ferdinand Wegenschimmel"
        , image =
            { url = Pages.Url.external "https://jakobferdinand.at"
            , alt = "Jakob Ferdinand Wegenschimmel"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "The personal homepage of Jakob Ferdinand Wegenschimmel"
        , locale = Nothing
        , title = "Jakob Ferdinand" -- metadata.title -- TODO
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = "Jakob Ferdinand Wegenschimmel"
    , body =
        [ column [ height fill, width fill ]
            [ viewContent
            ]
        ]
    }


viewContent : Element Msg
viewContent =
    column
        [ Region.mainContent
        , centerX
        , centerY
        , spacing 16
        , paddingXY 0 16
        ]
        [ image
            [ centerX
            , width <| px (128 * 3)
            , height <| px (128 * 3)
            , Border.rounded (128 * 3)
            , Element.clip
            ]
            { src = "https://avatars1.githubusercontent.com/u/16666458?s=460&v=4"
            , description = "Me hanging down the 'Himmelsleiter' on the Donnerkogel ferrata."
            }
        , el
            [ centerX
            , Font.size 24
            , Font.color <| rgb255 137 176 174
            ]
            (text "Welcome!")
        , textColumn
            [ centerX
            , Font.size 16
            , Font.center
            , width fill
            ]
            [ paragraph [] [ text "Hello, my name is Jakob Ferdinand Wegenschimmel." ]
            , paragraph [] [ text "I´m a software developer living in Austria." ]
            , paragraph [] [ text "In my day to day job I mostly use C# in .Net Client Applications." ]
            , paragraph [] [ text "Some time ago I discoverd the ELM programming language and immedeately felt in love with it." ]
            , paragraph [] [ text "So I decided to build my own homepage in elm. I´m excited where that will take me." ]
            ]
        ]
