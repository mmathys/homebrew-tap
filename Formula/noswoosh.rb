class Noswoosh < Formula
  desc "Instant macOS space switching with Ctrl+arrow keys, minus the swoosh"
  homepage "https://github.com/mmathys/noswoosh"
  url "https://github.com/mmathys/noswoosh/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "159f36057fd111b3beba8cb99e59da4a0cbfb7d1add7ae9c9a96c1a38cdc6a1c"
  license "MIT"

  depends_on :macos

  def install
    system "swiftc", "noswoosh.swift", "-O", "-o", "noswoosh",
           "-F", "/System/Library/PrivateFrameworks", "-framework", "SkyLight"
    system "swiftc", "tools/ctrl-arrows.swift", "-O", "-o", "noswoosh-ctrl-arrows"
    bin.install "noswoosh", "noswoosh-ctrl-arrows"
  end

  service do
    run [opt_bin/"noswoosh"]
    keep_alive true
    process_type :interactive
    log_path var/"log/noswoosh.log"
    error_log_path var/"log/noswoosh.log"
  end

  def caveats
    <<~EOS
      Finish the setup (copy-paste all three commands):

        noswoosh-ctrl-arrows off      # disable the system's animated Ctrl+arrow shortcuts (live + persisted)
        defaults write com.apple.dock workspaces-auto-swoosh -bool NO && killall Dock  # fix the empty-desktop yank
        brew services start noswoosh  # start the daemon now and at every login

      Then the one step that can't be scripted — grant Accessibility
      permission (macOS prompts on first start), or add it manually:
      System Settings > Privacy & Security > Accessibility > "+" and select:

        #{opt_bin}/noswoosh

      Then: brew services restart noswoosh

      NOTE: the Accessibility grant is tied to the binary hash — re-grant it
      after every `brew upgrade noswoosh` (remove the entry, restart the
      service, re-approve).

      To undo everything:

        brew services stop noswoosh
        noswoosh-ctrl-arrows on
        defaults delete com.apple.dock workspaces-auto-swoosh && killall Dock
        brew uninstall noswoosh
    EOS
  end

  test do
    output = shell_output("#{bin}/noswoosh bogus 2>&1", 1)
    assert_match "usage", output
  end
end
