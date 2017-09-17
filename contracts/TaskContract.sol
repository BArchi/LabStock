pragma solidity ^0.4.0;

import "./owned.sol";
import "./mortal.sol";


contract TaskContract is owned, mortal
{
    struct Commitment
    {
        bool isCreated;
        uint availableHours;
        uint committedHours;
        uint approvedHours; //reserved to future use
        
    }
    
    //task information
    address productOwner;
    uint    hoursEstimated;
    
    string  description;
    uint    fee;
    
    //task allocated
    uint   hoursAllocated;
    mapping (address => Commitment) commitments;
    
    uint   commitmentsCount;
    
    mapping( int => address ) developers;
    int developersCount;
    
    enum TaskStatus  { Prepare, InProgress, Ready, Closed }
    TaskStatus status;
    
    
    function TaskContract( address _productOwner,  uint _hoursEstimated, string _description, uint _fee)
    {
        productOwner  = _productOwner;
        hoursEstimated = _hoursEstimated;
        description   = _description;
        fee           = _fee;
        status = TaskStatus.Prepare;
    }
    function isProductOwner( address user ) returns( bool result )
    {
        return user == productOwner;
    }
    
    function isDeveloperParticipate(address developer) returns (bool result) 
    {
        var idx = lookupDeveloper(developer);
        return idx != -1;
    }
    function lookupDeveloper(address developer) returns( int idx) 
    {
        for (int i = 0; i < developersCount; i++) {
            if ( developers[i] == developer ) return i;
        }
        return -1;
    }
    function getStatus() returns (TaskStatus _status )
    {
        return status;
    }
    function getDeveloper(int idx) returns( address dev)
    {
        return developers[idx];
    }
    function getDevelopersCount() returns(int count)
    {
        return developersCount;
    }
    function getCommitment(address developer) returns (uint  value)
    {
        return commitments[developer].committedHours;
    }
    
    //for Developer
    function participateInTask(uint reserveHours ) whenPrepare
    {
        hoursAllocated += reserveHours;
        if  (commitments[msg.sender].isCreated) {
            commitments[msg.sender].availableHours += reserveHours;
        }
        else {
            commitments[msg.sender] =  Commitment(true, reserveHours, 0, 0);
            developers[developersCount++] = msg.sender;
        }

        if  (isResourcesAllocated()) {
            status = TaskStatus.InProgress;
        }
    }
    
    function isResourcesAllocated() returns (bool isContracted)
    {
        return (hoursEstimated == hoursAllocated);
    }
    function getActualHours() returns( uint hoursActual)  
    {
        //verify Task condition
        for (int i = 0; i < developersCount; i++) {
            var developer  = developers[i];
            var commitment = commitments[developer];
            
            hoursActual += commitment.committedHours;
        }
    }
    function isWorkDone() returns( bool _isWorkDone)  
    {
        if ( getActualHours() < hoursEstimated ) {
            return false;
        } 
        return true;
    }
    
    
    
    //for Developer
    function commitHours(uint spentHours, string _description) whenInProgress onlyDeveloper 
    {
        var c = commitments[msg.sender];
        
        //TOOD: verify overflow
        
        c.committedHours += spentHours;
        if ( c.committedHours == c.availableHours) {
            //commitment completed
        }
        if ( isWorkDone() ) {
            //task finished, need to approve, notify
            status = TaskStatus.Ready;
        }
    }

    //for Product Owner
    function approve()  //onlyProductOwner whenReady 
    {
        //pay to all
        var feePerHour = fee / hoursEstimated;
        for (int i = 0; i < developersCount; i++) {
            var developer  = developers[i];
            var commitment = commitments[developer];
            
            var developerFee = feePerHour * commitment.availableHours;
            
            //TOOD: transfer money From Adminstrator  to Developer
        }
        status = TaskStatus.Closed; 
        
    }

    modifier onlyDeveloper( )   { if ( isDeveloperParticipate( msg.sender ) )  _; }
    modifier onlyProductOwner() { if (  isProductOwner( msg.sender ) ) _; }
    modifier whenWorkDone()     { if (  isWorkDone() ) _; }
    modifier whenReady()        { if (  status == TaskStatus.Ready ) _; }
    modifier whenInProgress()   { if (  status == TaskStatus.InProgress ) _; }
    modifier whenPrepare()      { if (  status == TaskStatus.Prepare ) _; }
    
}


