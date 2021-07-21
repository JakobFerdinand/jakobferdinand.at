module PaletteView exposing (Model, Msg, init, update, view)

import Browser
import Element exposing (Color, Element, alignBottom, alignLeft, centerX, centerY, column, el, fill, height, html, maximum, minimum, row, spacing, text, width)
import Element.Font as Font
import Palette exposing (..)
import Svg exposing (circle, rect, svg)
import Svg.Attributes as Attributes


type alias Model =
    {}


type Msg
    = NoOp


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


view : Model -> Element Msg
view model =
    column [ spacing normal ]
        [ el [ alignLeft, Font.heavy ] (text "Colors")
        , row
            [ spacing large
            , centerX
            , centerY
            ]
            [ viewColor { name = "foreground", color = foregroundColor, colorString = foregroundColorString }
            , viewColor { name = "background", color = backgroundColor, colorString = backgroundColorString }
            , viewColor { name = "accent1", color = accent1Color, colorString = accent1ColorString }
            , viewColor { name = "accent2", color = accent2Color, colorString = accent2ColorString }
            , viewColor { name = "accent3", color = accent3Color, colorString = accent3ColorString }
            ]
        , el [ Font.heavy ] (text "Spacings")
        , row
            [ spacing large ]
            [ viewSpacing "xxSmall" xxSmall
            , viewSpacing "xSmall" xSmall
            , viewSpacing "small" small
            , viewSpacing "normal" normal
            , viewSpacing "large" large
            , viewSpacing "xLarge" xLarge
            ]
        ]


viewColor : { name : String, color : Color, colorString : String } -> Element Msg
viewColor color =
    column
        [ height fill
        , spacing xSmall
        ]
        [ colorCircle color.colorString
        , el [ centerX ] (text color.name)
        , el [ centerX ] (text color.colorString)
        ]


viewSpacing : String -> Int -> Element Msg
viewSpacing spacingName spacingValue =
    let
        header : String
        header =
            spacingName ++ (" " ++ String.fromInt spacingValue)
    in
    column [ width fill, alignBottom, spacing normal ]
        [ el [ centerX ]
            (html
                (svg
                    [ Attributes.height <| String.fromInt spacingValue
                    , Attributes.width "20"
                    ]
                    [ rect
                        [ Attributes.width "20"
                        , Attributes.height <| String.fromInt spacingValue
                        , Attributes.fill "orange"
                        ]
                        []
                    ]
                )
            )
        , text header
        ]


colorCircle : String -> Element Msg
colorCircle color =
    let
        fill100 =
            fill
                |> maximum 100
                |> minimum 100
    in
    el
        [ centerX
        , height fill100
        , width fill100
        ]
        (html
            (svg
                [ Attributes.width "100"
                , Attributes.height "100"
                ]
                [ circle
                    [ Attributes.cx "50"
                    , Attributes.cy "50"
                    , Attributes.r "50"
                    , Attributes.fill color
                    ]
                    []
                ]
            )
        )
