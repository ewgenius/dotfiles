# Check status of custom services (opencode, tmux, tailscale-serve)
# Works on macOS (launchctl) and Linux (systemd)
# Usage:
#   services                    - show status of all services
#   services restart [name]     - restart one or all services
#   services stop [name]        - stop one or all services
#   services logs [name]        - tail service logs
function services
    set -l cmd $argv[1]
    set -l target $argv[2]

    # Service registry: short names
    set -l all_names opencode tmux tailscale

    # Resolve short name to platform service identifiers
    # Usage: _svc_resolve <name> -> sets _svc_mac and _svc_linux
    function _svc_resolve -a name
        switch "$name"
            case opencode oc
                set -g _svc_mac com.evgenii.opencode
                set -g _svc_linux opencode
                set -g _svc_display opencode
            case tmux
                set -g _svc_mac com.evgenii.tmux
                set -g _svc_linux tmux
                set -g _svc_display tmux
            case tailscale ts tailscale-serve
                set -g _svc_mac com.evgenii.tailscale-serve
                set -g _svc_linux opencode-tailscale
                set -g _svc_display tailscale-serve
            case '*'
                echo "Unknown service: $name"
                echo "Available: opencode (oc), tmux, tailscale (ts)"
                return 1
        end
    end

    # Determine targets (single service or all)
    # Dependency order: tmux and opencode first, tailscale last
    if test -n "$target"
        set _targets $target
        set _targets_rev $target
    else
        set _targets opencode tmux tailscale
        set _targets_rev tailscale opencode tmux
    end

    switch "$cmd"
        case restart
            if test (uname) = Darwin
                # Stop in reverse dependency order
                for name in $_targets_rev
                    _svc_resolve $name; or return 1
                    launchctl unload ~/Library/LaunchAgents/$_svc_mac.plist 2>/dev/null
                end
                # Start in dependency order
                for name in $_targets
                    _svc_resolve $name; or return 1
                    launchctl load ~/Library/LaunchAgents/$_svc_mac.plist 2>/dev/null
                    echo "  $_svc_display: restarted"
                end
            else if command -q systemctl
                for name in $_targets
                    _svc_resolve $name; or return 1
                    systemctl --user restart $_svc_linux.service 2>/dev/null
                    echo "  $_svc_display: restarted"
                end
            end

        case stop
            if test (uname) = Darwin
                for name in $_targets_rev
                    _svc_resolve $name; or return 1
                    launchctl unload ~/Library/LaunchAgents/$_svc_mac.plist 2>/dev/null
                    echo "  $_svc_display: stopped"
                end
            else if command -q systemctl
                for name in $_targets_rev
                    _svc_resolve $name; or return 1
                    systemctl --user stop $_svc_linux.service 2>/dev/null
                    echo "  $_svc_display: stopped"
                end
            end

        case start
            if test (uname) = Darwin
                for name in $_targets
                    _svc_resolve $name; or return 1
                    launchctl load ~/Library/LaunchAgents/$_svc_mac.plist 2>/dev/null
                    echo "  $_svc_display: started"
                end
            else if command -q systemctl
                for name in $_targets
                    _svc_resolve $name; or return 1
                    systemctl --user start $_svc_linux.service 2>/dev/null
                    echo "  $_svc_display: started"
                end
            end

        case logs
            if test (uname) = Darwin
                switch "$target"
                    case opencode oc
                        tail -f /tmp/opencode.log /tmp/opencode.error.log
                    case tailscale ts tailscale-serve
                        tail -f /tmp/tailscale-serve.log /tmp/tailscale-serve.error.log
                    case tmux
                        tail -f /tmp/tmux.log /tmp/tmux.error.log
                    case '*'
                        tail -f /tmp/opencode.log /tmp/opencode.error.log /tmp/tailscale-serve.log /tmp/tmux.log
                end
            else if command -q journalctl
                switch "$target"
                    case opencode oc
                        journalctl --user -u opencode.service -f
                    case tailscale ts tailscale-serve
                        journalctl --user -u opencode-tailscale.service -f
                    case tmux
                        journalctl --user -u tmux.service -f
                    case '*'
                        journalctl --user -u opencode.service -u opencode-tailscale.service -u tmux.service -f
                end
            end

        case '' status
            # Show status table
            set -l mac_services com.evgenii.opencode com.evgenii.tmux com.evgenii.tailscale-serve
            set -l linux_services opencode tmux opencode-tailscale
            set -l names opencode tmux tailscale-serve

            echo "SERVICE          PID       STATUS"
            echo "───────────────  ────────  ──────"

            for i in (seq (count $names))
                set -l name $names[$i]

                if test (uname) = Darwin
                    set -l svc $mac_services[$i]
                    set -l info (launchctl list $svc 2>&1)

                    if string match -q "Could not find*" "$info"
                        printf "%-17s %-9s %s\n" $name "-" "not loaded"
                    else
                        set -l pid (echo "$info" | string match -r '"PID" = (\d+)' | tail -1)
                        set -l exit_code (echo "$info" | string match -r '"LastExitStatus" = (\d+)' | tail -1)

                        if test -n "$pid"
                            printf "%-17s %-9s %s\n" $name $pid (set_color green)"running"(set_color normal)
                        else if test "$exit_code" = "0"
                            printf "%-17s %-9s %s\n" $name "-" (set_color yellow)"exited (0)"(set_color normal)
                        else
                            printf "%-17s %-9s %s\n" $name "-" (set_color red)"failed ($exit_code)"(set_color normal)
                        end
                    end
                else if command -q systemctl
                    set -l svc $linux_services[$i]
                    set -l state (systemctl --user show -p ActiveState --value $svc.service 2>/dev/null)
                    set -l pid (systemctl --user show -p MainPID --value $svc.service 2>/dev/null)
                    test "$pid" = "0"; and set pid "-"

                    switch "$state"
                        case active
                            printf "%-17s %-9s %s\n" $name $pid (set_color green)"running"(set_color normal)
                        case inactive
                            printf "%-17s %-9s %s\n" $name "-" (set_color yellow)"inactive"(set_color normal)
                        case failed
                            printf "%-17s %-9s %s\n" $name "-" (set_color red)"failed"(set_color normal)
                        case '*'
                            printf "%-17s %-9s %s\n" $name "-" "$state"
                    end
                end
            end

            # Health checks
            echo ""
            if curl -sf --max-time 2 http://127.0.0.1:4096 >/dev/null 2>&1
                echo "opencode http:   "(set_color green)"responding"(set_color normal)" on :4096"
            else
                echo "opencode http:   "(set_color red)"not responding"(set_color normal)" on :4096"
            end

            set -l ts_status (tailscale serve status 2>&1)
            if string match -q "*proxy*" "$ts_status"
                set -l ts_url (echo "$ts_status" | string match -r '(https://\S+)' | head -1)
                echo "tailscale serve: "(set_color green)"active"(set_color normal)" at $ts_url"
            else
                echo "tailscale serve: "(set_color red)"inactive"(set_color normal)
            end

        case help
            echo "Usage: services [command] [name]"
            echo ""
            echo "Commands:"
            echo "  (none), status    Show status of all services"
            echo "  start [name]      Start one or all services"
            echo "  stop [name]       Stop one or all services"
            echo "  restart [name]    Restart one or all services"
            echo "  logs [name]       Tail service logs"
            echo "  help              Show this help"
            echo ""
            echo "Services: opencode (oc), tmux, tailscale (ts)"

        case '*'
            echo "Unknown command: $cmd"
            echo "Run 'services help' for usage"
            return 1
    end

    # Cleanup helper functions
    functions -e _svc_resolve
    set -e _svc_mac _svc_linux _svc_display
end
