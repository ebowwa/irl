// AudioRecorder.tsx
'use client'

import React, { useEffect, useRef } from 'react'
import { Mic, Square, Trash2 } from 'lucide-react'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { configureStore, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { Provider, useDispatch, useSelector } from 'react-redux'

// ------------------------------
// Redux Slice: audioRecorderSlice
// ------------------------------

interface AudioClip {
  id: string
  url: string
  blob: Blob
  timestamp: string // ISO string for serialization
}

interface AudioRecorderState {
  isRecording: boolean
  error: string | null
  audioClips: AudioClip[]
  currentlyPlaying: string | null
}

const initialState: AudioRecorderState = {
  isRecording: false,
  error: null,
  audioClips: [],
  currentlyPlaying: null,
}

const audioRecorderSlice = createSlice({
  name: 'audioRecorder',
  initialState,
  reducers: {
    startRecording(state) {
      state.isRecording = true
      state.error = null
    },
    stopRecording(state) {
      state.isRecording = false
    },
    setError(state, action: PayloadAction<string>) {
      state.error = action.payload
    },
    addClip(state, action: PayloadAction<AudioClip>) {
      state.audioClips.push(action.payload)
    },
    deleteClip(state, action: PayloadAction<string>) {
      const clipToDelete = state.audioClips.find(clip => clip.id === action.payload)
      if (clipToDelete) {
        URL.revokeObjectURL(clipToDelete.url)
      }
      state.audioClips = state.audioClips.filter(clip => clip.id !== action.payload)
    },
    setCurrentlyPlaying(state, action: PayloadAction<string | null>) {
      state.currentlyPlaying = action.payload
    },
    clearClips(state) {
      state.audioClips.forEach(clip => URL.revokeObjectURL(clip.url))
      state.audioClips = []
    },
  },
})

const {
  startRecording,
  stopRecording,
  setError,
  addClip,
  deleteClip,
  setCurrentlyPlaying,
  clearClips,
} = audioRecorderSlice.actions

// ------------------------------
// Redux Store Configuration
// ------------------------------

const store = configureStore({
  reducer: {
    audioRecorder: audioRecorderSlice.reducer,
    // Add other reducers here if needed
  },
})

// Infer the `RootState` and `AppDispatch` types from the store itself
type RootState = ReturnType<typeof store.getState>
type AppDispatch = typeof store.dispatch

// Custom hooks for using dispatch and selector with TypeScript
const useAppDispatch = () => useDispatch<AppDispatch>()
const useAppSelector: <TSelected>(
  selector: (state: RootState) => TSelected
) => TSelected = useSelector

// ------------------------------
// AudioRecorder Component
// ------------------------------

const AudioRecorder: React.FC = () => {
  const dispatch = useAppDispatch()
  const { isRecording, error, audioClips, currentlyPlaying } = useAppSelector(
    (state: RootState) => state.audioRecorder
  )

  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const analyserRef = useRef<AnalyserNode | null>(null)
  const animationFrameRef = useRef<number | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const audioContextRef = useRef<AudioContext | null>(null)

  useEffect(() => {
    return () => {
      cleanup(true) // Pass true to indicate component unmount
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const logState = () => {
    console.log({
      isRecording,
      error,
      audioClips,
      currentlyPlaying,
      mediaRecorder: mediaRecorderRef.current,
      audioChunks: audioChunksRef.current,
      stream: streamRef.current,
      audioContext: audioContextRef.current,
      analyser: analyserRef.current,
      canvas: canvasRef.current,
      animationFrame: animationFrameRef.current,
    })
  }

  /**
   * Cleanup resources.
   * @param {boolean} isUnmount - If true, also stop all recordings.
   */
  const cleanup = (isUnmount: boolean = false) => {
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current)
    }
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === 'recording') {
      mediaRecorderRef.current.stop()
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop())
    }
    if (audioContextRef.current) {
      audioContextRef.current.close()
    }
    if (isUnmount) {
      // Optionally, clear all clips on unmount
      // dispatch(clearClips())
    }
    logState()
  }

  const startRecordingHandler = async () => {
    try {
      // Do not clear existing clips when starting a new recording
      cleanup(false)
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      streamRef.current = stream

      audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)()
      const source = audioContextRef.current.createMediaStreamSource(stream)
      const analyser = audioContextRef.current.createAnalyser()
      analyser.fftSize = 2048
      source.connect(analyser)
      analyserRef.current = analyser

      const mediaRecorder = new MediaRecorder(stream)
      mediaRecorderRef.current = mediaRecorder
      audioChunksRef.current = []

      mediaRecorder.ondataavailable = (event: BlobEvent) => {
        if (event.data.size > 0) {
          audioChunksRef.current.push(event.data)
        }
      }

      mediaRecorder.onstop = () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/wav' })
        const url = URL.createObjectURL(audioBlob)
        const newClip: AudioClip = {
          id: Date.now().toString(),
          url,
          blob: audioBlob,
          timestamp: new Date().toISOString(),
        }
        dispatch(addClip(newClip))
        logState()
      }

      mediaRecorder.start()
      dispatch(startRecording())
      logState()
      startVisualization()
    } catch (err: any) {
      dispatch(setError(err instanceof Error ? err.message : 'Failed to start recording'))
      logState()
    }
  }

  const stopRecordingHandler = () => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === 'recording') {
      mediaRecorderRef.current.stop()
      dispatch(stopRecording())

      if (streamRef.current) {
        streamRef.current.getTracks().forEach(track => track.stop())
      }

      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current)
      }
      logState()
    }
  }

  const deleteClipHandler = (clipId: string) => {
    dispatch(deleteClip(clipId))
    logState()
  }

  const startVisualization = () => {
    const canvas = canvasRef.current
    const analyser = analyserRef.current

    if (!canvas || !analyser) return

    const canvasCtx = canvas.getContext('2d')
    if (!canvasCtx) return

    const dataArray = new Uint8Array(analyser.frequencyBinCount)

    const draw = () => {
      animationFrameRef.current = requestAnimationFrame(draw)
      analyser.getByteTimeDomainData(dataArray)

      canvasCtx.fillStyle = 'rgb(200, 200, 200)'
      canvasCtx.fillRect(0, 0, canvas.width, canvas.height)
      canvasCtx.lineWidth = 2
      canvasCtx.strokeStyle = 'rgb(0, 0, 0)'
      canvasCtx.beginPath()

      const sliceWidth = canvas.width / dataArray.length
      let x = 0

      for (let i = 0; i < dataArray.length; i++) {
        const v = dataArray[i] / 128.0
        const y = v * canvas.height / 2

        if (i === 0) {
          canvasCtx.moveTo(x, y)
        } else {
          canvasCtx.lineTo(x, y)
        }

        x += sliceWidth
      }

      canvasCtx.lineTo(canvas.width, canvas.height / 2)
      canvasCtx.stroke()
    }

    draw()
  }

  const formatDate = (timestamp: string): string => {
    const date = new Date(timestamp)
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date)
  }

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-3xl font-bold mb-8">Audio Recorder</h1>

      {error && (
        <Alert variant="destructive" className="mb-6">
          <AlertTitle>Error</AlertTitle>
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <div className="space-y-6">
        <canvas
          ref={canvasRef}
          className="w-full h-32 bg-gray-100 rounded-lg"
          width={600}
          height={128}
        />

        <div className="flex justify-center space-x-4">
          <button
            onClick={isRecording ? stopRecordingHandler : startRecordingHandler}
            className={`flex items-center space-x-2 px-4 py-2 rounded-lg ${
              isRecording
                ? 'bg-red-500 hover:bg-red-600'
                : 'bg-blue-500 hover:bg-blue-600'
            } text-white transition-colors`}
          >
            {isRecording ? (
              <>
                <Square className="w-5 h-5" />
                <span>Stop Recording</span>
              </>
            ) : (
              <>
                <Mic className="w-5 h-5" />
                <span>Start Recording</span>
              </>
            )}
          </button>
        </div>

        {audioClips.length > 0 && (
          <div className="mt-8">
            <h2 className="text-xl font-semibold mb-4">Recordings</h2>
            <div className="space-y-4">
              {audioClips.map((clip) => (
                <div
                  key={clip.id}
                  className="bg-gray-50 p-4 rounded-lg flex items-center justify-between"
                >
                  <div className="flex items-center space-x-4">
                    <span className="text-sm text-gray-500">
                      {formatDate(clip.timestamp)}
                    </span>
                    <audio
                      src={clip.url}
                      controls
                      className="h-8"
                      onPlay={() => dispatch(setCurrentlyPlaying(clip.id))}
                      onPause={() => dispatch(setCurrentlyPlaying(null))}
                    />
                  </div>
                  <button
                    onClick={() => deleteClipHandler(clip.id)}
                    className="p-2 text-red-500 hover:text-red-700 transition-colors"
                    title="Delete recording"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

// ------------------------------
// App Component with Redux Provider
// ------------------------------

// This component wraps the AudioRecorder with the Redux Provider.
// If you're using a framework like Next.js, you should place the Provider at a higher level (e.g., in _app.tsx).
const App: React.FC = () => (
  <Provider store={store}>
    <AudioRecorder />
  </Provider>
)

export default App
