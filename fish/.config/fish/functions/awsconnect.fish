function awsconnect --description 'Connect to AWS with selected profile'
    # Get profiles from ~/.aws/credentials (lines like [profile-name])
    set -l cred_profiles
    if test -f ~/.aws/credentials
        while read -l line
            if string match -qr '^\[.+\]$' -- $line
                set -a cred_profiles (string replace -r '^\[(.+)\]$' '$1' -- $line)
            end
        end < ~/.aws/credentials
    end

    # Get profiles from ~/.aws/config (lines like [profile profile-name])
    set -l config_profiles
    if test -f ~/.aws/config
        while read -l line
            if string match -qr '^\[profile .+\]$' -- $line
                set -a config_profiles (string replace -r '^\[profile (.+)\]$' '$1' -- $line)
            end
        end < ~/.aws/config
    end

    # Combine and deduplicate profiles
    set -l profiles (printf '%s\n' $cred_profiles $config_profiles | sort -u)

    if test (count $profiles) -eq 0
        echo "No AWS profiles found in ~/.aws/credentials or ~/.aws/config"
        return 1
    end

    echo "Select AWS profile:"
    for i in (seq (count $profiles))
        echo "  $i) $profiles[$i]"
    end

    read -l -P "Enter choice [1-"(count $profiles)"]: " choice

    if test -z "$choice"
        echo "No selection made, aborting."
        return 1
    end

    if not string match -qr '^[0-9]+$' -- $choice
        echo "Invalid input, please enter a number."
        return 1
    end

    if test $choice -lt 1 -o $choice -gt (count $profiles)
        echo "Invalid choice, please select 1-"(count $profiles)"."
        return 1
    end

    set -l selected_profile $profiles[$choice]
    echo "Using profile: $selected_profile"

    AWS_PROFILE=$selected_profile npm run connect --prefix /Users/evgenii/Developer/Spice/ai-platform/infra/aws $argv
end