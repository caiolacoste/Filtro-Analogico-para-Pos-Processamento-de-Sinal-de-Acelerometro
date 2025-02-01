# Filtro-Analogico-para-Pos-Processamento-de-Sinal-de-Acelerometro

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




















