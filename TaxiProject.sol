// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Taxi_Project{
    
    struct TaxiDriver{
        address payable driverId;
        uint salary;
        uint drvBalance;
        uint approvalState;
        uint salaryTime;
    }
    struct Participant{
        address payable prtpId;
        uint prtpBalance;
        bool isApprovedPurchase;
        bool isApprovedDriver;
    }
    struct Car{
        uint32 carId;
        uint price;
        uint validDate;
        uint approvalState;
    }

    address payable public owner;
    address payable public carDealer;

   
    mapping (address => Participant) participants;
    address payable[] public participantArr;

    TaxiDriver public driver;
    TaxiDriver public propDriver;
    Car public ownedCar;
    Car public propCar;
    
    uint public balance;
    uint public lastCarExpenseDate;
    uint lastDividentDate;
    
    uint fixExpense;
    uint fee;

    modifier isParticipant(){
        require(participants[msg.sender].prtpId == msg.sender, "Caller is not a participant");
        _;
    }
    modifier isCarDealer(){
        require(carDealer == msg.sender, "Caller is not a Car Dealer");
        _;
    }
    modifier isDriver(){
        require(driver.driverId == msg.sender, "Caller is not a driver");
        _;
    }

    constructor() payable{
        owner = msg.sender;
        balance = 0;
        fixExpense = 10 ether;
        fee = 100 ether;
        lastCarExpenseDate = 0;
        lastDividentDate = 0;
    }

    function Join() external payable{
        require(msg.value == fee, "You should send 100 ETH");
        require(participantArr.length < 9, "There is no place in the contract");
        require(participants[msg.sender].prtpId != msg.sender, "You already joined before");
        balance += fee;
        participantArr.push(msg.sender);
        participants[msg.sender] = Participant({prtpId: msg.sender, prtpBalance:0 ether, isApprovedPurchase:false, isApprovedDriver: false});
        uint total = msg.value - fee;
        if(total>0) msg.sender.transfer(total);
    }

    function CarProposeToBusiness(uint32 pCarId, uint pPrice, uint pValidDate) public isCarDealer(){
        propCar = Car({carId: pCarId, price: pPrice, validDate: pValidDate, approvalState:0});
        for(uint i=0; i<participantArr.length; i++) {
            participants[participantArr[i]].isApprovedPurchase = false;
        }
    }

    function ApprovePurchaseCar() public isParticipant(){
        require(participants[msg.sender].isApprovedPurchase == false, "Each participant can approve once");
        propCar.approvalState+=1;
        participants[msg.sender].isApprovedPurchase = true;
        if(propCar.approvalState > participantArr.length/2) PurchaseCar();

    }

    function PurchaseCar() public{
        require(balance >= propCar.price, "Balance is not enough for this car");
        require(block.timestamp <= propCar.validDate, "Validation date is expired");
        require(propCar.approvalState > participantArr.length/2, "There are not enough votes");
        balance -= propCar.price;
        if(!carDealer.send(propCar.price)){
            balance += propCar.price;
            revert();
        }
        ownedCar = Car({carId: propCar.carId, price: propCar.price, validDate: propCar.validDate, approvalState:0});
        lastCarExpenseDate = block.timestamp;
        for(uint i=0; i<participantArr.length; i++) {
            participants[participantArr[i]].isApprovedPurchase = false;
        }
        propCar = Car({carId: 0, price: 0, validDate: 0, approvalState:0});
    }

    function RepurchaseCarPropose(uint32 pCarId, uint pPrice, uint pValidDate) public isCarDealer(){
        propCar = Car({carId: pCarId, price: pPrice, validDate: pValidDate, approvalState: 0});
        for(uint i=0; i<participantArr.length; i++) {
            participants[participantArr[i]].isApprovedPurchase = false;
        }
    }

    function ApproveSellProposal() public isParticipant(){
        require(participants[msg.sender].isApprovedPurchase == false, "Each participant can approve once");
        propCar.approvalState+=1;
        participants[msg.sender].isApprovedPurchase = true;
        if(propCar.approvalState > participantArr.length/2) RepurchaseCar();
    }

    function RepurchaseCar() public{
        require(balance >= propCar.price, "Balance is not enough for this car");
        require(block.timestamp <= propCar.validDate, "Validation date is expired");
        require(propCar.approvalState > participantArr.length/2, "There are not enough votes");
        balance += ownedCar.price;
        balance -= propCar.price;
        if(!carDealer.send(propCar.price)){
            balance += propCar.price;
            balance -=ownedCar.price;
            revert();
        }
        ownedCar = Car({carId: propCar.carId, price: propCar.price, validDate: propCar.validDate, approvalState:0});
        lastCarExpenseDate = block.timestamp;
        for(uint i=0; i<participantArr.length; i++) {
            participants[participantArr[i]].isApprovedPurchase = false;
        }
        propCar = Car({carId: 0, price: 0, validDate: 0, approvalState:0});
    }

    function ProposeDriver(address payable id, uint expSalary) public{
        propDriver = TaxiDriver({driverId: id, salary: expSalary, drvBalance: 0, approvalState: 0, salaryTime: 0});
        for(uint i=0; i<participantArr.length; i++){
            participants[participantArr[i]].isApprovedDriver = false;
        }
    }

    function ApproveDriver() public isParticipant(){
        require(participants[msg.sender].isApprovedDriver == false, "Each participant can approve once");
        propDriver.approvalState += 1;
        participants[msg.sender].isApprovedDriver = true;
        if(propDriver.approvalState > participantArr.length/2) SetDriver();
    }

    function SetDriver() public{
        require(propDriver.driverId != address(0), "Anyone proposed any driver");
        require(propDriver.approvalState > participantArr.length/2, "There are not enough votes");
        driver = TaxiDriver({driverId: propDriver.driverId, salary: propDriver.salary, drvBalance: 0, approvalState:0, salaryTime: 0});
        for(uint i=0; i<participantArr.length; i++){
            participants[participantArr[i]].isApprovedDriver = false;
        }
        propDriver = TaxiDriver({driverId: address(0), salary: 0, drvBalance: 0, approvalState: 0, salaryTime: 0});
    }

    function ProposeFireDriver() public isParticipant(){
        participants[msg.sender].isApprovedDriver = true;
        driver.approvalState += 1;
        if(driver.approvalState > participantArr.length/2) FireDriver();
    }

    function FireDriver() public{
        require(driver.approvalState > participantArr.length/2, "There are not enough votes");
        driver.drvBalance += driver.salary;
        balance -= driver.salary;
        driver = TaxiDriver({driverId: address(0), salary: 0, drvBalance: 0, approvalState: 0, salaryTime: 0});
        for(uint i=0; i<participantArr.length; i++){
            participants[participantArr[i]].isApprovedDriver = false;
        }
    }

    function LeaveJob() public isDriver(){
        driver = TaxiDriver({driverId: address(0), salary: 0, drvBalance: 0, approvalState: 0, salaryTime: 0});
        for(uint i=0; i<participantArr.length; i++){
            participants[participantArr[i]].isApprovedDriver = false;
        }
    }

    function GetCharge() payable public{
        balance += msg.value;
    }

    function GetSalary() public isDriver(){
        require(driver.driverId != address(0), "There is no driver at the moment");
        require(block.timestamp >= (driver.salaryTime + 30 days), "Driver got his salary this month");
        require(balance >= driver.salary, "Balance is not enough for paying the driver's salary");
        driver.drvBalance += driver.salary;
        balance -= driver.salary;
        driver.salaryTime = block.timestamp;
    }

    function CarExpenses() public isParticipant(){
        require(block.timestamp >= lastCarExpenseDate + 180 days, "Car has fixed within 6 months");
        require(balance >= fixExpense, "You have no enough money");
        balance -= fixExpense;
        if(!carDealer.send(fixExpense)){
            balance += fixExpense;
            revert();
        }
        lastCarExpenseDate = block.timestamp;
    }

    function PayDivident() public isParticipant(){
        require(block.timestamp >= lastDividentDate + 180 days, "You have already splitted the total money in last 6 months");
        GetSalary();
        CarExpenses();
        uint shareout = balance / participantArr.length;
        for(uint i=0; i<participantArr.length; i++){
            participants[participantArr[i]].prtpBalance += shareout;
        }
        lastDividentDate = block.timestamp;
        balance = 0;
    }

    fallback() external{
        revert();
    }
}