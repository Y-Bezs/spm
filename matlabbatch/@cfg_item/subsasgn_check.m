function [sts, val] = subsasgn_check(item,subs,val)

% function [sts, val] = subsasgn_check(item,subs,val)
% Do a check for proper assignments of values to fields. This routine
% will be called for derived objects from @cfg_.../subsasgn with the
% original object as first argument and the proposed subs and val fields
% before an assignment is made. It is up to each derived class to
% implement assignment checks for both its own fields and fields
% inherited from cfg_item. If used for assignment checks for inherited
% fields, these must be dealt with in special cases in @cfg_.../subsasgn
% 
% This routine is a both a check for cfg_item fields and a fallback
% placeholder in cfg_item if a derived class does not implement its own
% checks. In this case it always returns true. A derived class may also
% check assignments to cfg_item fields (e.g. to enforce specific validity
% checks for .val fields). subsasgn_check of the derived class is called
% before this generic subsasgn_check is called and both checks need to be
% passed.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: subsasgn_check.m 1862 2008-06-30 14:12:49Z volkmar $

rev = '$Rev: 1862 $'; %#ok

sts = true;
switch class(item)
    case {'cfg_item'}
        % do subscript checking for base class
        switch subs(1).subs
            case {'tag', 'name'},
                if ~ischar(val)
                    cfg_message('matlabbatch:check:tagname', '%s: Value must be a string.', subsasgn_checkstr(item,subs));
                    sts = false;
                end
            case {'val'},
                % Check match of a dependency. Other item-specific checks
                % are performed in an item's subsasgn_check.
                if isa(val, 'cfg_dep')
                    sts = match(item, cfg_dep.tgt_spec);
                    if ~sts
                        cfg_message('matlabbatch:checkval', '%s: Dependency does not match.', subsasgn_checkstr(item,subs));
                    end
                end
            case {'check'},
                if ~subsasgn_check_funhandle(val)
                    cfg_message('matlabbatch:check:funhandle', ...
                            ['%s: Value must be a function or function ' ...
                             'handle on MATLAB path.'], subsasgn_checkstr(item,subs));
                    sts = false;
                end
            case {'help'},
                if isempty(val)
                    val = {};
                elseif ~iscellstr(val)
                    cfg_message('matlabbatch:check:help', '%s: Value must be a cell string.', subsasgn_checkstr(item,subs));
                    sts = false;
                end
            case {'def'},
                if isempty(val)
                    val = [];
                elseif ~subsasgn_check_funhandle(val)
                    cfg_message('matlabbatch:check:def', '%s: Value must be a function or function handle.', subsasgn_checkstr(item,subs));
                    sts = false;
                end
            case {'hidden', 'expanded'},
                if ~islogical(val)
                    cfg_message('matlabbatch:check:hiddenexpanded', '%s: Value must be ''true'' or ''false''.', subsasgn_checkstr(item,subs));
                    sts = false;
                end
        end
    otherwise
        % fall back for derived classes
        sts = true;
end
