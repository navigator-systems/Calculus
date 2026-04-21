#include <octave/oct.h>
#include <cstdlib>

extern "C" {
    char* KConfigMap(char* action, char* name, char* ns, char* key, char* value);
}

DEFUN_DLD (kConfigMap, args, nargout, "Manage a Kubernetes ConfigMap\n\
Usage: kConfigMap(action, name, namespace, key, value)\n\
  action    - Action to perform: 'create', 'update', or 'delete'\n\
  name      - ConfigMap name\n\
  namespace - Kubernetes namespace (use '' for default)\n\
  key       - Data key (used by create and update)\n\
  value     - Data value (used by create and update)")
{
    if (args.length() != 5) {
        error("kConfigMap requires 5 arguments: action, name, namespace, key, value");
        return octave_value();
    }

    std::string action = args(0).string_value();
    std::string name = args(1).string_value();
    std::string ns = args(2).string_value();
    std::string key = args(3).string_value();
    std::string value = args(4).string_value();

    char* result = KConfigMap(
        const_cast<char*>(action.c_str()),
        const_cast<char*>(name.c_str()),
        const_cast<char*>(ns.c_str()),
        const_cast<char*>(key.c_str()),
        const_cast<char*>(value.c_str())
    );

    std::string output(result);
    free(result);
    return octave_value(output);
}
