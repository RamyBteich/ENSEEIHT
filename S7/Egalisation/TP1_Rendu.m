
% Script for computing the BER for BPSK/QPSK modulation in ISI Channels
% 
close all;
clear all;

%% Simulation parameters
% On décrit ci-après les paramètres généraux de la simulation

%Frame length
M=4; %2:BPSK, 4: QPSK
N  = 1000000; % Number of transmitted bits or symbols
Es_N0_dB = [0:30]; % Eb/N0 values

%Multipath channel parameters
hc=[1 0.8*exp(1i*pi/3) 0.3*exp(1i*pi/6) ];%0.1*exp(1i*pi/12)];%ISI channel
% hc=[0.04, -0.05, 0.07, -0.21, -0.5, 0.72, 0.36, 0, 0.21, 0.03, 0.07];
%a=1.2;
%hc=[1 -0.9];

Lc=length(hc);%Channel length
ChannelDelay=0; %delay is equal to number of non causal taps

%Preallocations
nErr_zf=zeros(1,length(Es_N0_dB));
nErr_zfinf=zeros(1,length(Es_N0_dB));
nErr_mmseinf=zeros(1,length(Es_N0_dB));
nErr_zfinfdirectimp=zeros(1,length(Es_N0_dB));
nErr_mmseinfdirectimp=zeros(1,length(Es_N0_dB));

const=qammod((0:M-1)',M); %reference Gray QPSK constellation
tblen=16; %Traceback depth
nsamp=1; %Oversampling rate
preamble=[];
postamble=[];


for ii = 1:length(Es_N0_dB)

%    % BPSK symbol generations
%    bits = rand(1,N)>0.5; % GENERATING 0,1 WITH EQUAL PROBABILITY
%    s = 1-2*bits; % BPSK MODULATION FOLLOWING: {0 -> +1; 1 -> -1} 
   
    % QPSK symbol generations
   bits = rand(2,N)>0.5; % generating 0,1 with equal probability
   s = 1/sqrt(2)*((1-2*bits(1,:))+1j*(1-2*bits(2,:))); % QPSK modulation following the BPSK rule for each quadatrure component: {0 -> +1; 1 -> -1} 
   sigs2=var(s);
   
   % Channel convolution: equivalent symbol based representation
   z = conv(hc,s);  
   
   %Generating noise
   sig2b=10^(-Es_N0_dB(ii)/10);

  % n = sqrt(sig2b)*randn(1,N+Lc-1); % white gaussian noise, BPSK Case
    n = sqrt(sig2b/2)*randn(1,N+Lc-1)+1j*sqrt(sig2b/2)*randn(1,N+Lc-1); % white gaussian noise, QPSK case
   
   % Adding Noise
   y = z + n; % additive white gaussian noise

%    %% zero forcing equalization
%    % We now study ZF equalization
%    
%    %Unconstrained ZF equalization, only if stable inverse filtering
%    
%    
   s_zf=filter(1,hc,y);   %if stable causal filter is existing
    bhat_zf = zeros(2,length(bits));
    bhat_zf(1,:)= real(s_zf(1:N)) < 0;
    bhat_zf(2,:)= imag(s_zf(1:N)) < 0;
    nErr_zfinfdirectimp(1,ii) = size(find([bits(:)- bhat_zf(:)]),1);



       

    %Otherwise, to handle the non causal case
    Nzf=200;
    [r, p, k]=residuez(1, hc);
    [w_zfinf]=computerI( Nzf, r, p, k );
    s_zf=conv(w_zfinf,y);
    bhat_zf = zeros(2,length(bits));
    bhat_zf(1,:)= real(s_zf(Nzf:N+Nzf-1)) < 0;
    bhat_zf(2,:)= imag(s_zf(Nzf:N+Nzf-1)) < 0;
    nErr_zfinf(1,ii) = size(find([bits(:)- bhat_zf(:)]),1);
    
        %MMSE filter
    deltac = zeros(1, 2*Lc-1);
    deltac(Lc) = 1;
    Nmmse = 200; % calcul part
    [r, p, k] = residuez(fliplr(conj(hc)), (conv(hc, fliplr(conj(hc)))+(sig2b/sigs2)*deltac));
    [w_mmseinf] = computerI(Nmmse, r, p, k);
    s_mmse=conv(w_mmseinf,y);
    bhat_mmse=zeros(2,length(bits));
    bhat_mmse(1,:)= real(s_mmse(Nmmse:N+Nmmse-1)) < 0;
    bhat_mmse(2,:)= imag(s_mmse(Nmmse:N+Nmmse-1)) < 0;
    nErr_mmseinfdirectimp(1,ii) = size(find([bits(:) - bhat_mmse(:)]),1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Nw =100;
    H= toeplitz([hc(1) zeros(1,Nw-1)]',[hc,zeros(1 ,Nw-1)]);
    Ry=conj(H)*H.';
    p=zeros(Nw+Lc-1,1);
    P=H.'*inv(Ry)*conj(H);
    [alpha,dopt]=max(diag(abs(P)));
    p(dopt)=1;
    gamma=conj(H)*p;
    w_zf_ls=(inv(Ry)*gamma).';
    sig_e_opt=sigs2-conj(w_zf_ls)*gamma;

    bias=1-sig_e_opt/sigs2;

    shat=conv(w_zf_ls,y);
    shat=shat(dopt:end);
    bhat_zf = zeros(2,length(bits));
    bhat_zf(1,:)= real(s_zf(1:N)) < 0;
    bhat_zf(2,:)= imag(s_zf(1:N)) < 0;
    nErr_zf= size(find([bits(:)- bhat_zf(:)]),1);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%     % MMSE avec bruit
   Nw =100;
 
   H1= toeplitz([hc(1) zeros(1,Nw-1)]',[hc,zeros(1 ,Nw-1)]);
   q=sig2b/sigs2;
   Ry1=(conj(H1)*H1.'+q*eye(length(conj(H1)*H1.')));
   p=zeros(Nw+Lc-1,1);
   P=H1.'*inv(Ry1)*conj(H1);
   [alpha,dopt]=max(diag(abs(P)));
   p(dopt)=1;
   gamma=conj(H1)*p;
   w_mmse_ls=(inv(Ry1)*gamma).';
   sig_e_opt=sigs2-conj(w_mmse_ls)*gamma;
   bias=1-sig_e_opt/sigs2;
   shat1=conv(w_mmse_ls,y);
   shat1=shat1(dopt:end);
   bhat1=zeros(2,length(bits));
   bhat1(1,:)=real(shat1(1:N))<0;
   bhat1(2,:)=imag(shat1(1:N))<0;
   nErr_mmseinf(1,ii) = size(find([bits(:)- bhat1(:)]),1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Maximum likelihood
    s_ml = mlseeq(y,hc,const,tblen,'rst',nsamp,[ ],[ ])/sqrt(2) ;
    bits_ml = zeros(2,length(bits));
    bits_ml(1,:) = real(s_ml(1:N))<0;
    bits_ml(2,:) = imag(s_ml(1:N))<0;
    nErr_ml(1,ii) = size(find([bits(:)- bits_ml(:)]),1);



 end
ii=1
simBer_zfinfdirectimp = nErr_zfinfdirectimp/N/log2(M); % simulated ber
simBer_zfinf = nErr_zfinf/N/log2(M); % simulated ber
simBer_mmseinf =  nErr_mmseinf/N/log2(M); % simulated ber
simBer_mmseindirectimp = nErr_mmseinfdirectimp/N/log2(M); % simulated ber
simBer_zf = nErr_zf/N/log2(M);

%plot



Fe = 1;
figure
[DSP_emission, freq]=pwelch(s,[],[],[],Fe);
plot(freq, log(DSP_emission))
title("DSP à l'émission")


figure
subplot(2,1,1)
[DSP_nb, freq]=pwelch(z,[],[],[],Fe);
plot(freq, log(DSP_nb))
title("DSP sans bruit")

subplot(2,1,2)
[DSP_b, freq] = pwelch(y,[],[],[],Fe);
plot(freq, log(DSP_b))
title("DSP avec bruit")


scatterplot(y)
title("Avec bruit")
scatterplot(z)
title("sans bruit")


figure
plot(Es_N0_dB,simBer_zf)
title("TEB avec égaliseur ZF ")






figure
semilogy(Es_N0_dB,simBer_mmseinf(1,:),'bs-','Linewidth',2);
axis([0 50 10^-6 0.5])
hold on
semilogy(Es_N0_dB,simBer_zfinf(1,:),'rs-','Linewidth',2);
axis([0 50 10^-6 0.5])
grid on
legend('sim-msme-inf/direct','sim-zf-inf/direct');
xlabel('E_s/N_0, dB');
ylabel('Bit Error Rate');
title('Comparison between MMSE & ZF (QPSK:ISI)')

figure

stem(real(w_mmseinf))
hold on
stem(real(w_mmseinf),'b-')
xlabel('time index')
ylabel('Amplitude');
title('MMSE Impulse response')

figure

stem(real(w_zfinf))
hold on
stem(real(w_zfinf),'g-')
xlabel('time index')
ylabel('Amplitude');
title('ZF Impulse response')

figure
semilogy(Es_N0_dB,simBer_zfinf(1,:),'bs-','Linewidth',2);
axis([0 50 10^-6 0.5])
hold on
semilogy(Es_N0_dB,simBer_mmseindirectimp(1,:),'rs-','Linewidth',2);
grid on
legend('RIF~ZF','RIF~MMSE');
xlabel('E_s/N_0, dB');
ylabel('Bit Error Rate');
title("Egaliseurs à structure RIF")


%% Egaliseur Maximum de vraisemblance
simBer_ml = nErr_ml/N/log2(M); % simulated ber
figure
semilogy(Es_N0_dB,simBer_ml,'bo-','Linewidth',2);
xlabel('E_s/N_0, dB');
ylabel('Bit Error Rate');
title('Bit error probability curve for Maximum Likelihood Equalizer')


