close all;
clear all;

BlT = 10.^[-3:0.01:3];
EbNodB = input('Eb/No in dB =? '); %  10 dB
EbNo = 10^(EbNodB/10);

N_symb=1000;
M=4;   %QPSK
NCO_mem=0;      % initialisation du retard de la mise a jour
filtre_mem=0;   % initialisation de la memoire du filtre
phi_est(1)=0;  %  valeur initiale de la phase estimee

phi_est = zeros(1, N_symb+1); % estimated phase vector, initialized to zero


symb_emis = (2*randi([0, 1], 1, N_symb)-1) + 1j*(2*randi([0, 1], 1, N_symb)-1);


sigma = sqrt(1/(2*EbNo)); % sigma du bruit thermique
bruit = sigma*randn(1, N_symb) + j*sigma*randn(1, N_symb);  % vecteur de bruit
dephasage = 0 * pi/180; % phase shift, initialized to zero (dephasage signal recu)
recu = symb_emis .* exp(j*dephasage) + bruit; % echantillons en entree DPLL

% Simulation over different values of BlT
Phase_Jitter = zeros(length(BlT), 1); % Initialize Phase_Jitter vector

for jj = 1:length(BlT)
    %ordre 2
    zeta=sqrt(2)/2;
    wnT=2*BlT(jj)./(zeta+1/(4*zeta));
    A=wnT.*(2+wnT)./(1+3*wnT+wnT.^2);
    B=wnT.^2./(1+3*wnT+wnT.^2);


    % DPLL processing
    for ii = 1:N_symb

             % affichage de ii par multiples de 1000
            if mod(ii,1000)==0
                ii
            end

        out_det = -imag((recu(ii) .* exp(-j*phi_est(ii))).^4); % Detector equation

    % filtre de boucle
        w = filtre_mem + out_det; % % memoire filtre + sortie detecte
        filtre_mem = w;
        out_filtre = A*out_det + B*w; % sortie du filtre a l'instant ii :  F(z)=A+B/(1-z^-1)
    

         % integrateur + retard 
    
    phi_est(ii+1) = out_filtre + NCO_mem; % N(z)=1/(z-1) 
    NCO_mem=phi_est(ii+1);
    end

    % Phase Jitter calculation
    Phase_Jitter(jj) = mean(abs(phi_est - phi_est(1)).^2);
end

% Plot Phase Jitter vs BlT
figure(1);
loglog(BlT, Phase_Jitter);
grid on;
xlabel('BlT');
ylabel('Phase Jitter');
title('JITTER BlT');