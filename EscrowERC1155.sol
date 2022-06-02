//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.8;
import "./interfaces.sol";

contract EscrowERC1155 is ERC1155TokenReceiver {
    Escrow[] escrows;

    struct Escrow {
        address nftOwner;
        address nftContract;
        uint nftID;
        uint nftAmount;
        address tokenRecieve;
        uint weiRecieve;
    }
    
    //require users to own enough nfts, and add an escrow to the list
    function createEscrow(address _nftContract, uint _nftID, uint _nftAmount, address _tokenRecieve, uint _weiRecieve) public {
        require(ERC1155(_nftContract).balanceOf(msg.sender, _nftID) >= _nftAmount, "You don't own enough of this nft");
        escrows.push(Escrow(msg.sender, _nftContract, _nftID, _nftAmount, _tokenRecieve, _weiRecieve));
        // (frontend) allow nft to contract
    }

    //require user owns the escrow, remove from list
    function removeEscrow(uint i) public {
        require(msg.sender == escrows[i].nftOwner);
        escrows[i] = escrows[escrows.length-1];
        escrows.pop();
        // (frontend) disallow nft to contract
    }

    //require user has enough tokens for payment, transfer nft from seller to contract, allow contract to recieve nft, transfer nft to buyer, transfer tokens to seller, remove escrow from list
    function executeEscrow(uint i) public {
        require(ERC20(escrows[i].tokenRecieve).balanceOf(msg.sender) >= escrows[i].weiRecieve, "Cannot afford nft");
        ERC1155(escrows[i].nftContract).safeTransferFrom(escrows[i].nftOwner, address(this), escrows[i].nftID, escrows[i].nftAmount, "");
        this.onERC1155Received(msg.sender, escrows[i].nftOwner, escrows[i].nftID, escrows[i].nftAmount, "");
        ERC1155(escrows[i].nftContract).safeTransferFrom(address(this), msg.sender, escrows[i].nftID, escrows[i].nftAmount, "");
        ERC20(escrows[i].tokenRecieve).transferFrom(msg.sender, escrows[i].nftOwner, escrows[i].weiRecieve);
        escrows[i] = escrows[escrows.length-1];
        escrows.pop();
        // (frontend) allow tokens to nftOwner
    }

    function getEscrow(uint i) public view returns (Escrow memory) {
        return escrows[i];
    }

    //view msg.sender's escrow list indexes
    function getMyEscrowIndexes() public view returns (uint[] memory) {
        uint count;
        for(uint i; i < escrows.length; i++){
            if(msg.sender == escrows[i].nftOwner) {
                count++;
            }
        }
        uint[] memory escrowIndexes = new uint[](count);
        uint j;
        for(uint i; i < escrows.length; i++){
            if(msg.sender == escrows[i].nftOwner) {
                escrowIndexes[j] = i;
                j++;
            }
            if (j==count) {break;}
        }
        return escrowIndexes;
    }

    // (standard) allow contract to recieve ERC1155
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
        )
        external pure override returns(bytes4) {
            return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    // (standard) unused function, fail on purpose
    function onERC1155BatchReceived(
            address operator,
            address from,
            uint256[] calldata ids,
            uint256[] calldata values,
            bytes calldata data
            )
            external pure override returns(bytes4) {
                return this.onERC1155BatchReceived.selector;
    }
    
}
