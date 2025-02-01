% Dados do sistema
load('aceleracao.mat')
T0=1/51200;
Fs=1/T0;
L=length(acc);

NFFT = 2^nextpow2(L); % Número de pontos na FFT
Ys = fft(acc, NFFT)/L; % Transformada de Fourier normalizada
fs = Fs/2*linspace(0, 1, NFFT/2+1); % Escala de frequências positivas
% bar(fs,2*abs(Ys(1:NFFT/2+1)))
% grid

% Parâmetros do filtro
f_cut = 4; % Frequência de corte (Hz)
cut_idx = find(fs > f_cut, 1); % Índice correspondente à frequência de corte

% Aplicar filtro de corte
Ys_filtered = Ys; % Cópia do espectro original
Ys_filtered(cut_idx:end) = 0; % Zerar frequências acima de f_cut
Ys_filtered(end-cut_idx+1:end) = 0; % Zerar simetricamente no domínio da frequência

% Transformada inversa para retornar ao domínio do tempo
filtered_signal = ifft(Ys_filtered, 'symmetric') * L; % Sinal filtrado

% Plotar os resultados
% figure;

t = (0:L-1)*T0; % Vetor de tempo
plot(t, acc);
hold on;
plot(t, filtered_signal(1:L),'LineWidth', 2); % Pegue apenas os L primeiros pontos do sinal
title('Sinal no Tempo');
xlabel('Tempo (s)');
ylabel('Amplitude');
grid;
