class Spaceswitcher < Formula
  desc "Instant macOS space switching with Ctrl+arrow keys"
  homepage "https://github.com/mmathys/spaceswitcher"
  url "https://github.com/mmathys/spaceswitcher/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "d259f22f1100e3b9c3f17491b9afc7748ce85afab7c3774d2beb9c3faf67d25e"
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
      Finish the setup (copy-paste both commands):

        spaceswitcher-ctrl-arrows off      # disable the system's animated Ctrl+arrow shortcuts (live + persisted)
        brew services start spaceswitcher  # start the daemon now and at every login

      Then the one step that can't be scripted — grant Accessibility
      permission (macOS prompts on first start), or add it manually:
      System Settings > Privacy & Security > Accessibility > "+" and select:

        #{opt_bin}/spaceswitcher

      Then: brew services restart spaceswitcher

      NOTE: the Accessibility grant is tied to the binary hash — re-grant it
      after every `brew upgrade spaceswitcher` (remove the entry, restart the
      service, re-approve).

      To undo everything:

        brew services stop spaceswitcher
        spaceswitcher-ctrl-arrows on
        brew uninstall spaceswitcher
    EOS
  end

  test do
    output = shell_output("#{bin}/spaceswitcher bogus 2>&1", 1)
    assert_match "usage", output
  end
end
