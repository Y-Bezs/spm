function D = spm_eeg_rdata_CTF275(S)
%%%% function to read in CTF data to Matlab
try
   pre_data = ctf_read(S.Fdata);
catch
 	pre_data = ctf_read;
    S.Fdata = pre_data.folder;
end

try
    Fchannels = S.Fchannels;
catch
    Fchannels = spm_select(1, '\.mat$', 'Select channel template file', {}, fullfile(spm('dir'), 'EEGtemplates'));
end


D.channels.ctf = spm_str_manip(Fchannels, 't');

D.channels.Bad = [];

% compatibility with some preprocessing functions
D.channels.heog = 0;
D.channels.veog = 0;
D.channels.reference = 0;

PP1=squeeze(pre_data.data(:,1));
PP2=squeeze(pre_data.data(:,2));

inds=find(diff(PP1)>0);
D.events.code=PP1(inds+2)'; %changed to +2 from +1 to avoid errors when changing event code without passing by zero.
D.events.time=inds'+1;
inds=find(diff(PP2)<0);
D.events.code=[D.events.code,PP2(inds+1)'+255];
D.events.time=[D.events.time,inds'+1];

[X,I]=sort(D.events.time);
D.events.time=D.events.time(I);
D.events.code=D.events.code(I);

sens=pre_data.sensor.index.all_sens;
D.channels.name=pre_data.sensor.label(sens);
D.channels.order=[1:length(sens)];
D.Nchannels=length(sens);
D.channels.eeg=[1:length(sens)];
D.Radc=pre_data.setup.sample_rate;
D.Nsamples=pre_data.setup.number_samples;
D.Nevents=pre_data.setup.number_trials;
[pathstr,name,ext,versn]=fileparts(pre_data.folder);
D.datatype= 'float';
D.fname=[name,'.mat'];
D.path=pwd;
D.fnamedat=[name,'.dat'];

D.scale = ones(D.Nchannels, 1, 1);

fpd = fopen(fullfile(D.path, D.fnamedat), 'w');
for n=1:D.Nsamples
	
		fwrite(fpd, pre_data.data(n,sens).*1e15, 'float');
	
end
fclose(fpd);

% --- Save coil/sensor positions and orientations for source reconstruction (in mm) ---

% - channel locations and orientations
SensLoc = [];
SensOr  = [];
for i = 1:length(pre_data.sensor.location);
    if any(pre_data.sensor.location(:,i)) & pre_data.sensor.label{i}(1) == 'M'
        SensLoc = [SensLoc; pre_data.sensor.location(:,i)'];
        SensOr  = [SensOr ; pre_data.sensor.orientation(:,i)'];
    end
end
SensLoc = 10*SensLoc; % convertion from cm to mm
if length(SensLoc) > 275
    warning(sprintf('Found more than 275 channels!\n'));
end

[pth,nam,ext]  = fileparts(D.fname);
fic_sensloc    = fullfile(D.path,[nam '_sensloc.mat']);
fic_sensorient = fullfile(D.path,[nam '_sensorient.mat']);
save(fic_sensloc, 'SensLoc');
save(fic_sensorient, 'SensOr');
clear SensLoc

% for DCM/ERF: Use fieldtrip functions to retrieve sensor location and
% orientation structure
hdr = read_ctf_res4(findres4file(S.Fdata));
grad = fieldtrip_ctf2grad(hdr);
D.channels.grad = grad;

% - coil locations (in this order - NZ:nazion , LE: left ear , RE: right ear)
CurrentDir = pwd;
cd(pre_data.folder);
hc_files = dir('*.hc');
if isempty(hc_files)
    warning(sprintf('Impossible to find head coil file\n'));
elseif length(hc_files) > 1
    hc_file = spm_select(1, '\.hc$', 'Select head coil file');
else
    hc_file = fullfile(pre_data.folder,hc_files.name);
end
clear hc_files
fid = fopen(hc_file,'r');
for i = 1:24
    UnusedLines = fgetl(fid);
end
UnusedLines = fgetl(fid);
for i = 1:3 % Nazion coordinates
    UsedLine    = fgetl(fid);
    UsedLine    = fliplr(deblank(fliplr(UsedLine)));
    [A,COUNT,ERRMSG,NEXTINDEX] = sscanf(UsedLine,'%c = %f');
    if ~isempty(ERRMSG) | (COUNT ~= 2)
        warning(sprintf('Unable to read head coil file\n'));
    else
        NZ(i) = A(2);
    end
end
UnusedLines = fgetl(fid);
for i = 1:3 % Left Ear coordinates
    UsedLine    = fgetl(fid);
    UsedLine    = fliplr(deblank(fliplr(UsedLine)));
    [A,COUNT,ERRMSG,NEXTINDEX] = sscanf(UsedLine,'%c = %f');
    if ~isempty(ERRMSG) | (COUNT ~= 2)
        warning(sprintf('Unable to read head coil file\n'));
    else
        LE(i) = A(2);
    end
end
UnusedLines = fgetl(fid);
for i = 1:3 % Right Ear coordinates
    UsedLine    = fgetl(fid);
    UsedLine    = fliplr(deblank(fliplr(UsedLine)));
    [A,COUNT,ERRMSG,NEXTINDEX] = sscanf(UsedLine,'%c = %f');
    if ~isempty(ERRMSG) | (COUNT ~= 2)
        warning(sprintf('Unable to read head coil file\n'));
    else
        RE(i) = A(2);
    end
end
fclose(fid);
CoiLoc = 10*[NZ ; LE ; RE]; % convertion from cm to mm
cd(CurrentDir);

fic_sensloc   = fullfile(D.path,[nam '_fidloc_meeg.mat']);
save(fic_sensloc,'CoiLoc');
clear hc_file CoiLoc UnusedLines UsedLine A COUNT ERRMSG NEXTINDEX
% -------

D.modality = 'MEG';
D.units = 'femto T';

if str2num(version('-release'))>=14
    save(fullfile(D.path, D.fname), '-V6', 'D');
else
	save(fullfile(D.path, D.fname), 'D');
end

% find file name if truncated or with uppercase extension
% added by Arnaud Delorme June 15, 2004
% -------------------------------------------------------
function res4name = findres4file( folder )

res4name = dir([ folder filesep '*.res4' ]);
if isempty(res4name)
    res4name = dir([ folder filesep '*.RES4' ]);
end

if isempty(res4name)
    error('No file with extension .res4 or .RES4 in selected folder');
else
    res4name = [ folder filesep res4name.name ];
end;
return
