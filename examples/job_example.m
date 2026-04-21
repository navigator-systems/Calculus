%% job_example.m - Basic Kubernetes Job lifecycle example
%
% Demonstrates the three-step pattern for running a job:
%   1. Create the job
%   2. Wait and stream its logs
%   3. Delete the job
%
% Functions used:
%   kJob(action, namespace, name, image, command [, configmaps])
%     action    - 'create' | 'delete' | 'stream'
%     namespace - target namespace
%     name      - unique job name
%     image     - container image
%     command   - shell command to execute
%     configmaps- (optional) comma-separated ConfigMap names to mount at /data/<name>
%
% Prerequisites:
%   - Run 'make rebuild' in the project root to build the octave bindings
%   - Have a valid kubeconfig configured (~/.kube/config)

%% Add the build directory to the path
addpath('../build');

%% Define Job parameters
namespace = 'default';
job_name = 'octave-hello-world';
image = 'busybox:latest';
command = 'echo Hello';

%% Create the Job
disp('Creating Kubernetes Job...');
disp(['  Namespace: ', namespace]);
disp(['  Job Name:  ', job_name]);
disp(['  Image:     ', image]);
disp(['  Command:   ', command]);

result = kJob('create', namespace, job_name, image, command);
disp(['Result: ', result]);

%% Wait for job to complete and get logs
disp('');
disp('Waiting 5 seconds for job to complete...');
pause(5);

disp('');
disp('Fetching job logs...');
logs = kJob('stream', namespace, job_name, '', '');
disp('=== Job Logs ===');
disp(logs);
disp('================');

%% Wait and then delete the job (optional)
disp('');
disp('Press any key to delete the job...');
pause;

result = kJob('delete', namespace, job_name, image, command);
disp(['Delete Result: ', result]);

disp('Done!');
