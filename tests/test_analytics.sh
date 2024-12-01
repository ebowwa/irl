#!/bin/bash
# chmod +x /Users/ebowwa/caringmind/backend/tests/test_analytics.sh
# /Users/ebowwa/caringmind/backend/tests/test_analytics.sh

BASE_URL="https://9419-2a01-4ff-f0-b1f6-00-1.ngrok-free.app"
VISITOR_ID="test_user_123"
SESSION_ID="test_session_456"

# Helper function to generate timestamp
get_timestamp() {
    echo $(($(date +%s) * 1000))
}

echo "1. Track initial visit"
curl -X POST "$BASE_URL/analytics/track" \
  -H "Content-Type: application/json" \
  -d '{
    "visitor_id": "'$VISITOR_ID'",
    "session_id": "'$SESSION_ID'",
    "timestamp": '$(get_timestamp)',
    "page": "/home",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    "screen_resolution": "1920x1080",
    "device_type": "desktop",
    "location": {
      "city": "San Francisco",
      "country": "US"
    }
  }'
echo -e "\n"

sleep 2

echo "2. Track exercise completion"
curl -X POST "$BASE_URL/analytics/track" \
  -H "Content-Type: application/json" \
  -d '{
    "visitor_id": "'$VISITOR_ID'",
    "session_id": "'$SESSION_ID'",
    "timestamp": '$(get_timestamp)',
    "page": "/exercise/1",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    "screen_resolution": "1920x1080",
    "device_type": "desktop",
    "location": {
      "city": "San Francisco",
      "country": "US"
    },
    "event_type": "complete_exercise",
    "event_data": {
      "exercise_id": "ex_123",
      "duration": 300,
      "score": 95
    }
  }'
echo -e "\n"

sleep 2

echo "3. Start new session"
curl -X POST "$BASE_URL/analytics/track" \
  -H "Content-Type: application/json" \
  -d '{
    "visitor_id": "'$VISITOR_ID'",
    "session_id": "'$SESSION_ID'_new",
    "timestamp": '$(get_timestamp)',
    "page": "/dashboard",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    "screen_resolution": "1920x1080",
    "device_type": "desktop",
    "location": {
      "city": "San Francisco",
      "country": "US"
    },
    "event_type": "start_session",
    "event_data": {
      "referrer": "direct"
    }
  }'
echo -e "\n"

sleep 2

echo "4. Get user metadata"
curl -X GET "$BASE_URL/analytics/user/$VISITOR_ID"
echo -e "\n"

# Test multiple exercise completions to trigger achievements
echo "5. Complete multiple exercises to test achievements"
for i in {1..5}; do
  echo "Completing exercise $i"
  curl -X POST "$BASE_URL/analytics/track" \
    -H "Content-Type: application/json" \
    -d '{
      "visitor_id": "'$VISITOR_ID'",
      "session_id": "'$SESSION_ID'_achievement",
      "timestamp": '$(get_timestamp)',
      "page": "/exercise/'$i'",
      "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
      "screen_resolution": "1920x1080",
      "device_type": "desktop",
      "location": {
        "city": "San Francisco",
        "country": "US"
      },
      "event_type": "complete_exercise",
      "event_data": {
        "exercise_id": "ex_'$i'",
        "duration": 300,
        "score": 95
      }
    }'
  echo -e "\n"
  sleep 1
done

echo "6. Final user metadata check"
curl -X GET "$BASE_URL/analytics/user/$VISITOR_ID"
echo -e "\n"
