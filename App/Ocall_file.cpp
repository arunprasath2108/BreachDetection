#include "Ocall_file.h"

void ocall_print_error(const char* str) {

    printf("%s", str);
}

void ocall_print_struct(Userdata* user) {

    std::cout << "id : " << user->user_id << std::endl;    //id success
    if (user == NULL) {
        ocall_print_error("Invalid Userdata pointer");
        return;
    }
}

void ocall_saveFile(uint8_t* sealed_data, size_t sealed_size) {
    bool isFileSaved = saveFile(sealed_data, sealed_size);
    if( !isFileSaved ) {
        std::cout << "Failed in writing to the file." << std::endl;
        return;
    }
}

void ocall_send_result(const char* str, int isBreached, size_t len) {
    
    bool value = false;
    if(isBreached == 1) {
        value = true;
    }
    result_map.insert(std::make_pair(str, value));
    
}