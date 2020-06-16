pragma solidity >=0.5.11;


import "./Authorised.sol";

/*  @title Un contratto per gestire l'ammontare dei rifiuti riciclati
    @author
    @notice per il momento gestisce solo l'inserimento di nuovi bags
*/
contract Recycle is Authorised{
    
    event NewBagTransaction(string qrcode, string timestamp, string recyType);
    event  DelBagTransaction(string qrcode, uint index, uint bags_lenght);

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
        //ownerZombieCount[msg.sender]++;
    }
    
    // @notice genera una smart bag
    // @parameter _qrcode: il qrcode scannerizzato
    // @parameter _timestamp: timestamp
    // @parameter _recyType: il tipo di recycle
    function generateBag(string memory _qrcode, string memory _timestamp, string memory _recyType) public onlyAuthorised(msg.sender){
        // require che l'address sia di quelli a me consoni
        //require(ownerZombieCount[msg.sender] == 0);
        //uint randDna = _generateRandomDna(_name);
        //randDna = randDna - randDna % 100;
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

        if(bags.length == 1){ // se presente un solo elemento in bags
            bags.pop();
        }
        else{
            qrcodeToBag[bags[bags.length-1].qrcode] = qrcodeToBag[bags[index].qrcode];
            bags[index] = bags[bags.length-1];
            bags.pop();
        }
        delete qrcodeToBag[qrcode];
    }


    // @notice distruzione del contratto
    // @dev solo l'owner può, farò un modifier apposito
    function destroy() public onlyOwner{
        selfdestruct(msg.sender);    // si distrugge il contratto e si mandano gli ether suo presenti all'address del suo creatore (payable format)
    }
    
    // @notice accetto ether dall'esterno in ogni modo
    receive () external payable {}

}