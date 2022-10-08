module Data.Image exposing (..)

import Head.Seo exposing (Image)
import Pages.Url


profile : Image
profile =
    { url = Pages.Url.external "https://avatars1.githubusercontent.com/u/16666458?s=460&v=4"
    , alt = "Me hanging down the 'Himmelsleiter' on the Donnerkogel ferrata."
    , dimensions = Nothing
    , mimeType = Nothing
    }
