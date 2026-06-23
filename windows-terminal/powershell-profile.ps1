# Windows Terminal shell integration for PowerShell.
#
# Makes "duplicate tab" / "duplicate pane" (and the Alt+v / Alt+s splits and
# Alt+t new-tab bound in windows-terminal/settings.json) open in the directory
# you are CURRENTLY in, instead of the profile's startingDirectory (your home).
#
# Why this is needed: on Windows, PowerShell does not report its working
# directory as you `cd` around, so Windows Terminal cannot know it. The fix is
# to emit the "OSC 9;9" escape sequence from the prompt, which tells the
# terminal the current path. See:
# https://learn.microsoft.com/windows/terminal/tutorials/new-tab-same-directory
#
# install.ps1 appends this fragment to your PowerShell 7 ($PROFILE) under a
# marker block, so it composes with anything else already in your profile.
# If you use oh-my-posh / starship / posh-git, keep their init ABOVE this block:
# it wraps whatever `prompt` is defined when it loads and only appends the
# OSC sequence, so your existing prompt is preserved.

# Capture the prompt defined so far (the built-in default, or your custom one)
# so we augment rather than replace it.
if (Test-Path Function:\prompt) {
  $script:__wtPrevPrompt = $function:prompt
}

function prompt {
  # Render the previous prompt (custom or default) unchanged.
  if ($script:__wtPrevPrompt) {
    $rendered = & $script:__wtPrevPrompt
  } else {
    $rendered = "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
  }

  # Prepend the OSC 9;9 "current working directory" report (filesystem paths
  # only — UNC/registry/etc. providers are skipped). ESC ] 9 ; 9 ; "<path>" ESC \
  $loc = $executionContext.SessionState.Path.CurrentLocation
  if ($loc.Provider.Name -eq 'FileSystem') {
    $osc = "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
    return $osc + $rendered
  }
  return $rendered
}
