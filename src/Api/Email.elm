module Api.Email exposing (Email(..), EmailMessage, send, toString)

import Http
import Json.Encode as Encode exposing (Value)


send :
    EmailMessage
    -> (Result Http.Error () -> msg)
    -> Cmd msg
send message expect =
    Http.post
        { url = ".netlify/functions/send-email"
        , body = Http.jsonBody <| encodeEmail message
        , expect = Http.expectWhatever expect
        }


type Email
    = Email String


toString : Email -> String
toString email =
    case email of
        Email e ->
            e


type alias EmailMessage =
    { name : String
    , fromEmail : Email
    , message : String
    }


body : EmailMessage -> Http.Body
body email =
    Http.jsonBody <| encodeEmail email


encodeEmail : EmailMessage -> Value
encodeEmail message =
    Encode.object
        [ ( "name", Encode.string message.name )
        , ( "fromEmail", Encode.string <| toString message.fromEmail )
        , ( "message", Encode.string message.message )
        ]
