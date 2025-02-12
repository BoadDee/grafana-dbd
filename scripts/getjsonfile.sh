#!/bin/bash

# CONFIGURATION - Set these before running
GRAFANA_URL="https://grafana-dre-test-bbbqeedbh4hfbpgd.cca.grafana.azure.com"  # Replace with your Grafana URL
API_KEY="glsa_jb9a0d7vTzlzE6jAo0vh2Pj25b5wp4be_f077c59c"  # Replace with your API Key
FOLDER_NAME="dre"  # The folder containing dashboards
EXPORT_FOLDER="./exported_dashboards"  # Folder to save JSON files

# Create folder if not exists
mkdir -p "$EXPORT_FOLDER"

# Get all folders and extract the UID of the target folder
FOLDER_UID=$(curl -s -H "Authorization: Bearer $API_KEY" "$GRAFANA_URL/api/folders" | jq -r --arg name "$FOLDER_NAME" '.[] | select(.title==$name) | .uid')

# Check if the folder exists
if [ -z "$FOLDER_UID" ]; then
    echo "❌ Folder '$FOLDER_NAME' not found!"
    exit 1
fi

echo "📂 Found folder '$FOLDER_NAME' (UID: $FOLDER_UID)"

# Get list of dashboards
DASHBOARDS_JSON=$(curl -s -H "Authorization: Bearer $API_KEY" "$GRAFANA_URL/api/search?query=")

DASHBOARDS_JSON=$(curl -s -H "Authorization: Bearer $API_KEY" "$GRAFANA_URL/api/search?folderIds=$FOLDER_UID")

# Extract UIDs and Titles
for row in $(echo "$DASHBOARDS_JSON" | jq -r '.[] | @base64'); do
    _jq() {
        echo "$row" | base64 --decode | jq -r "$1"
    }

    DASHBOARD_UID=$(_jq '.uid')
    DASHBOARD_TITLE=$(_jq '.title' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')  # Remove spaces & lowercase
    DASHBOARD_FILE="${EXPORT_FOLDER}/${DASHBOARD_TITLE}.json"

    echo "📤 Exporting Dashboard: $DASHBOARD_TITLE (UID: $DASHBOARD_UID)"

    # Fetch full dashboard JSON and save to file
    curl -s -H "Authorization: Bearer $API_KEY" \
         -H "Content-Type: application/json" \
         "$GRAFANA_URL/api/dashboards/uid/$DASHBOARD_UID" | jq '.' > "$DASHBOARD_FILE"

    echo "✅ Saved to: $DASHBOARD_FILE"
done

echo "🎉 Export complete! Dashboards from '$FOLDER_NAME' saved in '$EXPORT_FOLDER'"