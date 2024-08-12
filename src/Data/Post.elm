module Data.Post exposing (Post, PostDetails, allPosts, allPostsGlob, postDetails)

import BackendTask
import BackendTask.File as File
import BackendTask.Glob as Glob
import Compare exposing (Comparator)
import Date exposing (Date)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Time exposing (Month(..))


type alias Post =
    { title : String
    , tags : List String
    , imageUrl : String
    , slug : String
    , description : Maybe String
    , date : Date
    , publishDate : Maybe Date
    }


allPostsGlob : BackendTask.BackendTask FatalError (List { filePath : String, slug : String })
allPostsGlob =
    Glob.succeed
        (\filePath slug ->
            { filePath = filePath
            , slug = slug
            }
        )
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/blog/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask


allPosts : BackendTask.BackendTask FatalError (List Post)
allPosts =
    allPostsGlob
        |> BackendTask.map
            (List.map
                (\post ->
                    File.onlyFrontmatter postFrontmatterDecoder post.filePath |> BackendTask.allowFatal
                )
            )
        |> BackendTask.resolve
        |> BackendTask.map (List.sortWith dateComparator)


dateComparator : Comparator Post
dateComparator =
    Compare.compose .date Date.compare |> Compare.reverse


postFrontmatterDecoder : Decoder Post
postFrontmatterDecoder =
    Decode.map7 Post
        (Decode.field "title" Decode.string)
        tagsDecoder
        (Decode.field "image-url" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.field "date" dateDecoder)
        (Decode.maybe (Decode.field "publish-on" dateDecoder))


tagsDecoder : Decoder (List String)
tagsDecoder =
    Decode.field "tags" Decode.string
        |> Decode.maybe
        |> Decode.map
            (\tags ->
                case tags of
                    Just tagsString ->
                        tagsString
                            |> String.split ","
                            |> List.map String.trim

                    Nothing ->
                        []
            )


toMonth : Int -> Month
toMonth month =
    case month of
        1 ->
            Jan

        2 ->
            Feb

        3 ->
            Mar

        4 ->
            Apr

        5 ->
            May

        6 ->
            Jun

        7 ->
            Jul

        8 ->
            Aug

        9 ->
            Sep

        10 ->
            Oct

        11 ->
            Nov

        _ ->
            Dec


dateDecoder : Decoder Date
dateDecoder =
    let
        create : Int -> Month -> Int -> { year : Int, month : Month, day : Int }
        create year month day =
            { year = year
            , month = month
            , day = day
            }
    in
    Decode.map3 create
        (Decode.field "year" Decode.int)
        (Decode.field "month" Decode.int |> Decode.map toMonth)
        (Decode.field "day" Decode.int)
        |> Decode.map (\date -> Date.fromCalendarDate date.year date.month date.day)


type alias PostDetails =
    { title : String
    , imageUrl : String
    , description : Maybe String
    , content : String
    }


postDetails : String -> BackendTask.BackendTask FatalError PostDetails
postDetails slug =
    let
        filePath =
            "content/blog/" ++ slug ++ ".md"
    in
    File.bodyWithFrontmatter
        (\markdown ->
            Decode.map4 PostDetails
                (Decode.field "title" Decode.string)
                (Decode.field "image-url" Decode.string)
                (Decode.field "description" (Decode.maybe Decode.string))
                (Decode.succeed markdown)
        )
        filePath
        |> BackendTask.allowFatal
