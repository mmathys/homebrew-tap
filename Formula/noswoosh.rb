class Noswoosh < Formula
  desc "Instant macOS space switching with Ctrl+arrow keys, minus the swoosh"
  homepage "https://github.com/mmathys/noswoosh"
  url "https://github.com/mmathys/noswoosh/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "58246e3e08307b803b5385d742f41e15e238c12f9f03ee1c77930c800f6fa541"
  license "MIT"

  depends_on :macos

  def install
    system "swiftc", "noswoosh.swift", "-O", "-o", "noswoosh",
           "-F", "/System/Library/PrivateFrameworks", "-framework", "SkyLight"
    bin.install "noswoosh"
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

        noswoosh setup                # shortcuts + empty-desktop yank fix (restarts the Dock)
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
        noswoosh teardown
        brew uninstall noswoosh
    EOS
  end

  test do
    output = shell_output("#{bin}/noswoosh bogus 2>&1", 1)
    assert_match "usage", output
  end
end
