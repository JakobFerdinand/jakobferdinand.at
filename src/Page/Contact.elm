module Page.Contact exposing (Data, Model, Msg, page)

import Api.Email as Email
import Browser.Navigation
import Component
import Data.Image
import DataSource exposing (DataSource)
import Element exposing (..)
import Form exposing (Form)
import Form.View
import Head
import Head.Seo as Seo
import Http
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.Manifest exposing (DisplayMode(..))
import Pages.PageUrl exposing (PageUrl)
import Path
import Shared
import View exposing (View)


type alias Model =
    Form.View.Model ModelData


type Msg
    = FormChanged (Form.View.Model ModelData)
    | SendMessage Email.EmailMessage
    | MessageSent (Result Http.Error ())


type alias RouteParams =
    {}


page : PageWithState RouteParams Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithLocalState
            { init = init
            , subscriptions = subscriptions
            , update = update
            , view = view
            }


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
        , siteName = "Contact"
        , image = Data.Image.profile
        , description = "Contact me"
        , locale = Nothing
        , title = "Contact" -- metadata.title -- TODO
        }
        |> Seo.website


init :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> ( Model, Cmd Msg )
init url shared static =
    ( clearForm
    , Cmd.none
    )


clearForm : Form.View.Model ModelData
clearForm =
    Form.View.idle
        { agreedToTerms = False
        , name = ""
        , email = ""
        , message = ""
        , errors =
            { agreedToTerms = Nothing
            , name = Nothing
            , email = Nothing
            , message = Nothing
            }
        }


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update url key shared static msg model =
    case msg of
        FormChanged newData ->
            ( newData, Cmd.none )

        SendMessage message ->
            ( model
            , Email.send message MessageSent
            )

        MessageSent result ->
            case result of
                Ok _ ->
                    ( clearForm, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


subscriptions :
    Maybe PageUrl
    -> RouteParams
    -> Path.Path
    -> Model
    -> Sub Msg
subscriptions url params path model =
    Sub.none


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    { title = "Contact me"
    , body =
        [ column
            [ height fill
            , width fill
            , spacing 20
            ]
            [ Component.heading
                { title = "Send me a message"
                , description = Nothing
                }
            , Component.layout
                { onChange = FormChanged
                , action = "Send message"
                , loading = "Sending message"
                , validation = Form.View.ValidateOnSubmit
                }
                (Form.map SendMessage form)
                model
            ]
        ]
    }


type alias ModelData =
    { agreedToTerms : Bool
    , name : String
    , email : String
    , message : String
    , errors :
        { agreedToTerms : Maybe String
        , name : Maybe String
        , email : Maybe String
        , message : Maybe String
        }
    }


nameField : Form ModelData String
nameField =
    Form.textField
        { parser =
            \name ->
                if String.length name < 2 then
                    Err "The name must have at least 2 characters"

                else
                    Ok name
        , value = .name
        , update = \value values -> { values | name = value }
        , attributes =
            { label = "Name"
            , placeholder = "Your name"
            }
        , error = .errors >> .name
        }


emailField : Form ModelData Email.Email
emailField =
    Form.emailField
        { parser = parseEmail
        , value = .email
        , update = \value values -> { values | email = value }
        , attributes =
            { label = "Email"
            , placeholder = "your@email.com"
            }
        , error = .errors >> .email
        }


parseEmail : String -> Result String Email.Email
parseEmail s =
    if String.contains "@" s then
        Ok <| Email.Email s

    else
        Err "Invalid email"


messageField : Form ModelData String
messageField =
    Form.textareaField
        { parser =
            \message ->
                if String.length message < 30 then
                    Err "The message must have at least 30 characters"

                else
                    Ok message
        , value = .message
        , update = \value values -> { values | message = value }
        , attributes =
            { label = "Message"
            , placeholder = "Enter your message..."
            }
        , error = .errors >> .message
        }


termsCheckbox : Form ModelData ()
termsCheckbox =
    Form.checkboxField
        { parser =
            \value ->
                if value then
                    Ok ()

                else
                    Err "You must accept the terms"
        , value = .agreedToTerms
        , update = \value values -> { values | agreedToTerms = value }
        , attributes = { label = "I agree to terms and conditions" }
        , error = .errors >> .agreedToTerms
        }


form : Form ModelData Email.EmailMessage
form =
    Form.succeed
        (\name email message _ ->
            Email.EmailMessage name email message
        )
        |> Form.append nameField
        |> Form.append emailField
        |> Form.append messageField
        |> Form.append termsCheckbox
