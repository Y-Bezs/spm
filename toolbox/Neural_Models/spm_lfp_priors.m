function [varargout] = spm_lfp_priors(A,B,C,L,H)
% prior moments for a neural mass model of ERPs
% FORMAT [pE,pC] = spm_lfp_priors(A,B,C,L,H)
% FORMAT [M]     = spm_lfp_priors(A,B,C,L,H)
% FORMAT           spm_lfp_priors(A,B,C,L,H)
%
% A{3},B{m},C    - binary constraints on extrinsic connectivity
% L              - lead field matrix    [default = I]
% H              - contributing states  [default = x(9) - pyramidal]
%
% pE - prior expectation
%
% synaptic parameters
%--------------------------------------------------------------------------
%    pE.T - synaptic time constants
%    pE.H - synaptic densities
%
% spatial parameters
%--------------------------------------------------------------------------
%    pE.L - Lead field or Gain OR pE.Lpos - position
%                                 pE.Lmon - moment (orientation):
%    pE.M - contributing states
%
% connectivity parameters
%--------------------------------------------------------------------------
%    pE.A - extrinsic - coupling
%    pE.B - extrinsic - trial-dependent
%    pE.C - extrinsic - stimulus input
%    pE.G - intrinsic
%    pE.D - extrinsic delays
%    pE.I - intrinsic delays
%
% input and noise parameters
%--------------------------------------------------------------------------
%    pE.a - amplitude of AR component
%    pE.b - amplitude of IID component
%    pE.c - amplitude of noise (spectral density)
%    pE.d - amplitude of noise (cross-spectral density)
%
% NB: This is the same as spm_erp_priors but without stimulus parameters 
% and treating stimulus and experimental inputs in the same way
%--------------------------------------------------------------------------
%
% pC - prior covariances: cov(spm_vec(pE))
%
% Because priors are specified under log normal assumptions, most
% parameters are simply scaling coefficients with a prior expectation
% and variance of one.  After log transform this renders pE = 0 and
% pC = 1;  The prior expectations of what they scale are specified in
% spm_lfp_fx
%__________________________________________________________________________
%
% David O, Friston KJ (2003) A neural mass model for MEG/EEG: coupling and
% neuronal dynamics. NeuroImage 20: 1743-1755
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_lfp_priors.m 1132 2008-02-06 14:12:17Z karl $


% defaults
%--------------------------------------------------------------------------
if nargin <  3                                  % a single source model
    A   = {0 0 0};
    B   = {0};
    C   = 1;
end
n   = size(C,1);                                % number of sources
N   = n*13;                                     % number of states
if nargin <  4, L = speye(length(C));  end
if nargin <  5, H = sparse(9,1,1,13,1); end
 
 
 
% disable log zero warning
%--------------------------------------------------------------------------
warning off
 
% sigmoid parameters
%--------------------------------------------------------------------------
E.R   = [0 0];             V.R = [1 1]/8;
 
% set intrinsic [excitatory] time constants
%--------------------------------------------------------------------------
E.T   = log(ones(n,2));    V.T = ones(n,2)/8;      % time constants
E.H   = log(ones(n,1));    V.H = ones(n,1)/8;      % synaptic density
E.G   = log(ones(n,5));    V.G = ones(n,5)/8;      % intrinsic connections
 
% set observer parameters
%--------------------------------------------------------------------------
E.M   = H;                 V.M = H*0;              % contributing states
 
% set observer parameters
%--------------------------------------------------------------------------
if ~isstruct(L)                                    % static lead-field
    E.L    = L;            V.L = L*0;              % lead field
    
else  % parameterised lead-field based on equivalent current dipoles
%------------------------------------------------------------------------
    E.Lpos = L.pos;        V.Lpos =   0*ones(3,n); % dipole positions
    E.Lmom = sparse(3,n);  V.Lmom = 256*ones(3,n); % dipole orientations
end
 
% set extrinsic connectivity
%--------------------------------------------------------------------------
Q     = sparse(n,n);
for i = 1:length(A)
    E.A{i} = log(~~A{i} + eps);                    % forward
    V.A{i} = A{i}/2;                               % backward
    Q      = Q | A{i};                             % and lateral connections
end
 
for i = 1:length(B)
    E.B{i} = 0*B{i};                               % input-dependent scaling
    V.B{i} = ~~B{i}/2;
    Q      = Q | B{i};
end
E.C    = log(~~C + eps);                           % where inputs enter
V.C    = C/2;
 
% set endogenous noise
%--------------------------------------------------------------------------
E.a    = 0;               V.a = 1/32;              % amplitude AR
E.b    = 0;               V.b = 0;                 % amplitude IID
 
% set delay
%--------------------------------------------------------------------------
E.D    = sparse(n,n);     V.D = Q/8;               % extrinsic delays
E.I    = 0;               V.I = 1/32;              % intrinsic delays
 
% vectorize
%--------------------------------------------------------------------------
pE     = E;
pV     = spm_vec(V);
pC     = diag(sparse(pV));
warning on
 
% prior momments if two arguments
%--------------------------------------------------------------------------
if nargout == 2, varargout{1} = pE; varargout{2} = pC; return, end
 
 
% Model specification
%==========================================================================
M.f      = 'spm_fx_lfp';
M.g      = 'spm_gx_lfp';
M.x      = sparse(N,1);
M.pE     = pE;
M.pC     = pC;
M.m      = length(B);
M.n      = size(M.x,1);
M.l      = size(pE.L,1);
M.IS     = 'spm_int';
 
if nargout == 1, varargout{1} = M; return, end
 
% compute impulse response
%--------------------------------------------------------------------------
N       = 128;
U.dt    = 8/1000;
U.u     = sparse(1,1,1/U.dt,N,M.m);
y       = feval(M.IS,M.pE,M,U);
plot([1:N]*U.dt*1000,y)
 
 
return
 
% demo for log-normal pdf
%--------------------------------------------------------------------------
x    = [1:64]/16;
for i = [2 16]
    v = 1/i;
    p = 1./x.*exp(-log(x).^2/(2*v))/sqrt(2*pi*v);
    plot(x,p)
    text(x(16),p(16),sprintf('variance = 1/%i',1/v))
    hold on
end
xlabel('scaling')
ylabel('density')
grid on
hold off
