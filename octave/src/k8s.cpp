#include <octave/oct.h>
#include <cstdlib>

extern "C" {
    char* KJob(char* name, char* image, char* command);
    char* KPod(char* name, char* image, char* command);
}

/*
 * kJob(name, image, command)
 */
DEFUN_DLD (kJob, args, nargout, "Create a Kubernetes Job")
{
    if (args.length() != 3) {
        error("kJob requires 3 arguments: name, image, command");
    }

    std::string name = args(0).string_value();
    std::string image = args(1).string_value();
    std::string command = args(2).string_value();

    char* result = KJob(
        const_cast<char*>(name.c_str()),
        const_cast<char*>(image.c_str()),
        const_cast<char*>(command.c_str())
    );

    std::string output(result);
    free(result); // Free the memory allocated by CGo
    return octave_value(output);
}

/*
 * kPod(name, image, command)
 */
DEFUN_DLD (kPod, args, nargout, "Create a Kubernetes Pod")
{
    if (args.length() != 3) {
        error("kPod requires 3 arguments: name, image, command");
    }

    std::string name = args(0).string_value();
    std::string image = args(1).string_value();
    std::string command = args(2).string_value();

    char* result = KPod(
        const_cast<char*>(name.c_str()),
        const_cast<char*>(image.c_str()),
        const_cast<char*>(command.c_str())
    );

    std::string output(result);
    free(result); // Free the memory allocated by CGo
    return octave_value(output);
}