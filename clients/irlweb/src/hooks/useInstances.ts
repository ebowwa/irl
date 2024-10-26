// src/hooks/useInstances.ts

import { useState } from 'react';

export type InstanceConfig = {
  prompt: string;
  temperature: number;
  maxTokens: number;
};

export type Instance = {
  id: string;
  model: string;
  config: InstanceConfig;
};

const MODELS = ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-1.5-flash-8b'];

export const useInstances = () => {
  const [instances, setInstances] = useState<Instance[]>([]);
  const [activeTab, setActiveTab] = useState<string>('');

  const createInstance = (model: string) => {
    const instanceId = `${model}-${Date.now()}`;
    const defaultConfig: InstanceConfig = {
      prompt: '',
      temperature: 0.7,
      maxTokens: 150,
    };
    const newInstance: Instance = { id: instanceId, model, config: defaultConfig };
    setInstances((prev) => [...prev, newInstance]);
    setActiveTab(instanceId);
  };

  const removeInstance = (instanceId: string) => {
    setInstances((prev) => {
      const newInstances = prev.filter((inst) => inst.id !== instanceId);
      // Update activeTab if the removed instance was active
      if (activeTab === instanceId) {
        setActiveTab(newInstances[0]?.id || '');
      }
      return newInstances;
    });
  };

  const updateInstanceConfig = (instanceId: string, newConfig: InstanceConfig) => {
    setInstances((prev) =>
      prev.map((inst) => (inst.id === instanceId ? { ...inst, config: newConfig } : inst))
    );
  };

  return {
    instances,
    createInstance,
    removeInstance,
    updateInstanceConfig,
    activeTab,
    setActiveTab,
    MODELS,
  };
};
