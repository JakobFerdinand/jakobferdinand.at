module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Route
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    ()


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask FatalError Data
data =
    BackendTask.succeed ()


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Jakob Ferdinand Wegenschimmel"
        , image =
            { url = Pages.Url.external "https://avatars1.githubusercontent.com/u/16666458?s=460&v=4"
            , alt = "Me hanging down the 'Himmelsleiter' on the Donnerkogel ferrata."
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "The personal homepage of Jakob Ferdinand Wegenschimmel"
        , locale = Nothing
        , title = "Personal Homepage of Jakob Ferdinand Wegenschimmel"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    let
        imageSize : Int
        imageSize =
            case shared.device.class of
                Phone ->
                    250

                _ ->
                    400
    in
    { title = "Jakob Ferdinand Wegenschimmel"
    , body =
        [ column
            [ Region.mainContent
            , centerX
            , centerY
            , spacing 16
            , padding 20
            ]
            [ image
                [ centerX
                , width <| px imageSize
                , height <| px imageSize
                , Border.rounded imageSize
                , clip
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
                ]
            ]
        ]
    }
