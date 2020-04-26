function [Y] = spm_marginal(X)
% Marginal densities over a multidimensional array of probabilities
% FORMAT [Y] = spm_marginal(X)
% X  - numeric array of probabilities
%
% Y  - cell array of marginals
%
% See also: spm_dot
%__________________________________________________________________________
% Copyright (C) 2020 Wellcome Centre for Human Neuroimaging

% Karl Friston
% $Id: spm_marginal.m 7840 2020-04-26 23:11:25Z spm $


% evaluate marginals
%--------------------------------------------------------------------------
n     = ndims(X);
Y     = cell(n,1);
for i = 1:n
    j    = 1:n;
    j(i) = [];
    
    Y{i} = reshape(spm_sum(X,j),[],1);
end
