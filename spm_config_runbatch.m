function opts = spm_config_runbatch
% Configuration file for running batched jobs
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Darren Gitelman
% $Id: spm_config_runbatch.m 1143 2008-02-07 19:33:33Z spm $

data.type = 'files';
data.name = 'Batch Files';
data.tag  = 'jobs';
data.filter = 'batch';
data.num  = [1 Inf];
data.help = {'Select the batch job files to be run.'};

opts.type = 'branch';
opts.name = 'Execute Batch Jobs';
opts.tag  = 'runbatch';
opts.val  = {data};
opts.prog = @runbatch;
opts.help = {[...
'This facility allows previously created batch jobs to be run. ',...
'These are simply created by the batch user interface ',...
'(which you are currently using).']};
return;
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function runbatch(varargin)
jobs = varargin{1}.jobs;
for i=1:numel(jobs),
    spm_jobman('run',jobs{i});
end;
return;

