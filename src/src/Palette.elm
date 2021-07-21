module Palette exposing (..)

import Element exposing (Color, rgb255, toRgb)



-- Sizes


xxSmall : Int
xxSmall =
    4


xSmall : Int
xSmall =
    8


small : Int
small =
    16


normal : Int
normal =
    32


large : Int
large =
    64


xLarge : Int
xLarge =
    128



-- Colors
-- Desined with https://coolors.co/
-- Current color scheme: https://coolors.co/555b6e-89b0ae-bee3db-faf9f9-820933


foregroundColor : Color
foregroundColor =
    rgb255 13 19 33


foregroundColorString : String
foregroundColorString =
    "#0d1321"


backgroundColor : Color
backgroundColor =
    rgb255 250 249 249


backgroundColorString : String
backgroundColorString =
    "#faf9f9"


accent1Color : Color
accent1Color =
    rgb255 137 176 174


accent1ColorString : String
accent1ColorString =
    "#89b0ae"


accent2Color : Color
accent2Color =
    rgb255 130 9 51


accent2ColorString : String
accent2ColorString =
    "#820933"


accent3Color : Color
accent3Color =
    rgb255 85 91 110


accent3ColorString : String
accent3ColorString =
    "#555b6e"


colorToHex : Color -> String
colorToHex color =
    let
        { red, green, blue } =
            toRgb color
    in
    [ red, green, blue ]
        |> List.map toByteValue
        |> List.map round
        |> List.map toHex
        |> (::) "#"
        |> String.join ""


toByteValue : Float -> Float
toByteValue x =
    x * 255


toHex : Int -> String
toHex =
    toRadix >> String.padLeft 2 '0'


toRadix : Int -> String
toRadix n =
    let
        getChar c =
            if c < 10 then
                String.fromInt c

            else
                String.fromChar <| Char.fromCode (87 + c)
    in
    if n < 16 then
        getChar n

    else
        toRadix (n // 16) ++ getChar (modBy n 16)
