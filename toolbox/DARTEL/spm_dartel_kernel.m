function spm_dartel_kernel(job)
% Generate Fisher kernel from flow fields
% FORMAT spm_dartel_kernel(job)
% job.flowfields - Flow-fields
% job.rform      - Form of L
% job.rparam     - Parameters of L
% job.dotprod    - Part of filename for results
%
% k(x_1,x_2) = <x_1,L x_2> = <L x_1, x_2>
%
% This is very slow, and is not in a form that would be
% suited to weighting according to location in the image.
% For this, the "square root" of L would need to be used
% in order to convert the flow fields into (e.g.) their
% Jacobian tensor fields.  For linear elasticity, this
% field would be decomposed by J = (J+J')/2 + (J-J')/2.
% The elements of the symetric part (along with its trace)
% would then be used to generate the kernel.
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% John Ashburner
% $Id: spm_dartel_kernel.m 1143 2008-02-07 19:33:33Z spm $


P      = strvcat(job.flowfields);
[pth,nam,ext] = fileparts(job.dotprod);
ofname = fullfile(pwd,['dp_' nam '.mat']);
form   = job.rform;
param  = job.rparam;

prm = [form 1 1 1 param];

N   = nifti(P);
dm  = size(N(1).dat);
A   = zeros([dm(1:3),6],'single');
A(:,:,:,1:3) = 1e-6;
n   = numel(N);
Phi = zeros(n,n);
spm_progress_bar('Init',n*n,'Generating kernel','Elements done');
for i=1:n,
    x1 = single(squeeze(N(i).dat(:,:,:,:,:)));
    x1 = dartel3('vel2mom',x1,prm);
    for j=i:n,
        x2       =squeeze(N(j).dat(:,:,:,:,:,:));
        d        = x1(:)'*x2(:);
        Phi(i,j) = d;
        Phi(j,i) = d;

        if ~rem(j,8)
            spm_progress_bar('Set',...
                n*n-(n+1-i)*(n+1-i)+(j-i)*2+1);
        end
    end
    input = job;
    typ   = 'flow1';
    save(ofname,'Phi','input','typ');
end
spm_progress_bar('Clear');

