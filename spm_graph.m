function [Y,y,BETA,SE] = spm_graph(SPM,VOL,DES,hReg)
% graphical display of adjusted data
% FORMAT [Y y BETA SE] = spm_graph(SPM,VOL,DES,hReg)
%
% SPM  - SPM structure      {'Z' 'n' 'STAT' 'df' 'u' 'k'}
% VOL  - Spatial structure  {'R' 'FWHM' 'S' 'DIM' 'VOX' 'ORG' 'M' 'XYZ' 'QQ'}
% DES  - Design structure   {'X' 'C' 'B'}
% hReg - handle of MIP register
%
% Y    - fitted   data for the selected voxel
% Y    - adjusted data for the selected voxel
% BETA - parameter estimates
% SE   - standard error of parameter estimates
%
% see spm_getSPM for details
%_______________________________________________________________________
%
% spm_graph is a CallBack script that uses the strcutures above to
% produce plots of adjusted activity at the significant (p < 0.05
% uncorrected according the the F statistic following the AnCova) that is
% nearest to the point selected.  These mean activities are the average
% estimates over subjects.  If these estimates derive from an activation
% study (the effects are factors described by the H partition) the data
% are plotted as a bar chart,  If they derive from covariates (C) then
% they are plotted as against [a compound of] the covariates or scan
% number as specified by you.  The adjusted data for the selected voxel
% are displayed in the command window for potential use outside SPM.  The
% vatiables x and y contain the ordinates and activities respectively in
% the order in which the scans were entered (i.e. the same as the design
% matrix, The variable Y represents the fitted responses [e.g. means]
% accross subjects).
%
%_______________________________________________________________________
% %W% Karl Friston %E%


%-Get figure handles and filenames
%-----------------------------------------------------------------------
Finter = spm_figure('FindWin','Interactive');
Fgraph = spm_figure('FindWin','Graphics');
global CWD


%-Delete previous axis and their pagination controls (if any)
%-----------------------------------------------------------------------
spm_results_ui('ClearPane',Fgraph,'RNP');
subplot(2,1,2)

%-Load ER.mat (event-related) file if it exists
%-----------------------------------------------------------------------
str    = [CWD,'/ER.mat'];
if exist(str,'file'); load(str); end


% Find nearest voxel [Euclidean distance] in point list XYZ & update GUI
%-----------------------------------------------------------------------
L      = spm_XYZreg('GetCoords',hReg);
[L,i]  = spm_XYZreg('NearestXYZ',L,VOL.XYZ);
spm_XYZreg('SetCoords',L,hReg);


% Get adjusted data y and fitted effects Y
%-----------------------------------------------------------------------
y      = spm_readXA(VOL.QQ(i));			% data
BETA   = pinv(DES.X)*y;				% parameter estimate
Y      = DES.X*BETA;				% fitted data
R      = y - Y;					% residuals
RES    = sum(R.^2);				% SSQ of residuals
SE     = sqrt(RES*diag(DES.B));			% standard error of estimates
COL    = ['r' 'b' 'g' 'c' 'y' 'm' 'r' 'b' 'g' 'c' 'y' 'm'];

% Inference (for xlabel)
%-----------------------------------------------------------------------
Z      = SPM.Z(i);
Pz     = spm_P(1,0,Z,SPM.df,SPM.STAT,1,    SPM.n);
Pu     = spm_P(1,0,Z,SPM.df,SPM.STAT,VOL.R,SPM.n);
STR    = [SPM.STAT sprintf(' = %0.2f, p = %0.3f (%.3f corrected.)',Z,Pz,Pu)];


% find out what to plot
%----------------------------------------------------------------------
Cplot = str2mat(...
		'Parameter estimates',...
		'Responses',...
		'Event-related responses');
str   = 'plot ';
Cp    = spm_input(str,1,'m',Cplot,[1:size(Cplot,1)]);
TITLE = deblank(Cplot(Cp,:));



% plot parameter estimates
%----------------------------------------------------------------------
if     Cp == 1

	% specify [contrasts] of parameter estimate to bar
	%--------------------------------------------------------------
	Cplot = str2mat(...
		'All parameters',...
		'Parameters specified by contrast',...
		'Contrast of parameters');
	str   = 'Estimates to plot';
	Cp    = spm_input(str,1,'m',Cplot,[1:size(Cplot,1)]);
	TITLE = deblank(Cplot(Cp,:));
	XLAB  = 'effect';


	if     Cp == 1
		
		BETA = BETA(1:size(DES.C,2));
		SE   = SE(1:size(DES.C,2));

	elseif Cp == 2

		BETA = BETA(any(DES.C,1));
		SE   = SE(any(DES.C,1));

	elseif Cp == 3

		BETA = DES.C*BETA;
		SE   = sqrt(diag(RES*DES.C*DES.B*DES.C'));
		XLAB = 'contrast';

	end


	% bar chart
	%--------------------------------------------------------------
	figure(Fgraph)
	h     = bar(BETA);
	set(h,'FaceColor',[1 1 1]*.8)
	for j = 1:length(BETA)
		line([j j],([SE(j) 0 - SE(j)] + BETA(j)),...
			    'LineWidth',3,'Color','r')
	end



% All fitted effects or selected effects
%-----------------------------------------------------------------------
elseif Cp == 2

	% fitted data
	%---------------------------------------------------------------
	Cplot = str2mat(...
			'All effects',...
			'subspace spanned by contrast.',...
			'subspace of the contrast.',...
			'specified effects');
	str   = 'Fit';
	Cx    = spm_input(str,1,'m',Cplot,[1:size(Cplot,1)]);
	TITLE = [TITLE ': ' deblank(Cplot(Cp,:))];


	if     Cx == 1
		
		Y    = DES.X*BETA;

	elseif Cx == 2

		i    = any(DES.C,1);
		Y    = DES.X(:,i)*BETA(i);

	elseif Cx == 3

		X    = DES.X*DES.C';
		Y    = X*(pinv(X)*y);

	elseif Cx == 4

		str  = sprintf('columns or effects 1 - %0.0f',size(DES.X,2));
		i    = spm_input(str,'!+1','e',1);
		Y    = DES.X(:,i)*BETA(i);
	end


	% adjusted data
	%---------------------------------------------------------------
	y     = Y + R;


	% get ordinates
	%---------------------------------------------------------------
	Cplot = str2mat(...
			'A column of design matrix',...
			'Contrast of design matrix',...
			'scan or time.',...
			'a user specified ordinate');
	str   = 'plot against';
	Cx    = spm_input(str,1,'m',Cplot,[1:size(Cplot,1)]);

	if     Cx == 1

		str  = sprintf('column 1 - %0.0f',size(DES.X,2));
		i    = spm_input(str,'!+1','e',1);
		x    = DES.X(:,i);
		XLAB = sprintf('Explanatory variable %0.0f',i);

	elseif Cx == 2

		x    = DES.X*DES.C(1,:)';
		XLAB = 'Contrast of Explanatory variables';

	elseif Cx == 3

		if exist('RT')
			x    = RT*[1:size(Y,1)]';
			XLAB = 'time {seconds}';
		else
			x    = [1:size(Y,1)]';
			XLAB = 'scan number';
		end

	elseif Cx == 3

		x    = [];
		str  = sprintf('enter {1 x %0.0f} ordinate',size(Y,1));
		while length(x) ~= length(Y)
			x    = spm_input(str,'!+1');
			x    = x(:);
		end
		XLAB = 'ordinate';

	end

	% plot
	%---------------------------------------------------------------
	figure(Fgraph)
	[p q] = sort(x);
	if all(diff(x(q)))
		plot(x(q),y(q),':b'); hold on
		plot(x(q),y(q),'.b','MarkerSize',8); hold on
		plot(x(q),Y(q),'r' ); hold off

	else
		plot(x(q),y(q),'.b', 'MarkerSize',8); hold on
		plot(x(q),Y(q),'.r','MarkerSize',16); hold off

	end
	set(gca,'XLim',[-1 1] + get(gca,'XLim'))



% modeling evoked responses
%----------------------------------------------------------------------
elseif Cp == 3

	j     = 1;
	if size(ERI,2) > 1
		j    = spm_input('which events',1,'e','1 2');
	end
	Cplot = str2mat(...
			'Fitted response',...
			'Fitted response and PSTH.',...
			'Fitted response +/- standard error of response.',...
			'Fitted response +/- standard error of onset.',...
			'Fitted response and adjusted data');
	str   = 'plot in terms of';
	Cp    = spm_input(str,'!+1','m',Cplot,[1:size(Cplot,1)]);
	TITLE = deblank(Cplot(Cp,:));


	% cycle over selected events
	%--------------------------------------------------------------
	dx    = 0.1;
	x     = [0:(size(DER,1) - 1)]'*dx - 4;

	% reconstruct response without smoothing
	%--------------------------------------------------------------
	figure(Fgraph)
	XLAB  = 'peri-stimulus time {secs}';
	hold on
	u     = 1;
	for i = j
		Y      = DER*BETA(ERI(:,i));
		se     = sqrt(diag(DER*DES.B(ERI(:,i),ERI(:,i))*DER')*RES);
		pst    = PST(:,i);
		bin    = round((pst + 4)/dx);
		q      = find( (bin >= 1) & (bin <= size(DER,1)) & pst);
		bin    = bin(q);
		pst    = pst(q);
		y      = DER(bin,:)*BETA(ERI(:,i)) + R(q);
		v      = min(find(abs(Y) > max(abs(Y))/2));
		T      = x(v);
		dYdt   = gradient(Y')'/dx;
		seT    = se(v)./dYdt(v);

		% PSTH
		%------------------------------------------------------
		dBIN   = 2/dx;
		BIN    = 1/dx:dBIN:32/dx;
		PSTH   = zeros(length(BIN) - 1,1);
		SEM    = zeros(length(BIN) - 1,1);
		for k  = 1:(length(BIN) - 1)
			q = find(bin > BIN(k) & bin <= BIN(k + 1));
			n = length(q);
			if n
				PSTH(k) = mean(y(q));
				SEM(k)  = std(y(q))/sqrt(n);
			end
		end
		BIN    = (BIN(1:k) + dBIN/2)*dx - 4;
		

		% plot
		%------------------------------------------------------
		if Cp == 1
			plot(x,Y,COL(u))

		elseif Cp == 2
			errorbar(BIN,PSTH,SEM,[':' COL(u)])
			plot(BIN,PSTH,['.' COL(u)],'MarkerSize',16), hold on
			plot(BIN,PSTH,COL(u),'LineWidth',2)
			plot(x,Y,['-.' COL(u)])
			TITLE = 'Peristimulus histogram (2s bins with sem)';

		elseif Cp == 3
			plot(x,Y,COL(u),x,Y + se,...
				['-.' COL(u)],x,Y - se,['-.' COL(u)])

		elseif Cp == 4
			plot(x,Y,COL(u))
			line(([-seT seT] + T),[Y(v) Y(v)],'LineWidth',6)

		elseif Cp == 5
			plot(x,Y,COL(u),pst,y,['.' COL(u)],...
				'MarkerSize',8,'LineWidth',2)

		end
		XLAB = str2mat(XLAB,[sprintf('Trial type %d - ',i) COL(u)]);
		u    = u + 1;
	end

	hold off; axis on
	set(gca,'XLim',[min(x) max(x)])

end


% Label and call Plot UI
%----------------------------------------------------------------------
axis square
XLAB      = str2mat(XLAB,STR);
YLAB      = 'effect size';
xlabel(XLAB, 'FontSize',10)
ylabel(YLAB,'FontSize',10)
title(TITLE,'FontSize',16)

spm_results_ui('PlotUi',gca)
