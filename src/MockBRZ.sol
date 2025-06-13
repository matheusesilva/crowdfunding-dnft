// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Contrato Mock para o token BRZ, utilizado para testes.
contract MockBRZ is ERC20 {
    constructor() ERC20("BRZ Token", "BRZ") {
        // Minta uma quantidade inicial de tokens para o deployer.
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /**
     * @dev Cunha tokens para um destinatário específico, apenas para testes.
     * @param destinatario O endereço para o qual os tokens serão cunhados.
     * @param quantidade A quantidade de tokens a ser cunhada.
     */
    function mint(address destinatario, uint256 quantidade) external {
        _mint(destinatario, quantidade);
    }
}
