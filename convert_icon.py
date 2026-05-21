#!/usr/bin/env python3
"""
Simple SVG to PNG converter for app icon
Requires: pip3 install pillow svglib
"""

try:
    from svglib.svglib import svg2rlg
    from reportlab.graphics import renderPM
    
    drawing = svg2rlg("assets/images/app_icon.svg")
    renderPM.drawToFile(drawing, "assets/images/app_icon.png", fmt="PNG", dpi=300)
    
    # Resize to 1024x1024 using PIL
    from PIL import Image
    img = Image.open("assets/images/app_icon.png")
    img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    img.save("assets/images/app_icon.png")
    
    print("✓ Successfully converted SVG to PNG (1024x1024)")
    print("✓ Run: dart run flutter_launcher_icons")
    
except ImportError as e:
    print(f"❌ Missing dependency: {e}")
    print("\nPlease install required packages:")
    print("  pip3 install pillow svglib reportlab")
    print("\nOr use online converter:")
    print("  1. Go to https://svgtopng.com/")
    print("  2. Upload assets/images/app_icon.svg")
    print("  3. Set size to 1024x1024")
    print("  4. Save as assets/images/app_icon.png")
    print("  5. Run: dart run flutter_launcher_icons")
