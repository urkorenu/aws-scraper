#!/usr/bin/env bash

# HTML Report Generator for AWS Infrastructure Inventory
# Copyright (c) 2024
# Licensed under MIT License

# Function to convert JSON to HTML table
json_to_html_table() {
    local json="$1"
    local title="$2"
    local output_file="$3"
    
    {
        echo "<div class='resource-section'>"
        echo "<h2>$title</h2>"
        
        # Check if the JSON is empty or null
        if [ "$json" == "[]" ] || [ "$json" == "null" ] || [ -z "$json" ]; then
            echo "<p class='no-resources'>No resources found.</p>"
        else
            echo "<div class='table-responsive'>"
            echo "<table class='resource-table'>"
            
            # Extract headers from the first object
            echo "<thead><tr>"
            echo "$json" | jq -r 'if type == "array" then .[0] else . end | keys[] | "<th>\(.)</th>"' 2>/dev/null || echo "<th>Value</th>"
            echo "</tr></thead><tbody>"
            
            # Extract values and create rows
            echo "$json" | jq -r '
                if type == "array" then .[] else . end |
                to_entries |
                map(.value) |
                @tsv
            ' 2>/dev/null | while IFS=$'\t' read -r line; do
                echo "<tr>"
                for value in $line; do
                    # Handle JSON arrays and objects differently
                    if [[ $value == "["* ]] || [[ $value == "{"* ]]; then
                        echo "<td><pre class='json-data'>$value</pre></td>"
                    else
                        echo "<td>$value</td>"
                    fi
                done
                echo "</tr>"
            done
            
            echo "</tbody></table></div>"
        fi
        echo "</div>"
    } >> "$output_file"
}

# Function to generate HTML report
generate_html_report() {
    local temp_dir="$1"
    local output_file="$2"
    
    # Start HTML file
    cat > "$output_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AWS Infrastructure Report</title>
    <style>
        :root {
            --primary-color: #232f3e;
            --secondary-color: #ff9900;
            --background-color: #f5f5f5;
            --card-background: white;
            --text-color: #333;
            --border-color: #eee;
        }
        
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: var(--background-color);
            color: var(--text-color);
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            background: var(--primary-color);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        
        h1 { 
            margin: 0;
            font-size: 24px;
        }
        
        h2 {
            color: var(--primary-color);
            margin-top: 0;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--secondary-color);
        }
        
        .resource-section {
            background: var(--card-background);
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .table-responsive {
            overflow-x: auto;
            margin: 15px 0;
        }
        
        .resource-table {
            width: 100%;
            border-collapse: collapse;
            margin: 10px 0;
            font-size: 14px;
        }
        
        .resource-table th {
            background: var(--primary-color);
            color: white;
            padding: 12px;
            text-align: left;
            position: sticky;
            top: 0;
        }
        
        .resource-table td {
            padding: 10px;
            border-bottom: 1px solid var(--border-color);
        }
        
        .resource-table tbody tr:hover {
            background-color: rgba(255, 153, 0, 0.05);
        }
        
        .tag {
            background: var(--secondary-color);
            color: var(--primary-color);
            padding: 2px 8px;
            border-radius: 12px;
            margin: 2px;
            display: inline-block;
            font-size: 12px;
        }
        
        .timestamp {
            color: #666;
            font-size: 14px;
            margin: 10px 0;
        }
        
        .no-resources {
            color: #666;
            font-style: italic;
            padding: 20px;
            text-align: center;
            background: #f9f9f9;
            border-radius: 4px;
        }
        
        .json-data {
            margin: 0;
            white-space: pre-wrap;
            font-size: 12px;
            font-family: monospace;
        }
        
        .summary-card {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        
        .metric-box {
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            flex: 1;
            margin: 0 10px;
            text-align: center;
        }
        
        .metric-box h3 {
            margin: 0;
            color: var(--primary-color);
            font-size: 14px;
        }
        
        .metric-value {
            font-size: 24px;
            color: var(--secondary-color);
            margin: 10px 0;
        }
        
        @media (max-width: 768px) {
            .summary-card {
                flex-direction: column;
            }
            .metric-box {
                margin: 10px 0;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>AWS Infrastructure Report</h1>
            <div class="timestamp">Generated on: $(date)</div>
        </div>
EOF
    
    # Add summary section
    echo "<div class='summary-card'>" >> "$output_file"
    
    # Count total resources
    EC2_COUNT=$(jq 'length // 0' "$temp_dir/ec2.json" 2>/dev/null || echo "0")
    S3_COUNT=$(jq 'length // 0' "$temp_dir/s3.json" 2>/dev/null || echo "0")
    RDS_COUNT=$(jq 'length // 0' "$temp_dir/rds.json" 2>/dev/null || echo "0")
    
    cat >> "$output_file" << EOF
        <div class="metric-box">
            <h3>EC2 Instances</h3>
            <div class="metric-value">$EC2_COUNT</div>
        </div>
        <div class="metric-box">
            <h3>S3 Buckets</h3>
            <div class="metric-value">$S3_COUNT</div>
        </div>
        <div class="metric-box">
            <h3>RDS Instances</h3>
            <div class="metric-value">$RDS_COUNT</div>
        </div>
EOF
    echo "</div>" >> "$output_file"
    
    # Process each section
    if [ -f "$temp_dir/ec2.json" ]; then
        json_to_html_table "$(cat "$temp_dir/ec2.json")" "EC2 Instances" "$output_file"
    fi
    
    if [ -f "$temp_dir/s3.json" ]; then
        json_to_html_table "$(cat "$temp_dir/s3.json")" "S3 Buckets" "$output_file"
    fi
    
    if [ -f "$temp_dir/rds.json" ]; then
        json_to_html_table "$(cat "$temp_dir/rds.json")" "RDS Instances" "$output_file"
    fi
    
    if [ -f "$temp_dir/lambda.json" ]; then
        json_to_html_table "$(cat "$temp_dir/lambda.json")" "Lambda Functions" "$output_file"
    fi
    
    if [ -f "$temp_dir/vpc.json" ]; then
        json_to_html_table "$(cat "$temp_dir/vpc.json")" "VPC Resources" "$output_file"
    fi
    
    # Close HTML file
    echo "</div></body></html>" >> "$output_file"
} 