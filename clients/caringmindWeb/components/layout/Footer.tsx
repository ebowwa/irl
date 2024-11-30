"use client";

import Link from "next/link";
import { Github, Twitter, Linkedin } from "lucide-react";

export function Footer() {
  const links = {
    product: [
      { label: "Features", href: "#features" },
      { label: "iOS App", href: "/ios" },
      { label: "Apple Watch", href: "/watch" },
      { label: "Roadmap", href: "#roadmap" },
    ],
    company: [
      { label: "About", href: "/about" },
      { label: "Blog", href: "/blog" },
      { label: "Careers", href: "/careers" },
      { label: "Contact", href: "/contact" },
    ],
    resources: [
      { label: "FAQ", href: "/faq" },
      { label: "Documentation", href: "/docs" },
      { label: "Privacy", href: "/privacy" },
      { label: "Terms", href: "/terms" },
    ],
    social: [
      { label: "Twitter", href: "https://twitter.com", icon: Twitter },
      { label: "GitHub", href: "https://github.com", icon: Github },
      { label: "LinkedIn", href: "https://linkedin.com", icon: Linkedin },
    ],
  };

  return (
    <footer className="bg-white border-t border-gray-100">
      <div className="max-w-7xl mx-auto px-4 py-12">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Product</h3>
            <ul className="space-y-3">
              {links.product.map((link) => (
                <li key={link.href}>
                  <Link 
                    href={link.href}
                    className="text-gray-600 hover:text-purple-600 transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Company</h3>
            <ul className="space-y-3">
              {links.company.map((link) => (
                <li key={link.href}>
                  <Link 
                    href={link.href}
                    className="text-gray-600 hover:text-purple-600 transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Resources</h3>
            <ul className="space-y-3">
              {links.resources.map((link) => (
                <li key={link.href}>
                  <Link 
                    href={link.href}
                    className="text-gray-600 hover:text-purple-600 transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Connect</h3>
            <ul className="space-y-3">
              {links.social.map((link) => (
                <li key={link.href}>
                  <a 
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 text-gray-600 hover:text-purple-600 transition-colors"
                  >
                    <link.icon className="w-5 h-5" />
                    <span>{link.label}</span>
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>
        <div className="mt-12 pt-8 border-t border-gray-100">
          <p className="text-center text-gray-600 text-sm">
            © {new Date().getFullYear()} CaringMind. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}