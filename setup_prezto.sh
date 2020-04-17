rm -f ~/.zshrc
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

rm -f ~/.zpreztorc
cat > ~/.zpreztorc <<- EOM
zstyle ':prezto:*:*' color 'yes'
zstyle ':prezto:load' pmodule \\
  'environment' \\
  'terminal' \\
  'editor' \\
  'history' \\
  'directory' \\
  'spectrum' \\
  'utility' \\
  'completion' \\
  'prompt' \\
  'history-substring-search' \\
  'git'
zstyle ':prezto:module:editor' key-bindings 'emacs'
zstyle ':prezto:module:prompt' theme 'sorin'
EOM

echo ""
echo "All done!"

exit
