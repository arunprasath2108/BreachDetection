#SGX SDK Settings

SGX_SDK ?= /home/arun-17915/Desktop/linux-sgx/linux/installer/bin/sgxsdk
# SGX_SDK ?= /opt/intel/sgxsdk
SGX_SSL ?= /home/arun-17915/Desktop/ssl/intel-sgx-ssl/Linux/package
SGX_MODE ?= HW
SGX_ARCH ?= x64
SGX_DEBUG ?= 1

ifeq ($(shell getconf LONG_BIT), 32)
	SGX_ARCH := x86
else ifeq ($(findstring -m32, $(CXXFLAGS)), -m32)
	SGX_ARCH := x86
endif

ifeq ($(SGX_ARCH), x86)
	SGX_COMMON_FLAGS := -m32
	SGX_LIBRARY_PATH := $(SGX_SDK)/lib
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x86/sgx_sign
	SGX_EDGER8R := $(SGX_SDK)/bin/x86/sgx_edger8r
else
	SGX_COMMON_FLAGS := -m64
	SGX_LIBRARY_PATH := $(SGX_SDK)/lib64
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x64/sgx_sign
	SGX_EDGER8R := $(SGX_SDK)/bin/x64/sgx_edger8r
endif

ifeq ($(SGX_DEBUG), 1)
ifeq ($(SGX_PRERELEASE), 1)
$(error Cannot set SGX_DEBUG and SGX_PRERELEASE at the same time!!)
endif
endif

ifeq ($(SGX_DEBUG), 1)
	SGX_COMMON_FLAGS += -O0 -g
else
	SGX_COMMON_FLAGS += -O2
endif

SGX_COMMON_FLAGS += -Wall -Wextra -Winit-self -Wpointer-arith -Wreturn-type \
                     -Waddress -Wsequence-point -Wformat-security \
                     -Wmissing-include-dirs -Wfloat-equal -Wundef -Wshadow \
                     -Wcast-align -Wcast-qual -Wconversion -Wredundant-decls
SGX_COMMON_CFLAGS = $(SGX_COMMON_FLAGS) -Wjump-misses-init -Wstrict-prototypes -Wunsuffixed-float-constants
SGX_COMMON_CXXFLAGS = $(SGX_COMMON_FLAGS) -Wnon-virtual-dtor -std=c++11


#App Settings

ifneq ($(SGX_MODE), HW)
	Urts_Library_Name := sgx_urts_sim
else
	Urts_Library_Name := sgx_urts
endif

App_Cpp_Files := $(wildcard App/*.cpp)
App_Include_Paths := -I$(SGX_SDK)/include 

App_Compile_CFlags := -fPIC -Wno-attributes $(App_Include_Paths)
# Three configuration modes - Debug, prerelease, release
#   Debug - Macro DEBUG enabled.
#   Prerelease - Macro NDEBUG and EDEBUG enabled.
#   Release - Macro NDEBUG enabled.
ifeq ($(SGX_DEBUG), 1)
        App_Compile_CFlags += -DDEBUG -UNDEBUG -UEDEBUG
else ifeq ($(SGX_PRERELEASE), 1)
        App_Compile_CFlags += -DNDEBUG -DEDEBUG -UDEBUG
else
        App_Compile_CFlags += -DNDEBUG -UEDEBUG -UDEBUG
endif

App_Compile_CXXFlags := -std=c++0x $(App_Compile_CFlags)
App_Link_Flags := -L$(SGX_LIBRARY_PATH) -l$(Urts_Library_Name) -lpthread -L$(SGX_SSL)/lib64 -lsgx_usgxssl

Gen_Untrusted_Source_Seal := App/Enclave_u.c
Gen_Untrusted_Object_Seal := App/Enclave_u.o

App_Objects := $(Gen_Untrusted_Object_Seal) $(App_Cpp_Files:.cpp=.o)

App_Name := app


# Enclave Settings 

ifneq ($(SGX_MODE), HW)
	Trts_Library_Name := sgx_trts_sim
	Service_Library_Name := sgx_tservice_sim
else
	Trts_Library_Name := sgx_trts
	Service_Library_Name := sgx_tservice
endif
Crypto_Library_Name := sgx_tcrypto

Enclave_Include_Paths := -I$(SGX_SDK)/include -I$(SGX_SDK)/include/tlibc -I$(SGX_SDK)/include/libcxx -I$(SGX_SSL)/include/openssl -I$(SGX_SSL)/include -ltsgxsslio.h

CC_BELOW_4_9 := $(shell expr "`$(CC) -dumpversion`" \< "4.9")
ifeq ($(CC_BELOW_4_9), 1)
	Enclave_Compile_CFlags := -fstack-protector
else
	Enclave_Compile_CFlags := -fstack-protector-strong
endif
Enclave_Compile_CFlags += -nostdinc -ffreestanding -fvisibility=hidden -fpie -ffunction-sections -fdata-sections $(Enclave_Include_Paths)
Enclave_Compile_CXXFlags := -nostdinc++ -std=c++11 $(Enclave_Compile_CFlags)

# Enable the security flags
Enclave_Security_Link_Flags := -Wl,-z,relro,-z,now,-z,noexecstack

SGX_SSL_Link_Flags := -L$(SGX_SSL)/lib64 -Wl,--whole-archive -lsgx_tsgxssl -Wl,--no-whole-archive \
						-lsgx_tsgxssl_crypto -Wl,--whole-archive -lsgx_pthread


# To generate a proper enclave, it is recommended to follow below guideline to link the trusted libraries:
#    1. Link sgx_trts with the `--whole-archive' and `--no-whole-archive' options,
#       so that the whole content of trts is included in the enclave.
#    2. For other libraries, you just need to pull the required symbols.
#       Use `--start-group' and `--end-group' to link these libraries.
# Do NOT move the libraries linked with `--start-group' and `--end-group' within `--whole-archive' and `--no-whole-archive' options. 
# Otherwise, you may get some undesirable errors.
Enclave_Link_Flags := $(Enclave_Security_Link_Flags) $(SGX_SSL_Link_Flags) \
    -Wl,--no-undefined -nostdlib -nodefaultlibs -nostartfiles -L$(SGX_LIBRARY_PATH) \
	-Wl,--whole-archive -l$(Trts_Library_Name) -Wl,--no-whole-archive \
	-Wl,--start-group -lsgx_tstdc -lsgx_tcxx -l$(Crypto_Library_Name) -l$(Service_Library_Name) -Wl,--end-group \
	-Wl,-Bstatic -Wl,-Bsymbolic -Wl,--no-undefined -Wl,-pie,-eenclave_entry \
	-Wl,--export-dynamic -Wl,--defsym,__ImageBase=0 -Wl,--gc-sections \


# Enclave_Seal
Enclave_Cpp_Files := $(wildcard Enclave/*.cpp)
Enclave_Cpp_Objects := $(Enclave_Cpp_Files:.cpp=.o)
Gen_Trusted_Source_Seal := Enclave/Enclave_t.c
Gen_Trusted_Object_Seal := Enclave/Enclave_t.o
Enclave_Objects_Files := $(Gen_Trusted_Object_Seal) $(Enclave_Cpp_Files:.cpp=.o)

Enclave_Seal_Name := enclave_seal.so
Signed_Enclave_Seal_Name := enclave_seal.signed.so
Enclave_Seal_Config_File := Enclave/Enclave.config.xml
Enclave_Seal_Test_Key := Enclave/Enclave_private_test.pem
Enclave_Seal_Link_Flags := $(Enclave_Link_Flags) -Wl,--version-script=Enclave/Enclave.lds


ifeq ($(SGX_MODE), HW)
ifeq ($(SGX_DEBUG), 1)
	Build_Mode = HW_DEBUG
else ifeq ($(SGX_PRERELEASE), 1)
	Build_Mode = HW_PRERELEASE
else
	Build_Mode = HW_RELEASE
endif
else
ifeq ($(SGX_DEBUG), 1)
	Build_Mode = SIM_DEBUG
else ifeq ($(SGX_PRERELEASE), 1)
	Build_Mode = SIM_PRERELEASE
else
	Build_Mode = SIM_RELEASE
endif
endif

.PHONY: all target
all: .config_$(Build_Mode)_$(SGX_ARCH)
	@$(MAKE) target

ifeq ($(Build_Mode), HW_RELEASE)
target: $(App_Name) $(Enclave_Seal_Name)
	@echo "The project has been built in release hardware mode."
	echo "Please sign the enclaves $(Enclave_Seal_Name) first with your signing key before you run the $(App_Name) to launch and access the enclaves."
	@echo "To sign the enclaves use the command:"
	@echo "   $(SGX_ENCLAVE_SIGNER) sign -key <your key> -enclave $(Enclave_Seal_Name) -out <$(Signed_Enclave_Seal_Name)> -config $(Enclave_Seal_Config_File)"
	@echo "You can also sign the enclave using an external signing tool."
	@echo "To build the project in simulation mode set SGX_MODE=SIM. To build the project in prerelease mode set SGX_PRERELEASE=1 and SGX_MODE=HW."
else
target: $(App_Name) $(Signed_Enclave_Seal_Name)
ifeq ($(Build_Mode), HW_DEBUG)
	@echo "The project has been built in debug hardware mode."
else ifeq ($(Build_Mode), SIM_DEBUG)
	@echo "The project has been built in debug simulation mode."
else ifeq ($(Build_Mode), HW_PRERELEASE)
	@echo "The project has been built in pre-release hardware mode."
else ifeq ($(Build_Mode), SIM_PRERELEASE)
	@echo "The project has been built in pre-release simulation mode."
else
	@echo "The project has been built in release simulation mode."
endif
endif

.config_$(Build_Mode)_$(SGX_ARCH):
	@rm -f .config_* $(App_Name) $(App_Objects) $(Enclave_Seal_Name) $(Signed_Enclave_Seal_Name)
	@rm -f $(Enclave_Objects_Files) App/Enclave_u.* Enclave/Enclave_t.*
	@touch .config_$(Build_Mode)_$(SGX_ARCH)


# App Objects 

$(Gen_Untrusted_Source_Seal): $(SGX_EDGER8R) Enclave/Enclave.edl
	@cd App && $(SGX_EDGER8R) --untrusted ../Enclave/Enclave.edl --search-path $(SGX_SDK)/include  --search-path $(SGX_SSL)/include
	@echo "GEN  =>  $@"

$(Gen_Untrusted_Object_Seal): $(Gen_Untrusted_Source_Seal)
	@$(CC) $(SGX_COMMON_CFLAGS) $(App_Compile_CFlags)  -c $< -o $@
	@echo "CC   <=  $<"

App/%.o: App/%.cpp
	@$(CXX) $(SGX_COMMON_CXXFLAGS) $(App_Compile_CXXFlags) -c $< -o $@
	@echo "CXX  <=  $<"

$(App_Objects): $(Gen_Untrusted_Source_Seal)

$(App_Name): $(App_Objects)
	@$(CXX) $(SGX_COMMON_CXXFLAGS) $^ -o $@ $(App_Link_Flags)
	@echo "LINK =>  $@"


# Enclave Seal Objects 

$(Gen_Trusted_Source_Seal): $(SGX_EDGER8R) Enclave/Enclave.edl
	@cd Enclave && $(SGX_EDGER8R) --trusted Enclave.edl --search-path $(SGX_SDK)/include --search-path $(SGX_SSL)/include
	@echo "GEN  =>  $@"

$(Gen_Trusted_Object_Seal): $(Gen_Trusted_Source_Seal)
	@$(CC) $(SGX_COMMON_CFLAGS) $(Enclave_Compile_CFlags) -c $< -o $@
	@echo "CC   <=  $<"

Enclave/%.o: Enclave/%.cpp
	@$(CXX) $(SGX_COMMON_CXXFLAGS) $(Enclave_Compile_CXXFlags) -c $< -o $@
	@echo "CXX  <=  $<"

$(Enclave_Seal_Objects): $(Gen_Trusted_Source_Seal) 

$(Enclave_Seal_Name): $(Enclave_Objects_Files)
	@$(CXX) $(SGX_COMMON_CXXFLAGS) $(Enclave_Objects_Files) -o $@ $(Enclave_Seal_Link_Flags)
	@echo "LINK =>  $@"

$(Signed_Enclave_Seal_Name): $(Enclave_Seal_Name)
ifeq ($(wildcard $(Enclave_Seal_Test_Key)),)
	@echo "There is no enclave test key<Enclave_private_test.pem>."
	@echo "The project will generate a key<Enclave_private_test.pem> for test."
	@openssl genrsa -out $(Enclave_Seal_Test_Key) -3 3072
endif
	@$(SGX_ENCLAVE_SIGNER) sign -key $(Enclave_Seal_Test_Key) -enclave $(Enclave_Seal_Name) -out $@ -config $(Enclave_Seal_Config_File)
	@echo "SIGN =>  $@"


# clean up

.PHONY: clean

clean:
	@rm -f .config_* $(App_Name) $(App_Objects) $(Enclave_Seal_Name) $(Signed_Enclave_Seal_Name)
	@rm -f $(Enclave_Objects_Files) App/Enclave_u.* Enclave/Enclave_t.* App/sgx_tsgxssl_u.* Enclave/sgx_tsgxssl_t.*
