#include <fstream>
#include "App.h"

bool saveFile(const uint8_t* sealed_data, const size_t sealed_size);
bool loadFile(uint8_t* sealed_data, size_t sealed_size);
size_t getFileSize();