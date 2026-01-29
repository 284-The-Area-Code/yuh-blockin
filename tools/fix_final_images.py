"""
Fix Final images by covering only the 'First 100 customers' promo text with white
Preserves original dimensions and keeps logo/pricing intact
"""

from PIL import Image, ImageDraw
import os

OUTPUT_DIR = r"C:\Users\Deze_Tingz\AndroidStudioProjects\Yuh_Blockin\assets\images"
WHITE = (255, 255, 255)

def fix_image(filename):
    """Cover only the promotional text at bottom with white, keep dimensions"""
    filepath = os.path.join(OUTPUT_DIR, filename)

    img = Image.open(filepath)
    original_size = img.size
    draw = ImageDraw.Draw(img)

    width, height = img.size
    print(f"{filename}: {width}x{height}")

    # For 1024x1024 images:
    # - Logo and "Move with respect" end around y=500
    # - "Premium Monthly — $2.99" around y=580
    # - "Lifetime — $19.99" around y=660
    # - "First 100 customers..." starts around y=720
    # We want to cover from ~y=720 to bottom

    # Cover the promo text area (approximately bottom 30%)
    # This covers "First 100 customers..." and below
    promo_start_y = int(height * 0.72)  # Start covering at 72% down

    # Draw white rectangle over the promo text area only
    draw.rectangle([0, promo_start_y, width, height], fill=WHITE)

    # Verify dimensions unchanged
    assert img.size == original_size, "Dimensions changed!"

    # Save with same format
    if filename.endswith('.jpg'):
        img.save(filepath, 'JPEG', quality=95)
    else:
        img.save(filepath, 'PNG')

    print(f"  Fixed: covered y={promo_start_y} to {height} (kept {width}x{height})")

if __name__ == "__main__":
    print("Fixing promotional images...")
    print("Removing 'First 100 customers' text while keeping dimensions\n")

    fix_image("Final.png")
    fix_image("Final_AppStore_1024x1024.png")
    fix_image("Final_AppStore_1024x1024.jpg")

    print("\nDone! Dimensions preserved, promo text removed.")
