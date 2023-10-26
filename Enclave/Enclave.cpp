#include "Enclave_t.h"
#include "sgx_trts.h"
#include "sgx_tseal.h"
#include "string.h"
#include "PasswordManager.h"

sgx_status_t seal_userdata(const Userdata* user, sgx_sealed_data_t* sealed_data, size_t sealed_size) {
    return sgx_seal_data(0, NULL, sizeof(Userdata), (uint8_t*)user, sealed_size, sealed_data);
}

sgx_status_t unseal_userdata(const sgx_sealed_data_t* sealed_data, Userdata* plaintext, uint32_t plaintext_size) {
    return sgx_unseal_data(sealed_data, NULL, NULL, (uint8_t*)plaintext, &plaintext_size);
}

void ecall_seal_data(unsigned char* pub_key, int user_id, size_t pk_szie) {
    
    sgx_status_t sealing_status;
    Userdata* user = (Userdata*)malloc(sizeof(Userdata));
    if (user == NULL) {
        ocall_print_error("Failed to allocate memory");
        return;
    }
    user->pub_key = pub_key;
    user->user_id = user_id;

    //sealing
    size_t sealed_size = sizeof(sgx_sealed_data_t) + sizeof(Userdata);
    uint8_t* sealed_data = (uint8_t*)malloc(sealed_size);
    sealing_status = seal_userdata(user, (sgx_sealed_data_t*)sealed_data, sealed_size);
    free(user);
    if (sealing_status != SGX_SUCCESS) {
      free(sealed_data);
      ocall_print_error("error in sealing");
    }

    //save sealed data to file
    ocall_saveFile(sealed_data, sealed_size);
    free(sealed_data);
}

void ecall_unseal_data(uint8_t* sealed_data, size_t sealed_size) {
    
    uint32_t plaintext_size = sizeof(Userdata);
    Userdata* unsealed_userdata = (Userdata*)malloc(plaintext_size);

    sgx_status_t unseal_status = unseal_userdata((sgx_sealed_data_t*)sealed_data, unsealed_userdata, plaintext_size);
    if (unseal_status != SGX_SUCCESS) {
      free(unsealed_userdata);
      ocall_print_error("error in unsealing");
    }
    // ocall_print_struct(unsealed_userdata);
    free(sealed_data);
    free(unsealed_userdata);
}

