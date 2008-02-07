function D = spm_eeg_inv_ecd_ui(varargin)
% Fits dipole(s) onto a bit of EEG data.
% Use parts of a routine previously written for the DipFit
% toolbox.
%
% FORMAT D = spm_eeg_inv_ecd_ui(D)
% Input:
% D         - input data struct (optional)
% Output:
% D         - same data struct including the details of the model
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Christophe Phillips
% $Id: spm_eeg_inv_ecd_ui.m 1143 2008-02-07 19:33:33Z spm $

% 1. call dipfit gui to get all the parameters and fit the dipoles
% 2. if multiple seeds were used summarise results by grouping the solutions
% 3. display the results on the MRI

% initialise
%--------------------------------------------------------------------------
[D,val] = spm_eeg_inv_check(varargin{:});

% 1. call dipfit gui to get all the parameters and fit the dipoles
%--------------------------------------------------------------------------
D.inv{D.val}.inverse.sdip   = spm_eeg_inv_ecd_fitDip_ui(D);

% 2. if multiple seeds were used, summarise results by grouping solutions
%--------------------------------------------------------------------------
D.inv{D.val}.inverse.resdip = spm_eeg_inv_ecd_sDipRes(D.inv{D.val}.inverse.sdip);

% 3. display the results on the MRI
%--------------------------------------------------------------------------
spm_eeg_inv_ecd_DrawDip('Init',D.inv{D.val}.inverse.resdip,D.inv{D.val}.mesh.sMRI)

