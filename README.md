# AWS Infrastructure Inventory Tool

A professional command-line tool for generating comprehensive reports of your AWS infrastructure resources.

## Features

- 📊 Generate detailed reports of AWS resources (EC2, S3, RDS, Lambda, etc.)
- 💰 Cost analysis and tracking
- 🔒 Security group analysis
- 📱 Multiple output formats (JSON, HTML, Table, YAML)
- 🎨 Beautiful HTML reports with interactive features
- 🔍 Resource filtering and tagging support
- 📈 Resource usage metrics and monitoring

## Installation

### macOS (Homebrew)
```bash
brew install aws-inventory
```

### Linux (apt)
```bash
# Add repository
curl -s https://packagecloud.io/install/repositories/aws-inventory/stable/script.deb.sh | sudo bash

# Install package
sudo apt-get install aws-inventory
```

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/aws-scraper.git
cd aws-scraper

# Install dependencies
./install.sh
```

## Quick Start

1. Configure AWS credentials:
```bash
aws configure
```

2. Create a configuration file (optional):
```yaml
output_format: "html"
resources:
  ec2: true
  s3: true
  rds: true
  lambda: true
filters:
  tags:
    Environment: "production"
```

3. Run the inventory:
```bash
aws-inventory
```

## Configuration

The tool can be configured using either command-line arguments or a YAML configuration file.

### Command-line Arguments

```bash
aws-inventory [OPTIONS]

Options:
  -f, --format FORMAT    Output format (json|html|table|yaml)
  -c, --config FILE     Configuration file path
  -o, --output FILE     Output file path
  -v, --verbose         Enable verbose logging
  -h, --help           Show help message
```

### Configuration File

Create a `config.yaml` file with the following options:

```yaml
output_format: "html"
resources:
  ec2: true
  s3: true
  rds: true
  lambda: true
  vpc: true
  elb: true
  cloudwatch: true
  elasticache: true
  sqs: true
  sns: true
  cloudfront: true
  route53: true
  iam: true
  dynamodb: true
  eks: true

filters:
  tags:
    Environment: "production"
  vpc:
    exclude_default: true
    exclude_main_route_tables: true
    exclude_default_subnets: true
```

## Output Formats

### HTML Report
- Interactive tables
- Resource summary cards
- Cost analysis
- Security group visualization
- Mobile-responsive design

### JSON Output
- Structured data format
- Easy to parse and integrate
- Complete resource details

### Table Output
- Human-readable format
- Terminal-friendly
- Quick overview

### YAML Output
- Hierarchical structure
- Easy to read and edit
- Configuration-friendly

## Development

### Prerequisites
- Bash 4.0+
- AWS CLI
- jq
- yq
- Python 3.8+ (for tests)

### Building from Source
```bash
git clone https://github.com/yourusername/aws-scraper.git
cd aws-scraper
./build.sh
```

### Running Tests
```bash
./test.sh
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- AWS CLI team for the excellent command-line interface
- jq team for JSON processing
- yq team for YAML processing

## Support

For support, please open an issue in the GitHub repository or contact the maintainers.
