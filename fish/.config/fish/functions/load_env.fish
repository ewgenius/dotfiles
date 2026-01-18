function load_env
    set -l env_file $argv[1]
    for line in (cat $env_file)
        # Skip empty lines and comments
        if test -z "$line"; or string match -qr '^\s*#' -- $line
            continue
        end

        # Only process lines that look like KEY=VALUE
        if string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- $line
            set key (string split -m 1 '=' $line)[1]
            set value (string split -m 1 '=' $line)[2]
            set -x $key $value
        end
    end
end
