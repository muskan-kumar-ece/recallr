import os
from PIL import Image, ImageDraw

def create_recallr_icon(size):
    # Create high-res canvas (1024x1024) for supersampling
    scale = 1024
    img = Image.new("RGBA", (scale, scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background Rounded Squircle
    padding = 40
    radius = 230
    bg_color = (13, 15, 22, 255)  # Obsidian Dark Base
    border_color = (40, 46, 68, 255)  # Slate border

    draw.rounded_rectangle(
        [padding, padding, scale - padding, scale - padding],
        radius=radius,
        fill=bg_color,
        outline=border_color,
        width=16
    )

    # 2. Glowing Neural Core Accents (circles in background)
    glow_color = (124, 58, 237, 45)  # Violet glow
    draw.ellipse([260, 260, 764, 764], fill=glow_color)
    cyan_glow = (6, 182, 212, 40)  # Cyan glow
    draw.ellipse([340, 340, 684, 684], fill=cyan_glow)

    # 3. Main Brand 'R' Geometry
    # Left vertical stem
    stem_color = (139, 92, 246, 255)  # Electric Violet
    draw.rounded_rectangle([280, 240, 380, 784], radius=36, fill=stem_color)

    # Upper loop of 'R'
    loop_color = (6, 182, 212, 255)  # Cyan
    # Outer arc
    draw.rounded_rectangle([340, 240, 720, 520], radius=110, fill=loop_color)
    # Inner cutout
    draw.rounded_rectangle([420, 310, 620, 450], radius=60, fill=bg_color)
    # Re-draw stem overlap cleanly
    draw.rounded_rectangle([280, 240, 380, 784], radius=36, fill=stem_color)

    # Diagonal Kick Leg of 'R'
    leg_color = (245, 158, 11, 255)  # Amber / Cyan gradient node
    # Draw leg polygon with rounded joint
    leg_points = [(460, 470), (540, 470), (740, 760), (640, 784)]
    draw.polygon(leg_points, fill=loop_color)
    # Rounded foot
    draw.ellipse([630, 720, 750, 794], fill=loop_color)

    # 4. Neural Connection Nodes (Recallr Memory Dots)
    node_violet = (167, 139, 250, 255)
    node_cyan = (56, 189, 248, 255)
    node_amber = (251, 191, 36, 255)

    # Top-right node
    draw.ellipse([700, 200, 770, 270], fill=node_cyan)
    # Bottom-left node
    draw.ellipse([210, 730, 270, 790], fill=node_violet)
    # Center accent node
    draw.ellipse([640, 470, 690, 520], fill=node_amber)

    # Resize to target size with high quality Lanczos filter
    final_icon = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_icon

def main():
    targets = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
    }

    for path, size in targets.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        icon = create_recallr_icon(size)
        icon.save(path, "PNG")
        print(f"Generated {path} ({size}x{size})")

if __name__ == "__main__":
    main()
