# Anamnesis

**NOTE: Safari has implemented this functionality for several versions now
(since Safari 5, in one form or another), so this plugin is no longer required.
It it maintained here for posterity.**

Anamnesis is a [SIMBL](http://www.culater.net/software/SIMBL/SIMBL.php)-based
plugin for Safari on OS X that implements "Reopen Last Closed Tab," a feature
I’m tired of waiting for Apple to add.  The source code is released under the
MIT License.  Features include the following:

- Reopen tabs that have been closed on the current window, obviously
- Maintains all history for closed tabs
- Reassigns the "Hide/Show Tab Bar" key combination to `⌥⇧⌘T` so that the
  `⇧⌘T`
  key combination can be assigned to reopen the last closed tab
- Adds a Reopen Last Closed Tab option to the History menu
- Works on both 32-bit and 64-bit Safari

There are still a few quirks that I’m working out, but they shouldn’t affect
usage for most people:

- The "Reopen Last Closed Tab" option replaces "Reopen All Windows From Last
  Session" in the History menu.  This isn’t due to a technical restriction, but
  for some reason the History menu doesn’t like being modified.  I suspect that
  this has something to do with the fact that it displays a variable number of
  history items underneath "Reopen All Windows From Last Session."
- Reopening the last tab doesn’t restore user input into forms
- If you reopen a window, you can’t reopen tabs in that window

I’m still working on these, but I suspect the first won’t bother most people and
the last two only make it slightly less useful.

Anyway, if you want to give it a shot, do the following:

- Quit Safari
- Download and install [SIMBL](http://www.culater.net/software/SIMBL/SIMBL.php)
- Compile the Anamnesis project to generate `Anamnesis.bundle`
- Copy `Anamnesis.bundle` into either
  `/Library/Application Support/SIMBL/Plugins` or
  `~/Library/Application Support/SIMBL/Plugins` (create one of these directories
  if they don’t exist)
- Fire up Safari

To uninstall, just delete `Anamnesis.bundle` from wherever you put it and
restart Safari.
