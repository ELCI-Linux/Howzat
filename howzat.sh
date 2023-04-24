#!/bin/bash

# Replace with your CricAPI key
API_KEY="<YOUR_CRICAPI_KEY>"

# Get the match IDs for all current cricket games
get_match_ids() {
  curl -s "https://cricapi.com/api/matches?apikey=${API_KEY}" | jq '.matches[] | select(.matchStarted == true) | .unique_id'
}

# Function to get the wicket count for a match
get_wicket_count() {
  local match_id=$1
  curl -s "https://cricapi.com/api/cricketScore?apikey=${API_KEY}&unique_id=${match_id}" | jq '.score' | grep -o 'wickets=[0-9]*' | grep -o '[0-9]*'
}

# Initialize the wicket count for each match
declare -A wicket_counts
for match_id in $(get_match_ids); do
  wicket_counts["$match_id"]=$(get_wicket_count $match_id)
done

# Monitor wickets and notify on change
while true; do
  sleep 60 # Check every minute
  for match_id in "${!wicket_counts[@]}"; do
    current_wicket_count=$(get_wicket_count $match_id)

    if [ "$current_wicket_count" -gt "${wicket_counts[$match_id]}" ]; then
      espeak "Howzat"
      match_info=$(curl -s "https://cricapi.com/api/cricketScore?apikey=${API_KEY}&unique_id=${match_id}" | jq -r '.stat, .score' | paste -sd '\n' -)
      zenity --notification --text="$match_info"
    fi

    wicket_counts["$match_id"]=$current_wicket_count
  done
done
