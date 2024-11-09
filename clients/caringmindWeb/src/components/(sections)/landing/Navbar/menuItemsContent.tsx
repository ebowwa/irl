export type ProductItemContent = {
    title: string;
    description: string;
    href: string;
    imagePath: string;
  };

export type MenuItemContent = {
    title: string;
    items: ProductItemContent[];
  };

  export const menuItemsContent: Record<string, MenuItemContent> = {
    "Getting Started": {
      title: "Getting Started",
      items: [
        {
          title: "Blog",
          description: "Dive into our insightful blog posts tailored for individuals seeking knowledge and inspiration.",
          href: "/blog",
          imagePath: "/placeholder.png",
        },
        {
          title: "Pricing",
          description: "Explore our flexible pricing options designed to meet the needs of professionals at every level.",
          href: "/pricing",
          imagePath: "/placeholder.png",
        },
        {
          title: "Affiliates",
          description: "Join our affiliate program and unlock opportunities for organizations to grow and thrive.",
          href: "/affiliates",
          imagePath: "/placeholder.png",
        },
      ],
    },
    Labs: {
      title: "Labs",
      items: [
        {
          title: "Learning",
          description: "Embark on a journey of knowledge with our extensive library of educational resources.",
          href: "/learning",
          imagePath: "/placeholder.png",
        },
        {
          title: "Print on Demand",
          description: "Transform your designs into tangible products with our innovative Print on Demand solutions.",
          href: "/printondemand",
          imagePath: "/placeholder.png",
        },
        {
          title: "Resume Assistance",
          description: "Get ready for the future! Our generative AI is soon to revolutionize resume drafting. Sign up for the waitlist now.",
          href: "/resume",
          imagePath: "/placeholder.png",
        },
      ],
    },
  };