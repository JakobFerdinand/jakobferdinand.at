module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Element exposing (Element, alignBottom, alignLeft, alignTop, centerX, centerY, column, el, fill, height, html, image, link, newTabLink, padding, paddingXY, paragraph, px, row, spacing, text, textColumn, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Palette exposing (..)
import PaletteView
import Svg exposing (svg)
import Svg.Attributes exposing (cx, cy, r, stroke, x1, x2, y1, y2)
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, s, string)


type alias Model =
    { page : Page
    , key : Nav.Key
    }


type Msg
    = ClickedLink Browser.UrlRequest
    | ChangedUrl Url
    | GotPaletteViewMsg PaletteView.Msg


type Route
    = Home
    | PaletteView


type Page
    = HomePage
    | PaletteViewPage PaletteView.Model


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    updateUrl url { page = HomePage, key = key }


view : Model -> Document Msg
view model =
    let
        content : Element Msg
        content =
            case model.page of
                HomePage ->
                    viewContent model

                PaletteViewPage palette ->
                    PaletteView.view palette
                        |> Element.map GotPaletteViewMsg
    in
    { title = "Jakob Ferdinand Wegenschimmel"
    , body =
        [ Element.layout
            [ width fill
            , height fill
            , padding small
            , Background.color backgroundColor
            , Font.family
                [ Font.external
                    { name = "Montserrat"
                    , url = "https://fonts.googleapis.com/css?family=Montserrat:300&display=swap"
                    }
                ]
            , Font.color foregroundColor
            ]
            (column
                [ height fill ]
                [ viewHeader model
                , row
                    [ width fill, height fill ]
                    [ viewNavigation
                    , content
                    ]
                , viewFooter model
                ]
            )
        ]
    }


viewHeader : Model -> Element Msg
viewHeader model =
    column
        [ alignTop
        , width fill
        , spacing xSmall
        ]
        [ row [ width fill ]
            [ text "Header"
            ]
        , line 1
        ]


viewNavigation : Element Msg
viewNavigation =
    let
        navLink : Route -> { url : String, caption : String } -> Element Msg
        navLink targetPage { url, caption } =
            link []
                { url = url
                , label = text caption
                }
    in
    column
        [ alignLeft
        , alignTop
        , spacing small
        , paddingXY 0 small
        ]
        [ navLink Home { url = "/", caption = "Home" }
        , navLink Home { url = "/palette", caption = "Palette" }
        ]


viewContent : Model -> Element Msg
viewContent model =
    column
        [ Region.mainContent
        , centerX
        , centerY
        , spacing small
        , paddingXY 0 small
        ]
        [ image
            [ centerX
            , width <| px (xLarge * 3)
            , height <| px (xLarge * 3)
            , Border.rounded (xLarge * 3)
            , Element.clip
            ]
            { src = "https://avatars1.githubusercontent.com/u/16666458?s=460&v=4"
            , description = "Me hanging down the 'Himmelsleiter' on the Donnerkogel ferrata."
            }
        , el
            [ centerX
            , Font.size 24
            , Font.color accent1Color
            ]
            (text "Welcome!")
        , textColumn
            [ centerX
            , Font.family [
                Font.external
                { name = "Source Code Pro"
                , url = "https://fonts.googleapis.com/css2?family=Source+Code+Pro:wght@300&display=swap"
                }
            ]
            , Font.size small
            , Font.center
            , width <| px (xLarge * 4)
            ]
            [ paragraph [] [ text "I´m a software developer living in Austria." ]
            , paragraph [] [ text "In my day to day job I mostly use C# in .Net Client Applications." ]
            , paragraph [] [ text "Some time ago I discoverd the ELM programming language and immedeately felt in love with it." ]
            , paragraph [] [ text "So I decided to build my own homepage in elm. I´m excited where that will take me." ]
            ]
        , newTabLink [ centerX ] { url = "https://github.com/JakobFerdinand", label = text "My Github page." }
        , newTabLink [ centerX ] { url = "https://elm-lang.org/", label = text "A link to Elm language." }
        ]


viewFooter : Model -> Element Msg
viewFooter model =
    column
        [ alignBottom
        , width fill
        , spacing xSmall
        ]
        [ line 1
        , row
            [ width fill
            ]
            [ text "Footer"
            , el [ centerX ] (text "One is never alone with a rubber duck. - Douglas Adams")
            ]
        ]


line : Int -> Element Msg
line strokeWidth =
    el [ centerX ]
        (html
            (svg
                [ Svg.Attributes.height <| String.fromInt strokeWidth
                , Svg.Attributes.width "800"
                ]
                [ Svg.line
                    [ x1 "0"
                    , y1 "0"
                    , x2 "1200"
                    , y2 "0"
                    , stroke "black"
                    , Svg.Attributes.strokeWidth <| String.fromInt strokeWidth
                    , Svg.Attributes.fill "none"
                    ]
                    []
                ]
            )
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink onUrlRequest ->
            case onUrlRequest of
                Browser.External href ->
                    ( model, Nav.load href )

                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

        ChangedUrl url ->
            updateUrl url model

        GotPaletteViewMsg paletteMsg ->
            case model.page of
                PaletteViewPage palette ->
                    toPalette model (PaletteView.update paletteMsg palette)

                _ ->
                    ( model, Cmd.none )


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Parser.parse parser url of
        Just PaletteView ->
            PaletteView.init
                |> toPalette model

        Just Home ->
            ( { model | page = HomePage }, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


toPalette : Model -> ( PaletteView.Model, Cmd PaletteView.Msg ) -> ( Model, Cmd Msg )
toPalette model ( colors, cmd ) =
    ( { model | page = PaletteViewPage colors }
    , Cmd.map GotPaletteViewMsg cmd
    )


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map PaletteView (s "palette")
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
