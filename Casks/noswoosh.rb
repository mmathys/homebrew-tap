cask "noswoosh" do
  version "1.7.7"
  sha256 "a31be7d6b7bbee9fea3d1333ea588e1daf02af52ec379e83dcd52643ebbb5da7"

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
    # postflight writes this, so uninstall must remove it: zap only runs with
    # --zap, and a stale plist points launchd at a binary that no longer exists.
    FileUtils.rm(File.expand_path("~/Library/LaunchAgents/ax.max.noswoosh.plist"), force: true)
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

    The daemon picks the grant up on its own within a second. Ctrl+Left /
    Ctrl+Right then switch spaces instantly, and the grant persists across
    upgrades.
  EOS
end
