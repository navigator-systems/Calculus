#include <octave/oct.h>
#include <cstdlib>

extern "C" {
    char* KNamespace(char* action, char* name);
    
}

DEFUN_DLD (kNamespace, args, nargout, "Create a Kubernetes Namespace\n\
Usage: kNamespace(action, name)\n\
  action - Action to perform (create/delete)\n\
  name - Namespace name")
{
    if (args.length() != 2) {
        error("kNamespace requires 2 arguments: action and name");
        return octave_value();
    }

    std::string action = args(0).string_value();
    std::string name = args(1).string_value();

    char* result = KNamespace(
        const_cast<char*>(action.c_str()),
        const_cast<char*>(name.c_str())
    );

    std::string output(result);
    free(result);
    return octave_value(output);
}
