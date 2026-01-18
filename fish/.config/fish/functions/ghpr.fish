function ghpr --wraps='gh pr create -a @me --fill -r spicehq/engineering' --description 'alias ghpr=gh pr create -a @me --fill -r spicehq/engineering'
  gh pr create -a @me --fill -r spicehq/engineering $argv
        
end
