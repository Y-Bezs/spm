function spm_slice_timing(P, Seq, refslice, timing)
% function spm_slice_timing(P, Seq,refslice,timing)
% INPUT:
% 	P		nimages x ?	Matrix with filenames
%	Seq		slice acquisition order (1,2,3 = asc, desc, interl)
%	refslice	slice for time 0
%	timing		additional information for sequence timing
%			timing(1) = time between slices
%			timing(2) = time between last slices and next volume
%
% 	If no input is specified the function serves as a GUI			
%
% OUTPUT:
%	None
%
% NMH_ACQCORRECT  Correct differences in image acquisition time between slices
%   This routine is intended to correct for the staggered order of
%   slice acquisition that is used during echoplanar scanning. The
%   correction is necessary to make the data on each slice correspond
%   to the same point in time. Without correction, the data on one
%   slice will represent a point in time as far removed as 1/2 the TR
%   from an adjacent slice (in the case of an interleaved sequence).
%
%   This routine "shifts" a signal in time to provide an output
%   vector that represents the same (continuous) signal sampled
%   starting either later or earlier. This is accomplished by a simple
%   shift of the phase of the sines that make up the signal.
%
%   Recall that a Fourier transform allows for a representation of any
%   signal as the linear combination of sinusoids of different
%   frequencies and phases. Effectively, we will add a constant
%   to the phase of every frequency, shifting the data in time.
%
%    Shifter - This is the filter by which the signal will be convolved
%    to introduce the phase shift. It is constructed explicitly in
%    the Fourier domain. In the time domain, it may be described as
%    an impulse (delta function) that has been shifted in time the
%    amount described by TimeShift.
%
%   The correction works by lagging (shifting forward) the time-series
%     data on each slice using sinc-interpolation. This results in each
%     time series having the values that would have been obtained had
%     the slice been acquired at the beginning of each TR.
%
%   To make this clear, consider a neural event (and ensuing hemodynamic
%     response) that occurs simultaneously on two adjacent slices. Values
%     from slice "A" are acquired starting at time zero, simultaneous to
%     the neural event, while values from slice "B" are acquired one
%     second later. Without corection, the "B" values will describe a
%     hemodynamic response that will appear to have began one second
%     EARLIER on the "B" slice than on slice "A". To correct for this,
%     the "B" values need to be shifted towards the Right, i.e., towards
%     the last value.
%
%   This correction assumes that the data are band-limited (i.e. there
%     is no meaningful information present in the data at a frequency
%     higher than that of the Nyquist). This assumption is support by
%     the study of Josephs et al (1997, NeuroImage) that obtained
%     event-related data at an effective TR of 166 msecs. No physio-
%     logical signal change was present at frequencies higher than our
%     typical Nyquist (0.25 HZ).
%
%   NOTE WELL:  This correction should be the first performed (i.e.,
%     before orienting, motion correction, padding, smoothing, etc.).
%     Additionally, it should only be performed once!
%
%  NOTE ALSO: The routine below assumes the data are interleaved. Since
%     the images out of the vision have already been arranged in proper
%     slice order, this routine will not work on non-interleaved slices.
%
% Written by Darren Gitelman at Northwestern U., 1998
%
% Based (in large part) on ACQCORRECT.PRO from Mark D'Exposito,
%  and Geof Aquirre and Eric Zarahn at U. Penn.
%
% v1.0	07/04/98	DRG
% v1.1  07/09/98	DRG	fixed code to reflect 1-based indices
%				of matlab vs. 0-based of pvwave
%
% Modified by R Henson and C Buechel and J Ashburner, FIL, 1999, to
% handle different sequence acquisitions, analyze format, different
% reference slices and memory mapping.


SPMid = spm('FnBanner',mfilename,'%I%');
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Slice timing');
spm_help('!ContextHelp',mfilename);

if nargin < 1,
	% Choose the images
	P = spm_get(+Inf,'*.img','Select images to acquisition correct');
end;

% map image files into memory
Vin 	= spm_vol(P);
nimgo	= size(P,1);
nimg	= 2^(floor(log2(nimgo))+1);
nslices	= Vin(1).dim(3);

if nargin < 2,
	% select fMRI acquisition sequence type
	Stype = str2mat(...
		'ascending (first slice=bottom)',...
		'descending (first slice=top)',...
		'interleaved (first slice=top)',...
		'user specified');
	str   = 'Select sequence type';
	Seq   = spm_input(str,'!+1','m',Stype,[1:size(Stype,1)]);
end;

if Seq==[1],
	sliceorder = [1:1:nslices];
elseif Seq==[2],
	sliceorder = [nslices:-1:1];
elseif Seq==[3],
	% Assumes interleaved sequences top-middle downwards
	for k=1:nslices,
		sliceorder(k) = round((nslices-k)/2 + (rem((nslices-k),2) * (nslices - 1)/2)) + 1;
	end;
elseif Seq==[4],
	sliceorder = [];
	while length(sliceorder)~=nslices | max(sliceorder)>nslices | ...
		min(sliceorder)<1 | any(diff(sort(sliceorder))~=1),
		sliceorder = spm_input('Order of slices (1=bottom)','!+0','e');
	end;
end;

if nargin < 3,
	% Choose reference slice (in Analyze format, slice 1 = bottom)
	% Note: no checking that 1 < refslice < no.slices (default = middle slice)
	refslice = spm_input('Reference Slice (1=bottom)','!+0','e',floor(Vin(1).dim(3)/2));
end;

if nargin < 4,
	factor = 1/nslices;
else,
	TR 	= (nslices-1)*timing(1)+timing(2);
	fprintf('Your TR is %1.1f\n',TR);
	factor = timing(1)/TR;
end;


spm('Pointer','Watch')
spm('FigName','Slice timing: working',Finter,CmdLine);

% create new header files
Vout 	= Vin;
for k=1:nimgo,
	[pth,nm,xt,vr] = fileparts(deblank(Vin(k).fname));
	Vout(k).fname  = fullfile(pth,['a' nm xt vr]);
	if isfield(Vout(k),'descrip'),
		desc = [Vout(k).descrip ' '];
	else,
		desc = '';
	end;
	Vout(k).descrip = [desc 'acq-fix ref-slice ' int2str(refslice)];
	Vout(k) = spm_create_image(Vout(k));
end;

% Set up large matrix for holding image info
% Organization is time by voxels
stack = zeros(nimg,prod(Vout(1).dim(1:2)));

spm_progress_bar('Init',nslices,'Correcting acquisition delay','planes complete');

% For loop to read data slice by slice do correction and write out
% In analzye format, the first slice in is the first one in the volume.
for k = 1:nslices,

	% Set up time acquired within slice order
	timeacquired = find(sliceorder==k) - find(sliceorder==refslice); 
	shiftamount  = timeacquired * factor;

	% Read in slice data
	B  = spm_matrix([0 0 k]);
	for m=1:nimgo,
		% Retrieve slice, convert to vector and update stack
		x  = spm_slice_vol(Vin(m),B,Vin(1).dim(1:2),1);
		stack(m,:) = x(:)';
	end;

	% fill in continous function to avoid edge effects
	%-------------------------------------------------
	for g=1:size(stack,2),
		stack(nimgo+1:size(stack,1),g) = linspace(stack(nimgo,g),stack(1,g),nimg-nimgo)';
	end;

	% set up shifting variables
	shifter = [];
	OffSet  = 0;
	len     = size(stack,1);
	phi     = zeros(1,len);

	% Check if signal is odd or even -- impacts how Phi is reflected
	%  across the Nyquist frequency. Opposite to use in pvwave.
	if rem(len,2) ~= 0, OffSet = 1; end;

	% Phi represents a range of phases up to the Nyquist frequency
	% Shifted phi 1 to right.
	for f = 1:len/2,
		phi(f+1) = -1*shiftamount*2*pi/(len/f);
	end;

	% Mirror phi about the center
	% 1 is added on both sides to reflect Matlab's 1 based indices
	% Offset is opposite to program in pvwave again because indices are 1 based
	phi(len/2+1+1-OffSet:len) = -fliplr(phi(1+1:len/2+OffSet));
	
	% Transform phi to the frequency domain and take the complex transpose
	shifter = [cos(phi) + sin(phi)*sqrt(-1)].';

	% The memory hungry version without the looping..
	% Make shifter the same size as signal using Tony's trick which
	% references column 1 of shifter
	shifter = shifter(:,ones(size(stack,2),1));
	% perform the shift
	stack = real(ifft(fft(stack,[],1).*shifter,[],1));

	% Atternative version with looping
	% for pix=1:size(stack,2),
	% 	stack(:,pix) = real(ifft(fft(stack(:,pix),[],1).*shifter,[],1));
	% end;

	% write out the slice for all volumes
	for p = 1:nimgo,
		d       = reshape(stack(p,:),Vout(p).dim(1:2));
		Vout(p) = spm_write_plane(Vout(p),d,k);
	end;
	spm_progress_bar('Set',k);
end;

spm_progress_bar('Clear');

spm('FigName','Slice timing: done',Finter,CmdLine);
spm('Pointer');
return;
