module Markdown exposing (TableOfContent, markdown)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html
import Html.Attributes
import Markdown.Block as Block exposing (ListItem, Task(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer


type alias TableOfContent =
    List
        { anchorId : String
        , name : String
        , level : Block.HeadingLevel
        }


markdown : String -> Result String ( TableOfContent, List (Element msg) )
markdown markdownString =
    case markdownString |> Markdown.Parser.parse of
        Ok okAst ->
            case Markdown.Renderer.render customElmUiRenderer okAst of
                Ok rendered ->
                    Ok ( buildToc okAst, rendered )

                Err errors ->
                    Err errors

        Err error ->
            Err (error |> List.map Markdown.Parser.deadEndToString |> String.join "\n")



--- TOC


buildToc : List Block.Block -> TableOfContent
buildToc blocks =
    gatherHeadings blocks
        |> List.map
            (\headings ->
                { anchorId = headings |> Tuple.second |> Block.extractInlineText |> rawTextToId
                , name = headings |> Tuple.second |> Block.extractInlineText
                , level = headings |> Tuple.first
                }
            )


gatherHeadings : List Block.Block -> List ( Block.HeadingLevel, List Block.Inline )
gatherHeadings blocks =
    blocks
        |> List.filterMap
            (\block ->
                case block of
                    Block.Heading level content ->
                        Just ( level, content )

                    _ ->
                        Nothing
            )


rawTextToId : String -> String
rawTextToId rawText =
    rawText
        |> String.split " "
        |> String.join "-"
        |> String.toLower



---UI Renderer


customElmUiRenderer : Markdown.Renderer.Renderer (Element msg)
customElmUiRenderer =
    elmUiRenderer



-- { elmUiRenderer
--     | html =
--         Markdown.Html.oneOf
--             [ customElmUiRenderer.html ]
-- }


elmUiRenderer : Markdown.Renderer.Renderer (Element msg)
elmUiRenderer =
    { heading = heading
    , paragraph = paragraph [ spacing 15 ]
    , blockQuote = blockQuote
    , html =
        Markdown.Html.oneOf
            [ Markdown.Html.tag "hr"
                (\_ ->
                    el
                        [ Border.widthEach { bottom = 2, top = 0, left = 0, right = 0 }
                        , width fill
                        , Border.color (rgba 0 0 0 0.5)
                        ]
                        none
                )
            ]
    , text = text
    , codeSpan = code
    , strong = \content -> row [ Font.bold ] content
    , emphasis = \content -> row [ Font.italic ] content
    , strikethrough = \content -> row [] content
    , hardLineBreak = html <| Html.br [] []
    , link = mdLink
    , image =
        \img ->
            image [ width fill ] { src = img.src, description = img.alt }
    , unorderedList = unorderdList
    , orderedList = orderedList
    , codeBlock = codeBlock
    , thematicBreak = none
    , table = column [ width fill ]
    , tableHeader = column [ width fill ]
    , tableBody = column [ width fill ]
    , tableRow = row [ width fill ]
    , tableCell = \maybeAlignment children -> paragraph [ alignTop, padding 8 ] children
    , tableHeaderCell = \maybeAlignment children -> paragraph [ Font.heavy, padding 5 ] children
    }


heading :
    { level : Block.HeadingLevel, rawText : String, children : List (Element msg) }
    -> Element msg
heading { level, rawText, children } =
    paragraph
        [ Font.size
            (case level of
                Block.H1 ->
                    36

                Block.H2 ->
                    24

                _ ->
                    20
            )
        , Font.bold
        , Region.heading <| Block.headingLevelToInt level
        ]
        children


color : { blue : Color, darkCharcoal : Color, lightBlue : Color, lightGrey : Color, white : Color }
color =
    { blue = rgb255 0x72 0x9F 0xCF
    , darkCharcoal = rgb255 0x2E 0x34 0x36
    , lightBlue = rgb255 0xC5 0xE8 0xF7
    , lightGrey = rgb255 0xE0 0xE0 0xE0
    , white = rgb255 0xFF 0xFF 0xFF
    }


blockQuote : List (Element msg) -> Element msg
blockQuote children =
    column
        [ padding 10
        , Border.widthEach { top = 0, right = 0, bottom = 0, left = 10 }
        , Border.color color.darkCharcoal
        , Background.color color.lightGrey
        ]
        children


code : String -> Element msg
code snippet =
    el
        [ Background.color color.lightGrey
        , Border.rounded 4
        , paddingXY 5 1
        , Font.family
            [ Font.external
                { url = "https://fonts.googleapis.com/css?family=Source+Code+Pro"
                , name = "Source Code Pro"
                }
            ]
        ]
    <|
        text snippet


mdLink : { title : Maybe String, destination : String } -> List (Element msg) -> Element msg
mdLink { title, destination } body =
    newTabLink
        [ htmlAttribute <| Html.Attributes.style "display" "inline-flex" ]
        { url = destination
        , label = paragraph [ Font.color color.blue ] body
        }


unorderdList : List (ListItem (Element msg)) -> Element msg
unorderdList items =
    column [ spacing 15 ]
        (items
            |> List.map
                (\(Block.ListItem task children) ->
                    row [ spacing 5 ]
                        [ row
                            [ alignTop ]
                            ((case task of
                                IncompleteTask ->
                                    Input.defaultCheckbox False

                                CompletedTask ->
                                    Input.defaultCheckbox True

                                NoTask ->
                                    el [ Font.heavy ] <| text "-"
                             )
                                :: text " "
                                :: children
                            )
                        ]
                )
        )


orderedList : Int -> List (List (Element msg)) -> Element msg
orderedList startingIndex items =
    column [ spacing 15 ] <|
        List.indexedMap
            (\index itemBlocks ->
                row [ spacing 5 ]
                    [ row [ alignTop ] <|
                        text
                            (String.fromInt (index + startingIndex) ++ " ")
                            :: itemBlocks
                    ]
            )
            items


codeBlock : { body : String, language : Maybe String } -> Element msg
codeBlock { body, language } =
    el
        [ width fill
        , scrollbarX
        , Background.color (rgba 0 0 0 0.03)
        , htmlAttribute (Html.Attributes.style "white-space" "pre")
        , padding 20
        , Font.family
            [ Font.external
                { url = "https://fonts.googleapis.com/css?family=Source+Code+Pro"
                , name = "Source Code Pro"
                }
            ]
        ]
    <|
        text body
