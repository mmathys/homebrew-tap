class Spaceswitcher < Formula
  desc "Instant macOS space switching with Ctrl+arrow keys"
  homepage "https://github.com/mmathys/spaceswitcher"
  url "https://github.com/mmathys/spaceswitcher/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "562948839be39884c5017bef6ad82e7baa6077a14c137b9345f8afccab0dc1a3"
  license "MIT"

  depends_on :macos

  def install
    system "swiftc", "spaceswitcher.swift", "-O", "-o", "spaceswitcher",
           "-F", "/System/Library/PrivateFrameworks", "-framework", "SkyLight"
    system "swiftc", "tools/ctrl-arrows.swift", "-O", "-o", "spaceswitcher-ctrl-arrows"
    bin.install "spaceswitcher", "spaceswitcher-ctrl-arrows"
  end

  service do
    run [opt_bin/"spaceswitcher"]
    keep_alive true
    process_type :interactive
    log_path var/"log/spaceswitcher.log"
    error_log_path var/"log/spaceswitcher.log"
  end

  def caveats
    <<~EOS
      Three one-time setup steps:

      1. Disable the system's ANIMATED Ctrl+arrow shortcuts so spaceswitcher
         receives the keys (live now, and persisted for future logins):

           spaceswitcher-ctrl-arrows off
           defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 \\
             '{enabled = 0; value = { parameters = (65535, 123, 8650752); type = standard; };}'
           defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 \\
             '{enabled = 0; value = { parameters = (65535, 124, 8650752); type = standard; };}'

      2. Start the daemon:

           brew services start spaceswitcher

      3. Grant Accessibility permission (macOS prompts on first start), or add
         it manually: System Settings > Privacy & Security > Accessibility >
         "+" and select:

           #{opt_bin}/spaceswitcher

         Then: brew services restart spaceswitcher

      NOTE: the Accessibility grant is tied to the binary hash — re-grant it
      after every `brew upgrade spaceswitcher` (remove the entry, restart the
      service, re-approve).

      To undo everything: brew services stop spaceswitcher,
      spaceswitcher-ctrl-arrows on, re-enable the shortcuts in
      System Settings > Keyboard > Keyboard Shortcuts > Mission Control,
      then brew uninstall spaceswitcher.
    EOS
  end

  test do
    output = shell_output("#{bin}/spaceswitcher bogus 2>&1", 1)
    assert_match "usage", output
  end
end
