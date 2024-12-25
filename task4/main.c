#include <stdio.h>
#include <stdlib.h>  // For rand() and srand()
#include <time.h>    // For time() function to seed srand()

volatile unsigned *vga = (volatile unsigned *) 0x00004000; /* VGA adapter base address */
unsigned char pixel_list[] = {
#include "../misc/pixels.txt"
};

void vga_plot(unsigned x, unsigned y, unsigned colour)
{
    /* your code here */
    unsigned int result = (y << 24) | (x << 16) | (0x00 << 8) | colour;
    *vga = 0x00004000 + result;
}

unsigned num_pixels = sizeof(pixel_list)/2;

int get_table_value(int col_add, int row_add) {
	// Define the table as a 2D array
    int table[5][5] = {
        {1, 2, 4, 2, 1},
        {2, 4, 8, 4, 2},
        {4, 8, 16, 8, 4},
        {2, 4, 8, 4, 2},
        {1, 2, 4, 2, 1}
    };

    // Adjust col_add and row_add from -2/+2 to index 0-4
    int col_index = col_add + 2;
    int row_index = row_add + 2;

    // Return the value from the table
    return table[row_index][col_index];
}

int compute_weight(int x, int y) {
	int weight = 0;

	int row_add = -2;
	int col_add = -2;

	for (y + row_add; row_add <= 2; row_add++){
		for (x + col_add; col_add <= 2; col_add++) {
			if ( (0 <= x + col_add && x + col_add <= 159) && (0 <= y + row_add && row_add <= 119) ) {
				unsigned int i;
				for (i = 0; i < num_pixels; i++) {
					if ( (x + col_add == pixel_list[2*i]) && (y + row_add == pixel_list[2*i + 1]) ) {
						//weight += 10;
						weight += get_table_value(col_add, row_add);
						i = num_pixels;
					}
				}
			}
			//printf("(%d, %d)\n", x+col_add, y+row_add);
		}
		col_add = -2;
	}

	return ( (weight * 255) / 100) ; //scale num from out of 90 to out of 255

}

int is_in_list(unsigned x, unsigned y) {
	unsigned int i;

	for (i = 0; i < num_pixels; i++){
		if ( (x == pixel_list[2*i]) && (y == pixel_list[2*i + 1]) ) {
			return 1;
		}
	}

	return 0;
}

int main()
{
	//*hex = 0x00;

	unsigned int i;
	unsigned int x;
	unsigned int y;

	for (x = 0; x < 160; x++) {
		for (y = 0; y < 120; y++) {
			vga_plot(x, y, 0);
		}
	}

	for (i = 0; i < num_pixels; i++){
		int weight = compute_weight(pixel_list[2*i], pixel_list[2*i + 1]);
		vga_plot(pixel_list[2*i], pixel_list[2*i + 1], weight);
	}

/*
	for (x = 0; x < 160; x++) {
		for (y = 0; y < 120; y++) {
			if (is_in_list(x, y) == 1) {
				vga_plot(x, y, 0);
			}
			else {
				vga_plot(x, y, 255);
			}
		}
	}
*/

	return 0;
}
