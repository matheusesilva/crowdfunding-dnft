// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {ContratoPrincipal} from "../src/ContratoPrincipal.sol"; // Importa o contrato principal.
import {MockBRZ} from "../src/MockBRZ.sol"; // Importa o mock do token BRZ.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Importa a interface ERC20.
import "@openzeppelin/contracts/access/Ownable.sol";

// Contrato de testes abrangente para o ContratoPrincipal.
contract ContratoPrincipalTest is Test {
    ContratoPrincipal public contrato; // Instância do contrato principal a ser testado.
    MockBRZ public brz; // Instância do token BRZ mock para simulações.

    address public deployer = makeAddr("deployer"); // Endereço usado para implantar o contrato.
    address public alice = makeAddr("alice");     // Primeiro endereço de teste para usuários.
    address public bob = makeAddr("bob");         // Segundo endereço de teste para usuários.
    address public charlie = makeAddr("charlie"); // Terceiro endereço de teste para usuários.
    address public destino1 = makeAddr("destino1"); // Endereço para destino de fundos.
    address public destino2 = makeAddr("destino2"); // Outro endereço para destino de fundos.


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

        // Configuração inicial das camisas para que os testes de mint não falhem.
        contrato.cadastrarCamisa("Camisa Comum 1", ContratoPrincipal.Raridade.Comum);
        contrato.cadastrarCamisa("Camisa Media 1", ContratoPrincipal.Raridade.Media);
        contrato.cadastrarCamisa("Camisa Rara 1", ContratoPrincipal.Raridade.Rara);

        vm.stopPrank(); // Para a sessão do deployer.
    }

    // Testa se o contrato principal foi implantado corretamente e com os parâmetros iniciais.
    function testContratoPrincipalImplantado() public view {
        assertEq(address(contrato) != address(0), true, "ContratoPrincipal nao foi implantado");
        assertEq(contrato.precoMinimo(), PRECO_MINIMO, "Preco minimo incorreto");
        assertEq(contrato.duracaoPrimeiraRodada(), DURACAO_PRIMEIRA_RODADA, "Duracao da primeira rodada incorreta");
        assertEq(contrato.owner(), deployer, "Proprietario do contrato incorreto");
        assertEq(contrato.rodadaAtual(), 1, "Rodada inicial incorreta");

        // Acessando o campo 'fim' da tupla retornada pelo getter público.
        (, uint256 fimRodada1, , , , ) = contrato.rodadas(1);
        assertGt(fimRodada1, block.timestamp, "Fim da rodada inicial incorreto");
    }

    // Testa a cunhagem de um NFT com sucesso e a doação associada.
    function testMintComSucesso() public {
        vm.startPrank(alice);
        brz.mint(alice, 20 ether);
        brz.approve(address(contrato), 20 ether);
        contrato.mint(15 ether);

        assertEq(contrato.balanceOf(alice), 1, "Alice deve ter 1 NFT");
        assertEq(contrato.ownerOf(1), alice, "Alice nao e dona do NFT de ID 1");
        assertEq(brz.balanceOf(address(contrato)), 15 ether, "BRZ nao transferido para o contrato");
        assertEq(contrato.donoToTokenId(alice), 1, "Mapeamento donoToTokenId incorreto");

        // Verifica os dados de doação e camisa do NFT.
        (string memory nomeCamisa,,, uint256 totalDoado, uint256 qtdDoacoes,) = contrato.dadosCompletos(alice);
        assertNotEq(bytes(nomeCamisa).length, 0, "Nome da camisa vazio");
        assertEq(totalDoado, 15 ether, "Total doado incorreto na mintagem");
        assertEq(qtdDoacoes, 1, "Quantidade de doacoes incorreta na mintagem");

        vm.stopPrank();
    }

    // Testa a tentativa de cunhagem com valor insuficiente.
    function testMintComValorInsuficienteReverte() public {
        vm.startPrank(alice);
        brz.mint(alice, 5 ether);
        brz.approve(address(contrato), 5 ether);

        vm.expectRevert("Valor insuficiente para mintagem");
        contrato.mint(5 ether);

        vm.stopPrank();
    }

    // Testa a tentativa de cunhagem por um endereço que já possui um NFT.
    function testMintComEnderecoJaPossuiNFTReverte() public {
        vm.startPrank(alice);
        brz.mint(alice, 20 ether);
        brz.approve(address(contrato), 20 ether);
        contrato.mint(15 ether);

        vm.expectRevert("Endereco ja possui NFT");
        contrato.mint(15 ether);

        vm.stopPrank();
    }

    // Testa se a função `doar` funciona corretamente.
    function testDoarComSucesso() public {
        vm.startPrank(alice);
        brz.mint(alice, 20 ether);
        brz.approve(address(contrato), 20 ether);
        contrato.mint(15 ether);

        brz.mint(alice, 10 ether);
        brz.approve(address(contrato), 10 ether);
        contrato.doar(5 ether);

        assertEq(brz.balanceOf(address(contrato)), 20 ether, "BRZ nao transferido corretamente apos doacao");
        (,,, uint256 totalDoado, uint256 qtdDoacoes,) = contrato.dadosCompletos(alice);
        assertEq(totalDoado, 20 ether, "Total doado incorreto apos doacao");
        assertEq(qtdDoacoes, 2, "Quantidade de doacoes incorreta apos doacao");
        vm.stopPrank();
    }

    // Testa a tentativa de doação por um endereço sem NFT.
    function testDoarSemNFTReverte() public {
        vm.startPrank(bob);
        brz.mint(bob, 10 ether);
        brz.approve(address(contrato), 10 ether);

        vm.expectRevert("Voce nao possui NFT para doar");
        contrato.doar(5 ether);

        vm.stopPrank();
    }

    // Testa a função `cadastrarCamisa` (apenas para o proprietário).
    function testCadastrarCamisaApenasOwner() public {
        vm.startPrank(deployer);
        // Já cadastrado no setUp, mas testando a função diretamente aqui.
        contrato.cadastrarCamisa("Nova Camisa Teste", ContratoPrincipal.Raridade.Media);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );

        contrato.cadastrarCamisa("Camisa Comum Teste", ContratoPrincipal.Raridade.Comum);
        vm.stopPrank();
    }

    // Testa o cálculo do nível do usuário com diferentes cenários de doação.
    function testNivelDoUsuario() public {
        vm.startPrank(alice);
        brz.mint(alice, 10 ether);
        brz.approve(address(contrato), 10 ether);
        contrato.mint(10 ether);

        assertEq(contrato.nivelDoUsuario(alice), "Bronze", "Nivel incorreto para doacao inicial");

        vm.warp(block.timestamp + 61 days);
        assertEq(contrato.nivelDoUsuario(alice), "Bronze", "Nivel incorreto para doacao antiga");

        brz.mint(alice, 100 ether);
        brz.approve(address(contrato), 100 ether);
        contrato.doar(100 ether);

        assertEq(contrato.nivelDoUsuario(alice), "Prata", "Nivel incorreto para doacao recente e media");

        brz.mint(alice, 150 ether);
        brz.approve(address(contrato), 150 ether);
        contrato.doar(150 ether);

        assertEq(contrato.nivelDoUsuario(alice), "Prata", "Nivel incorreto para doacao recente e media-alta");

        brz.mint(alice, 500 ether);
        brz.approve(address(contrato), 500 ether);
        contrato.doar(500 ether);

        assertEq(contrato.nivelDoUsuario(alice), "Ouro", "Nivel incorreto para doacao recente e alta");

        vm.stopPrank();
    }

    // Testa a criação de propostas e o processo de votação.
    function testCriarEBotarEmProposta() public {
        // Setup base para propostas e votos.
        vm.startPrank(alice);
        brz.mint(alice, PRECO_MINIMO);
        brz.approve(address(contrato), PRECO_MINIMO);
        contrato.mint(PRECO_MINIMO);
        vm.stopPrank();

        vm.startPrank(bob);
        brz.mint(bob, PRECO_MINIMO);
        brz.approve(address(contrato), PRECO_MINIMO);
        contrato.mint(PRECO_MINIMO);
        vm.stopPrank();

        vm.startPrank(deployer);
        contrato.criarProposta("Proposta de teste 1", destino1);
        contrato.criarProposta("Proposta de teste 2", destino2);
        vm.stopPrank();

        vm.startPrank(alice);
        contrato.votar(0);
        vm.stopPrank();

        vm.startPrank(bob);
        contrato.votar(0);
        vm.stopPrank();

        // Verifica os votos.
        (,, uint256 votos0) = contrato.obterProposta(contrato.rodadaAtual(), 0);
        assertEq(votos0, 2, "Proposta 0 deve ter 2 votos");
        (,, uint256 votos1) = contrato.obterProposta(contrato.rodadaAtual(), 1);
        assertEq(votos1, 0, "Proposta 1 deve ter 0 votos");

        vm.startPrank(alice);
        vm.expectRevert("Endereco ja votou nesta rodada");
        contrato.votar(1);
        vm.stopPrank();
    }

    // Testa o cenário de encerramento da rodada sem votos.
    function testEncerrarRodadaSemVotosReverte() public {
        vm.startPrank(alice);
        brz.mint(alice, PRECO_MINIMO);
        brz.approve(address(contrato), PRECO_MINIMO);
        contrato.mint(PRECO_MINIMO);
        vm.stopPrank();

        vm.startPrank(deployer);
        vm.warp(block.timestamp + DURACAO_PRIMEIRA_RODADA + 1);
        vm.expectRevert("Nenhum voto registrado para distribuir fundos");
        contrato.encerrarRodada();
        vm.stopPrank();
    }

    // Testa o cenário de tentativa de encerramento da rodada antes do tempo.
    function testEncerrarRodadaAntesDoTempoReverte() public {
        vm.startPrank(deployer);
        vm.expectRevert("Rodada ainda ativa");
        contrato.encerrarRodada();
        vm.stopPrank();
    }

    // NOVO TESTE: Testa a distribuição de fundos e início da próxima rodada após setup completo.
    function testEncerrarRodadaEDistribuirFundos() public {
        // Setup: Mint, Doações, Criação de Propostas e Votos.
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

        vm.startPrank(deployer);
        contrato.criarProposta("Projeto Alpha", destino1); // Proposta 0
        contrato.criarProposta("Projeto Beta", destino2);  // Proposta 1
        vm.stopPrank();

        vm.startPrank(alice);
        contrato.votar(0); // Alice vota na proposta 0.
        vm.stopPrank();

        vm.startPrank(bob);
        contrato.votar(0); // Bob vota na proposta 0.
        vm.stopPrank();

        vm.startPrank(charlie);
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

        // Cálculos esperados:
        uint256 currentTotalArrecadado = contrato.getTotalArrecadado(); // Pega o valor real arrecadado no contrato (após o encerramento)
        ( , , , uint256 currentTotalVotosRodada, , ) = contrato.rodadas(1); // Pega os votos da rodada encerrada (rodada 1)

        vm.startPrank(deployer);
        vm.warp(block.timestamp + DURACAO_PRIMEIRA_RODADA + 1); // Avança o tempo para encerrar a rodada.
        contrato.encerrarRodada(); // Encerra a rodada e distribui.
        vm.stopPrank();

        uint256 expectedPart0 = (2 * currentTotalArrecadado) / currentTotalVotosRodada;
        uint256 expectedPart1 = (1 * currentTotalArrecadado) / currentTotalVotosRodada;

        assertEq(brz.balanceOf(destino1), balancoDestino1Antes + expectedPart0, "Fundos para destino1 incorretos");
        assertEq(brz.balanceOf(destino2), balancoDestino2Antes + expectedPart1, "Fundos para destino2 incorretos");

        // Verifica que o contrato transferiu o total arrecadado.
        assertEq(brz.balanceOf(address(contrato)), balancoContratoAntes - expectedPart0 - expectedPart1, "BRZ remanescente no contrato incorreto");

        // Verifica se uma nova rodada foi iniciada.
        ( , uint256 fimRodada2, , , , ) = contrato.rodadas(2);
        assertEq(contrato.rodadaAtual(), 2, "Nova rodada nao iniciada");
        assertGt(fimRodada2, block.timestamp, "Fim da nova rodada incorreto");
    }
}

