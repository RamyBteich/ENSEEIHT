clear;
close all;
clc;



% Initialisation des paramètres
Fe = 12000;
Te = 1 / Fe;
beta = 0.35; %Facteur de roll-off
span = 8;
fp = 2000;
fc = 1500;
Rs = 3000;
n_bits = 200000; % nombre de bits a transemettre
Ns = 1; % facteur de surech
N = 50;
M=4;
Tc = 10 * Ns;
F = 1/(5*Tc);
k =5;
Eb_N0_dB=-16:0;


% Génération de l’information binaire
sym = randi([0, 1], 1, n_bits);

% Mapping BPSK
ik = 2 * sym(1 : 2 : end) - 1; %bits impair
pk = 2 * sym(2 : 2 : end) - 1; % bits pair
ck = ik + 1j * pk;

%Surechantillonage
sym1 = kron(ik, [1 zeros(1, Ns - 1)]);
sym2 = kron(pk, [1 zeros(1, Ns - 1)]);

% Génération de la réponse impulsionnelle du filtre de mise en forme
h = rcosdesign(beta, 8, Ns, 'sqrt');
delay = (span * Ns) / 2;

% Filtrage de mise en forme du signal généré sur la voie In-Phase (reelle)
Inphase = filter(h, 1, [sym1 zeros(1, delay)]);
Inphase = Inphase(delay + 1 : end);

% Filtrage de mise en forme du signal généré sur la voie Quadrature (imaginaire)
Quad = filter(h, 1, [sym2 zeros(1, delay)]);
Quad = Quad(delay + 1 : end);

% Le signal transmis sur fréquence porteuse(addition des 2 parties)
sum =  Inphase + 1i * Quad;

% Filtre temps de cohérence
[b,a] = butter(1,F);  %creation du filtre
Canal_Rice = randn(1,length(sum)) + 1j * randn(1,length(sum)); %generation du canal rice
m = filter(b,a,Canal_Rice); %filytrage du canal

alpha = sqrt(k * mean(abs(m) .^ 2)); %calcul de la const
modulation_r = (alpha + m).*sum;

TEB0 = zeros(1,17);
TEB1 = zeros(1,17);
for ii = 0 : 16
    % L'ajout du bruit blanc gaussien
    signal_puissance = mean(abs(sum) .^ 2);
    bruit_puissance = signal_puissance * Ns  / (2 * log2(4) * 10 .^ ((ii-8) / 10));
    bruit_gauss = (sqrt(bruit_puissance) * randn(1, length(sum))) + 1i * (sqrt(bruit_puissance) * randn(1, length(sum)));
    modulation_bruit = modulation_r + bruit_gauss;
    
    % Filtrage de réception
    h_r = h; %reponse impulsionelle du filtre
    sig_filtre = filter(h_r, 1, [modulation_bruit zeros(1,delay)]); %signale filtre en reception 
    sig_filtre = sig_filtre(delay + 1 : end);
    
    % Echantillonnage du signals
    sig_echant = sig_filtre(1 : Ns : end);

    % Egalisation ZF
    v = alpha + m;
    v_zf = v(1:Ns:end);
    sig_zf = sig_echant./v_zf;
    sig_ml = sig_echant.*conj(v_zf);

    % Demodulation aprés égalisation ZF

    sym_zf = zeros(1,length(sig_zf));
    for i = 1 : length(sig_zf)
        if (real(sig_zf(i)) <= 0 && imag(sig_zf(i)) <= 0)
            sym_zf(i) = -1 - 1i;
            
        elseif (real(sig_zf(i)) >= 0 && imag(sig_zf(i)) >= 0)
            sym_zf(i) = 1 + 1i;
            
        elseif (real(sig_zf(i)) <= 0 && imag(sig_zf(i)) >= 0)
            sym_zf(i) = -1 + 1i;
            
        elseif (real(sig_zf(i)) >= 0 && imag(sig_zf(i)) <= 0)
            sym_zf(i) = 1 - 1i;
        end
    end

    % Demodulation aprés égalisation ML

    sym_ml = zeros(1,length(sig_ml));
    for j = 1 : length(sig_ml)
        if (real(sig_ml(j)) <= 0 && imag(sig_ml(j)) <= 0)
            sym_ml(j) = -1 - 1i;
            
        elseif (real(sig_ml(j)) >= 0 && imag(sig_ml(j)) >= 0)
            sym_ml(j) = 1 + 1i;
            
        elseif (real(sig_ml(j)) <= 0 && imag(sig_ml(j)) >= 0)
            sym_ml(j) = -1 + 1i;
            
        elseif (real(sig_ml(j)) >= 0 && imag(sig_ml(j)) <= 0)
            sym_ml(j) = 1 - 1i;
        end
    end
   
    
    % Calcul du TEB
    TEB0(ii + 1) = length(find(sym_zf ~= ck)) / (length(ck));
    % Calcul du TEB
    TEB1(ii + 1) = length(find(sym_ml ~= ck)) / (length(ck));
    
end

% Comparaison entre le TE obtenu aprés égalisation ZF et l'égalisation ML.


figure;
semilogy([0: 16], TEB0, '*');
hold on
semilogy([0 : 16], TEB1, 'b');
grid
title('TEB Sans Codage pour les égalisations ZF et ML');
legend('TEB avec égalistion ZF','TEB avec égalistion ML')
xlabel("$\frac{Eb}{N_{o}}$ (dB)", 'Interpreter', 'latex');
ylabel('TEB');

% Calcule de la diversité
zf_diversite = polyfit(Eb_N0_dB,10*log(TEB0),1);
fprintf("Diversité de ZF est [%i %i] \n",zf_diversite);
ml_diversite = polyfit(Eb_N0_dB,10*log(TEB1),1);
fprintf("Diversité de ML est [%i %i] \n",ml_diversite);-1





%% sans enterlaceur


% Mapping 
s = 2 * sym -1;

% Génération de la suite de Diracs pondérés par les symbols (suréchantillonnage)
sym3 = kron(s, [1 zeros(1, Ns - 1)]);


% Filtrage de mise en forme du signal généré sur la voie I
In = filter(h, 1, [sym3 zeros(1, delay)]);
In = In(delay + 1 : end);

% Filtre temps de cohérence
[c,d] = butter(1,F);
Canal_Rice1 = randn(1,length(In)) + 1j * randn(1,length(In));
x = filter(c,d,Canal_Rice1);

alpha1 = sqrt(k * mean(abs(x) .^ 2));
modulation_rse = (alpha1 + x).*In;

TEB3 = zeros(1,17);
TEB4 = zeros(1,17);
for i = 0 : 16
    % L'ajout du bruit blanc gaussien
    sig_puiss = mean(abs(modulation_rse) .^ 2);
    bruit_puiss = sig_puiss * Ns  / (2 * log2(4) * 10 .^ (i / 10));
    gaussien_bruit = (sqrt(bruit_puiss) * randn(1, length(modulation_rse))) + 1i * (sqrt(bruit_puiss) * randn(1, length(modulation_rse)));
    modulation_br = modulation_rse + gaussien_bruit;
    
    % Filtrage de réception
    h_r = h;
    sig_filtre = filter(h_r, 1, [modulation_br zeros(1,delay)]);
    sig_filtre = sig_filtre(delay + 1 : end);
    
    % Echantillonnage du signals
    sig_echant = sig_filtre(1 : Ns : end);

    % Egalisation ZF
    v = alpha1 + x;
    v_zf = v(1:Ns:end);
    sig_zf = sig_echant./v_zf;
    sig_ml = sig_echant.*conj(v_zf);

    % Demodulation aprés égalisation ZF
    sym_zf = sign(real(sig_zf));
    sym_ml = sign(real(sig_ml));
    % Calcul du TES
    TEB3(i + 1) = length(find(sym_zf ~= s)) / (length(s));
    % Calcul du TES
    TEB4(i + 1) = length(find(sym_ml ~= s)) / (length(s));
    
end

% Comparaison entre le TEB obtenu aprés égalisation
% ZF et le TEB aprés égalisation ML.
figure;
semilogy([0 : 16], TEB3, 'r*');
hold on
semilogy([0 : 16], TEB4, 'r');
grid
title('TEB en absence du entrelaceur pour les égalisations ZF et ML');
legend('TEB avec égalistion ZF','TEB avec égalistion ML')
xlabel("$\frac{Eb}{N_{o}}$ (dB)", 'Interpreter', 'latex');
ylabel('TEB');

% Calcule de la diversité
diversite_zf = polyfit(Eb_N0_dB,10*log(TEB3),1);
fprintf("Diversité de ZF est : [%i %i] \n",diversite_zf);
diversite_ml = polyfit(Eb_N0_dB,10*log(TEB3),1);
fprintf("Diversité de ML est : [%i %i] \n ",diversite_ml);

