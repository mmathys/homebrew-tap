cask "noswoosh" do
  version "1.3.1"
  sha256 "bd7d819b0cb0d543e7fb0b967e6549c02fa9529165960c582fd06ffd8ff53cce"

  url "https://github.com/mmathys/noswoosh/releases/download/v#{version}/noswoosh-#{version}.app.zip"
  name "noswoosh"
  desc "Instant space switching with Ctrl+arrow keys, minus the swoosh"
  homepage "https://github.com/mmathys/noswoosh"

  depends_on macos: :monterey

  app "noswoosh.app"
  binary "#{appdir}/noswoosh.app/Contents/MacOS/noswoosh"

  postflight do
    exe = "#{appdir}/noswoosh.app/Contents/MacOS/noswoosh"
    system_command exe, args: ["setup"]

    plist = File.expand_path("~/Library/LaunchAgents/ax.max.noswoosh.plist")
    File.write(plist, <<~XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>ax.max.noswoosh</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{exe}</string>
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
          <string>#{File.expand_path("~/Library/Logs/noswoosh.log")}</string>
      </dict>
      </plist>
    XML

    system_command "/bin/launchctl", args:         ["bootout", "gui/#{Process.uid}/ax.max.noswoosh"],
                                     must_succeed: false
    system_command "/bin/launchctl", args:         ["bootstrap", "gui/#{Process.uid}", plist],
                                     must_succeed: false
  end

  uninstall_preflight do
    system_command "/bin/launchctl", args:         ["bootout", "gui/#{Process.uid}/ax.max.noswoosh"],
                                     must_succeed: false
    system_command "#{appdir}/noswoosh.app/Contents/MacOS/noswoosh", args:         ["teardown"],
                                                                     must_succeed: false
  end

  zap trash: [
    "~/Library/LaunchAgents/ax.max.noswoosh.plist",
    "~/Library/Logs/noswoosh.log",
  ]

  caveats <<~EOS
    One manual step remains: grant Accessibility permission (macOS prompts on
    first start), or add it yourself:

      System Settings > Privacy & Security > Accessibility > "+" and select
      #{appdir}/noswoosh.app

    Then restart the daemon:

      launchctl kickstart -k gui/$(id -u)/ax.max.noswoosh

    Ctrl+Left / Ctrl+Right then switch spaces instantly. Because the app is
    signed with a stable Developer ID, the grant survives future upgrades.
  EOS
end
