# 🚀 Plataforma de Crowdfunding Descentralizada com NFTs e Votação

Uma plataforma de crowdfunding descentralizada onde doadores recebem NFTs intransferíveis baseados em raridade e votam na alocação de fundos em rodadas, promovendo transparência e engajamento.

Este projeto apresenta um contrato inteligente robusto para uma plataforma de crowdfunding totalmente descentralizada, combinando doações com a emissão de NFTs intransferíveis e um sistema de governança por votação para a alocação de fundos.

---

## ✨ Recursos Principais

### 🏅 NFTs Intransferíveis como Comprovante de Doação

- Doadores recebem um NFT exclusivo ao fazer uma doação mínima, servindo como um distintivo de participação e engajamento.
- Estes NFTs são desenhados para serem intransferíveis, garantindo que o comprovante de doação permaneça ligado ao endereço original.

### 🧱 Sistema de Níveis para Doadores

- Os doadores são categorizados em níveis (Bronze, Prata, Ouro) com base no valor total doado e na frequência de suas contribuições, incentivando o engajamento contínuo.

### 📊 Mecanismo de Rodadas de Financiamento e Votação

- A plataforma opera em rodadas de financiamento, onde os fundos são arrecadados e as propostas de utilização são criadas.
- Os detentores de NFTs podem votar nas propostas para decidir como os fundos arrecadados serão distribuídos.
- A distribuição de fundos é proporcional ao número de votos que cada proposta recebe.

### 👕 Gerenciamento de Camisas (NFTs)

- Capacidade de cadastrar diferentes "camisas" (representações visuais ou temáticas para os NFTs) com raridades variadas: Comum, Média e Rara.
- A raridade da camisa doada é sorteada aleatoriamente no momento da cunhagem do NFT.

### 🔍 Transparência e Imutabilidade

- Construído sobre a blockchain, todas as doações, votos e distribuições de fundos são registrados de forma transparente e imutável.

### 💰 Uso de Token ERC-20 (BRZ)

- As doações e a alocação de fundos são realizadas utilizando um token ERC-20 específico (simulado como `MockBRZ` para testes).

### 🔐 Funções Controladas pelo Proprietário

- O proprietário do contrato possui controle sobre funções administrativas, como o cadastro de novas camisas, a criação de propostas e o encerramento das rodadas.

---

## 🛠️ Tecnologias Utilizadas

- **Solidity**: Linguagem de programação para contratos inteligentes na Ethereum Virtual Machine (EVM).
- **OpenZeppelin Contracts**: Bibliotecas seguras e testadas para padrões de token (ERC-721) e controle de acesso (`Ownable2Step`).
- **Foundry (Forge & Cast)**: Conjunto de ferramentas de desenvolvimento para contratos Solidity, utilizado para compilação, teste e interação com o contrato.

---

## 🚀 Como Executar o Projeto (Desenvolvimento)

Siga os passos abaixo para configurar e testar o projeto localmente:

### 1. Clone o Repositório

```bash
git clone https://github.com/matheusesilva/crowdfunding-dnft.git
cd crowdfunding-dnft
