-- Opens files in the running Emacs server (the most recently used frame,
-- terminal or GUI). Falls back to the Emacs app if no server is running.
-- Build: osacompile -o ~/Applications/EmacsClient.app macos/EmacsClient.applescript
on open theFiles
	repeat with f in theFiles
		set p to quoted form of POSIX path of f
		do shell script "/opt/homebrew/bin/emacsclient -n " & p & " || open -a Emacs " & p
	end repeat
end open
