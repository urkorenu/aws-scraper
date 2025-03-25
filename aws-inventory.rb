class AwsInventory < Formula
  desc "AWS Infrastructure Inventory Tool - A comprehensive tool for listing and analyzing AWS resources"
  homepage "https://github.com/yourusername/aws-inventory"
  url "https://github.com/yourusername/aws-inventory/archive/v1.0.0.tar.gz"
  sha256 "YOUR_SHA256_HERE" # You'll need to replace this with the actual SHA256 of your release

  depends_on "awscli"
  depends_on "jq"
  depends_on "yq"

  def install
    bin.install "bin/aws-inventory"
    share.install "src"
    man1.install "man/aws-inventory.1"
    
    # Create config directory
    (etc/"aws-inventory").mkpath
    
    # Install default config if it doesn't exist
    unless (etc/"aws-inventory/config.yaml").exist?
      (etc/"aws-inventory/config.yaml").write <<~EOS
        output_format: "json"
        resources:
          ec2: true
          s3: true
          rds: true
          lambda: true
          vpc: true
        filters:
          tags: {}
      EOS
    end
  end

  def post_install
    # Create user config directory
    (Dir.home/".aws-inventory").mkpath
    
    # Copy default config to user directory if it doesn't exist
    unless (Dir.home/".aws-inventory/config.yaml").exist?
      cp etc/"aws-inventory/config.yaml", Dir.home/".aws-inventory/"
    end
  end

  test do
    system "#{bin}/aws-inventory", "--version"
  end
end 