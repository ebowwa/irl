// providers.tsx
'use client';

import { PropsWithChildren, useEffect } from 'react';
import '../i18n'; // import the i18n configuration
import { I18nextProvider } from 'react-i18next';
import i18n from '../i18n';

export function Providers({ children }: PropsWithChildren) {
  useEffect(() => {
    // Initialize i18n on the client side
    if (!i18n.isInitialized) {
      i18n.init();
    }
  }, []);

  return <I18nextProvider i18n={i18n}>{children}</I18nextProvider>;
}
