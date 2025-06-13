// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {ContratoPrincipal} from "../src/ContratoPrincipal.sol"; // Importa o contrato principal.
import {MockBRZ} from "../src/MockBRZ.sol"; // Importa o mock do token BRZ.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Importa a interface ERC20.

// Contrato de testes abrangente para o ContratoPrincipal.
contract ContratoPrincipalTest is Test {
    ContratoPrincipal public contrato; // Instância do contrato principal a ser testado.
    MockBRZ public brz; // Instância do token BRZ mock para simulações.

    address public deployer = makeAddr("deployer"); // Endereço usado para implantar o contrato.
    address public alice = makeAddr("alice");     // Primeiro endereço de teste para usuários.
    address public bob = makeAddr("bob");         // Segundo endereço de teste para usuários.
    address public charlie = makeAddr("charlie"); // Terceiro endereço de teste para usuários.

    uint256 public constant PRECO_MINIMO = 10 ether;         // Valor mínimo de doação para cunhar um NFT.
    uint256 public constant DURACAO_PRIMEIRA_RODADA = 365 days; // Duração inicial da primeira rodada.

    // Configuração inicial para cada teste.
    function setUp() public {
        deal(deployer, 10 ether); // Financia o deployer com ether para taxas de gás.
        vm.startPrank(deployer); // Inicia a sessão como o deployer.

        brz = new MockBRZ(); // Implanta o contrato MockBRZ.

        // Implanta o ContratoPrincipal com o token BRZ mock e parâmetros iniciais.
        contrato = new ContratoPrincipal(
            address(brz),
            PRECO_MINIMO,
            DURACAO_PRIMEIRA_RODADA
        );
        vm.stopPrank(); // Para a sessão do deployer.
    }

    // Testa se o contrato principal foi implantado corretamente e com os parâmetros iniciais.
    function testContratoPrincipalImplantado() public view {
        assertEq(address(contrato) != address(0), true, "ContratoPrincipal nao foi implantado");
        assertEq(contrato.precoMinimo(), PRECO_MINIMO, "Preco minimo incorreto");
        assertEq(contrato.duracaoPrimeiraRodada(), DURACAO_PRIMEIRA_RODADA, "Duracao da primeira rodada incorreta");
        assertEq(contrato.owner(), deployer, "Proprietario do contrato incorreto");
        assertEq(contrato.rodadaAtual(), 1, "Rodada inicial incorreta");
        assertGt(contrato.rodadas(1).fim(), block.timestamp, "Fim da rodada inicial incorreto");
    }

    // Testa a cunhagem de um NFT com sucesso e a doação associada.
    function testMintComSucesso() public {
        vm.startPrank(alice); // Inicia sessão como Alice.
        brz.mint(alice, 20 ether); // Minta 20 BRZ para Alice.
        brz.approve(address(contrato), 20 ether); // Alice aprova o contrato para gastar BRZ.

        contrato.mint(15 ether); // Alice cunha um NFT com 15 BRZ.

        assertEq(contrato.balanceOf(alice), 1, "Alice deve ter 1 NFT"); // Verifica balanço de NFT.
        assertEq(contrato.ownerOf(1), alice, "Alice nao e dona do NFT de ID 1"); // Verifica posse do NFT.
        assertEq(brz.balanceOf(address(contrato)), 15 ether, "BRZ nao transferido para o contrato"); // Verifica balanço de BRZ do contrato.
        assertEq(contrato.donoToTokenId(alice), 1, "Mapeamento donoToTokenId incorreto"); // Verifica mapeamento doador-tokenID.

        // Verifica os dados de doação e camisa do NFT.
        (string memory nomeCamisa, string memory nivel, uint8 raridade, uint256 totalDoado, uint256 qtdDoacoes, uint256 ultimaDoacao) = contrato.dadosCompletos(alice);
        assertNotEq(bytes(nomeCamisa).length, 0, "Nome da camisa vazio");
        assertEq(totalDoado, 15 ether, "Total doado incorreto na mintagem");
        assertEq(qtdDoacoes, 1, "Quantidade de doacoes incorreta na mintagem");
        assertNotEq(ultimaDoacao, 0, "Ultima doacao nao registrada");

        vm.stopPrank(); // Para a sessão de Alice.
    }

    // Testa a tentativa de cunhagem com valor insuficiente.
    function testMintComValorInsuficienteReverte() public {
        vm.startPrank(alice); // Inicia sessão como Alice.
        brz.mint(alice, 5 ether); // Minta 5 BRZ (menos que o mínimo).
        brz.approve(address(contrato), 5 ether); // Alice aprova o gasto.

        vm.expectRevert("Valor insuficiente para mintagem"); // Espera que a transação reverta.
        contrato.mint(5 ether); // Tenta cunhar com 5 BRZ.

        vm.stopPrank(); // Para a sessão de Alice.
    }

    // Testa a tentativa de cunhagem por um endereço que já possui um NFT.
    function testMintComEnderecoJaPossuiNFTReverte() public {
        vm.startPrank(alice); // Inicia sessão como Alice.
        brz.mint(alice, 20 ether);
        brz.approve(address(contrato), 20 ether);
        contrato.mint(15 ether); // Alice cunha seu primeiro NFT.

        vm.expectRevert("Endereco ja possui NFT"); // Espera que a transação reverta.
        contrato.mint(15 ether); // Alice tenta cunhar um segundo NFT.

        vm.stopPrank(); // Para a sessão de Alice.
    }

    // Testa se a função `doar` funciona corretamente.
    function testDoarComSucesso() public {
        vm.startPrank(alice); // Inicia sessão como Alice.
        brz.mint(alice, 20 ether);
        brz.approve(address(contrato), 20 ether);
        contrato.mint(15 ether); // Mintagem inicial para Alice.

        brz.mint(alice, 10 ether); // Minta mais BRZ para Alice para a doação.
        brz.approve(address(contrato), 10 ether);
        contrato.doar(5 ether); // Alice doa mais 5 BRZ.

        assertEq(brz.balanceOf(address(contrato)), 20 ether, "BRZ nao transferido corretamente apos doacao"); // Verifica balanço do contrato.
        (,,,,,uint256 totalDoado, uint256 qtdDoacoes,) = contrato.dadosCompletos(alice);
        assertEq(totalDoado, 20 ether, "Total doado incorreto apos doacao"); // Verifica total doado por Alice.
        assertEq(qtdDoacoes, 2, "Quantidade de doacoes incorreta apos doacao"); // Verifica quantidade de doações.
        vm.stopPrank(); // Para a sessão de Alice.
    }

    // Testa a tentativa de doação por um endereço sem NFT.
    function testDoarSemNFTReverte() public {
        vm.startPrank(bob); // Inicia sessão como Bob (sem NFT).
        brz.mint(bob, 10 ether);
        brz.approve(address(contrato), 10 ether);

        vm.expectRevert("Voce nao possui NFT para doar"); // Espera que a transação reverta.
        contrato.doar(5 ether); // Bob tenta doar.

        vm.stopPrank(); // Para a sessão de Bob.
    }

    // Testa a função `cadastrarCamisa` (apenas para o proprietário).
    function testCadastrarCamisaApenasOwner() public {
        vm.startPrank(deployer); // Inicia sessão como deployer (proprietário).
        contrato.cadastrarCamisa("Camisa Rara Teste", ContratoPrincipal.Raridade.Rara); // Cadastra uma camisa.
        vm.stopPrank();

        // Tenta cadastrar por um não-proprietário.
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner"); // Espera que reverta.
        contrato.cadastrarCamisa("Camisa Comum Teste", ContratoPrincipal.Raridade.Comum);
        vm.stopPrank();
    }

    // Testa o cálculo do nível do usuário com diferentes cenários de doação.
    function testNivelDoUsuario() public {
        vm.startPrank(alice); // Inicia sessão como Alice.
        brz.mint(alice, 10 ether);
        brz.approve(address(contrato), 10 ether);
        contrato.mint(10 ether); // Doa 10 BRZ.

        assertEq(contrato.nivelDoUsuario(alice), "Bronze", "Nivel incorreto para doacao inicial"); // Deve ser Bronze.

        vm.warp(block.timestamp + 61 days); // Avança o tempo (mais de 60 dias).
        assertEq(contrato.nivelDoUsuario(alice), "Bronze", "Nivel incorreto para doacao antiga"); // Deve ser Bronze devido ao tempo.

        brz.mint(alice, 100 ether);
        brz.approve(address(contrato), 100 ether);
        contrato.doar(100 ether); // Doa 100 BRZ (total 110 BRZ, média 55 BRZ).

        // A média é 55 ether, tempo recente (0 dias). Deve ser Prata.
        assertEq(contrato.nivelDoUsuario(alice), "Prata", "Nivel incorreto para doacao recente e media"); // Verifica nível Prata.

        brz.mint(alice, 150 ether);
        brz.approve(address(contrato), 150 ether);
        contrato.doar(150 ether); // Doa 150 BRZ (total 260 BRZ, média ~86 BRZ).

        // A média é ~86 ether, tempo recente. Deve ser Prata (não atinge 100 ether).
        assertEq(contrato.nivelDoUsuario(alice), "Prata", "Nivel incorreto para doacao recente e media-alta");

        brz.mint(alice, 500 ether);
        brz.approve(address(contrato), 500 ether);
        contrato.doar(500 ether); // Doa 500 BRZ (total 760 BRZ, média 190 BRZ).

        // A média é 190 ether, tempo recente (0 dias). Deve ser Ouro.
        assertEq(contrato.nivelDoUsuario(alice), "Ouro", "Nivel incorreto para doacao recente e alta"); // Verifica nível Ouro.

        vm.stopPrank(); // Para a sessão de Alice.
    }

    // Testa a criação de propostas e o processo de votação.
    function testCriarEBotarEmProposta() public {
        // Preparação: mintagem para Alice e Bob para que possam votar.
        vm.startPrank(alice);
        brz.mint(alice, 10 ether);
        brz.approve(address(contrato), 10 ether);
        contrato.mint(10 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        brz.mint(bob, 10 ether);
        brz.approve(address(contrato), 10 ether);
        contrato.mint(10 ether);
        vm.stopPrank();

        // Criar proposta (apenas owner).
        vm.startPrank(deployer);
        // Precisamos cadastrar camisas para que a função _gerarCamisaAleatoria não reverta se a lista for vazia.
        contrato.cadastrarCamisa("Camisa Comum 1", ContratoPrincipal.Raridade.Comum);
        contrato.cadastrarCamisa("Camisa Media 1", ContratoPrincipal.Raridade.Media);
        contrato.cadastrarCamisa("Camisa Rara 1", ContratoPrincipal.Raridade.Rara);

        contrato.criarProposta("Proposta de teste 1", makeAddr("destino1")); // Cria proposta 0.
        contrato.criarProposta("Proposta de teste 2", makeAddr("destino2")); // Cria proposta 1.
        vm.stopPrank();

        // Votar nas propostas.
        vm.startPrank(alice);
        contrato.votar(0); // Alice vota na proposta 0.
        vm.stopPrank();

        vm.startPrank(bob);
        contrato.votar(0); // Bob vota na proposta 0.
        vm.stopPrank();

        // Verifica os votos.
        (string memory desc0, address dest0, uint256 votos0) = contrato.obterProposta(contrato.rodadaAtual(), 0);
        assertEq(votos0, 2, "Proposta 0 deve ter 2 votos");
        (string memory desc1, address dest1, uint256 votos1) = contrato.obterProposta(contrato.rodadaAtual(), 1);
        assertEq(votos1, 0, "Proposta 1 deve ter 0 votos");

        // Tenta votar novamente na mesma rodada.
        vm.startPrank(alice);
        vm.expectRevert("Endereco ja votou nesta rodada");
        contrato.votar(1);
        vm.stopPrank();
    }

    // Testa o encerramento da rodada e a distribuição de fundos.
    function testEncerrarRodadaEDistribuirFundos() public {
        address destino1 = makeAddr("destino1");
        address destino2 = makeAddr("destino2");

        // Preparação: Minta NFTs e faça doações para que haja fundos.
        vm.startPrank(alice);
        brz.mint(alice, 50 ether);
        brz.approve(address(contrato), 50 ether);
        contrato.mint(20 ether); // Alice doa 20.
        contrato.doar(30 ether); // Alice doa mais 30. Total 50.
        vm.stopPrank();

        vm.startPrank(bob);
        brz.mint(bob, 20 ether);
        brz.approve(address(contrato), 20 ether);
        contrato.mint(20 ether); // Bob doa 20.
        vm.stopPrank();

        assertEq(contrato.getTotalArrecadado(), 70 ether, "Total arrecadado incorreto antes da distribuicao");

        // Criar propostas.
        vm.startPrank(deployer);
        contrato.cadastrarCamisa("Camisa Comum", ContratoPrincipal.Raridade.Comum); // Garante que a lista não está vazia
        contrato.criarProposta("Projeto Alpha", destino1); // Proposta 0
        contrato.criarProposta("Projeto Beta", destino2);  // Proposta 1
        vm.stopPrank();

        // Votar.
        vm.startPrank(alice);
        contrato.votar(0); // Alice vota na proposta 0.
        vm.stopPrank();

        vm.startPrank(bob);
        contrato.votar(0); // Bob vota na proposta 0.
        vm.stopPrank();

        vm.startPrank(charlie); // Charlie também tem NFT, mas não vou dar BRZ, apenas para votar.
        brz.mint(charlie, PRECO_MINIMO);
        brz.approve(address(contrato), PRECO_MINIMO);
        contrato.mint(PRECO_MINIMO);
        contrato.votar(1); // Charlie vota na proposta 1.
        vm.stopPrank();


        // Proposta 0: 2 votos
        // Proposta 1: 1 voto
        // Total de votos: 3
        // Total arrecadado: 70 ether

        // Balanço inicial dos destinos.
        uint256 balancoDestino1Antes = brz.balanceOf(destino1);
        uint256 balancoDestino2Antes = brz.balanceOf(destino2);
        uint256 balancoContratoAntes = brz.balanceOf(address(contrato));

        vm.startPrank(deployer);
        vm.warp(block.timestamp + DURACAO_PRIMEIRA_RODADA + 1); // Avança o tempo para encerrar a rodada.
        contrato.encerrarRodada(); // Encerra a rodada e distribui.
        vm.stopPrank();

        // Cálculos esperados:
        // Proposta 0: (2 votos / 3 votos) * 70 ether = 46.666... ether
        // Proposta 1: (1 voto / 3 votos) * 70 ether = 23.333... ether
        // Note: Solidity lida com inteiros, então haverá truncamento.
        uint256 expectedPart0 = (2 * 70 ether) / 3; // Approx 46666666666666666666
        uint256 expectedPart1 = (1 * 70 ether) / 3; // Approx 23333333333333333333

        assertEq(brz.balanceOf(destino1), balancoDestino1Antes + expectedPart0, "Fundos para destino1 incorretos");
        assertEq(brz.balanceOf(destino2), balancoDestino2Antes + expectedPart1, "Fundos para destino2 incorretos");

        // Verifica que o contrato transferiu o total arrecadado.
        assertEq(brz.balanceOf(address(contrato)), balancoContratoAntes - expectedPart0 - expectedPart1, "BRZ remanescente no contrato incorreto");

        // Verifica se uma nova rodada foi iniciada.
        assertEq(contrato.rodadaAtual(), 2, "Nova rodada nao iniciada");
        assertGt(contrato.rodadas(2).fim(), block.timestamp, "Fim da nova rodada incorreto");
    }

    // Testa o encerramento da rodada sem votos.
    function testEncerrarRodadaSemVotosReverte() public {
        vm.startPrank(alice); // Alice faz doação.
        brz.mint(alice, PRECO_MINIMO);
        brz.approve(address(contrato), PRECO_MINIMO);
        contrato.mint(PRECO_MINIMO);
        vm.stopPrank();

        vm.startPrank(deployer); // Deployer tenta encerrar a rodada sem votos.
        vm.warp(block.timestamp + DURACAO_PRIMEIRA_RODADA + 1); // Avança o tempo.
        vm.expectRevert("Nenhum voto registrado para distribuir fundos"); // Espera que reverta.
        contrato.encerrarRodada();
        vm.stopPrank();
    }

    // Testa a tentativa de encerrar a rodada antes do tempo.
    function testEncerrarRodadaAntesDoTempoReverte() public {
        vm.startPrank(deployer); // Deployer tenta encerrar a rodada cedo.
        vm.expectRevert("Rodada ainda ativa"); // Espera que reverta.
        contrato.encerrarRodada();
        vm.stopPrank();
    }
}

