function spm_Deformations
%_______________________________________________________________________
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

% John Ashburner
% $Id$


SPMid = spm('FnBanner',mfilename,'$Rev$');
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Deformations');
spm_help('!ContextHelp',mfilename);

fig = spm_figure('GetWin','Interactive');
h0  = uimenu(fig,...
	'Label',	'Deformations',...
	'Separator',	'on',...
	'Tag',		'Def',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'Deformations from sn.mat',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_sn2def(''def'');',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'Tensors from sn.mat',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'HandleVisibility','on');
h2  = uimenu(h1,...
	'Label',	'Jacobian determinant',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_sn2def(''jacdet'');',...
	'HandleVisibility','on');
h2  = uimenu(h1,...
	'Label',	'Jacobian matrix',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_sn2def(''jacmat'');',...
	'HandleVisibility','on');
h2  = uimenu(h1,...
	'Label',	'Strain Tensors',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'HandleVisibility','on');
h3  = uimenu(h2,...
	'Label',	'Almansi Tensors (m=-2)',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_sn2def(''tensor'',-2);',...
	'HandleVisibility','on');
h3  = uimenu(h2,...
	'Label',	'        Tensors (m=-1)',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_sn2def(''tensor'',-1);',...
	'HandleVisibility','on');
h3  = uimenu(h2,...
	'Label',	'Hencky Tensors (m= 0)',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_sn2def(''tensor'',0);',...
	'HandleVisibility','on');
h3  = uimenu(h2,...
	'Label',	'Biot Tensors (m= 1)',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_sn2def(''tensor'',1);',...
	'HandleVisibility','on');
h3  = uimenu(h2,...
	'Label',	'Green Tensors (m= 2)',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_sn2def(''tensor'',2);',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'High-dimensional warping',...
	'Separator',	'on',...
	'Tag',		'Def',...
	'CallBack',	'spm_warp_ui;',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'Invert deformations',...
	'Separator',	'on',...
	'Tag',		'Def',...
	'CallBack',	'spm_invdef_ui;',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'Combine deformations',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_combdef_ui;',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'Apply deformations',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_applydef_ui;',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'Tensors from deformations',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'HandleVisibility','on');
h2  = uimenu(h1,...
	'Label',	'Jacobian determinant',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_def2det_ui;',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'Remove pose from deformations',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_procrustes_ui;',...
	'HandleVisibility','on');
h1  = uimenu(h0,...
	'Label',	'Visualise deformations',...
	'Separator',	'off',...
	'Tag',		'Def',...
	'CallBack',	'spm_visdef_ui;',...
	'HandleVisibility','on');
