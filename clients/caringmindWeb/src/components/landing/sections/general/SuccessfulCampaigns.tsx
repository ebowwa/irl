// SuccessfulCampaigns.tsx
import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
export interface Bot {
    bot: string;
    idea: string;
    sequence: string;
    "intro message": string;
    "info message": string;
    description: string;
    "feature_1": string;
    "feature_2": string;
    "feature_3": string;
    twitter_handle: string;
    rating: number;
    tags: string;
    href: string;
    image: string;
    author: string;
}

export type BotData = Bot[];
interface SuccessfulCampaignsProps {
    title: string;
    description: string;
    bots: Bot[];
}

const SuccessfulCampaigns: React.FC<SuccessfulCampaignsProps> = ({ title, description, bots }) => {
    return (
        <section className="w-full py-12 md:py-24 lg:py-32" id="portfolio">
            <div className="container px-4 md:px-6">
                <div className="space-y-2 text-center">
                    <div className="inline-block rounded-lg bg-gray-100 px-3 py-1 text-sm dark:bg-gray-800">NEW BOTS</div>
                    <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl">{title}</h2>
                    <p className="max-w-[700px] mx-auto text-gray-500 md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed dark:text-gray-400">
                        {description}
                    </p>
                </div>
                <div className="mx-auto grid max-w-5xl justify-items-center gap-16 py-12 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-2">
                    {bots.map((bot, index) => (
                        <div key={index} className="w-full sm:w-[400px] md:w-[450px] lg:w-[500px]">
                            <Link href={`${bot.href}`}>
                                <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-950 hover:shadow-lg hover:transform hover:-translate-y-1 transition-all duration-300 cursor-pointer">
                                    <div className="space-y-2">
                                        <h3 className="text-2xl font-bold">{bot.bot}</h3>
                                        <p className="text-lg">{bot.idea}</p>
                                    </div>
                                    <Image
                                        alt={`Portfolio ${index + 1}`}
                                        className="mb-4 aspect-[4/3] w-full rounded-lg object-cover h-[300px]"
                                        height={300}
                                        src={bot.image}
                                        width={400}
                                        priority={index === 0}
                                    />
                                </div>
                            </Link>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
};

export default SuccessfulCampaigns;
