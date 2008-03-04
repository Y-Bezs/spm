function deletefiles = spm_cfg_deletefiles
% SPM Configuration file
% automatically generated by the MATLABBATCH utility function GENCODE
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% $Id: spm_cfg_deletefiles.m 1185 2008-03-04 16:31:21Z volkmar $

% ---------------------------------------------------------------------
% deletefiles Files to delete
% ---------------------------------------------------------------------
deletefiles1         = cfg_files;
deletefiles1.tag     = 'deletefiles';
deletefiles1.name    = 'Files to delete';
deletefiles1.help    = {'Select files to delete.'};
deletefiles1.filter = '.*';
deletefiles1.ufilter = '.*';
deletefiles1.num     = [0 Inf];
% ---------------------------------------------------------------------
% deletefiles Delete Files
% ---------------------------------------------------------------------
deletefiles         = cfg_exbranch;
deletefiles.tag     = 'deletefiles';
deletefiles.name    = 'Delete Files (Deprecated)';
deletefiles.val     = {deletefiles1 };
deletefiles.help    = {'This module is deprecated and has been moved to BasicIO.',...
                    ['Jobs which are ready to run may continue using it, but ' ...
                    'the module inputs can not be changed via GUI. ' ...
                    'Please switch to the BasicIO module instead.'], ...
                    'This facilty allows to delete files in a batch. Note that deleting files will not make them disappear from file selection lists. Therefore one has to be careful not to select the original files after they have been programmed to be deleted.',...
                       '',...
                       'If image files (.img or .nii) are selected, corresponding .hdr or .mat files will be deleted as well, if they exist.'
}';
deletefiles.prog = @my_deletefiles;
deletefiles.hidden = true;
%------------------------------------------------------------------------
function my_deletefiles(varargin)
job = varargin{1};
for k = 1:numel(job.deletefiles)
    [p n e] = spm_fileparts(job.deletefiles{k});
    if strcmp(e,'.img') || strcmp(e,'.nii')
        spm_unlink(fullfile(p,[n '.hdr']));
        spm_unlink(fullfile(p,[n '.mat']));
    end
    spm_unlink(fullfile(p,[n e]));
end
