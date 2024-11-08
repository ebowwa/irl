// src/hooks/useMessages.ts

import { useState } from 'react';

export type Message = {
  sender: 'user' | 'gemini' | 'system';
  text: string;
  timestamp: Date;
};

export const useMessages = () => {
  const [messages, setMessages] = useState<Record<string, Message[]>>({});

  const appendMessage = (
    instanceId: string,
    sender: 'user' | 'gemini' | 'system',
    text: string
  ) => {
    setMessages((prev) => ({
      ...prev,
      [instanceId]: [...(prev[instanceId] || []), { sender, text, timestamp: new Date() }],
    }));
  };

  const removeMessages = (instanceId: string) => {
    setMessages((prev) => {
      const newMessages = { ...prev };
      delete newMessages[instanceId];
      return newMessages;
    });
  };

  return { messages, appendMessage, removeMessages };
};
