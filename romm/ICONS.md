# Icon and Logo Requirements

This add-on requires two image files that cannot be generated automatically:

## Required Files

### 1. icon.png
- **Dimensions:** 128x128 pixels
- **Format:** PNG with transparency
- **Purpose:** Displayed in Home Assistant add-on store
- **Location:** `/romm/icon.png`

### 2. logo.png
- **Dimensions:** Approximately 250x100 pixels (or similar aspect ratio)
- **Format:** PNG with transparency
- **Purpose:** Displayed on add-on details page
- **Location:** `/romm/logo.png`

## How to Obtain

### Option 1: Use Official Romm Branding
Download the official Romm logo and icon from the Romm repository:

**GitHub Repository:**
```bash
# Clone Romm repository
git clone https://github.com/rommapp/romm.git

# Look for logo/icon files in:
# - romm/frontend/public/
# - romm/docs/assets/
# - romm/.github/
```

**Extract from Web:**
Visit https://github.com/rommapp/romm and look for logo images in the repository.

### Option 2: Create Custom Icons
If official branding is not available, create custom icons:

1. **Use a game controller icon** (fitting for ROM manager)
2. **Color scheme:** Use Romm's brand colors or Home Assistant theme colors
3. **Tools:**
   - [Figma](https://figma.com) - Free design tool
   - [Canva](https://canva.com) - Easy icon creation
   - [GIMP](https://gimp.org) - Free image editor
   - [Inkscape](https://inkscape.org) - Vector graphics editor

### Option 3: Placeholder Icons
For testing, you can use Material Design Icons:

**icon.png** - Use `mdi:gamepad-variant` rendered as PNG:
- Visit https://materialdesignicons.com/icon/gamepad-variant
- Download or screenshot the icon
- Resize to 128x128 pixels
- Save as PNG with transparent background

**logo.png** - Create text logo:
- Create 250x100px image
- Add text "Romm" with game controller icon
- Use clean, modern font
- Save as PNG

## Installation

Once you have the icon and logo files:

1. **Save files:**
   ```bash
   # Copy icon.png and logo.png to the romm directory
   cp /path/to/icon.png /mnt/d/dev/projects/ha-addons-dev/romm/icon.png
   cp /path/to/logo.png /mnt/d/dev/projects/ha-addons-dev/romm/logo.png
   ```

2. **Verify:**
   ```bash
   ls -lh /mnt/d/dev/projects/ha-addons-dev/romm/*.png
   ```

## Copyright and Attribution

If using official Romm branding:
- Respect Romm's licensing (AGPL-3.0)
- Provide attribution to Romm project
- Do not modify official logos without permission

If creating custom icons:
- Ensure you have rights to use any assets
- Consider contributing back to the community
- Document any third-party assets used

## Notes

- Icons are required for add-on to be published in the Home Assistant add-on store
- For local testing, placeholder icons are acceptable
- High-quality icons improve user experience and add-on discoverability
- Icons should be optimized for file size (use PNG compression)

## Temporary Placeholders

For immediate testing, you can create simple placeholder files:

```bash
# Create a simple colored square as icon (requires ImageMagick)
convert -size 128x128 xc:#5B5FEE romm/icon.png

# Create a simple text logo
convert -size 250x100 xc:#5B5FEE -gravity center -pointsize 40 -fill white -annotate +0+0 "Romm" romm/logo.png
```

**Note:** Replace these with proper icons before publishing the add-on.
