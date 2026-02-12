#!/usr/bin/env python3
"""
Validate image URLs in HTML files against a curated list of working Unsplash images.
Usage: python3 validate_images.py [html_file_or_directory]
"""

import os
import re
import subprocess
import sys
from pathlib import Path

# Load validated images
VALIDATED_IMAGES = {}
with open("/Users/benstagl/WebsitesMaster/validated_images.txt") as f:
    for line in f:
        if line.strip():
            category, photo_id = line.strip().split(": ")
            VALIDATED_IMAGES[category.lower()] = photo_id

def check_image_url(url):
    """Check if an image URL returns HTTP 200"""
    try:
        result = subprocess.run(
            ['curl', '-s', '-o', '/dev/null', '-w', '%{http_code}', url],
            capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip() == "200"
    except:
        return False

def find_broken_images(html_file):
    """Find all broken Unsplash image URLs in an HTML file"""
    with open(html_file, 'r') as f:
        content = f.read()
    
    # Find all image URLs
    img_pattern = r'src="(https://images\.unsplash\.com/[^"]+)"'
    urls = re.findall(img_pattern, content)
    
    broken = []
    for url in urls:
        if not check_image_url(url):
            broken.append(url)
    
    return broken

def suggest_replacement(broken_url):
    """Suggest a replacement image from validated list"""
    # Try to guess category from HTML context or offer random
    return next(iter(VALIDATED_IMAGES.values()))

if __name__ == "__main__":
    if len(sys.argv) > 1:
        target = sys.argv[1]
        if os.path.isdir(target):
            for html_file in Path(target).glob("**/index.html"):
                broken = find_broken_images(str(html_file))
                if broken:
                    print(f"❌ {html_file}: {len(broken)} broken images")
                else:
                    print(f"✅ {html_file}: All images valid")
        else:
            broken = find_broken_images(target)
            if broken:
                print(f"Found {len(broken)} broken images:")
                for url in broken:
                    print(f"  - {url}")
