"use client"; // src/components/blog/container.tsx

import React, { useState } from "react";
import Alert from '../components/alert';

type Props = {
  preview?: boolean;
  children?: React.ReactNode;
};

const Container = ({ children }: Props) => {
    return (
    <div>
    <div suppressHydrationWarning>
      
        <div className="min-h-screen">
        <Alert preview={true} />
        {children}
      </div>
    </div>
    </div>
  );
};

export default Container;