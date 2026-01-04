# Demo Python script that uses external dependencies
# When you run this with d1run, it will:
# 1. Automatically create a .venv in this folder
# 2. Install packages from requirements.txt
# 3. Run this script using the virtual environment

import requests
from colorama import Fore, Style, init

# Initialize colorama for colored output
init()

def main():
    print(f"{Fore.GREEN}========================================{Style.RESET_ALL}")
    print(f"{Fore.CYAN}  d1run Python Auto-venv Demo{Style.RESET_ALL}")
    print(f"{Fore.GREEN}========================================{Style.RESET_ALL}")
    print()
    
    # Make a simple HTTP request to demonstrate 'requests' works
    print(f"{Fore.YELLOW}Making HTTP request to httpbin.org...{Style.RESET_ALL}")
    try:
        response = requests.get("https://httpbin.org/json", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"{Fore.GREEN}✓ Request successful!{Style.RESET_ALL}")
            print(f"  Response title: {data.get('slideshow', {}).get('title', 'N/A')}")
        else:
            print(f"{Fore.RED}✗ Request failed with status: {response.status_code}{Style.RESET_ALL}")
    except Exception as e:
        print(f"{Fore.RED}✗ Request error: {e}{Style.RESET_ALL}")
    
    print()
    print(f"{Fore.MAGENTA}Both 'requests' and 'colorama' were installed automatically!{Style.RESET_ALL}")
    print(f"{Fore.GREEN}Virtual environment is located at: .venv/{Style.RESET_ALL}")

if __name__ == "__main__":
    main()
