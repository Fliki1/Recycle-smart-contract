pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./Authorised.sol";

/*  @title Un contratto per gestire l'ammontare dei rifiuti riciclati
    @author
    @notice per il momento gestisce solo l'inserimento di nuovi bags
*/
contract Recycle is Authorised{
    
    event NewBagTransaction(string qrcode, string timestamp, string recyType);
    event DelBagTransaction(string qrcode, uint index, uint bags_lenght);
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

    // @dev mapping che parte da 1, lo 0 è usato per indicare 'qr code non presente'. L'indice corrispettivo in bags è -1
    mapping (string => uint256) private qrcodeToBag;

    // @notice Struttura della smart bag
    // @qrcode la stringa corrispondente a un QR code: Numeric digits (0-9) Uppercase letters (A-Z) Lowercase letters (a-z)
    // @timestamp parametro che salva la data di consegna bags formato: dd/mm/yyyy (vale la pena anche se la transazione riporta il suo timestamp?)
    // @time timestamp in riferimento in Time Units di secondi
    // @recyType glass/paper/plastic/metal
    struct SmartBag {
      string qrcode;
      string timestamp; 
      uint32 time;
      string recyType;
    }
    
    // @dev other contracts would then be able to read from, but not write to, this array. So this is a useful pattern for storing public data in your contract
    SmartBag[] public bags;

    // @notice Inserimento di una nuova smart bag
    // @parameter _qrcode: il qrcode
    // @parameter _timestamp: la timestamp
    // @parameter _recyType: il tipo di recycle
    function _createBag(string memory _qrcode, string memory _timestamp, string memory _recyType) internal {
        bags.push(SmartBag(_qrcode, _timestamp, uint32(now), _recyType));
        qrcodeToBag[_qrcode] = bags.length;
        emit NewBagTransaction(_qrcode, _timestamp, _recyType);
    }
    
    // @notice genera una smart bag
    // @parameter _qrcode: il qrcode scannerizzato
    // @parameter _timestamp: timestamp
    // @parameter _recyType: il tipo di recycle
    function generateBag(string memory _qrcode, string memory _timestamp, string memory _recyType) public onlyAuthorised(msg.sender){
        _createBag(_qrcode, _timestamp, _recyType);
    }
    
    // @notice Ritorna il numero di bags generati fino ad ora (universali)
    function queryBagsLength() external view onlyOwner returns (uint) {
        return bags.length;
    }
    
    // @notice controllo bag a partire dal qrcode ---usando il mapping
    // @parameter qrcheck: qrcode di cui si vuole sapere i suoi riferimenti
    // @return gli elementi che compongono la sua smart bag
    function checkBagByQR_MAP(string calldata qrcheck) external view onlyAuthorised(msg.sender) returns (string memory, string memory, uint32, string memory) {
        require (qrcodeToBag[qrcheck] != 0, 'Il qrcode non è stato trattato');
        uint i = qrcodeToBag[qrcheck] -1;
        return (bags[i].qrcode, bags[i].timestamp, bags[i].time, bags[i].recyType);
    }


    // @notice cancelliamo il bag di riferimento
    // @parameter qrcode: qrcode
    // @dev visto il costo di questa operazione sarebbe meglio farlo compiere solo dall'owner previa segnalazione
    function deleteBag(string calldata qrcode) external onlyOwner {
        require (qrcodeToBag[qrcode] != 0, 'Il qrcode non è stato trattato');

        uint index = qrcodeToBag[qrcode] -1;
        emit DelBagTransaction(bags[index].qrcode, qrcodeToBag[qrcode], index);

        if(bags.length != 1){ // se presente più di un bags
            qrcodeToBag[bags[bags.length-1].qrcode] = qrcodeToBag[bags[index].qrcode];
            bags[index] = bags[bags.length-1];
        }
        bags.pop();
        delete qrcodeToBag[qrcode];
    }

    // @dev funzione che ritorna tutti gli smartbags presenti (sarebbe meglio gestirlo diversamente in base ai casi: connect your contract with Web3(JS) or truffle console (test locali))
    function getAllBags() view external onlyOwner returns(SmartBag[] memory) {
        return bags;
    }


    // @notice distruzione del contratto
    // @dev solo l'owner può, farò un modifier apposito
    function destroy() external onlyOwner{
        selfdestruct(msg.sender);    // si distrugge il contratto e si mandano gli ether suo presenti all'address del suo creatore (payable format)
    }

    // @notice solo l'owner può depositarvi ether all'interno
    function deposit() external payable onlyOwner {
        emit Deposit(msg.sender, msg.value);
    }

    // @notice ritorna quanti ether sono presenti nel contratto
    // @dev public e non external per essere invocato anche dal withdraw che ne fa un controllo nell'ether pool
    function balanceOf() public view onlyOwner returns(uint){
        return address(this).balance;
    }

    // @notice fornisce gli ether presenti nel contract all'owner
    // @parameter withdra_amount ether che si vuole ritirare dallo smart contract
    function withdraw(uint withdraw_amount) external onlyOwner {
        // Limit withdrawal amount
        require(withdraw_amount <= balanceOf(), 'Insufficient balance for withdrawal request');
        msg.sender.transfer(withdraw_amount); // dallo smart contract a msg.sender == owner
        emit Withdrawal(msg.sender, withdraw_amount);
    }
    
    // @notice accetto ether solo dall'owner
    // @dev mi permette di istanziare Ether già dal suo deploy
    receive () external payable onlyOwner {}

}