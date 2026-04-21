%% k8s_demo.m - Complete demo of Calculus K8s bindings for Octave
%
% Covers the basic usage of every available function:
%   kNamespace(action, name)
%     action - 'create' | 'delete'
%
%   kConfigMap(action, name, namespace, key, value)
%     action - 'create' | 'update' | 'delete'
%
%   kJob(action, namespace, name, image, command [, configmaps])
%     action    - 'create' | 'delete' | 'stream'
%     configmaps- (optional) comma-separated ConfigMap names
%
%   kPod(action, namespace, name, image, command [, configmaps])
%     action    - 'create' | 'delete' | 'stream'
%     configmaps- (optional) comma-separated ConfigMap names
%
% For a full end-to-end demo that exercises ConfigMap mounts and
% multi-ConfigMap workloads, see full_demo.m.

%% Setup - Add build path
addpath('../build');

%% Configuration
ns = 'calculus-demo';
job_name = 'compute-pi';
image = 'perl:latest';

%% 1. Create a namespace for our demo
disp('=== Creating Namespace ===');
result = kNamespace('create', ns);
disp(result);

%% 2. Create a ConfigMap with some data
disp('');
disp('=== Creating ConfigMap ===');
result = kConfigMap('create', 'app-config', ns, 'greeting', 'Hello from Octave!');
disp(result);

%% 3. Create a Job that computes pi
disp('');
disp('=== Creating Job ===');
pi_command = 'perl -Mbignum=bpi -wle "print bpi(100)"';
result = kJob('create', ns, job_name, image, pi_command);
disp(result);

%% 4. Show instructions for checking the job
disp('');
disp('=== Check your job with: ===');
disp(['  kubectl get jobs -n ', ns]);
disp(['  kubectl logs job/', job_name, ' -n ', ns]);

%% 5. Wait and stream job logs
disp('');
disp('=== Waiting for job to complete (10s)... ===');
pause(10);

disp('');
disp('=== Streaming Job Logs ===');
logs = kJob('stream', ns, job_name, '', '');
disp(logs);

%% Cleanup prompt
disp('');
input('Press Enter to clean up resources...', 's');

%% 6. Delete the job and remaining resources
disp('');
disp('=== Deleting Job ===');
result = kJob('delete', ns, job_name, '', '');
disp(result);

disp('');
disp('=== Deleting ConfigMap ===');
result = kConfigMap('delete', 'app-config', ns, '', '');
disp(result);

disp('');
disp('=== Deleting Namespace ===');
result = kNamespace('delete', ns);
disp(result);

disp('');
disp('Demo complete!');
