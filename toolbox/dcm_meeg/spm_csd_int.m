function [Y,w,t,x,G,S,E] = spm_csd_int(P,M,U)
% Time frequency response of a neural mass model
% FORMAT [Y,w,t,x,G,S,E] = spm_csd_int(P,M,U)
%
% P - parameters
% M - neural mass model structure
% U - time-dependent input
%
% Y - {Y(t,w,nc,nc}} - cross-spectral density for nc channels {trials}
%                    - for w frequencies over time t in M.Hz
% w - frequencies
% t - peristimulus time
% x - expectation of hidden (neuronal) states (for last trial)
% G - {G(t,w,nc,nc}} - cross spectrum density before dispersion
% S - {S(t,w,nc,nu}} - transfer functions
% E - {E(t,nc}}      - event-related average (sensor space)
%__________________________________________________________________________
%
% This integration routine evaluates the responses of a neural mass model
% to exogenous input - in terms of neuronal states. These are then used as
% expansion point to generate complex cross spectral responses due to
% random neuronal fluctuations. The ensuing spectral (induced) response is
% then convolved (in time) with a window that corresponds to the window of
% a standard wavelet transform. In other words, this routine generates
% predictions of data features based upon a wavelet transform
% characterisation of induced responses.
%__________________________________________________________________________
% Copyright (C) 2012-2013 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_csd_int.m 5951 2014-04-12 11:38:44Z karl $


% check input - default: one trial (no between-trial effects)
%--------------------------------------------------------------------------
if nargin < 3
    U.dt = 1/256;
    U.u  = sparse(1,M.m);
    U.X  = sparse(1,0);
end


% check function format
%--------------------------------------------------------------------------
f   = fcnchk(M.f);

% check input function  u = f(t,P,M)
%--------------------------------------------------------------------------
try, fu  = M.fu;    catch, fu  = 'spm_erp_u'; end
try, ns  = M.ns;    catch, ns  = 128;         end
try, Rft = M.Rft;   catch, Rft = 4;           end
try, dt  = U.dt;    catch, dt  = 1/256;       end


% within-trial (exogenous) inputs
%==========================================================================
if ~isfield(U,'u')
    u = feval(fu,(1:ns)*dt,P,M)';
else
    u = U.u';
end

% peristimulus time
%--------------------------------------------------------------------------
ns   = size(u,2);
t    = (1:ns)*U.dt;

% between-trial (experimental) inputs
%==========================================================================
try
    X = U.X;
    if ~size(X,1)
        X = sparse(1,0);
    end
catch
    X = sparse(1,0);
end

% number of endogenous inputs and hidden states
%==========================================================================
nu    = length(P.A{1});
nx    = M.n;

% paramter update eqation
%--------------------------------------------------------------------------
if isfield(M,'h'), h = spm_funcheck(M.h);  end


% cycle over trials or conditions
%--------------------------------------------------------------------------
for c = 1:size(X,1)
    
    % condition-specific parameters
    %----------------------------------------------------------------------
    Q   = spm_gen_Q(P,X(c,:));
    
    % initialise hidden states
    %----------------------------------------------------------------------
    x   = spm_vec(spm_dcm_neural_x(Q,M));
    
    % remove state (X) and input (Y) dependent parameter from Q
    %----------------------------------------------------------------------
    if isfield(Q,'X'), Q = rmfield(Q,'X'); end
    if isfield(Q,'Y'), Q = rmfield(Q,'Y'); end
    
    
    % get local linear operator LL and delay operator D
    %==================================================================
    if nargout(f) >= 3
        [f0,dfdx,D] = f(x(:,1),u(:,1),Q,M);
        
    elseif nargout(f) == 2
        [f0,dfdx]   = f(x(:,1),u(:,1),Q,M);
        D           = 1;
        
    else
        dfdx        = spm_diff(f,x(:,1),u(:,1),Q,M,1);
        D           = 1;
    end
    
    % get local linear (Lie) operator L
    %------------------------------------------------------------------
    p     = max(abs(real(eig(full(dfdx)))));
    N     = ceil(max(1,dt*p*2));
    L     = (spm_expm(dt*D*dfdx/N) - speye(nx,nx))*spm_inv(dfdx);
    
    % cycle over time - expanding around expected states and input
    %======================================================================
    dQ    = spm_vec(Q)*0;
    dU    = dQ;
    dX    = dQ;
    for i = 1:length(t)
        
        % hidden states
        %------------------------------------------------------------------
        if i > 1, x(:,i) = x(:,i - 1); end
        
        
        % state-dependent parameters (and plasticity)
        %==================================================================
        if isfield(P,'X'), dU  = P.X*u(:,i);                      end
        if isfield(P,'Y'), dX  = P.Y*x(:,i);                      end
        if isfield(M,'h'), dQ  = dQ + h(x(:,i),u(:,i),dQ,M)*U.dt; end
        
        % update
        %------------------------------------------------------------------
        R       = spm_unvec(spm_vec(Q) + spm_vec(dQ + dU + dX),Q);
        
        
        % compute complex cross spectral density
        %==================================================================
        
        % use current states
        %------------------------------------------------------------------
        M.x     = spm_unvec(x(:,i),M.x);
        M.u     = sparse(nu,1);
        [g,w,s] = spm_csd_mtf(R,M);
 
        
        % place CSD and transfer functions in response
        %------------------------------------------------------------------
        G{c}(i,:,:,:) = g{1};
        S{c}(i,:,:,:) = s{1};

        
        % update dx = (expm(dt*J) - I)*inv(J)*f(x,u) = LL*f(x,u)
        %==================================================================
        
        % reset to expansion point (hidden states and exogenous input)
        %------------------------------------------------------------------
        M     = rmfield(M,'u');
        M.x   = spm_unvec(x(:,1),M.x); 
        for j = 1:N
            x(:,i) = x(:,i) + L*f(x(:,i),u(:,i),R,M);
        end
        
        % and ERP response
        %------------------------------------------------------------------
        erp(:,i)  = feval(M.g,x(:,i),u(:,i),R,M);
        
    end
    
    % model dispersion associated with wavelet transforms
    %----------------------------------------------------------------------
    Y{c}  = spm_morlet_conv(G{c},w*dt,Rft);
    E{c}  = erp';
    
end
