#include"FileHandling.h"

bool saveFile(const uint8_t* sealed_data, const size_t sealed_size) {
    std::ofstream file(SEALED_FILE_NAME, std::ios_base::out);
    if(file.fail()) {
        std::cout << " Can't open the file " << SEALED_FILE_NAME << std::endl;
        return false;
    }
    file.write((const char*) sealed_data, sealed_size);
    file.close();
    return true;
}

bool loadFile(uint8_t* sealed_data, const size_t sealed_size) {
    std::ifstream file(SEALED_FILE_NAME, std::ios_base::in);
    if(file.fail()) {
        std::cout << " Can't open the file " << SEALED_FILE_NAME << std::endl;
        return false;
    }
    file.read((char*) sealed_data, sealed_size);
    file.close();
    return true;
}

size_t getFileSize() {
    std::ifstream file(SEALED_FILE_NAME, std::ios::in | std::ios::binary);
    if (file.fail())
    {
        std::cout << "Failed to open the file \"" << SEALED_FILE_NAME << "\"" << std::endl;
        return 0;
    }
    file.seekg(0, std::ios::end);
    size_t size = (size_t)file.tellg();
    file.close();
    return size;
}