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


contract TaskManager is owned, mortal {
    
    struct Commitment
    {
        uint availableHours;
        uint committedHours;
        uint approvedHours; //reserved to future use
    }

    struct Task {
        //task information
        address productOwner;
        uint    hoursEstimated;
        
        string  description;
        uint    fee;
        
        //task allocated
        uint   hoursAllocated;
        mapping (address => Commitment) commitments;
        
        uint   commitmentsCount;
        
        address[] developers;
    }
    
    mapping (uint  => Task) tasks;
    uint numTasks;
    
    modifier onlyAdminstrator { if (msg.sender == owner) _; }
    modifier onlyDeveloper( uint taskId )    { if ( isDeveloperParticipate( msg.sender, taskId ) )  _; }
    modifier onlyProductOwner( uint taskId ) { if ( msg.sender == tasks[taskid].productOwner) _; }
    
    function isDeveloperParticipate(address developer, uint taskId)
    {
        Task task  = tasks[taskId];
        for (var i = 0; i < task.developers.length; i++) {
            if ( task.developers[i] == developer ) return true;
        }
        return false;
    }
    
    
    //for productOwner
    function requestTask(uint hoursEstimated, string description, uint fee) returns (uint taskId)
    {
        taskId = numTasks++;
        tasks[taskId] = Task( {productOwner: msg.sender,  hoursEstimated: hoursEstimated, description: description, fee : fee } );
    }
    
    //for Developer
    function participateInTask(uint taskId, uint reserveHours )
    {
        //TODO: transfer money from Owner to Administrator


        Task task  = tasks[taskId];
        task.hoursAllocated += reserveHours;
        task.commitments[msg.sender] =  Commitment({availableHours: reserveHours});
        task.commitmentsCount++;
        
        task.developers[task.developers.length] = msg.sender;
        
        if   (this.isResourcesAllocated(taskId)) {
            //notify developers, they can start
        }
    }

    //for Administrator     (Service)  -- all resources allocated for task
    function isResourcesAllocated(uint taskId) returns (bool isContracted)
    {
        Task task  = tasks[taskId];
        if (task.hoursEstimated < task.hoursAllocated) {
            return false;
        }
        return true;
    }
    
    //for Developer
    function commitHours(uint taskId, uint spentHours, string description) onlyDeveloper(taskId)
    {
        Task task  = tasks[taskId];
        Commitment c = task.commitments[msg.sender];
        
        //TOOD: verify overflow
        
        c.committedHours += spentHours;
        if ( c.committedHours == c.availableHours) {
            task.commitmentsCount--;
        }
        if ( task.commitmentsCount == 0) {
            //task finished, need to approve, notify
        }
    }
    
    //for Product Owner
    function approve(uint taskId) onlyProductOwner( taskid ) onlyAdminstator
    {
        Task task  = tasks[taskId];
        var feePerHour = task.fee / task.hoursEstimated;
        for (var i = 0; i < task.developers.length; i++) {
            Commitment commitment = task.commitments;
            
            var developerFee = feePerHour * commitment.availableHours;
            
            //TOOD: transfer money From Adminstrator  to Developer
        }
    }
    
    
    
    
    
}
