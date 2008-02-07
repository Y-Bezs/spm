function job = spm_config_fieldmap
% Configuration file for FieldMap jobs
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Chloe Hutton
% $Id: spm_config_FieldMap.m 1143 2008-02-07 19:33:33Z spm $
%_______________________________________________________________________
entry = inline(['struct(''type'',''entry'',''name'',name,'...
        '''tag'',tag,''strtype'',strtype,''num'',num)'],...
        'name','tag','strtype','num');

files = inline(['struct(''type'',''files'',''name'',name,'...
        '''tag'',tag,''filter'',fltr,''num'',num)'],...
        'name','tag','fltr','num');

mnu = inline(['struct(''type'',''menu'',''name'',name,'...
        '''tag'',tag,''labels'',{labels},''values'',{values})'],...
        'name','tag','labels','values');

branch = inline(['struct(''type'',''branch'',''name'',name,'...
        '''tag'',tag,''val'',{val})'],...
        'name','tag','val');

repeat = inline(['struct(''type'',''repeat'',''name'',name,''tag'',tag,'...
         '''values'',{values})'],'name','tag','values');
     
choice = inline(['struct(''type'',''choice'',''name'',name,''tag'',tag,'...
         '''values'',{values})'],'name','tag','values');
%______________________________________________________________________

addpath(fullfile(spm('dir'),'toolbox','FieldMap'));

%------------------------------------------------------------------------
% File selection for Precalculated fieldmap data (in Hz)
precalcfieldmap.type = 'files';
precalcfieldmap.name = 'Precalculated fieldmap';
precalcfieldmap.tag  = 'precalcfieldmap';
precalcfieldmap.num  = [1 1];
precalcfieldmap.filter = 'image';
precalcfieldmap.help   = {['Select a precalculated fieldmap. This should be a ',...
'processed fieldmap (ie phase unwrapped, masked if necessary and scaled to Hz), ',...
'for example as generated by the FieldMap toolbox and stored as an fpm_* file.']};

%------------------------------------------------------------------------
% File selection for Phase/Magnitude fieldmap data

shortphase.type = 'files';
shortphase.name = 'Short Echo Phase Image';
shortphase.tag  = 'shortphase';
shortphase.num  = [1 1];
shortphase.filter = 'image';
shortphase.help   = {['Select short echo phase image']};

shortmag.type = 'files';
shortmag.name = 'Short Echo Magnitude Image';
shortmag.tag  = 'shortmag';
shortmag.num  = [1 1];
shortmag.filter = 'image';
shortmag.help   = {['Select short echo magnitude image']};

longphase.type = 'files';
longphase.name = 'Long Echo Phase Image';
longphase.tag  = 'longphase';
longphase.num  = [1 1];
longphase.filter = 'image';
longphase.help   = {['Select long echo phase image']};

longmag.type = 'files';
longmag.name = 'Long Echo Magnitude Image';
longmag.tag  = 'longmag';
longmag.num  = [1 1];
longmag.filter = 'image';
longmag.help   = {['Select long echo magnitude image']};

%------------------------------------------------------------------------
% File selection for Presubtracted Magnitude/Phase fieldmap data
presubmag.type = 'files';
presubmag.name = 'Magnitude Image';
presubmag.tag  = 'magnitude';
presubmag.num  = [1 1];
presubmag.filter = 'image';
presubmag.help   = {['Select a single magnitude image']};

presubphase.type = 'files';
presubphase.name = 'Phase Image';
presubphase.tag  = 'phase';
presubphase.num  = [1 1];
presubphase.filter = 'image';
presubphase.help   = {['Select a single phase image. This should be the result from the ',...
'subtraction of two phase images (where the subtraction is usually done automatically by ',...
'the scanner software). The phase image will be scaled between +/- PI.']};

%------------------------------------------------------------------------
% File selection for Real/Imaginary fieldmap data
shortreal.type = 'files';
shortreal.name = 'Short Echo Real Image';
shortreal.tag  = 'shortreal';
shortreal.num  = [1 1];
shortreal.filter = 'image';
shortreal.help   = {['Select short echo real image']};

shortimag.type = 'files';
shortimag.name = 'Short Echo Imaginary Image';
shortimag.tag  = 'shortimag';
shortimag.num  = [1 1];
shortimag.filter = 'image';
shortimag.help   = {['Select short echo imaginary image']};

longreal.type = 'files';
longreal.name = 'Long Echo Real Image';
longreal.tag  = 'longreal';
longreal.num  = [1 1];
longreal.filter = 'image';
longreal.help   = {['Select long echo real image']};

longimag.type = 'files';
longimag.name = 'Long Echo Imaginary Image';
longimag.tag  = 'longimag';
longimag.num  = [1 1];
longimag.filter = 'image';
longimag.help   = {['Select long echo imaginary image']};

%------------------------------------------------------------------------
% Defaults parameter file used for fieldmap creation
[default_file_path, tmpname] = fileparts(mfilename('fullpath'));
default_filename = sprintf('%s%s%s',default_file_path,filesep,'pm_defaults.m'); 
defaults.type = 'files';
defaults.name = 'Defaults File';
defaults.tag  = 'defaults';
defaults.num  = [1 1];
defaults.filter  = 'm';
defaults.ufilter = '^pm_defaults.*\.m$';
defaults.val = {default_filename};
defaults.dir = default_file_path;
defaults.help = {[...
'Select the ''pm_defaults*.m'' file containing the parameters for the fieldmap data. ',...
'Please make sure that the parameters defined in the defaults file are correct for ',...
'your fieldmap and EPI sequence. To create your own defaults file, either edit the '...
'distributed version and/or save it with the name ''pm_defaults_yourname.m''.']};

%-----------------------------------------------------------------------
% Match anatomical image
matchanat.type = 'menu';
matchanat.name = 'Match anatomical image to EPI?';
matchanat.tag  = 'matchanat';
matchanat.labels = {'match anat', 'none'};
matchanat.values = {1,0};
matchanat.val = {0};
matchanat.help = {[...
'Match the anatomical image to the distortion corrected EPI.']};

%------------------------------------------------------------------------
% Select a anatomical image for display and comparison
anat.type = 'files';
anat.name = 'Select anatomical image for comparison';
anat.tag  = 'anat';
anat.filter = 'image';
anat.num  = [0 1];
anat.val  = {''};
anat.help = {[...
'Select an anatomical image for comparison with the distortion corrected EPI.']};

%-----------------------------------------------------------------------
% Write unwarped EPI image
writeunwarped.type = 'menu';
writeunwarped.name = 'Write unwarped EPI?';
writeunwarped.tag  = 'writeunwarped';
writeunwarped.labels = {'write unwarped EPI', 'none'};
writeunwarped.values = {1,0};
writeunwarped.val = {0};
writeunwarped.help = {[...
'Write out distortion corrected EPI image. The image is saved with the prefix u.']};

%-----------------------------------------------------------------------
% Match VDM file to EPI image
matchvdm.type = 'menu';
matchvdm.name = 'Match VDM to EPI?';
matchvdm.tag  = 'matchvdm';
matchvdm.labels = {'match vdm', 'none'};
matchvdm.values = {1,0};
matchvdm.val = {0};
matchvdm.help = {[...
'Match VDM file to EPI image. This option will coregister the fieldmap data ',...
'to the selected EPI before doing distortion correction.']};

%------------------------------------------------------------------------
% Select a single EPI to unwarp
epi.type = 'files';
epi.name = 'Select EPI to Unwarp';
epi.tag  = 'epi';
epi.filter = 'image';
epi.num  = [0 1];
epi.val  = {''};
epi.help = {[...
'Select an image to distortion correct. The original and the distortion ',...
'corrected images can be displayed for comparison.']};

%------------------------------------------------------------------------
% Display results or not?
fieldmap.options.display = 1;

display.type = 'menu';
display.name = 'Display Results?';
display.tag  = 'display';
display.labels = {'Display Results','none'};
display.values = {1,0};
display.val = {1};
display.help = {['Display the results.']};

%------------------------------------------------------------------------
% Other options that are not included in the defaults file
options.type = 'branch';
options.name = 'FieldMap Options';
options.tag  = 'options';
options.val  = {display,epi,matchvdm,writeunwarped,anat,matchanat};
options.help = {[...
'Options for FieldMap creation.']};

%------------------------------------------------------------------------
% Define precalculated fieldmap type of job
subj.type = 'branch';
subj.name = 'Subject';
subj.tag  = 'subj';
subj.val  = {precalcfieldmap,defaults,options};
subj.help = {'Data for this subject.'};

data.type = 'repeat';
data.name = 'Data';
data.values = {subj};
data.num  = [1 Inf];
data.help = {'List of subjects.'};

precalcfieldmap.type = 'branch';
precalcfieldmap.name = 'Precalculated FieldMap (in Hz)';
precalcfieldmap.tag  = 'precalcfieldmap';
precalcfieldmap.val  = {data};
precalcfieldmap.help = {[...
'Calculate a voxel displacement map from a precalculated fieldmap. This option ',...
'expects a processed fieldmap (ie phase unwrapped, masked if necessary and scaled to Hz). ',...
'Precalculated fieldmaps can be generated by the FieldMap toolbox and stored as fpm_* files.']};

%------------------------------------------------------------------------
% Define phase/magnitude type of job, double phase and magnitude file
subj.type = 'branch';
subj.name = 'Subject';
subj.tag  = 'subj';
subj.val  = {shortphase,shortmag,longphase,longmag,defaults,options};
subj.help = {'Data for this subject.'};

data.type = 'repeat';
data.name = 'Data';
data.values = {subj};
data.num  = [1 Inf];
data.help = {'List of subjects.'};

phasemag.type = 'branch';
phasemag.name = 'Phase and Magnitude Data';
phasemag.tag  = 'phasemag';
phasemag.val  = {data};
phasemag.help = {[...
'Calculate a voxel displacement map from double phase and magnitude fieldmap data.'...
'This option expects two phase and magnitude pairs of data of two different ',...
'echo times.']};


%------------------------------------------------------------------------
% Define phase/magnitude type of job, presubtracted phase and single magnitude file
subj.type = 'branch';
subj.name = 'Subject';
subj.tag  = 'subj';
subj.val  = {presubphase,presubmag,defaults,options};
%subj.val  = {matname};
subj.help = {'Data for this subject.'};

data.type = 'repeat';
data.name = 'Data';
data.values = {subj};
data.num  = [1 Inf];
data.help = {'List of subjects.'};

presubphasemag.type = 'branch';
presubphasemag.name = 'Presubtracted Phase and Magnitude Data';
presubphasemag.tag  = 'presubphasemag';
presubphasemag.val  = {data};
presubphasemag.help = {[...
'Calculate a voxel displacement map from presubtracted phase and magnitude fieldmap data. ',...
'This option expects a single magnitude image and a single phase image resulting from the ',...
'subtraction of two phase images (where the subtraction is usually done automatically by ',...
'the scanner software). The phase image will be scaled between +/- PI.']};

%------------------------------------------------------------------------
% Define real/imaginary type of job
subj.type = 'branch';
subj.name = 'Subject';
subj.tag  = 'subj';
subj.val  = {shortreal,shortimag,longreal,longimag,defaults,options};
subj.help = {'Data for this subject.'};

data.type = 'repeat';
data.name = 'Data';
data.values = {subj};
data.num  = [1 Inf];
data.help = {'List of subjects.'};

realimag.type = 'branch';
realimag.name = 'Real and Imaginary Data';
realimag.tag  = 'realimag';
realimag.val  = {data};
realimag.help = {[...
'Calculate a voxel displacement map from real and imaginary fieldmap data. ',...
'This option expects two real and imaginary pairs of data of two different ',...
'echo times.']};

%------------------------------------------------------------------------
% Define fieldmap job
job.type = 'choice';
job.name = 'FieldMap';
job.tag  = 'fieldmap';
job.prog = @fieldmap_job;
job.values = {presubphasemag,realimag,phasemag,precalcfieldmap};
p1 = [...
'The FieldMap toolbox generates unwrapped fieldmaps which are converted to ',...
'voxel displacement maps (vdm_* files) that can be used to unwarp geometrically ',...
'distorted EPI images. For references and an explantion of the theory behind the fieldmap based ',...
'unwarping, see FieldMap_principles.man. ',...
'The resulting vdm_* files can be used in combination with Realign & Unwarp ',...
'to calculate and correct for the combined effects of static and movement-related ',...
'susceptibility induced distortions.'];
job.help = {p1,''};

%------------------------------------------------------------------------
function fieldmap_job(job)

if isfield(job,'presubphasemag')
    FieldMap_Run(job.presubphasemag.subj);
elseif isfield(job,'realimag')
    FieldMap_Run(job.realimag.subj);
elseif isfield(job,'phasemag')
    Fieldmap_Run(job.phasemag.subj);
elseif isfield(job,'precalcfieldmap')
    FieldMap_Run(job.precalcfieldmap.subj);
end
        



