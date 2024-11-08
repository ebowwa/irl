"use client"
import React, { useState, useEffect, useRef } from 'react';
import { 
  Card,
  CardContent, 
  CardHeader,
  CardTitle 
} from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { 
  BarChart,
  Clock,
  Mic,
  Send,
  StopCircle,
  Wifi,
  WifiOff,
  X
} from 'lucide-react';

// Define types for messages, stats, and instances
type Message = {
  sender: 'user' | 'gemini' | 'system';
  text: string;
  timestamp: Date;
};

type Stats = {
  totalMessages: number;
  averageResponseTime: number;
  messagesByModel: Record<string, { count: number; totalTime: number }>;
};

type RecordingState = Record<string, boolean>;

type ConnectionsState = Record<string, WebSocket>;

type MessagesState = Record<string, Message[]>;

type MediaRecordersState = Record<string, MediaRecorder>;

type AudioChunksState = Record<string, Blob[]>;

type MessageInputsState = Record<string, string>;

const MODELS = [
  'gemini-1.5-flash',
  'gemini-1.5-pro',
  'gemini-1.5-flash-8b'
];

const GeminiMultiChat: React.FC = () => {
  const [instances, setInstances] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState<string>('');
  const [connections, setConnections] = useState<ConnectionsState>({});
  const [messages, setMessages] = useState<MessagesState>({});
  const [recording, setRecording] = useState<RecordingState>({});
  const [stats, setStats] = useState<Stats>({
    totalMessages: 0,
    averageResponseTime: 0,
    messagesByModel: {}
  });

  const messageInputs = useRef<MessageInputsState>({});
  const mediaRecorders = useRef<MediaRecordersState>({});
  const audioChunks = useRef<AudioChunksState>({});
  const startTimes = useRef<Record<string, number>>({});

  const createInstance = (model: string) => {
    const instanceId = `${model}-${Date.now()}`;
    setInstances(prev => [...prev, instanceId]);
    setMessages(prev => ({ ...prev, [instanceId]: [] }));
    messageInputs.current[instanceId] = '';
    setActiveTab(instanceId);
    connectWebSocket(instanceId, model);
  };

  const removeInstance = (instanceId: string) => {
    disconnectWebSocket(instanceId);
    setInstances(prev => prev.filter(id => id !== instanceId));
    setMessages(prev => {
      const newMessages = { ...prev };
      delete newMessages[instanceId];
      return newMessages;
    });
    if (activeTab === instanceId) {
      setActiveTab(instances[0] || '');
    }
  };

  const connectWebSocket = (instanceId: string, model: string) => {
    const ws = new WebSocket('wss://4d9b-76-78-246-141.ngrok-free.app/api/gemini/ws/chat');
    
    ws.onopen = () => {
      setConnections(prev => ({ ...prev, [instanceId]: ws }));
      appendMessage(instanceId, 'system', `Connected to ${model}`);
    };

    ws.onmessage = (event: MessageEvent) => {
      const data = JSON.parse(event.data);
      const endTime = Date.now();
      const responseTime = endTime - (startTimes.current[instanceId] || endTime);
      
      if (data.response) {
        appendMessage(instanceId, 'gemini', data.response);
        updateStats(instanceId, responseTime);
      } else if (data.error) {
        appendMessage(instanceId, 'system', `Error: ${data.error}`);
      }
    };

    ws.onclose = () => {
      setConnections(prev => {
        const newConns = { ...prev };
        delete newConns[instanceId];
        return newConns;
      });
      appendMessage(instanceId, 'system', 'Disconnected');
    };
  };

  const disconnectWebSocket = (instanceId: string) => {
    if (connections[instanceId]) {
      connections[instanceId].close();
    }
  };

  const appendMessage = (instanceId: string, sender: 'user' | 'gemini' | 'system', text: string) => {
    setMessages(prev => ({
      ...prev,
      [instanceId]: [...(prev[instanceId] || []), { sender, text, timestamp: new Date() }]
    }));
  };

  const updateStats = (instanceId: string, responseTime: number) => {
    setStats(prev => {
      const model = instanceId.split('-')[0];
      const modelStats = prev.messagesByModel[model] || { count: 0, totalTime: 0 };
      
      return {
        totalMessages: prev.totalMessages + 1,
        averageResponseTime: (prev.averageResponseTime * prev.totalMessages + responseTime) / (prev.totalMessages + 1),
        messagesByModel: {
          ...prev.messagesByModel,
          [model]: {
            count: modelStats.count + 1,
            totalTime: modelStats.totalTime + responseTime,
          }
        }
      };
    });
  };

  const sendMessage = (instanceId: string) => {
    const message = messageInputs.current[instanceId];
    if (!message.trim() || !connections[instanceId]) return;

    appendMessage(instanceId, 'user', message);
    startTimes.current[instanceId] = Date.now();
    
    connections[instanceId].send(JSON.stringify({
      role: 'user',
      text: message,
      type: 'text'
    }));
    
    messageInputs.current[instanceId] = '';
  };

  const startRecording = async (instanceId: string) => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      
      mediaRecorder.onstart = () => {
        audioChunks.current[instanceId] = [];
        setRecording(prev => ({ ...prev, [instanceId]: true }));
      };

      mediaRecorder.ondataavailable = (event: BlobEvent) => {
        audioChunks.current[instanceId].push(event.data);
      };

      mediaRecorder.onstop = () => {
        const audioBlob = new Blob(audioChunks.current[instanceId], { type: 'audio/wav' });
        const reader = new FileReader();

        reader.onload = () => {
          const base64Audio = (reader.result as string).split(',')[1];
          connections[instanceId].send(JSON.stringify({
            role: 'user',
            audio: base64Audio,
            type: 'audio'
          }));
        };

        reader.readAsDataURL(audioBlob);
        setRecording(prev => ({ ...prev, [instanceId]: false }));
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

  return (
    <div className="w-full max-w-4xl mx-auto p-4">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Multi-Instance Gemini Chat</CardTitle>
          <div className="flex gap-2">
            {MODELS.map(model => (
              <Button 
                key={model}
                variant="outline"
                onClick={() => createInstance(model)}
                size="sm"
              >
                New {model}
              </Button>
            ))}
          </div>
        </CardHeader>
        
        <CardContent>
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <div className="flex items-center">
              <TabsList className="flex-1">
                {instances.map(instanceId => (
                  <TabsTrigger key={instanceId} value={instanceId} className="flex items-center gap-2">
                    {connections[instanceId] ? <Wifi size={16} /> : <WifiOff size={16} />}
                    {instanceId.split('-')[0]}
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={(e) => {
                        e.stopPropagation();
                        removeInstance(instanceId);
                      }}
                    >
                      <X size={16} />
                    </Button>
                  </TabsTrigger>
                ))}
              </TabsList>
            </div>

            {instances.map(instanceId => (
              <TabsContent key={instanceId} value={instanceId} className="border rounded-lg p-4">
                <ScrollArea className="h-[400px] mb-4">
                  {messages[instanceId]?.map((msg, idx) => (
                    <div
                      key={idx}
                      className={`mb-2 p-2 rounded ${
                        msg.sender === 'user' ? 'bg-blue-100 ml-auto' :
                        msg.sender === 'gemini' ? 'bg-green-100' : 'bg-gray-100'
                      } max-w-[80%] ${msg.sender === 'user' ? 'ml-auto' : ''}`}
                    >
                      <div className="text-sm font-medium mb-1">
                        {msg.sender.charAt(0).toUpperCase() + msg.sender.slice(1)}
                      </div>
                      <div>{msg.text}</div>
                      <div className="text-xs text-gray-500 mt-1">
                        {msg.timestamp.toLocaleTimeString()}
                      </div>
                    </div>
                  ))}
                </ScrollArea>

                <div className="flex gap-2">
                <Input
                    placeholder="Type your message..."
                    value={messageInputs.current[instanceId] || ''}
                    onChange={(e) => messageInputs.current[instanceId] = e.target.value}
                    onKeyDown={(e) => e.key === 'Enter' && sendMessage(instanceId)}
                  />
                  <Button 
                    onClick={() => sendMessage(instanceId)}
                    disabled={!connections[instanceId]}
                  >
                    <Send size={16} />
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => recording[instanceId] ? stopRecording(instanceId) : startRecording(instanceId)}
                    disabled={!connections[instanceId]}
                  >
                    {recording[instanceId] ? <StopCircle size={16} /> : <Mic size={16} />}
                  </Button>
                </div>
              </TabsContent>
            ))}
          </Tabs>

          <Card className="mt-4">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart size={20} />
                Chat Statistics
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <div className="text-sm font-medium">Total Messages</div>
                  <div className="text-2xl">{stats.totalMessages}</div>
                </div>
                <div>
                  <div className="text-sm font-medium">Average Response Time</div>
                  <div className="text-2xl flex items-center gap-1">
                    <Clock size={20} />
                    {Math.round(stats.averageResponseTime)}ms
                  </div>
                </div>
                <div>
                  <div className="text-sm font-medium">Active Sessions</div>
                  <div className="text-2xl">{instances.length}</div>
                </div>
              </div>
              
              <div className="mt-4">
                <div className="text-sm font-medium mb-2">Messages by Model</div>
                {Object.entries(stats.messagesByModel).map(([model, data]) => (
                  <div key={model} className="flex justify-between items-center mb-2">
                    <div>{model}</div>
                    <div className="text-sm">
                      {data.count} msgs ({Math.round(data.totalTime / data.count)}ms avg)
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </CardContent>
      </Card>
    </div>
  );
};

export default GeminiMultiChat;
