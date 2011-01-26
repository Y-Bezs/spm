function [varargout] = ft_qualitycheck(cfg, varargin)

% FT_QUALITYCHECK facilitates quality inspection of a dataset.
% There are three likely steps for a user to check his/her dataset;
%
% 1) create an output.mat file with the quantified data (done by ft_qualitycheck)
% 2) visualize the quantifications (done by ft_qualitycheck; exported to .PNG and .PDF)
% 3) a more detailed inspection (user-specific, some examples on the FT wiki)
%
% This function is specific for the data recorded with the CTF MEG system
% at the Donders Centre for Cognitive Neuroimaging, Nijmegen, The
% Netherlands.
%
% Use as:
%   [output] = ft_qualitycheck(cfg, '*.ds')
%
%   No configuration options are yet implemented.
%
% Copyright (C) 2010-2011, Arjen Stolk, Bram Daams, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.

% set the defaults:
if ~isfield(cfg,'analyze'),        cfg.analyze = 'yes';                           end
if ~isfield(cfg,'savemat'),        cfg.savemat = 'yes';                           end
if ~isfield(cfg,'visualize'),      cfg.visualize = 'yes';                         end
if ~isfield(cfg,'saveplot'),       cfg.saveplot = 'yes';                          end


%% READ HISTORY FILE in order to extract date & time
cfghist                     = [];
cfghist.dataset             = varargin{1};
cfghist                     = checkconfig(cfghist, 'dataset2files', 'yes'); % translate into datafile+headerfile

logfile                     = strcat(cfghist.datafile(1:end-5),'.hist');
fileline                    = 0;
fid                         = fopen(logfile,'r');
while fileline >= 0
    fileline = fgets(fid);
    if ~isempty(findstr(fileline,'Collection started'))
        startdate = sscanf(fileline(findstr(fileline,'Collection started:'):end),'Collection started: %s');
        starttime = sscanf(fileline(findstr(fileline,startdate):end),strcat(startdate, '%s'));
    end
    if ~isempty(findstr(fileline,'Collection stopped'))
        stopdate = sscanf(fileline(findstr(fileline,'Collection stopped:'):end),'Collection stopped: %s');
        stoptime = sscanf(fileline(findstr(fileline,stopdate):end),strcat(stopdate, '%s'));
    end
    if ~isempty(findstr(fileline,'Dataset name'))
        datasetname = sscanf(fileline(findstr(fileline,'Dataset name'):end),'Dataset name %s');
    end
    if ~isempty(findstr(fileline,'Sample rate'))
        fsample = sscanf(fileline(findstr(fileline,'Sample rate:'):end),'Sample rate: %s');
    end
end
[daynr, daystr] = weekday(startdate);
startrec        = strcat(daystr,'-',startdate);
exportname      = strcat(datasetname(end-10:end-3),'_',starttime([1:2 4:5]));

if strcmp(cfg.analyze,'yes')
    %% DEFINE THE SEGMENTS; 10 second trials
    tic
    cfgdef                         = [];
    cfgdef.dataset                 = varargin{1};
    cfgdef.trialdef.eventtype      = 'trial';
    cfgdef.trialdef.prestim        = 0;
    cfgdef.trialdef.poststim       = 10; % 10 seconds of data
    cfgdef                         = ft_definetrial(cfgdef);
    
    %% TRIAL LOOP; process trial by trial
    ntrials = size(cfgdef.trl,1);
    for t = 1:ntrials
        fprintf('analyzing trial %s of %s \n', num2str(t), num2str(ntrials));
        
        % preproc raw
        cfgpreproc                  = cfgdef;
        cfgpreproc.trl              = cfgdef.trl(t,:);
        data                        = ft_preprocessing(cfgpreproc); clear cfgpreproc;
        
        % store grad file once
        if t == 1
            gradfile = data.grad;
        end            
        
        % determine headposition
        x1i = strmatch('HLC0011', data.label); % x nasion
        y1i = strmatch('HLC0012', data.label); % y nasion
        z1i = strmatch('HLC0013', data.label); % z nasion
        x2i = strmatch('HLC0021', data.label); % x left
        y2i = strmatch('HLC0022', data.label); % y left
        z2i = strmatch('HLC0023', data.label); % z left
        x3i = strmatch('HLC0031', data.label); % x right
        y3i = strmatch('HLC0032', data.label); % y right
        z3i = strmatch('HLC0033', data.label); % z right
        
        hpos(1,t) = mean(data.trial{1,1}(x1i,:) * 100);  % convert from meter to cm
        hpos(2,t) = mean(data.trial{1,1}(y1i,:) * 100);
        hpos(3,t) = mean(data.trial{1,1}(z1i,:) * 100);
        hpos(4,t) = mean(data.trial{1,1}(x2i,:) * 100);
        hpos(5,t) = mean(data.trial{1,1}(y2i,:) * 100);
        hpos(6,t) = mean(data.trial{1,1}(z2i,:) * 100);
        hpos(7,t) = mean(data.trial{1,1}(x3i,:) * 100);
        hpos(8,t) = mean(data.trial{1,1}(y3i,:) * 100);
        hpos(9,t) = mean(data.trial{1,1}(z3i,:) * 100);
        
        % determine headmotion: diffrence from initial trial (in cm)
        hmotion(1,t) = sqrt((hpos(1,t)-hpos(1,1)).^2 + (hpos(2,t)-hpos(2,1)).^2 + (hpos(3,t)-hpos(3,1)).^2); % Na
        hmotion(2,t) = sqrt((hpos(4,t)-hpos(4,1)).^2 + (hpos(5,t)-hpos(5,1)).^2 + (hpos(6,t)-hpos(6,1)).^2); % L
        hmotion(3,t) = sqrt((hpos(7,t)-hpos(7,1)).^2 + (hpos(8,t)-hpos(8,1)).^2 + (hpos(9,t)-hpos(9,1)).^2); % R
               
        % determine the minima, maxima, range, and average
        chans                       = ft_channelselection('MEG', data.label);
        rawindx                     = match_str(data.label, chans);
        minima(1,t)                 = min(min(data.trial{1,1}(rawindx,:)));
        maxima(1,t)                 = max(max(data.trial{1,1}(rawindx,:)));
        range(1,t)                  = abs(maxima(1,t)-minima(1,t));
        average(1,t)                = mean(mean(data.trial{1,1}(rawindx,:)));
        
        % jump artefact counter
        jumpthreshold               = 1e-10;
        nchans                      = length(chans);
        for c = 1:nchans
            jumps(c,t)              = length(find(diff(data.trial{1,1}(rawindx(c),:)) > jumpthreshold));
        end
        
        refchans                    = ft_channelselection('MEGREF', data.label);
        refindx                     = match_str(data.label, refchans);
        nrefs                       = length(refchans);
        for c = 1:nrefs
            refjumps(c,t)           = length(find(diff(data.trial{1,1}(refindx(c),:)) > jumpthreshold));
        end
        
        % determine noise
        freq                        = spectralestimate(data);
        [spec(:,:,t), foi]          = findpower(1, 400, freq);
        lowfreqnoise(1,t)           = mean(mean(findpower(0, 2, freq)));
        linenoise_prefilt           = mean(findpower(49, 51, freq),2); clear freq;
        
        % preproc with noise filter
        cfgpreproc2.dftfilter       = 'yes'; % notch filter to filter out 50Hz
        data2                       = ft_preprocessing(cfgpreproc2, data); clear data;
        
        % determine noise
        freq2                       = spectralestimate(data2); clear data2;
        linenoise_postfilt          = mean(findpower(49, 51, freq2),2); clear freq2;
        
        % ratio dft filtered data: (brain+line - brain) / brain+line
        linenoise(1,t)           = ...
            mean((linenoise_prefilt-linenoise_postfilt)./linenoise_prefilt);
        clear linenoise_prefilt; clear linenoise_postfilt;
        
        toc
    end % end of trial loop
    
    %% EXPORT TO .MAT
    output.datasetname  = datasetname;
    output.startrec     = startrec;
    output.starttime    = starttime;
    output.stoptime     = stoptime;
    output.fsample      = fsample;
    output.avg          = average;
    output.range        = range;
    output.minima       = minima;
    output.maxima       = maxima;
    output.jumps        = jumps;
    output.label        = chans;
    output.refjumps     = refjumps;
    output.reflabel     = refchans;
    output.linenoise    = linenoise;
    output.lowfreqnoise = lowfreqnoise;
    output.freq         = foi;
    output.powspctrm    = spec; % chan_freq_time where time is avg per 10 sec segments
    output.time         = (1:ntrials)*cfgdef.trialdef.poststim-.5*cfgdef.trialdef.poststim;
    output.hpos         = hpos;
    output.hmotion      = hmotion;
    output.grad         = gradfile;
    
    % save to .mat
    if strcmp(cfg.savemat,'yes')
        save(strcat(exportname,'.mat'), 'output');
    end
end

if strcmp(cfg.visualize,'yes')
    
    if strcmp(cfg.analyze,'no')
        load(strcat(exportname,'.mat'));
    end
    
    %% VISUALIZE
    % Parent figure
    h.MainFigure = figure(...
        'MenuBar','none',...
        'Name','ft_qualitycheck',...
        'Units','normalized',...
        'color','white',...
        'Position',[0.01 0.01 .99 .99]); % nearly fullscreen
    
    h.MainText = uicontrol(...
        'Parent',h.MainFigure,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',output.startrec,...
        'Backgroundcolor','white',...
        'Position',[.05 .96 .15 .02]);
    
    h.MainText2 = uicontrol(...
        'Parent',h.MainFigure,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String','Topographic artefact distribution',...
        'Backgroundcolor','white',...
        'Position',[.02 .46 .22 .02]);
    
    h.MainText3 = uicontrol(...
        'Parent',h.MainFigure,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String','Mean powerspectrum',...
        'Backgroundcolor','white',...
        'Position',[.4 .3 .15 .02]);
    
    h.MainText4 = uicontrol(...
        'Parent',h.MainFigure,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String','Timeplots',...
        'Backgroundcolor','white',...
        'Position',[.5 .96 .08 .02]);
    
    h.MainText5 = uicontrol(...
        'Parent',h.MainFigure,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String','Quantification',...
        'Backgroundcolor','white',...
        'Position',[.8 .3 .1 .02]);
    
    % plot the top 5 artefact chans
    [cnts, indx] = sort(sum(output.jumps,2));
    artchans = output.label(indx(end:-1:end-4));
    h.MainText6 = uicontrol(...
        'Parent',h.MainFigure,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',['Top 5'; artchans(1:end)],...
        'Backgroundcolor','white',...
        'Position',[.2 .24 .05 .14]);
    
    % Headmotion
    h.HmotionPanel = uipanel(...
        'Parent',h.MainFigure,...
        'Units','normalized',...
        'Backgroundcolor','white',...
        'Position',[.01 .5 .25 .47]);
    
    h.HmotionAxes = axes(...
        'Parent',h.HmotionPanel,...
        'Units','normalized',...
        'color','white',...
        'Position',[.05 .08 .9 .52]);
       
    h.DataText = uicontrol(...
        'Parent',h.HmotionPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',output.datasetname,...
        'Backgroundcolor','white',...
        'Position',[.01 .85 .99 .1]);
    
    h.TimeText = uicontrol(...
        'Parent',h.HmotionPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',[output.starttime ' - ' output.stoptime],...
        'Backgroundcolor','white',...
        'Position',[.01 .78 .99 .1]);
    
    h.DataText2 = uicontrol(...
        'Parent',h.HmotionPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',['fs: ' output.fsample ', nchans: ' num2str(size(output.label,1))],...
        'Backgroundcolor','white',...
        'Position',[.01 .71 .99 .1]);
    
    allchans = ft_senslabel('ctf275');
    misschans = setdiff(output.label, allchans);
    h.DataText3 = uicontrol(...
        'Parent',h.HmotionPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',['missing chans: ' misschans'],...
        'Backgroundcolor','white',...
        'Position',[.01 .64 .99 .1]);    
    
    % Topo artefact plot
    h.TopoPanel = uipanel(...
        'Parent',h.MainFigure,...
        'Units','normalized',...
        'Backgroundcolor','white',...
        'Position',[.01 .01 .25 .46]); 
    
    h.TopoREF = axes(...
        'Parent',h.TopoPanel,...
        'color','white',...
        'Position',[0.05 0.86 0.9 0.06]);
    
    h.TopoMEG = axes(...
        'Parent',h.TopoPanel,...
        'color','white',...
        'Position',[0.01 0.01 0.99 0.6]);
    
    % Mean spectrum
    h.SpectrumPanel = uipanel(...
        'Parent',h.MainFigure,...
        'Units','normalized',...
        'Backgroundcolor','white',...
        'Position',[.28 .01 .4 .3]);
    
    h.SpectrumAxes = axes(...
        'Parent',h.SpectrumPanel,...
        'color','white',...
        'Position',[.13 .17 .85 .73]);
    
    % Time plots
    h.SignalPanel = uipanel(...
        'Parent',h.MainFigure,...
        'Units','normalized',...
        'Backgroundcolor','white',...
        'Position',[.28 .34 .71 .63]);
    
    h.SignalAxes = axes(...
        'Parent',h.SignalPanel,...
        'Units','normalized',...
        'color','white',...
        'Position',[.08 .7 .89 .25]);
    
    h.LinenoiseAxes = axes(...
        'Parent',h.SignalPanel,...
        'Units','normalized',...
        'color','white',...
        'Position',[.08 .4 .89 .25]);
    
    h.LowfreqnoiseAxes = axes(...
        'Parent',h.SignalPanel,...
        'Units','normalized',...
        'color','white',...
        'Position',[.08 .1 .89 .25]);
    
    % Quick overview quantification sliders
    h.QuantityPanel = uipanel(...
        'Parent',h.MainFigure,...
        'Units','normalized',...
        'Backgroundcolor','white',...
        'Position',[.7 .01 .29 .3]);
    
    h.LineNoiseSlider = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','slider',...
        'Units','normalized',...
        'Value',mean(output.linenoise),...
        'Min',0,...
        'Max',1,...
        'Position',[.1 .35 .8 .2],...
        'String','Line noise');
    
    h.LineNoiseText = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String','Line noise [Ratio]',...
        'Backgroundcolor','white',...
        'Position',[.2 .55 .6 .07]);
    
    h.LineNoiseTextMin = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',get(h.LineNoiseSlider,'Min'),...
        'Backgroundcolor','white',...
        'Position',[.0 .35 .1 .2]);
    
    h.LineNoiseTextMax = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',get(h.LineNoiseSlider,'Max'),...
        'Backgroundcolor','white',...
        'Position',[.9 .35 .1 .2]);
    
    h.LowFreqSlider = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','slider',...
        'Units','normalized',...
        'Value',mean(output.lowfreqnoise),...
        'Min',0,...
        'Max',1e-20,...
        'SliderStep',[1e-23 1e-22],...
        'Position',[.1 .0 .8 .2],...
        'String','Low freq noise');
    
    h.LowFreqText = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String','Low freq power [T^2]' ,...
        'Backgroundcolor','white',...
        'Position',[.2 .2 .6 .07]);
    
    h.LowFreqTextMin = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',get(h.LowFreqSlider,'Min'),...
        'Backgroundcolor','white',...
        'Position',[.0 .0 .1 .2]);
    
    h.LowFreqTextMax = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',get(h.LowFreqSlider,'Max'),...
        'Backgroundcolor','white',...
        'Position',[.9 .0 .1 .2]);
    
    h.ArtifactSlider = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','slider',...
        'Units','normalized',...
        'Value',sum(sum(output.jumps,2),1)/10,...
        'Min',0,...
        'Max',50,...
        'Position',[.1 .7 .8 .2],...
        'String','Artifacts');
    
    h.ArtifactText = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String','Artifacts [#/10seconds]',...
        'Backgroundcolor','white',...
        'Position',[.2 .9 .6 .07]);
    
    h.ArtifactTextMin = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',get(h.ArtifactSlider,'Min'),...
        'Backgroundcolor','white',...
        'Position',[.0 .7 .1 .2]);
    
    h.ArtifactTextMax = uicontrol(...
        'Parent',h.QuantityPanel,...
        'Style','text',...
        'Units','normalized',...
        'FontSize',10,...
        'String',get(h.ArtifactSlider,'Max'),...
        'Backgroundcolor','white',...
        'Position',[.9 .7 .1 .2]);
    
    % plot artefacts on the dewar sensors
    cfgtopo               = [];
    cfgtopo.colorbar      = 'WestOutside';
    cfgtopo.commentpos    = 'leftbottom';
    cfgtopo.comment       = '# Artifacts';
    cfgtopo.style         = 'straight';
    cfgtopo.layout        = 'CTF275.lay';
    cfgtopo.colormap      = hot;
    cfgtopo.zlim          = 'maxmin';
    cfgtopo.interpolation = 'nearest';
    data.label            = output.label;
    data.powspctrm        = sum(output.jumps,2);
    data.dimord           = 'chan_freq';
    data.freq             = 1;
    axes(h.TopoMEG);
    ft_topoplotTFR(cfgtopo, data);
    
    % plot artefacts on the reference sensors
    data.label     = output.reflabel;
    data.powspctrm = output.refjumps;
    axes(h.TopoREF);
    plot_REF(data, h); clear data;
    
    % boxplot headmotion (*10; cm-> mm) per coil
    hmotions = ([output.hmotion(3,:)'  output.hmotion(2,:)' output.hmotion(1,:)'])*10;
    boxplot(h.HmotionAxes, hmotions, 'orientation', 'horizontal', 'notch', 'on');

    set(h.HmotionAxes,'YTick',[1:3]);
    set(h.HmotionAxes,'YTickLabel',{'R','L','N'}); 
    xlim(h.HmotionAxes, [0 10]);
    xlabel(h.HmotionAxes, 'Headposition from origin (mm)');
    
    % plot powerspectrum
    loglog(h.SpectrumAxes, output.freq, squeeze(mean(mean(output.powspctrm,1),3)),'r','LineWidth',2);
    xlabel(h.SpectrumAxes, 'Frequency [Hz]');
    ylabel(h.SpectrumAxes, 'Power [T^2/Hz]');
    
    % plot mean and range of the raw signal
    plot(h.SignalAxes, output.time, output.avg, output.time, output.range, 'LineWidth',3);
    grid(h.SignalAxes,'on');
    ylim(h.SignalAxes,[-Inf 4e-10]);
    legend(h.SignalAxes,'Mean','Range');
    set(h.SignalAxes,'XTickLabel','');
    
    % plot linenoise
    plot(h.LinenoiseAxes, output.time, output.linenoise, 'LineWidth',3);
    grid(h.LinenoiseAxes,'on');
    ylim(h.LinenoiseAxes,[0 1]);
    legend(h.LinenoiseAxes, 'Line noise ratio');
    set(h.LinenoiseAxes,'XTickLabel','');
    
    % plot lowfreqnoise
    semilogy(h.LowfreqnoiseAxes, output.time, output.lowfreqnoise, 'LineWidth',3);
    grid(h.LowfreqnoiseAxes,'on');
    legend(h.LowfreqnoiseAxes, 'Low freq power');
    xlabel(h.LowfreqnoiseAxes, 'Time [seconds]');
    
    %% EXPORT TO .PNG AND .PDF
    if strcmp(cfg.saveplot,'yes')
        set(gcf, 'PaperType', 'a4');
        print(gcf, '-dpng', strcat(exportname,'.png'));
        orient landscape;
        print(gcf, '-dpdf', strcat(exportname,'.pdf'));
    end
end

% varargout handler
if nargout>0
    mOutputArgs{1} = output;
    [varargout{1:nargout}] = mOutputArgs{:};
    clearvars -except varargout
else
    clear
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [freqoutput] = spectralestimate(data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cfgredef             = [];
cfgredef.length      = 1;
cfgredef.overlap     = 0;
redef                = ft_redefinetrial(cfgredef, data);

cfgfreq              = [];
cfgfreq.output       = 'pow';
cfgfreq.channel      = 'MEG';
cfgfreq.method       = 'mtmfft';
cfgfreq.taper        = 'hanning';
cfgfreq.keeptrials   = 'no';
cfgfreq.foilim       = [0 400]; % Fr ~ .1 hz
freqoutput           = ft_freqanalysis(cfgfreq, redef);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [power, freq] = findpower(low, high, freqinput)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% replace value with the index of the nearest bin
xmin  = nearest(getsubfield(freqinput, 'freq'), low);
xmax  = nearest(getsubfield(freqinput, 'freq'), high);
% select the freq range
power = freqinput.powspctrm(:,xmin:xmax);
freq = freqinput.freq(:,xmin:xmax);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_REF(dat, h)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare sensors
cfgref            = [];
cfgref.layout     = 'CTFREF.lay';
cfgref.layout     = ft_prepare_layout(cfgref);
cfgref.layout     = rmfield(cfgref.layout,'outline');

% Select the channels in the data that match with the layout:
[seldat, sellay] = match_str(dat.label, cfgref.layout.label);
if isempty(seldat)
    error('labels in data and labels in layout do not match');
end
datavector = dat.powspctrm(seldat,:);
labelvector = cfgref.layout.label(sellay);

% Plotting
imagesc(sum(datavector,2)');
colormap(hot);
set(h.TopoREF,'XTick',[1:length(labelvector)]);
for l = 1:length(labelvector)
    if sum(datavector(l,:),2) > 0
        Xlab{l} = labelvector{l};
    else
        Xlab{l} = '';
    end
end
set(h.TopoREF,'XTickLabel',Xlab);
set(h.TopoREF,'YTickLabel',{''});
title(h.TopoREF,'Reference sensors');