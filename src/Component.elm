module Component exposing (heading)

import Element exposing (..)
import Element.Font as Font
import Element.Region exposing (description)


heading :
    { title : String
    , description : Maybe String
    }
    -> Element msg
heading { title, description } =
    column [ spacing 8 ]
        [ el [ alignTop, Font.bold ] <| text title
        , case description of
            Just desc ->
                paragraph [ alignTop ]
                    [ text desc ]

            Nothing ->
                none
        ]
