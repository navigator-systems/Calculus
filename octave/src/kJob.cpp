#include <octave/oct.h>
#include <cstdlib>

extern "C" {
    char* KJob(char* action, char* _namespace, char* name, char* image, char* command, char* configMaps);
}

DEFUN_DLD (kJob, args, nargout, "Manage a Kubernetes Job\n\
Usage: kJob(action, namespace, name, image, command [, configmaps])\n\
  action     - 'create', 'delete', or 'stream'\n\
  namespace  - Kubernetes namespace (use '' for default)\n\
  name       - Job name\n\
  image      - Container image\n\
  command    - Command to run\n\
  configmaps - (optional) Comma-separated ConfigMap names to mount under /data/<name>")
{
    if (args.length() < 5 || args.length() > 6) {
        error("kJob requires 5 or 6 arguments: action, namespace, name, image, command [, configmaps]");
        return octave_value();
    }

    std::string action = args(0).string_value();
    std::string _namespace = args(1).string_value();
    std::string name = args(2).string_value();
    std::string image = args(3).string_value();
    std::string command = args(4).string_value();
    std::string configMaps = (args.length() == 6) ? args(5).string_value() : "";

    char* result = KJob(
        const_cast<char*>(action.c_str()),
        const_cast<char*>(_namespace.c_str()),
        const_cast<char*>(name.c_str()),
        const_cast<char*>(image.c_str()),
        const_cast<char*>(command.c_str()),
        const_cast<char*>(configMaps.c_str())
    );

    std::string output(result);
    free(result);
    return octave_value(output);
}
