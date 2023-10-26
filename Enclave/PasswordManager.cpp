#include "PasswordManager.h"


//compare user pass with breached passwords.
void ecall_compare_passwords() {

    for(int i=0;i<userPasswords.size();i++) {

        auto position = breachedPasswords.find(userPasswords[i]);
        if(position != breachedPasswords.end()) {
            result_map.insert(std::make_pair(userPasswords[i], true));
            ocall_send_result(userPasswords[i].c_str(), 1, strlen(userPasswords[i].c_str()));
        }
    }

    freeup_memory();
}

//get user passwords inside enclave
void ecall_get_user_passwords(const char* arr[], size_t len) {

    for (size_t i = 0; i < len; ++i) {
        userPasswords.push_back(arr[i]);
    }
}

//get breached passwords inside enclave
void ecall_get_breached_passwords(const char* password[], size_t len) {

    for (size_t i = 0; i < len; ++i) {
        breachedPasswords.insert(password[i]);
    }
}

//free-up enclave memory
void freeup_memory() {

    userPasswords.clear();
    breachedPasswords.clear();
    result_map.clear();
    
}