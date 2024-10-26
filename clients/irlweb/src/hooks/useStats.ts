// src/hooks/useStats.ts

import { useState } from 'react';

export type Stats = {
  totalMessages: number;
  averageResponseTime: number;
  messagesByModel: Record<string, { count: number; totalTime: number }>;
};

export const useStats = () => {
  const [stats, setStats] = useState<Stats>({
    totalMessages: 0,
    averageResponseTime: 0,
    messagesByModel: {},
  });

  const updateStats = (instanceId: string, responseTime: number) => {
    setStats((prev) => {
      const model = instanceId.split('-')[0];
      const modelStats = prev.messagesByModel[model] || { count: 0, totalTime: 0 };

      const newTotalMessages = prev.totalMessages + 1;
      const newAverageResponseTime =
        (prev.averageResponseTime * prev.totalMessages + responseTime) / newTotalMessages;

      return {
        totalMessages: newTotalMessages,
        averageResponseTime: newAverageResponseTime,
        messagesByModel: {
          ...prev.messagesByModel,
          [model]: {
            count: modelStats.count + 1,
            totalTime: modelStats.totalTime + responseTime,
          },
        },
      };
    });
  };

  return { stats, updateStats };
};
