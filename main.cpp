#include <iostream>
#include <stdexcept>
#include <fstream>

#include <stdio.h>
#include <string.h>
extern "C" int find_markers (char *bitmap,    //  function should return by reference arrays of x/y coordinates
           unsigned int *x_pos,
           unsigned int *y_pos);

#define fileName "source.bmp"

#define HEIGHT 240
#define WIDTH 320

#define WIDTH_OFFSET 0x12       // there is width stored
#define HEIGHT_OFFSET 0x16      // there is height stored
#define FIRST_PIXEL_OFFSET 0x0A // there is the information, where pixels start
#define HEADER_SIZE 54          // how many bytes are in the header
#define MAX_NUMBER_OF_MARKERS 50

int main()
{
    std::ifstream reader;
    reader.open(fileName, std::ios::binary);
    if (reader.good())
        std::cout << "Otwarto plik...\n";
    else
    {
        std::cout << "Unable to open file\n";
        return -2;
    }

    // read header
    char header[HEADER_SIZE];
    reader.read(header, HEADER_SIZE);

    auto fileSize = *reinterpret_cast<uint32_t *>(&header[2]);
    auto dataOffset = *reinterpret_cast<uint32_t *>(&header[10]);
    auto width = *reinterpret_cast<uint32_t *>(&header[18]);
    auto height = *reinterpret_cast<uint32_t *>(&header[22]);

    uint32_t numberOfPixels = width * height;

    if (width != WIDTH || height != HEIGHT)
        throw std::invalid_argument("dimensions do not meet specyfication, width!=320 or height!=240");

    // skipping additinal information, by moving pointer on the list
    reader.seekg(dataOffset);

    // reading image to list
    char image[3 * numberOfPixels];                // reading this not as unsigned char, because it causes problems - does not affect anything
    reader.read(image, 3 * numberOfPixels);

    // declare arrays, where positions will be returned by reference
    unsigned int x_positions[MAX_NUMBER_OF_MARKERS];
    unsigned int y_positions[MAX_NUMBER_OF_MARKERS];

    // call extern function
    int foundMarkersCounter = find_markers(image, x_positions, y_positions);

    // print results 
    std::cout << "Printing results:\n";
    for(int i=0; i<foundMarkersCounter; ++i)
    {
        std::cout << "row: " << y_positions[i] << " column: " << x_positions[i] << '\n';
    }
    std::cout << "End of program\n";
    return 0;
}
