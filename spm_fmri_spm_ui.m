function spm_fmri_spm_ui
% Setting up the general linear model for fMRI time-series
% FORMAT spm_fmri_spm_ui
%____________________________________________________________________________
%
% spm_fmri_spm_ui configures the design matrix, data specification and
% filtering that specify the ensuing statistical analysis. These
% arguments are passed to spm_spm that then performs the actual analysis.
%
% The design matrix defines the experimental design and the nature of
% hypothesis testing to be implemented.  The design matrix has one row
% for each scan and one column for each effect or explanatory variable.
% (e.g. regression or stimulus function).  The parameters are estimated in
% a least squares sense using the general linear model.  Specific profiles
% within these parameters are tested using a linear compound or contrast
% with the T or F statistic.  The resulting staistical map of constitutes 
% an SPM.  The SPM{T}/{F} is then characterized in terms of focal or regional
% differences by assuming that (under the null hypothesis) the components of
% the SPM (i.e. residual fields) behave as a smooth stationary Gaussian field.
%
% spm_fmri_spm_ui allows you to (i) specify a statistical model in terms
% of a design matrix, (ii) specify the data and (iii) proceed to estimate
% the parameters of the model.  Inferences can be made about the ensuing
% parameter estimates (at a first or fixed-effect level) in the results
% section, or they can be re-entered into a second (random-effect) level
% analysis by treating the session or subject-specific parameter
% estimates as new summary data.  Inferences at any level obtain by
% specifying appropriate T or F contrasts in the results section to
% produce SPMs and tables of p values and statistics.
%
% spm_fmri_spm calls spm_fMRI_design which allows you to configure a
% design matrix in terms of events or epochs.  This design matrix can be
% specified before or during data specification.  In some instances
% (e.g.  with stochastic designs that have to realized before data
% acquisition) it is necessary to build the design matrix first and then
% select the corresponding data.  In others it may be simpler to specify
% the data and then the design.  Both options are supported.  Once the
% design matrix, data and filtering have been specified spm_fmri_spm_ui
% calls spm_spm to estimate the model parameters that are then saved for
% subsequent analysis.
%
% spm_fMRI_design allows you to build design matrices with separable
% session-specific partitions.  Each partition may be the same (in which
% case it is only necessary to specify it once) or different.  Responses
% can be either event- or epoch related, where the latter model prolonged
% and possibly time-varying responses to state-related changes in
% experimental conditions.  Event-related response are modelled in terms
% of responses to instantaneous events.  Mathematically they are both
% modelled by convolving a series of delta (or stick) functions,
% indicating the onset of an event or epoch with a set of basis
% functions.  These basis functions can be very simple, like a box car,
% or may model voxel-specific forms of evoked responses with a linear
% combination of several basis functions (e.g.  a Fourier set).  Basis
% functions can be used to plot estimated responses to single events or
% epochs once the parameters (i.e.  basis function coefficients) have
% been estimated.  The importance of basis functions is that they provide
% a graceful transition between simple fixed response models (like the
% box-car) and finite impulse response (FIR) models, where there is one
% basis function for each scan following an event or epoch onset.  The
% nice thing about basis functions, compared to FIR models, is that data
% sampling and stimulus presentation does not have to be sychronized
% thereby allowing a uniform and unbiased sampling of peri-stimulus time.
% 
% Event-related designs may be stochastic or deterministic.  Stochastic
% designs involve one of a number of trial-types occurring with a
% specified probably at successive intervals in time.  These
% probabilities can be fixed (stationary designs) or time-dependent
% (modulated or non-stationary designs).  The most efficient designs
% obtain when the probabilities of every trial type are equal and this is
% enforced in SPM.  The modulation of non-stationary designs is simply
% sinusoidal with a period of 32 seconds.  A critical aspect of
% stochastic event-related designs is whether to include null events or
% not.  If you wish to estimate the evoke response to a specific event
% type (as opposed to differential responses) then a null event must be
% included (even though it is not modelled explicitly).
% 
% The choice of basis functions depends upon the nature of the inference
% sought.  One important consideration is whether you want to make
% inferences about compounds of parameters (i.e.  contrasts).  This is
% the case if (i) you wish to use a SPM{T} to look separately at
% activations and deactivations or (ii) you with to proceed to a second
% (random-effect) level of analysis.  If this is the case then (for
% event-related studies) use a canonical hemodynamic response function
% (HRF) and derivatives with respect to latency (and dispersion).  Unlike
% other bases contrasts of these effects have a physical interpretation
% and represent a parsimonious way of characterising event-related
% responses.  Bases such as a Fourier set require the SPM{F} for
% inference and preclude second level analyses.
% 
% In epoch-related designs you will be asked to specify the epochs in
% terms of condition order e.g.  010201020102 for conditions 1 and 2
% intercalated with a baseline condition 0. Later you will be asked to
% specify the number of scans for each epoch, again as a vector (list of
% numbers).  If the epochs were all the same length, then just type in
% that length once. The baseline condition will not be modelled
% explicitly so that condition-specific responses are uniquely
% estimable.
% 
% Serial correlations in fast fMRI time-series are dealt with as
% described in spm_spm.  At this stage you need to specific the filtering
% that will be applied to the data (and design matrix).  This filtering
% is important to ensure that bias in estimates of the standard error are
% minimized.  This bias results from a discrepancy between the estimated
% (or assumed) auto-correlation structure of the data and the actual
% intrinsic correlations.  The intrinsic correlation will be estimated
% automatically using an AR(1) model during parameter estimation.  The
% discrepancy between estimated and actual intrinsic (i.e.  prior to
% filtering) correlation are greatest at low frequencies.  Therefore
% specification of the high-pass component of the filter is particularly
% important.  High pass filtering is now implemented at the level of the
% filtering matrix K (as opposed to entering as confounds in the design
% matrix).  The default cutoff period is twice the maximum time interval
% between the most frequently occurring event or epoch (i.e the minium of
% all maximum intervals over event or epochs).
%
%---------------------------------------------------------------------------
% Refs:
%
% Friston KJ, Holmes A, Poline J-B, Grasby PJ, Williams SCR, Frackowiak
% RSJ & Turner R (1995) Analysis of fMRI time-series revisited. NeuroImage
% 2:45-53
%
% Worsley KJ and Friston KJ (1995) Analysis of fMRI time-series revisited -
% again. NeuroImage 2:178-181
%
% Friston KJ, Frith CD, Frackowiak RSJ, & Turner R (1995) Characterising
% dynamic brain responses with fMRI: A multivariate approach NeuroImage -
% 2:166-172
%
% Frith CD, Turner R & Frackowiak RSJ (1995) Characterising evoked 
% hemodynamics with fMRI Friston KJ, NeuroImage 2:157-165
%
% Josephs O, Turner R and Friston KJ (1997) Event-related fMRI, Hum. Brain
% Map. 0:00-00
%
%___________________________________________________________________________
% %W% Karl Friston, Jean-Baptiste Poline, Christian Buechel %E%



% Initialize variables
%---------------------------------------------------------------------------
Finter = spm_figure('FindWin','Interactive');
set(Finter,'Name','fMRI analysis'); 

% get design matrix and/or data
%===========================================================================
MType   = {'specify a model',...
	   'estimate a specified model',...
	   'specify and estimate a model'};
str     = 'Would you like to';
MT      = spm_input(str,1,'m',MType);


switch MT
%---------------------------------------------------------------------------

	case 1
	% specify a design matrix
	%-------------------------------------------------------------------
	spm_fMRI_design;
	return

	case 2
	% load pre-specified design matrix
	%-------------------------------------------------------------------
	load(spm_get(1,'.mat','Select fMRIDesMtx.mat'))


	% get filenames
	%-------------------------------------------------------------------
	nsess  = length(Sess);
	nscan  = zeros(1,nsess);
	P      = [];
	if nsess < 16
		for  i = 1:nsess
			nscan(i) = length(Sess{i}.row);
			str      = sprintf('select scans for session %0.0f',i);
			q        = spm_get(nscan(i),'.img',str);
 			P        = strvcat(P,q);
		end
	else
		for  i = 1:nsess
			nscan(i) = length(Sess{i}.row);
		end
		str    = sprintf('select scans for session %0.0f',i);
		P      = spm_get(sum(nscan),'.img',str);
	end

	% Repeat time
	%-------------------------------------------------------------------
	RT     = X.RT;


	case 3
	% get filenames and design matrix
	%-------------------------------------------------------------------
	nsess  = spm_input(['number of sessions'],1,'e',1);
	nscan  = zeros(1,nsess);
	P      = [];
	for  i = 1:nsess
		str      = sprintf('select scans for session %0.0f',i);
		q        = spm_get(Inf,'.img',str);
 		P        = strvcat(P,q);
		nscan(i) = size(q,1);
	end

	% get Repeat time
	%-------------------------------------------------------------------
	RT     = spm_input('Interscan interval {secs}',2);

	% get design matrix
	%-------------------------------------------------------------------
	[X,Sess] = spm_fMRI_design(nscan,RT);

end


% Global normalization
%---------------------------------------------------------------------------
str    = 'remove Global effects';
Global = spm_input(str,1,'scale|none',{'Scaling' 'None'});


% Temporal filtering
%===========================================================================

% High-pass filtering
%---------------------------------------------------------------------------
str	= 'High-pass filter?';
cLFmenu = {'specify',...
	   'none'};
cLF     = spm_input(str,'+1','b',cLFmenu);
param   = [];

% specify cut-off (default based on peristimulus time)
% param = cut-off period (max = 512, min = 32)
%---------------------------------------------------------------------------
switch cLF

	case 'specify'
	%-------------------------------------------------------------------
	param   = 512*ones(1,nsess);
	for   i = 1:nsess
		for j = 1:length(Sess{i}.pst)
			param(i) = min([param(i) 2*max(RT + Sess{i}.pst{j})]);
		end
	end
	param   = ceil(param);
	param(param < 32) = 32;
	str     = 'Cut off period[s] for each session';
	param   = spm_input(str,'+1','e',param);
	if length(param) == 1
		 param = param*ones(1,nsess);
	end
end

% create filterLF struct
%---------------------------------------------------------------------------
for i = 1:nsess
	filterLF{i} = struct('Choice',cLF,'Param',param(i));
end

% Low-pass filtering
%---------------------------------------------------------------------------
if spm_input('Low-pass filter?','+1','specify|none',[1 0]);
	cHFmenu = {'hrf',...
		   'Gaussian'};
	cHF     = spm_input('kernel','+1','b',cHFmenu);
else
	cHF     = 'none';
end

% get Gaussian parameter
%---------------------------------------------------------------------------
switch cHF

	case 'Gaussian'
	%-------------------------------------------------------------------
	param = spm_input('Gaussian FWHM (secs)','+1','r',4);
	param = param/sqrt(8*log(2)); 
end

% create filterHF struct
%---------------------------------------------------------------------------
for i = 1:nsess
	filterHF{i} = struct('Choice',cHF,'Param',param);
end


% intrinsic autocorrelations (Vi)
%---------------------------------------------------------------------------
str     = 'Model intrinsic correlations?';
cVimenu = {'none','AR(1)'};
cVi     = spm_input(str,'+1','b',cVimenu);


% create Vi struct
%---------------------------------------------------------------------------
Vi      = speye(sum(nscan));
xVi     = struct('Vi',Vi,'Form',cVi);
for   i = 1:nsess
	xVi.row{i} = Sess{i}.row;
end

% the interactive parts of spm_spm_ui are now finished: Cleanup GUI
%---------------------------------------------------------------------------
spm_clf(Finter);
set(Finter,'Name','thankyou','Pointer','Watch')



% Contruct convolution matrix and Vi struct
%===========================================================================
K     = [];
for i = 1:nsess
	k      = nscan(i);
	[x y]  = size(K);
	q      = spm_make_filter(k,RT,filterHF{i},filterLF{i});
	K(([1:k] + x),([1:k] + y)) = q;
end
K     = sparse(K);

% get file identifiers and Global values
%===========================================================================
VY     = spm_vol(P);

if any(any(diff(cat(1,VY.dim),1,1),1)&[1,1,1,0])
	error('images do not all have the same dimensions'),           end
if any(any(any(diff(cat(3,VY.mat),1,3),3)))
	error('images do not all have same orientation & voxel size'), end


%-Compute Global variate
%---------------------------------------------------------------------------
GM     = 100;
q      = sum(nscan);
g      = zeros(q,1);
for i  = 1:q, g(i) = spm_global(VY(i)); end

% scale if specified (otherwise session specific grand mean scaling)
%---------------------------------------------------------------------------
gSF    = GM./g;
if strcmp(Global,'None')
	for i = 1:nsess
		j      = Sess{i}.row;
		gSF(j) = GM./mean(g(j));
	end
end

%-Apply gSF to memory-mapped scalefactors to implement scaling
%---------------------------------------------------------------------------
for i = 1:q, VY(i).pinfo(1:2,:) = VY(i).pinfo(1:2,:)*gSF(i); end


%-Masking structure
%---------------------------------------------------------------------------
xM = struct(	'T',	ones(q,1),...
		'TH',	g.*gSF,...
		'I',	0,...
		'VM',	{[]},...
		'xs',	struct('Masking','analysis threshold'));


%-Construct full design matrix (X), parameter names (Xnames),
% and design information structure (xX)
%===========================================================================
Xnames = [X.Xname X.Bname];
xX     = struct(	'X',		[X.xX X.bX],...
			'K',		K,...
			'xVi',		xVi,...
			'RT',		X.RT,...
			'dt',		X.dt,...
			'filterLF',	filterLF,...
			'filterHF',	filterHF,...
			'Xnames',	{Xnames'});



%-Effects designated "of interest" - constuct an F-contrast
%--------------------------------------------------------------------------
if isempty(X.bX)  %- no confounds
	F_iX0 = [];
else 
	% if isempty(X.xX) we have size(X.xX,2) == 0;
	F_iX0 = size(X.xX,2) + [1:size(X.bX,2)];
end

%-Design description (an nx2 cellstr) - for saving and display
%==========================================================================
for i    = 1:length(Sess), ntr(i) = length(Sess{i}.name); end
sGXcalc  = 'mean voxel value';
sGMsca   = 'session specific';
xsDes    = struct(	'Design',			X.DSstr,...
			'Basis_functions',		X.BFstr,...
			'Number_of_sessions',		sprintf('%d',nsess),...
			'Conditions_per_session',	sprintf('%-2d',ntr),...
			'Interscan_interval',		sprintf('%0.2f',RT),...
			'High_pass_Filter',		filterHF{1}.Choice,...
			'Low_pass_Filter',		filterLF{1}.Choice,...
			'Intrinsic_correlations',	xVi.Form,...
			'Global_calculation',		sGXcalc,...
			'Grand_mean_scaling',		sGMsca,...
			'Global_normalisation',		Global);
%-global structure
%---------------------------------------------------------------------------
xGX.iGXcalc  = Global{1};
xGX.sGXcalc  = sGXcalc;
xGX.rg       = g;
xGX.sGMsca   = sGMsca;
xGX.GM       = GM;
xGX.gSF      = gSF;


%-Save SPMcfg.mat file
%---------------------------------------------------------------------------
save SPMcfg xsDes VY xX xM xGX F_iX0 Sess

%-Display Design report
%===========================================================================
spm_DesRep('DesMtx',xX,{VY.fname}',xsDes)


%-Analysis Proper
%===========================================================================
spm_clf(Finter);
if spm_input('estimate?',1,'b','yes|no',[1 0])
	spm_spm(VY,xX,xM,F_iX0,Sess);
end


%-End: Cleanup GUI
%---------------------------------------------------------------------------
spm_clf(Finter); spm('Pointer','Arrow')

