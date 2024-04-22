close all;
clear all;
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARTIE 2 : Implantation de la chaine de transmission OFDM sans canal %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 2.1) Emission

 %Déclaration des constantes
N = 16;      % Nombre de porteuses
n = 16000;    % Nombre de bits à transmettre
Fe = N;  % Fréquence d'echantillonnage
Rb = 3000;   % Débit binaire

 % Génération de bits
 bits = randi([0,1],1,n);

 % Mapping BPSK
 Symboles = 2*bits-1;

 % Génération du signal OFDM sans canal
Symboles_reshape = reshape(Symboles , N, n/N);

% Génération du signal OFDM lorsque une seul porteuse est utilisée
Porteuse_1 =[zeros(3,n/N); Symboles_reshape(4,:); zeros(N-4,n/N)];
IFFT1=ifft(Porteuse_1);
P1 = reshape(IFFT1, 1, []);

% Génération du signal OFDM lorsque  deux porteuses sont utilisées
Porteuse_2 = [zeros(4,n/N);Symboles_reshape(5:6,:); zeros(N-6,n/N)];
IFFT2=ifft(Porteuse_2);
P2 = reshape(IFFT2, 1, []);

% Génération du signal OFDM lorsque les 8 porteuses centrales sont utilisées
Porteuse_8 = [zeros(4,n/N);Symboles_reshape(5:12,:); zeros(4,n/N)];
IFFT3=ifft(Porteuse_8);
P3 = reshape(IFFT3,1,[]);

% Caclcul des densites spectrales
[DSP_P1, f1] = pwelch(P1,[],[],[],Fe,"twosided");
figure(1)
plot(f1, 10*log10(DSP_P1));
title("DSP de la quatrième porteuse ")
xlabel('Fréquence(Hz)')
ylabel("DSP(dB)")

[DSP_P2, f2] = pwelch(P2,[],[],[],Fe,"twosided");
figure(2)
plot(f2,10*log10(DSP_P2));
title("DSP de la cinquième et sixième porteuses ")
xlabel('Fréquence(Hz)')
ylabel("DSP(dB)")

[DSP_P3, f3] = pwelch(P3,[],[],[],Fe,"twosided");
figure(3)
plot(f3,10*log10(DSP_P3));
title("DSP des 8 porteuses centrales")
xlabel('Fréquence(Hz)')
ylabel("DSP(dB)")


%% 2.1) Récéption sans canal
% Symboles reçus: N=16 porteuses
Matrice_OFDM= ifft(Symboles_reshape);
Signal_OFDM = reshape(Matrice_OFDM,1,n);
FFT_Matrice_SignalOFDM = fft(Matrice_OFDM);
FFT_SignalOFDM = reshape(FFT_Matrice_SignalOFDM, 1, n);
Symboles_recus = sign(FFT_SignalOFDM);

% Demapping
bits_recus = (Symboles_recus + 1)/2;

% Calcul du TEB
ecart_ss_canal = abs(bits - bits_recus);
TEB_ss_canal = mean(ecart_ss_canal);

%% PARTIE 3 : Implantation de la chaine de transmission OFDM avec canal multi-trajets, sans bruit 

N_calcule = 16; % Nombres de porteuses calculées


 %%Récéption avec canal
% Symboles reçus: N_calcule = 16 porteuses
Symboles_reshape16 = reshape(Symboles , N_calcule, n/N_calcule);
Matrice_OFDM16= ifft(Symboles_reshape16);
Signal_OFDM16 = reshape(Matrice_OFDM16,1,n);
FFT_Matrice_SignalOFDM16 = fft(Matrice_OFDM16);
FFT_SignalOFDM16 = reshape(FFT_Matrice_SignalOFDM16, 1, n);
Symboles_recus16 = sign(FFT_SignalOFDM16);

% Demapping
bits_recus16 = (Symboles_recus16 + 1)/2;

% Canal de propagation
alpha0 = 0.227; 
alpha1 = 0.46;
alpha2 = 0.688;
alpha3 = 0.46;
alpha4 = 0.227;

h = [alpha0 alpha1  alpha2 alpha3 alpha4];


figure(5)
subplot(2,1,1)
plot(abs(fft(h,4096)));
title("Module de la réponse fréquentielle")
subplot(2,1,2)
plot(angle(fft(h,4096)));
title("Phase de la réponse fréquentielle")



%% 3.1) Implantation sans intervalle de garde
% Filtrage du signal OFDM
Signal_Recu = filter(h, 1, Signal_OFDM);
Matrice_Signal_Recu = reshape(Signal_Recu, N_calcule, n/N_calcule);

figure(6)
plot(real(Signal_Recu));
title("le passage du signal OFDM dans le canal de propagation");
xlabel("fréquences normalisés");
ylabel("l'amplitude");


% Comparaison des DSPs avant et après le canal
[DSP_Signal_Recu, f_signal_recu] = pwelch(Signal_Recu,[],[],[],Fe,"twosided");
[DSP_Signal_OFDM, f_signal_ofdm] = pwelch(Signal_OFDM,[],[],[],Fe,"twosided");
figure(7)
xlim([0 1]);
plot(f_signal_recu, log10(DSP_Signal_Recu),'r');
hold on
plot(f_signal_ofdm, log10(DSP_Signal_OFDM),'b');
title("Les DSPs avant et après le canal")
xlabel('Fréquence(Hz)')
ylabel("DSP(dB)")
legend('après le canal','avant le canal')

% Réception
FFT_Signal_Recu_Matrice = fft(Matrice_Signal_Recu);
FFT_Signal_Recu = reshape(FFT_Signal_Recu_Matrice, 1, n);

% Constellations
scatterplot(FFT_Signal_Recu_Matrice(3,:));
title("Constellations de la troisième porteuse sans canal")
scatterplot(FFT_Signal_Recu_Matrice(15,:));
title("Constellations de la quinzième porteuse sans canal")

% Calcul du TEB
symboles_recu_canal = sign(real(FFT_Signal_Recu));
bits_recus_canal = (symboles_recu_canal + 1)/2;
ecart_canal = abs(bits_recus_canal - bits);
TEB_canal = mean(ecart_canal);



%% 3.2) Implantation avec intervalle de garde composé de zéros
% Emission
Matrice_Signal_OFDM_IG = [zeros(10,n/N_calcule); Matrice_OFDM16];
Signal_OFDM_IG = reshape(Matrice_Signal_OFDM_IG, 1, n+10*n/N_calcule);
Signal_Recu_IG = filter(h, 1, Signal_OFDM_IG);
Signal_Recu_IG_Matrice = reshape(Signal_Recu_IG, N_calcule+10, n/N_calcule);

% Réception
Signal_Recu_IG_Matrice = Signal_Recu_IG_Matrice(11:N_calcule+10,:);
TF_Signal_Recu_IG_Matrice = fft(Signal_Recu_IG_Matrice);

% Constellations
scatterplot(TF_Signal_Recu_IG_Matrice(3,:));
title("Constellations de la troisième porteuse avec IG")
scatterplot(TF_Signal_Recu_IG_Matrice(15,:));
title("Constellations de la quinzième porteuse avec IG")

% Calcul du TEB
TF_Signal_Recu_IG = reshape(TF_Signal_Recu_IG_Matrice, 1, n);
symboles_recu_IG = sign(real(TF_Signal_Recu_IG));
bits_recus_IG = (symboles_recu_IG + 1)/2;
ecart_IG = abs(bits_recus_IG - bits);
TEB_IG = mean(ecart_IG);



%% 3.3) Implantation avec préfixe cyclique
Matrice_Signal_OFDM_PC = [Matrice_OFDM16(N_calcule-9:N_calcule,:); Matrice_OFDM16];
Signal_OFDM_PC = reshape(Matrice_Signal_OFDM_PC, 1, (N_calcule+10)*(n/N_calcule));
Signal_Recu_PC = filter(h, 1, Matrice_Signal_OFDM_PC);
Matrice_Signal_Recu_PC = reshape(Signal_Recu_PC, N_calcule+10, n/N_calcule);

% Réception
Matrice_Signal_Recu_PC = Matrice_Signal_Recu_PC(11:N_calcule+10,:);
Matrice_FFT_Signal_Recu_PC = fft(Matrice_Signal_Recu_PC);
FFT_Signal_Recu_PC = reshape(Matrice_FFT_Signal_Recu_PC, 1, n);

% Constellations
scatterplot(Matrice_FFT_Signal_Recu_PC(3,:));
title("Constellations de la troisième porteuse avec PC")
scatterplot(Matrice_FFT_Signal_Recu_PC(15,:));
title("Constellations de la quinzième porteuse avec PC")

% Calcul du TEB
symboles_recu_PC = sign(real(FFT_Signal_Recu_PC));
bits_recus_PC = (symboles_recu_PC + 1)/2;
ecart_PC = abs(bits_recus_PC - bits);
TEB_PC = mean(ecart_PC);


%% 3.4) Implantation avec préfixe cyclique et égalisation

h = [h zeros(1,N_calcule-length(h))];
H = fft(h);

% Egalisation ZFE
Matrice_symboles_recu_ZFE = Matrice_FFT_Signal_Recu_PC./H.';

%Constellations
scatterplot(Matrice_symboles_recu_ZFE(3,:));
title("Constellations de la troisième porteuse avec egalisation ZFE ")
scatterplot(Matrice_symboles_recu_ZFE(15,:));
title("Constellations de la quinzième porteuse avec egalisation ZFE ")

% Calcul du TEB
symboles_recu_ZFE = reshape(Matrice_symboles_recu_ZFE, 1, n);
symboles_recu_ZFE = sign(real(symboles_recu_ZFE));
bits_recus_ZFE = (symboles_recu_ZFE + 1)/2;
ecart_ZFE = abs(bits_recus_ZFE - bits);
TEB_ZFE = mean(ecart_ZFE);

% Egalisation ML
Matrice_symboles_recu_ML = Matrice_FFT_Signal_Recu_PC.*H';

%Constellations
scatterplot(Matrice_symboles_recu_ML(3,:));
title("Constellations de la troisième porteuse avec Egalisation ML ")
scatterplot(Matrice_symboles_recu_ML(15,:));
title("Constellations de la quinzième porteuse Egalisation ML ")

%Calcul du TEB
symboles_recu_ML = reshape(Matrice_symboles_recu_ML, 1, n);
symboles_recu_ML = sign(real(symboles_recu_ML));
bits_recus_ML = (symboles_recu_ML + 1)/2;
ecart_ML = abs(bits_recus_ML - bits);
TEB_ML = mean(ecart_ML);






%% PARTIE 4 : Impact d'une erreur de synchronisation horloge 

% Surdimensionnement du préfixe cyclique
Matrice_Signal_OFDM_PC = [Matrice_OFDM(9:16,:); Matrice_OFDM];

% Cas 1
Signal_OFDM_PC_cas = reshape(Matrice_Signal_OFDM_PC, 1, (N+8)*(n/N));

Signal_Recu = filter(h, 1, Signal_OFDM_PC_cas);

Mat_Recu=Signal_Recu;
Mat_Entre=reshape(Mat_Recu,N+8,n/N);
Mat_Entre1=Mat_Entre(1:N+1,:);
M_Recu1=fft(Mat_Entre1);


% % Calcul du TEB cas 1
% sig_recu1 = reshape(M_Recu1, 1, n);
% symboles_recu1 = sign(real(sig_recu1));
% bits_recu1 = (symboles_recu1 + 1)/2;
% ecart1 = abs(bits_recu1 - bits);
% TEB_cas1 = mean(ecart1);

% Constellations
scatterplot(M_Recu1(3,:))
title("troisième porteuse dans le premier cas")
scatterplot(M_Recu1(15,:))
title("quinzième porteuse dans le premier cas")


% Cas 2
Signal_OFDM_PC_cas = reshape(Matrice_Signal_OFDM_PC, 1, (N+8)*(n/N));
Signal_Recu = filter(h, 1, Signal_OFDM_PC_cas);
Mat_Recu=Signal_Recu;
Mat_Entre=reshape(Mat_Recu,N+8,n/N);
Mat_Entre2=Mat_Entre(6:N+5,:);
M_Recu2=fft(Mat_Entre2);


% % Calcul du TEB cas 2
% Sig_recu2 = reshape(M_Recu2, 1, n);
% symboles_recu2 = sign(real(Sig_recu2));
% bits_recu2 = (symboles_recu2 + 1)/2;
% ecart2 = abs(bits_recu2 - bits);
% TEB_cas2 = mean(ecart2);

% Constellations
scatterplot(M_Recu2(3,:))
title("troisième porteuse dans le deuxième cas ")
scatterplot(M_Recu2(15,:))
title("quinzième porteuse dans le deuxième cas")

% Cas 3
Signal_OFDM_PC_cas = reshape(Matrice_Signal_OFDM_PC, 1, (N+8)*(n/N));

Signal_Recu = filter(h, 1, Signal_OFDM_PC_cas);

Mat_Recu=Signal_Recu;
Signal_Recu=[Signal_Recu(3:end) Signal_Recu(1) Signal_Recu(2)];
Mat_Entre=reshape(Signal_Recu,N+8,n/N);
Mat_Entre3=Mat_Entre(9:N+8,:);
M_Recu3=fft(Mat_Entre3);

% % Calcul du TEB cas 3
% Sig_recu3 = reshape(M_Recu3, 1, n);
% symboles_recu3 = sign(real(Sig_recu3));
% bits_recu3 = (symboles_recu3 + 1)/2;
% ecart3 = abs(bits_recu3 - bits);
% TEB_cas3 = mean(ecart3);

% Constellations
scatterplot(M_Recu3(3,:))
title("troisième porteuse dans le troisième cas")
scatterplot(M_Recu3(15,:))
title("quinzième porteuse dans le troisième cas")


