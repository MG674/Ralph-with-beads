#!/bin/bash
# notify.sh - Send notification when Ralph completes/blocks
# Customize this for your preferred notification method

MESSAGE="${1:-Ralph loop finished}"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] $MESSAGE"

# Terminal bell
echo -e "\a"

# ============================================
# CUSTOMIZE BELOW FOR YOUR NOTIFICATION METHOD
# ============================================

# Option 1: macOS notification (uncomment if on Mac)
# osascript -e "display notification \"$MESSAGE\" with title \"Ralph\""

# Option 2: Send email (requires mail command configured)
# echo "$MESSAGE" | mail -s "Ralph Notification" your@email.com

# Option 3: Slack webhook (set SLACK_WEBHOOK_URL environment variable)
# if [ -n "$SLACK_WEBHOOK_URL" ]; then
#     curl -X POST -H 'Content-type: application/json' \
#         --data "{\"text\":\"$MESSAGE\"}" \
#         "$SLACK_WEBHOOK_URL"
# fi

# Option 4: Discord webhook (set DISCORD_WEBHOOK_URL environment variable)
# if [ -n "$DISCORD_WEBHOOK_URL" ]; then
#     curl -X POST -H 'Content-type: application/json' \
#         --data "{\"content\":\"$MESSAGE\"}" \
#         "$DISCORD_WEBHOOK_URL"
# fi

# Option 5: ntfy.sh (simple push notifications)
# curl -d "$MESSAGE" ntfy.sh/your-ralph-topic
