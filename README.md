# 🦖 T-Rex Runner em FPGA

Implementação de uma versão do jogo **T-Rex Runner**, conhecido pelo jogo offline do Google Chrome, utilizando **Verilog HDL** e uma placa FPGA. O projeto apresenta os elementos gráficos por meio de uma saída VGA e reproduz as principais mecânicas do jogo original.

## Sobre o projeto

O objetivo deste projeto é desenvolver um jogo interativo em hardware, aplicando conceitos de Sistemas Digitais, como máquinas de estados finitos, contadores, circuitos sequenciais e geração de sinais de vídeo.

O jogador controla um dinossauro que precisa desviar de obstáculos durante a partida. Para isso, pode realizar saltos utilizando os botões físicos da placa FPGA.

A imagem do jogo é gerada diretamente pela lógica descrita em Verilog, utilizando a interface VGA para exibição em um monitor.

## Funcionalidades

- **Máquina de estados finitos (FSM):** controle das etapas do jogo.
- **Movimentação do personagem:** dinossauro com mecanismo de salto.
- **Obstáculos:** presença de cactos e pássaros.
- **Detecção de colisão:** identificação do contato entre o dinossauro e os obstáculos.
- **Game Over:** encerramento da partida após uma colisão.
- **Pontuação:** acompanhamento dos pontos durante a partida.
- **Recorde:** armazenamento da maior pontuação alcançada durante a execução.
- **Modo diurno e noturno:** alternância entre diferentes aparências visuais.
- **Saída VGA:** geração da imagem com resolução de 640 × 480 pixels.

## Tecnologias e ferramentas

| Tecnologia | Utilização |
|---|---|
| Verilog HDL | Descrição da lógica digital do jogo |
| Quartus | Compilação e programação da FPGA |
| FPGA DE1 | Execução do circuito digital |
| VGA | Exibição dos elementos gráficos |
| Clock de 50 MHz | Clock de entrada da placa |

## Estrutura do repositório

```text
Trex/
│
├── bdf/
│   └── Arquivos relacionados aos diagramas e projetos
│
├── img/
│   └── Imagens utilizadas no projeto
│
├── v/
│   └── Arquivos de código Verilog
│
└── README.md
```

## Funcionamento do jogo

O funcionamento é organizado por uma máquina de estados finitos, responsável por controlar as diferentes situações da partida:

| Estado | Descrição |
|---|---|
| IDLE | Estado inicial do jogo |
| RUN | Execução normal da partida |
| JUMP | Realização do salto do dinossauro |
| DEAD | Encerramento após uma colisão |

Durante a execução, os obstáculos se deslocam horizontalmente em direção ao personagem. O jogador deve utilizar o comando de salto para evitar o contato com eles.

A posição dos elementos é atualizada pela lógica do jogo, enquanto o circuito VGA determina quais pixels devem ser apresentados no monitor.

## Controles

Os botões físicos da placa FPGA são utilizados para controlar a partida:

| Entrada | Função |
|---|---|
| KEY[0] | Reset do sistema |
| KEY[1] | Comando de salto |

O tratamento das entradas considera o acionamento dos botões e utiliza debounce para evitar múltiplos comandos causados por oscilações elétricas.

## Como executar

Para executar o projeto na FPGA:

1. Clone ou baixe este repositório:

   ```bash
   git clone https://github.com/yaralima08/Trex.git
   ```

2. Abra o projeto no **Quartus**.

3. Verifique as configurações do dispositivo FPGA e as atribuições dos pinos de acordo com a placa utilizada.

4. Compile o projeto para gerar o arquivo de programação.

5. Conecte a placa FPGA ao computador e ao monitor VGA.

6. Utilize o **Programmer** do Quartus para carregar o arquivo gerado na placa.

7. Após a programação, utilize os botões físicos para iniciar e controlar o jogo.

## Resultado

O projeto apresenta o jogo T-Rex Runner executando na FPGA, com geração gráfica pela saída VGA, movimentação dos obstáculos, mecanismo de salto, pontuação, alternância entre os modos visuais e detecção de colisões.

## Autoras

**Kailayni Rodrigues Janez** — RA: 824751  
**Yara Vieira de Lima** — RA: 824341

Universidade Federal de São Carlos (UFSCar)  
Departamento de Computação  
Disciplina: Sistemas Digitais  
Professor: Prof. Dr. Emerson Carlos Pedrino  
Ano: 2026

---
**Link do video funcionando:** https://drive.google.com/file/d/1HhL5t2uC-VIXDlqn1fzCsSK6q49o-dbw/view?usp=drive_link
**Repositório:** [github.com/yaralima08/Trex](https://github.com/yaralima08/Trex)
