export default {
    name: "hobby",
    title: "Hobby",
    type: "document",
    fields: [
        {
            name: 'title',
            title: 'Title',
            type: 'string'
        },
        {
            name: 'slug',
            title: 'Slug',
            type: 'slug',
            options: {
                source: 'title',
                maxLength: 96
            },
        },
        {
            name: 'mainImage',
            title: 'Main image',
            type: 'image',
            options: {
                hotspot: true,
            },
        },
        {
            name: 'images',
            title: 'Images',
            type: 'array',
            of: [ { type: 'image' }]
        },
        {
            name: 'description',
            title: 'Description',
            type: 'markdown'
        }
    ],

    preview: {
        select: {
            title: 'title',
            media: 'mainImage'
        }
    }
}