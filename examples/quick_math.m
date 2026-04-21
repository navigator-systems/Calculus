%% quick_math.m - Quick single-job math examples
%
% Uncomment one of the blocks below to run that particular calculation
% as a Kubernetes Job. The job is created, its output is streamed, and
% it is deleted automatically.
%
% Functions used:
%   kJob(action, namespace, name, image, command)
%     action    - 'create' | 'delete' | 'stream'
%     namespace - target namespace ('default' here)
%     name      - unique job name
%     image     - container image
%     command   - shell command to execute
%
% No ConfigMaps are used in this script. All computations are
% expressed as inline commands passed directly to the container.

addpath('../build');
ns = 'default';

%% Choose one example by uncommenting:

%% --- Euler's number (e) ---
job_name = 'euler';
image = 'python:3-slim';
command = 'python -c "import math; print(math.e)"';

%% --- Pi with 50 decimals ---
% job_name = 'pi-calc';
% image = 'python:3-slim';
% command = 'python -c "from decimal import Decimal, getcontext; getcontext().prec=55; print(Decimal(1).exp() - Decimal(1).exp() + Decimal(\"3.14159265358979323846264338327950288419716939937510\"))"';

%% --- Fibonacci ---
% job_name = 'fib';
% image = 'busybox:latest';
% command = 'sh -c "a=0; b=1; for i in 1 2 3 4 5 6 7 8 9 10; do echo -n \"$a \"; t=$((a+b)); a=$b; b=$t; done"';

%% --- Factorial of 10 ---
% job_name = 'factorial';
% image = 'python:3-slim';
% command = 'python -c "import math; print(f\"10! = {math.factorial(10)}\")"';

%% --- Golden ratio ---
% job_name = 'golden';
% image = 'python:3-slim';
% command = 'python -c "import math; phi=(1+math.sqrt(5))/2; print(f\"Golden ratio: {phi}\")"';

%% --- 2x2 Matrix determinant ---
% job_name = 'matrix-det';
% image = 'python:3-slim';
% command = 'python -c "A=[[3,8],[4,6]]; det=A[0][0]*A[1][1]-A[0][1]*A[1][0]; print(f\"det([[3,8],[4,6]]) = {det}\")"';

%% Run the job
disp(['Creating job: ', job_name]);
disp(['Image: ', image]);
disp(['Command: ', command]);
disp('');

result = kJob('create', ns, job_name, image, command);
disp(['Result: ', result]);

disp('');
disp('Waiting 15 seconds for job to complete...');
pause(15);

disp('');
disp('=== Output ===');
logs = kJob('stream', ns, job_name, '', '');
disp(logs);

disp('');
disp('Cleaning up...');
kJob('delete', ns, job_name, '', '');
disp('Done!');
