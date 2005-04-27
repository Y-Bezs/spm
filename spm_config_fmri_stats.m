function conf = spm_config_fmri_stats
% Configuration file for fmri statistics jobs
%_______________________________________________________________________
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

% Darren Gitelman and Will Penny
% $Id$


% Define inline types.
%-----------------------------------------------------------------------

entry = inline(['struct(''type'',''entry'',''name'',name,'...
    '''tag'',tag,''strtype'',strtype,''num'',num,''help'',hlp)'],...
    'name','tag','strtype','num','hlp');

files = inline(['struct(''type'',''files'',''name'',name,'...
    '''tag'',tag,''filter'',fltr,''num'',num,''help'',hlp)'],...
    'name','tag','fltr','num','hlp');

mnu = inline(['struct(''type'',''menu'',''name'',name,'...
    '''tag'',tag,''labels'',{labels},''values'',{values},''help'',hlp)'],...
    'name','tag','labels','values','hlp');

branch = inline(['struct(''type'',''branch'',''name'',name,'...
    '''tag'',tag,''val'',{val},''help'',hlp)'],...
    'name','tag','val','hlp');

repeat = inline(['struct(''type'',''repeat'',''name'',name,'...
    '''tag'',tag,''values'',{values},''help'',hlp)'],...
    'name','tag','values','hlp');

choice = inline(['struct(''type'',''choice'',''name'',name,'...
    '''tag'',tag,''values'',{values},''help'',hlp)'],...
    'name','tag','values','hlp');

%-----------------------------------------------------------------------

sp_text = ['                                                      ',...
      '                                                      '];
%-----------------------------------------------------------------------

onset   = entry('Onsets','onset','e',[Inf 1],'Vector of onsets');
p1 = 'Specify a vector of onset times for this trial/condition type.';
p2 = [...
  'With longs TRs you may want to shift the regressors so that they are ',...
  'aligned to a particular slice.  This is effected by resetting the ',...
  'values of defaults.stats.fmri.t and defaults.stats.fmri.t0 in ',...
  'spm_defaults. defaults.stats.fmri.t is the number of time-bins per ',...
  'scan used when building regressors.  Onsets are defined ',...
  'in temporal units of scans starting at 0.  defaults.stats.fmri.t0 is ',...
  'the first time-bin at which the regressors are resampled to coincide ',...
  'with data acquisition.  If defaults.stats.fmri.t0 = 1 then the ',...
  'regressors will be appropriate for the first slice.  If you want to ',...
  'temporally realign the regressors so that they match responses in the ',...
  'middle slice then make defaults.stats.fmri.t0 = ',...
  'defaults.stats.fmri.t/2 (assuming there is a negligible gap between ',...
  'volume acquisitions. Default values are defaults.stats.fmri.t = 16 ',...
  'and defaults.stats.fmri.t0 = 1.'];
onset.help = {p1,'','Slice Timing Information',p2};

%-------------------------------------------------------------------------

duration = entry('Durations','duration','e',[Inf 1],'Duration/s');
duration.help = [...
  'Specify the event durations (in seconds). Epoch and event-related ',...
  'responses are modeled in exactly the same way but by specifying their ',...
  'different durations.  Events are ',...
  'specified with a duration of 0.  If you enter a single number for the ',...
  'durations it will be assumed that all trials conform to this duration. ',...
  'If you have multiple different durations, then the number must match the ',...
  'number of onset times.'];

%-------------------------------------------------------------------------

time_mod = mnu('Time Modulation','tmod',...
    {'No Time Modulation','1st order Time Modulation',...
     '2nd order Time Modulation','3rd order Time Modulation',...
     '4th order Time Modulation','5th order Time Modulation',...
     '6th order Time Modulation'},...
    {0,1,2,3,4,5,6},'');
time_mod.val = {0};
p1 = [...
  'Model interractions with time?  This allows nonlinear effects over time ',...
  'to be modelled in the design matrix.  For example, 1st order modulation ',...
  'would model the stick functions and a linear change of the stick function ',...
  'heights over time. Higher order modulation will introduce further columns that ',...
  'contain the stick functions scaled by time squared, time cubed etc.'];
p2 = [...
  'Interactions or response modulations can enter at two levels.  Firstly ',...
  'the stick function itself can be modulated by some parametric variate ',...
  '(this can be time or some trial-specific variate like reaction time) ',...
  'modeling the interaction between the trial and the variate or, secondly ',...
  'interactions among the trials themselves can be modeled using a Volterra ',...
  'series formulation that accommodates interactions over time (and therefore ',...
  'within and between trial types).'];
time_mod.help = {p1,'',p2};

%-------------------------------------------------------------------------
%ply = mnu('Polynomial Expansion','poly',...
%    {'None','1st order','2nd order','3rd order','4th order','5th order','6th order'},...
%    {0,1,2,3,4,5,6},'Polynomial Order');
%ply.val = {0};
%-------------------------------------------------------------------------

name      = entry('Name','name','s', [1 Inf],'Name of parameter');
name.val  = {'Param'};
name.help = {'Enter a name for this parameter.'};

%-------------------------------------------------------------------------

param  = entry('Values','param','e',[Inf 1],'Parameter vector');
param.help = {'Enter a vector of values, one for each occurence of the event.'};

%-------------------------------------------------------------------------

ply = mnu('Polynomial Expansion','poly',...
    {'1st order','2nd order','3rd order','4th order','5th order','6th order'},...
    {1,2,3,4,5,6},'Polynomial Order');
ply.val = {1};
ply.help = {[...
  'For example, 1st order modulation ',...
  'would model the stick functions and a linear change of the stick function ',...
  'heights over different values of the parameter. Higher order modulation will ',...
  'introduce further columns that ',...
  'contain the stick functions scaled by parameter squared, cubed etc.']};

%-------------------------------------------------------------------------

pother = branch('Parameter','mod',{name,param,ply},'Custom parameter');
p1 = [...
  'Model interractions with user specified parameters. ',...
  'This allows nonlinear effects relating to some other measure ',...
  'to be modelled in the design matrix.'];
p2 = [...
  'Interactions or response modulations can enter at two levels.  Firstly ',...
  'the stick function itself can be modulated by some parametric variate ',...
  '(this can be time or some trial-specific variate like reaction time) ',...
  'modeling the interaction between the trial and the variate or, secondly ',...
  'interactions among the trials themselves can be modeled using a Volterra ',...
  'series formulation that accommodates interactions over time (and therefore ',...
  'within and between trial types).'];
pother.help = {p1,'',p2};

%-------------------------------------------------------------------------
mod      = repeat('Parametric Modulations','mod',{pother},'');
mod.help = {[...
  'The stick function itself can be modulated by some parametric variate ',...
  '(this can be time or some trial-specific variate like reaction time) ',...
  'modeling the interaction between the trial and the variate. ',...
  'The events can be modulated by zero or more parameters.']};

%-------------------------------------------------------------------------

name     = entry('Name','name','s',[1 Inf],'Condition Name');
name.val = {'Trial'};

%-------------------------------------------------------------------------

cond  = branch('Condition/Trial','cond',{name,onset,duration,time_mod,mod},...
    'Condition/Trial');
cond.check = @cond_check;
cond.help = {[...
  'An array of input functions is contructed, ',...
  'specifying occurrence events or epochs (or both). ',...
  'These are convolved with a basis set at a later stage to give ',...
  'regressors that enter into the design matrix. Interactions of evoked ',...
  'responses with some parameter (time or a specified variate) enter at ',...
  'this stage as additional columns in the design matrix with each trial multiplied ',...
  'by the [expansion of the] trial-specific parameter. ',...
  'The 0th order expansion is simply the main effect in the first column.']};

%-------------------------------------------------------------------------

conditions = repeat('Conditions/Trials','condrpt',{cond},'Conditions');
conditions.help = {[...
  'You are allowed to combine both event- and epoch-related ',...
  'responses in the same model and/or regressor. Any number ',...
  'of trial (event or epoch) types can be specified.  Epoch and event-related ',...
  'responses are modeled in exactly the same way by specifying their ',...
  'onsets [in terms of onset times] and their durations.  Events are ',...
  'specified with a duration of 0.  If you enter a single number for the ',...
  'durations it will be assumed that all trials conform to this duration.']};

%-------------------------------------------------------------------------

name     = entry('Name','name','s',[1 Inf],'Regressor Name');
name.val = {'Regressor'};

%-------------------------------------------------------------------------

val      = entry('Value','val','e',[Inf 1],'Param Value');

%-------------------------------------------------------------------------

regress  = branch('Regressor','regress',{name,val},'regressor');
regressors = repeat('Regressors','regress',{regress},'Regressors');
regressors.help = {[...
  'Regressors are additional columns included in the design matrix, ',...
  'which may model effects that would not be convolved with the ',...
  'haemodynamic response.  One such example would be the estimated movement ',...
  'parameters, which may confound the data.']};

%-------------------------------------------------------------------------

scans    = files('Scans','scans','image',[1 Inf],'Select scans');
scans.help = {[...
'Select the scans for this session.  Note that they all need to have the same ',...
'image dimensions, orientation, voxel size etc.']};

%-------------------------------------------------------------------------

hpf      = entry('High-pass filter','hpf','e',[1 1],'');
hpf.val  = {Inf};
hpf.help = {[...
    'High-pass filtering is implemented at the level of the ',...
    'filtering matrix K (as opposed to entering as confounds in the design ',...
    'matrix).  The default cutoff period is 128 seconds.  Use ''explore design'' ',...
    'to ensure this cuttof is not removing too much experimental variance. ',...
    'Note that high-pass filtering uses a residual forming matrix (i.e. ',...
    'it is not a convolution) and is simply to a way to remove confounds ',...
    'without estimating their parameters explicitly.  The constant term ',...
    'is also incorportated into this filter matrix.']};

%-------------------------------------------------------------------------

sess  = branch('Subject/Session','sess',{scans,conditions,regressors,hpf},'Session');
sess.check = @sess_check;
p1 = [...
'The design matrix for fMRI data consists of one or more seperable, ',...
'session-specific partitions.  These partitions are usually either one per ',...
'subject, or one per fMRI scanning session for that subject.'];
sess.help = {p1};

%-------------------------------------------------------------------------

block = repeat('Data & Design','blocks',{sess},'');
p1 = [...
  'The design matrix defines the experimental design and the nature of ',...
  'hypothesis testing to be implemented.  The design matrix has one row ',...
  'for each scan and one column for each effect or explanatory variable. ',...
  '(e.g. regressor or stimulus function).  The parameters are estimated ',...
  'using Bayesian or Restricted Maximum Likelihood algorithms.  Specific profiles ',...
  'within these parameters are tested using a linear compound or contrast ',...
  'with the T or F statistic. '];
p2 = [...
  'This allows you to build design matrices with separable ',...
  'session-specific partitions.  Each partition may be the same (in which ',...
  'case it is only necessary to specify it once) or different.  Responses ',...
  'can be either event- or epoch related, where the latter model prolonged ',...
  'and possibly time-varying responses to state-related changes in ',...
  'experimental conditions.  Event-related response are modelled in terms ',...
  'of responses to instantaneous events.  Mathematically they are both ',...
  'modelled by convolving a series of delta (stick) or box-car functions, ',...
  'encoding the input or stimulus function. with a set of hemodynamic ',...
  'basis functions.'];
block.help = {'Specify the Data and Design','',p1,'',p2};

% Specification of factorial designs

fname.type    = 'entry';
fname.name    = 'Name';
fname.tag     = 'name';
fname.strtype = 's';
fname.num     = [1 1];
fname.help    = {'Name of factor'};

levels = entry('Levels','levels','e',[Inf 1],''); 
levels.val = {2};
p1=['Enter number of levels for this factor'];
levels.help ={p1};

factor.type   = 'branch';
factor.name   = 'Factor';
factor.tag    = 'fact';
factor.val    = {fname,levels};
factor.help = {'Add a new factor to your experimental design'};

factors.type = 'repeat';
factors.name = 'Factorial design';
factors.tag  = 'factors';
factors.values = {factor};
p1 = ['If you have a factorial design then SPM can automatically generate ',...
      'the contrasts necessary to test for the main effects and interactions.'];
p2 = ['This includes the models/F-contrasts necessary to test for these effects at ',...
      'the within-subject level (first level) and the simple contrasts necessary ',...
      'to generate the contrast images for a between-subject (second-level) ',...
      'analysis.'];
p3 = ['To use this option you should know that the conditions are numbered ',...
      'in the order you enter them. You should also write down the contingency ',...
      'table for your design. The table relates the levels of each factor to the ',...
      ' conditions. If you have C conditions and a k1-by-k2 design ',...
      ' your contingency table is given by the transpose of reshape([1:1:C],k2,k1) ',...
      ' (try entering this at the matlab command prompt). The ',...
      'levels of the first factor are then given by the rows, and the levels of ',...
      'the second factor by the columns.'];
  
factors.help ={p1,sp_text,p2,sp_text,p3};
    
%-------------------------------------------------------------------------

rt       = entry('Interscan interval','RT','e',[1 1],'Interscan interval {secs}');
rt.help = {[...
'Interscan interval {secs}.  This is the time between acquiring a plane of one volume ',...
'and the same plane in the next volume.  It is assumed to be constant throughout.']};

%-------------------------------------------------------------------------

units    = mnu('Units for design spec','units',{'Scans','Seconds'},{'scans','secs'},'');
units.help = {'Units for design spec.'};

%-------------------------------------------------------------------------

glob  = mnu('Global normalisation','global',...
    {'Scaling','None'},{'Scaling','None'},{'Global intensity normalisation'});
glob.val={'None'};

%-------------------------------------------------------------------------

cvi   = mnu('Serial correlations','cvi',{'none','AR(1)'},{'none','AR(1)'},...
    {'Correct for serial correlations'});
cvi.val={'AR(1)'};
p1 = [...
    'Serial correlations in fast fMRI time-series are dealt with as ',...
    'described in spm_spm.  At this stage you need to specify the filtering ',...
    'that will be applied to the data (and design matrix) to give a ',...
    'generalized least squares (GLS) estimate of the parameters required. ',...
    'This filtering is important to ensure that the GLS estimate is ',...
    'efficient and that the error variance is estimated in an unbiased way.'];
p2 = ['                                                      ',...
      '                                                      '];
p3 = [...
    'The serial correlations will be estimated with a ReML (restricted ',...
    'maximum likelihood) algorithm using an autoregressive AR(1) plus ',...
    ' white noise model during parameter estimation.  This estimate assumes the same ',...
    'correlation structure for each voxel, within each session.  The ReML ',...
    'estimates are then used to correct for non-sphericity during inference ',...
    'by adjusting the statistics and degrees of freedom appropriately.  The ',...
    'discrepancy between estimated and actual intrinsic (i.e. prior to ',...
    'filtering) correlations are greatest at low frequencies.  Therefore ',...
    'specification of the high-pass filter is particularly important.'];
cvi.help = {p1,p2,p3};
 
% Bayesian estimation over slices or whole volume ?

slices  = entry('Slices','Slices','e',[Inf 1],'Enter Slice Numbers');

volume  = struct('type','const','name','Volume','tag','Volume','val',{{1}});
p1=['You have selected the Volume option. SPM will analyse fMRI ',...
    'time series in all slices of each volume.'];
volume.help={p1};

space   = choice('Analysis Space','space',{volume,slices},'Analyse whole volume or selected slices only');
space.val={volume};

% Regression coefficient  priors for Bayesian estimation

w_prior  = mnu('Signal priors','signal',{'GMRF','LORETA','Global','Uninformative'},...
    {'GMRF','LORETA','Global','Uninformative'},{'Signal priors'});
w_prior.val={'GMRF'};
p1=['[GMRF] = Gaussian Markov Random Field. This spatial prior is the recommended option. '];
p2=['[LORETA] = Low resolution Tomography Prior. This spatial prior is popular in the EEG world. '];
p3=['[Global] = Global Shrinkage prior. This is not a spatial prior.'];
p4=['[Uninformative] = A flat prior. Essentially, no prior information is used. '];
w_prior.help={p1,p2,p3,p4};

% AR model order for Bayesian estimation

arp   = entry('AR model order','ARP','e',[Inf 1],'Enter AR model order');
arp.val={3};
p1=['An AR model order of 3 is recommended'];
arp.help={p1};

% AR coefficient  priors for Bayesian estimation

a_gmrf = struct('type','const','name','GMRF','tag','GMRF','val',{{1}});
a_loreta = struct('type','const','name','LORETA','tag','LORETA','val',{{1}});
a_tissue_type = files('Tissue-type','tissue_type','image',[1 Inf],'Select tissue-type images');
p1=['Select files that specify tissue types. These are typically chosen to be ',...
    'Grey Matter, White Matter and CSF images derived from segmentation of ',...
    'registered structural scans.'];
a_tissue_type.help={p1};
a_prior = choice('Noise priors','noise',{a_gmrf,a_loreta,a_tissue_type},'Noise priors');
a_prior.val={a_gmrf};
p1=['[GMRF] = Gaussian Markov Random Field. This spatial prior is the recommended option. '];
p2=['[LORETA] = Low resolution Tomography Prior. This spatial prior is popular in the EEG world. '];
p3=['[Tissue-type] = AR estimates at each voxel are biased towards typical ',...
    'values for that tissue type. '];
a_prior.help={p1,p2,p3};

% ANOVA options

first  = mnu('First level','first',...
    {'No','Yes'},{'No','Yes'},{''});
first.val={'No'};
p1=['[First level ANOVA ?] '];
p2=['This is implemented using Bayesian model comparison. ',...
    'This requires explicit fitting of several models at each voxel and is ',...
    'computationally demanding (requiring several hours of computation). ',...
    'The recommended option is therefore NO.'];
p3=['To use this option you must also specify your Factorial design (see options ',...
    'under FMRI Stats).'];
first.help={p1,sp_text,p2,sp_text,p3};

second  = mnu('Second level','second',...
    {'No','Yes'},{'No','Yes'},{''});
second.val={'Yes'};
p1=['[Second level ANOVA ?] '];
p2=['This option tells SPM to automatically generate ',...
    'the simple contrasts that are necessary to produce the contrast images ',...
    'for a second-level (between-subject) ANOVA. With the Bayesian estimation ',...
    'option it is recommended that contrasts are computed during the parameter ',...
    'estimation stage (see HELP for Simple contrasts). ',...
    'The recommended option here is therefore YES.'];
p3=['To use this option you must also specify your Factorial design (see options ',...
    'under FMRI Stats).'];
second.help={p1,sp_text,p2,sp_text,p3};

anova.type   = 'branch';
anova.name   = 'ANOVA';
anova.tag    = 'anova';
anova.val    = {first,second};
anova.help = {'Perform 1st or 2nd level ANOVAs'};

% Contrasts to be computed during Bayesian estimation

name.type    = 'entry';
name.name    = 'Name';
name.tag     = 'name';
name.strtype = 's';
name.num     = [1 1];
name.help    = {'Name of contrast'};

gconvec.type    = 'entry';
gconvec.name    = 'Contrast vector';
gconvec.tag     = 'convec';
gconvec.strtype = 's';
gconvec.num     = [1 1];
gconvec.help    = {''};
            
gcon.type   = 'branch';
gcon.name   = 'Simple contrast';
gcon.tag    = 'gcon';
gcon.val    = {name,gconvec};
gcon.help = {''};
            
contrast.type = 'repeat';
contrast.name = 'Simple contrasts';
contrast.tag  = 'contrasts';
contrast.values = {gcon};
p1 =['Specify simple one-dimensional contrasts'];
p2 =['If you have a factoral design then the contrasts needed to generate ',...
     'the contrast images for a 2nd-level ANOVA can be specified automatically ',...
     'using the ANOVA->Second level option.'];
p3 =['When using the Bayesian estimation option it is computationally more ',...
     'efficient to compute the contrasts when the parameters are estimated. ',...
     'This is because estimated parameter vectors have potentially different ',...
     'posterior covariance matrices at different voxels ',...
     'and these matrices are not stored. If you compute contrasts ',...
     'post-hoc these matrices must be recomputed (an approximate reconstruction ',...
     'based on a Taylor series expansion is used). ',...
     'It is therefore recommended to specify as many contrasts as possible ',...
     'prior to parameter estimation.'];
contrast.help={p1,sp_text,p2,sp_text,p3};



% Bayesian estimation

est_bayes = branch('Bayesian','Bayesian',{space,w_prior,arp,a_prior,anova,contrast},'Bayesian Estimation');
bayes_1 = ['[Bayesian] - model parameters are estimated using Variational Bayes. ',...
     'This allows you to specify spatial priors for regression coefficients ',...
     'and regularised voxel-wise AR(P) models for fMRI noise processes. ',...
     'The algorithm does not require functional images to be spatially smoothed. ',...
     'Estimation will take about 5 times longer than with the classical approach.' ];
bayes_2 = ['After estimation, contrasts are used to find regions with effects larger ',...
      'than a user-specified size eg. 1 per cent of the global mean signal. ',...
      'These effects are assessed statistically using a Posterior Probability Map (PPM).'];
est_bayes.help={bayes_1,sp_text,bayes_2};

% Classical (ReML) estimation

est_class = branch('Classical','Classical',{cvi},{'Classical Estimation'});
classical_1 =['[Classical] - model parameters are estimated using Restricted Maximum ',...
     'Likelihood (ReML). This assumes the error correlation structure is the ',...
     'same at each voxel. This correlation can be specified using an ',...
     'AR(1) plus white noise model. The algorithm should be applied to spatially ',...
     'smoothed functional images.'];
classical_2 = ['After estimation, specific profiles of parameters are tested using a linear ',...
      'compound or contrast with the T or F statistic. The resulting statistical map ',...
      'constitutes an SPM. The SPM{T}/{F} is then characterised in terms of ',...
      'focal or regional differences by assuming that (under the null hypothesis) ',...
      'the components of the SPM (ie. residual fields) behave as smooth stationary ',...
      'Gaussian fields.'];
est_class.help={classical_1,sp_text,classical_2};

% Select method of estimation - Bayesian or classical

meth   = choice('Method','Method',{est_class,est_bayes},{'Type of estimation procedure'});
meth.val={est_class};
p1 = [...
     'Estimation procedure:'];

meth.help={classical_1,sp_text,classical_2,sp_text,bayes_1,sp_text,bayes_2};

% Select when to estimate model

when   = mnu('Execution','when',{'At Run Time','Later'},{'At Run Time','Later'},...
    {'Specify when estimation will take place'});
when.val={'At Run Time'};
p1 = ['Estimate this model:'];
p2 = ['                                                      ',...
      '                                                        '];

p3 =['At Run Time - ie. when you press the RUN button or run the script ',...
     'using spm_jobman'];
p4 = ['Later - at some point later on. When you run this batch job SPM ',...
     'will only create the design matrix and assign data to it. This allows '...
     'you to visually inspect the design (using the Review Design button)',...
     'to make sure you have got it right'];
when.help={p1,p2,p3,p2,p4};

% Specify estimation procedure

estim   = branch('Estimation','estim',{when,meth},{'Specify estimation procedure'});
p1 = ['These options allow you to specify when parameters will be ',...
      'estimated and what method will be used (Bayesian or Classical).'];
estim.help={p1};

%-----------------------------------------------------------------------

% These are currently unused
%hrfpar = entry('Parameters','params','e',[1 7],'HRF Parameters');
%hrfpar.val = {[6 16 1 1 6 0 32]};
%hrfpar.help = {...
%    'The parameters are:',...
%    '   p(1) - delay of response (relative to onset)       6',...
%    '   p(2) - delay of undershoot (relative to onset)    16',...
%    '   p(3) - dispersion of response                      1',...
%    '   p(4) - dispersion of undershoot                    1',...
%    '   p(5) - ratio of response to undershoot             6',...
%    '   p(6) - onset (seconds)                             0',...
%    '   p(7) - length of kernel (seconds)                 32'};

%-------------------------------------------------------------------------

derivs = mnu('Model derivatives','derivs',...
    {'No derivatives', 'Time derivatives', 'Time and Dispersion derivatives'},...
    {[0 0],[1 0],[1 1]},'Model HRF Derivatives');
derivs.val = {[0 0]};
derivs.help = {[...
'Model HRF Derivatives.  Modelling time and dispersion derivatives is recommended ',...
'if you plan to use a second level analyses of event related fMRI.']}; 

%-------------------------------------------------------------------------

hrf   = branch('Canonical HRF','hrf',{derivs},'Canonical Heamodynamic Response Function');
hrf.help = {[...
'Canonical Heamodynamic Response Function - Useful if (i) you wish to use a SPM{T} to ',...
'look separately at activations and deactivations or (ii) you wish to proceed to a second ',...
'(random-effect) level of analysis. ',...
'Unlike other bases, contrasts of these effects have a physical interpretation ',...
'and represent a parsimonious way of characterising event-related ',...
'responses.']};

%-------------------------------------------------------------------------

len   = entry('Window length','length','e',[1 1],'window length {secs}');
order = entry('Order','order','e',[1 1],'order');
o1    = branch('Fourier Set','fourier',{len,order},'');
o1.help = {'Fourier basis functions - requires SPM{F} for inference.'};
o2    = branch('Fourier Set (Hanning)','fourier_han',{len,order},'');
o2.help = {'Fourier basis functions with Hanning Window - requires SPM{F} for inference.'};
o3    = branch('Gamma Functions','gamma',{len,order},'');
o3.help = {'Gamma basis functions - requires SPM{F} for inference.'};
o4    = branch('Finite Impulse Response','fir',{len,order},'');
o4.help = {'Finite impulse response - requires SPM{F} for inference.'};

%-------------------------------------------------------------------------

bases = choice('Basis Functions','bases',{hrf,o1,o2,o3,o4},'');
bases.val = {hrf};
bases.help = {[...
    'The choice of basis functions depends upon the nature of the inference ',...
    'sought.  One important consideration is whether you want to make ',...
    'inferences about compounds of parameters (i.e.  contrasts).  This is ',...
    'the case if (i) you wish to use a SPM{T} to look separately at ',...
    'activations and deactivations or (ii) you wish to proceed to a second ',...
    '(random-effect) level of analysis.  If this is the case then (for ',...
    'event-related studies) use a canonical hemodynamic response function ',...
    '(HRF) and derivatives with respect to latency (and dispersion).  Unlike ',...
    'other bases, contrasts of these effects have a physical interpretation ',...
    'and represent a parsimonious way of characterising event-related ',...
    'responses.  Bases such as a Fourier set require the SPM{F} for ',...
    'inference.']};
%-------------------------------------------------------------------------

volt  = mnu('Model Interactions (Volterra)','volt',{'Do not model Interractions','Model Interractions'},{1,2},'');
volt.val = {1};
p1 = ['Generalized convolution of inputs (U) with basis set (bf).'];
p2 = [...
  'For first order expansions the causes are simply convolved ',...
  '(e.g. stick functions) in U.u by the basis functions in bf to create ',...
  'a design matrix X.  For second order expansions new entries appear ',...
  'in ind, bf and name that correspond to the interaction among the ',...
  'orginal causes. The basis functions for these efects are two dimensional ',...
  'and are used to assemble the second order kernel in spm_graph.m. ',...
  'Second order effects are computed for only the first column of U.u.'];
p3 = [...
  'Interactions or response modulations can enter at two levels.  Firstly ',...
  'the stick function itself can be modulated by some parametric variate ',...
  '(this can be time or some trial-specific variate like reaction time) ',...
  'modeling the interaction between the trial and the variate or, secondly ',...
  'interactions among the trials themselves can be modeled using a Volterra ',...
  'series formulation that accommodates interactions over time (and therefore ',...
  'within and between trial types).'];
volt.help = {p1,'',p2,p3};

%-------------------------------------------------------------------------

mask = files('Explicit mask','mask','image',[0 1],'Image mask');
mask.val = {''};
p1=['Specify an image for explicitly masking the analysis. ',...
 'A sensible option here is to use a segmention of structural images ',...
 'to specify a within-brain mask. If you select that image as an ',...
 'explicit mask then only those voxels in the brain will be analysed. ',...
 'This both speeds the estimation and restricts SPMs/PPMs to within-brain ',...
 'voxels. Alternatively, if such structural images are unavailble or no ',...
 'masking is required, then leave this field empty.'];
mask.help={p1};

%-------------------------------------------------------------------------

cdir = files('Directory','dir','dir',1,'');
cdir.help = {[...
'Select an analysis directory to change to. ',...
'This is where the results of the statistics will be written.']};

%-------------------------------------------------------------------------

% conf = branch('FMRI Stats','fmri_stats',...
%     {block,bases,volt,cdir,rt,units,glob,cvi,mask},'fMRI design');

conf = branch('FMRI Stats','fmri_stats',...
    {units,block,factors,bases,volt,cdir,rt,glob,mask,estim},'fMRI design');
conf.prog   = @run_stats;
conf.vfiles = @vfiles_stats;
conf.check  = @check_dir;
conf.modality = {'FMRI'};
p1 = [...
  'This configures the design matrix, data specification and ',...
  'filtering that specify the ensuing statistical analysis. These ',...
  'arguments are passed to spm_spm that then performs the actual parameter ',...
  'estimation.'];
p2 = [...
  'The design matrix defines the experimental design and the nature of ',...
  'hypothesis testing to be implemented.  The design matrix has one row ',...
  'for each scan and one column for each effect or explanatory variable. ',...
  '(e.g. regressor or stimulus function).  The parameters are estimated using ',...
  'Bayesian or Restricted Maximum Likelihood algorithms. Specific profiles ',...
  'within these parameters are tested using a linear compound or contrast ',...
  'with the T or F statistic. '];
p3 = [...
  'You (i) specify a statistical model in terms ',...
  'of a design matrix, (ii) associate some data with a pre-specified design ',...
  '[or (iii) specify both the data and design] and then proceed to estimate ',...
  'the parameters of the model. ',...
  'Inferences can be made about the ensuing parameter estimates (at a first ',...
  'or fixed-effect level) in the results section, or they can be re-entered ',...
  'into a second (random-effect) level analysis by treating the session or ',...
  'subject-specific [contrasts of] parameter estimates as new summary data. ',...
  'Inferences at any level obtain by specifying appropriate T or F contrasts ',...
  'in the results section to produce SPMs/PPMs and tables of statistics.'];
p4 = [...
  'You can build design matrices with separable ',...
  'session-specific partitions.  Each partition may be the same (in which ',...
  'case it is only necessary to specify it once) or different.  Responses ',...
  'can be either event- or epoch related, The only distinction is the duration ',...
  'of the underlying input or stimulus function. Mathematically they are both ',...
  'modeled by convolving a series of delta (stick) or box functions (u), ',...
  'indicating the onset of an event or epoch with a set of basis ',...
  'functions.  These basis functions model the hemodynamic convolution, ',...
  'applied by the brain, to the inputs.  This convolution can be first-order ',...
  'or a generalized convolution modeled to second order (if you specify the ',...
  'Volterra option). [The same inputs are used by the hemodynamic model or ',...
  'or dynamic causal models which model the convolution explicitly in terms of ',...
  'hidden state variables (see spm_hdm_ui and spm_dcm_ui).] ',...
  'Basis functions can be used to plot estimated responses to single events ',...
  'once the parameters (i.e. basis function coefficients) have ',...
  'been estimated.  The importance of basis functions is that they provide ',...
  'a graceful transition between simple fixed response models (like the ',...
  'box-car) and finite impulse response (FIR) models, where there is one ',...
  'basis function for each scan following an event or epoch onset.  The ',...
  'nice thing about basis functions, compared to FIR models, is that data ',...
  'sampling and stimulus presentation does not have to be synchronized ',...
  'thereby allowing a uniform and unbiased sampling of peri-stimulus time.'];
p5 = [...
  'Event-related designs may be stochastic or deterministic.  Stochastic ',...
  'designs involve one of a number of trial-types occurring with a ',...
  'specified probably at successive intervals in time.  These ',...
  'probabilities can be fixed (stationary designs) or time-dependent ',...
  '(modulated or non-stationary designs).  The most efficient designs ',...
  'obtain when the probabilities of every trial type are equal. ',...
  'A critical issue in stochastic designs is whether to include null events ',...
  'If you wish to estimate the evoke response to a specific event ',...
  'type (as opposed to differential responses) then a null event must be ',...
  'included (even if it is not modeled explicitly).'];
r1 = [...
  '  * Friston KJ, Holmes A, Poline J-B, Grasby PJ, Williams SCR, Frackowiak ',...
  'RSJ & Turner R (1995) Analysis of fMRI time-series revisited. NeuroImage ',...
  '2:45-53'];
r2 = [...
  '  * Worsley KJ and Friston KJ (1995) Analysis of fMRI time-series revisited - ',...
  'again. NeuroImage 2:178-181'];
r3 = [...
  '  * Friston KJ, Frith CD, Frackowiak RSJ, & Turner R (1995) Characterising ',...
  'dynamic brain responses with fMRI: A multivariate approach NeuroImage - ',...
  '2:166-172'];
r4 = [...
  '  * Frith CD, Turner R & Frackowiak RSJ (1995) Characterising evoked ',...
  'hemodynamics with fMRI Friston KJ, NeuroImage 2:157-165'];
r5 = [...
  '  * Josephs O, Turner R and Friston KJ (1997) Event-related fMRI, Hum. Brain ',...
  'Map. 0:00-00'];
conf.help = {'fMRI Statistics','',p1,'',p2,'',p3,'',p4,'',p5,...
             '','Referencess:',r1,'',r2,'',r3,'',r4,'',r5};

return;
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------

function t = check_dir(job)
t = {};
%d = pwd;
%try,
%    cd(job.dir{1});
%catch,
%    t = {['Cannot Change to directory "' job.dir{1} '".']};
%end;

%disp('Checking...');
%disp(fullfile(job.dir{1},'SPM.mat'));

% Should really include a check for a "virtual" SPM.mat
if exist(fullfile(job.dir{1},'SPM.mat'),'file'),
    t = {'SPM files exist in the analysis directory.'};
end;
return;
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------

function t = cond_check(job)
t   = {};
if (numel(job.onset) ~= numel(job.duration)) && (numel(job.duration)~=1),
    t = {sprintf('"%s": Number of event onsets (%d) does not match the number of durations (%d).',...
        job.name, numel(job.onset),numel(job.duration))};
end;
for i=1:numel(job.mod),
    if numel(job.onset) ~= numel(job.mod(i).param),
        t = {t{:}, sprintf('"%s" & "%s":Number of event onsets (%d) does not equal the number of parameters (%d).',...
            job.name, job.mod(i).name, numel(job.onset),numel(job.mod(i).param))};
    end;
end;
return;
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------

function t = sess_check(sess)
t = {};
for i=1:numel(sess.regress),
    if numel(sess.scans) ~= numel(sess.regress(i).val),
        t = {t{:}, sprintf('Num scans (%d) ~= Num regress[%d] (%d).',numel(sess.scans),i,numel(sess.regress(i).val))};
    end;
end;
return;
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function my_cd(varargin)
job = varargin{1};
if ~isempty(job)
    try
    cd(char(job));
    fprintf('Changing directory to: %s\n',char(job));
    catch
        error('Failed to change directory. Aborting run.')
    end
end
return;
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function run_stats(job)
% Set up the design matrix and run a design.

spm_defaults;
global defaults
defaults.modality='FMRI';

original_dir = pwd;
my_cd(job.dir);

% If we've gotten to this point we're committed to overwriting files.
% Delete them so we don't get stuck in spm_spm
%------------------------------------------------------------------------
files = {'mask.???','ResMS.???','RVP.???',...
    'beta_????.???','con_????.???','ResI_????.???',...
    'ess_????.???', 'spm?_????.???'};
for i=1:numel(files),
    if any(files{i} == '*' | files{i} == '?')
        [j,unused] = spm_list_files(pwd,files{i});
        for i=1:size(j,1),
            spm_unlink(deblank(j(i,:)));
        end
    else
        spm_unlink(files{i});
    end
end


% Variables
%-------------------------------------------------------------
SPM.xY.RT = job.RT;
SPM.xY.P = [];

% Basis function variables
%-------------------------------------------------------------
SPM.xBF.UNITS = job.units;
SPM.xBF.dt    = job.RT/defaults.stats.fmri.t;
SPM.xBF.T     = defaults.stats.fmri.t;
SPM.xBF.T0    = defaults.stats.fmri.t0;

% Basis functions
%-------------------------------------------------------------
if strcmp(fieldnames(job.bases),'hrf')
    if all(job.bases.hrf.derivs == [0 0])
        SPM.xBF.name = 'hrf';
    elseif all(job.bases.hrf.derivs == [1 0])
        SPM.xBF.name = 'hrf (with time derivative)';
    elseif all(job.bases.hrf.derivs == [1 1])
        SPM.xBF.name = 'hrf (with time and dispersion derivatives)';
    else
        error('Unrecognized hrf derivative choices.')
    end
else
    nambase = fieldnames(job.bases);
    if ischar(nambase)
        nam=nambase;
    else
        nam=nambase{1};
    end
    switch nam,
        case 'fourier',
            SPM.xBF.name = 'Fourier set';
        case 'fourier_han', 
            SPM.xBF.name = 'Fourier set (Hanning)';
        case 'gamma',
            SPM.xBF.name = 'Gamma functions';
        case 'fir',
            SPM.xBF.name = 'Finite Impulse Response';
        otherwise
            error('Unrecognized hrf derivative choices.')
    end
    SPM.xBF.length = job.bases.(nam).length;
    SPM.xBF.order  = job.bases.(nam).order;
end
SPM.xBF          = spm_get_bf(SPM.xBF);
if isempty(job.sess),
    SPM.xBF.Volterra = false;
else
    SPM.xBF.Volterra = job.volt;
end;

for i = 1:numel(job.sess),
    sess = job.sess(i);

    % Image filenames
    %-------------------------------------------------------------
    SPM.nscan(i) = size(sess.scans,1);
    SPM.xY.P     = strvcat(SPM.xY.P,sess.scans{:});

    U = [];

    % Configure the input structure array
    %-------------------------------------------------------------
    for j = 1:length(sess.cond),
        cond      = sess.cond(j);
        U(j).name = {cond.name};
        U(j).ons  = cond.onset(:);
        U(j).dur  = cond.duration(:);
        if length(U(j).dur) == 1
            U(j).dur    = U(j).dur*ones(size(U(j).ons));
        elseif length(U(j).dur) ~= length(U(j).ons)
            error('Mismatch between number of onset and number of durations.')
        end

        P  = [];
        q1 = 0;
        if cond.tmod>0,
            % time effects
            P(1).name = 'time';
            P(1).P    = U(j).ons*RT;
            P(1).h    = cond.tmod;
            q1        = 1;
        end;
        for q = 1:numel(cond.mod),
            % Parametric effects
            q1 = q1 + 1;
            P(q1).name = cond.mod(q).name;
            P(q1).P    = cond.mod(q).param;
            P(q1).h    = cond.mod(q).poly;
        end;
        if isempty(P)
            P.name = 'none';
            P.h    = 0;
        end
        U(j).P = P;

    end

    SPM.Sess(i).U = U;


    % User specified regressors
    %-------------------------------------------------------------
    C = [];
    Cname = cell(1,numel(sess.regress));
    for q = 1:numel(sess.regress),
        Cname{q} = sess.regress(q).name;
        C         = [C, sess.regress(q).val(:)];
    end
    SPM.Sess(i).C.C    = C;
    SPM.Sess(i).C.name = Cname;

end

% Factorial design
%-------------------------------------------------------------
if isfield(job,'fact')
    NC=length(SPM.Sess(1).U); % Number of conditions
    CheckNC=1;
    for i=1:length(job.fact)
        SPM.factor(i).name=job.fact(i).name;
        SPM.factor(i).levels=job.fact(i).levels;
        CheckNC=CheckNC*SPM.factor(i).levels;
    end
    if ~(CheckNC==NC)
        disp('Error in fmri_stats job: factors do not match conditions');
        return
    end
end

% Globals
%-------------------------------------------------------------
SPM.xGX.iGXcalc = job.global;
SPM.xGX.sGXcalc = 'mean voxel value';
SPM.xGX.sGMsca  = 'session specific';

% High Pass filter
%-------------------------------------------------------------
for i = 1:numel(job.sess),
    SPM.xX.K(i).HParam = job.sess(i).hpf;
end

% Autocorrelation
%-------------------------------------------------------------
classical=isfield(job.estim.Method,'Classical');

if classical,
    SPM.xVi.form = job.estim.Method.Classical.cvi;
else
    % Autocorrelation is specified in a different way
    % for Bayesian estimation
    SPM.xVi.form = 'none';
end

% Let SPM configure the design
%-------------------------------------------------------------
SPM = spm_fmri_spm_ui(SPM);

if ~isempty(job.mask)
    SPM.xM.VM         = spm_vol(job.mask{:});
    SPM.xM.xs.Masking = [SPM.xM.xs.Masking, '+explicit mask'];
end

%-Save SPM.mat
%-----------------------------------------------------------------------
fprintf('%-40s: ','Saving SPM configuration with explicit mask')   %-#
if str2num(version('-release'))>=14,
    save('SPM','-V6','SPM');
else
    save('SPM','SPM');
end;

fprintf('%30s\n','...SPM.mat with mask saved')                     %-#

if ~classical
    % Bayesian estimation options
    
    % Analyse specific slices or whole volume
    if isfield(job.estim.Method.Bayesian.space,'Slices')
        SPM.PPM.space_type='Slices';
        SPM.PPM.AN_slices=job.estim.Method.Bayesian.space.Slices;
    else
        SPM.PPM.space_type='Volume';
    end
    
    % Regression coefficient priors
    switch job.estim.Method.Bayesian.signal
        case 'GMRF',
            SPM.PPM.priors.W='Spatial - GMRF';
        case 'LORETA',
            SPM.PPM.priors.W='Spatial - LORETA';
        case 'Global',
            SPM.PPM.priors.W='Voxel - Shrinkage';
        case 'Uninformative',
            SPM.PPM.priors.W='Voxel - Uninformative';
        otherwise
            disp('Unkown prior for W in spm_config_fmri_stats');
    end
    
    % Number of AR coefficients
    SPM.PPM.AR_P=job.estim.Method.Bayesian.ARP;
    
    % AR coefficient priors
    if isfield(job.estim.Method.Bayesian.noise,'GMRF')
        SPM.PPM.priors.W='Spatial - GMRF';
    elseif isfield(job.estim.Method.Bayesian.noise,'LORETA')
        SPM.PPM.priors.W='Spatial - LORETA';
    elseif isfield(job.estim.Method.Bayesian.noise,'tissue_type')
        SPM.PPM.priors.W='Discrete';
        SPM.PPM.priors.SY=job.estim.Method.Bayesian.noise.tissue_type;
    end
    
    % Define an empty contrast
    NullCon.name=[];
    NullCon.c=[];
    NullCon.STAT = 'P';
    NullCon.X0=[];
    NullCon.iX0=[];
    NullCon.X1o=[];
    NullCon.eidf=1;
    NullCon.Vcon=[];
    NullCon.Vspm=[];
        
    SPM.xCon=[];
    % Set up contrasts for 2nd-level ANOVA
    if strcmp(job.estim.Method.Bayesian.anova.second,'Yes')
        cons=spm_design_contrasts(SPM);
        for i=1:length(cons),
            % Create a simple contrast for each row of each F-contrast
            % The resulting contrast image can be used in a 2nd-level analysis
            Fcon=cons(i).c;
            nrows=size(Fcon,1);
            STAT='P';
            for r=1:nrows,
                con=Fcon(r,:);     
                
                % Normalise contrast st. sum of positive elements is 1
                % and sum of negative elements  is 1
                s1=length(find(con==1));
                con=con./s1;
                
                % Change name 
                str=cons(i).name;
                sp1=min(find(str==' '));
                if strcmp(str(1:11),'Interaction')
                    name=['Positive ',str,'_',int2str(r)];
                else
                    name=['Positive',str(sp1:end),'_',int2str(r)];
                end
                
                DxCon=NullCon;
                DxCon.name=name;
                DxCon.c=con';
                
                if isempty(SPM.xCon),
                    SPM.xCon = DxCon;
                else
                    SPM.xCon(end+1) = DxCon;
                end
            end
        end
    end
    
    % Set up user-specified simple contrasts
    ncon=length(job.estim.Method.Bayesian.gcon);
    K=size(SPM.xX.X,2);
    for c = 1:ncon,
        DxCon=NullCon;
        DxCon.name = job.estim.Method.Bayesian.gcon(c).name;
        convec=sscanf(job.estim.Method.Bayesian.gcon(c).convec,'%f');
        if length(convec)==K
            DxCon.c = convec;
        else
            disp('Error in spm_config_fmri_stats: contrast does not match design');
            return
        end
        
        if isempty(SPM.xCon),
            SPM.xCon = DxCon;
        else
            SPM.xCon(end+1) = DxCon;
        end;
    end
    

end

bayes_anova=0;
if ~classical
    if strcmp(job.estim.Method.Bayesian.anova.first,'Yes')
        bayes_anova=1;
    end
end

if strcmp(job.estim.when,'Later')
    my_cd(original_dir); % Change back dir
    
    fprintf('Done\n')
    return
end

if classical
    SPM = spm_spm(SPM);
else
    if bayes_anova
        SPM.PPM.update_F=1; % Compute evidence for each model
        SPM.PPM.compute_det_D=1; 
    end
    SPM = spm_spm_vb(SPM);
end

if bayes_anova
    % We don't want to estimate contrasts for each different model
    SPM.xCon=[];
    spm_vb_ppm_anova(SPM);
end

% Automatically set up contrasts for factorial designs
if classical & isfield(SPM,'factor')
    cons=spm_design_contrasts(SPM);
    
    % Create F-contrasts
    for i=1:length(cons),
        con=cons(i).c;
        name=cons(i).name;
        STAT='F';
        [c,I,emsg,imsg] = spm_conman('ParseCon',con,SPM.xX.xKXs,STAT);
        if all(I)
            DxCon = spm_FcUtil('Set',name,STAT,'c',c,SPM.xX.xKXs);
        else
            DxCon = [];
        end
        if isempty(SPM.xCon),
            SPM.xCon = DxCon;
        else
            SPM.xCon(end+1) = DxCon;
        end;
        spm_contrasts(SPM,length(SPM.xCon));
    end
    
    % Create t-contrasts
    for i=1:length(cons),
        % Create a t-contrast for each row of each F-contrast
        % The resulting contrast image can be used in a 2nd-level analysis
        Fcon=cons(i).c;
        nrows=size(Fcon,1);
        STAT='T';
        for r=1:nrows,
            con=Fcon(r,:);     
            
            % Change name 
            str=cons(i).name;
            sp1=min(find(str==' '));
            if strcmp(str(1:11),'Interaction')
                name=['Positive ',str,'_',int2str(r)];
            else
                name=['Positive',str(sp1:end),'_',int2str(r)];
            end
            
            [c,I,emsg,imsg] = spm_conman('ParseCon',con,SPM.xX.xKXs,STAT);
            if all(I)
                DxCon = spm_FcUtil('Set',name,STAT,'c',c,SPM.xX.xKXs);
            else
                DxCon = [];
            end
            if isempty(SPM.xCon),
                SPM.xCon = DxCon;
            else
                SPM.xCon(end+1) = DxCon;
            end;
            spm_contrasts(SPM,length(SPM.xCon));
        end
    end
end
    
my_cd(original_dir); % Change back
fprintf('Done\n')
return
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function vf = vfiles_stats(job)
direc = job.dir{1};
vf    = {fullfile(direc,'SPM.mat')};

% Should really create a few vfiles for beta images etc here as well.

