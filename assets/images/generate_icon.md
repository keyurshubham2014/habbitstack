# StackHabit App Icon - Quick Generation Guide

Since your app uses the **layers_rounded** icon from Material Icons, here's how to create a matching app icon:

## Option 1: Use Material Icons Export (Recommended)

1. Go to: https://fonts.google.com/icons?icon.query=layers
2. Search for "layers"
3. Click on the "layers" or "layers_rounded" icon
4. Download it (you may need to use screenshot or export tools)
5. Or use this alternative...

## Option 2: Use Figma Material Design Icons (Free)

1. Go to: https://www.figma.com/community/file/1014241558898418245
2. Duplicate the Material Design Icons file
3. Find "layers" icon
4. Export as PNG at 1024x1024
5. Save as `assets/images/app_icon.png`

## Option 3: Create in Canva (Easiest - 5 minutes)

1. Go to: https://www.canva.com/
2. Create: 1024x1024px custom size
3. Add 3 rounded rectangles stacked on top of each other
4. Colors to use:
   - Top layer: #5E60CE (Deep Blue)
   - Middle layer: #4ECDC4 (Gentle Teal)  
   - Bottom layer: #FF6B6B (Warm Coral)
5. Make them slightly offset for depth
6. Download as PNG
7. Save to: `assets/images/app_icon.png`

## Current Status
- Your welcome screen uses: `Icons.layers_rounded` (Material Icon)
- We need to create a PNG version of this for the app launcher icon
- Once you place the PNG at `assets/images/app_icon.png`, run:
  ```bash
  flutter pub get
  dart run flutter_launcher_icons
  flutter clean
  flutter run
  ```
