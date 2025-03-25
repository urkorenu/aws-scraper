# AWS Infrastructure Inventory Tool

A powerful and efficient tool for collecting and reporting AWS infrastructure resources. This tool provides detailed insights into your AWS environment with support for multiple output formats and customizable resource collection.

## Features

- **Multiple Resource Types**: Collect information about EC2, S3, RDS, Lambda, VPC, and more
- **Flexible Output Formats**: Support for HTML, JSON, YAML, and table formats
- **Customizable Configuration**: YAML-based configuration for easy customization
- **Beautiful HTML Reports**: Modern, responsive HTML reports with interactive tables
- **Resource Filtering**: Filter resources by tags and other criteria
- **Cost Analysis**: Basic cost analysis for major AWS services
- **Security Analysis**: Basic security group analysis
- **Cross-Platform**: Works on Linux, macOS, and Windows (via WSL)

## Installation

### Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/aws-scraper/main/install.sh | bash
```

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/aws-scraper.git
cd aws-scraper
```

2. Install dependencies:
```bash
# For Ubuntu/Debian
sudo apt-get install awscli jq yq

# For macOS
brew install awscli jq yq
```

3. Make the script executable:
```bash
chmod +x src/aws-inventory.sh
```

4. Create a symbolic link:
```bash
sudo ln -s "$(pwd)/src/aws-inventory.sh" /usr/local/bin/aws-inventory
```

## Configuration

The tool uses a YAML configuration file located at `~/.aws-inventory/config.yaml`. A default configuration will be created on first run.

Example configuration:
```yaml
output:
  format: html
  directory: ~/.aws-inventory/reports

resources:
  ec2: true
  s3: true
  rds: true
  lambda: true
  vpc: true

filters:
  tags: {}
  vpc:
    exclude_default: true
    exclude_main_route_tables: true
    exclude_default_subnets: true
```

## Usage

Basic usage:
```bash
aws-inventory
```

With options:
```bash
aws-inventory --format html --output my-report.html
```

### Command Line Options

- `-f, --format FORMAT`: Output format (json|html|table|yaml)
- `-c, --config FILE`: Configuration file path
- `-o, --output FILE`: Output file path
- `-v, --verbose`: Enable verbose logging
- `-h, --help`: Show help message

## Output Formats

### HTML Report
- Modern, responsive design
- Interactive tables
- Resource summaries
- Cost analysis
- Security analysis

### JSON Output
- Structured data format
- Easy to parse and integrate with other tools
- Complete resource information

### YAML Output
- Human-readable format
- Hierarchical structure
- Easy to edit and modify

### Table Output
- Simple text-based format
- Easy to read in terminal
- Basic resource information

## Development

### Project Structure

```
aws-scraper/
├── src/                    # Source code
│   ├── aws-inventory.sh    # Main script
│   ├── html_report.sh      # HTML report generator
│   └── utils.sh           # Utility functions
├── tests/                  # Test files
├── docs/                   # Documentation
├── man/                    # Manual pages
├── bin/                    # Binary files
└── config.yaml            # Default configuration
```

### Running Tests

```bash
make test
```

### Building

```bash
make build
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- AWS CLI team for the powerful command-line interface
- jq developers for JSON processing
- yq developers for YAML processing
- All contributors to this project

## Support

For support, please open an issue in the GitHub repository or contact the maintainers.
