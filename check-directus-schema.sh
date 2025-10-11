#!/bin/bash
# Check if thumbnail field exists in problems collection

echo "Checking Directus schema for 'problems' collection..."
echo ""

# Check fields in problems collection
curl -s "http://192.168.1.3:8055/fields/problems" | jq '.'

echo ""
echo "Looking for 'thumbnail' field..."
curl -s "http://192.168.1.3:8055/fields/problems" | jq '.data[] | select(.field == "thumbnail")'

echo ""
echo "If empty above, the thumbnail field doesn't exist in Directus schema yet."
echo "You need to add it via Directus admin UI (Task 9 in todo list)."
