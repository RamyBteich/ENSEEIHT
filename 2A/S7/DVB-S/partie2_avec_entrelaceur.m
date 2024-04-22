clear all 
close all





% Initialisation des paramètres
M=4;
beta=0.5;
P=[1 1 0 1];
Eb_N0_dB=-32:0;
Eb_N0_dB2=0:20;
n0=8;
Te=1;
span = 8;
Ts=4*Te;
Tc=10*Ts;
F=1/(5*Tc);
k=5;
Ns=1;
N=204;
K=188;
p = 8 * 100 * K;



% Génération de l’information binaire
sym_colone = randi([0 1],p,1);
sym = sym_colone.';

% Codage RS
encoder = comm.RSEncoder(N,K,'BitInput',true);
decoder = comm.RSDecoder(N,K,'BitInput',true);
codedbits_RS=encoder(sym_colone);


% L'entrelacement :
perm_vect = randperm(length(codedbits_RS));
f = intrlv(codedbits_RS,perm_vect);

% Generation du treillis
trellis = poly2trellis([7],[171 133]);

% Generation du code convolutif avec entrelaceur
codedbits_ae = convenc(f.',trellis,P).';

% Modulation BPSK
 
sig_RS = qammod(codedbits_ae,2,'InputType','bit').';
symb4 = kron(sig_RS, [1 zeros(1, Ns - 1)]);

% Génération de la réponse impulsionnelle du filtre de mise en forme
h = rcosdesign(beta, 8, Ns, 'sqrt');
delay = (span * Ns) / 2;

% Filtrage de mise en forme du signal
u= filter(h,1,[symb4 zeros(1,delay)]);
u= u(1 + delay : end);
    
   
% Canal de Rice 
canal_Rice= randn(1,length(u)) + i*randn(1,length(u));
[e,f] = butter(1,F);

m = filter(e,f,canal_Rice);
beta1= sqrt(k*mean(m.^2));
w= m + beta1;
modulation_ae = (m+beta1).*u;

TEB4=zeros(1,33);
TEB5=zeros(1,33);

% %% BPSK
% for i=0:32
%    
% 
% 
%      % L'ajout du bruit blanc gaussien
% 
%     sig_puiss = mean(abs(u) .^ 2);
%     bruit_puiss=sig_puiss *Ns / (2*log2(M) * 10 .^ ((i-16) / 10));
%     gaussien_br = (sqrt(bruit_puiss) * randn(1, length(modulation_ae))) + 1i * (sqrt(bruit_puiss) * randn(1, length(modulation_ae)));
%     y= modulation_ae + gaussien_br;
% 
%     % Egalisation :
%     sig_ml = y.*conj(w);
% 
%     % Filtrage de réception
%     h_r = h;
%     sig = filter(h_r, 1, [sig_ml zeros(1,delay)]);
%     sig = sig(delay + 1 : end);
% 
%     
%     % Echantillonage 
%     sig_echantillonne = sig(1:Ns:end);
% 
%     % Demodulation
%     dicided_bits_soft= qamdemod(sig_echantillonne,2,'OutputType','llr');
%     decided_bits_hard = qamdemod(sig_echantillonne,2,'OutputType','bit');
% 
% 
% 
%     % Decodage
%     tblen=5*7;
% 
%     % Hard decoding  
%     hard_bits_decodes = vitdec(decided_bits_hard,trellis,tblen,'trunc','hard',P);
% 
%     % Suppression de l'entrelacement
%     hard_bits_decodes = deintrlv(hard_bits_decodes,perm_vect);
% 
%     % Décodage RS :
%     hard_bits_decodes = decoder(hard_bits_decodes.').';
%     
%     % TEB
% 	TEB4(i + 1) = length(find(hard_bits_decodes ~= sym)) / (length(sym));
% 
% 
%     % Soft decoding :
%    
%     soft_bits_decodes = vitdec(dicided_bits_soft,trellis,tblen,'trunc','unquant',P);
%     %dé_entrelacement
%     soft_bits_decodes=deintrlv(soft_bits_decodes,perm_vect);
%     %décodage RS :
%     soft_bits_decodes=decoder(soft_bits_decodes.');
%     soft_bits_decodes=soft_bits_decodes.';
%     % TEB
% 	TEB5(i + 1) = length(find(soft_bits_decodes ~= sym)) / (length(sym));
% 
%     
%     
% 
% end
% 
% % Comparaison entre le taux d'erreur binaire (TEB) obtenu avec un codage
% % soft et le TEB obtenu avec un codage hard
% figure;
% semilogy([0 : 32], TEB4, 'r');
% hold on
% semilogy([0 : 32], TEB5, 'g');
% grid
% title('TEB avec entrelacement dans le cas d une modulation BPSK');
% legend('TEB avec codage Hard','TEB avec codage Soft')
% xlabel("$\frac{Eb}{N_{o}}$ (dB)", 'Interpreter', 'latex');
% ylabel('TEB');
% 
% 
% % Diversités :
% d_soft=polyfit(Eb_N0_dB(6:19),10*log(TEB4(6:19)),1);
% fprintf("Diversité de ZF soft est : [%i %i] \n",d_soft);
% d_hard=polyfit(Eb_N0_dB(6:19),10*log(TEB5(6:19)),1);
% fprintf("Diversité de ZF hard est : [%i %i] \n",d_hard);


%% QPSK

%variables de la chaine de trasmission :
M=4;
beta=0.5;
n0=8;
P=[1 1 0 1];
Eb_N0_dB=0:20;
Te=1;
span = 8;
Ts=4*Te;
Tc=10*Ts;
F=1/(5*Tc);
K=5;
Ns=4;
N=204;
K=188;
p = 8 * 100 * K;



% Génération de l’information binaire
bits_colone = randi([0 1],p,1);
bits = bits_colone.';

% Codage RS
encoder = comm.RSEncoder(N,K,'BitInput',true);
decoder = comm.RSDecoder(N,K,'BitInput',true);
codedbits_RS=encoder(bits_colone);


% L'entrelacement :
perm_vect = randperm(length(codedbits_RS));
f = intrlv(codedbits_RS,perm_vect);

% Generation du treillis
trellis = poly2trellis([7],[171 133]);

% Generation du code convolutif (Avec entrelaceur)
codedbits_ae = convenc(f.',trellis,P).';

% Modulation BPSK
 
sig_RS = qammod(codedbits_ae,4,'InputType','bit').';
symb4 = kron(sig_RS, [1 zeros(1, Ns - 1)]);

% Génération de la réponse impulsionnelle du filtre de mise en forme
h = rcosdesign(beta, 8, Ns, 'sqrt');
delay = (span * Ns) / 2;

% Filtrage de mise en forme du signal
u= filter(h,1,[symb4 zeros(1,delay)]);
u= u(1 + delay : end);
    
   
% Canal de Rice 
canal_Rice= randn(1,length(u)) + j*randn(1,length(u));
[e,f] = butter(1,F);

m = filter(e,f,canal_Rice);
beta1= sqrt(K*mean(m.^2));
w= m + beta1;
modulation_ae = (m+beta1).*u;

TEB6=zeros(1,21);
TEB7=zeros(1,21);

for j=0:20
   


     % L'ajout du bruit blanc gaussien

    sig_puiss = mean(abs(u) .^ 2);
    bruit_puiss=sig_puiss *Ns / (2*log2(M) * 10 .^ (j / 10));
    gaussien_br = (sqrt(bruit_puiss) * randn(1, length(modulation_ae))) + 1i * (sqrt(bruit_puiss) * randn(1, length(modulation_ae)));
    y= modulation_ae + gaussien_br;

    % Egalisation :
    sig_ml = y.*conj(w);

    % Filtrage de réception
    h_r = h;
    sig = filter(h_r, 1, [sig_ml zeros(1,delay)]);
    sig = sig(delay + 1 : end);

    
    % Echantillonage 
    sig_echantillonne = sig(1:Ns:end);

    % Demodulation
    decided_soft_bits= qamdemod(sig_echantillonne,4,'OutputType','llr');
    decided_soft_bits_s = reshape(decided_soft_bits,1,2*length(decided_soft_bits));
    decided_hard_bits = qamdemod(sig_echantillonne,4,'OutputType','bit');
    decided_hard_bits_s = reshape(decided_hard_bits,1,2*length(decided_hard_bits));



    % Decodage
    tblen=5*7;

    % Hard decoding  
    hard_decoded_bits = vitdec(decided_hard_bits_s,trellis,tblen,'trunc','hard',P);

    % Suppression de l'entrelacement
    hard_decoded_bits = deintrlv(hard_decoded_bits,perm_vect);

    % Décodage RS :
    hard_decoded_bits = decoder(hard_decoded_bits.').';
    
    % TEB
	TEB6(j + 1) = length(find(hard_decoded_bits ~= bits)) / (length(bits));


    % Soft decoding 
    soft_decoded_bits = vitdec(decided_soft_bits_s,trellis,tblen,'trunc','unquant',P);

    %déentrelacement
    soft_decoded_bits=deintrlv(soft_decoded_bits,perm_vect);

    %décodage RS :
    soft_decoded_bits=decoder(soft_decoded_bits.');
    soft_decoded_bits=soft_decoded_bits.';

    % TEB
	TEB7(j + 1) = length(find(soft_decoded_bits ~= bits)) / (length(bits));

    
    

end

figure;
semilogy([0 : 20], TEB6, 'g');
hold on
semilogy([0 : 20], TEB7, 'b');
grid
title('TEB avec entrelacement dans le cas de modulation QPSK');
legend('TEB avec codage Hard','TEB avec codage Soft')
xlabel("$\frac{Eb}{N_{o}}$ (dB)", 'Interpreter', 'latex');
ylabel('TEB');


% Diversités :
d_soft=polyfit(Eb_N0_dB(3:14),10*log(TEB6(3:14)),1);
fprintf("Diversité soft est : [%i %i] \n",d_soft);
d_hard=polyfit(Eb_N0_dB(3:14),10*log(TEB7(3:14)),1);
fprintf("Diversité hard est : [%i %i] \n",d_hard);


