module Site exposing (config)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import LanguageTag
import LanguageTag.Language
import MimeType
import Pages.Url as Url
import SiteConfig exposing (SiteConfig)


config : SiteConfig
config =
    { canonicalUrl = "https://jakobferdinand.at"
    , head = head
    }


head : BackendTask FatalError (List Head.Tag)
head =
    [ Head.metaName "viewport" (Head.raw "width=device-width,initial-scale=1")
    , Head.metaName "mobile-web-app-capable" (Head.raw "yes")
    , Head.metaName "theme-color" (Head.raw "#ffffff")
    , Head.metaName "apple-mobile-web-app-capable" (Head.raw "yes")
    , Head.metaName "apple-mobile-web-app-status-bar-style" (Head.raw "black-translucent")
    , Head.icon [ ( 32, 32 ) ] MimeType.Png (Url.external "/favicon-32x32.png")
    , Head.icon [ ( 16, 16 ) ] MimeType.Png (Url.external "/favicon-16x16.png")
    , Head.appleTouchIcon (Just 180) (Url.external "/apple-touch-icon.png")
    , Head.appleTouchIcon (Just 192) (Url.external "/apple-touch-icon.png")
    , LanguageTag.Language.en
        |> LanguageTag.build LanguageTag.emptySubtags
        |> Head.rootLanguage
    ]
        |> BackendTask.succeed
