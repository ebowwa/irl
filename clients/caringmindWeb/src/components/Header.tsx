'use client';

import React from 'react';
import { useTranslation } from 'react-i18next';
import { LanguageSwitcher } from './LanguageSwitcher';

export const Header: React.FC = () => {
  const { t } = useTranslation();

  return (
    <header className="bg-white shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex justify-between items-center">
          <nav className="flex space-x-4">
            <a href="#" className="text-gray-700 hover:text-gray-900">
              {t('navigation.home')}
            </a>
            <a href="#" className="text-gray-700 hover:text-gray-900">
              {t('navigation.about')}
            </a>
            <a href="#" className="text-gray-700 hover:text-gray-900">
              {t('navigation.services')}
            </a>
            <a href="#" className="text-gray-700 hover:text-gray-900">
              {t('navigation.contact')}
            </a>
          </nav>
          <LanguageSwitcher />
        </div>
      </div>
    </header>
  );
};
