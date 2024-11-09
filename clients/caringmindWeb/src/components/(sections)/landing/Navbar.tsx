"use client";

import React, { useState, useEffect } from 'react';
import { UserProvider } from '@/utils/storage/context/UserContext';
import { usePathname } from 'next/navigation';
import { Menu, MenuItem, ProductItem } from "@/components/ui/navbar-menu";
import AuthButtons from '@/components/(third-party)/supabase/AuthButton';
import Image from 'next/image';
import { Menu as MenuIcon, X } from 'lucide-react';
import { menuItemsContent } from './Navbar/menuItemsContent'

const TallyNavbar: React.FC = () => {
  const [activeItem, setActiveItem] = useState<string | null>(null);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    setActiveItem(null);
    setIsMobileMenuOpen(false);
  }, [pathname]);

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  return (
    <UserProvider>
      <nav className="flex justify-between items-center py-4 px-4 md:px-8 border-b">
      <Image src="https://cdn.jsdelivr.net/gh/ebowwar/asset-store@main/un-automated/pixelcut-export-5.svg" alt="Logo" width={150} height={50} />        
      <div className="hidden md:flex items-center">
          <Menu setActive={setActiveItem}>
            {Object.entries(menuItemsContent).map(([key, content]) => (
              <MenuItem key={key} setActive={setActiveItem} active={activeItem} item={content.title}>
                {activeItem === content.title && (
                  <div className="flex flex-col">
                    {content.items.map((item, index) => (
                      <ProductItem
                        key={index}
                        title={item.title}
                        description={item.description}
                        href={item.href}
                        imagePath={item.imagePath}
                        width={200}
                        height={200}
                      />
                    ))}
                  </div>
                )}
              </MenuItem>
            ))}
          </Menu>
          <AuthButtons />
        </div>
        <div className="md:hidden">
          <button onClick={toggleMobileMenu}>
            {isMobileMenuOpen ? <X size={24} /> : <MenuIcon size={24} />}
          </button>
        </div>
      </nav>
      {isMobileMenuOpen && (
        <div className="md:hidden bg-white w-full">
          {Object.entries(menuItemsContent).map(([key, content]) => (
            <div key={key} className="px-4 py-2 border-b">
              <h2 className="font-bold">{content.title}</h2>
              <ul>
                {content.items.map((item, index) => (
                  <li key={index} className="py-1">
                    <a href={item.href}>{item.title}</a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
          <div className="px-4 py-2">
            <AuthButtons />
          </div>
        </div>
      )}
    </UserProvider>
  );
};

export default TallyNavbar;