function job = spm_config_preproc8
% Configuration file for Segment jobs
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Department of Imaging Neuroscience

% John Ashburner
% $Id: spm_config_preproc8.m 1434 2008-04-16 14:00:56Z john $


%_______________________________________________________________________

entry = inline(['struct(''type'',''entry'',''name'',name,'...
        '''tag'',tag,''strtype'',strtype,''num'',num,''help'',{{}})'],...
        'name','tag','strtype','num');

files = inline(['struct(''type'',''files'',''name'',name,'...
        '''tag'',tag,''filter'',fltr,''num'',num,''help'',{{}})'],...
        'name','tag','fltr','num');

mnu = inline(['struct(''type'',''menu'',''name'',name,'...
        '''tag'',tag,''labels'',{labels},''values'',{values},''help'',{{}})'],...
        'name','tag','labels','values');

branch = inline(['struct(''type'',''branch'',''name'',name,'...
        '''tag'',tag,''val'',{val},''help'',{{}})'],...
        'name','tag','val');

repeat = inline(['struct(''type'',''repeat'',''name'',name,'...
        '''tag'',tag,''values'',{values})'],...
        'name','tag','values');

addpath(fullfile(spm('dir'),'toolbox','Seg'));
%_______________________________________________________________________

vols = files('Volumes','vols','image',[1 Inf]);
vols.help = {[...
'Select scans from this channel for processing. ',...
'If multiple channels are used (eg T1 & T2), then the same order ',...
'of subjects must be specified for each channel and they must be ',...
'in register (same position, size, voxel dims etc..).']};

%------------------------------------------------------------------------

biasreg = mnu('Bias regularisation','biasreg',{...
'no regularisation (0)','extremely light regularisation (0.00001)',...
'very light regularisation (0.0001)','light regularisation (0.001)',...
'medium regularisation (0.01)','heavy regularisation (0.1)',...
'very heavy regularisation (1)','extremely heavy regularisation (10)'},...
{0, 0.00001, 0.0001, 0.001, 0.01, 0.1, 1.0, 10});
biasreg.val  = {0.0001};
biasreg.help = {[...
'MR images are usually corrupted by a smooth, spatially varying artifact that modulates the intensity ',...
'of the image (bias). ',...
'These artifacts, although not usually a problem for visual inspection, can impede automated ',...
'processing of the images.'],...
'',...
[...
'An important issue relates to the distinction between intensity variations that arise because of ',...
'bias artifact due to the physics of MR scanning, and those that arise due to different tissue ',...
'properties.  The objective is to model the latter by different tissue classes, while modelling the ',...
'former with a bias field. ',...
'We know a priori that intensity variations due to MR physics tend to be spatially smooth, ',...
'whereas those due to different tissue types tend to contain more high frequency information. ',...
'A more accurate estimate of a bias field can be obtained by including prior knowledge about ',...
'the distribution of the fields likely to be encountered by the correction algorithm. ',...
'For example, if it is known that there is little or no intensity non-uniformity, then it would be wise ',...
'to penalise large values for the intensity non-uniformity parameters. ',...
'This regularisation can be placed within a Bayesian context, whereby the penalty incurred is the negative ',...
'logarithm of a prior probability for any particular pattern of non-uniformity.'],...
['Knowing what works best should be a matter '...
'of empirical exploration.  For example, if your data has very little '...
'intensity non-uniformity artifact, then the bias regularisation should '...
'be increased.  This effectively tells the algorithm that there is very little '...
'bias in your data, so it does not try to model it.']};

%------------------------------------------------------------------------

biasfwhm    = mnu('Bias FWHM','biasfwhm',{...
'30mm cutoff','40mm cutoff','50mm cutoff','60mm cutoff','70mm cutoff',...
'80mm cutoff','90mm cutoff','100mm cutoff','110mm cutoff','120mm cutoff',...
'130mm cutoff','140mm cutoff','150mm cutoff','No correction'},...
{30,40,50,60,70,80,90,100,110,120,130,140,150,Inf});
biasfwhm.val  = {60};
biasfwhm.help = {[...
'FWHM of Gaussian smoothness of bias. ',...
'If your intensity non-uniformity is very smooth, then choose a large ',...
'FWHM. This will prevent the algorithm from trying to model out intensity variation ',...
'due to different tissue types. The model for intensity non-uniformity is one ',...
'of i.i.d. Gaussian noise that has been smoothed by some amount, ',...
'before taking the exponential. ',...
'Note also that smoother bias fields need fewer parameters to describe them. ',...
'This means that the algorithm is faster for smoother intensity non-uniformities.']};

%------------------------------------------------------------------------

biascor    = mnu('Save Bias Corrected','write',...
                {'Save Nothing','Save Bias Corrected',...
                 'Save Bias Field','Save Field and Corrected'},{[0 0],[0 1],[1 0],[1 1]});
biascor.val = {[0 0]};
biascor.help = {[...
'This is the option to save a bias corrected version of your images from this channel, or/and ',...
'the estimated bias field. ',...
'MR images are usually corrupted by a smooth, spatially varying artifact that modulates the intensity ',...
'of the image (bias). ',...
'These artifacts, although not usually a problem for visual inspection, can impede automated ',...
'processing of the images.  The bias corrected version should have more uniform intensities within ',...
'the different types of tissues.']};

%------------------------------------------------------------------------

channel = branch('Channel','channel',{vols,biasreg,biasfwhm,biascor});
channel.help = {[...
'A channel for processing. ',...
'If multiple channels are used (eg T1 & T2), then the same order ',...
'of subjects must be specified for each channel and they must be ',...
'in register (same position, size, voxel dims etc..).']};

%------------------------------------------------------------------------

data = repeat('Data','data',{channel});
data.num = [1 Inf];
data.val = {channel};
data.help = {[...
'Specify the number of different channels (for multi-spectral classification). ',...
'If you have scans of different contrasts for each of the subjects, then it is ',...
'possible to combine the information from them in order to improve the ',...
'segmentation accuracy. Note that only the first channel of data is used for the ',...
'initial affine registration with the tissue probability maps.']};

%------------------------------------------------------------------------

tpm = files('Tissue probability map','tpm','image',[1 1]);
tpm.help = {...
[...
'Select the tissue probability image for this class. '...
'These should be maps of eg grey matter, white matter ',...
'or cerebro-spinal fluid probability. '...
'A nonlinear deformation field is estimated that best overlays the '...
'tissue probability maps on the individual subjects'' image. '...
'The default tissue probability maps are modified versions of the '...
'ICBM Tissue Probabilistic Atlases.',...
'These tissue probability maps are kindly provided by the ',...
'International Consortium for Brain ',...
'Mapping, John C. Mazziotta and Arthur W. Toga. ',...
'http://www.loni.ucla.edu/ICBM/ICBM_TissueProb.html. ',...
'The original data are derived from 452 T1-weighted scans, ',...
'which were aligned with an atlas space, corrected for scan ',...
'inhomogeneities, and classified ',...
'into grey matter, white matter and cerebrospinal fluid. ',...
'These data were then affine registered to the MNI space and ',...
'downsampled to 2mm resolution.'],...
'',...
[...
'Rather than assuming stationary prior probabilities based upon mixing '...
'proportions, additional information is used, based on other subjects'' brain '...
'images.  Priors are usually generated by registering a large number of '...
'subjects together, assigning voxels to different tissue types and averaging '...
'tissue classes over subjects. '...
'Three tissue classes are used: grey matter, white matter and cerebro-spinal fluid. '...
'A fourth class is also used, which is simply one minus the sum of the first three. '...
'These maps give the prior probability of any voxel in a registered image '...
'being of any of the tissue classes - irrespective of its intensity.'],...
'',...
[...
'The model is refined further by allowing the tissue probability maps to be '...
'deformed according to a set of estimated parameters. '...
'This allows spatial normalisation and segmentation to be combined into '...
'the same model.']};

%------------------------------------------------------------------------

ngaus      = mnu('Num. Gaussians','ngaus',...
                 {'1','2','3','4','5','6','7','8'},...
                 { 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 });
ngaus.val  = {2};
ngaus.help = {[...
'The number of Gaussians used to represent the intensity distribution '...
'for each tissue class can be greater than one. '...
'In other words, a tissue probability map may be shared by several clusters. '...
'The assumption of a single Gaussian distribution for each class does not '...
'hold for a number of reasons. '...
'In particular, a voxel may not be purely of one tissue type, and instead '...
'contain signal from a number of different tissues (partial volume effects). '...
'Some partial volume voxels could fall at the interface between different '...
'classes, or they may fall in the middle of structures such as the thalamus, '...
'which may be considered as being either grey or white matter. '...
'Various other image segmentation approaches use additional clusters to '...
'model such partial volume effects. '...
'These generally assume that a pure tissue class has a Gaussian intensity '...
'distribution, whereas intensity distributions for partial volume voxels '...
'are broader, falling between the intensities of the pure classes. '...
'Unlike these partial volume segmentation approaches, the model adopted '...
'here simply assumes that the intensity distribution of each class may '...
'not be Gaussian, and assigns belonging probabilities according to these '...
'non-Gaussian distributions. '...
'Typical numbers of Gaussians could be two for grey matter, two for white '...
'matter, two for CSF, three for bone, four for other soft tissues and ',...
'two for air (background).']};

%------------------------------------------------------------------------
% SOME OPTIONS ARE UNUSED
native = mnu('Native Tissue','native',{...
    'None',...
    'Native Space',...
    'DARTEL Imported',...
    'Native + DARTEL Imported'},...
    {[0 0],[1 0],[0 1],[1 1]});
native.val = {[1 0]};

native = mnu('Native Tissue','native',{...
    'None',...
    'Native Space'},...
    {[0 0],[1 0]});
native.val = {[1 0]};

native.help  = {[...
'The native space option allows you to produce a tissue class image (c*) that ',...
'is in alignment with the original/* (see Figure \ref{seg1})*/. ',...
'It can also be used for "importing" into a form that can be used with DARTEL (rc*)']};

%------------------------------------------------------------------------

warped = mnu('Warped Tissue','warped',{...
    'None',...
    'Modulated',...
    'Unmodulated',...
    'Modulated + Unmodulated'},...
    {[0 0],[1 0],[0 1],[1 1]});
warped.val  = {[0 0]};
warped.help = {[...
'You can produce spatially normalised versions of the tissue class - ',...
'both with (mwc*) and without (wc*) modulation (see below). ',...
'These can be used for voxel-based morphometry. ',...
'All you need to do is smooth them and do the stats.'],...
'',...
[...
'Modulation is to compensate for the effect of spatial normalisation.  When warping a series ',...
'of images to match a template, it is inevitable that volumetric differences will be introduced ',...
'into the warped images.  For example, if one subject''s temporal lobe has half the volume of that of ',...
'the template, then its volume will be doubled during spatial normalisation. This will also ',...
'result in a doubling of the voxels labelled grey matter.  In order to remove this confound, the ',...
'spatially normalised grey matter (or other tissue class) is adjusted by multiplying by its relative ',...
'volume before and after warping.  If warping results in a region doubling its volume, then the ',...
'correction will halve the intensity of the tissue label. This whole procedure has the effect of preserving ',...
'the total amount of grey matter signal in the normalised partitions.  Actually, the warped data are not scaled ',...
'by the Jacobian determinants when generating the "modulated" data.  Instead, the original voxels are ',...
'projected into their new location in the warped images.  This exactly preserves the tissue count, but ',...
'has the effect of introducing aliasing artifacts - especially if the original data are at a lower resolution than ',...
'the warped images.  Smoothing should reduce this artifact though.']};
%------------------------------------------------------------------------

tissue  = branch('Tissue','tissue',{tpm,ngaus,native,warped});
tissues = repeat('Tissues','tissues',{tissue});

tpm_nam = fullfile(fileparts(which(mfilename)),'TPM.nii');
ngaus   = [2 2 2 3 4 2];
nval    = {[1 0],[1 0],[1 0],[1 0],[1 0],[0 0]};
for k=1:numel(ngaus),
    tissue.val{1}.val{1} = {[tpm_nam ',' num2str(k)]};
    tissue.val{2}.val    = {ngaus(k)};
    tissue.val{3}.val    = {nval{k}};
    tissues.val{k}       = tissue;
end

%------------------------------------------------------------------------

warpreg      = entry('Warping Regularisation','reg','e',[1 1]);
warpreg.val  = {4};
warpreg.help = {[...
'The objective function for registering the tissue probability maps to the ',...
'image to process, involves minimising the sum of two terms. ',...
'One term gives a function of how probable the data is given the warping parameters. ',...
'The other is a function of how probable the parameters are, and provides a ',...
'penalty for unlikely deformations. ',...
'Smoother deformations are deemed to be more probable. ',...
'The amount of regularisation determines the tradeoff between the terms. ',...
'Pick a value around one.  However, if your normalised images appear ',...
'distorted, then it may be an idea to increase the amount of ',...
'regularisation (by an order of magnitude). ',...
'More regularisation gives smoother deformations, ',...
'where the smoothness measure is determined by the bending energy of the deformations. ']};
%------------------------------------------------------------------------

affreg = mnu('Affine Regularisation','affreg',...
   {'No Affine Registration','ICBM space template - European brains',...
    'ICBM space template - East Asian brains', 'Average sized template','No regularisation'},...
   {'','mni','eastern','subj','none'});
affreg.val  = {'mni'};
affreg.help = {[...
'The procedure is a local optimisation, so it needs reasonable initial '...
'starting estimates. Images should be placed in approximate alignment '...
'using the Display function of SPM before beginning. '...
'A Mutual Information affine registration with the tissue '...
'probability maps (D''Agostino et al, 2004) is used to achieve '...
'approximate alignment. '...
'Note that this step does not include any model for intensity non-uniformity. '...
'This means that if the procedure is to be initialised with the affine '...
'registration, then the data should not be too corrupted with this artifact.'...
'If there is a lot of intensity non-uniformity, then manually position your '...
'image in order to achieve closer starting estimates, and turn off the '...
'affine registration.'],...
'',...
[...
'Affine registration into a standard space can be made more robust by ',...
'regularisation (penalising excessive stretching or shrinking).  The ',...
'best solutions can be obtained by knowing the approximate amount of ',...
'stretching that is needed (e.g. ICBM templates are slightly bigger ',...
'than typical brains, so greater zooms are likely to be needed). ',...
'For example, if registering to an image in ICBM/MNI space, then choose this ',...
'option.  If registering to a template that is close in size, then ',...
'select the appropriate option for this.']};

%------------------------------------------------------------------------

samp      = entry('Sampling distance','samp','e',[1 1]);
samp.val  = {3};
samp.help = {[...
'The approximate distance between sampled points when estimating the ',...
'model parameters. Smaller values use more of the data, but the procedure ',...
'is slower.']};

%------------------------------------------------------------------------

warps = mnu('Deformation Fields','write',{...
    'None',...
    'Inverse',...
    'Forward',...
    'Inverse + Forward'},...
    {[0 0],[1 0],[0 1],[1 1]});
warps.val  = {[0 0]};
warps.help = {'Deformation fields can be written.'};

%------------------------------------------------------------------------

bb      = entry('Bounding box','bb','e',[2 3]);
bb.val  = {ones(2,3)*NaN};
bb.help = {[...
'The bounding box (in mm) of any spatially normalised volumes to be written ',...
'(relative to the anterior commissure). '...
'Non-finite values will be replaced by the bounding box of the tissue '...
'probability maps used in the segmentation.']};

%------------------------------------------------------------------------

vox      = entry('Voxel size','vox','e',[1 1]);
vox.val  = {1.5};
vox.help = {...
['The (isotropic) voxel sizes of any spatially normalised written images. '...
 'A non-finite value will be replaced by the average voxel size of '...
 'the tissue probability maps used by the segmentation.']};

%------------------------------------------------------------------------
% SOME OPTIONS ARE NOT READY
%warping = branch('Warping','warp',{warpreg,affreg,samp,warps,bb,vox});
warping = branch('Warping','warp',{warpreg,affreg,samp,warps});

%------------------------------------------------------------------------
% UNUSED
msk = files('Masking image','msk','image',[0 1]);
msk.val = {''};
msk.help = {[...
'The segmentation can be masked by an image that conforms to ',...
'the same space as the images to be segmented.  If an image is selected, then ',...
'it must match the image(s) voxel-for voxel, and have the same ',...
'voxel-to-world mapping.  Regions containing a value of zero in this image ',...
'do not contribute when estimating the various parameters. ']};

%------------------------------------------------------------------------

%------------------------------------------------------------------------
% UNUSED
cleanup.tag  = 'cleanup';
cleanup.type = 'menu';
cleanup.name = 'Clean up any partitions';
cleanup.help = {[...
'This uses a crude routine for extracting the brain from segmented',...
'images.  It begins by taking the white matter, and eroding it a',...
'couple of times to get rid of any odd voxels.  The algorithm',...
'continues on to do conditional dilations for several iterations,',...
'where the condition is based upon gray or white matter being present.',...
'This identified region is then used to clean up the grey and white',...
'matter partitions, and has a slight influences on the CSF partition.'],'',[...
'If you find pieces of brain being chopped out in your data, then you ',...
'may wish to disable or tone down the cleanup procedure.']};
cleanup.labels = {'Dont do cleanup','Light Clean','Thorough Clean'};
cleanup.values = {0 1 2};
cleanup.val    = {0};

%------------------------------------------------------------------------

job        = branch('Segment','preproc8',{data,tissues,warping});
job.prog   = @execute;
%job.vfiles = @vfiles;
%job.check  = @check;
job.help   = {[...
'This toolbox is currently only work in progress, and is an extension of the default ',...
'unified segmentation.  The algorithm is essentially the same as that described in the ',...
'Unified Segmentation paper, except for (i) a slightly different treatment of the mixing ',...
'proportions, (ii) the use of an improved registration model, ',...
'(iii) the ability to use multi-spectral data, (iv) an extended set of ',...
'tissue probability maps, which allows a different treatment of voxels outside the brain. ',...
'Some of the options in the toolbox do not yet work, and it has not yet been seamlessly integrated ',...
'into the SPM8 software.  Also, the extended tissue probability maps need further refinement. ',...
'The current versions were crudely generated (by JA) using data that was kindly provided by ',...
'Cynthia Jongen of the Imaging Sciences Institute at Utrecht, NL.'],...
'',[...
'Segment, bias correct and spatially normalise - all in the same model/* \cite{ashburner05}*/. ',...
'This function can be used for bias correcting, spatially normalising ',...
'or segmenting your data.'],...
'',...
[...
'Many investigators use tools within older versions of SPM for '...
'a technique that has become known as "optimised" voxel-based '...
'morphometry (VBM). '...
'VBM performs region-wise volumetric comparisons among populations of subjects. '...
'It requires the images to be spatially normalised, segmented into '...
'different tissue classes, and smoothed, prior to performing '...
'statistical tests/* \cite{wright_vbm,am_vbmreview,ashburner00b,john_should}*/. The "optimised" pre-processing strategy '...
'involved spatially normalising subjects'' brain images to a '...
'standard space, by matching grey matter in these images, to '...
'a grey matter reference.  The historical motivation behind this '...
'approach was to reduce the confounding effects of non-brain (e.g. scalp) '...
'structural variability on the registration. '...
'Tissue classification in older versions of SPM required the images to be registered '...
'with tissue probability maps. After registration, these '...
'maps represented the prior probability of different tissue classes '...
'being found at each location in an image.  Bayes rule can '...
'then be used to combine these priors with tissue type probabilities '...
'derived from voxel intensities, to provide the posterior probability.'],...
'',...
[...
'This procedure was inherently circular, because the '...
'registration required an initial tissue classification, and the '...
'tissue classification requires an initial registration.  This circularity '...
'is resolved here by combining both components into a single '...
'generative model. This model also includes parameters that account '...
'for image intensity non-uniformity. '...
'Estimating the model parameters (for a maximum a posteriori solution) '...
'involves alternating among classification, bias correction and registration steps. '...
'This approach provides better results than simple serial applications of each component.']};

return;
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function execute(job)
spm_preproc_run(job);

function vf = vfiles(job)
vf = spm_preproc_run(job,'vfiles');

function msg = check(job)
msg = spm_preproc_run(job,'check');

