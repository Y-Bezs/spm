function [y] = spm_gx_fmri(x,u,P,M)
% Simulated BOLD response to input
% FORMAT [y] = spm_gx_fmri(x,u,P,M)
% y          - BOLD response (%)
% x          - state vector     (see spm_fx_dcm)
% P          - Parameter vector (see spm_fx_dcm)
% M          - model specification structure (see spm_nlsi)
%__________________________________________________________________________
%
% This function implements the BOLD signal model described in: 
%
% Stephan KE, Weiskopf N, Drysdale PM, Robinson PA, Friston KJ (2007)
% Comparing hemodynamic models with DCM. NeuroImage 38: 387-401.
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston & Klaas Enno Stephan
% $Id: spm_gx_fmri.m 3705 2010-02-01 20:51:28Z karl $
 
 
% Biophysical constants for 1.5T
%==========================================================================
 
% time to echo (TE) (default 0.04 sec)
%--------------------------------------------------------------------------
try, TE = M.TE; catch, TE = 0.04; end
 
% resting venous volume (%)
%--------------------------------------------------------------------------
V0  = 8;

% estimated region-specific ratios of intra- to extra-vascular signal 
%--------------------------------------------------------------------------
ep  = 1*exp(P.epsilon);
 
% slope r0 of intravascular relaxation rate R_iv as a function of oxygen 
% saturation S:  R_iv = r0*[(1 - S)-(1 - S0)] (Hz)
%--------------------------------------------------------------------------
r0  = 25;
 
% frequency offset at the outer surface of magnetized vessels (Hz)
%--------------------------------------------------------------------------
nu0 = 40.3; 
 
% resting oxygen extraction fraction
%--------------------------------------------------------------------------
E0  = 0.4;
 
%-Coefficients in BOLD signal model
%==========================================================================
k1  = 4.3*nu0*E0*TE;
k2  = ep*r0*E0*TE;
k3  = 1 - ep;
 
%-Output equation of BOLD signal model
%==========================================================================
v   = exp(x(:,4));
q   = exp(x(:,5));
y   = V0*(k1.*(1 - q) + k2.*(1 - q./v) + k3.*(1 - v));
