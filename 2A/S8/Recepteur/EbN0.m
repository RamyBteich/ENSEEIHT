close all
clear

% il faut avoir au prealable calculer la pente du detecteur en boucle
% ouverte



BlT= 10^-(2.5);  % ex: 0.01
EbNodB= 0:5:50;
EbNo=10.^(EbNodB/10);
N_symb=10000;



%
% calcul des parametres de la boucle
%

symb_emis=(2*randi([0 1],1,N_symb)-1)+j*(2*randi([0 1],1,N_symb)-1); % symboles QPSK
phi =  zeros(1, N_symb+1);

%ordre2
zeta=sqrt(2)/2;
wnT=2*BlT./(zeta+1/(4*zeta));
A=wnT.*(2+wnT)./(1+3*wnT+wnT.^2);
B=wnT.^2./(1+3*wnT+wnT.^2);


for jj=1:length(EbNo)

    NCO_mem=0;      % initialisation du retard de la mise a jour
    filtre_mem=0;   % initialisation de la memoire du filtre
    phi_est(1)=0;  %  valeur initiale de la phase estimee
  
    
    sigma = sqrt(1/(2*EbNo(jj)));   % sigma du bruit thermique
    bruit=sigma*randn(1,N_symb)+j*sigma*randn(1,N_symb) ; % vecteur de bruit
    dephasage = 0 *pi/180;% dephasage signal recu

    %  DPLL
 
    for ii=1:N_symb

             % affichage de ii par multiples de 1000
            if mod(ii,1000)==0
                ii
            end
    
        recu=symb_emis.*exp(j*dephasage)+bruit;
        out_det(ii)= -imag((recu(ii).*exp(-j*phi_est(ii)*(pi/180))).^4); % a completer ! %
    
        % filtre de boucle
    
        w(ii)=filtre_mem+out_det(ii); % memoire filtre + sortie detecteur 
        filtre_mem=w(ii);            
        out_filtre=A*out_det(ii)+B*w(ii);   % sortie du filtre a l'instant ii :  F(z)=A+B/(1-z^-1)
    
         % integrateur + retard 
    
        phi_est(ii+1)=(out_filtre+NCO_mem); % N(z)=1/(z-1) 
        NCO_mem=phi_est(ii+1);
    end
    jitter(jj) = mean((phi - phi_est).^2);
end


% Plot Jitter vs. Eb/No on a log-log scale
figure
loglog(EbNo, jitter, 'b');
grid on
xlabel('Eb/No (dB)');
ylabel('Phase Jitter (radians)');
title('Eb/No');