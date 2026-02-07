#!/usr/bin/env python3
from PIL import Image, ImageDraw
import os

def create_app_icon():
    # Create 1024x1024 icon (required for macOS)
    size = 1024
    img = Image.new('RGB', (size, size), color='#2C3E50')
    draw = ImageDraw.Draw(img)
    
    # Colors
    bg_color = '#2C3E50'  # Dark blue-gray background
    pane_color = '#ECF0F1'  # Light gray panes
    accent_color = '#3498DB'  # Blue accent
    arrow_color = '#E74C3C'  # Red arrows
    
    # Draw rounded rectangle background
    margin = 80
    draw.rounded_rectangle(
        [margin, margin, size-margin, size-margin],
        radius=120,
        fill=bg_color
    )
    
    # Left pane
    left_pane_x = 150
    left_pane_y = 200
    pane_width = 320
    pane_height = 624
    draw.rounded_rectangle(
        [left_pane_x, left_pane_y, left_pane_x + pane_width, left_pane_y + pane_height],
        radius=30,
        fill=pane_color
    )
    
    # Right pane
    right_pane_x = 554
    draw.rounded_rectangle(
        [right_pane_x, left_pane_y, right_pane_x + pane_width, left_pane_y + pane_height],
        radius=30,
        fill=pane_color
    )
    
    # Add "file" rectangles in left pane
    file_y_start = 250
    file_height = 50
    file_spacing = 70
    for i in range(5):
        y = file_y_start + (i * file_spacing)
        draw.rounded_rectangle(
            [left_pane_x + 30, y, left_pane_x + pane_width - 30, y + file_height],
            radius=8,
            fill=accent_color
        )
    
    # Add "file" rectangles in right pane
    for i in range(3):
        y = file_y_start + (i * file_spacing)
        draw.rounded_rectangle(
            [right_pane_x + 30, y, right_pane_x + pane_width - 30, y + file_height],
            radius=8,
            fill=accent_color
        )
    
    # Draw transfer arrows (right arrow)
    arrow_y = 512
    arrow_start_x = left_pane_x + pane_width + 20
    arrow_end_x = right_pane_x - 20
    arrow_width = 25
    
    # Right arrow shaft
    draw.rectangle(
        [arrow_start_x, arrow_y - arrow_width//2, arrow_end_x - 40, arrow_y + arrow_width//2],
        fill=arrow_color
    )
    
    # Right arrow head
    arrow_head_points = [
        (arrow_end_x - 40, arrow_y - 50),
        (arrow_end_x, arrow_y),
        (arrow_end_x - 40, arrow_y + 50)
    ]
    draw.polygon(arrow_head_points, fill=arrow_color)
    
    # Left arrow (below)
    arrow_y2 = 612
    
    # Left arrow shaft
    draw.rectangle(
        [arrow_start_x + 40, arrow_y2 - arrow_width//2, arrow_end_x, arrow_y2 + arrow_width//2],
        fill=arrow_color
    )
    
    # Left arrow head
    arrow_head_points2 = [
        (arrow_start_x + 40, arrow_y2 - 50),
        (arrow_start_x, arrow_y2),
        (arrow_start_x + 40, arrow_y2 + 50)
    ]
    draw.polygon(arrow_head_points2, fill=arrow_color)
    
    # Save the main icon
    output_dir = 'AppIcon.appiconset'
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate all required sizes for macOS
    sizes = [
        (16, '16x16'),
        (32, '16x16@2x'),
        (32, '32x32'),
        (64, '32x32@2x'),
        (128, '128x128'),
        (256, '128x128@2x'),
        (256, '256x256'),
        (512, '256x256@2x'),
        (512, '512x512'),
        (1024, '512x512@2x')
    ]
    
    for pixel_size, name in sizes:
        resized = img.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS)
        resized.save(f'{output_dir}/icon_{name}.png')
        print(f'Created icon_{name}.png ({pixel_size}x{pixel_size})')
    
    # Create Contents.json
    contents_json = '''{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}'''
    
    with open(f'{output_dir}/Contents.json', 'w') as f:
        f.write(contents_json)
    
    print(f'\nIcon set created in {output_dir}/')
    print('Next steps:')
    print('1. In Xcode, open Assets.xcassets')
    print('2. Delete the existing AppIcon')
    print('3. Drag the AppIcon.appiconset folder into Assets.xcassets')

if __name__ == '__main__':
    create_app_icon()
