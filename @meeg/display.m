function str = display(this)
% Method for displaying information about an meeg object
% FORMAT display(this)
% _______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: display.m 2113 2008-09-18 11:14:46Z vladimir $

str = ['SPM M/EEG data object\n'...
    'Type: ' type(this) '\n'...
    num2str(nconditions(this)), ' conditions\n'...
    num2str(nchannels(this)), ' channels\n'...
    num2str(nsamples(this)), ' samples/trial\n'...
    num2str(ntrials(this)), ' trials\n'...
    'Sampling frequency: ' num2str(fsample(this)) ' Hz\n'...
    'Loaded from file  %s\n\n'...
    'Use the syntax D(channels, samples, trials) to access the data\n'...
    'Type "methods(''meeg'')" for the list of methods performing other operations with the object\n'...
    ];

str = sprintf(str, fullfile(this.path, this.fname));

disp(str);