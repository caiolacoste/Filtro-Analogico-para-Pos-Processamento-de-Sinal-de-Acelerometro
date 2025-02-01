% Especificações de entrada
w_s = 5;
w_p = 1;
alpha_min = 4;
alpha_max = 0.05;

% Cálculo da ordem do filtro
n = log((10^(alpha_min/10)-1)/(10^(alpha_max/10)-1))/(2*log(w_s/w_p));
n_inteiro = ceil(n);
% Cálculo da frequência de corte
w_o1 = w_s/(10^(alpha_min/10)-1)^(1/(2*n_inteiro));
w_o2 = w_p/(10^(alpha_max/10)-1)^(1/(2*n_inteiro));

Q = 0.71;

% Dados do sistema
load('aceleracao.mat')
Ts=1/51200; % Período (incremento de tempo)
Fs=1/Ts; % Frequência em Hz
L=length(acc);
t = ((0:L-1)*Ts)'; % Duração total em segundos

% Combinar lado a lado em uma matriz com 2 colunas
aceleracao = [t, acc]; % Concatenação horizontal
x = aceleracao(:, 1);
y = aceleracao(:, 2);

% Função de transferência contínua
s = tf('s');
H_cont = w_o1^2/(s^2+(w_o1/Q)*s+w_o1^2);
% Simular a saída da função de transferência contínua
output_signal = lsim(H_cont, y, x);
% Remover o offset
offset = -0.644; % Valor do offset
output_signal_cont = output_signal - offset;

% Transformação bilinear (Tustin)
H_disc = c2d(H_cont, Ts, 'tustin');
% Simular a saída da função de transferência discreta
output_signal = lsim(H_disc, y, x);
% Remover o offset
output_signal_disc = output_signal - offset;

% Plotando os sinais
figure;
subplot(2,1,1);
plot(x, y, 'b', 'DisplayName', 'Sinal Original'); hold on;
plot(x, output_signal_cont, 'r', 'DisplayName', 'Sinal Filtrado', 'LineWidth',2);
title('Filtro analógico');
xlabel('Tempo (s)');
ylabel('Aceleração (m/s^2)');
grid on;

subplot(2,1,2);
plot(x, y, 'b', 'DisplayName', 'Sinal Original'); hold on;
plot(x, output_signal_disc, 'r', 'DisplayName', 'Sinal Filtrado', 'LineWidth',2);
title('Filtro digital');
xlabel('Tempo (s)');
ylabel('Aceleração (m/s^2)');
grid on;










