
close all;
clear all;

%% Simulation parameters
% On d�crit ci-apr�s les param�tres g�n�raux de la simulation

%modulation parameters
M = 4; %Modulation order 
Nframe = 100;
Nfft=1024;
Ncp=8;
Ns=Nframe*(Nfft+Ncp);
N= log2(M)*Nframe*Nfft;

%Channel Parameters
Eb_N0_dB = [0:100]; % Eb/N0 values

%Multipath channel parameters
hc=[1 -0.9];
Lc=length(hc);%Channel length
H=fft(hc,Nfft);

%Preallocations
nErr_zffde=zeros(1,length(Eb_N0_dB));
nErr_mmsefde=zeros(1,length(Eb_N0_dB));
for ii = 1:length(Eb_N0_dB)

   %Message generation
   bits= randi([0 1],N,1);
   s = qammod(bits,M,'InputType','bit');
   sigs2=var(s);
   
   %Add CP
   smat=reshape(s,Nfft,Nframe);
  % smat=ifft(smat);
   smatcp=[smat(end-Ncp+1:end,:);smat];
   scp=reshape(smatcp,1,(Nfft+Ncp)*Nframe);
   
    % Channel convolution: equivalent symbol based representation
   z = filter(hc,1,scp);  
   
   %Generating noise
   sig2b=10^(-Eb_N0_dB(ii)/10);
   
   %n = sqrt(sig2b)*randn(1,N+Lc-1); % white gaussian noise, 
   n = sqrt(sig2b/2)*randn(1,Ns)+1j*sqrt(sig2b/2)*randn(1,Ns); % white gaussian noise, 
   
    % Noise addition
   ycp = z + n; % additive white gaussian noise

   %remove CP
   yrmcp=reshape(ycp,Nfft+Ncp,Nframe);
   yrm=yrmcp(Ncp+1:end,:);
   
   %FDE
   yrm=fft(yrm);
   
   %Detection
   w_zf=conj(H)./(abs(H).*abs(H));
   w_mmse=conj(H)./(abs(H).*abs(H)+sig2b/sigs2);
  
   Y_zf=yrm.*w_zf.';
   Y_mmse=yrm.*w_mmse.';

   Y_zf=ifft(Y_zf);
   Y_mmse=ifft( Y_mmse);

   Y_zf=reshape(Y_zf,1,Nfft*Nframe).';
   Y_mmse=reshape(Y_mmse,1,Nfft*Nframe).';
   
   bhat_zfeq=qamdemod(Y_zf,4,'OutputType','bit');
   bhat_mmseeq=qamdemod(Y_mmse,4,'OutputType','bit');
   
   nErr_zffde(1,ii) = size(find([bits(:)- bhat_zfeq(:)]),1);
   nErr_mmsefde(1,ii) = size(find([bits(:)- bhat_mmseeq(:)]),1);

end

simBer_zf = nErr_zffde/N; % simulated ber
simBer_mmse=nErr_mmsefde/N;
% plot

figure
semilogy(Eb_N0_dB,simBer_zf(1,:),'bs-','Linewidth',2);
hold on
semilogy(Eb_N0_dB,simBer_mmse(1,:),'rd-','Linewidth',2);
axis([0 30 10^-6 0.5])
grid on
legend('sim-zf-fde','sim-mmse-fde');
xlabel('Eb/No, dB');
ylabel('Bit Error Rate');
title('Bit error probability curve for QPSK in ISI with ZF and MMSE equalizers')

%% Simulation parameters
M = 4; %Modulation order
Nframe = 100;
Nfft=1024;
Ncp=8;
Ns=Nframe*(Nfft+Ncp);
N= log2(M)*Nframe*Nfft;
hMod = comm.QPSKModulator('BitInput',true);
hDemodHD = comm.QPSKDemodulator('BitOutput',true,...
    'DecisionMethod', 'Hard decision');


%Channel Parameters
Eb_N0_dB = [0:70]; % Eb/N0 values

%Multipath channel parameters
%hc=[1 -0.9];
hc1=[0.227, 0.46, 0.688, 0.460, 0.227];
hc2=[0.227, 0.46, 0.688, 0.460, 0.227];
Lc1=length(hc1);%Channel length
Lc2=length(hc2);%Channel length
H1=fft(hc1,Nfft);
H2=fft(hc2,Nfft);

%Preallocations
nErr_zffde=zeros(1,length(Eb_N0_dB));
nErr_mmsefde=zeros(1,length(Eb_N0_dB));
biasvect=zeros(1,length(Eb_N0_dB));

for ii = 1:length(Eb_N0_dB)

   disp(ii);
   %Message generation

   %first user
   fuser= randi([0 1],N/2,1);
   f1 = step(hMod, fuser);
   smat1 = reshape(f1,Nfft/2,Nframe);
   F1 = fft(smat1,Nfft/2,1);
   F11 = ifft([F1;zeros(Nfft/2,Nframe)],Nfft,1);

   sigs2=var(f1);

   %second user
   bits2= randi([0 1],N/2,1);
   f2 = step(hMod, bits2);
   smat2 = reshape(f2,Nfft/2,Nframe);
   F2 = fft(smat2,Nfft/2,1);
   F22 = ifft([zeros(Nfft/2,Nframe);F2],Nfft,1);

   %Add CP

   %first user
   fusercp=[F11(end-Ncp+1:end,:);F11];
   fuserScp=reshape(fusercp,1,(Nfft+Ncp)*Nframe);


   %second user
   susercp=[F22(end-Ncp+1:end,:);F22];
   suserScp=reshape(susercp,1,(Nfft+Ncp)*Nframe);

   % Channel convolution: equivalent symbol based representation

   %first user
   z1 = filter(hc1,1,fuserScp);

   %second user
   z2 = filter(hc2,1,suserScp);


   %Generating noise
   sig2b=10^(-Eb_N0_dB(ii)/10);

   %n = sqrt(sig2b)*randn(1,N+Lc-1); % white gaussian noise,
   n = sqrt(sig2b/2)*randn(1,Ns)+1j*sqrt(sig2b/2)*randn(1,Ns); % white gaussian noise,

    % Noise addition
   ycp = z1 + z2 + n; % additive white gaussian noise

   %remove CP
   yrmcp=reshape(ycp,Nfft+Ncp,Nframe);

   y = yrmcp(Ncp+1:end,:);

   %first user

   H = H1;

   bits = fuser; % estimation first user 

   %% zero forcing equalization
   % We now study ZF equalization
   W_zf=1./H;
   Y=fft(y,Nfft,1);
   Yf=diag(W_zf)*Y;%static channel
   xhat_zf=ifft(Yf(1:Nfft/2,:),Nfft/2,1); % Nfft/2+1 : end
   bhat_zfeq = step(hDemodHD,xhat_zf(:));
   %%%%%%

   %% MMSE Equalization
   % We now study MMSE equalization
   W_mmse=conj(H)./(abs(H).^2+sig2b/sigs2);
   Y=fft(y,[],1);
   Yf=diag(W_mmse)*Y;
   xhat_mmse=ifft(Yf(1:Nfft/2,:),[],1);
   bhat_mmseeq = step(hDemodHD,xhat_mmse(:));
   %%%%%%
    nErr_zffde(1,ii) = size(find([bits(:)- bhat_zfeq(:)]),1);
    nErr_mmsefde(1,ii) = size(find([bits(:)- bhat_mmseeq(:)]),1);
    biasvect(ii)=1/Nfft*sum(W_mmse.*H);
end

simBer_zf = nErr_zffde/N/2; % simulated ber
simBer_mmse = nErr_mmsefde/N/2; % simulated ber
% plot

figure
semilogy(Eb_N0_dB,simBer_zf(1,:),'bs-','Linewidth',2);
hold on
semilogy(Eb_N0_dB,simBer_mmse(1,:),'rd-','Linewidth',2);
axis([0 70 10^-6 0.5])
grid on
legend('sim-zf-fde','sim-mmse-fde');
xlabel('Eb/No, dB');
ylabel('Bit Error Rate');
title('Bit error probability curve for QPSK in ISI with ZF and MMSE equalizers')

bias= 1/Nfft*sum(W_mmse.*H);
%% Partie Multi-utilisateurs


%% Simulation parameters
% On décrit ci-après les paramètres généraux de la simulation

%modulation parameters
M = 4; %Modulation order 
Nframe = 10000;
Nfft=1024;
Nfftu = 512;
Ncp=8;
Ns=Nframe*(Nfft+Ncp);
N= log2(M)*Nframe*Nfft;
Nsamples = 100;

%Channel Parameters
Eb_N0_dB = 5; % Eb/N0 values

%Multipath channel parameters
hc1=[1 -0.9];
hc2=[0.227,0.46,0.688,0.46,0.227];
Lc1=length(hc1);%Channel length
Lc2=length(hc2);
H1=fft(hc1,Nfft);
H2=fft(hc2,Nfft);

%Preallocations
bits1 = randi([0 1],N/2,1);
bits2 = randi([0 1],N/2,1);
s1 = qammod(bits1,M,'InputType','bit');
s2 = qammod(bits2,M,'InputType','bit');
sigs1 = var(s1);
sigs2 = var(s2);

smat1 = reshape(s1,Nfftu,Nframe);
smat2 = reshape(s2,Nfftu,Nframe);

u1 = [fft(smat1);zeros(Nfftu,Nframe)];
u2 = [zeros(Nfftu,Nframe);fft(smat2)];
u1 = ifft(u1);
u2 = ifft(u2);

u1cp = [u1(end-Ncp+1:end,:);u1];
u2cp = [u2(end-Ncp+1:end,:);u2];
z1 = reshape(u1cp,1,Ns);
z2 = reshape(u2cp,1,Ns);
z1 = filter(hc1,1,z1);
z2 = filter(hc2,1,z2);
z = z1 + z2;

sig2b=10^(-Eb_N0_dB/10);
n = sqrt(sig2b/2)*randn(1,Ns)+1j*sqrt(sig2b/2)*randn(1,Ns);
y = z + n;
y = reshape(y,Nfft+Ncp,Nframe);
y = y(Ncp+1:end,:);

Y = fft(y);

W1 = conj(H1)./(abs(H1).^2 + sig2b/sigs1);
W2 = conj(H2)./(abs(H2).^2 + sig2b/sigs2);
Y1 = diag(W1(1:Nfftu))*Y(1:Nfftu,:);
Y2 = diag(W2(Nfftu+1:end))*Y(Nfftu+1:end,:);
S1 = ifft(Y1);
S2 = ifft(Y2);

xhat1 = qamdemod(S1(:),M,'outputType','bit');
xhat2 = qamdemod(S2(:),M,'outputType','bit');




figure()
subplot(2,1,1)
plot(abs(fft(hc1,4096)));
title("Module de la réponse fréquentielle du premier")
subplot(2,1,2)
plot(angle(fft(hc1,4096)));
title("Phase de la réponse fréquentielle du premier")

figure()
subplot(2,1,1)
plot(abs(fft(hc2,4096)));
title("Module de la réponse fréquentielle ddu deuxieme")
subplot(2,1,2)
plot(angle(fft(hc2,4096)));
title("Phase de la réponse fréquentielle du deuxieme")












    