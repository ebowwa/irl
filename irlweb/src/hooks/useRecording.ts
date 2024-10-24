// src/hooks/useRecording.ts

import { useState, useRef } from 'react';

type AppendMessage = (
  instanceId: string,
  sender: 'user' | 'gemini' | 'system',
  text: string
) => void;

type WebSocketConnections = Record<string, WebSocket>;

export const useRecording = (
  appendMessage: AppendMessage,
  connections: WebSocketConnections
) => {
  const [recording, setRecording] = useState<Record<string, boolean>>({});
  const audioChunks = useRef<Record<string, Blob[]>>({});
  const mediaRecorders = useRef<Record<string, MediaRecorder>>({});

  const startRecording = async (instanceId: string) => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);

      mediaRecorder.onstart = () => {
        audioChunks.current[instanceId] = [];
        setRecording((prev) => ({ ...prev, [instanceId]: true }));
      };

      mediaRecorder.ondataavailable = (event: BlobEvent) => {
        audioChunks.current[instanceId].push(event.data);
      };

      mediaRecorder.onstop = () => {
        const audioBlob = new Blob(audioChunks.current[instanceId], { type: 'audio/wav' });
        const reader = new FileReader();

        reader.onload = () => {
          const base64Audio = (reader.result as string).split(',')[1];
          connections[instanceId]?.send(
            JSON.stringify({
              role: 'user',
              audio: base64Audio,
              type: 'audio',
            })
          );
        };

        reader.readAsDataURL(audioBlob);
        setRecording((prev) => ({ ...prev, [instanceId]: false }));
      };

      mediaRecorders.current[instanceId] = mediaRecorder;
      mediaRecorder.start();
    } catch (error) {
      appendMessage(instanceId, 'system', 'Audio recording failed');
      console.error('Recording error:', error);
    }
  };

  const stopRecording = (instanceId: string) => {
    if (mediaRecorders.current[instanceId]) {
      mediaRecorders.current[instanceId].stop();
    }
  };

  return { recording, startRecording, stopRecording };
};
