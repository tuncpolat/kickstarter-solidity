pragma solidity ^0.4.17; // specify solidity version - old version


contract CampaignFactory {
    address[] public deployedCampaigns;
    
    function createCampaign(uint minimum) public {
        address newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }
    
    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    
    struct Request {
        string description; // why the request is being created
        uint value; // amount of money that the manager wants to send to vendor
        address recipient; // address that the money will be sent to
        bool complete; // true if the request has already been processed (money sent)
        uint approvalCount; // track number of approvals
        mapping(address => bool) approvals; // track who has voted (reference type)
    }
    
    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function Campaign(uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }
    
    function contribute() public payable {
        require(msg.value > minimumContribution);
        approvers[msg.sender] = true; // add contributer to approvers mapping (Object)
        approversCount++; // increase count
    }
    
    function createRequest(string description, uint value, address recipient) public restricted {
        // initalize value types (not necessary to init reference types)
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });
        
        // same as Request newRequest = Request(description, value, recipient, false, 0)
        
        requests.push(newRequest);
    }
    
    function approveRequest(uint index) public {
        
        Request storage request = requests[index]; // simplify life
        
        require(approvers[msg.sender]); // check if user contributed to campaign (contract) 
        require(!request.approvals[msg.sender]); // check if user has not already approved/disapproved/voted on the request yet
    
        request.approvals[msg.sender] = true; // add sender to approvals
        request.approvalCount++; // increment approvalCount
        
    }
    
    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];
        require(request.approvalCount > (approversCount / 2)); // request must at least get 50% of the votes
        require(!request.complete); // check if request is not already been completed
        request.recipient.transfer(request.value); // send money predefined in request to the recipient 
        request.complete = true;
    }
}