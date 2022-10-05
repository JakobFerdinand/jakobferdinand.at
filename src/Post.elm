module Post exposing (Post, PostDetails, allPosts, postDetails)

import DataSource exposing (DataSource)
import DataSource.Http
import DataSource.File as File
import DataSource.File
import DataSource.Glob as Glob
import OptimizedDecoder as Decode exposing (Decoder)
import Pages.Secrets as Secrets


type alias Post =
    { title : String
    , imageUrl : String
    , slug : String
    , description : Maybe String
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
                        postFrontmatterDecoder
                        blogPost.filePath
                ))
        |> DataSource.resolve
                
postFrontmatterDecoder : Decoder Post
postFrontmatterDecoder = 
    Decode.map4 Post
        (Decode.field "title" Decode.string)
        (Decode.succeed "url")
        (Decode.succeed "slug")
        (Decode.succeed Nothing)
        

type alias PostDetails =
    { title : String
    , imageUrl : String
    , description : Maybe String
    , content : String
    }


postDetails : String -> DataSource PostDetails
postDetails slug =
    DataSource.Http.get
        (Secrets.succeed <| "https://6mpzd5sq.api.sanity.io/v1/data/query/production?query=*%5B_type%20%3D%3D%20%22post%22%20%26%26%20slug.current%20%3D%3D%20%22" ++ slug ++ "%22%5D%0A%7B%0A%20%20title%2C%0A%09%22imageUrl%22%3A%20mainImage.asset-%3Eurl%2C%0A%20%20description%2C%0A%20%20content%0A%7D")
        (Decode.field "result"
            (Decode.index
                0
                (Decode.map4 PostDetails
                    (Decode.field "title" Decode.string)
                    (Decode.field "imageUrl" Decode.string)
                    (Decode.maybe (Decode.field "description" Decode.string))
                    (Decode.field "content" Decode.string)
                )
            )
        )
