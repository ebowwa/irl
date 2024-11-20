"use client";
import React, { useState, useEffect, useRef } from 'react';
import {
  Volume2,
  Search,
  Heart,
  Brain,
  Calendar,
  Clock,
  AlertTriangle,
  Users,
  Music,
  Coffee,
  Phone,
  Mic,
  Sparkles,
  Play,
  Pause,
} from 'lucide-react';

interface Deception {
  indicators?: string[];
  context?: string;
  pattern?: string;
}

interface Thread {
  id: string;
  type: 'critical' | 'warning' | 'normal';
  summary: string;
}

interface Exchange {
  id: number;
  timestamp: string;
  speaker: string;
  text: string;
  emotion: string;
  subtext?: string;
  prosody: string;
  truthScore: number;
  deceptionIndicators?: string[];
  context?: string;
  thread?: string;
  critical?: boolean;
  powerDynamic?: string;
  intent?: string;
}

interface LiveExchange {
  metadata: {
    title: string;
    time: string;
    participants: string[];
  };
  threads: Thread[];
  exchanges: Exchange[];
}

interface Moment {
  id: number;
  timestamp: string;
  type: 'conversation' | 'phone call' | 'ambient' | 'meeting' | 'presentation' | 'social';
  context: string;
  exchanges: Exchange[];
  importance?: string;
  deception?: string;
  deceptionPattern?: string;
  impact?: string;
  resonance?: string;
  emotionalUndercurrent?: string;
  relationshipInsight?: string;
  ambientContext?: string;
  privacy?: string;
  observation?: string;
  ethicalFlag?: string;
  supportingData?: string;
}

const LifeStream: React.FC = () => {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [isSearchVisible, setIsSearchVisible] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [isPlaying, setIsPlaying] = useState<boolean>(true);

  const [liveExchange, setLiveExchange] = useState<LiveExchange>({
    metadata: {
      title: "Contract Negotiation",
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      participants: ["Alex Chen (CEO)", "David Smith (Vendor)"],
    },
    threads: [
      {
        id: 'pricing',
        type: 'critical',
        summary: 'Pricing discrepancy thread',
      },
      {
        id: 'timeline',
        type: 'warning',
        summary: 'Delivery timeline concerns',
      },
    ],
    exchanges: [
      {
        id: 1,
        timestamp: "14:22",
        speaker: "Alex Chen",
        text: "Let's review the terms you've proposed. The $1.2M figure seems high compared to market rates.",
        emotion: "neutral",
        subtext: "confident, analytical",
        prosody: "measured pace, clear articulation",
        truthScore: 0.95,
        intent: "establishing baseline",
        thread: 'pricing',
      },
      {
        id: 2,
        timestamp: "14:30",
        speaker: "David Smith",
        text: "Our pricing reflects premium materials and guaranteed delivery times. We're actually taking a smaller margin than usual.",
        emotion: "defensive",
        subtext: "slight tension",
        prosody: "increased pace, higher pitch",
        truthScore: 0.62,
        deceptionIndicators: [
          "Pitch elevation during 'smaller margin'",
          "Micro-expression: lip tightening",
          "Increased blink rate",
        ],
        context: "Financial records indicate standard industry margins",
        thread: 'pricing',
        critical: true,
      },
      {
        id: 3,
        timestamp: "14:35",
        speaker: "Alex Chen",
        text: "I appreciate quality, but I've seen the material costs. Let's focus on real numbers.",
        emotion: "firm",
        subtext: "maintaining control",
        prosody: "steady rhythm, authoritative tone",
        truthScore: 0.96,
        powerDynamic: "assertive but non-aggressive",
        thread: 'pricing',
      },
    ],
  });

  const [moments, setMoments] = useState<Moment[]>([
    {
      id: 1,
      timestamp: "2 hours ago",
      type: "conversation",
      context: "Coffee Shop",
      exchanges: [
        {
          id: 101,
          timestamp: "12:00",
          speaker: "You",
          text: "I feel like this could be my breakthrough year, you know?",
          emotion: "hopeful with underlying uncertainty",
          prosody: "rising intonation, thoughtful pauses",
          truthScore: 0.82,
          subtext: "Seeking validation while masking self-doubt",
        },
        {
          id: 102,
          timestamp: "12:02",
          speaker: "Emma",
          text: "Of course it will be! You've been putting in so much work.",
          emotion: "supportive, genuine",
          prosody: "warm, emphatic stress on 'will'",
          truthScore: 0.95,
          //resonance: "strong emotional connection",
        },
      ],
      importance: "personal insight",
      resonance: "strong emotional connection",
    },
  ]);

  const exchangeIdRef = useRef<number>(liveExchange.exchanges.length + 1);
  const momentIdRef = useRef<number>(moments.length + 1);

  // Simulate live transcription updates
  useEffect(() => {
    if (!isPlaying) return;

    const interval = setInterval(() => {
      const newExchange: Exchange = generateRandomExchange(exchangeIdRef.current++);
      setLiveExchange((prev) => ({
        ...prev,
        exchanges: [...prev.exchanges, newExchange],
        metadata: {
          ...prev.metadata,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        },
      }));
    }, 5000); // New exchange every 5 seconds

    return () => clearInterval(interval);
  }, [isPlaying]);

  // Move old exchanges to moments after a certain time
  useEffect(() => {
    const interval = setInterval(() => {
      if (liveExchange.exchanges.length === 0) return;

      // Create a new moment with current exchanges
      const newMoment: Moment = {
        id: momentIdRef.current++,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        type: determineMomentType(liveExchange.exchanges),
        context: liveExchange.metadata.title,
        exchanges: [...liveExchange.exchanges],
        importance: determineImportance(liveExchange.exchanges),
      };

      setMoments((prev) => [newMoment, ...prev]);
      setLiveExchange((prev) => ({
        ...prev,
        exchanges: [],
      }));
    }, 15000); // Move exchanges every 15 seconds

    return () => clearInterval(interval);
  }, [liveExchange.exchanges, liveExchange.metadata.title]);

  const generateRandomExchange = (id: number): Exchange => {
    const speakers = ["Alex Chen", "David Smith"];
    const emotions = ["neutral", "defensive", "firm", "supportive", "genuine"];
    const texts = [
      "Can we discuss the delivery timeline in more detail?",
      "I'm confident that this partnership will be mutually beneficial.",
      "Are there any concerns regarding the contract terms?",
      "We need to ensure that the quality standards are met.",
      "Let's finalize the details and move forward.",
    ];
    const prosodies = [
      "calm and reassuring tone",
      "steady rhythm, authoritative tone",
      "increased pace, higher pitch",
      "warm, emphatic stress on key points",
      "measured pace, clear articulation",
    ];
    const truthScores = [0.85, 0.90, 0.88, 0.92, 0.80];
    const deceptionIndicatorsList: string[][] | undefined[] = [

    ];

    const randomIndex = Math.floor(Math.random() * texts.length);

    return {
      id,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      speaker: speakers[randomIndex % speakers.length],
      text: texts[randomIndex],
      emotion: emotions[randomIndex],
      prosody: prosodies[randomIndex],
      truthScore: truthScores[randomIndex],
      deceptionIndicators: deceptionIndicatorsList[randomIndex],
      thread: 'pricing',
      critical: randomIndex === 2,
    };
  };

  const determineMomentType = (exchanges: Exchange[]): Moment['type'] => {
    // Determine type based on threads involved
    const threads = exchanges.map((exchange) => exchange.thread);
    if (threads.includes('pricing')) return 'meeting';
    if (threads.includes('timeline')) return 'presentation';
    return 'conversation';
  };

  const determineImportance = (exchanges: Exchange[]): string | undefined => {
    if (exchanges.some((exchange) => exchange.critical)) return 'critical';
    return undefined;
  };

  const renderLiveExchange = (exchange: Exchange): JSX.Element => {
    const isDeceptive = exchange.truthScore < 0.8;
    const borderColor =
      exchange.truthScore > 0.9
        ? 'border-green-200'
        : exchange.truthScore > 0.8
        ? 'border-yellow-200'
        : 'border-red-200';

    return (
      <div
        key={exchange.id}
        className={`group relative transition-all duration-500 ease-in-out
          ${isDeceptive ? 'bg-red-50' : 'bg-white hover:bg-gray-50'}
          border-l-4 ${borderColor} rounded-r-lg mb-3`}
      >
        <div className="px-6 py-4">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-4">
              <span className="text-sm text-gray-500">{exchange.timestamp}</span>
              <span className="font-medium text-gray-900">{exchange.speaker}</span>
            </div>
            <div className="flex items-center gap-2">
              {exchange.critical && (
                <span className="text-purple-600">
                  <Sparkles className="h-4 w-4" />
                </span>
              )}
              <Volume2 className="h-4 w-4 text-gray-400" />
            </div>
          </div>

          <p className="text-gray-900 mb-3">{exchange.text}</p>

          <div className="grid grid-cols-2 gap-4 text-sm">
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-gray-600">
                <Heart className="h-4 w-4" />
                <span>{exchange.emotion}</span>
                {exchange.subtext && (
                  <span className="text-gray-400">• {exchange.subtext}</span>
                )}
              </div>
              <div className="flex items-center gap-2 text-gray-600">
                <Brain className="h-4 w-4" />
                <span>{exchange.prosody}</span>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2">
              <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden">
                <div
                  className={`h-full transition-all duration-500 ease-out ${
                    exchange.truthScore > 0.9
                      ? 'bg-green-500'
                      : exchange.truthScore > 0.8
                      ? 'bg-yellow-500'
                      : 'bg-red-500'
                  }`}
                  style={{ width: `${exchange.truthScore * 100}%` }}
                />
              </div>
              <span className="text-sm text-gray-500">
                {Math.round(exchange.truthScore * 100)}%
              </span>
            </div>
          </div>

          {isDeceptive && exchange.deceptionIndicators && (
            <div className="mt-4 p-3 bg-red-100 rounded-lg border border-red-200">
              <div className="flex items-start gap-2">
                <AlertTriangle className="h-4 w-4 text-red-600 mt-0.5" />
                <div className="space-y-1">
                  <p className="text-sm font-medium text-red-800">Potential deception detected:</p>
                  <ul className="text-sm text-red-700 list-disc pl-4">
                    {exchange.deceptionIndicators.map((indicator, i) => (
                      <li key={i}>{indicator}</li>
                    ))}
                  </ul>
                  {exchange.context && (
                    <p className="text-sm text-red-700 mt-2 pt-2 border-t border-red-200">
                      Context: {exchange.context}
                    </p>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>

        {exchange.powerDynamic && (
          <div className="absolute -right-2 top-1/2 transform -translate-y-1/2">
            <div className="bg-black text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200">
              {exchange.powerDynamic}
            </div>
          </div>
        )}
      </div>
    );
  };

  const renderMoment = (moment: Moment): JSX.Element => (
    <div
      key={moment.id}
      className={`relative group transition-all duration-300 ease-in-out 
        ${moment.deception ? 'bg-red-50' : 'bg-white hover:bg-gray-50'}
        border-l-4 ${
          moment.exchanges.some((exchange) => exchange.truthScore > 0.9)
            ? 'border-green-200'
            : moment.exchanges.some((exchange) => exchange.truthScore > 0.8)
            ? 'border-yellow-200'
            : 'border-red-200'
        }
        rounded-lg mb-4 shadow-sm hover:shadow-md`}
    >
      <div className="px-6 py-4">
        <div className="absolute -left-24 top-1/2 transform -translate-y-1/2 opacity-0 
                      group-hover:opacity-100 transition-opacity duration-300">
          <span className="text-sm text-gray-400">{moment.timestamp}</span>
        </div>

        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-3">
            <span className="text-sm font-medium text-gray-700">
              {moment.type.charAt(0).toUpperCase() + moment.type.slice(1)}
            </span>
            {moment.context && (
              <span className="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full flex items-center gap-1">
                {getContextIcon(moment.type)}
                {moment.context}
              </span>
            )}
            {moment.importance && (
              <span className="text-xs text-purple-600 bg-purple-50 px-2 py-0.5 rounded-full">
                {moment.importance}
              </span>
            )}
          </div>
          <Volume2 className="h-4 w-4 text-gray-400" />
        </div>

        <div className="space-y-4">
          {moment.exchanges.map((exchange) => renderLiveExchange(exchange))}
        </div>

        <div className="opacity-0 group-hover:opacity-100 transition-opacity duration-300">
          <div className="flex flex-wrap items-center gap-6 text-sm text-gray-600 mb-3">
            {moment.exchanges.map((exchange) => (
              <React.Fragment key={exchange.id}>
                <div className="flex items-center gap-2">
                  <Heart className="h-4 w-4" />
                  <span>{exchange.emotion}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Brain className="h-4 w-4" />
                  <span>{exchange.prosody}</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-20 h-1.5 bg-gray-200 rounded-full overflow-hidden">
                    <div
                      className={`h-full transition-all duration-500 ${
                        exchange.truthScore > 0.9
                          ? 'bg-green-500'
                          : exchange.truthScore > 0.8
                          ? 'bg-yellow-500'
                          : 'bg-red-500'
                      }`}
                      style={{ width: `${exchange.truthScore * 100}%` }}
                    />
                  </div>
                  <span className="text-xs text-gray-500">
                    {Math.round(exchange.truthScore * 100)}%
                  </span>
                </div>
              </React.Fragment>
            ))}
          </div>

          {(moment.deception || moment.deceptionPattern) && (
            <div className="mt-2 p-3 bg-red-50 rounded-lg border border-red-100">
              <div className="flex items-start gap-2">
                <AlertTriangle className="h-4 w-4 text-red-500 mt-0.5" />
                <div>
                  <p className="text-sm text-red-600">{moment.deception}</p>
                  {moment.deceptionPattern && (
                    <p className="text-xs text-red-500 mt-1">{moment.deceptionPattern}</p>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );

  const getContextIcon = (type: Moment['type']): JSX.Element => {
    switch (type) {
      case 'conversation':
        return <Users className="h-4 w-4" />;
      case 'phone call':
        return <Phone className="h-4 w-4" />;
      case 'ambient':
        return <Music className="h-4 w-4" />;
      case 'meeting':
        return <Coffee className="h-4 w-4" />;
      case 'presentation':
        return <Mic className="h-4 w-4" />;
      case 'social':
        return <Users className="h-4 w-4" />;
      default:
        return <Users className="h-4 w-4" />;
    }
  };

  const scrollToBottom = () => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  };

  useEffect(() => {
    scrollToBottom();
  }, [liveExchange.exchanges, moments]);

  // Filter moments based on search term
  const filteredMoments = moments.filter((moment) =>
    moment.exchanges.some((exchange) =>
      exchange.text.toLowerCase().includes(searchTerm.toLowerCase())
    )
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Live Header */}
      <div className="bg-black bg-opacity-95 text-white sticky top-0 z-50">
        <div className="max-w-5xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-light">{liveExchange.metadata.title}</h1>
              <div className="flex items-center gap-4 mt-1 text-sm text-gray-400">
                <span>{liveExchange.metadata.time}</span>
                <span>{liveExchange.metadata.participants.join(" • ")}</span>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <button
                onClick={() => setIsPlaying(!isPlaying)}
                className="p-2 rounded-full hover:bg-gray-800 transition-colors"
              >
                {isPlaying ? <Pause className="h-5 w-5" /> : <Play className="h-5 w-5" />}
              </button>
              <div className="flex items-center gap-2">
                <div className="h-2 w-2 rounded-full bg-red-500 animate-pulse" />
                <span className="text-sm">Live</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-6 py-8" ref={scrollRef}>
        {/* Live Transcription */}
        <div className="mb-12">
          <div className="space-y-6">
            {liveExchange.exchanges.map(renderLiveExchange)}
          </div>
        </div>

        {/* Time break indicator */}
        <div className="flex items-center gap-4 mb-8 text-sm text-gray-500">
          <div className="h-px flex-1 bg-gray-200" />
          <span>Earlier Today</span>
          <div className="h-px flex-1 bg-gray-200" />
        </div>

        {/* Historical Moments */}
        <div className="space-y-6">
          {filteredMoments.map(renderMoment)}
        </div>

        <div className="py-20 text-center text-gray-400">
          <div className="animate-bounce">Loading more moments...</div>
        </div>
      </div>

      {/* Search Button */}
      <div className="fixed top-6 right-6 z-20">
        <button
          onClick={() => setIsSearchVisible(!isSearchVisible)}
          className="h-10 w-10 bg-black text-white rounded-full flex items-center justify-center
                     shadow-lg hover:bg-gray-800 transition-colors"
        >
          <Search className="h-5 w-5" />
        </button>
      </div>

      {/* Search overlay */}
      {isSearchVisible && (
        <div className="fixed inset-0 bg-black bg-opacity-50 z-10 flex items-start justify-center pt-20">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl p-6">
            <input
              type="text"
              placeholder="Search your moments..."
              className="w-full px-4 py-3 text-lg border-none focus:ring-2 focus:ring-black rounded-lg"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <div className="flex flex-wrap gap-2 mt-4">
              <button className="px-3 py-1.5 text-sm bg-gray-100 rounded-full hover:bg-gray-200">
                Today
              </button>
              <button className="px-3 py-1.5 text-sm bg-gray-100 rounded-full hover:bg-gray-200">
                Important Moments
              </button>
              <button className="px-3 py-1.5 text-sm bg-gray-100 rounded-full hover:bg-gray-200">
                High Impact
              </button>
              <button className="px-3 py-1.5 text-sm bg-gray-100 rounded-full hover:bg-gray-200">
                Deception Detected
              </button>
              <button className="px-3 py-1.5 text-sm bg-gray-100 rounded-full hover:bg-gray-200">
                Critical Conversations
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Time indicator */}
      <div className="fixed top-6 left-6 z-20">
        <div className="text-sm text-gray-500">
          <div className="flex items-center gap-2 mb-1">
            <Calendar className="h-4 w-4" />
            <span>Today</span>
          </div>
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            <span>Now</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LifeStream;
