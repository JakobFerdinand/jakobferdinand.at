module Data.Post exposing (Post, PostDetails, allPosts, postDetails)

import Compare exposing (Comparator)
import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob
import Date exposing (Date)
import OptimizedDecoder as Decode exposing (Decoder)
import Time exposing (Month(..))


type alias Post =
    { date : Date
    , title : String
    , imageUrl : String
    , slug : String
    , description : Maybe String
    , filePath : String
    }


allPosts : DataSource (List Post)
allPosts =
    let
        blogPosts =
            Glob.succeed
                (\filePath year month day slug ->
                    { year = year
                    , month = toMonth month
                    , day = day
                    , filePath = filePath
                    , slug = slug
                    }
                )
                |> Glob.captureFilePath
                |> Glob.match (Glob.literal "content/blog/")
                |> Glob.capture Glob.int
                |> Glob.match (Glob.literal "-")
                |> Glob.capture Glob.int
                |> Glob.match (Glob.literal "-")
                |> Glob.capture Glob.int
                |> Glob.match (Glob.literal "-")
                |> Glob.capture Glob.wildcard
                |> Glob.match (Glob.literal ".md")
                |> Glob.toDataSource
    in
    blogPosts
        |> DataSource.map
            (List.map
                (\post ->
                    File.onlyFrontmatter
                        (postFrontmatterDecoder
                            { year = post.year
                            , month = post.month
                            , day = post.day
                            , filePath = post.filePath
                            }
                        )
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


postFrontmatterDecoder :
    { year : Int
    , month : Month
    , day : Int
    , filePath : String
    }
    -> Decoder Post
postFrontmatterDecoder post =
    Decode.map6 Post
        (Decode.succeed (Date.fromCalendarDate post.year post.month post.day))
        (Decode.field "title" Decode.string)
        (Decode.field "image-url" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "description" (Decode.maybe Decode.string))
        (Decode.succeed post.filePath)


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
