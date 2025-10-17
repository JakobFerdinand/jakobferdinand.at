import { defineCollection, z } from "astro:content";

const blog = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    slug: z.string(),
    imageUrl: z.string(),
    description: z.string().optional(),
    date: z.coerce.date(),
    publishOn: z.coerce.date().optional(),
    tags: z.array(z.string()).default([]),
  }),
});

export const collections = {
  blog,
};
