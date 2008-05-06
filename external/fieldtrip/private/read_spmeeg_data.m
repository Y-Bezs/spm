function dat = read_spmeeg_data(filename, varargin)
% read_spmeeg_data() - import SPM5 and SPM8 meeg datasets
%
% Usage:
%   >> header = read_spmeeg_data(filename, varargin);
%
% Inputs:
%   filename - [string] file name
%
% Optional inputs:
%   'begsample'      first sample to read
%   'endsample'      last sample to read
%   'chanindx'  -    list with channel indices to read
%   'header'    - FILEIO structure header
%
% Outputs:
%   dat    - data over the specified range
% _______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
% Vladimir Litvak



if nargin < 1
  help read_spmeeg_data;
  return;
end;


typenames = {'uint8','int16','int32','float32','float64','int8','uint16','uint32'};
typesizes   = [1  2  4  4 8 1 2 4];

header    = keyval('header',     varargin);
begsample = keyval('begsample',  varargin);
endsample = keyval('endsample',  varargin);
chanindx  = keyval('chanindx',   varargin);

if isempty(header)
  header = read_spmeeg_header([filename(1:(end-3)) 'mat']);
end

datatype = 'float32';
scale = [];
if isfield(header, 'orig')
    if isfield(header.orig, 'datatype')
        datatype = header.orig.datatype;
    elseif isfield(header.orig.data, 'datatype')
        datatype = header.orig.data.datatype;
    end
    if isfield(header.orig, 'scale')
        scale = header.orig.scale;
    elseif isfield(header.orig.data, 'scale')
        scale = header.orig.data.scale;
    end
end

stepsize = typesizes(strmatch(datatype, typenames));

if isempty(begsample), begsample = 1; end;
if isempty(endsample), endsample = header.nSamples; end;

filename = [filename(1:(end-3)) 'dat'];

fid = fopen(filename, 'r');
fseek(fid, stepsize*header.nChans*(begsample-1), 'bof');
[dat, siz] = fread(fid, [header.nChans, (endsample-begsample+1)], datatype);
fclose(fid);

if ~isempty(chanindx)
    % select the desired channels
    dat = dat(chanindx,:,:);
end

if ~isempty(scale) && ~ismember(datatype, {'float32', 'float64'})
    dat = dat .* repmat(scale(chanindx,:,:), [1, size(dat, 2), 1]);
end
