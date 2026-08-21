class Noswoosh < Formula
  desc "Instant macOS space switching with Ctrl+arrow keys, minus the swoosh"
  homepage "https://github.com/mmathys/noswoosh"
  url "https://github.com/mmathys/noswoosh/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "fe53737a6d36e56820df0e442ea3d9f4bb419405ea654b435aad2e2b18563239"
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
      Finish the setup (copy-paste both commands):

        noswoosh-ctrl-arrows off      # disable the system's animated Ctrl+arrow shortcuts (live + persisted)
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
        brew uninstall noswoosh
    EOS
  end

  test do
    output = shell_output("#{bin}/noswoosh bogus 2>&1", 1)
    assert_match "usage", output
  end
end
