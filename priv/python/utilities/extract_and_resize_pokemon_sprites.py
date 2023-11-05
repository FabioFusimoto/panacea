import cv2

from PIL import Image

initial_x = 11
initial_y = 45
sprite_distance_x = 130
sprite_distance_y = 164
sprite_size_x = 64
sprite_size_y = 64
sprites_per_row = 15
sprite_count = 151
source = Image.open('./sprites_gen_1.png')

target_size_x = 32
target_size_y = 32
target_dimensions = (target_size_x, target_size_y)

new_background_color = (0, 0, 0)

def replace_background(image):
    background_color = image.getpixel((0, 0))
    pixel_data = image.load()

    for y in range(image.size[1]):
        for x in range(image.size[0]):
            pixel_color = pixel_data[x, y]
            if pixel_color == background_color:
                pixel_data[x, y] = new_background_color

    return image

for index in range(sprite_count):
    pokedex_number = index + 1
    filename = './{:03d}.png'.format(pokedex_number)

    horizontal_pixel_offset = (index % sprites_per_row) * sprite_distance_x
    vertical_pixel_offset = (index // sprites_per_row) * sprite_distance_y
    
    crop_region = (
        initial_x + horizontal_pixel_offset,
        initial_y + vertical_pixel_offset,
        initial_x + horizontal_pixel_offset + sprite_size_x,
        initial_y + vertical_pixel_offset + sprite_size_y
    )

    raw_sprite = source.crop(crop_region)
    raw_sprite = replace_background(raw_sprite) 
    raw_sprite.save(filename)

    opencv_image = cv2.imread(filename)
    resized_opencv_image = cv2.resize(opencv_image, target_dimensions, interpolation = cv2.INTER_CUBIC)
    cv2.imwrite(filename, resized_opencv_image)

    resized_pil_image = Image.open(filename)
    rgba_resized_pil_image = resized_pil_image.convert('RGBA')
    rgba_resized_pil_image.save(filename)