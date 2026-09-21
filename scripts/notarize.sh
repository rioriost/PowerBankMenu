#!/bin/sh
# One credential profile for all PowerBankMenu notarization operations.
# Never add password arguments, environment-variable fallbacks, or shell tracing.
set -eu

readonly NOTARY_PROFILE='powerbankmenu-notary'
readonly DEVELOPER_TEAM='23889H77KX'
readonly NOTARY_KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

usage() {
    cat <<'USAGE'
Usage: scripts/notarize.sh COMMAND [ARGUMENT]

  profile          Show the fixed profile name, team, and keychain
  setup            Register/replace credentials using secure interactive prompts
  check            Validate the saved credentials with Apple's notary service
  submit ZIP       Submit an archive once; return its submission ID as JSON
  info ID          Read the submission status as JSON
  wait ID          Wait up to 60 seconds for an existing submission
  log ID           Retrieve the notarization log
  staple APP       Staple, validate, and assess an accepted .app

Credentials: powerbankmenu-notary in the login keychain.
Run setup in your terminal after issuing an app-specific password.
USAGE
}

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

require_credentials() {
    if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" \
        --keychain "$NOTARY_KEYCHAIN" --output-format json > /dev/null; then
        fail 'Cannot use the fixed notarization profile. Run scripts/notarize.sh setup, or resolve the reported connection/keychain error, then retry check.'
    fi
}

command_name=${1:-help}
case "$command_name" in
    help|-h|--help) usage ;;
    profile|setup|check)
        [ "$#" -eq 1 ] || fail 'This command takes no arguments.'
        case "$command_name" in
            profile)
                printf 'Profile: %s\nTeam: %s\nKeychain: %s\n' \
                    "$NOTARY_PROFILE" "$DEVELOPER_TEAM" "$NOTARY_KEYCHAIN"
                ;;
            setup)
                [ -t 0 ] && [ -t 1 ] || fail 'Run setup interactively in your terminal; do not pipe credentials into this script.'
                printf 'Developer Apple ID: '
                IFS= read -r developer_apple_id
                [ -n "$developer_apple_id" ] || fail 'Apple ID is required.'
                # Omitting --password makes notarytool use its secure prompt.
                xcrun notarytool store-credentials "$NOTARY_PROFILE" \
                    --apple-id "$developer_apple_id" --team-id "$DEVELOPER_TEAM" \
                    --keychain "$NOTARY_KEYCHAIN" --validate
                require_credentials
                printf 'Profile %s is registered and validated.\n' "$NOTARY_PROFILE"
                ;;
            check)
                require_credentials
                printf 'Profile %s is available and authenticated.\n' "$NOTARY_PROFILE"
                ;;
        esac
        ;;
    submit|info|wait|log|staple)
        [ "$#" -eq 2 ] || fail 'This command requires exactly one archive path, submission ID, or app path.'
        argument=$2
        case "$argument" in ''|-*) fail 'The argument must be nonempty and must not begin with a dash.' ;; esac
        case "$command_name" in
            submit)
                [ -f "$argument" ] || fail "Archive not found: $argument"
                case "$argument" in *.zip) ;; *) fail 'Submit a ZIP containing the signed application.' ;; esac
                # Fail before uploading if the fixed profile is missing or invalid.
                require_credentials
                exec xcrun notarytool submit "$argument" \
                    --keychain-profile "$NOTARY_PROFILE" --keychain "$NOTARY_KEYCHAIN" \
                    --output-format json --no-wait
                ;;
            info|log)
                exec xcrun notarytool "$command_name" "$argument" \
                    --keychain-profile "$NOTARY_PROFILE" --keychain "$NOTARY_KEYCHAIN" \
                    --output-format json
                ;;
            wait)
                exec xcrun notarytool wait "$argument" \
                    --keychain-profile "$NOTARY_PROFILE" --keychain "$NOTARY_KEYCHAIN" \
                    --output-format json --timeout 60s
                ;;
            staple)
                [ -d "$argument" ] || fail "Application not found: $argument"
                case "$argument" in *.app) ;; *) fail 'Specify the exported .app directory.' ;; esac
                xcrun stapler staple "$argument"
                xcrun stapler validate "$argument"
                codesign --verify --deep --strict "$argument"
                spctl --assess --type execute --verbose=4 "$argument"
                ;;
        esac
        ;;
    *) usage >&2; exit 1 ;;
esac
