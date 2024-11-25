from PIL import Image

def ensure_icon_requirements(input_path, output_path):
    """
    Ensures the image meets app icon requirements:
    - 1024x1024 pixels
    - PNG format
    - No transparency

    Args:
    - input_path: Path to the input image.
    - output_path: Path to save the adjusted image.
    """
    try:
        # Open the image
        with Image.open(input_path) as img:
            print(f"Original mode: {img.mode}")
            # Convert the image to RGBA if needed
            if img.mode not in ("RGBA", "RGB"):
                print(f"Converting image to RGB mode from {img.mode}...")
                img = img.convert("RGB")
                print(f"Converting image to RGBA mode...")
                img = img.convert("RGBA")
            
            # Remove transparency if present
            if img.mode == "RGBA":
                print(f"Removing transparency...")
                background = Image.new("RGBA", img.size, (255, 255, 255, 255))  # White background with full opacity
                img = Image.alpha_composite(background, img).convert("RGB")
            
            # Ensure the size is 1024x1024
            if img.size != (1024, 1024):
                print(f"Resizing image to 1024x1024 pixels...")
                img = img.resize((1024, 1024), Image.ANTIALIAS)
            
            # Save the final image
            img.save(output_path, format="PNG")
            print(f"App icon saved at {output_path}.")

    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
# input_image_path = "clients/app/irlapp/irlapp/Assets/AppIcon.png"  # Replace with the path to your image
# output_image_path = "appIcon.png"  # Replace with the desired output path
# ensure_icon_requirements(input_image_path, output_image_path)