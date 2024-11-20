// AudioRecorder.tsx
'use client'
// no button but needs VAD and then gemini integration
import React, { useEffect, useRef } from 'react'
import { Trash2 } from 'lucide-react'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { configureStore, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { Provider, useDispatch, useSelector } from 'react-redux'

// ------------------------------
// Redux Slice: audioRecorderSlice
// ------------------------------

// i want to rename AudioClip into LocalAudioClip as this will not be the only type to the AudioClip references
// for cloud usage we want to have a type that refers to the cloud url of the file annd maybe other properties
// - for cloud we wont save blob 
interface AudioClip {
  id: string
  url: string
  blob: Blob
  timestamp: string // ISO string for serialization
}

interface AudioRecorderState {
  error: string | null
  audioClips: AudioClip[]
  currentlyPlaying: string | null
}

const initialState: AudioRecorderState = {
  error: null,
  audioClips: [],
  currentlyPlaying: null,
}

const audioRecorderSlice = createSlice({
  name: 'audioRecorder',
  initialState,
  reducers: {
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
  const { error, audioClips, currentlyPlaying } = useAppSelector(
    (state: RootState) => state.audioRecorder
  )

  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const analyserRef = useRef<AnalyserNode | null>(null)
  const animationFrameRef = useRef<number | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const audioContextRef = useRef<AudioContext | null>(null)
  const lastRecordingTimeRef = useRef<number>(Date.now())
  const silenceStartTimeRef = useRef<number>(0)
  const isSilentRef = useRef<boolean>(true)

  useEffect(() => {
    startRecording()
    return () => {
      cleanup(true) // Pass true to indicate component unmount
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const logState = () => {
    console.log({
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
      isSilent: isSilentRef.current,
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
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
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

  const startRecording = async () => {
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
      silenceStartTimeRef.current = Date.now()
      isSilentRef.current = true
      lastRecordingTimeRef.current = Date.now()

      mediaRecorder.ondataavailable = (event: BlobEvent) => {
        if (event.data.size > 0) {
          audioChunksRef.current.push(event.data)
        }
      }

      mediaRecorder.onstop = () => {
        if (audioChunksRef.current.length > 0) {
          const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/wav' })
          const url = URL.createObjectURL(audioBlob)
          const newClip: AudioClip = {
            id: Date.now().toString(),
            url,
            blob: audioBlob,
            timestamp: new Date().toISOString(),
          }
          dispatch(addClip(newClip))
          audioChunksRef.current = [] // Reset chunks after saving
          logState()
        }
        // Restart recording
        if (mediaRecorder.state !== 'recording') {
          mediaRecorder.start()
          lastRecordingTimeRef.current = Date.now()
        }
      }

      // Start recording
      mediaRecorder.start()

      // Start monitoring for silence and batch duration
      startMonitoring()
      logState()
    } catch (err: any) {
      dispatch(setError(err instanceof Error ? err.message : 'Failed to start recording'))
      logState()
    }
  }

  const startMonitoring = () => {
    const analyser = analyserRef.current
    const mediaRecorder = mediaRecorderRef.current

    if (!analyser || !mediaRecorder) return

    const dataArray = new Uint8Array(analyser.fftSize)

    const checkSilenceAndDuration = () => {
      animationFrameRef.current = requestAnimationFrame(checkSilenceAndDuration)
      analyser.getByteTimeDomainData(dataArray)

      let sum = 0
      for (let i = 0; i < dataArray.length; i++) {
        const amplitude = (dataArray[i] - 128) / 128
        sum += amplitude * amplitude
      }
      const rms = Math.sqrt(sum / dataArray.length)
      const SILENCE_THRESHOLD = 0.02 // Adjust this threshold as needed

      if (rms < SILENCE_THRESHOLD) {
        // Detected silence
        if (!isSilentRef.current) {
          silenceStartTimeRef.current = Date.now()
          isSilentRef.current = true
        }
      } else {
        // Detected sound
        isSilentRef.current = false
      }

      const currentTime = Date.now()

      // If silent for more than 2 seconds, pause recording
      if (isSilentRef.current && currentTime - silenceStartTimeRef.current > 2000) {
        if (mediaRecorder.state === 'recording') {
          mediaRecorder.pause()
        }
      } else {
        if (mediaRecorder.state === 'paused') {
          mediaRecorder.resume()
        }
      }

      // Save recording every 20 seconds
      if (currentTime - lastRecordingTimeRef.current >= 20000) {
        if (mediaRecorder.state === 'recording') {
          mediaRecorder.stop()
          lastRecordingTimeRef.current = currentTime
        }
      }
    }

    checkSilenceAndDuration()
  }

  const deleteClipHandler = (clipId: string) => {
    dispatch(deleteClip(clipId))
    logState()
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
        {/* Optional Canvas Visualization */}
        <canvas
          ref={canvasRef}
          className="w-full h-32 bg-gray-100 rounded-lg"
          width={600}
          height={128}
        />

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
