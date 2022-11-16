module Data.Post exposing (Post, PostDetails, allPosts, postDetails)

import Compare exposing (Comparator)
import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob
import Date exposing (Date)
import OptimizedDecoder as Decode exposing (Decoder)
import Time exposing (Month(..))


type alias Post =
    { title : String
    , tags : List String
    , imageUrl : String
    , slug : String
    , description : Maybe String
    , date : Date
    , publishDate : Maybe Date
    , filePath : String
    }


allPosts : DataSource (List Post)
allPosts =
    let
        blogPosts =
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
                |> Glob.toDataSource
    in
    blogPosts
        |> DataSource.map
            (List.map
                (\post ->
                    File.onlyFrontmatter
                        (postFrontmatterDecoder post.filePath)
                        post.filePath
                )
            )
        |> DataSource.resolve
        |> DataSource.map (List.sortWith dateComparator)


dateComparator : Comparator Post
dateComparator =
    Compare.compose .date Date.compare |> Compare.reverse


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


postFrontmatterDecoder : String -> Decoder Post
postFrontmatterDecoder filePath =
    Decode.succeed Post
        |> Decode.andMap (Decode.field "title" Decode.string)
        |> Decode.andMap tagsDecoder
        |> Decode.andMap (Decode.field "image-url" Decode.string)
        |> Decode.andMap (Decode.field "slug" Decode.string)
        |> Decode.andMap (Decode.maybe (Decode.field "description" Decode.string))
        |> Decode.andMap (Decode.field "date" dateDecoder)
        |> Decode.andMap (Decode.maybe (Decode.field "publish-on" dateDecoder))
        |> Decode.andMap (Decode.succeed filePath)


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
    Decode.succeed create
        |> Decode.andMap (Decode.field "year" Decode.int)
        |> Decode.andMap (Decode.field "month" Decode.int |> Decode.map toMonth)
        |> Decode.andMap (Decode.field "day" Decode.int)
        |> Decode.map (\date -> Date.fromCalendarDate date.year date.month date.day)


type alias PostDetails =
    { title : String
    , imageUrl : String
    , description : Maybe String
    , content : String
    }


postDetails : String -> DataSource PostDetails
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
