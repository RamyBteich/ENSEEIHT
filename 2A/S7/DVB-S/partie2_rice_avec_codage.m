clear;
close all;
clc;



%%Partie II :

%%3- Etude de la diversité apportée par le codage dans un canal de Rice non sélectif en
%%fréquence


% Initialisation des paramètres
M=4;
Ns=4;
beta=0.35;
span =8;
Eb_N0_dB=-16:16;
Te=1;
Ts=4*Te;
Tc=10*Ts;
F=1/(5*Tc);
TEB = zeros(1,33);
K=[0 5 10];
P = [1 1 0 1];
N = 204;
k = 188;
p = 8 * 100 * k;

% Génération de l'information binaire:
sym_colone=randi([0 1],p,1);
sym=sym_colone.';

% Codage RS
encoder = comm.RSEncoder(N,k,'BitInput',true);
decoder = comm.RSDecoder(N,k,'BitInput',true);
codedbits_RS= encoder(sym_colone);

% L'entrelacement
perm_vect = randperm(length(codedbits_RS)); 
f = intrlv(codedbits_RS,perm_vect);

% Generation du treillis 
treillis = poly2trellis([7], [171 133]);


% Generation du code convolutif (Avec entrelaceur)
coded_bits_ae = convenc(f.',treillis,P).';

% Mapping 
sig = qammod(coded_bits_ae,4,'InputType','bit').';
symb5 = kron(sig, [1 zeros(1, Ns - 1)]);

% Génération de la réponse impulsionnelle du filtre de mise en forme
h = rcosdesign(beta, 8, Ns, 'sqrt');
delay = (span * Ns) / 2;

signal_emis = filter(h,1,[symb5 zeros(1,delay)]);
u = signal_emis(1+delay: length(signal_emis));
    
   

for jj = 1:3 

   % Canal de Rice 
   canal_rice = (randn(1,length(u))+ 1i * randn(1,length(u)));
   [b,f] = butter(1,F);
   m = filter(b,f,canal_rice);
   beta_chan = sqrt(K(jj)*mean(m.^2));
   w = m+beta_chan;
   modulation_rac = (m+beta_chan).*u;


for jj = 0:32
   
    % L'ajout du bruit blanc gaussien
    sig_puiss = mean(abs(u) .^ 2);
    bruit_puiss = sig_puiss*Ns/(2*log2(M)*10 .^ ((jj-16)/ 10));
    sigma=sqrt(bruit_puiss);
    bruit = sigma*randn(1,length(modulation_rac)) + 1i*sigma*randn(1,length(modulation_rac)); 
    y = modulation_rac + bruit;

    % Egalisation ML:
    y = y.*conj(m+beta_chan);

    % Filtrage de réception
    hr = h;
    y = filter(hr, 1, [y zeros(1,delay)]);
    sig = y(1 + delay:end);

    
    % Demodulation
    sig_echantillonne = sig(1:Ns:end);
    decided_bits_m = qamdemod(sig_echantillonne,4,'OutputType','bit');
    decide_bits = reshape(decided_bits_m,1,2*length(decided_bits_m));
    
    % Decodage
    decoded_hard_bits = vitdec(decide_bits,treillis,35,'trunc','hard',P);

    % Suppression de l'entrelacement 
    decoded_hard_bits = deintrlv(decoded_hard_bits,perm_vect);

    % Décodage RS 
    decoded_bits = decoder(decoded_hard_bits.').';
    
    % Calcul du TEB
    TEB(jj + 1) = length(find(decoded_bits ~= sym)) / (length(sym));

end
plot(Eb_N0_dB,10*log(TEB))
hold on 
diversite = polyfit(Eb_N0_dB(3:14),10*log(TEB(3:14)),1);
fprintf("La diversité obtenu pour k=%d est [%i %i] \n",j,diversite);
end

legend("K=0dB","K=5dB","K=10dB")
xlabel("$\frac{Eb}{N_{o}}$ (dB)", 'Interpreter', 'latex');
ylabel("TEB")
