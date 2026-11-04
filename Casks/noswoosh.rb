cask "noswoosh" do
  version "1.7.7"
  sha256 "a31be7d6b7bbee9fea3d1333ea588e1daf02af52ec379e83dcd52643ebbb5da7"

  url "https://github.com/mmathys/noswoosh/releases/download/v#{version}/noswoosh-#{version}.app.zip"
  name "noswoosh"
  desc "Instant space switching with Ctrl+arrow keys, minus the swoosh"
  homepage "https://github.com/mmathys/noswoosh"

  depends_on macos: :monterey

  app "noswoosh.app"
  # Install steps run sandboxed, where `defaults` cannot write (`noswoosh setup`
  # still reports success) and launchd refuses `launchctl bootstrap`. So this runs
  # as an installer script, before the app is moved into place. KeepAlive is the
  # fallback if launchd tries to spawn the agent before the binary exists.
  installer script: {
    executable:   "/bin/sh",
    args:         ["-c",
                   <<~SH,
                     "$1" setup || exit 1
                     plist="$HOME/Library/LaunchAgents/ax.max.noswoosh.plist"
                     mkdir -p "$(dirname "$plist")"
                     cat > "$plist" <<XML
                     <?xml version="1.0" encoding="UTF-8"?>
                     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                     <plist version="1.0">
                     <dict>
                         <key>Label</key>
                         <string>ax.max.noswoosh</string>
                         <key>ProgramArguments</key>
                         <array>
                             <string>$0</string>
                         </array>
                         <key>RunAtLoad</key>
                         <true/>
                         <key>KeepAlive</key>
                         <true/>
                         <key>ProcessType</key>
                         <string>Interactive</string>
                         <key>LimitLoadToSessionType</key>
                         <string>Aqua</string>
                         <key>StandardErrorPath</key>
                         <string>$HOME/Library/Logs/noswoosh.log</string>
                     </dict>
                     </plist>
                     XML
                     launchctl bootout "gui/$(id -u)/ax.max.noswoosh"
                     launchctl bootstrap "gui/$(id -u)" "$plist"
                   SH
                   "#{appdir}/noswoosh.app/Contents/MacOS/noswoosh",
                   "#{staged_path}/noswoosh.app/Contents/MacOS/noswoosh"],
    must_succeed: false,
  }
  binary "#{appdir}/noswoosh.app/Contents/MacOS/noswoosh"

  # Not `launchctl:`, which also looks the service up with sudo and can prompt for
  # a password. Removing the plist here matters: zap only runs with --zap, and a
  # stale plist points launchd at a binary that no longer exists.
  uninstall script: {
    executable:   "/bin/sh",
    args:         ["-c", 'launchctl bootout "gui/$(id -u)/ax.max.noswoosh"; "$0" teardown; ' \
                         'rm -f "$HOME/Library/LaunchAgents/ax.max.noswoosh.plist"',
                   "#{appdir}/noswoosh.app/Contents/MacOS/noswoosh"],
    must_succeed: false,
  }

  zap trash: [
    "~/Library/LaunchAgents/ax.max.noswoosh.plist",
    "~/Library/Logs/noswoosh.log",
  ]

  caveats <<~EOS
    One manual step remains: grant Accessibility permission (macOS prompts on
    first start), or add it yourself:

      System Settings > Privacy & Security > Accessibility > "+" and select
      #{appdir}/noswoosh.app

    The daemon picks the grant up on its own within a second. Ctrl+Left /
    Ctrl+Right then switch spaces instantly, and the grant persists across
    upgrades.
  EOS
end
