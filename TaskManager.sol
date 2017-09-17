pragma solidity ^0.4.0;


contract owned {
  function owned() { owner = msg.sender; }
  address owner;

  // This contract only defines a modifier but does not use it - it will
  // be used in derived contracts.
  // The function body is inserted where the special symbol "_" in the
  // definition of a modifier appears.
  modifier onlyowner { if (msg.sender == owner) _; }
  
}
contract mortal is owned {
  // This contract inherits the "onlyowner"-modifier from "owned" and
  // applies it to the "kill"-function, which causes that calls to "kill"
  // only have an effect if they are made by the stored owner.
  function kill() onlyowner {
    suicide(owner);
  }
}


/*

Scenario:
1. Product owner :  taskID = mgr.requestTask( 10 hours, "some taks descriptiption or link", fee: 1000 );
2. Develeper 1   :  mgr.participateInTask( taskID, 6 hours);
3. Developer 2   :  mgr.participateInTask( taskID, 4 hours);
4. Administrator :  mgr.isResourcesAllocated( taskID ) => true, notify all
5. Developer 1   :  mgr.commitHours( 3, "some work done" )
6. Developer 1   :  mgr.commitHours( 3, "another  work done" )
7. Developer 2   :  mgr.commitHours( 4, "work done" )
8. Administrator :  mgr.isTaskfinished( taskID ) => true, notify Owner
9. Owner         :  mgr.approve( taskId ) 
10. Developer 1   :  get fee
11. Developer 2   :  get fee


*/

contract TaskContract is owned, mortal
{
    struct Commitment
    {
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
    
    mapping( uint => address ) developers;
    uint developersCount;
    
    
    function TaskContract( address _productOwner,  uint _hoursEstimated, string _description, uint _fee)
    {
        productOwner  = _productOwner;
        hoursEstimated = _hoursEstimated;
        description   = _description;
        fee           = _fee;
    }
    function isProductOwner( address user ) returns( bool result )
    {
        return user == productOwner;
    }
    
    function isDeveloperParticipate(address developer) returns (bool result) 
    {
        for (uint i = 0; i < developersCount; i++) {
            if ( developers[i] == developer ) return true;
        }
        return false;
    }
    
    //for Developer
    function participateInTask(uint reserveHours )
    {
        hoursAllocated += reserveHours;
        commitments[msg.sender] =  Commitment(reserveHours, 0, 0);
        commitmentsCount++;
        
        developers[developersCount++] = msg.sender;
    }
    
    function isResourcesAllocated() returns (bool isContracted)
    {
        return (hoursEstimated == hoursAllocated);
    }
    
    //for Developer
    function commitHours(uint spentHours, string _description) onlyDeveloper
    {
        var c = commitments[msg.sender];
        
        //TOOD: verify overflow
        
        c.committedHours += spentHours;
        if ( c.committedHours == c.availableHours) {
            commitmentsCount--;
        }
        if ( commitmentsCount == 0) {
            //task finished, need to approve, notify
        }
    }

    function isWorkDone() returns( bool _isWorkDone)  
    {
        //verify Task condition
        uint hoursActual = 0;
        for (uint i = 0; i < developersCount; i++) {
            var developer  = developers[i];
            var commitment = commitments[developer];
            
            hoursActual += commitment.committedHours;
        }
        if ( hoursActual < hoursEstimated ) {
            return false;
        } 
        return true;
    }
    
    //for Product Owner
    function approve()  onlyProductOwner whenWorkDone 
    {
        //pay to all
        var feePerHour = fee / hoursEstimated;
        for (uint i = 0; i < developersCount; i++) {
            var developer  = developers[i];
            var commitment = commitments[developer];
            
            var developerFee = feePerHour * commitment.availableHours;
            
            //TOOD: transfer money From Adminstrator  to Developer
        }
    }

    modifier onlyDeveloper( )   { if ( isDeveloperParticipate( msg.sender ) )  _; }
    modifier onlyProductOwner() { if (  isProductOwner( msg.sender ) ) _; }
    modifier whenWorkDone()     { if (  isWorkDone() ) _; }
    
}


contract TaskManager is owned, mortal 
{

    mapping (uint  => TaskContract) tasks;
    uint numTasks;
    
    modifier onlyAdminstrator { if (msg.sender == owner) _; }
    modifier onlyDeveloper( uint taskId )    { if ( isDeveloperParticipate( msg.sender, taskId ) )  _; }
    modifier onlyProductOwner( uint taskId ) { if (  tasks[taskId].isProductOwner( msg.sender ) ) _; }
    
    function isDeveloperParticipate(address developer, uint taskId) returns (bool result) 
    {
        var task  = tasks[taskId];
        return task.isDeveloperParticipate( developer);
    }


    //for productOwner
    function requestTask(uint hoursEstimated, string description, uint fee) 
        returns (uint taskId) 
    {
        taskId = numTasks;
        tasks[taskId] = new TaskContract( msg.sender,  hoursEstimated, description, fee );
        numTasks++;
        
        return taskId;
    }
    
    //for Developer
    function participateInTask(uint taskId, uint reserveHours )
    {
        //TODO: transfer money from Owner to Administrator
        
        var  task  = tasks[taskId];
        task.participateInTask(reserveHours);

        /*if   (isResourcesAllocated(taskId)) {
            //notify developers, they can start
        }*/
    }

    //for Administrator     (Service)  -- all resources allocated for task
    function isResourcesAllocated(uint taskId) returns (bool isContracted)
    {
        var task  = tasks[taskId];
        return task.isResourcesAllocated();
    }

    //for Administrator     (Service)  -- task finished
    function isTaskDone(uint taskId) returns (bool isContracted)
    {
        var task  = tasks[taskId];
        return task.isWorkDone();
    }

    //for Developer
    function commitHours(uint taskId, uint spentHours, string _description) onlyDeveloper(taskId)
    {
        var task  = tasks[taskId];
        task.commitHours( spentHours,  _description);
    }
    
    //for Product Owner
    function approve(uint taskId) onlyAdminstrator onlyProductOwner( taskId ) 
    {
        var task  = tasks[taskId];
        task.approve();
    }
}