"use client";

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
  X,
  Settings
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

type InstanceConfig = {
  prompt: string;
  temperature: number;
  maxTokens: number;
};

type Instance = {
  id: string;
  model: string;
  config: InstanceConfig;
};

const MODELS = [
  'gemini-1.5-flash',
  'gemini-1.5-pro',
  'gemini-1.5-flash-8b'
];

const GeminiMultiChat: React.FC = () => {
  const [instances, setInstances] = useState<Instance[]>([]);
  const [activeTab, setActiveTab] = useState<string>('');
  const [connections, setConnections] = useState<ConnectionsState>({});
  const [messages, setMessages] = useState<MessagesState>({});
  const [recording, setRecording] = useState<RecordingState>({});
  const [stats, setStats] = useState<Stats>({
    totalMessages: 0,
    averageResponseTime: 0,
    messagesByModel: {}
  });

  const [configModalOpen, setConfigModalOpen] = useState<boolean>(false);
  const [currentConfigInstanceId, setCurrentConfigInstanceId] = useState<string>('');
  const [tempConfig, setTempConfig] = useState<InstanceConfig>({
    prompt: '',
    temperature: 0.7,
    maxTokens: 150
  });

  const messageInputs = useRef<MessageInputsState>({});
  const mediaRecorders = useRef<MediaRecordersState>({});
  const audioChunks = useRef<AudioChunksState>({});
  const startTimes = useRef<Record<string, number>>({});

  const createInstance = (model: string) => {
    const instanceId = `${model}-${Date.now()}`;
    const defaultConfig: InstanceConfig = {
      prompt: '',
      temperature: 0.7,
      maxTokens: 150
    };
    const newInstance: Instance = {
      id: instanceId,
      model,
      config: defaultConfig
    };
    setInstances(prev => [...prev, newInstance]);
    setMessages(prev => ({ ...prev, [instanceId]: [] }));
    messageInputs.current[instanceId] = '';
    setActiveTab(instanceId);
    connectWebSocket(newInstance);
  };

  const removeInstance = (instanceId: string) => {
    disconnectWebSocket(instanceId);
    setInstances(prev => prev.filter(inst => inst.id !== instanceId));
    setMessages(prev => {
      const newMessages = { ...prev };
      delete newMessages[instanceId];
      return newMessages;
    });
    if (activeTab === instanceId) {
      setActiveTab(instances[0]?.id || '');
    }
  };

  const connectWebSocket = (instance: Instance) => {
    const ws = new WebSocket('wss://4d9b-76-78-246-141.ngrok-free.app/api/gemini/ws/chat');

    ws.onopen = () => {
      setConnections(prev => ({ ...prev, [instance.id]: ws }));
      appendMessage(instance.id, 'system', `Connected to ${instance.model}`);
      // Removed the initial configuration message
      // All necessary configurations will be sent with each message
    };

    ws.onmessage = (event: MessageEvent) => {
      const data = JSON.parse(event.data);
      const endTime = Date.now();
      const responseTime = endTime - (startTimes.current[instance.id] || endTime);

      if (data.response) {
        appendMessage(instance.id, 'gemini', data.response);
        updateStats(instance.id, responseTime);
      } else if (data.error) {
        appendMessage(instance.id, 'system', `Error: ${data.error}`);
      }
    };

    ws.onclose = () => {
      setConnections(prev => {
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

    const instance = instances.find(inst => inst.id === instanceId);
    if (!instance) return;

    // Construct the message with required fields
    const messagePayload = {
      type: "text",
      role: "user",
      text: message,
      model_name: instance.model,
      generation_config: {
        temperature: instance.config.temperature,
        top_p: 0.9, // You can make this configurable if needed
        max_output_tokens: instance.config.maxTokens,
        candidate_count: 1,
        response_mime_type: "text/plain"
      },
      stream: false // Adjust as needed
    };

    appendMessage(instanceId, 'user', message);
    startTimes.current[instanceId] = Date.now();
    
    connections[instanceId].send(JSON.stringify(messagePayload));
    
    messageInputs.current[instanceId] = '';
  };

  const sendAudioMessage = (instanceId: string, base64Audio: string) => {
    const instance = instances.find(inst => inst.id === instanceId);
    if (!instance) return;

    // Construct the audio message with required fields
    const audioPayload = {
      type: "audio",
      role: "user",
      audio: base64Audio,
      model_name: instance.model,
      generation_config: {
        temperature: instance.config.temperature,
        top_p: 0.9, // You can make this configurable if needed
        max_output_tokens: instance.config.maxTokens,
        candidate_count: 1,
        response_mime_type: "text/plain"
      },
      stream: false // Adjust as needed
    };

    appendMessage(instanceId, 'user', "Audio message sent.");
    startTimes.current[instanceId] = Date.now();
    
    connections[instanceId].send(JSON.stringify(audioPayload));
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
          sendAudioMessage(instanceId, base64Audio);
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

  const openConfigModal = (instanceId: string) => {
    const instance = instances.find(inst => inst.id === instanceId);
    if (instance) {
      setCurrentConfigInstanceId(instanceId);
      setTempConfig({
        prompt: instance.config.prompt,
        temperature: instance.config.temperature,
        maxTokens: instance.config.maxTokens
      });
      setConfigModalOpen(true);
    }
  };

  const saveConfig = () => {
    setInstances(prev => prev.map(inst => {
      if (inst.id === currentConfigInstanceId) {
        return { ...inst, config: tempConfig };
      }
      return inst;
    }));
    // Optionally, reconnect the WebSocket with new config
    disconnectWebSocket(currentConfigInstanceId);
    const updatedInstance = instances.find(inst => inst.id === currentConfigInstanceId);
    if (updatedInstance) {
      connectWebSocket(updatedInstance);
    }
    setConfigModalOpen(false);
  };

  const closeModal = () => {
    setConfigModalOpen(false);
  };

  // Optional: Close modal on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && configModalOpen) {
        closeModal();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [configModalOpen]);

  // Optional: Focus on the prompt input when modal opens
  const promptInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (configModalOpen && promptInputRef.current) {
      promptInputRef.current.focus();
    }
  }, [configModalOpen]);

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
                {instances.map(instance => (
                  <TabsTrigger key={instance.id} value={instance.id} className="flex items-center gap-2">
                    {connections[instance.id] ? <Wifi size={16} /> : <WifiOff size={16} />}
                    {instance.model}
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={(e) => {
                        e.stopPropagation();
                        removeInstance(instance.id);
                      }}
                    >
                      <X size={16} />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={(e) => {
                        e.stopPropagation();
                        openConfigModal(instance.id);
                      }}
                    >
                      <Settings size={16} />
                    </Button>
                  </TabsTrigger>
                ))}
              </TabsList>
            </div>

            {instances.map(instance => (
              <TabsContent key={instance.id} value={instance.id} className="border rounded-lg p-4">
                <ScrollArea className="h-[400px] mb-4">
                  {messages[instance.id]?.map((msg, idx) => (
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
                    value={messageInputs.current[instance.id] || ''}
                    onChange={(e) => messageInputs.current[instance.id] = e.target.value}
                    onKeyPress={(e) => e.key === 'Enter' && sendMessage(instance.id)}
                  />
                  <Button 
                    onClick={() => sendMessage(instance.id)}
                    disabled={!connections[instance.id]}
                  >
                    <Send size={16} />
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => recording[instance.id] ? stopRecording(instance.id) : startRecording(instance.id)}
                    disabled={!connections[instance.id]}
                  >
                    {recording[instance.id] ? <StopCircle size={16} /> : <Mic size={16} />}
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

      {/* Custom Configuration Modal */}
      {configModalOpen && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
          <div className="bg-white rounded-lg shadow-lg w-11/12 max-w-md p-6">
            <Card>
              <CardHeader>
                <CardTitle>Configure Instance</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-col gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">Prompt</label>
                    <Input
                      ref={promptInputRef}
                      value={tempConfig.prompt}
                      onChange={(e) => setTempConfig(prev => ({ ...prev, prompt: e.target.value }))}
                      placeholder="Enter system prompt..."
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Temperature</label>
                    <input
                      type="range"
                      min="0"
                      max="100"
                      value={tempConfig.temperature * 100}
                      onChange={(e) => setTempConfig(prev => ({ ...prev, temperature: Number(e.target.value) / 100 }))}
                      className="w-full"
                    />
                    <div className="text-sm text-gray-700">{tempConfig.temperature.toFixed(2)}</div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Max Tokens</label>
                    <Input
                      type="number"
                      value={tempConfig.maxTokens}
                      onChange={(e) => setTempConfig(prev => ({ ...prev, maxTokens: Number(e.target.value) }))}
                      placeholder="Enter max tokens..."
                      min={10}
                      max={1000}
                    />
                  </div>
                  <div className="flex justify-end gap-2">
                    <Button variant="outline" onClick={closeModal}>Cancel</Button>
                    <Button onClick={saveConfig}>Save</Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      )}
    </div>
  );
};

export default GeminiMultiChat;
