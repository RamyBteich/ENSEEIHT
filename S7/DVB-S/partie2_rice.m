clear;
close all;
clc;


% Initialisation des paramètres
M=4;
Ns=4;
beta=0.35;
n=20000;
span =8;
Eb_N0_dB=0:20;
Te=1;
Ts=4*Te;
Tc=10*Ts;
F=1/(5*Tc);
TEB = zeros(1,21);
K=[0 5 10];


% Génération de l'information binaire 
sym_colone=randi([0 1],n,1);
sym=sym_colone.';




% Mapping permettant d'obtenir dk ∈ {±1 ± j}
symboles = qammod(sym_colone,4,'InputType','bit').';

% Génération de la suite de Diracs pondérés par les symbols (suréchantillonnage)
symboles_surechan = kron(symboles, [1 zeros(1, Ns - 1)]);

% Génération de la réponse impulsionnelle du filtre de mise en forme
h = rcosdesign(beta, 8, Ns, 'sqrt');
delay = (span * Ns) / 2;

signal_emis = filter(h,1,[symboles_surechan zeros(1,delay)]);
u = signal_emis(1+delay: length(signal_emis));
    
   

for i = 1:3 

   % Canal de Rice 
   canal_rice = randn(1,length(u))+ 1i * randn(1,length(u));
   [b,f] = butter(1,F);
   m = filter(b,f,canal_rice);
   beta_chan = sqrt(K(i)*mean(m.^2));
   w = m+beta_chan;
   modulation_rsc = (m+beta_chan).*u;


for j = 0:20
   
    % L'ajout du bruit blanc gaussien
    sig_puiss = mean(abs(u) .^ 2);
    bruit_puiss = sig_puiss*Ns/(2*log2(M)*10 .^ (j / 10));
    sigma=sqrt(bruit_puiss);
    bruit = sigma*randn(1,length(modulation_rsc)) + 1i*sigma*randn(1,length(modulation_rsc)); 
    y = modulation_rsc + bruit;

    % Egalisation ML:
    y = y.*conj(m+beta_chan);

    % Filtrage de réception
    hr = h;
    y = filter(hr, 1, [y zeros(1,delay)]);
    sig = y(1 + delay:end);

    
    % Demodulation
    sig_echantillonne = sig(1:Ns:end);
    decided_bits_m = qamdemod(sig_echantillonne,4,'OutputType','bit');
    decided_bits = reshape(decided_bits_m,1,2*length(decided_bits_m));

   
    % Calcul du TEB
    TEB(j + 1) = length(find(decided_bits ~= sym)) / (length(sym));

end


plot(Eb_N0_dB,10*log(TEB))
hold on 
diversite = polyfit(Eb_N0_dB(3:14),10*log(TEB(3:14)),1);
fprintf("La diversité obtenu pour k=%d est [%i %i] \n",i,diversite);
end

legend("K=0dB","K=5dB","K=10dB")
xlabel("$\frac{Eb}{N_{o}}$ (dB)", 'Interpreter', 'latex');
ylabel("TEB")





