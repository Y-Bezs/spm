function [d] = spm_kl_gamma (b_q,c_q,b_p,c_p)
% KL divergence for Gamma densities
% FORMAT [d] = spm_kl_gamma (b_q,c_q,b_p,c_p)
%
% KL (Q||P) = <log Q/P> where avg is wrt Q
%
% b_q, c_q    Parameters of first Gamma density
% b_p, c_p    Parameters of second Gamma density
%___________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Will Penny 
% $Id: spm_kl_gamma.m 1143 2008-02-07 19:33:33Z spm $

digamma_c_q=spm_digamma(c_q);
d=(c_q-1)*digamma_c_q-log(b_q)-c_q-gammaln(c_q);
d=d+gammaln(c_p)+c_p*log(b_p)-(c_p-1)*(digamma_c_q+log(b_q));
d=d+b_q*c_q/b_p;


