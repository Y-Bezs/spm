function [G,Psig] = spm_granger (mar)
% Compute Granger causality matrix 
% FORMAT [G,Psig] = spm_granger (mar)
%
% mar            MAR data structure (see spm_mar.m) 
%
% G              [d x d] matrix with i,jth entry equal to 1 if
%                time series i 'Granger causes' time series j. 
%                All other entries set to 0.
%
% Psig           [d x d] matrix of corresponding significance values
%___________________________________________________________________________
% Copyright (C) 2007 Wellcome Department of Imaging Neuroscience

% Will Penny 
% $Id$

d=size(mar.noise_cov,1);

G=ones(d,d);
Psig=ones(d,d);

for i=1:d,
    for j=1:d,
        con=zeros(d,d);
        con(i,j)=1;
        Psig(i,j)=spm_mar_conn(mar,con);
    end
end

G=Psig<0.05;