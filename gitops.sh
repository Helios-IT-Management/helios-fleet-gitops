#!/usr/bin/env bash

# -e: Immediately exit if any command has a non-zero exit status.
# -x: Print all executed commands to the terminal.
# -u: Exit if an undefined variable is used.
# -o pipefail: Exit if any command in a pipeline fails.
set -exuo pipefail

FLEET_GITOPS_DIR="${FLEET_GITOPS_DIR:-.}"
FLEET_GLOBAL_FILE="${FLEET_GLOBAL_FILE:-$FLEET_GITOPS_DIR/default.yml}"
FLEETCTL="${FLEETCTL:-fleetctl}"
FLEET_DRY_RUN_ONLY="${FLEET_DRY_RUN_ONLY:-false}"
FLEET_DELETE_OTHER_TEAMS="${FLEET_DELETE_OTHER_TEAMS:-true}"

# Check for existence of the global file in case the script is used
# on repositories with team only yamls.
if [ -f "$FLEET_GLOBAL_FILE" ]; then
	# Validate that global file contains org_settings
	grep -Exq "^org_settings:.*" "$FLEET_GLOBAL_FILE"
else
	FLEET_DELETE_OTHER_TEAMS=false
fi

# Indent multiline MDM SSO metadata so it stays valid YAML when injected into default.yml.
# Raw XML pasted into GitHub secrets needs leading spaces on continuation lines.
if [ -n "${FLEET_MDM_SSO_METADATA:-}" ]; then
  FLEET_MDM_SSO_METADATA=$( sed '2,$s/^/        /' <<<  "${FLEET_MDM_SSO_METADATA}")
fi

if compgen -G "$FLEET_GITOPS_DIR"/teams/*.yml > /dev/null; then
  # Validate that every team has a unique name.
  # This is a limited check that assumes all team files contain the phrase: `name: <team_name>`
  ! perl -nle 'print $1 if /^name:\s*(.+)$/' "$FLEET_GITOPS_DIR"/teams/*.yml | sort | uniq -d | grep . -cq
fi

team_files=()
for team_file in "$FLEET_GITOPS_DIR"/teams/*.yml; do
  if [ -f "$team_file" ]; then
    team_files+=("$team_file")
  fi
done

if [ "$FLEET_DELETE_OTHER_TEAMS" = true ]; then
  # Keep a single apply when deleting other teams so Fleet can compute removals
  # against the full desired team set in one request.
  args=()
  if [ -f "$FLEET_GLOBAL_FILE" ]; then
    args=(-f "$FLEET_GLOBAL_FILE")
  fi
  for team_file in "${team_files[@]}"; do
    args+=(-f "$team_file")
  done
  args+=(--delete-other-teams)

  $FLEETCTL gitops "${args[@]}" --dry-run
  if [ "$FLEET_DRY_RUN_ONLY" = true ]; then
    exit 0
  fi

  $FLEETCTL gitops "${args[@]}"
else
  # Apply default and each team separately to avoid very large software batch
  # requests that can hit upstream timeouts/resets.
  if [ -f "$FLEET_GLOBAL_FILE" ]; then
    $FLEETCTL gitops -f "$FLEET_GLOBAL_FILE" --dry-run
  fi
  for team_file in "${team_files[@]}"; do
    $FLEETCTL gitops -f "$team_file" --dry-run
  done

  if [ "$FLEET_DRY_RUN_ONLY" = true ]; then
    exit 0
  fi

  if [ -f "$FLEET_GLOBAL_FILE" ]; then
    $FLEETCTL gitops -f "$FLEET_GLOBAL_FILE"
  fi
  for team_file in "${team_files[@]}"; do
    $FLEETCTL gitops -f "$team_file"
  done
fi