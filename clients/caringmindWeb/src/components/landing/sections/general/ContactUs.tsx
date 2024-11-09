// ContactUs.tsx
import React, { useState } from 'react';
import { Label } from '@/components/landing/ui/label';
import { Input } from '@/components/landing/ui/input';
import { Textarea } from '@/components/landing/ui/textarea';
import { Button } from '@/components/landing/ui/button';

interface ContactUsProps {
    title: string;
    description: string;
}

const ContactUs: React.FC<ContactUsProps> = ({ title, description }) => {
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        message: '',
    });

    const handleInputChange = (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        setFormData({
            ...formData,
            [event.target.name]: event.target.value,
        });
    };

    const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
        event.preventDefault();

        try {
            const response = await fetch('/api/contact', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData),
            });

            if (response.ok) {
                // Form submission successful
                console.log('Form submitted successfully');
                // You can also reset the form data here
                setFormData({
                    name: '',
                    email: '',
                    message: '',
                });
            } else {
                // Form submission failed
                console.error('Error submitting form:', await response.json());
            }
        } catch (error) {
            console.error('Error submitting form:', error);
        }
    };

    return (
        <section className="w-full py-12 md:py-24 lg:py-32 border-t" id="contact">
            <div className="container px-4 md:px-6">
                <div className="space-y-2 text-center">
                    <div className="inline-block rounded-lg bg-gray-100 px-3 py-1 text-sm dark:bg-gray-800">Contact Us</div>
                    <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl">{title}</h2>
                    <p className="max-w-[700px] mx-auto text-gray-500 md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed dark:text-gray-400">
                        {description}
                    </p>
                </div>
                <div className="mx-auto max-w-3xl py-12">
                    <form onSubmit={handleSubmit}>
                        <div className="grid gap-6 sm:grid-cols-2">
                            <div>
                                <Label className="mb-2">Name</Label>
                                <Input
                                    type="text"
                                    name="name"
                                    value={formData.name}
                                    onChange={handleInputChange}
                                    placeholder="Your Company"
                                    required
                                />
                            </div>
                            <div>
                                <Label className="mb-2">Email</Label>
                                <Input
                                    type="email"
                                    name="email"
                                    value={formData.email}
                                    onChange={handleInputChange}
                                    placeholder="levelsio@dingboard.com"
                                    required
                                />
                            </div>
                            <div className="sm:col-span-2">
                                <Label className="mb-2">Message</Label>
                                <Textarea
                                    name="message"
                                    value={formData.message}
                                    onChange={handleInputChange}
                                    rows={4}
                                    placeholder="Type your message here..."
                                    required
                                />
                            </div>
                        </div>
                        <div className="mt-6 flex justify-center">
                            <Button type="submit">Submit</Button>
                        </div>
                    </form>
                </div>
            </div>
        </section>
    );
};

export default ContactUs;