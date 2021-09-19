module Post exposing (Post, PostDetails, allPosts, postDetails)

import DataSource exposing (DataSource)
import DataSource.Http
import OptimizedDecoder as Decode
import OptimizedDecoder.Pipeline exposing (decode)
import Pages.Secrets as Secrets


type alias Post =
    { title : String
    , imageUrl : String
    , slug : String
    }


allPosts : DataSource (List Post)
allPosts =
    DataSource.Http.get
        (Secrets.succeed "https://6mpzd5sq.api.sanity.io/v1/data/query/production?query=*%5B_type%20%3D%3D%20%22post%22%5D%0A%7B%0A%20%20title%2C%20%0A%09%22imageUrl%22%3A%20mainImage.asset-%3Eurl%2C%0A%20%20%22slug%22%3A%20slug.current%0A%7D")
        (Decode.field "result"
            (Decode.list
                (Decode.map3 Post
                    (Decode.field "title" Decode.string)
                    (Decode.field "imageUrl" Decode.string)
                    (Decode.field "slug" Decode.string)
                )
            )
        )


type alias PostDetails =
    { title : String
    , imageUrl : String
    , description : String
    }


postDetails : String -> DataSource PostDetails
postDetails slug =
    DataSource.Http.get
        (Secrets.succeed <| "https://6mpzd5sq.api.sanity.io/v1/data/query/production?query=*%5B_type%20%3D%3D%20%22post%22%20%26%26%20slug.current%20%3D%3D%20%22" ++ slug ++ "%22%5D%0A%7B%0A%20%20title%2C%20%0A%09%22imageUrl%22%3A%20mainImage.asset-%3Eurl%2C%0A%20%20description%0A%7D")
        (Decode.field "result"
            (Decode.index
                0
                (Decode.map3 PostDetails
                    (Decode.field "title" Decode.string)
                    (Decode.field "imageUrl" Decode.string)
                    (Decode.field "description" Decode.string)
                )
            )
        )
