%% full_demo.m - Full end-to-end demo of all Calculus K8s bindings
%
% Demonstrates the complete lifecycle of Kubernetes resources:
%   1.  Create a dedicated namespace
%   2.  Create ConfigMap with a Python script
%   2b. Create two extra ConfigMaps (plain text files) for multi-CM demo
%   3.  Create a Job  that mounts the script ConfigMap
%   4.  Create a Pod  that mounts the script ConfigMap
%   5.  Create a plain Job  (no ConfigMap)
%   6.  Create a plain Pod  (no ConfigMap)
%   6b. Create a Job  that mounts both extra ConfigMaps and cats them
%   6c. Create a Pod  that mounts both extra ConfigMaps and cats them
%   6d. Update ConfigMap demo-file-a, then create a Job to verify the new content
%   7.  Stream logs from all workloads
%   8.  Delete everything one by one (jobs, pods, configmaps, namespace)

%% -----------------------------------------------------------------
%% Setup
%% -----------------------------------------------------------------
addpath('../build');

ns         = 'calculus-full-demo';
image      = 'python:3-slim';
cm_name    = 'demo-script';

% Job / Pod names
job_cm     = 'job-with-cm';
pod_cm     = 'pod-with-cm';
job_plain  = 'job-plain';
pod_plain  = 'pod-plain';
job_multi  = 'job-multi-cm';
pod_multi  = 'pod-multi-cm';

% Two extra ConfigMaps (plain text files) used by the multi-CM workloads
cm_a_name    = 'demo-file-a';
cm_b_name    = 'demo-file-b';
cm_a_data    = 'This is file A, served from ConfigMap demo-file-a.';
cm_b_data    = 'This is file B, served from ConfigMap demo-file-b.';
cm_a_updated = 'File A has been UPDATED - this is the new content!';

job_updated  = 'job-updated-cm';

% Command: cat both mounted files in one shot (sh is available in python:3-slim)
cmd_multi  = ['sh -c "cat /data/', cm_a_name, '/file.txt && echo && cat /data/', cm_b_name, '/file.txt"'];

% The Python script that will be stored inside the ConfigMap.
% It prints a short message together with the hostname so we can
% tell the pod/job apart in the logs.
script_content = strjoin({
    'import socket, datetime'
    'host = socket.gethostname()'
    'now  = datetime.datetime.utcnow().isoformat()'
    'print(f"[{now}] Hello from ConfigMap script, running on {host}")'
}, '\n');

% Command for workloads that use the ConfigMap
cmd_with_cm  = ['python /data/', cm_name, '/script.py'];

% Command for plain workloads (inline one-liner)
cmd_plain = 'python -c "import math; print(math.e)"';
%% -----------------------------------------------------------------
%% 1. Create Namespace
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  1. Creating Namespace');
disp('================================================================');
result = kNamespace('create', ns);
disp(['  -> ', result]);

pause;

%% -----------------------------------------------------------------
%% 2. Create ConfigMap  (key=script.py, value=the Python script)
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  2. Creating ConfigMap');
disp('================================================================');
result = kConfigMap('create', cm_name, ns, 'script.py', script_content);
disp(['  -> ', result]);

pause;

%% -----------------------------------------------------------------
%% 2b. Create two extra ConfigMaps for the multi-CM demo
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  2b. Creating extra ConfigMaps (file-a and file-b)');
disp('================================================================');
result = kConfigMap('create', cm_a_name, ns, 'file.txt', cm_a_data);
disp(['  -> ', result]);
result = kConfigMap('create', cm_b_name, ns, 'file.txt', cm_b_data);
disp(['  -> ', result]);

pause;

%% -----------------------------------------------------------------
%% 3. Create Job that uses the ConfigMap
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  3. Creating Job with ConfigMap mount');
disp('================================================================');
result = kJob('create', ns, job_cm, image, cmd_with_cm, cm_name);
disp(['  -> ', result]);

pause;
%% -----------------------------------------------------------------
%% 4. Create Pod that uses the ConfigMap
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  4. Creating Pod with ConfigMap mount');
disp('================================================================');
result = kPod('create', ns, pod_cm, image, cmd_with_cm, cm_name);
disp(['  -> ', result]);

pause;
%% -----------------------------------------------------------------
%% 5. Create plain Job (no ConfigMap)
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  5. Creating plain Job (no ConfigMap)');
disp('================================================================');
result = kJob('create', ns, job_plain, image, cmd_plain);
disp(['  -> ', result]);
pause;
%% -----------------------------------------------------------------
%% 6. Create plain Pod (no ConfigMap)
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  6. Creating plain Pod (no ConfigMap)');
disp('================================================================');
result = kPod('create', ns, pod_plain, image, cmd_plain);
disp(['  -> ', result]);
pause;

%% -----------------------------------------------------------------
%% 6b. Create Job with multiple ConfigMaps (cats both files)
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  6b. Creating Job with multiple ConfigMaps');
disp('================================================================');
result = kJob('create', ns, job_multi, image, cmd_multi, [cm_a_name, ',', cm_b_name]);
disp(['  -> ', result]);
pause;

%% -----------------------------------------------------------------
%% 6c. Create Pod with multiple ConfigMaps (cats both files)
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  6c. Creating Pod with multiple ConfigMaps');
disp('================================================================');
result = kPod('create', ns, pod_multi, image, cmd_multi, [cm_a_name, ',', cm_b_name]);
disp(['  -> ', result]);
pause;

%% -----------------------------------------------------------------
%% 6d. Update ConfigMap demo-file-a and run a job with the new content
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  6d. Updating ConfigMap demo-file-a');
disp('================================================================');
result = kConfigMap('update', cm_a_name, ns, 'file.txt', cm_a_updated);
disp(['  -> ', result]);
pause;

disp('');
disp('================================================================');
disp('  6d. Creating Job with updated ConfigMap');
disp('================================================================');
cmd_cat_a = ['sh -c "cat /data/', cm_a_name, '/file.txt"'];
result = kJob('create', ns, job_updated, image, cmd_cat_a, cm_a_name);
disp(['  -> ', result]);
pause;

%% -----------------------------------------------------------------
%% 7. Wait and stream logs from all workloads
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  7. Waiting 20s for workloads to complete...');
disp('================================================================');
pause;

disp('');
disp('--- Logs: Job with ConfigMap ---');
logs = kJob('stream', ns, job_cm, '', '');
disp(logs);

pause;
disp('--- Logs: Pod with ConfigMap ---');
logs = kPod('stream', ns, pod_cm, '', '');
disp(logs);
pause;
disp('--- Logs: Plain Job ---');
logs = kJob('stream', ns, job_plain, '', '');
disp(logs);

pause;

disp('--- Logs: Plain Pod ---');
logs = kPod('stream', ns, pod_plain, '', '');
disp(logs);

pause;
disp('--- Logs: Job with multiple ConfigMaps ---');
logs = kJob('stream', ns, job_multi, '', '');
disp(logs);

pause;
disp('--- Logs: Pod with multiple ConfigMaps ---');
logs = kPod('stream', ns, pod_multi, '', '');
disp(logs);

pause;
disp('--- Logs: Job with updated ConfigMap ---');
logs = kJob('stream', ns, job_updated, '', '');
disp(logs);

%% -----------------------------------------------------------------
%% 8. Cleanup - delete everything one by one
%% -----------------------------------------------------------------
disp('');
disp('================================================================');
disp('  8. Cleanup');
disp('================================================================');

disp('  Deleting Job with ConfigMap...');
result = kJob('delete', ns, job_cm, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting Pod with ConfigMap...');
result = kPod('delete', ns, pod_cm, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting plain Job...');
result = kJob('delete', ns, job_plain, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting plain Pod...');
result = kPod('delete', ns, pod_plain, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting Job with multiple ConfigMaps...');
result = kJob('delete', ns, job_multi, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting Pod with multiple ConfigMaps...');
result = kPod('delete', ns, pod_multi, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting Job with updated ConfigMap...');
result = kJob('delete', ns, job_updated, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting ConfigMap (script)...');
result = kConfigMap('delete', cm_name, ns, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting ConfigMap (file-a)...');
result = kConfigMap('delete', cm_a_name, ns, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting ConfigMap (file-b)...');
result = kConfigMap('delete', cm_b_name, ns, '', '');
disp(['  -> ', result]);
pause;
disp('  Deleting Namespace...');
result = kNamespace('delete', ns);
disp(['  -> ', result]);
pause;
disp('');
disp('================================================================');
disp('  Demo complete!');
disp('================================================================');
