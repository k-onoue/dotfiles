# Julia startup file managed by dotfiles.
# Keep this file lightweight so every Julia process starts quickly.

atreplinit() do repl
    # Make REPL displays a little less compact while leaving scripts untouched.
    repl.options.iocontext[:compact] = false
end
