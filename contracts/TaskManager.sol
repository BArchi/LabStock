pragma solidity ^0.4.0;

import "./owned.sol";
import "./mortal.sol";
import "./TaskContract.sol";

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


contract TaskManager is owned, mortal 
{

    mapping (uint  => TaskContract) tasks;
    uint numTasks;
    
    modifier onlyAdminstrator { if (msg.sender == owner) _; }
    modifier onlyDeveloper( uint taskId )    { if ( tasks[taskId].isDeveloperParticipate(msg.sender) )  _ ; }
    modifier onlyProductOwner( uint taskId ) { if ( tasks[taskId].isProductOwner( msg.sender ) ) _; }
    modifier whenTaskDone( uint taskId )     { if (  tasks[taskId].isWorkDone() ) _; }

    modifier whenReady(uint taskId)        { if (  tasks[taskId].getStatus() == TaskContract.TaskStatus.Ready ) _; }
    modifier whenInProgress(uint taskId)   { if (  tasks[taskId].getStatus() == TaskContract.TaskStatus.InProgress ) _; }
    modifier whenPrepare(uint taskId)      { if (  tasks[taskId].getStatus() == TaskContract.TaskStatus.Prepare ) _; }

    function isDeveloperParticipate(address developer, uint taskId) returns (bool isParticipate) 
    {
        var task  = tasks[taskId];
        return task.isDeveloperParticipate( developer);
    }
    //for Administrator     (Service)  -- all resources allocated for task
    function isResourcesAllocated(uint taskId) returns (bool isContracted)
    {
        var task  = tasks[taskId];
        return task.isResourcesAllocated();
    }

    //for Administrator     (Service)  -- task finished
    function isTaskDone(uint taskId) returns (bool _isTaskDone)
    {
        var task  = tasks[taskId];
        return task.isWorkDone();
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

        if   (isResourcesAllocated(taskId)) {
            //notify developers, they can start
        }
    }


    //for Developer
    function commitHours(uint taskId, uint spentHours, string _description) //onlyDeveloper(taskId)
    {
        var task  = tasks[taskId];
        task.commitHours( spentHours,  _description);
    }
    
    //for Product Owner
    function approve(uint taskId) onlyProductOwner(taskId) whenTaskDone(taskId)
    {
        var task  = tasks[taskId];
        task.approve();
    }
    
    function lookupTask( uint taskId) returns( TaskContract task)
    {
        return tasks[taskId];
    }
}

