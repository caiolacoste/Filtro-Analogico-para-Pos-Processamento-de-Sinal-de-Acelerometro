% Especificações de entrada
w_s = 5;
w_p = 1;
alpha_min = 4;
alpha_max = 0.05;

% Cálculo da ordem do filtro
n = log10((10^(alpha_min/10)-1)/(10^(alpha_max/10)-1))/(2*log10(w_s/w_p));
n_inteiro = ceil(n);
% Cálculo da frequência de corte
w_o1 = w_s/(10^(alpha_min/10)-1)^(1/(2*n_inteiro));
w_o2 = w_p/(10^(alpha_max/10)-1)^(1/(2*n_inteiro));

Q = 0.71;

% Dados do sistema
load('aceleracao.mat')
T0=1/51200; % Período (incremento de tempo)
Fs=1/T0; % Frequência em Hz
L=length(acc);
t = ((0:L-1)*T0)'; % Duração total em segundos

s = tf('s');
H = w_o1^2/(s^2+(w_o1/Q)*s+w_o1^2);

% Combinar lado a lado em uma matriz com 2 colunas
aceleracao = [t, acc]; % Concatenação horizontal

x = aceleracao(:, 1);
y = aceleracao(:, 2);

% Simular a saída da função de transferência
output_signal = lsim(H, y, x);

% Remover o offset
offset = -0.644; % Valor do offset
output_signal_corrigido = output_signal - offset;

% Plotando os sinais
figure;
plot(x, y, 'b', 'DisplayName', 'Sinal Original'); hold on;
plot(x, output_signal_corrigido, 'r', 'DisplayName', 'Sinal Filtrado', 'LineWidth',2);
legend;
xlabel('Tempo (s)');
ylabel('Amplitude');
title('Comparação entre Sinal Original e Filtrado');
grid on;

v0 = 0; % Condição inicial da velocidade
s0 = 0; % Condição inicial do deslocamento
% Vetor de velocidade
v = cumtrapz(x, output_signal_corrigido);
% Vetor de deslocamento
s = cumtrapz(x, v);

% Ajustar com as condições iniciais
v = v + v0;
s = s + s0;

% Plotar os resultados
figure;
subplot(3,1,1);
plot(x, output_signal_corrigido, 'r', 'LineWidth', 1.5);
title('Aceleração');
xlabel('Tempo (s)');
ylabel('Aceleração (m/s^2)');
grid on;

subplot(3,1,2);
plot(x, v, 'b', 'LineWidth', 1.5);
title('Velocidade');
xlabel('Tempo (s)');
ylabel('Velocidade (m/s)');
grid on;

subplot(3,1,3);
plot(x, s, 'g', 'LineWidth', 1.5);
title('Deslocamento');
xlabel('Tempo (s)');
ylabel('Deslocamento (m)');
grid on;








