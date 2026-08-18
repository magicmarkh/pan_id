#!/usr/bin/env bash
# Moves all accounts from ou-lq9x-5svgxsqy to ou-lq9x-6aumntl4 and resets tags.

SOURCE_OU="ou-lq9x-5svgxsqy"
DEST_OU="ou-lq9x-6aumntl4"

echo "Fetching accounts in $SOURCE_OU..."
ACCOUNT_IDS=$(aws organizations list-children \
  --parent-id "$SOURCE_OU" \
  --child-type ACCOUNT \
  --query "Children[].Id" --output text)

if [ -z "$ACCOUNT_IDS" ]; then
  echo "No accounts found in $SOURCE_OU"
  exit 0
fi

for ACCOUNT_ID in $ACCOUNT_IDS; do
  echo "--- Processing $ACCOUNT_ID ---"

  aws organizations move-account \
    --account-id "$ACCOUNT_ID" \
    --source-parent-id "$SOURCE_OU" \
    --destination-parent-id "$DEST_OU"
  echo "Moved to $DEST_OU"

  aws organizations tag-resource \
    --resource-id "$ACCOUNT_ID" \
    --tags Key=Status,Value=Available
  aws organizations untag-resource \
    --resource-id "$ACCOUNT_ID" \
    --tag-keys AssignedTo AssignedBy AssignedAt
  echo "Tags updated"
done

echo "Done."