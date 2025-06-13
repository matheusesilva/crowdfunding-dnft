🚀 Plataforma de Crowdfunding Descentralizada com NFTs e Votação

Uma plataforma de crowdfunding descentralizada onde doadores recebem NFTs intransferíveis baseados em raridade e votam na alocação de fundos em rodadas, promovendo transparência e engajamento.

Este projeto apresenta um contrato inteligente robusto para uma plataforma de crowdfunding totalmente descentralizada, combinando doações com a emissão de NFTs intransferíveis e um sistema de governança por votação para a alocação de fundos.
✨ Recursos Principais

    NFTs Intransferíveis como Comprovante de Doação:

        Doadores recebem um NFT exclusivo ao fazer uma doação mínima, servindo como um distintivo de participação e engajamento.

        Estes NFTs são desenhados para serem intransferíveis, garantindo que o comprovante de doação permaneça ligado ao endereço original.

    Sistema de Níveis para Doadores:

        Os doadores são categorizados em níveis (Bronze, Prata, Ouro) com base no valor total doado e na frequência de suas contribuições, incentivando o engajamento contínuo.

    Mecanismo de Rodadas de Financiamento e Votação:

        A plataforma opera em rodadas de financiamento, onde os fundos são arrecadados e as propostas de utilização são criadas.

        Os detentores de NFTs podem votar nas propostas para decidir como os fundos arrecadados serão distribuídos.

        A distribuição de fundos é proporcional ao número de votos que cada proposta recebe.

    Gerenciamento de Camisas (NFTs):

        Capacidade de cadastrar diferentes "camisas" (representações visuais ou temáticas para os NFTs) com raridades variadas (Comum, Média, Rara).

        A raridade da camisa doada é sorteada aleatoriamente no momento da cunhagem do NFT.

    Transparência e Imutabilidade:

        Construído sobre a blockchain, todas as doações, votos e distribuições de fundos são registrados de forma transparente e imutável.

    Uso de Token ERC-20 (BRZ):

        As doações e a alocação de fundos são realizadas utilizando um token ERC-20 específico (simulado como MockBRZ para testes).

    Funções Controladas pelo Proprietário:

        O proprietário do contrato possui controle sobre funções administrativas, como o cadastro de novas camisas, a criação de propostas e o encerramento das rodadas.

🛠️ Tecnologias Utilizadas

    Solidity: Linguagem de programação para contratos inteligentes na Ethereum Virtual Machine (EVM).

    OpenZeppelin Contracts: Bibliotecas seguras e testadas para padrões de token (ERC-721) e controle de acesso (Ownable2Step).

    Foundry (Forge & Cast): Conjunto de ferramentas de desenvolvimento para contratos Solidity, utilizado para compilação, teste e interação com o contrato.

🚀 Como Executar o Projeto (Desenvolvimento)

Para configurar e testar o projeto localmente, siga os passos abaixo:

    Clone o Repositório:

    git clone <URL_DO_SEU_REPOSITORIO>
    cd <NOME_DO_SEU_REPOSITORIO>

    Instale o Foundry:
    Se você ainda não tem o Foundry, instale-o seguindo as instruções em Foundry Book.

    Instale as Dependências (se aplicável):

        Se você tiver um package.json para OpenZeppelin ou outras bibliotecas JS/TS:

        npm install
        # Ou yarn install

        Certifique-se de que seu foundry.toml está configurado corretamente para encontrar as dependências do OpenZeppelin (geralmente libs = ["node_modules", "lib"]).

    Compile os Contratos:

    forge build

    Execute os Testes:

    forge test

🛣️ Próximos Passos e Melhorias Potenciais

    Interface de Usuário (Frontend): Desenvolver uma aplicação web (usando frameworks como React, Vue ou Next.js) para permitir que os usuários interajam com o contrato de forma intuitiva.

    Oráculo de Aleatoriedade Verificável: Para ambientes de produção, integrar um serviço como Chainlink VRF para a geração de NFTs, garantindo uma aleatoriedade segura e auditável.

    Sistema de Propostas Avançado: Implementar funcionalidades mais complexas para as propostas, como votação ponderada, diferentes requisitos de quórum ou múltiplos tipos de propostas.

    Visualização de NFTs: Integrar com sistemas de armazenamento descentralizado como IPFS para armazenar metadados e imagens dos NFTs, permitindo sua visualização em plataformas de mercado.
