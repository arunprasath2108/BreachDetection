#include "App.h"
#include "sgx_urts.h"
#include "UserPassword.h"
#include "BreachedPasswords.h"
#include "Ocall_file.h"



static sgx_status_t initialize_enclave(const char* enclave_path, sgx_enclave_id_t *eid)
{
    sgx_status_t ret = SGX_ERROR_UNEXPECTED;

    ret = sgx_create_enclave(enclave_path, SGX_DEBUG_FLAG, NULL, NULL, eid, NULL);
    if (ret != SGX_SUCCESS) {
        return ret;
    }
    return SGX_SUCCESS;
}

bool seal_data(sgx_enclave_id_t eid) {

    const char* pub_key = "MIIBORq6a+HPGQMd2kTQIhAKMSvzIBnni7ot/+Uyv/Ow5T0q5gIJAiEAyS";
    int user_id = 123;

    sgx_status_t ret = ecall_seal_data(eid, (unsigned char*) pub_key, user_id, strlen(pub_key));
    if(ret != SGX_SUCCESS) {
        return false;
    }
    return true;
}

bool unseal_data(sgx_enclave_id_t eid) {


    // Read the sealed blob from the file
    size_t sealed_size = getFileSize();
    if(sealed_size == 0) 
    {   
        std::cout << "error in file size\n";
        return false; 
    }
    if (sealed_size == (size_t)-1)
    {
        std::cout << "Failed to get the file size of \"" << SEALED_FILE_NAME << "\"" << std::endl;
        return false;
    }
    // std::cout << "size : " << sealed_size << "\n";
    uint8_t *sealed_data = (uint8_t *)malloc(sealed_size);
    if(sealed_data == NULL)
    {
        std::cout << "Out of memory" << std::endl;
        free(sealed_data);
        return false;
    }
    if(!loadFile(sealed_data, sealed_size)) {
        free(sealed_data);
        return false;
    }

    // ocall_print_uint8_t(sealed_data, sealed_size);

    //unseal data
    sgx_status_t unseal_status = ecall_unseal_data(eid, sealed_data, sealed_size);
    if (unseal_status != SGX_SUCCESS)
    {   
        std::cout << "err\n";
        free(sealed_data);
        // sgx_destroy_enclave(eid);
        return false;
    }

    return true;
}

int checkBreachedPasswords(sgx_enclave_id_t eid) {

    sgx_status_t ret;

    ret = ecall_get_breached_passwords(eid, breached_passwords, breach_password_count);
    if(ret != SGX_SUCCESS) {
        return 0;
    }

    ret = ecall_get_user_passwords(eid, user_passwords, num_passwords);
    if(ret != SGX_SUCCESS) {
        return 0;
    }

    ret = ecall_compare_passwords(eid);
    if(ret != SGX_SUCCESS) {
        std::cout << " Error.\n";
    }

    return 1;
}

int main() {

    sgx_enclave_id_t eid = 0;

    sgx_status_t ret = initialize_enclave(ENCLAVE_SEAL_NAME, &eid);
    if (ret != SGX_SUCCESS)
    {   
        std::cout << " error \n";
        return 0;
    }

    if(seal_data(eid)) {
        std::cout << "Sealing data success." << std::endl;
    }
    
    // if(unseal_data(eid)) {
    //     std::cout << "Unsealing data success." << std::endl;
    // }

    if(!checkBreachedPasswords(eid)) {
        std::cout << "failed in send Usr Pass\n";
    }

    for(auto it : result_map) {
        std::cout << it.first << " ~ " << it.second << "\n";
    }


}





