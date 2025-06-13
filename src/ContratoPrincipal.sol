// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ContratoPrincipal is ERC721, Ownable2Step {
    // ===========================================
    // Eventos do Contrato
    // ===========================================
    event NFCMinted(uint256 indexed tokenId, address indexed owner, uint256 donationValue); // Emitido ao cunhar um novo NFT.
    event DonationMade(uint256 indexed tokenId, address indexed donor, uint256 donationValue); // Emitido a cada nova doação.
    event ShirtRegistered(string name, uint8 raridade); // Emitido ao cadastrar uma camisa.
    event RoundStarted(uint256 indexed idRodada, uint256 inicio, uint256 fim); // Emitido ao iniciar uma rodada.
    event ProposalCreated(uint256 indexed idRodada, uint256 indexed idProposta, string descricao, address destinatario); // Emitido ao criar uma proposta.
    event VoteRegistered(uint256 indexed idRodada, uint256 indexed idProposta, address votante); // Emitido ao registrar um voto.
    event RoundEnded(uint256 indexed idRodada, uint256 totalArrecadado, uint256 totalVotos); // Emitido ao encerrar uma rodada.
    event FundsDistributed(uint256 indexed idRodada, uint256 indexed idProposta, address indexed destinatario, uint256 amount); // Emitido ao distribuir fundos.


    // ===========================================
    // Lógica de Camisas
    // ===========================================

    enum Raridade { Comum, Media, Rara } // Níveis de raridade das camisas.

    struct Camisa { // Representa uma camisa NFT.
        string nome;
        uint8 raridade;
    }

    mapping(Raridade => string[]) private internasCamisas; // Camisas cadastradas por raridade.

    function _cadastrarCamisa(string memory nome, Raridade raridade) internal {
        internasCamisas[raridade].push(nome); // Adiciona uma camisa ao registro.
    }

    function _removerCamisa(uint256 indice, Raridade raridade) internal {
        require(indice < internasCamisas[raridade].length, "Indice invalido");
        uint256 ultima = internasCamisas[raridade].length - 1;
        internasCamisas[raridade][indice] = internasCamisas[raridade][ultima];
        internasCamisas[raridade].pop(); // Remove uma camisa existente.
    }

    function _gerarCamisaAleatoria(address para) internal view returns (Camisa memory) {
        require(block.number > 0, "Geracao de aleatorio requer block.number > 0");
        // Gera aleatoriamente uma camisa baseada em probabilidades (10% Rara, 30% Média, 60% Comum).
        // ATENÇÃO: blockhash não é totalmente imprevisível em PoW.
        uint256 aleatorio = uint256(
            keccak256(abi.encodePacked(para, block.timestamp, blockhash(block.number - 1)))
        ) % 100;

        if (aleatorio < 10 && internasCamisas[Raridade.Rara].length > 0) {
            return Camisa({nome: internasCamisas[Raridade.Rara][aleatorio % internasCamisas[Raridade.Rara].length], raridade: uint8(Raridade.Rara)});
        } else if (aleatorio < 40 && internasCamisas[Raridade.Media].length > 0) {
            return Camisa({nome: internasCamisas[Raridade.Media][aleatorio % internasCamisas[Raridade.Media].length], raridade: uint8(Raridade.Media)});
        } else {
            require(internasCamisas[Raridade.Comum].length > 0, "Nenhuma camisa comum disponivel.");
            return Camisa({nome: internasCamisas[Raridade.Comum][aleatorio % internasCamisas[Raridade.Comum].length], raridade: uint8(Raridade.Comum)});
        }
    }

    function _listarCamisas(Raridade raridade) internal view returns (string[] memory) {
        return internasCamisas[raridade]; // Retorna a lista de camisas por raridade.
    }


    // ===========================================
    // Lógica de Doações
    // ===========================================

    struct DadosDoacao { // Armazena o histórico de doações de um usuário.
        uint256 totalDoado;
        uint256 quantidadeDoacoes;
        uint256 ultimaDoacao;
    }

    function _registrarDoacao(DadosDoacao storage dados, uint256 valor) internal {
        dados.totalDoado += valor;
        dados.quantidadeDoacoes++;
        dados.ultimaDoacao = block.timestamp; // Atualiza o histórico de doações.
    }

    function _calcularMedia(DadosDoacao memory dados) internal pure returns (uint256) {
        if (dados.quantidadeDoacoes == 0) return 0;
        return dados.totalDoado / dados.quantidadeDoacoes; // Calcula a média das doações.
    }


    // ===========================================
    // Lógica de Níveis (Baseada em Doações)
    // ===========================================

    function _calculaNivel(DadosDoacao memory dados) internal view returns (string memory) {
        if (dados.quantidadeDoacoes == 0 || dados.ultimaDoacao == 0) return "Bronze";

        uint256 media = _calcularMedia(dados);
        uint256 tempoDesdeUltimaDoacao = block.timestamp - dados.ultimaDoacao;

        // Define o nível do doador (Ouro, Prata, Bronze) com base em doações e tempo.
        if (media >= 100 ether && tempoDesdeUltimaDoacao <= 30 days) {
            return "Ouro";
        } else if (media >= 50 ether && tempoDesdeUltimaDoacao <= 60 days) {
            return "Prata";
        } else {
            return "Bronze";
        }
    }


    // ===========================================
    // Lógica de Rodadas de Votação e Distribuição
    // ===========================================

    struct Proposta { // Representa uma proposta de distribuição de fundos.
        string descricao;
        address destinatario;
        uint256 votos;
        bool executada; // Evita dupla distribuição.
    }

    struct Rodada { // Representa uma rodada de arrecadação e votação.
        uint256 inicio;
        uint256 fim;
        bool encerrada;
        uint256 totalVotos;
        uint256 totalArrecadado;
        uint256 quantidadePropostas;
        mapping(uint256 => Proposta) propostas;
        mapping(address => bool) votou; // Controla votos por endereço.
    }

    mapping(uint256 => Rodada) public rodadas; // Mapeamento de ID da rodada para dados.
    uint256 public rodadaAtual; // ID da rodada ativa.

    function _iniciarPrimeiraRodada(uint256 duracao) internal {
        rodadaAtual = 1;
        Rodada storage r = rodadas[rodadaAtual];
        r.inicio = block.timestamp;
        r.fim = block.timestamp + duracao;
        emit RoundStarted(rodadaAtual, r.inicio, r.fim); // Inicia a primeira rodada.
    }

    function _adicionarArrecadacao(uint256 valor) internal {
        Rodada storage r = rodadas[rodadaAtual];
        require(block.timestamp < r.fim, "Rodada encerrada para arrecadacao");
        r.totalArrecadado += valor; // Adiciona valor à arrecadação da rodada.
    }

    function _criarProposta(string memory descricao, address destinatario) internal onlyOwner {
        Rodada storage r = rodadas[rodadaAtual];
        require(block.timestamp < r.fim, "Rodada encerrada para propostas");
        uint256 newProposalId = r.quantidadePropostas++;
        r.propostas[newProposalId] = Proposta({descricao: descricao, destinatario: destinatario, votos: 0, executada: false});
        emit ProposalCreated(rodadaAtual, newProposalId, descricao, destinatario); // Cria uma nova proposta.
    }

    function _registrarVoto(address votante, uint256 idProposta) internal {
        Rodada storage r = rodadas[rodadaAtual];
        require(block.timestamp < r.fim, "Rodada encerrada para votacao");
        require(!r.votou[votante], "Endereco ja votou nesta rodada");
        require(idProposta < r.quantidadePropostas, "Proposta invalida");

        r.propostas[idProposta].votos++;
        r.totalVotos++;
        r.votou[votante] = true;
        emit VoteRegistered(rodadaAtual, idProposta, votante); // Registra um voto.
    }

    function _encerrarRodadaAtual() internal onlyOwner {
        Rodada storage r = rodadas[rodadaAtual];
        require(block.timestamp >= r.fim, "Rodada ainda ativa");
        require(!r.encerrada, "Rodada ja encerrada");

        r.encerrada = true;
        emit RoundEnded(rodadaAtual, r.totalArrecadado, r.totalVotos); // Encerra a rodada atual.
    }

    function _iniciarNovaRodada(uint256 duracaoAnterior) internal {
        rodadaAtual++;
        Rodada storage r = rodadas[rodadaAtual];
        r.inicio = block.timestamp;
        uint256 newDuration = duracaoAnterior > 0 ? duracaoAnterior : 365 days;
        r.fim = block.timestamp + newDuration;
        emit RoundStarted(rodadaAtual, r.inicio, r.fim); // Inicia uma nova rodada.
    }

    function obterProposta(uint256 idRodada, uint256 idProposta) public view returns (string memory descricao, address destinatario, uint256 votos) {
        Rodada storage r = rodadas[idRodada];
        require(idProposta < r.quantidadePropostas, "Proposta invalida");
        Proposta storage p = r.propostas[idProposta];
        return (p.descricao, p.destinatario, p.votos); // Retorna detalhes de uma proposta.
    }

    function obterQuantidadePropostas(uint256 idRodada) public view returns (uint256) {
        return rodadas[idRodada].quantidadePropostas; // Retorna a quantidade de propostas em uma rodada.
    }

    function jaVotou(uint256 idRodada, address votante) public view returns (bool) {
        return rodadas[idRodada].votou[votante]; // Verifica se um endereço já votou.
    }


    // ===========================================
    // Variáveis de Estado do Contrato Principal
    // ===========================================
    IERC20 public tokenBRZ;
    uint256 public precoMinimo;
    uint256 public contadorIds;
    uint256 public duracaoPrimeiraRodada;

    mapping(address => uint256) public donoToTokenId; // Mapeia doador para ID do NFT.
    mapping(uint256 => Camisa) public dadosCamisas; // Mapeia ID do NFT para dados da camisa.
    mapping(uint256 => DadosDoacao) public historicoDoacoes; // Mapeia ID do NFT para histórico de doações.


    // ===========================================
    // Construtor
    // ===========================================
    constructor(
        address _tokenBRZ,
        uint256 _precoMinimo,
        uint256 _duracaoPrimeiraRodada
    )
        ERC721("CamisaNFT", "CNFT")
        Ownable(msg.sender)
    {
        tokenBRZ = IERC20(_tokenBRZ);
        precoMinimo = _precoMinimo;
        duracaoPrimeiraRodada = _duracaoPrimeiraRodada;
        _iniciarPrimeiraRodada(_duracaoPrimeiraRodada); // Inicializa a primeira rodada.
    }


    // ===========================================
    // Lógica NFT Intransferível (_update) - OpenZeppelin 5.1.0+
    // ===========================================

    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        // Previne transferências entre endereços não-zero. Cunhagem e queima permitidas.
        if (from != address(0) && to != address(0) && from != to) {
            revert(unicode"NFT intransferivel");
        }
        return super._update(to, tokenId, auth); // Chama a função `_update` do contrato pai.
    }


    // ===========================================
    // Funções Públicas do Contrato Principal
    // ===========================================

    function mint(uint256 valor) external {
        require(donoToTokenId[msg.sender] == 0, "Endereco ja possui NFT");
        require(valor >= precoMinimo, "Valor insuficiente para mintagem");

        require(tokenBRZ.transferFrom(msg.sender, address(this), valor), "Transferencia BRZ falhou");

        contadorIds++;
        uint256 novoId = contadorIds;

        Camisa memory camisaSorteada = _gerarCamisaAleatoria(msg.sender);
        dadosCamisas[novoId] = camisaSorteada;

        _safeMint(msg.sender, novoId);
        donoToTokenId[msg.sender] = novoId;

        _registrarDoacao(historicoDoacoes[novoId], valor);
        _adicionarArrecadacao(valor);
        emit NFCMinted(novoId, msg.sender, valor); // Cunha novo NFT e registra doação.
    }

    function doar(uint256 valor) external {
        uint256 tokenId = donoToTokenId[msg.sender];
        require(tokenId != 0, "Voce nao possui NFT para doar");

        require(tokenBRZ.transferFrom(msg.sender, address(this), valor), "Transferencia BRZ falhou");

        _registrarDoacao(historicoDoacoes[tokenId], valor);
        _adicionarArrecadacao(valor);
        emit DonationMade(tokenId, msg.sender, valor); // Realiza uma doação adicional.
    }

    function cadastrarCamisa(string memory nome, Raridade raridade) external onlyOwner {
        _cadastrarCamisa(nome, raridade);
        emit ShirtRegistered(nome, uint8(raridade)); // Cadastra uma nova camisa.
    }

    function criarProposta(string memory descricao, address destinatario) external onlyOwner {
        _criarProposta(descricao, destinatario); // Cria uma nova proposta.
    }

    function votar(uint256 idProposta) external {
        uint256 tokenId = donoToTokenId[msg.sender];
        require(tokenId != 0, "Voce nao possui NFT para votar");

        _registrarVoto(msg.sender, idProposta); // Permite votar em uma proposta.
    }

    function encerrarRodada() external onlyOwner {
        _encerrarRodadaAtual();

        Rodada storage r = rodadas[rodadaAtual];
        require(r.totalVotos > 0, "Nenhum voto registrado para distribuir fundos");

        for (uint256 i = 0; i < r.quantidadePropostas; i++) {
            Proposta storage p = r.propostas[i];
            if (!p.executada) {
                uint256 parte = (p.votos * r.totalArrecadado) / r.totalVotos;
                if (parte > 0) {
                    require(tokenBRZ.transfer(p.destinatario, parte), "Falha ao transferir fundos para a proposta");
                    p.executada = true;
                    emit FundsDistributed(rodadaAtual, i, p.destinatario, parte); // Distribui fundos para propostas.
                }
            }
        }
        _iniciarNovaRodada(r.fim - r.inicio); // Encerra a rodada e inicia uma nova.
    }

    function nivelDoUsuario(address usuario) external view returns (string memory) {
        uint256 tokenId = donoToTokenId[usuario];
        if (tokenId == 0) return "Sem NFT";
        return _calculaNivel(historicoDoacoes[tokenId]); // Retorna o nível de doação do usuário.
    }

    function dadosCompletos(address usuario) external view returns (
        string memory nomeCamisa, string memory nivel, uint8 raridade,
        uint256 totalDoado, uint256 qtdDoacoes, uint256 ultimaDoacao
    ) {
        uint256 tokenId = donoToTokenId[usuario];
        require(tokenId != 0, "Usuario nao possui NFT");

        Camisa memory c = dadosCamisas[tokenId];
        DadosDoacao memory d = historicoDoacoes[tokenId];

        return (c.nome, _calculaNivel(d), c.raridade, d.totalDoado, d.quantidadeDoacoes, d.ultimaDoacao); // Retorna todos os dados do usuário.
    }

    function getTotalArrecadado() public view returns (uint256) {
        return rodadas[rodadaAtual].totalArrecadado; // Retorna o total arrecadado na rodada atual.
    }
}


