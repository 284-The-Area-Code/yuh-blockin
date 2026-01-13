"""
Generate promotional images for App Store In-App Purchases
Creates 1024x1024 images that are distinct from the app icon
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Brand colors from the app
TEAL = (28, 107, 124)  # Primary brand teal
CORAL = (248, 131, 121)  # Accent coral/salmon
WHITE = (255, 255, 255)
DARK_TEAL = (20, 80, 95)
GOLD = (255, 199, 0)  # Premium gold
LIGHT_TEAL = (230, 245, 248)

OUTPUT_DIR = r"C:\Users\Deze_Tingz\AndroidStudioProjects\Yuh_Blockin\assets\iap_promotional"

def create_gradient_background(draw, width, height, color1, color2):
    """Create a vertical gradient background"""
    for y in range(height):
        ratio = y / height
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

def draw_star(draw, center_x, center_y, size, color):
    """Draw a simple star shape"""
    points = []
    import math
    for i in range(10):
        angle = math.pi / 2 + i * math.pi / 5
        r = size if i % 2 == 0 else size / 2
        x = center_x + r * math.cos(angle)
        y = center_y - r * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, fill=color)

def draw_crown(draw, center_x, center_y, width, height, color):
    """Draw a simple crown shape"""
    # Base rectangle
    base_y = center_y + height // 3
    draw.rectangle([
        center_x - width // 2, base_y,
        center_x + width // 2, center_y + height // 2
    ], fill=color)

    # Crown points
    points = [
        (center_x - width // 2, base_y),
        (center_x - width // 2, center_y - height // 4),
        (center_x - width // 4, center_y),
        (center_x, center_y - height // 3),
        (center_x + width // 4, center_y),
        (center_x + width // 2, center_y - height // 4),
        (center_x + width // 2, base_y),
    ]
    draw.polygon(points, fill=color)

    # Crown jewels (circles)
    jewel_y = center_y - height // 6
    draw.ellipse([center_x - 15, jewel_y - 15, center_x + 15, jewel_y + 15], fill=CORAL)
    draw.ellipse([center_x - width//3 - 10, jewel_y + 20, center_x - width//3 + 10, jewel_y + 40], fill=WHITE)
    draw.ellipse([center_x + width//3 - 10, jewel_y + 20, center_x + width//3 + 10, jewel_y + 40], fill=WHITE)

def draw_infinity(draw, center_x, center_y, width, height, color, thickness=20):
    """Draw an infinity symbol"""
    import math
    for t in range(0, 360, 1):
        angle = math.radians(t)
        # Parametric equation for infinity/lemniscate
        scale = width / 3
        x = scale * math.cos(angle) / (1 + math.sin(angle) ** 2)
        y = scale * math.sin(angle) * math.cos(angle) / (1 + math.sin(angle) ** 2)
        draw.ellipse([
            center_x + x - thickness // 2,
            center_y + y * 0.7 - thickness // 2,
            center_x + x + thickness // 2,
            center_y + y * 0.7 + thickness // 2
        ], fill=color)

def create_monthly_promo():
    """Create promotional image for monthly subscription"""
    img = Image.new('RGB', (1024, 1024), WHITE)
    draw = ImageDraw.Draw(img)

    # Gradient background - teal to darker teal
    create_gradient_background(draw, 1024, 1024, TEAL, DARK_TEAL)

    # Decorative circles
    draw.ellipse([50, 50, 250, 250], fill=(255, 255, 255, 30), outline=None)
    draw.ellipse([-100, 700, 200, 1000], fill=(255, 255, 255, 20), outline=None)
    draw.ellipse([800, 100, 1100, 400], fill=(255, 255, 255, 20), outline=None)

    # Draw crown at top
    draw_crown(draw, 512, 280, 200, 180, GOLD)

    # "PREMIUM" text
    try:
        font_large = ImageFont.truetype("arial.ttf", 100)
        font_medium = ImageFont.truetype("arial.ttf", 60)
        font_small = ImageFont.truetype("arial.ttf", 45)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()

    # Main text
    draw.text((512, 450), "PREMIUM", font=font_large, fill=WHITE, anchor="mm")
    draw.text((512, 540), "MONTHLY", font=font_medium, fill=GOLD, anchor="mm")

    # Features list
    features = ["Unlimited Alerts", "10 Vehicles", "All Themes"]
    y_start = 650
    for i, feature in enumerate(features):
        # Checkmark circle
        check_x = 350
        check_y = y_start + i * 70
        draw.ellipse([check_x - 20, check_y - 20, check_x + 20, check_y + 20], fill=CORAL)
        draw.text((check_x, check_y), "✓", font=font_small, fill=WHITE, anchor="mm")
        # Feature text
        draw.text((check_x + 50, check_y), feature, font=font_small, fill=WHITE, anchor="lm")

    # Bottom accent bar
    draw.rectangle([0, 950, 1024, 1024], fill=CORAL)

    # Stars decoration
    draw_star(draw, 150, 400, 30, GOLD)
    draw_star(draw, 874, 400, 30, GOLD)
    draw_star(draw, 100, 600, 20, (255, 255, 255, 100))
    draw_star(draw, 924, 600, 20, (255, 255, 255, 100))

    img.save(os.path.join(OUTPUT_DIR, "monthly_premium_promo_1024.png"), "PNG")
    print(f"Created: monthly_premium_promo_1024.png")

def create_lifetime_promo():
    """Create promotional image for lifetime purchase"""
    img = Image.new('RGB', (1024, 1024), WHITE)
    draw = ImageDraw.Draw(img)

    # Gradient background - gold to dark gold
    dark_gold = (180, 140, 0)
    create_gradient_background(draw, 1024, 1024, GOLD, dark_gold)

    # Decorative elements
    draw.ellipse([750, -100, 1150, 300], fill=(255, 255, 255, 40), outline=None)
    draw.ellipse([-150, 600, 250, 1000], fill=(255, 255, 255, 30), outline=None)

    # Draw infinity symbol for "lifetime"
    draw_infinity(draw, 512, 280, 400, 150, WHITE, 25)

    try:
        font_large = ImageFont.truetype("arial.ttf", 100)
        font_medium = ImageFont.truetype("arial.ttf", 60)
        font_small = ImageFont.truetype("arial.ttf", 45)
        font_xlarge = ImageFont.truetype("arial.ttf", 80)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
        font_xlarge = font_large

    # Main text
    draw.text((512, 420), "LIFETIME", font=font_large, fill=DARK_TEAL, anchor="mm")
    draw.text((512, 510), "PREMIUM", font=font_medium, fill=TEAL, anchor="mm")

    # "ONE TIME" badge
    badge_width, badge_height = 300, 60
    badge_x, badge_y = 512, 590
    draw.rounded_rectangle([
        badge_x - badge_width // 2, badge_y - badge_height // 2,
        badge_x + badge_width // 2, badge_y + badge_height // 2
    ], radius=30, fill=CORAL)
    draw.text((badge_x, badge_y), "ONE TIME PAYMENT", font=font_small, fill=WHITE, anchor="mm")

    # Features list
    features = ["Forever Premium", "All Future Updates", "Priority Support"]
    y_start = 700
    for i, feature in enumerate(features):
        # Diamond bullet
        diamond_x = 330
        diamond_y = y_start + i * 70
        size = 15
        diamond_points = [
            (diamond_x, diamond_y - size),
            (diamond_x + size, diamond_y),
            (diamond_x, diamond_y + size),
            (diamond_x - size, diamond_y)
        ]
        draw.polygon(diamond_points, fill=DARK_TEAL)
        # Feature text
        draw.text((diamond_x + 40, diamond_y), feature, font=font_small, fill=DARK_TEAL, anchor="lm")

    # Bottom accent bar
    draw.rectangle([0, 950, 1024, 1024], fill=TEAL)

    # Sparkle decorations
    draw_star(draw, 150, 200, 25, WHITE)
    draw_star(draw, 874, 200, 25, WHITE)
    draw_star(draw, 200, 500, 15, (255, 255, 255, 150))
    draw_star(draw, 824, 500, 15, (255, 255, 255, 150))

    img.save(os.path.join(OUTPUT_DIR, "lifetime_premium_promo_1024.png"), "PNG")
    print(f"Created: lifetime_premium_promo_1024.png")

if __name__ == "__main__":
    print("Creating IAP Promotional Images...")
    print(f"Output directory: {OUTPUT_DIR}")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    create_monthly_promo()
    create_lifetime_promo()

    print("\nDone! Upload these images to App Store Connect for your IAP products.")
