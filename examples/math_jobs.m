%% math_jobs.m - Mathematical computation examples using Kubernetes Jobs
%
% Each example follows the same pattern:
%   1. Define a job name, container image, and inline Python command
%   2. Create the Kubernetes Job with kJob('create', ...)
%   3. Wait for the container to pull and execute
%   4. Stream logs with kJob('stream', ...)
%   5. Delete the job with kJob('delete', ...)
%
% Functions used:
%   kJob(action, namespace, name, image, command)
%     action    - 'create' | 'delete' | 'stream'
%     namespace - target namespace
%     name      - unique job name
%     image     - container image
%     command   - shell/python command to execute
%
% All examples run in the 'default' namespace and use 'python:3-slim'.
% No ConfigMaps are needed - computations are expressed as inline commands.

%% Setup
addpath('../build');
ns = 'default';

%% ============================================================
%% Example 1: Calculate Euler's number (e) using Python
%% ============================================================
disp('=== Example 1: Euler''s Number (e) with Python ===');

job_name = 'euler-number';
image = 'python:3-slim';
command = 'python -c "import math; print(math.e)"';

result = kJob('create', ns, job_name, image, command);
disp(['Created: ', result]);

disp('Waiting 15s for container to pull and run...');
pause(15);

logs = kJob('stream', ns, job_name, '', '');
disp(logs);

kJob('delete', ns, job_name, '', '');
disp('Job deleted.');

%% ============================================================
%% Example 2: Matrix multiplication with Python (no numpy)
%% ============================================================
disp('');
disp('=== Example 2: Matrix Multiplication (pure Python) ===');

job_name = 'matrix-mult';
image = 'python:3-slim';
command = 'python -c "A=[[1,2],[3,4]]; B=[[5,6],[7,8]]; C=[[sum(a*b for a,b in zip(row,col)) for col in zip(*B)] for row in A]; print(C)"';

result = kJob('create', ns, job_name, image, command);
disp(['Created: ', result]);

disp('Waiting 15s...');
pause(15);

logs = kJob('stream', ns, job_name, '', '');
disp(logs);

kJob('delete', ns, job_name, '', '');
disp('Job deleted.');

%% ============================================================
%% Example 3: Calculate Pi using Python
%% ============================================================
disp('');
disp('=== Example 3: Pi with 50 decimals ===');

job_name = 'calc-pi';
image = 'python:3-slim';
command = 'python -c "from decimal import Decimal, getcontext; getcontext().prec=55; print(Decimal(1).exp()/Decimal(1).exp() * Decimal(3.141592653589793238462643383279502884197169399375105820974944592))"';

result = kJob('create', ns, job_name, image, command);
disp(['Created: ', result]);

disp('Waiting 15s...');
pause(15);

logs = kJob('stream', ns, job_name, '', '');
disp(logs);

kJob('delete', ns, job_name, '', '');
disp('Job deleted.');

%% ============================================================
%% Example 4: Factorial with Python
%% ============================================================
disp('');
disp('=== Example 4: Factorial of 20 ===');

job_name = 'factorial';
image = 'python:3-slim';
command = 'python -c "import math; print(math.factorial(20))"';

result = kJob('create', ns, job_name, image, command);
disp(['Created: ', result]);

disp('Waiting 15s...');
pause(15);

logs = kJob('stream', ns, job_name, '', '');
disp(logs);

kJob('delete', ns, job_name, '', '');
disp('Job deleted.');

%% ============================================================
%% Example 5: Square root of 2 with high precision (Python)
%% ============================================================
disp('');
disp('=== Example 5: Square root of 2 (50 decimals) ===');

job_name = 'sqrt2';
image = 'python:3-slim';
command = 'python -c "from decimal import Decimal, getcontext; getcontext().prec=60; print(Decimal(2).sqrt())"';

result = kJob('create', ns, job_name, image, command);
disp(['Created: ', result]);

disp('Waiting 15s...');
pause(15);

logs = kJob('stream', ns, job_name, '', '');
disp(logs);

kJob('delete', ns, job_name, '', '');
disp('Job deleted.');

%% ============================================================
%% Example 6: Golden Ratio
%% ============================================================
disp('');
disp('=== Example 6: Golden Ratio (phi) ===');

job_name = 'golden-ratio';
image = 'python:3-slim';
command = 'python -c "from decimal import Decimal, getcontext; getcontext().prec=60; print((1+Decimal(5).sqrt())/2)"';

result = kJob('create', ns, job_name, image, command);
disp(['Created: ', result]);

disp('Waiting 15s...');
pause(15);

logs = kJob('stream', ns, job_name, '', '');
disp(logs);

kJob('delete', ns, job_name, '', '');
disp('Job deleted.');

disp('');
disp('=== All examples completed! ===');
