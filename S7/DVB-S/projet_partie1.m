clear
close all

% Paramètres de l'étude
Rb = 3000;        % Débit binaire
n_bits=20000;     % nombre de bits a transemettre
Fe = 24000; % Fréquence d'échantillonnage
M = 4;         % Ordre de modulation
Rs = Rb / log2(M); % Débit symbole
Ns = sqrt(Fe / Rs); %taux d'echantillonnage
beta = 0.35; % Facteur de roll-off




% Transmission au format DVB-S avec mapping 8-PSK

% Génération du message binaire aléatoire
sym = randi([0, 1], 1, n_bits);

% Mapping (Modulation 8-PSK)
symboles = qammod(sym.', M, 'InputType', 'bit').';

% Suréchantillonnage (on ajoute des échantillons supplémentaires entre les échantillons d'origine.)
symboles_surechan = kron(symboles, [1 zeros(1, Ns-1)]);
h = rcosdesign(beta,8,Ns);  %filtre en racine de cosinus sureleve
I= filter(h, 1, [symboles_surechan zeros(1, length(h)-1)]);

% Canal AWGN passe-bas équivalent
Eb_N0_dB = 0:4;       % Valeurs pour le rapport signal sur bruit (Eb/No) en (dB) allant de 0 à 8 dB.
Eb_N0 = 10.^(Eb_N0_dB/10);     % Convertit les valeurs de Eb/No de dB en puissance réelle

puissance_signal = mean(abs(I).^2); %puissande du signal emis
Dev = sqrt((puissance_signal * Ns) ./ (2 * log2(M) * Eb_N0)); %deviation stantard pour les valeur du signal emis

% Les dimensions pour les matrices de bruit.
dim_Eb_N0 = length(Eb_N0);
dim_I = length(I);

bruit_1 = Dev' * randn(1, dim_I); % vecteur de bruit gaussien
bruit_2 = Dev' * randn(1, dim_I); % vecteur de bruit gaussien
bruit_m = bruit_1 + 1i * bruit_2; %combinaison des reel et imaginaire

signal_recu = repmat(I, dim_Eb_N0, 1) + bruit_m; %ajout de bruit au signal transmis


% Réception du signal avec le bruit
%filtre en cosinus surelvee : reduction de l'interferance intersymboles, et la compatibilite avec 8-PSK)
hr = h; %filtre en racine de cosinus surelvee 
received_sig = filter(hr, 1, signal_recu, [], 2); %signal recu apres le filtrage du signal avec briut

% Réception sans bruit
received_sig_without_noise = filter(h, 1, I); % signal recu sans bruit, et filtre en racine de cosinus

% Le diagramme de l oeil en sortie du filtre de réception sans bruit
eyediagram = reshape(I, Ns, length(I) / Ns);
figure;
plot(eyediagram);
title("Diagramme de l'oeil sans bruit");

% Le diagramme de l oeil en sortie du filtre de réception avec bruit
eyediagram = reshape(received_sig, 2 * Ns, []);
figure;
plot(eyediagram);
title("Diagramme de l'oeil du signal reçu avec bruit");

% Echantillonnage
n0 = length(h); % longeuer du filtre en racine de cosinus
received_sampled_sig = received_sig(:, n0: Ns :end); %signal recu apres echantillonnage
reveived_sampled_sig_without_noise = received_sig_without_noise(n0: Ns :end);

%estimation des symboles basee sur le sign relle et imaginaire
estimated_sym = sign(real(received_sampled_sig)) + 1i * sign(imag(received_sampled_sig));
estimated_sym_witout_noise = sign(real(reveived_sampled_sig_without_noise)) + 1i * sign(imag(reveived_sampled_sig_without_noise));

bits_sans_bruit = qamdemod(estimated_sym_witout_noise.', M, 'OutputType', 'bit');
bits_sans_bruit = bits_sans_bruit';
bits = zeros(dim_Eb_N0, length(sym));

for i = 1:dim_Eb_N0
    ligne_i = qamdemod(estimated_sym(i,:).', M, 'OutputType', 'bit');
    bits(i,:) = ligne_i';
end

% Calcul du taux d'erreur binaire
TEB = mean(abs(sym - bits), 2).';
TEB_theorique = qfunc(sqrt(2*Eb_N0)); %distance minimale entre les points dans le plan complexe est sqrt(2).

% TES sans bruit en comparant les symboles estimés avec les symboles d'origine
TES_sans_bruit = mean(abs(symboles - estimated_sym_witout_noise));

% TES avec bruit
TES = mean(abs(symboles - estimated_sym), 2).';
TES_theorique = TEB_theorique*log2(M); %log2(M) est le nombre moyen de bits par symbole

figure;
semilogy(Eb_N0_dB, TEB);
grid on;
hold on
semilogy(Eb_N0_dB, TEB_theorique);
grid on;
legend("TEB estimé",'TEB théorique')
xlabel('E_b/N_0 (dB)')
ylabel('TEB')
title('fig 1:Comparaison entre TEB théorique et TEB simulé')

% figure;
% semilogy(Eb_N0_dB, TES);
% grid on;
% hold on
% semilogy(Eb_N0_dB, TES_theorique);
% grid on;
% legend(" TES simulé",'TES théorique')
% xlabel('E_b/N_0 (dB)')
% ylabel('TES')
% title('fig 2:Comparaison entre TES théorique et TES simulé')

%% Codage canal

% Introduction du code convolutif 
trellis = poly2trellis(7,[171 133]);  % Initialisation de la structure de code
encoded_bits = convenc(sym, trellis);  % Codage des message_binaire en utilisant la fonction "convenc"
 coded_bits_num = length(encoded_bits);    % Nombre de message_binaire codés



%% Sans poinçonnage
rendement = 0.5;          % Rendement du code sans poinçonnage 

% Mapping
symboles_codes = qammod(encoded_bits.',M,'InputType','bit').';

% Suréchantillonnage
s_codes = kron(symboles_codes, [1 zeros(1, Ns-1)]);
signal_e_codes = filter(h, 1, [s_codes zeros(1, length(h)-1)]);


% Canal AWGN passe-bas sans poinçonnage
Eb_N0_dB = -7:7;
Eb_N0 = 10.^(Eb_N0_dB/10);

P_signal_e_codes = mean(abs(signal_e_codes).^2); % Puissance du signal émis
sigma_ne_codes = sqrt((rendement*P_signal_e_codes * Ns)./(2*log2(M)*Eb_N0)); %l'écart type du bruit en fonction du rapport Eb/N0

dim1 = length(Eb_N0);   %generation du bruit complex dimession de la matrices
dim2 = length(signal_e_codes);
n_I_codes = randn(dim1, dim2) .* sigma_ne_codes.'; %partie reelle
n_Q_codes = randn(dim1, dim2) .* sigma_ne_codes.';%partie imaginaire
n_e_codes = n_I_codes + 1i * n_Q_codes; %addition des parties reel et imaginaire

r_codes = repmat(signal_e_codes, dim1, 1) + n_e_codes; %combinaison du signal avec le bruit


% Réception du signal 
h_reception = h;
z_codes = filter(h_reception,1, r_codes,[],2); %modéliser la réponse du canal

% Echantillonnage
n0 = length(h);   %la longueur de la réponse impulsionnelle 
z_codes = z_codes(:, n0: Ns :end);


%% soft

% Décision
d_codes = sign(real(z_codes)) + 1i * sign(imag(z_codes));%decision sur les symboles(assigne +1;-1 en fonction du signe dela partie reelle et ima)

bits_recus_soft = zeros(dim1, coded_bits_num);% décodage soft des symboles reçus (z_codes) en utilisant l'option de sortie en LLR (Log-Likelihood Ratio).
for i = 1:dim1
    bits_recus_soft(i, :) = (qamdemod(z_codes(i,:).', M, 'OutputType', 'llr')).';
end
clear i;

%decodage canal avec vitebri
tblen = 5*6; % longueur du registre de mémoire utilisé dans l'algorithme de décodage de Viterb(memoire de longeur 5 et 6 registres)
bits_decodes_soft = zeros(dim1, n_bits);
for i=1:dim1
    bits_decodes_soft(i,:) = vitdec(bits_recus_soft(i,:),trellis,tblen,'trunc','unquant');
end

% calcule du TEB
TEB_soft = mean(abs(sym-bits_decodes_soft),2).';

figure
semilogy(Eb_N0_dB, TEB_soft);
grid on;
hold on
semilogy(Eb_N0_dB, qfunc(sqrt(2*Eb_N0)));
legend("soft ", 'Théorique')
xlabel('E_b/N_0 (dB)')
ylabel('TEB')
title('fig 3:Comparaison des TEBs avec codage canal')

%%
%% hard

% Décision
d_codes = sign(real(z_codes)) + 1i * sign(imag(z_codes));

bits_recus_codes = zeros(dim1, coded_bits_num);
for i = 1:dim1
    bits_recus_codes(i,:) = (qamdemod(d_codes(i,:).', M, 'OutputType', 'bit')).';
end
clear i;

% decodage canal avec vitebri
tblen = 5*6; % longueur du registre de mémoire utilisé dans l'algorithme de décodage de Viterb(memoire de longeur 5 et 6 registres)
bits_decodes_hard = zeros(dim1, n_bits);
for i=1:dim1
    bits_decodes_hard(i,:) = vitdec(bits_recus_codes(i,:),trellis,tblen,'trunc','hard');
end

% calcule du TEB
TEB_hard = mean(abs(sym-bits_decodes_hard),2).';


figure
semilogy(Eb_N0_dB, TEB_hard);
grid on;
hold on
semilogy(Eb_N0_dB, qfunc(sqrt(2*Eb_N0)));
legend("Hard ", 'Théorique')
xlabel('E_b/N_0 (dB)')
ylabel('TEB')
title('fig 4:Comparaison des TEBs avec codage canal')


%% Avec poinçonnage

% Poinçonnage
Rendement_poiconne = 2/3;       % Rendement du code avec poinçonnage
poinc_matrix = [1 1 0 1];          % Matrice de poinçonnage
poinc_bits = convenc(sym, trellis, poinc_matrix); %application du popinconnage au code convolue
N_poinconnes = length(poinc_bits); %longeur du signal poiconne


% Mapping  
symboles_poinconne = qammod(poinc_bits.',M,'InputType','bit').';

% Suréchantillonnage
s_ap = kron(symboles_poinconne, [1 zeros(1, Ns-1)]);%répéter chaque symbole avec des zéros intercalés afin d'augmenter le taux d'échantillonnage
signal_e_poinconne = filter(h, 1, [s_ap zeros(1, length(h)-1)]); %filtrage du signal surechan...

% Canal AWGN passe-bas équivalent pour le cas avec poinçonnage

P_signal_e_poinconne = mean(abs(signal_e_poinconne).^2); % Puissance du signal émis
sigma_ne_poinconne = sqrt((Rendement_poiconne*P_signal_e_poinconne * Ns)./(2*log2(M)*Eb_N0));
dim1 = length(Eb_N0);           %Ajout de bruit AWGN
dim2 = length(signal_e_poinconne);
n_I_poinconne = randn(dim1, dim2) .* sigma_ne_poinconne.';
n_Q_poinconne = randn(dim1, dim2) .* sigma_ne_poinconne.';
n_e_poinconne = n_I_poinconne + 1i * n_Q_poinconne;

r_poinconne = repmat(signal_e_poinconne, dim1, 1) + n_e_poinconne;

% Réception du signal poinconne
z_poinconne = filter(h_reception,1, r_poinconne,[],2);

% Echantillonnage
z_poinconne = z_poinconne(:, n0: Ns :end);

% Démodulation (en attribuant la valeur +1 ou -1 en fonction du signe de la partie réelle et imaginaire.)
d_poinconne = sign(real(z_poinconne)) + 1i * sign(imag(z_poinconne));

% Décision des bits recu
bits_recus_poinconne = zeros(dim1, N_poinconnes);
for i = 1:dim1
    bits_recus_poinconne(i,:) = (qamdemod(d_poinconne(i,:).', M, 'OutputType', 'bit')).';
end
clear i;

% Décodage canal avec poinconnage
tblen = 5*6; % longueur du registre de mémoire utilisé dans l'algorithme de décodage de Viterb(memoire de longeur 5 et 7 registres)
bits_decoded_ap = zeros(dim1, n_bits);
for i=1:dim1
    bits_decoded_ap(i,:) = vitdec(bits_recus_poinconne(i,:),trellis,tblen,'trunc','hard', poinc_matrix);
end

% Calcul du taux d'erreur binaire
TEB_poinc = zeros(1,length(Eb_N0));
for i=1:length(Eb_N0)
    TEB_poinc(i) = mean(abs(sym-bits_decoded_ap(i,:)));
end
clear i;
 
% Comparaison entre TEB avec poinçonnage et TEB sans poinçonnage

figure()
semilogy(Eb_N0_dB, TEB_hard);
grid on;
hold on
semilogy(Eb_N0_dB, TEB_poinc);
grid on;
legend("sans poinçonnage","avec poinçonnage R=2/3")
xlabel('E_b/N_0 (dB)')
ylabel('TEB')
title('fig 4: Comparaison entre TEB avec poinçonnage et TEB sans poinçonnage')

%% Ajout de l'entrelaceur et du code de Reed Solomon
% Paramètres de l'entrelaceur
r = 204;         % La longueur totale des codes RS(R)
k = 188;         % La longueur des données originales avant codage RS(S)

% Génération de bits
bits_K = randi([0 1], 1, k*8*100);

% Entrelaceur et permutation aleatoire
rsencoder = comm.RSEncoder(r, k, 'BitInput', true); % encodeurr de la classe RSEncoder pour effectuer le codage RS(N,K)
redecoder = comm.RSDecoder(r, k, 'BitInput', true); % decodeur de la classe RSEncoder pour effectuer le decodage RS(N,K)
bitscoderRS = step(rsencoder, bits_K.');
vect_perm = randperm(length(bitscoderRS)); % vect_perm de permutations aléatoires de la longueur de bitscoderRS
intr = reshape(bitscoderRS(vect_perm), [], 1);

% Codage canal
bits_K_codes = convenc(bits_K, trellis, poinc_matrix); %codés par le code convolutif avec poinçonnage.
bits_K_codes_RS = convenc(intr.', trellis, poinc_matrix); %codés par le code convolutif avec poinçonnage.
N_K = length(bits_K_codes);
N_K_RS = length(bits_K_codes_RS);

% Modulation et filtrage de mise en forme
symboles_K_codes = (qammod(bits_K_codes.', M, 'InputType', 'bit')).';      %modulation en symboles QAM
symboles_K_codes_RS = (qammod(bits_K_codes_RS.', M, 'InputType', 'bit')).';%modulation en symboles QAM


s_K_codes = kron(symboles_K_codes, [1 zeros(1, Ns-1)]);       %le signal est suréchantillonné 
s_K_codes_RS = kron(symboles_K_codes_RS, [1 zeros(1, Ns-1)]); %le signal est suréchantillonné 

signal_e_K_codes = filter(h, 1, [s_K_codes zeros(1, length(h)-1)]);   % Signal émis sans codage RS
signal_e_K_codes_RS = filter(h, 1, [s_K_codes_RS zeros(1, length(h)-1)]); % Signal émis avec codage RS

% Canal AWGN passe-bas équivalent sans codage RS
R_K = 2/3; % Rendement du code 
P_signal_e_K_codes = mean(abs(signal_e_K_codes).^2); % Puissance du signal émis
sigma_ne_K_codes = sqrt((R_K*P_signal_e_poinconne * Ns)./(2*log2(M)*Eb_N0));%Écart-type du bruit AWGN en fonction du rapport signal sur bruit (Eb/N0) et de la puissance du signal émis.
dim1 = length(Eb_N0);%Dimensions des matrices utilisées.
dim2 = length(signal_e_K_codes);
n_I_K_codes = randn(dim1, dim2) .* sigma_ne_K_codes.';%partie reelle
n_Q_K_codes = randn(dim1, dim2) .* sigma_ne_K_codes.';%partie imaginaire
n_e_K_codes = n_I_K_codes + 1i* n_Q_K_codes; %Bruit AWGN complexe.

r_K_codes = repmat(signal_e_K_codes, dim1, 1) + n_e_K_codes;%Signal reçu après passage à travers le canal avec bruit AWGN


% Canal AWGN passe-bas équivalent avec codage RS
R_K_RS = 2/3; % Rendement du code
P_signal_e_K_codes_RS = mean(abs(signal_e_K_codes_RS).^2); % Puissance du signal émis
sigma_ne_K_codes_RS = sqrt((R_K_RS*P_signal_e_K_codes_RS * Ns)./(2*log2(M)*Eb_N0));
dim1 = length(Eb_N0);
dim2_RS = length(signal_e_K_codes_RS);
n_I_K_codes_RS = zeros(dim1, dim2_RS);
n_Q_K_codes_RS = zeros(dim1, dim2_RS);
n_e_K_codes_RS = zeros(dim1, dim2_RS);
for i=1:dim1
    n_I_K_codes_RS(i,:) = sigma_ne_K_codes_RS(i).*randn(1,dim2_RS);
    n_Q_K_codes_RS(i,:) = sigma_ne_K_codes_RS(i).*randn(1,dim2_RS);
    n_e_K_codes_RS(i,:) = n_I_K_codes_RS(i,:) + 1i* n_Q_K_codes_RS(i,:);
end

r_K_codes_RS = repmat(signal_e_K_codes_RS, dim1, 1) + n_e_K_codes_RS;

% Réception
z_K_codes = zeros(dim1, dim2); %signal apres passage a travers le canal
z_K_codes_RS = zeros(dim1, dim2_RS);%signal apres passage a travers le canal avec RS
for i=1:dim1
    z_K_codes(i,:) = filter(h_reception,1, r_K_codes(i,:)); %filtre de réception  sur le signal reçu.
    z_K_codes_RS(i,:) = filter(h_reception,1, r_K_codes_RS(i,:));  %filtre de réception  sur le signal reçu.
end
clear i;

% Echantillonnage
z_K_codes = z_K_codes(:, n0: Ns :end);
z_K_codes_RS = z_K_codes_RS(:, n0: Ns :end);

% Démodulation en en attribuant la valeur +1 ou -1 en fonction du signe de la partie réelle et imaginaire.
d_K_codes = sign(real(z_K_codes)) + 1i * sign(imag(z_K_codes));
d_K_codes_RS = sign(real(z_K_codes_RS)) + 1i * sign(imag(z_K_codes_RS));

% Décision
bits_recus_K_codes = zeros(dim1, N_K); %bits reçus après la démodulation
bits_recus_K_codes_RS = zeros(dim1, N_K_RS); %bits reçus après la démodulation
for i = 1:dim1
    bits_recus_K_codes(i,:) = (qamdemod(d_K_codes(i,:).', M, 'OutputType', 'bit')).'; %effectuer la décision des bits à partir des symboles démodulés.
    bits_recus_K_codes_RS(i,:) = (qamdemod(d_K_codes_RS(i,:).', M, 'OutputType', 'bit')).';
end
clear ligne_ii;

% Décodage
bits_K_decodes = zeros(1, length(bits_K)); %bits decode apres le le decodage des signaux
bits_K_decodes_RS = zeros(1, length(bits_K)); 
for i=1:dim1
    bits_K_decodes(i,:) = vitdec(bits_recus_K_codes(i,:),trellis,tblen,'trunc','hard', poinc_matrix); %decodage vitebri
    v = vitdec(bits_recus_K_codes_RS(i,:),trellis,tblen,'trunc','hard', poinc_matrix);
    v = deintrlv(v, vect_perm);%Les bits décodés sont désembrouillés (inverser la permutation) en utilisant la permutation inverse, Cela compense l'entrelacement appliqué précédemment.
    v = step(redecoder, v.');% Les bits désembrouillés sont ensuite décodés par le décodeur Reed-Solomon (redecoder), qui effectue la correction d'erreur.
    bits_K_decodes_RS(i,:) = v.'; 
end

% Calcul du taux d'erreur binaire
    % Sans entrelaceur
TEB_K = zeros(1,dim1);
for i=1:dim1
    TEB_K(i) = mean(abs(bits_K-bits_K_decodes(i,:)));
end
clear i;
    % Avec entrelaceur
TEB_K_RS = zeros(1,dim1);
for i=1:dim1
     TEB_K_RS(i) = mean(abs(bits_K-bits_K_decodes_RS(i,:)));
end
clear i;

%Ces boucles calculent le TEB en comparant les bits originaux (bits_K) 
% avec les bits décodés (bits_K_decodes et bits_K_decodes_RS).

% Comparaison entre TEB avec entrelaceur et TEB sans entrelaceur
figure()
semilogy(Eb_N0_dB, TEB_K);
hold on
grid on
semilogy(Eb_N0_dB, TEB_K_RS);
legend("Sans entrelaceur","Avec entrelaceur")
xlabel('E_b/N_0 (dB)')
ylabel('TEB')
title('Comparaison entre TEB avec entrelaceur et TEB sans entrelaceur ')
