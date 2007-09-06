function [DCM] = spm_dcm_ind_results(DCM,Action)
% Results for induced Dynamic Causal Modeling (DCM)
% FORMAT spm_dcm_ind_results(DCM,Action);
% Action:
% 'Frequency modes'
% 'Time-modes'
% 'Time-frequency'
% 'Coupling (A)'
% 'Coupling (B)'
% 'Input (C)'
% 'Input'
% 'Dipoles'
%                
%___________________________________________________________________________
%
% DCM is a causal modelling procedure for dynamical systems in which
% causality is inherent in the differential equations that specify the model.
% The basic idea is to treat the system of interest, in this case the brain,
% as an input-state-output system.  By perturbing the system with known
% inputs, measured responses are used to estimate various parameters that
% govern the evolution of brain states.  Although there are no restrictions
% on the parameterisation of the model, a bilinear approximation affords a
% simple re-parameterisation in terms of effective connectivity.  This
% effective connectivity can be latent or intrinsic or, through bilinear
% terms, model input-dependent changes in effective connectivity.  Parameter
% estimation proceeds using fairly standard approaches to system
% identification that rest upon Bayesian inference.
% 
%__________________________________________________________________________
% %W% Karl Friston %E


% get figure handle
%--------------------------------------------------------------------------
Fgraph = spm_figure('GetWin','Graphics');
figure(Fgraph)
clf

xY     = DCM.xY;
nt     = size(xY.xf,1);          % Nr of trial types
nf     = size(xY.xf,2);          % Nr of frequnecy modes
nc     = size(xY.xf{1},2);       % Nr channels
ns     = size(xY.xf{1},1);       % Nr channels
nu     = size(DCM.B,2);          % Nr inputs
nm     = size(DCM.Hc,2);         % Nr time-frequency modes
nr     = size(DCM.Hc{1},2);      % Nr of sources
pst    = xY.pst;                 % peri-stmulus time
Hz     = xY.Hz;                  % frequencies


% switch
%--------------------------------------------------------------------------
switch(lower(Action))
    
case{lower('Frequency modes')}
    
    % spm_dcm_ind_results(DCM,'Frequency modes')
    %----------------------------------------------------------------------
    plot(DCM.xY.Hz,DCM.xY.U)
    xlabel('Frequnecy (Hz)')
    xlabel('modes')
    title('Frequency modes modelled at each source')
    axis square
    grid on
    
    
case{lower('Time-modes')}
    
    % spm_dcm_ind_results(DCM,'Time-modes');
    %----------------------------------------------------------------------  
    for i = 1:nm
        subplot(ceil(nm/2),2,i), hold on
        str   = {};
        for j = 1:nt
            plot(pst,DCM.Hc{j,i},'LineWidth',2);
            plot(pst,DCM.Hc{j,i} + DCM.Rc{j,i},'-.');
            set(gca, 'XLim', [pst(1) pst(end)]);
        end
        hold off
        title({sprintf('mode %i (all regions)',i),'- predicted; -- observed'})
        grid on
        axis square
        xlabel('time (ms)')
        try, axis(A), catch A = axis; end
    end
   

    
case{lower('Time-frequency')}
    
    % reconstitute time-frequency and get principle model over channels
    %----------------------------------------------------------------------
    nk    = length(Hz);
    for i = 1:nt
        for j = 1:nr
            TF{i,j} = sparse(ns,nk);
            RF{i,j} = sparse(ns,nk);
        end
    end
    for i = 1:nt
        for j = 1:nr
            for k = 1:nf
                TF{i,j} = TF{i,j} + DCM.Hc{i,k}(:,j)*xY.U(:,k)';
                RF{i,j} = RF{i,j} + DCM.Rc{i,k}(:,j)*xY.U(:,k)';
            end
        end
    end

      
    % loop over trials, sources (predicted and observed)
    %----------------------------------------------------------------------
    for i = 1:nt
        for j = 1:nr
            subplot(nt*2,nr,(i - 1)*nr + j)
            imagesc(Hz,pst,TF{i,j} + RF{i,j})
            xlabel('frequency')
            ylabel('pst (ms)')
            title({sprintf('trial %i: source %i ',i,j);
                  'observed'})

            subplot(nt*2,nr,(i - 1)*nr + nr + j)
            imagesc(Hz,pst,TF{i,j})
            xlabel('channel')
            ylabel('pst (ms)')
            title({sprintf('trial %i: source %i ',i,j);
                  'predicted'})
        end
    end

    
case{lower('Coupling (A)')}
    
        
    % images
    %----------------------------------------------------------------------
    subplot(3,2,1)
    imagesc(DCM.Ep.A)
    title('Coupling','FontSize',10)
    set(gca,'YTick',[1:nr],'YTickLabel',DCM.Sname,'FontSize',8)
    set(gca,'XTick',[])
    xlabel('from','FontSize',10)
    ylabel('to','FontSize',10)
    axis square

    % table
    %----------------------------------------------------------------------
    subplot(3,2,2)
    text(-1/8,1/2,num2str(DCM.Ep.A,' %-8.2f'),'FontSize',8)
    axis off,axis square


    % PPM
    %----------------------------------------------------------------------
    subplot(3,2,3)
    image(64*DCM.Pp.A)
    set(gca,'YTick',[1:nr],'YTickLabel',DCM.Sname,'FontSize',8)
    set(gca,'XTick',[])
    title('Conditional probabilities')
    axis square

    % table
    %----------------------------------------------------------------------
    subplot(3,2,4)
    text(-1/8,1/2,num2str(DCM.Pp.A,' %-8.2f'),'FontSize',8)
    axis off, axis square
    
    
    % Guide
    %----------------------------------------------------------------------
    subplot(3,2,5)
    image(48*(kron(eye(nf,nf),ones(nr,nr)) - speye(nr*nf,nr*nf)))
    title('Within frequency (linear)')
    axis square
    
    subplot(3,2,6)
    image(48*(kron(1 - eye(nf,nf),ones(nr,nr))))
    title('Between frequency (non-linear)')
    axis square


case{lower('Coupling (B)')}
    
    % spm_dcm_erp_results(DCM,'coupling (B)');
    %--------------------------------------------------------------------
    for i = 1:nu
        
        % images
        %-----------------------------------------------------------
        subplot(4,nu,i)
        imagesc(DCM.Ep.B{i})
        title(DCM.xU.name{i},'FontSize',10)
        set(gca,'YTick',[1:ns],'YTickLabel',DCM.Sname,'FontSize',8)
        set(gca,'XTick',[])
        xlabel('from','FontSize',8)
        ylabel('to','FontSize',8)
        axis square

        % tables
        %--------------------------------------------------------------------
        subplot(4,nu,i + nu)
        text(-1/8,1/2,num2str(full(DCM.Ep.B{i}),' %-8.2f'),'FontSize',8)
        axis off
        axis square
        
        % PPM
        %-----------------------------------------------------------
        subplot(4,nu,i + 2*nu)
        image(64*DCM.Pp.B{i})
        set(gca,'YTick',[1:ns],'YTickLabel',DCM.Sname,'FontSize',8)
        set(gca,'XTick',[])
        title('PPM')
        axis square

        % tables
        %--------------------------------------------------------------------
        subplot(4,nu,i + 3*nu)
        text(-1/8,1/2,num2str(DCM.Pp.B{i},' %-8.2f'),'FontSize',8)
        axis off
        axis square
        
    end
    

case{lower('Input (C)')}
   
    
    % reconstitute time-frequency and get principal mode over channels
    %----------------------------------------------------------------------
    Nu    = size(DCM.Ep.C,2);
    for k = 1:Nu
        subplot(Nu,1,k)
        for i = 1:nr
            j = [1:nf]*nr - nr + i;
            UF(:,i) = DCM.Eg.L(i)*xY.U*DCM.Ep.C(j,k);
        end
        plot(Hz,UF)
        xlabel('Frequency (Hz)')
        title(sprintf('frequency response to input %i',k))
        axis square, grid on
        legend(DCM.Sname)
    end
    
    
case{lower('Input')}
    
    % get input
    % --------------------------------------------------------------------
    U = spm_ind_u((pst - pst(1))/1000,DCM.Ep,DCM.M);
    
    subplot(2,1,1)
    plot(pst,U)
    xlabel('time (ms)')
    title('input')
    axis square tight, grid on
    
    
case{lower('Dipoles')}
    
        sdip.n_seeds = 1;
        sdip.n_dip  = nr;
        sdip.Mtb    = 1;
        sdip.j{1}   = zeros(3*nr, 1);
        sdip.loc{1} = full(DCM.M.dipfit.L.pos);
        spm_eeg_inv_ecd_DrawDip('Init', sdip)

end
