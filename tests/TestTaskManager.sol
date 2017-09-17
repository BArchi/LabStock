pragma solidity ^0.4.0;

import "./TaskManager.sol";
import "./owned.sol";
import "./mortal.sol";


contract TestTaskManager is owned, mortal
{
    function test1() returns( uint value )
    {
        var mgr = new TaskManager();
        
        var taskId = mgr.requestTask( 100, "test work", 1000);
        var task = mgr.lookupTask( taskId);
        
        assert( TaskContract.TaskStatus.Prepare == task.getStatus());
        
        mgr.participateInTask(taskId, 50 );
        mgr.participateInTask(taskId, 50 );
        
        
        assert(false == mgr.isTaskDone( taskId));
        assert(TaskContract.TaskStatus.InProgress == task.getStatus());
        
        
        mgr.commitHours( taskId, 50, "some work done" );
        assert(false == mgr.isTaskDone( taskId));
        
        mgr.commitHours( taskId, 50, "some work done" );
        assert(true == mgr.isTaskDone( taskId));
        assert(TaskContract.TaskStatus.Ready == task.getStatus());
        
        mgr.approve( taskId );
        assert(TaskContract.TaskStatus.Closed == task.getStatus());
        
        
        //return 0;
    }
}