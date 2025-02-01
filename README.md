# Filtro Analógico para Pós-Processamento de Sinal de Acelerômetro

## 1. Introdução

O objetivo deste projeto é a obtenção de um filtro analógico para processar um sinal corrompido por ruídos de baixas e altas frequências, obtendo informações de aceleração, velocidade e posição de um veículo em função do tempo.

O **sinal utilizado** foi obtido de um acelerômetro instalado num carro. O carro acelera, a partir do estado de repouso, atinge uma velocidade máxima e depois desacelera até parar. A aquisição de dados começou alguns segundos antes da partida do carro, ficando um tempo parado, para que pudesse identificar a presença de off-set no sinal (valor CC). A frequência de amostragem do sinal foi de 51200Hz.

Para a retirada dos ruídos, foi utilizado um filtro low-pass (passa-baixas) **Butterworth**. Sua escolha se dá pela preferência à resposta em frequência o mais plana possível na banda passante, sem ondulações, em comparação com o filtro de Chebyshev, onde a atenuação rápida é mais importante e as ondulações são aceitáveis.

Foi escolhido um filtro **passa-baixas** ao invés de passa-banda porque o ruído de baixas frequências é o próprio off-set presente na medição, que será medido e retirado posteriormente. A função de transferência do filtro analógico low-pass Butterworth adotada é mostrada abaixo:

$$
H(s) = \frac{\omega_o^2}{s^2+(\frac{\omega_o}{Q})s+\omega_o^2},
$$

em que $\omega_o$ é a frequência de corte e $Q$ é o fator de qualidade.

## 2. Metodologia

Para o projeto do filtro analógico, é aplicada a seguinte sequência de passos:

![gabarito do filtro](https://github.com/user-attachments/assets/fdb7d5b8-11d0-4b10-967c-8383e030129c)

1. Escolher o **gabarito** do filtro, como mostrado na figura acima. Ou seja, escolher valores de $\omega_p$ (final da banda passante), $\omega_s$ (início da banda de rejeição), $A_{max}$ (máxima atenuação admitida na banda passante) e $A_{min}$ (mínima atenuação admitida na banda de rejeição);
2. Calcular **especificações** do filtro. Ou seja, calcular valores de $Q$ (fator de qualidade), $\omega_o$ (frequência de corte) e $n$ (ordem do filtro);
3. Tendo escolhido o filtro Butterworth, as especificações encontradas são utilizadas na equação e aplica o filtro no sinal de entrada.

### 2.1 Escolha do gabarito

Como o sinal completo já foi obtido, é possível filtrá-lo "manualmente", variando as frequências $\omega_p$ e $\omega_s$ até chegar na curva desejada. Para isso, o sinal no domínio do tempo é passado para o domínio da frequência utilizando a transformada de Fourier. Dessa forma é possível ver todas as componentes de frequência do sinal, e a partir disso escolher o valor aproximado de frequência de corte. O "corte" é feito zerando os valores do sinal cuja frequência é maior que a de corte, ao invés de tirá-los do conjunto de dados. Depois disso, é utilizada a transformada inversa de Fourier para voltar para o domínio do tempo e comparar o sinal original com o sinal filtrado. O código que implementa isso é o gabarito.mat, mostrado abaixo.

```matlab
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

t = (0:L-1)*T0; % Vetor de tempo
plot(t, acc);
hold on;
plot(t, filtered_signal(1:L),'LineWidth', 2); % Pegue apenas os L primeiros pontos do sinal
title('Sinal no Tempo');
xlabel('Tempo (s)');
ylabel('Amplitude');
grid;
```

Tendo escolhido o valor aproximado de frequência de corte $\omega=4Hz$, o resultado obtido é apresentado na figura abaixo.

![grafico gabarito](https://github.com/user-attachments/assets/c7022033-3d27-4cb5-93c3-3a0bcdd26c7d)

Tendo essa informação, foram escolhidos os parâmetros do filtro: (1) $\omega_p =1$; (2) $\omega_s =5$; (3) $A_{max} = 0,05 dB$; (4) $A_{min} = 4 dB$.

### 2.2 Cálculo dos parâmetros do filtro

Para encontrar as frequências de corte do filtro Butterworth low-pass, são utilizadas as seguintes fórmulas, retiradas do livro _Analog Filter Design_ de M. E. Van Valkenburg:

$$
\begin{align}
n &= \dfrac{log[(10^{\alpha_{min}/10}-1)/(10^{\alpha_{max}/10}-1)]}{2 log(\omega_s/\omega_p)} \\
\omega_o &= \dfrac{\omega_s}{(10^{\alpha_{min}/10}-1)^{1/2n}} \\ 
\omega_o &= \dfrac{\omega_p}{(10^{\alpha_{max}/10}-1)^{1/2n}} \\
Q&=\dfrac{1}{2 cos\Psi}
\end{align}
$$

O fator de qualidade utiliza um parâmetro extra, $\Psi$, que é o ângulo dos polos da função de transferência em relação ao eixo real negativo. A quantidade de polos do sistema é proporcional à ordem $n$ encontrada. Se $n$ é ímpar, tem um polo em $\Psi=0^\circ$e se $n$ é par, terão polos em $\Psi=\pm90^\circ/n$. Além disso, os polos estão separados por $\Psi=180^\circ/n$. Na figura abaixo estão mostradas as localizações dos polos para os primeiros valores de $n$.

![polos](https://github.com/user-attachments/assets/23c9d8c1-e690-4465-84cd-1d977589dadd)

O número de fatores de qualidade depende da ordem do filtro. Devido à estabilidade, são apenas escolhidos os polos do semi-plano esquerdo complexo. 

De acordo com o gabarito escolhido na seção anterior, os parâmetros são calculados com o código do arquivo Calculo_parametros_iniciais.mat, mostrado abaixo.

```matlab
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
```

Resultando em:

$$
\begin{align*}
    n &= 1,5135 =2 \text{ (arredonda para cima)} \\
    \omega_o &= 4,5091 
\end{align*}
$$

Como $n$ é par, terão polos apenas em $\Psi=\pm45^\circ$. Com isso o valor do fator de qualidade calculado é $Q=0,71$.

### 2.3 Cálculo da função de transferência

Com os valores de frequência de corte ($\omega_o$) e fator de qualidade ($Q$), é possível calcular a função de transferência utilizando a equação dada na introdução:

$$
\begin{equation*}
    H(s)=\frac{20,3320}{s^2+6,3509s+20,3320}
\end{equation*}
$$

A função de transferência é utilizada no Simulink, como mostrado na figura abaixo. 

![simulink](https://github.com/user-attachments/assets/70fbc1b0-f20b-4c39-b293-10faf5b26f5a)

O gráfico resultante fica assim:

![sinal filtrado](https://github.com/user-attachments/assets/89fc4044-15dd-4030-9a3e-6508d1cecca5)

#### Retirando o offset do sinal

Através da análise do gráfico filtrado, foi medido o off-set do sistema igual a $-0,6445$, conforme mostrado na figura abaixo.

![offset](https://github.com/user-attachments/assets/54ade20c-2799-43f5-a1c8-0af7a09db270)

E sua retirada é feita com:

```matlab
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
```

Com a aceleração filtrada por completo, podem ser determinados os valores de velocidade e deslocamento. Partindo da informação de que o carro iniciou a tomada de dados parado, a velocidade e deslocamento iniciais são zero. Como a velocidade é a integral da aceleração e o deslocamento é a integral da velocidade, a velocidade e deslocamento são determinadas no código exibido abaixo, do arquivo Calculo_parametros_iniciais. 

```matlab
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
```

Os resultados de aceleração, velocidade e deslocamento são:

![plot final](https://github.com/user-attachments/assets/a0f4fb20-d333-4e67-8921-52da4db7a0a3)

## 3. Transformação em filtro digital

O projeto do filtro digital pode ser feito através da discretização de um filtro analógico, ou pode ser projetado do zero, começando pelo gabarito do filtro já em tempo discreto. A discretização escolhida é feita no Matlab através da transformação bilinear, através da função \textit{c2d} com o método \textit{'tustin'}. O código utilizado, em cima do código do filtro analógico, está no arquivo digitalizacao.mat, e mostrado abaixo. 

```matlab
Ts=1/51200; % Período (incremento de tempo)
% Função de transferência contínua
s = tf('s');
H_cont = w_o1^2/(s^2+(w_o1/Q)*s+w_o1^2);

% Transformação bilinear (Tustin)
H_disc = c2d(H_cont, Ts, 'tustin');
% Simular a saída da função de transferência discreta
output_signal = lsim(H_disc, y, x);
% Remover o offset
output_signal_disc = output_signal - offset;
```

A comparação entre o filtro analógico e o filtro digital, aplicados no mesmo sinal do acelerômetro, é mostrada na figura abaixo.

![filtro digital](https://github.com/user-attachments/assets/25cf49df-b601-48a8-9f2a-7d8cce44c48b)

# Referências

[1] José Luiz da Silva Neto. Notas de aula de medidas elétricas e instrumentação, 2024. 
[2] M. E. Van Valkenburg. Analog Filter Design. Holt, Rinehart and Winston, New York, 1982.















