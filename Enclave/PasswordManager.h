#ifndef PASS_H
#define PASS_H

#include <vector>
#include <set>
#include <string>
#include <map>

#include "Enclave_t.h"

static std::vector<std::string> userPasswords;
static std::set<std::string> breachedPasswords;
static std::map<std::string, bool> result_map;


void freeup_memory();



#endif
