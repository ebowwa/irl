"Use client"
import React, { useState } from 'react';
import { Heart, Moon, Sun, Sparkles } from 'lucide-react';

const PresenceUI = () => {
  const [mode, setMode] = useState('day');
  
  return (
    <div className={`w-full h-screen flex flex-col items-center justify-center ${mode === 'day' ? 'bg-white' : 'bg-gray-900'}`}>
      <div className="w-full max-w-md px-8">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <Heart className={`w-8 h-8 ${mode === 'day' ? 'text-rose-500' : 'text-rose-400'}`} />
          {mode === 'day' ? (
            <Moon onClick={() => setMode('night')} className="w-6 h-6 text-gray-600 cursor-pointer" />
          ) : (
            <Sun onClick={() => setMode('day')} className="w-6 h-6 text-gray-300 cursor-pointer" />
          )}
        </div>
        
        {/* Main Interface */}
        <div className={`rounded-2xl p-6 mb-6 ${mode === 'day' ? 'bg-gray-50' : 'bg-gray-800'}`}>
          <div className={`text-lg font-light mb-4 ${mode === 'day' ? 'text-gray-800' : 'text-gray-200'}`}>
            "I notice you're feeling uncertain about tomorrow's presentation. Let's transform that energy into confidence."
          </div>
          <div className="flex items-center gap-2">
            <Sparkles className={`w-4 h-4 ${mode === 'day' ? 'text-amber-500' : 'text-amber-400'}`} />
            <span className={`text-sm ${mode === 'day' ? 'text-gray-600' : 'text-gray-400'}`}>
              caringmind is here with you
            </span>
          </div>
        </div>

        {/* Interaction Bubbles */}
        <div className="flex justify-around">
          <button className={`rounded-full p-4 ${mode === 'day' ? 'bg-rose-50 text-rose-500' : 'bg-rose-900 text-rose-300'}`}>
            Reflect
          </button>
          <button className={`rounded-full p-4 ${mode === 'day' ? 'bg-blue-50 text-blue-500' : 'bg-blue-900 text-blue-300'}`}>
            Connect
          </button>
          <button className={`rounded-full p-4 ${mode === 'day' ? 'bg-purple-50 text-purple-500' : 'bg-purple-900 text-purple-300'}`}>
            Grow
          </button>
        </div>
      </div>
    </div>
  );
};

export default PresenceUI;