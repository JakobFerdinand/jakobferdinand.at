module Post exposing (Post, PostDetails, allPosts, postDetails)

import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob
import DataSource.Http
import OptimizedDecoder as Decode exposing (Decoder)
import Pages.Secrets as Secrets


type alias Post =
    { title : String
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
                (\blogPost ->
                    File.onlyFrontmatter
                        (postFrontmatterDecoder blogPost.filePath)
                        blogPost.filePath
                )
            )
        |> DataSource.resolve


postFrontmatterDecoder : String -> Decoder Post
postFrontmatterDecoder filePath =
    Decode.map5 Post
        (Decode.field "title" Decode.string)
        (Decode.field "image-url" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "description" (Decode.maybe Decode.string))
        (Decode.succeed filePath)


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
