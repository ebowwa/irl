// app/settings/page.tsx
"use client";

import React from 'react';
import SettingsDropdown from '@/components/(sections)/printondemand/ui/SettingsDropdown'; // Adjust the import path as necessary

const SettingsPage = () => {
  return (
    <div className="flex justify-center items-center h-screen">
      <div className="p-4 bg-white shadow-lg rounded-lg">
        <h1 className="text-xl font-bold mb-4">Settings</h1>
        <SettingsDropdown />
      </div>
    </div>
  );
};

export default SettingsPage;
