extern volatile unsigned *vga;

inline void vga_plot(unsigned x, unsigned y, unsigned colour)
{
    /* your code here */
    unsigned int result = (0x00) | (y << 24) | (x << 16) | (0x00 << 8) | colour;
    *vga = 0x00004000 + result;
}