#!/bin/bash

# Color Output
GREEN="\033[0;32m"
NO_COLOR="\033[0m"

# Simple Banner for ReconMyWay
echo -e "${GREEN}"
echo "====================================="
echo "        ReconMyWay - Automation       "
echo "====================================="
echo -e "${NO_COLOR}"

# Random User-Agent generation for WAF bypass
USER_AGENTS=("Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "Mozilla/5.0 (X11; Linux x86_64)" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" "Mozilla/5.0 (Windows NT 6.1; WOW64)")
RAND_AGENT=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}

# WAF Bypass Headers
CUSTOM_HEADERS="-H 'X-Forwarded-For: 127.0.0.1' -H 'X-Real-IP: 127.0.0.1' -H 'X-Originating-IP: 127.0.0.1'"

# Function to double encode URLs
double_encode() {
    echo -n "$1" | jq -sRr @uri | jq -sRr @uri
}

# Function to add random query parameters to bypass WAF
add_random_query_params() {
    echo "$1?random_param=$RANDOM"
}

# Function to add path variation
add_path_variation() {
    echo "$1/../"
}

# Function to handle URLScan rate limits (429 errors)
handle_rate_limit() {
    echo -e "${GREEN}[ 429 ] Rate limit reached, waiting for cooldown period...${NO_COLOR}"
    sleep 120  # Wait for 2 minutes before retrying (adjust based on service limits)
}

# Check if domain is passed as an argument
if [ -z "$1" ]; then
    echo -e "${GREEN}Usage: $0 <domain>${NO_COLOR}"
    exit 1
fi

TARGET=$1
OUTPUT_DIR="${TARGET}_recon"
mkdir -p $OUTPUT_DIR

echo -e "${GREEN}Step 1: Subdomain Enumeration${NO_COLOR}"
# Run Subfinder and Assetfinder (removing Findomain)
subfinder -d $TARGET -silent -all -o $OUTPUT_DIR/subfinder.txt
assetfinder --subs-only $TARGET | tee $OUTPUT_DIR/assetfinder.txt

# Combine all subdomains and remove duplicates
echo -e "${GREEN}Step 2: Organizing and Removing Duplicates${NO_COLOR}"
cat $OUTPUT_DIR/*.txt > $OUTPUT_DIR/all.txt
sort -u $OUTPUT_DIR/all.txt -o $OUTPUT_DIR/all.txt

# Check if subdomains were found and file is not empty
if [ -s $OUTPUT_DIR/all.txt ]; then
    echo -e "${GREEN}Subdomains found. Proceeding with live domain check.${NO_COLOR}"
    # Check which subdomains are live using httpx-toolkit with WAF bypass options
    httpx-toolkit -l $OUTPUT_DIR/all.txt -ports 80,8080,8000,8888 -o $OUTPUT_DIR/live_domains.txt --silent --threads 100 --timeout 10 --status-code -H "User-Agent: $RAND_AGENT" $CUSTOM_HEADERS
else
    echo -e "${GREEN}No subdomains found. Please check the enumeration step.${NO_COLOR}"
    exit 1
fi

# Fix for Waymore version warning: Setting default values manually if config.yml isn't found
WAYMORE_CONFIG_PATH="config.yml"
if [ ! -f "$WAYMORE_CONFIG_PATH" ]; then
    echo -e "${GREEN}Waymore config.yml not found. Proceeding with default configuration.${NO_COLOR}"
fi

# Use Waymore with Rate Limiting Handling
echo -e "${GREEN}Step 4: Exploring Web Addresses and Endpoints with Rate Limit Handling${NO_COLOR}"
# Try running Waymore, and if rate limit (429) occurs, handle it
until waymore -i $TARGET -mode U -oU $OUTPUT_DIR/waymore.txt; do
    if grep -q "429" <<< "$(tail -n 1 $OUTPUT_DIR/waymore.txt)"; then
        handle_rate_limit
    else
        break
    fi
done

# Use Katana for endpoint discovery
cat $OUTPUT_DIR/live_domains.txt | katana -f qurl -silent -kf all -jc -aff -d 5 -o $OUTPUT_DIR/katana-param.txt

# Run Waybackurls on the target and save output to wayback.txt
echo -e "${GREEN}Step 5: Extracting URLs using Waybackurls${NO_COLOR}"
waybackurls "$TARGET" > $OUTPUT_DIR/wayback.txt

# Integrate Waybackurls tool to extract more endpoints with Rate Limiting
echo -e "${GREEN}Step 6: Extracting More Endpoints using Waybackurls with Rate Limiting${NO_COLOR}"
until cat $OUTPUT_DIR/live_domains.txt | waybackurls > $OUTPUT_DIR/wayback_live.txt; do
    if grep -q "429" <<< "$(tail -n 1 $OUTPUT_DIR/wayback_live.txt)"; then
        handle_rate_limit
    else
        break
    fi
done

# Extract JavaScript files from Waybackurls output
echo -e "${GREEN}Step 7: Extracting JavaScript files using Waybackurls${NO_COLOR}"
waybackurls "$TARGET" | grep -Eo 'https?://[^/]+/[^"]+\.js' > $OUTPUT_DIR/js_files.txt

# Extract interesting files (backup, js, php, etc.)
echo -e "${GREEN}Step 8: Extracting Interesting Files${NO_COLOR}"
grep -E -i -o '\S+\.(cobak|backup|swp|old|db|sql|asp|aspx|aspx~|asp~|php|php~|bak|bkp|cache|cgi|conf|csv|html|inc|jar|js|json|jsp|jsp~|lock|log|rar\.old|sql|tar\.gz|tar\.bz2|zip|xml|json)\b' "$OUTPUT_DIR/waymore.txt" "$OUTPUT_DIR/katana-param.txt" "$OUTPUT_DIR/wayback.txt" "$OUTPUT_DIR/js_files.txt" | sort -u > $OUTPUT_DIR/interesting.txt

# Combine Waymore, Katana, and Waybackurls results, remove duplicates and unnecessary extensions
echo -e "${GREEN}Step 9: Combining Results, Adding Variations, and Encoding Payloads${NO_COLOR}"
cat $OUTPUT_DIR/waymore.txt $OUTPUT_DIR/katana-param.txt $OUTPUT_DIR/wayback.txt $OUTPUT_DIR/js_files.txt | sort -u | grep "=" | qsreplace 'FUZZ' | egrep -v '(.css|.png|.jpeg|.jpg|.svg|.gif|.tif|.tiff|.woff|.woff2|.ico|.pdf)' > $OUTPUT_DIR/waymore-katana-unfilter-urls.txt

# Add advanced WAF bypass techniques
while IFS= read -r line; do
    # Double encoding URLs
    double_encoded_url=$(double_encode "$line")

    # Adding random query parameters
    url_with_random_param=$(add_random_query_params "$line")

    # Adding path variations
    url_with_path_variation=$(add_path_variation "$line")

    echo "$double_encoded_url" >> $OUTPUT_DIR/waymore-katana-unfilter-urls-waf.txt
    echo "$url_with_random_param" >> $OUTPUT_DIR/waymore-katana-unfilter-urls-waf.txt
    echo "$url_with_path_variation" >> $OUTPUT_DIR/waymore-katana-unfilter-urls-waf.txt
done < $OUTPUT_DIR/waymore-katana-unfilter-urls.txt

# Filter live URLs again using httpx-toolkit with WAF bypass techniques
echo -e "${GREEN}Step 10: Filtering Final URLs Using httpx-toolkit with Advanced WAF Bypass${NO_COLOR}"
httpx-toolkit -l $OUTPUT_DIR/waymore-katana-unfilter-urls-waf.txt -o $OUTPUT_DIR/waymore-katana-filter-urls.txt --silent --threads 100 --timeout 10 --status-code -H "User-Agent: $RAND_AGENT" $CUSTOM_HEADERS

# Find URLs with parameters (potential vulnerabilities)
echo -e "${GREEN}Step 11: Finding Testable Parameters${NO_COLOR}"
grep "=" $OUTPUT_DIR/waymore-katana-filter-urls.txt > $OUTPUT_DIR/parameters_with_equal.txt

echo -e "${GREEN}Reconnaissance Completed with Advanced WAF Bypass. Check $OUTPUT_DIR for results.${NO_COLOR}"

