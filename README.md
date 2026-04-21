# Calculus - Kubernetes SDK for GNU Octave

**Calculus** is a bridge that connects GNU Octave (a MATLAB-like programming language) to Kubernetes, allowing scientists and engineers to manage containerized computations directly from their Octave scripts.

Think of it as a remote control for Kubernetes, but instead of using `kubectl` commands in a terminal, you use simple Octave functions to create jobs, pods, namespaces, and configuration data in Kubernetes.

---

## What Problem Does This Solve?

Imagine you're a scientist working with Octave:
- You need to run **long-running calculations** on multiple machines
- You want to **scale computations horizontally** (use many computers in parallel)
- You'd prefer **not to learn Kubernetes deeply** or switch away from Octave
- You want to **run calculations in containers** but control them from your Octave scripts

**Calculus** lets you do all this by adding simple Octave functions like:
```octave
kJob('create', 'default', 'my-calc', 'python:3', 'python compute.py')
logs = kJob('stream', 'default', 'my-calc', '', '')
```

---

## Architecture Overview

The project is structured in three layers that work together:

```
┌────────────────────────────────────────────────────────────┐
│  Octave Scripts (MATLAB-like language)                     │
│  Users write: kJob('create', 'ns', 'name', 'img', 'cmd')   │
└────────────────┬───────────────────────────────────────────┘
                 │ Function calls
                 ▼
┌────────────────────────────────────────────────────────────┐
│  C++ Wrapper Files (.oct modules)                          │
│  Convert Octave types to C strings, call Go functions      │
│  Files: kJob.cpp, kPod.cpp, kConfigMap.cpp, kNamespace.cpp │
└────────────────┬───────────────────────────────────────────┘
                 │ C/C++ FFI (Foreign Function Interface)
                 ▼
┌────────────────────────────────────────────────────────────┐
│  Go Shared Library (libk8s.so)                             │
│  Core logic: Kubernetes API calls via client-go            │
│  Files: k8s/*.go (job.go, pod.go, etc.)                    │
└────────────────┬───────────────────────────────────────────┘
                 │ REST API over network
                 ▼
┌────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                        │
│  Manages containers, jobs, pods, namespaces                │
└────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
Calculus/
├── go/                      # Go source code
│   ├── main.go             # Exports functions for C FFI
│   ├── go.mod              # Go dependencies
│   └── internal/
│       ├── kube.go         # Creates Kubernetes client
│       └── helpers.go      # Utility functions (command parsing)
│   └── k8s/
│       ├── job.go          # Job management (create, delete, stream + ConfigMap mounts)
│       ├── pod.go          # Pod management (create, delete, stream + ConfigMap mounts)
│       ├── configmap.go    # ConfigMap management (create, update, delete)
│       └── namespace.go    # Namespace management (create, delete)
│
├── octave/src/             # C++ Octave bindings
│   ├── kJob.cpp           # Wraps Go's KJob function for Octave
│   ├── kPod.cpp           # Wraps Go's KPod function for Octave
│   ├── kConfigMap.cpp     # Wraps Go's KConfigMap function for Octave
│   └── kNamespace.cpp     # Wraps Go's KNamespace function for Octave
│
├── lib/                    # Generated shared library (created by build)
│   └── libk8s.so          # Go code compiled as a shared library
│
├── build/                  # Generated Octave modules (created by build)
│   ├── kJob.oct
│   ├── kPod.oct
│   ├── kConfigMap.oct
│   └── kNamespace.oct
│
├── examples/               # Example Octave scripts
│   ├── full_demo.m        # Complete end-to-end demo (all functions + ConfigMap mounts)
│   ├── quick_math.m       # Single math job examples
│   ├── k8s_demo.m         # Basic K8s feature walkthrough
│   ├── job_example.m      # Job lifecycle example
│   └── math_jobs.m        # Math computation examples via Jobs
│
├── Makefile               # Build instructions
└── README.md              # This file
```

---

## Quick Start

### Prerequisites

You need:
- **Go 1.26** - Download from [golang.org](https://golang.org)
- **GNU Octave 4.2+** - Install via `apt-get install octave` (Linux) or `brew install octave` (Mac)
- **Kubernetes cluster** - A running K8s cluster with `~/.kube/config` configured
- **mkoctfile** - Comes with Octave, compiles C++ to `.oct` modules

Check what you have:
```bash
go version
octave --version
kubectl version --client
which mkoctfile
```

### Building the Project

1. **Clone/download the project:**
```bash
cd /path/to/Calculus
```

2. **Install Go dependencies:**
```bash
cd go
go mod download
cd ..
```

3. **Build everything:**
```bash
make rebuild
```

This will:
1. Create `lib/` and `build/` directories if they don't exist
2. Compile Go code to `lib/libk8s.so` (a shared library)
3. Compile C++ files with Octave to `.oct` modules in `build/`
4. Test that Octave can find the functions

### Running an Example

1. **In a terminal, navigate to the project:**
```bash
cd /path/to/Calculus
```

2. **Start Octave with the build path:**
```bash
octave --path build/
```

3. **In Octave, run a simple example:**
```octave
result = kJob('create', 'default', 'test-job', 'python:3-slim', 'python -c "print(42)"')
disp(result)
```

4. **Check the job in Kubernetes (in another terminal):**
```bash
kubectl get jobs
kubectl logs job/test-job
```

---

## How The Three Parts Interact

### Example: Creating a Kubernetes Job

This is **what happens** when you call `kJob('create', 'default', 'calc1', 'python:3', 'python math.py')` from Octave:

#### Step 1: Octave Script
```octave
% You write this in Octave
result = kJob('create', 'default', 'calc1', 'python:3', 'python math.py')
```

#### Step 2: C++ Wrapper (kJob.cpp)
- Octave calls the `kJob` function defined in `octave/src/kJob.cpp`
- The C++ code:
  - Extracts the Octave string arguments: `.string_value()`
  - Converts them to C strings: `.c_str()`
  - Calls `KJob()` from the Go library
  - Receives a C string result back
  - Converts it back to an Octave value
  - Returns it to Octave

```cpp
// From kJob.cpp
char* result = KJob(
    const_cast<char*>(action.c_str()),      // "create"
    const_cast<char*>(_namespace.c_str()),  // "default"
    const_cast<char*>(name.c_str()),        // "calc1"
    const_cast<char*>(image.c_str()),       // "python:3"
    const_cast<char*>(command.c_str()),     // "python math.py"
    const_cast<char*>(configMaps.c_str())   // "" (empty = no mounts)
);
```

#### Step 3: Go Shared Library (main.go)
- The Go function `KJob()` receives C strings as parameters
- It converts them to Go strings using `C.GoString()`
- Calls the actual business logic in `k8s.Job()`
- Returns the result (or error message) as a C string

```go
// From main.go
func KJob(action *C.char, namespace *C.char, ...) *C.char {
    goAction := C.GoString(action)
    // ... convert other params ...
    result, err := k8s.Job(goAction, ...)
    return C.CString(result)
}
```

#### Step 4: Kubernetes Client (go/k8s/job.go)
- Uses `k8s.Job()` to execute the action
- Creates a `JobData` struct with the parameters
- Creates a Kubernetes client using `internal.NewClient()`
- Based on the action ("create", "delete", "stream"), calls different functions
- For "create": 
  - Parses the command string using `ParseCommand()` to handle quoted arguments
  - Creates a Kubernetes Job object (YAML-like structure)
  - Calls `clientset.BatchV1().Jobs(namespace).Create()` to submit it
  - Returns success message or error

```go
// Simplified from job.go
func Job(action, namespace, name, image, cmd, configMaps string) (string, error) {
    clientset, err := internal.NewClient()  // Connect to Kubernetes

    // configMaps is a comma-separated list, e.g. "scripts,dataset"
    // Each ConfigMap is mounted at /data/<name> inside the container
    data := JobData{
        Name: name, Namespace: namespace,
        Image: image, Cmd: cmd,
        ConfigMaps: parseConfigMaps(configMaps), // nil when empty
    }

    actionMap := map[string]actionFn{
        "create": createJob,
        "delete": deleteJob,
        "stream": streamJob,
    }
    return actionMap[action](clientset, data)
}
```

#### Step 5: Kubernetes API
- The Kubernetes cluster receives the Job definition
- Creates containers according to the specification
- Executes the command in the container
- Stores logs and results

#### Step 6: Return to Octave
- Go returns a success message (or error) as C string
- C++ receives it and converts back to Octave string
- Octave shows the result to you:
```
result = "Job 'calc1' created successfully in namespace 'default'"
```

---

## Available Functions

Once built, you have four main functions in Octave:

### 1. **kJob** - Manage Kubernetes Jobs
```octave
result = kJob(action, namespace, name, image, command)
result = kJob(action, namespace, name, image, command, configmaps)  % optional 6th arg

% Parameters:
%   action     - 'create', 'delete', or 'stream'
%   namespace  - Kubernetes namespace (e.g., 'default')
%   name       - Name for the job
%   image      - Container image (e.g., 'python:3-slim', 'ubuntu:22.04')
%   command    - Command to run (e.g., 'python script.py')
%   configmaps - (optional) Comma-separated ConfigMap names to mount under /data/<name>

% Examples:
result = kJob('create', 'default', 'my-job', 'python:3', 'python -c "print(42)"')
result = kJob('create', 'default', 'my-job', 'python:3', 'python /data/my-scripts/run.py', 'my-scripts')
result = kJob('create', 'default', 'my-job', 'python:3', 'cat /data/cfg-a/f.txt', 'cfg-a,cfg-b')
logs   = kJob('stream', 'default', 'my-job', '', '')
result = kJob('delete', 'default', 'my-job', '', '')
```

**What it does:**
- **create**: Submits a new Kubernetes Job and starts a container. If `configmaps` is provided, each ConfigMap is mounted as a read-only volume at `/data/<configmap-name>`.
- **stream**: Reads and returns the job's output logs.
- **delete**: Removes the job and its associated pods.

### 2. **kPod** - Manage Kubernetes Pods
```octave
result = kPod(action, namespace, name, image, command)
result = kPod(action, namespace, name, image, command, configmaps)  % optional 6th arg

% Parameters:
%   action     - 'create', 'delete', or 'stream'
%   namespace  - Kubernetes namespace (e.g., 'default')
%   name       - Pod name
%   image      - Container image
%   command    - Command to execute
%   configmaps - (optional) Comma-separated ConfigMap names to mount under /data/<name>

% Examples:
result = kPod('create', 'default', 'my-pod', 'ubuntu:22.04', 'echo hello')
result = kPod('create', 'default', 'my-pod', 'python:3-slim', 'python /data/scripts/run.py', 'scripts')
logs   = kPod('stream', 'default', 'my-pod', '', '')
result = kPod('delete', 'default', 'my-pod', '', '')
```

**What it does:**
- **create**: Creates a single Kubernetes Pod. If `configmaps` is provided, each ConfigMap is mounted at `/data/<configmap-name>`.
- **stream**: Reads and returns the pod's output logs.
- **delete**: Removes the pod.

### 3. **kConfigMap** - Manage Configuration Data
```octave
result = kConfigMap(action, name, namespace, key, value)

% Parameters:
%   action    - 'create', 'update', or 'delete'
%   name      - ConfigMap name
%   namespace - Kubernetes namespace (use '' for default)
%   key       - Data key (file name or config key)
%   value     - Data value (file contents or config value)

% Examples:
result = kConfigMap('create', 'app-config', 'default', 'script.py', 'print("hello")')
result = kConfigMap('update', 'app-config', 'default', 'script.py', 'print("updated")')
result = kConfigMap('delete', 'app-config', 'default', '', '')
```

**What it does:**
- **create**: Creates a new ConfigMap with the given key/value pair. Pods and jobs can mount it as a file under `/data/<name>/<key>`.
- **update**: Fetches an existing ConfigMap and adds or overwrites the specified key.
- **delete**: Removes the ConfigMap entirely.

### 4. **kNamespace** - Manage Kubernetes Namespaces
```octave
result = kNamespace(action, name)

% Parameters:
%   action - 'create' or 'delete'
%   name   - Namespace name

% Examples:
result = kNamespace('create', 'my-project')
result = kNamespace('delete', 'my-project')
```

**What it does:**
- Creates or deletes isolated environments in Kubernetes.
- Namespaces separate resources for different projects or teams.
- All other functions accept a `namespace` parameter that should match a created namespace.

---

## Development Guide

### Building

```bash
# Full rebuild (clean + build + test)
make rebuild

# Build only Go library
make gosdk

# Build only Octave modules
make octmod

# Run tests
make test

# Clean build artifacts
make clean
```

### Understanding the Build Process

The **Makefile** orchestrates the build:

1. **Go Compilation (→ libk8s.so)**
   ```bash
   cd go && go build -buildmode=c-shared -o ../lib/libk8s.so main.go
   ```
   - `-buildmode=c-shared`: Compiles Go as a shared library (.so file)
   - This library can be called from C/C++

2. **Octave Module Compilation (→ .oct files)**
   ```bash
   mkoctfile kJob.cpp -L./lib -lk8s -Wl,-rpath,$(CURDIR)/lib -o build/kJob.oct
   ```
   - `mkoctfile`: Compiles C++ code into Octave-compatible modules
   - `-L./lib`: Tells compiler where to find the Go library
   - `-lk8s`: Links against libk8s.so
   - `-Wl,-rpath,...`: Embeds path to library for runtime loading

### Modifying the Code

#### Add a New Kubernetes Feature

1. **Implement in Go** (`go/k8s/newfeature.go`):
```go
package k8s

func NewFeature(param1 string) (string, error) {
    clientset, err := internal.NewClient()
    if err != nil {
        return "", err
    }
    // Use clientset to interact with Kubernetes
    return "Success", nil
}
```

2. **Export from main.go**:
```go
//export KNewFeature
func KNewFeature(param1 *C.char) *C.char {
    goParam := C.GoString(param1)
    result, err := k8s.NewFeature(goParam)
    if err != nil {
        return C.CString(err.Error())
    }
    return C.CString(result)
}
```

3. **Create C++ wrapper** (`octave/src/kNewFeature.cpp`):
```cpp
#include <octave/oct.h>

extern "C" {
    char* KNewFeature(char* param1);
}

DEFUN_DLD (kNewFeature, args, nargout, "New feature description")
{
    if (args.length() != 1) {
        error("kNewFeature requires 1 argument");
        return octave_value();
    }
    
    std::string param1 = args(0).string_value();
    char* result = KNewFeature(const_cast<char*>(param1.c_str()));
    
    std::string output(result);
    free(result);
    return octave_value(output);
}
```

4. **Update Makefile**:
```makefile
octmod: $(BUILD_DIR)/kNewFeature.oct

$(BUILD_DIR)/kNewFeature.oct: $(OCTAVE_SRC_DIR)/kNewFeature.cpp
	@echo "==> Building kNewFeature.oct"
	mkoctfile $< \
		-L$(CURDIR)/$(LIB_DIR) -lk8s \
		-Wl,-rpath,$(CURDIR)/$(LIB_DIR) \
		-o $@
```

5. **Rebuild**:
```bash
make rebuild
```

### Debugging

**Problem: Octave can't find functions after rebuilding**
```bash
# Make sure the build/ directory has the .oct files
ls -la build/

# Test explicitly
octave --path build/ --eval "kJob('create', 'default', 'test', 'ubuntu', 'echo hi')"
```

**Problem: "libk8s.so not found" when running**
```bash
# Check if library path in .oct file is correct
ldd build/kJob.oct | grep libk8s

# Rebuild with correct rpath
make clean
make rebuild
```

**Problem: Go code not compiling**
```bash
cd go
go mod tidy       # Update dependencies
go build -buildmode=c-shared -o ../lib/libk8s.so main.go
cd ..
```

---

## Examples

### Example 1: Simple Math Calculation

Run a Python script to calculate factorial:

```octave
% example1_factorial.m
addpath('build');

% Create and run a job
result = kJob('create', 'default', 'factorial-job', 'python:3-slim', ...
              'python -c "import math; print(math.factorial(20))"');
disp(result);

% Wait for completion
pause(5);

% Stream the output
output = kJob('stream', 'default', 'factorial-job', '', '');
disp('Result:');
disp(output);

% Clean up
kJob('delete', 'default', 'factorial-job', '', '');
```

### Example 2: Multiple Parallel Jobs

Run calculations in parallel using a loop:

```octave
% example2_parallel.m
addpath('build');

% Create namespace for this experiment
kNamespace('create', 'math-jobs');

% Run 5 calculations in parallel
for i = 1:5
    job_name = sprintf('fibonacci-job-%d', i);
    fib_n = i * 5;
    command = sprintf('python -c "a,b=0,1; [print(a) or (a,b:=(b,a+b)) for _ in range(%d)]"', fib_n);
    
    result = kJob('create', 'math-jobs', job_name, 'python:3-slim', command);
    disp(['Created: ', job_name]);
end

% All jobs running in parallel now!
% Check status in terminal: kubectl get jobs -n math-jobs

% Clean up
pause(10);
for i = 1:5
    job_name = sprintf('fibonacci-job-%d', i);
    kJob('delete', 'math-jobs', job_name, '', '');
end
kNamespace('delete', 'math-jobs');
```

### Example 3: Using ConfigMap for Configuration

Mount a ConfigMap into a pod as a file under `/data`:

```octave
% example3_configmap.m
addpath('build');

% Create a namespace
kNamespace('create', 'config-demo');

% Store a Python script inside a ConfigMap
kConfigMap('create', 'my-script', 'config-demo', 'run.py', ...
    'print("precision=100, algorithm=monte-carlo")');

% Create a pod that mounts the ConfigMap and runs the script
result = kPod('create', 'config-demo', 'config-reader', 'python:3-slim', ...
    'python /data/my-script/run.py', 'my-script');
disp(result);

% Stream logs after pod completes
pause(15);
logs = kPod('stream', 'config-demo', 'config-reader', '', '');
disp(logs);

% Clean up
kPod('delete', 'config-demo', 'config-reader', '', '');
kConfigMap('delete', 'my-script', 'config-demo', '', '');
kNamespace('delete', 'config-demo');
```

---

## Troubleshooting

### "kJob: undefined" error in Octave

**Cause**: Octave can't find the module

**Solution**:
```octave
addpath('build');  % Add build directory to path
kJob('create', ...)
```

### Connection refused to Kubernetes

**Cause**: No Kubernetes cluster running or config not set up

**Solution**:
```bash
# Check kubeconfig exists and is valid
cat ~/.kube/config
kubectl cluster-info
```

### Build fails with compiler errors

**Solution**:
```bash
# Make sure you have the required tools
apt-get install build-essential           # Linux
brew install gcc                          # Mac

# Check Octave is properly installed
octave --version
which mkoctfile

# Clean and rebuild
make clean
make rebuild
```

### "libk8s.so" not found at runtime

**Cause**: rpath not set correctly

**Solution**: Check the Makefile has `$(CURDIR)` for absolute paths:
```makefile
-Wl,-rpath,$(CURDIR)/$(LIB_DIR)  # Correct
-Wl,-rpath,$(LIB_DIR)            # Wrong - relative path
```

### Known Issues with kPod

This section is no longer applicable. `kPod` now supports **create**, **delete**, and **stream** actions, accepts an optional sixth argument for ConfigMap mounts, and works in any namespace — just like `kJob`.

---

## Conceptual Overview

### What is Kubernetes?

Kubernetes is a system for running and managing containerized applications:

- **Container**: A lightweight, isolated environment with your application
- **Pod**: The smallest unit in Kubernetes, contains one or more containers
- **Job**: A "task" that runs to completion (like a batch job)
- **ConfigMap**: Stores configuration data that pods can access
- **Namespace**: An organizational unit that isolates resources

### What is Octave?

GNU Octave is a free, open-source alternative to MATLAB:

- MATLAB-like syntax for mathematical computing
- Scientific calculations and data analysis
- Matrix operations and numerical methods
- Scripts (`.m` files) that can call external functions

### What is Go?

Go is a programming language designed for:

- Building efficient system software
- Calling C/C++ libraries easily (via cgo)
- Excellent Kubernetes support (has official client-go library)

### Why This Architecture?

```
┌─────────────────────────────┐
│ Why not do it all in Go?    │
│                             │
│ → Scientists use Octave/    │
│   MATLAB for calculations   │
│ → Hard to add K8s support   │
│   directly to Octave        │
│ → This bridge lets both     │
│   worlds talk!              │
└─────────────────────────────┘
```

The C++ layer acts as a **bridge** that:
- Translates Octave types to C/C++ types
- Calls Go functions from C/C++
- Translates results back to Octave

This is the "FFI" (Foreign Function Interface) - the way different languages communicate.

---

## Next Steps

1. **Try the examples**:
   ```bash
   octave --path build/ examples/quick_math.m
   octave --path build/ examples/full_demo.m
   octave --path build/ examples/k8s_demo.m
   ```

2. **Read the code**:
   - Start with `go/main.go` to understand the export interface
   - Look at `go/k8s/job.go` to see Kubernetes usage
   - Check `octave/src/kJob.cpp` to see the C++ wrapper pattern

3. **Create your own script**:
   - Use the functions to submit calculations to your cluster
   - Monitor progress with `kubectl get jobs` and `kubectl logs`

4. **Extend the SDK**:
   - Add more Kubernetes resources (Deployments, Services, etc.)
   - Add more K8s operations (describe, list, watch, patch)
   - Improve error handling and information returned

---

## Key Files Reference

| File | Purpose |
|------|---------|
| [Makefile](Makefile) | Build instructions |
| [go/main.go](go/main.go) | Exports Go functions for C/FFI |
| [go/k8s/job.go](go/k8s/job.go) | Kubernetes Job management (create/delete/stream + ConfigMap mounts) |
| [go/k8s/pod.go](go/k8s/pod.go) | Kubernetes Pod management (create/delete/stream + ConfigMap mounts) |
| [go/k8s/configmap.go](go/k8s/configmap.go) | ConfigMap management (create/update/delete) |
| [go/k8s/namespace.go](go/k8s/namespace.go) | Namespace management (create/delete) |
| [go/internal/kube.go](go/internal/kube.go) | Kubernetes client setup |
| [octave/src/kJob.cpp](octave/src/kJob.cpp) | Octave interface for Jobs |
| [octave/src/kPod.cpp](octave/src/kPod.cpp) | Octave interface for Pods |
| [octave/src/kConfigMap.cpp](octave/src/kConfigMap.cpp) | Octave interface for ConfigMaps |
| [octave/src/kNamespace.cpp](octave/src/kNamespace.cpp) | Octave interface for Namespaces |
| [lib/libk8s.h](lib/libk8s.h) | Generated C header (do not edit) |
| [examples/full_demo.m](examples/full_demo.m) | Complete end-to-end demo of all functions |
| [examples/k8s_demo.m](examples/k8s_demo.m) | Basic K8s feature demo |
| [examples/math_jobs.m](examples/math_jobs.m) | Math computation examples via Jobs |
| [examples/quick_math.m](examples/quick_math.m) | Single-job quick math examples |
| [examples/job_example.m](examples/job_example.m) | Job lifecycle example |

---

## License

[Add your license information here]

## FAQ

**Q: Can I use this with MATLAB?**
A: Not directly. MATLAB and Octave have different calling conventions. You'd need to rewrite the Octave `.oct` files as MATLAB MEX files.

**Q: Does this work without a Kubernetes cluster?**
A: No, you need a real Kubernetes cluster or a local one (like Minikube or Docker Desktop's K8s).

**Q: Can I run Calculus outside the project directory?**
A: Yes, but you need to add the absolute path: `addpath('/full/path/to/Calculus/build')` in Octave.

**Q: How does the library path work via rpath?**
A: The `rpath` (runtime library path) embeds the location of `libk8s.so` into the `.oct` files. This way, Octave knows where to find the library when loading the module.

**Q: What if Kubernetes credentials are in a non-standard location?**
A: The Go code uses the default kubeconfig path (`~/.kube/config`). To use a different config, edit `go/internal/kube.go`.

---

**Note:** The current implementation has known limitations, particularly with the `kPod` function.

---
