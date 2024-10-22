**ReconMyWay** - Automated Reconnaissance Tool ReconMyWay is an automated web reconnaissance tool built for bug bounty hunters and penetration testers. The tool integrates several powerful utilities to discover subdomains, detect live endpoints, and gather important files such as JavaScript or backup files. It also includes advanced techniques for bypassing Web Application Firewalls (WAFs) using methods like random user-agent rotation, IP spoofing, double encoding, and path variation.

**Key Features** Subdomain Enumeration: Combines Subfinder and Assetfinder to get a comprehensive list of subdomains. Live Domain Detection: Uses httpx-toolkit to detect live subdomains, with WAF bypass options included. URL Exploration: Utilizes Waymore, Katana, and Waybackurls to discover and analyze useful endpoints. File Extraction: Filters out interesting files (such as .php, .js, .backup) for further investigation. WAF Bypass: Implements advanced bypass techniques including random query parameters, double encoding, and path variations to evade basic WAF protections. Rate Limit Handling: Automatically pauses when encountering rate-limiting responses like HTTP 429. This script simplifies the reconnaissance process and makes it more efficient, particularly when dealing with web application firewalls and preparing for vulnerability discovery.

**Prerequisites**:

Before running the ReconMyWay tool, make sure you have the following dependencies installed on your system:

**Subfinder**: ProjectDiscovery's subdomain enumeration tool.

**Install**: go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

**Assetfinder**: A tool for finding subdomains related to a domain.

**Install**: go get github.com/tomnomnom/assetfinder

**httpx-toolkit** or **httpx**: A fast and multi-purpose HTTP toolkit.

**Install**: go install github.com/projectdiscovery/httpx/cmd/httpx@latest

**Waymore**: An automated tool for collecting URL data.

**Install**: Clone the repository from GitHub (git clone https://github.com/xnl-h4ck3r/waymore.git) and run pip3 install -r requirements.txt

**Katana**: A tool for crawling web applications to discover endpoints.

**Install**: go install github.com/projectdiscovery/katana/cmd/katana@latest

**Waybackurls**: A tool to fetch URLs from the Wayback Machine.

**Install**: go install github.com/tomnomnom/waybackurls@latest

**jq**: A lightweight and flexible command-line JSON processor.

**Install**: sudo apt install jq

Make sure all these tools are available in your system’s PATH so that the ReconMyWay script can call them without issues.

**Usage**:

Navigate to the Directory

__cd /path/to/your/recon-script__

Make the Script Executable

__chmod +x recon.sh__

Run the Script with a Target Domain

__./recon.sh example.com__

Replace **example.com** with the domain you are targeting

Next Steps After running ReconMyWay, you will have a set of useful data, including subdomains, live endpoints, JavaScript files, and other potentially interesting files. You can use this data to perform further vulnerability scans with tools like Nuclei to detect weaknesses and security issues in the target application.

**Credits**

This script uses various open-source tools and resources developed by the awesome cybersecurity community. Special thanks to the creators of the following tools:

__Subfinder__: @ProjectDiscovery - Subdomain enumeration tool.

__Assetfinder__: @Tomnomnom - Subdomain finder tool.

__httpx-toolkit__: @ProjectDiscovery - Fast and multi-purpose HTTP toolkit.

__Waymore__: @xnl-h4ck3r - Automated URL data collection tool.

__Katana__: @ProjectDiscovery - Web application crawler and endpoint discovery tool.

__Waybackurls__: @Tomnomnom - Fetches URLs from the Wayback Machine for historical data.

__jq__: @Stephen Dolan - Lightweight and flexible command-line JSON processor.

The development of ReconMyWay would not have been possible without the contributions of these incredible developers and their projects.
