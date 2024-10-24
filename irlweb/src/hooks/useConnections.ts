// src/hooks/useConnections.ts

import { useState } from 'react';
import { Instance } from './useInstances';

type AppendMessage = (
  instanceId: string,
  sender: 'user' | 'gemini' | 'system',
  text: string
) => void;

type UpdateStats = (instanceId: string, responseTime: number) => void;

type ServerMessage = {
  response?: string;
  error?: string;
};

export const useConnections = (
  appendMessage: AppendMessage,
  updateStats: UpdateStats,
  startTimes: React.MutableRefObject<Record<string, number>>
) => {
  const [connections, setConnections] = useState<Record<string, WebSocket>>({});

  const connectWebSocket = (instance: Instance) => {
    const ws = new WebSocket('wss://4d9b-76-78-246-141.ngrok-free.app/api/geminiws/chat'); // **Replace with your actual WebSocket URL**

    ws.onopen = () => {
      setConnections((prev) => ({ ...prev, [instance.id]: ws }));
      appendMessage(instance.id, 'system', `Connected to ${instance.model}`);
      // Send initial configuration
      ws.send(
        JSON.stringify({
          role: 'system',
          text: instance.config.prompt,
          temperature: instance.config.temperature,
          max_tokens: instance.config.maxTokens,
        })
      );
    };

    ws.onmessage = (event: MessageEvent) => {
      try {
        const data: ServerMessage = JSON.parse(event.data);
        const endTime = Date.now();
        const responseTime = endTime - (startTimes.current[instance.id] || endTime);

        if (data.response) {
          appendMessage(instance.id, 'gemini', data.response);
          updateStats(instance.id, responseTime);
        } else if (data.error) {
          appendMessage(instance.id, 'system', `Error: ${data.error}`);
        }
      } catch (error) {
        console.error('Failed to parse message:', error);
        appendMessage(instance.id, 'system', 'Received malformed message');
      }
    };

    ws.onclose = () => {
      setConnections((prev) => {
        const newConns = { ...prev };
        delete newConns[instance.id];
        return newConns;
      });
      appendMessage(instance.id, 'system', 'Disconnected');
    };
  };

  const disconnectWebSocket = (instanceId: string) => {
    if (connections[instanceId]) {
      connections[instanceId].close();
    }
  };

  return { connections, connectWebSocket, disconnectWebSocket };
};
