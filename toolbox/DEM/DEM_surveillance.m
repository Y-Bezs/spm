function MDP = DEM_surveillance
% Demo of active (visual) scene-construction
%__________________________________________________________________________
%
% This routine uses a Markov decision process formulation of active
% inference (with belief propagation) to model active scene construction.
% It focuses on a discrete state space representation of a dynamic scene;
% generating visual snapshots at about the same frequency of saccadic eye
% movements. The generative model starts with latent states that correspond
% to natural kinds (e.g., objects) subject to natural laws (e.g., object
% invariance, classical mechanics, occlusion, and so on). A second latent
% factor (e.g., a 'where' stream) generates the fixation points in visual
% space for saccadic eye movements. The factors corresponding to multiple
% objects are themselves a Kronecker tensor product of attributes that
% depend upon each other; for example, position, velocity, pose, and
% non-spatial attributes that depend on spatial attributes. This
% interdependence means that object-specific attributes cannot be
% factorised; hence their combination as a tensor product (e.g., a 'what'
% stream).
%
% In what follows, we build a generative model, starting from state
% transitions that entail natural laws. Position refers to radial
% coordinates in egocentric space, implying a distinction between angular
% and radial (depth) states - and likewise for motion. This allows us to
% incorporate head orientation; in the form of head movements that
% reorientate the direction of gaze - that also depends upon the deployment
% of saccades in a head-centred frame of reference. Head movements are
% implemented, in the generative model, as moving objects in the egocentric
% frame of reference. This means that head movement is implemented via
% action-dependent transitions in location, while saccades are implemented
% via transitions among the latent states representing where gaze is
% deployed (in a head-centred frame of reference).
%
% Equipped with all of these hidden states, one can then complete a
% relatively simple generative model by specifying the likelihood mapping
% from hidden states to observations. This likelihood mapping is a high
% dimensional tensor - encoding all the high order dependencies generating
% visual input for the epoch in question. High order here refers to
% dependencies such as the interaction between two objects in the same line
% of sight that depends upon their relative depth to model occlusions.
%
% These outcomes are themselves discrete and multimodal. a high acuity
% modality models the parvocellular stream, with a restricted (central)
% field of view. This is complemented by two other modalities with a more
% peripheral field of view reporting contrast and motion energy, that is
% not spatially resolved (cf, the magnocellular stream). Note that in this
% construction (designed to generate the outputs of a computer vision
% scheme) motion is converted into a categorical (present versus absent)
% variable over discrete epochs of time. Note that the kind of scene
% construction and representation is implemented in egocentric and head
% centric frames of reference throughout. There is no part of the
% generative model that requires an allocentric representation - and yet,
% the agent can skilfully navigate a relatively complicated moving
% environment. in the example here, there are two inanimate objects (that
% play the role of landmarks) and an inanimate object (namely, a person who
% occasionally engages the agent with eye contact). This setup allows the
% simulation of reciprocal gaze and a primitive form of dyadic interaction.
% In other words, the prior preferences of this agent are to position
% itself and its direction of gaze to find someone who is looking at her.
%
% The code below is briefly annotated to illustrate how to build a
% generative model and then simulate active inference under that model, to
% produce relatively realistic sampling of a visual scene; namely, active
% scene construction. This inversion uses a sophisticated active inference
% scheme based upon a recursive estimation of expected free energy. This
% finesses the numerics because it uses belief propagation into the future
% - as opposed to marginal (variational) message passing. The numerical
% complexity of these models is a nontrivial issue: this is because most of
% the heavy lifting in the generative model is in the connectivity encoding
% dependencies that corresponds to high-dimensional tensors. In these
% simulations, the connectivity tensors are represented in working memory;
% whereas, in the brain or analogue (neuromorphic) implementations they
% would be simpler to instantiate.
%_________________________________________________________________________

% Karl Friston
% Copyright (C) 2008-2022 Wellcome Centre for Human Neuroimaging


rng('default')

%% set up and preliminaries
%==========================================================================

% Latent states
%--------------------------------------------------------------------------
% First we specify the hidden states for each factor (i.e., object). Each
% object has a number of attributes: line of sight, depth (foreground,
% background and distant), movement (none, right, left, retreat, approach),
% and disposition (e.g., looking in my direction or not).
%
% Note that there are several attributes that are shared by different
% objects or natural kinds; for example, an object can be in one of seven
% lines of sight. However, only animate objects can move.
%--------------------------------------------------------------------------

% number of: lines of sight, depth, motion and disposition
%--------------------------------------------------------------------------
N     = [ ...
    7,3,5,2;               % an animate object   (e.g., person)
    7,3,1,1;               % an inanimate object (e.g., landmark)
    7,3,1,1];              % an inanimate object (e.g., landmark)


% associate each object (i.e., natural kind) with a latent factor
%--------------------------------------------------------------------------
% This sets up a label structure with the names and cardinality of each
% factor and the accompanying latent states. These are further equipped
% with a number of actions that require a probability transition matrix for
% each allowable action. Here, the actions correspond to turning the head
% in one direction or another - or maintaining head position (the action
% 'stay')
%--------------------------------------------------------------------------
for i = 1:size(N,1)
    label.factor{i} = sprintf('kind %i',i);
    for j = 1:prod(N(i,:))
        label.name{i}{j}   = 'attributes';
    end
    label.action{i} = {'right','stay','left'};
end

% and as a controllable factor (line of sight): saccadic eye movements
%--------------------------------------------------------------------------
label.factor = [label.factor 'gaze'];
label.name   = [label.name   {{'right','centre','left'}}];
label.action = [label.action {{'right','centre','left'}}];

% with central and peripheral output modalities
%--------------------------------------------------------------------------
label.modality = {...
    'what',...
    'contrast-left',...
    'contrast-centre',...
    'contrast-right',...
    'motion-left',...
    'motion-centre',...
    'motion-right'};

% Central ('what') outcomes generated by object attributes
%--------------------------------------------------------------------------
label.outcome{1} = {  ...
    'person-near-right-yes',...
    'person-near-right-no',...
    'person-near-front-yes',...
    'person-near-front-no',...
    'person-near-left-yes',...
    'person-near-left-no',...
    'person-near-back',...
    'person-far-right',...
    'person-far-front',...
    'person-far-left',...
    'person-far-back',...
    'landmark-near',...
    'landmark-far',...
    'distance'};

% and the label contrast and motion energy in peripheral field of vision
%--------------------------------------------------------------------------
for i = 2:numel(label.modality)
    label.outcome{i} = {'near','far','none'};
end

%% Transitions: B
%==========================================================================
% Next, we specify the probabilistic transitions of hidden states for each
% factor (i.e., object).
%--------------------------------------------------------------------------
for i = 1:size(N,1)
    for j = 1:size(N,2)
        I{i,j} = speye(N(i,j),N(i,j));
    end
end

% spatial and non-spatial attributes of objects
%==========================================================================
% Transitions among these states are characterised by movement that induces
% conditional dependencies between location and motion, the location
% factorises into lines of sight and depth (i.e., egocentric polar
% coordinates)
%--------------------------------------------------------------------------
disp('specifying generative model (c.f., training)'), disp(' ')
for f = 1:size(N,1)
    
    % for each head motion, shift the scene
    %----------------------------------------------------------------------
    for u = 1:3
        
        % transitions along lines of sight that depend up (angular) movement
        %------------------------------------------------------------------
        b     = cell(N(f,3),N(f,3));
        c     = [-1,0,1];                     % head movements
        d     = [0 -1  1  0  0];              % object movements
        
        % shift angle appropriately by combining head and object movements
        %------------------------------------------------------------------
        for i = 1:N(f,3)
            b{i,i} = spm_speye(N(f,1),N(f,1),d(i) + c(u),1);  
        end
        
        % and place in a Kronecker tensor product
        %------------------------------------------------------------------
        b     = spm_kron({spm_cat(b),I{f,2},I{f,4}});         
        B{1}  = spm_permute_kron(b,N(f,[1,3,2,4]),[1,3,2,4]);
        
        % transitions between depth that depend upon (radial) movement
        %------------------------------------------------------------------
        b     = cell(N(f,3),N(f,3));
        d     = [0  0  0 -1  1];
        
        % shift depth appropriately (see spm_speye.m)
        %------------------------------------------------------------------
        for i = 1:N(f,3)
            b{i,i} = spm_speye(N(f,2),N(f,2),d(i),2);  
        end
        b     = spm_kron({I{f,1}, spm_cat(b),I{f,4}});
        B{2}  = spm_permute_kron(b,N(f,[1 2 3 4]),[1 2 3 4]);
        
        % transitions between movement that depend upon depth
        %------------------------------------------------------------------
        b      = cell(3,3);
        b{1,1} = [...     % when near...
            1 0 0 1 1;    % when near and standing tend to move or withdraw
            4 1 0 0 0;    % when near continue moving or withdraw
            4 0 1 0 0;    % when near continue moving or withdraw
            1 1 1 0 0;    % when near and withdrawing stand still
            0 0 0 0 0];   % when near and approaching stand still
        b{2,2} = [...     % when far...
            1 0 0 1 1;    % when Far and standing tend to move or approach
            4 4 0 0 0;    % ...
            4 0 4 0 0;
            1 0 0 0 0;
            4 1 1 0 0]; 
        b{3,3} = [...     % when distant...
            1 1 1 1 1;
            0 4 0 0 0;
            0 0 4 0 0;
            0 0 0 0 0;
            4 0 0 0 0];
        
        for i = 1:3
            b{i,i} = b{i,i}(1:N(f,3),1:N(f,3));
        end
        b     = b(1:N(f,2),1:N(f,2));
        b     = spm_kron({I{f,1}, spm_cat(b),I{f,4}});
        b     = bsxfun(@rdivide,b,sum(b));
        B{3}  = spm_permute_kron(b,N(f,[1 3 2 4]),[1 3 2 4]);
        
        
        % transitions between disposition that depends upon movement
        %------------------------------------------------------------------
        b      = cell(5,5);  
        b{1,1} = [4 4;1 1];    % positive disposition when standing
        b{2,2} = [4 1;1 4];    % maintain disposition when moving left
        b{3,3} = [4 1;1 4];    % maintain disposition when moving right
        b{4,4} = [0 0;1 1];    % look away when leaving
        b{5,5} = [4 4;1 1];    % look ahead when approaching
        
        for i = 1:5
            b{i,i} = b{i,i}(1:N(f,4),1:N(f,4));
        end
        b     = b(1:N(f,3),1:N(f,3));
        b     = spm_cat(b);
        b     = bsxfun(@rdivide,b,sum(b));
        b     = spm_kron({I{f,1},I{f,2},b});
        B{4}  = spm_permute_kron(b,N(f,[1 2 4 3]),[1 2 4 3]);
        
        % compose transitions over object attributes
        %------------------------------------------------------------------
        b  = 1;
        for i = 1:numel(B)
            b = full(b*B{i});
        end
        
        % transitions for this object and head motion
        %------------------------------------------------------------------
        T{f}(:,:,u) = b;
        
    end
end

% Finally, specify with controllable transitions among gaze directions
%--------------------------------------------------------------------------
nx    = numel(label.name{end});
nu    = numel(label.action{end});
b     = zeros(nx,nx,nu);
for u = 1:nu
    b(u,:,u) = 1;
end

% supplement B{:} and record the number of states for each factor
%--------------------------------------------------------------------------
B     = [T b];
for f = 1:numel(B)
    Nf(f) = size(B{f},1);
end
clear T


%% outcome probabilities: A
%==========================================================================
% Next, we specify the probabilistic mappings between latent states and
% outcomes with a tensor for each outcome modality, which models the high
% order interactions among the causes of outcomes (e.g., occlusion).
%--------------------------------------------------------------------------
for i = 1:numel(label.modality)
    A{i} = single(zeros([numel(label.outcome{i}),Nf]));
end

% loop over every combination of object attributes to specify outcomes
%--------------------------------------------------------------------------
% Here, we will assume that objects in the distance cannot be seen and that
% objects in the foreground occlude background objects. By construction,
% the dispositional (non-spatial) attributes of an object can only be
% observed when an object is in the foreground.
%
% Attributes:
%  line of sight: 1,2,...N(1)
%  depth:         foreground, background and distant
%  movement:      none, right, left, withdraw, approach
%  disposition:   looking or not
%--------------------------------------------------------------------------
c      = (N(1) + 1)/2;                 % central line of sight
los    = [-1 0 1] + c;                 % saccadic lines of side
for o1 = 1:Nf(1)
    for o2 = 1:Nf(2)
        for o3 = 1:Nf(3)
            for u = 1:Nf(4)
                
                % object attributes
                %==========================================================
                o = [o1,o2,o3];
                
                % Unpack object attributes for this combination of objects
                %----------------------------------------------------------
                for i = 1:size(N,1)
                    [a1,a2,a3,a4] = spm_ind2sub(N(i,:),o(i)); % attributes of ith object
                    a(i,:)        = [a1,a2,a3,a4];            % object x attribute array
                end
                
                % {'what'}: outcomes
                %----------------------------------------------------------
                %     'person-near-right-yes',...1
                %     'person-near-right-no',... 2
                %     'person-near-front-yes',...3
                %     'person-near-front-no',... 4
                %     'person-near-left-yes',... 5
                %     'person-near-left-no',...  6
                %     'person-near-back',...     7
                %     'person-far-right',...     8
                %     'person-far-front',...     9
                %     'person-far-left',...     10
                %     'person-far-back',...     11
                %     'landmark-near',...       12
                %     'landmark-far',...        13
                %     'distance',...            14
                %----------------------------------------------------------
                
                % nearest (foreground or background) object in line of sight
                %----------------------------------------------------------
                s     = find(a(:,1) == los(u) & a(:,2) < 3);
                [d,i] = min(a(s,2));
                i     = s(i);
                
                % generate outcome from i-th object
                %----------------------------------------------------------
                o     = spm_what(a(i,:),i);
                A{1}(o,o1,o2,o3,u) = true;
                
                
                % {'contrast-left'}:
                %----------------------------------------------------------
                % near...1
                % far... 2
                % none...3
                %----------------------------------------------------------
                
                % find nearest object on the left line of sight
                %----------------------------------------------------------
                s     = find(a(:,1) == (los(u) - 1) & a(:,2) < 3);
                [d,i] = min(a(s,2));
                i     = s(i);
                
                % and get contrast and motion energy
                %----------------------------------------------------------
                o     = spm_contrast_energy(a(i,:));
                A{2}(o,o1,o2,o3,u) = true;
                o     = spm_motion_energy(a(i,:));
                A{5}(o,o1,o2,o3,u) = true;
                
                
                % {'contrast-centre'}
                %----------------------------------------------------------
                s     = find(a(:,1) == (los(u) - 0) & a(:,2) < 3);
                [d,i] = min(a(s,2));
                i     = s(i);
                
                % and get contrast and motion energy
                %----------------------------------------------------------
                o     = spm_contrast_energy(a(i,:));
                A{3}(o,o1,o2,o3,u) = true;
                o     = spm_motion_energy(a(i,:));
                A{6}(o,o1,o2,o3,u) = true;
                
                % {'contrast-right'}
                %----------------------------------------------------------
                s     = find(a(:,1) == (los(u) + 1) & a(:,2) < 3);
                [d,i] = min(a(s,2));
                i     = s(i);
                
                % and get contrast energy
                %----------------------------------------------------------
                o     = spm_contrast_energy(a(i,:));
                A{4}(o,o1,o2,o3,u) = true;
                o     = spm_motion_energy(a(i,:));
                A{7}(o,o1,o2,o3,u) = true;
                
            end  
        end
    end
end



%% priors: (utility) C
%--------------------------------------------------------------------------
% Finally, we have to specify the prior preferences in terms of log
% probabilities over outcomes. Here, the agent prefers eye contact but
% finds staring at someone with averted gaze aversive.
%--------------------------------------------------------------------------
% {'what'}: outcomes
%--------------------------------------------------------------------------
%     'person-near-right-yes',...1
%     'person-near-right-no',... 2
%     'person-near-front-yes',...3
%     'person-near-front-no',... 4
%     'person-near-left-yes',... 5
%     'person-near-left-no',...  6
%     'person-near-back',...     7
%     'person-far-right',...     8
%     'person-far-front',...     9
%     'person-far-left',...     10
%     'person-far-back',...     11
%     'landmark-near',...       12
%     'landmark-far',...        13
%     'distance',...            14
%--------------------------------------------------------------------------
C{1}  = [2 -1 2 -1 2 -1 0 0 0 0 0 0 0 0];

% and uninformative preferences over peripheral vision
%--------------------------------------------------------------------------
for i = 2:numel(A)
    C{i}  = zeros(1,size(A{i},1));
end

% This concludes the ABC of the model; namely, the likelihood mapping,
% prior transitions and preferences. Now, specify prior beliefs about
% initial states
%--------------------------------------------------------------------------
D{1} = sparse(sub2ind(N(1,:),4,2,3,2),1,1,prod(N(1,:)),1); % someone in the background
D{2} = sparse(sub2ind(N(2,:),5,2,1,1),1,1,prod(N(2,:)),1); % landmark in the background
D{3} = sparse(sub2ind(N(3,:),2,3,1,1),1,1,prod(N(3,:)),1); % landmark in the distance
D{4} = [0,1,0];                                            % centre gaze

% introduce some uncertainty about the scene
%--------------------------------------------------------------------------
D{1} = D{1} + 4;
D{2} = D{2} + 4;
D{3} = D{3} + 4;

% and initialise actual states
%--------------------------------------------------------------------------
s(1,1) = sub2ind(N(1,:),4,2,3,2); % someone in the background
s(2,1) = sub2ind(N(2,:),5,2,1,1); % landmark in the background
s(3,1) = sub2ind(N(3,:),2,2,1,1); % landmark in the background

% allowable actions (with an action for each controllable state)
%--------------------------------------------------------------------------
U     = [ ...
    2     2     2     1;          % saccade to right line of sight
    2     2     2     2;          % saccade to centre line of sight      
    2     2     2     3;          % saccade to left line of sight
    1     1     1     1;          % turn to the right and saccade right
    3     3     3     3];         % turn to the left and saccade left

% MDP Structure, specifying 64 epochs (i.e., 16 seconds of active vision)
%==========================================================================
mdp.T = 64;                       % numer of moves
mdp.U = U;                        % actions
mdp.A = A;                        % likelihood probabilities
mdp.B = B;                        % transition probabilities
mdp.C = C;                        % prior preferences
mdp.D = D;                        % prior over initial states
mdp.N = 0;                        % policy depth
mdp.s = s;                        % initial state

mdp.label = label

% Solve - an example with multiple epochs to illustrate how the agent
% resolves uncertainty about where she is looking and comes to track
% anybody who might be looking at her
%==========================================================================
disp('inverting generative model (c.f., active inference)'), disp(' ')
OPTIONS.N = 1;
OPTIONS.B = 0;
MDP       = spm_MDP_VB_XXX(mdp,OPTIONS);

% illustrate scene construction and perceptual synthesis
%--------------------------------------------------------------------------
spm_figure('GetWin','Active inference'); clf
spm_surveillance_percept(MDP,N)

% illustrate behavioural responses
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 1'); clf
spm_MDP_VB_trial(MDP);

% illustrate physiological responses (first unit at the fourth epoch)
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 2'); clf
spm_MDP_VB_LFP(MDP,[1;4],2);

% focus on first two seconds
%--------------------------------------------------------------------------
for i = 1:4
    subplot(3,2,i), set(gca,'XLim',[0 2])
end

return


% subroutines
%==========================================================================

function o = spm_what(a,k)
% returns an outcome vector from a list of attributes
% FORMAT o = spm_what(a,k)
% a   -  attribute
% k   -  natural kind
%
% {'what'}: outcomes
%--------------------------------------------------------------------------
%     'person-near-right-yes',...1
%     'person-near-right-no',... 2
%     'person-near-front-yes',...3
%     'person-near-front-no',... 4
%     'person-near-left-yes',... 5
%     'person-near-left-no',...  6
%     'person-near-back',...     7
%     'person-far-right',...     8
%     'person-far-front',...     9
%     'person-far-left',...     10
%     'person-far-back',...     11
%     'landmark-near',...       12
%     'landmark-far',...        13
%     'background',...          14
%--------------------------------------------------------------------------

% if there is an object or natural kind
%--------------------------------------------------------------------------
if any(a)
    
    % animate object:
    %      depth        direction    disposition
    %----------------------------------------------------------------------
    if k == 1
        
        if     a(2) == 1 && a(3) == 2 && a(4) == 1
            o = 1;
        elseif a(2) == 1 && a(3) == 2 && a(4) == 2
            o = 2;
        elseif a(2) == 1 && (a(3) == 1 || a(3) == 5) && a(4) == 1
            o = 3;
        elseif a(2) == 1 && (a(3) == 1 || a(3) == 5) && a(4) == 2
            o = 4;
        elseif a(2) == 1 && a(3) == 3 && a(4) == 1
            o = 5;
        elseif a(2) == 1 && a(3) == 3 && a(4) == 2
            o = 6;
        elseif a(2) == 1 && a(3) == 4
            o = 7;
        elseif a(2) == 2 && a(3) == 2
            o = 8;
        elseif a(2) == 2 && (a(3) == 1 || a(3) == 5)
            o = 9;
        elseif a(2) == 2 && a(3) == 3
            o = 10;
        elseif a(2) == 2 && a(3) == 4
            o = 11;
        else
            o = 14;
        end
        
    elseif k == 2 || k == 3
        
        %  inanimate object, near or far
        %------------------------------------------------------------------
        if     a(2) == 1
            o = 12;
        elseif a(2) == 2
            o = 13;
        else
            o = 14;
        end
        
    else
        
        %  background object
        %------------------------------------------------------------------
        o = 14;
    end
    
else
    
    % nothing to see
    %----------------------------------------------------------------------
    o = 14;
    
end


function o = spm_contrast_energy(a)
% returns an outcome vector from a list of attributes
% FORMAT o = spm_what(a)
% a   -  attribute
%
% {'where'}: outcomes
%--------------------------------------------------------------------------
% near...1
% far... 2
% none...3
%--------------------------------------------------------------------------

% if there is an object or natural kind
%--------------------------------------------------------------------------
if any(a)
    if  a(2) == 1
        o = 1;                % if an object is in foreground
    elseif a(2) == 2
        o = 2;                % if an object in background
    else
        o = 3;                % object is in the distance
    end
else
    o = 3;                    % or none in this line of sight
end

return


function o = spm_motion_energy(a)
% returns an outcome vector from a list of attributes
% FORMAT o = spm_what(a,k)
% a   -  attribute
%
% {'where'}: outcomes
%--------------------------------------------------------------------------
% near...1
% far... 2
% none...3
%--------------------------------------------------------------------------

% if there is an object or natural kind
%--------------------------------------------------------------------------
if any(a)
    if a(3) > 1                % if there is motion
        if a(2) == 1
            o = 1;             % in foreground
        elseif a(2) == 2
            o = 2;             % or background
        else
            o = 3;             % in the distance
        end
    else
        o = 3;                 % not moving
    end
else
    o = 3;                     % no object in line of sight
end

return

function spm_surveillance_percept(MDP,N)
%% illustrates visual search graphically
%--------------------------------------------------------------------------
% number of: lines of sight, depth, object motion and disposition
%--------------------------------------------------------------------------
% N     = [ ...
%     7,3,5,2;               % an animate object   (e.g., person)
%     7,3,1,1;               % an inanimate object (e.g., landmark)
%     7,3,1,1;               % an inanimate object (e.g., landmark)
%     7,1,1,1];              % a background object (e.g., horizon)

% load images
%--------------------------------------------------------------------------
load DEM_scene
[k,l,m] = size(outcomes{1});

% {'what'}: outcomes{1}
%--------------------------------------------------------------------------
%     'person-near-right-yes',...1
%     'person-near-right-no',... 2
%     'person-near-front-yes',...3
%     'person-near-front-no',... 4
%     'person-near-left-yes',... 5
%     'person-near-left-no',...  6
%     'person-near-back',...     7
%     'person-far-right',...     8
%     'person-far-front',...     9
%     'person-far-left',...     10
%     'person-far-back',...     11
%     'landmark-near',...       12
%     'landmark-far',...        13
%     'background',...          14
%--------------------------------------------------------------------------

% loop over time
%--------------------------------------------------------------------------
for t = 1:MDP.T
    
    % what the agent actually sees
    %======================================================================
    
    % peripheral vision, or magnocellular (contrast energy)
    % foveal (central) vision, or parvocellular (contrast energy)
    % peripheral vision, or magnocellular (motion energy)
    %----------------------------------------------------------------------
    seen  = { ...
        outcomes{2}(:,:,MDP.o(2,t)) outcomes{2}(:,:,MDP.o(3,t)) outcomes{2}(:,:,MDP.o(4,t));
        outcomes{1}(:,:,end)        outcomes{1}(:,:,MDP.o(1,t)) outcomes{1}(:,:,end);
        outcomes{2}(:,:,MDP.o(5,t)) outcomes{2}(:,:,MDP.o(6,t)) outcomes{2}(:,:,MDP.o(7,t))};
    seen  = spm_cat(seen);
    
    subplot(3,1,2)
    image(spm_cat(seen))
    axis image, box off
    vision(t) = getframe(gca);
    
    % actual scene
    %======================================================================
    subplot(3,1,1)
    
    % Unpack object attributes for this combination of objects
    %----------------------------------------------------------------------
    for i = 1:size(N,1)
        [a1,a2,a3,a4] = spm_ind2sub(N(i,:),MDP.s(i,t)); % attributes of ith object
        a(i,:)        = [a1,a2,a3,a4];                  % object x attribute array
    end
    
    for j = 1:N(1)
        
        % nearest (foreground or background) object in line of sight
        %------------------------------------------------------------------
        s        = find(a(:,1) == j & a(:,2) < 3);
        [d,i]    = min(a(s,2));
        i        = s(i);
        
        % generate outcome from i-th object
        %------------------------------------------------------------------
        o        = spm_what(a(i,:),i);
        scene{j} = outcomes{1}(:,:,o);
    end
    
    % add direction of gaze and display
    %----------------------------------------------------------------------
    s    = MDP.s(end,t);
    s    = (N(1) + 1)/2 - 2 + s;
    image(spm_cat(scene))
    text(l*(s - 1/2),k/2,'+','FontSize',32,'Color','r')
    axis image, box off
    actual(t) = getframe(gca);
    
    
    % what the agent thinks she sees
    %======================================================================
    subplot(3,1,3)
    
    % find the most likely state of each object
    %----------------------------------------------------------------------
    for i = 1:size(N,1)
        [q,j] = max(MDP.X{i}(:,t));
        s(i) = j;
        p(i) = q;
    end
    
    % Unpack object attributes for this combination of objects
    %----------------------------------------------------------------------
    for i = 1:size(N,1)
        [a1,a2,a3,a4] = spm_ind2sub(N(i,:),s(i)); % attributes of ith object
        a(i,:)        = [a1,a2,a3,a4];            % object x attribute array
    end
    
    % find what would have been seen in line of sight
    %------------------------------------------------------------------
    for j = 1:N(1)
        
        % nearest (foreground or background) object in line of sight
        %------------------------------------------------------------------
        s     = find(a(:,1) == j & a(:,2) < 3);
        [d,i] = min(a(s,2));
        i     = s(i);
        
        % generate outcome from i-th object and weight by certainty
        %------------------------------------------------------------------
        o        = spm_what(a(i,:),i);
        o        = outcomes{1}(:,:,o);
        if i
            % modulate by uncertainty (the probability of most likely state
            %--------------------------------------------------------------
            scene{j} = 64 - p(i)*(64 - o);
        else
            scene{j} = o;
        end
    end
    
    % add direction of gaze and display
    %----------------------------------------------------------------------
    [q,s] = max(MDP.X{end}(:,t));
    s     = (N(1) + 1)/2 - 2 + s;
    image(spm_cat(scene))
    text(l*(s - 1/2),k/2,'+','FontSize',32,'Color','r')
    axis image, box off
    percept(t) = getframe(gca);
    
end

% assign movies to each graph object
%--------------------------------------------------------------------------
subplot(3,1,2)
set(gca,'Userdata',{vision,4})
set(gca,'ButtonDownFcn','spm_DEM_ButtonDownFcn')
title('Visual samples','FontSize',14)

subplot(3,1,1)
set(gca,'Userdata',{actual,4})
set(gca,'ButtonDownFcn','spm_DEM_ButtonDownFcn')
title('Actual scene','FontSize',14)

subplot(3,1,3)
set(gca,'Userdata',{percept,4})
set(gca,'ButtonDownFcn','spm_DEM_ButtonDownFcn')
title('Perceived scene','FontSize',14)

return
