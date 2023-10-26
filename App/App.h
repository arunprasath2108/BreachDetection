#ifndef APP_H
#define APP_H

#include <iostream>
#include <map>


#define ENCLAVE_SEAL_NAME "enclave_seal.signed.so"
#define SEALED_FILE_NAME "Sealed_file.txt"

//store the breached passwords.
static std::map<std::string, bool> result_map;


#endif