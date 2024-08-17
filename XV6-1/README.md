# XV6 Scheduling Algorithms

This repository contains an enhanced implementation of xv6 that offers three scheduling policy options: First-Come-First-Serve (FCFS), Multi-Level Feedback Queue (MLFQ), and Round Robin (RR). Round Robin was the default scheduling policy provided by the base xv6 source code. We have augmented it with two additional options, FCFS and MLFQ. You can run the xv6 operating system with these policies using the following commands:

RR   =>   make qemu 
FCFS =>   make qemu SCHEDULER=FCFS 
MLFQ =>   make qemu SCHEDULER=MLFQ CPUS=1  (MLFQ should be run only with 1 CPU)

!Only one policy can be run at a time!


## FCFS (First-Come-First-Serve)

### Overview

The First-Come, First-Serve (FCFS) scheduling algorithm represents a fundamental and straightforward approach to process management. It prioritizes processes for execution based on the order in which they enter the ready state, adhering to the principle of processing tasks solely in the sequence of their arrival. This method exemplifies the core concept of executing tasks in the same order they become ready, making FCFS a foundational scheduling algorithm.

### Implementation

In XV6, FCFS is implemented in following steps:

Step 1 : The process with the lowest creation time (ctime), signifying the earliest arrival, is identified as the RUNNABLE process.

>       for (p = proc; p < &proc[NPROC]; p++)
>       {
>          acquire(&p->lock);
>         if ( p->state == RUNNABLE)
>         { // Check if the process follows FCFS policy
>           if (p_fcfs == 0 || p->ctime < p_fcfs->ctime)
>           {
>             p_fcfs = p; // Found a process with a smaller creation time
>           }
>         }
>          release(&p->lock);
>       }
    
Step 2 : The selected process is scheduled, its state is changed to RUNNING, the current process in the CPU is set to p_fcfs, and a context switch is performed.

>       acquire(&p_fcfs->lock);
>      if (p_fcfs->state == RUNNABLE)
>      {
>        // Switch to the chosen process.
>        p_fcfs->state = RUNNING;
>        c->proc = p_fcfs;
>        // switchuvm(p_fcfs);
>        swtch(&c->context, &p_fcfs->context);
>        // switchkvm();
>        c->proc = 0;
>      }
>       release(&p_fcfs->lock);


## MLFQ (Multi-Level-FeedBack-Queue)

### Overview

The Multi-Level Feedback Queue (MLFQ) is a scheduling algorithm employed in operating systems that allocates varying priorities to processes and dynamically adjusts these priorities based on their behavior and resource utilization patterns.

MLFQ scheduling consistently gives precedence to processes in the highest-priority queue. It operates as a preemptive scheduling algorithm, meaning that if, during a clock tick, a process with a higher priority is identified and waiting to be scheduled, it will preempt the current process.

To prevent process starvation, an aging mechanism has been implemented. If a process is not getting scheduled in its current queue and has a waiting time (wtime) exceeding 30 ticks, it is promoted to the end of the next higher-priority queue, with its wtime reset to zero.

Additionally, if a process voluntarily yields control of the CPU before using its entire allocated time slice, it remains within its current queue. MLFQ scheduling also includes a process aging mechanism. Each process accumulates a tick count, reflecting the time spent waiting in the queue. If this count exceeds a predefined threshold, the process is moved to the back of a higher-priority queue. This mechanism effectively mitigates the risk of process starvation.

### Implementation

Step 1: Within the struct proc definition in proc.h, three new variables are introduced: "wtime" (indicating the duration a process remains pending before scheduling), "que" (denoting the priority queue number, with 0 indicating the highest priority group to which the process is assigned), and "qtime" (reflecting the number of execution cycles the process undergoes while in the RUNNING state).

>     int que;
>     int wtime;
>     int qtime;

Step 2:  Initialization of these new struct proc entries occurs in the "found" segment of the allocproc() function, located in proc.c. Set wtime to zero, qtime to zero, and que to zero. This initial configuration is applied because every newly created process is initially assigned to the highest-priority queue (0).

>     p->wtime = 0;
>     p->qtime = 0;
>     p->que = 0;

Step 3: Adjust the waiting time of all processes in the RUNNABLE state, indicating those prepared for execution but currently inactive. To incorporate aging, when incrementing the wtime of a process, check if the wtime for that process has exceeded the "Aging Ticks," which in this case are set to 30 ticks. If the process has exceeded the "Aging Ticks," its priority is promoted to the next higher-priority queue to prevent starvation. This promotion only occurs if the process is in any queue other than the highest-priority queue (0), and its wtime is reset to 0 to move it to the back of the next queue.

>       void update_time()
>       {
>         struct proc *p;
>         for (p = proc; p < &proc[NPROC]; p++)
>         {
>           acquire(&p->lock);
>           if (p->state == RUNNING)
>           {
>             p->rtime++;
>           }
>           else if (p->state == RUNNABLE)
>           {
>             p->wtime++;
>             // Aging
>             if (p->wtime > 30)
>             {
>               if (p->que > 0)
>               {
>                 p->que--;
>                 p->wtime = 0;
>               }
>             }
>           }
>       
>           release(&p->lock);
>         }
>       }

Step 4: Within the "scheduler()" function located in the "proc.c" file, create a variable named "p_mlfq" to store the process designated for scheduling. Ensure that interrupts are enabled using the "intr_on()" function to prevent potential deadlock situations.

Step 5: To identify a process for scheduling (stored in p_mlfq), iterate through all processes in a RUNNABLE state. The selection process involves two criteria: firstly, the process must belong to the highest priority bracket among all processes (indicated by a lower p->que). Secondly, the process with the maximum wtime is given preference as it would have been placed at the front of the queue assuming a queue data structure. Acquire and release steps can be skipped here since MLFQ is presumed to operate on a single CPU. 

>       struct proc *p_mlfq = 0;
>       int min_que = 3;
>       // Iterate through all processes
>       for (p = proc; p < &proc[NPROC]; p++)
>       {
>         // acquire(&p->lock);
>         if (p->state == RUNNABLE && p->que < min_que)
>         {
>           min_que = p->que;
>           if (min_que == 0)
>           {
>             break;
>           }
>         }
>         // release(&p->lock);
>       }
>       int maxwtime = 0;
>       for (p = proc; p < &proc[NPROC]; p++)
>       {
>         acquire(&p->lock);
>         if (p->state == RUNNABLE && p->que == min_que && p->wtime > maxwtime)
>         {
>           maxwtime = p->wtime;
>           p_mlfq = p;
>         }
>   
>         // release(&p->lock);
>       }
>        //release every acquired lock other than the selected process's lock
>       for (p = proc; p < &proc[NPROC]; p++)
>       {
>         if (p != p_mlfq)
>           release(&p->lock);
>       }

Step 6: Capture the identified process within the variable 'p_mlfq' and execute a context switch utilizing the 'swtch' function. Before doing so, ensure that the state of this process is set to 'RUNNING,' and both 'wtime' and 'qtime' are reset to zero. This adjustment is necessary since the process has now been scheduled.


>       if (p_mlfq)
>       {
>         // acquire(&p_mlfq->lock);
>         if (p_mlfq->state == RUNNABLE)
>         {
>           // Switch to the chosen process.
>           p_mlfq->state = RUNNING;
>           p_mlfq->wtime = 0;
>           p_mlfq->qtime = 0;
>           c->proc = p_mlfq;
>           // switchuvm(p_mlfq);
>           swtch(&c->context, &p_mlfq->context);
>           // switchkvm();
>           c->proc = 0;
>           release(&p_mlfq->lock);
>         }
>       }



Step 7: Within the "usertrap()" function in the "trap.c" file, when a timer interrupt occurs (specifically when the "which_dev" variable becomes equal to 2), increment the "qtime" counter for the RUNNING process by 1 to signify its current execution. Then, assess whether the accumulated running time of the process, as denoted by the "qtime" function, exceeds the time slice allocated for the respective queue to which the process belongs. The assumed time slice values for the four queues are as follows: queue 0 (1 tick), queue 1 (3 ticks), queue 2 (9 ticks), and queue 3 (15 ticks).
  
>       #ifdef MLFQ_SCHED
>       if (which_dev == 2)
>       {
>         p->qtime++;
>         if (p->que == 0 && p->qtime > 1)
>         {
>           p->que++;
>           p->qtime = 0;
>           p->wtime = 0;
>           yield();
>         }
>         else if (p->que == 1 && p->qtime > 3)
>         {
>           p->que++;
>           p->qtime = 0;
>           p->wtime = 0;
>           yield();
>         }
>         else if (p->que == 2 && p->qtime > 9)
>         {
>           p->que++;
>           p->qtime = 0;
>           p->wtime = 0;
>           yield();
>         }
>         else if (p->que == 3 && p->qtime > 15)
>         {
>           p->qtime = 0;
>           p->wtime = 0;
>           yield();
>         }
>       }
>       #endif


Step 8: If the running time exceeds the allocated time slice, it indicates that the process has consumed more time than allotted within its current queue (time slice). Consequently, reduce its priority level by incrementing the queue number by 1 and reset both qtime and wtime to 0. This action facilitates the process's termination through the yield function, and setting wtime to 0 indicates that it is placed at the end of the next lower priority queue.

Step 9: If the elapsed time is equal to or less than the allocated time slice, refrain from yielding and permit the process to maintain its current priority.

## Comparision between schedulers

*30 ticks for MLFQ Aging

### On a normal PC
| Scheduling Algorithm  | Run Time | Wait Time |
|-----------------------|----------|-----------|
| RR                    |    19    |    175    |
| RR (CPU-2)            |    21    |    133    |
| FCFS                  |    18    |    137    |
| FCFS (CPU-2)          |    19    |    117    |
| MLFQ                  |    18    |    176    |


### On a slower PC(mine)(has varying performance due to heating issue)
| Scheduling Algorithm  | Run Time | Wait Time |
|-----------------------|----------|-----------|
| RR                    |    36    |    252    |
| RR (CPU-2)            |    45    |    182    |
| FCFS                  |    45    |    208    |
| FCFS (CPU-2)          |    45    |    132    |
| MLFQ                  |    39    |    260    |


You can find the graphs for MLFQ in the same directory with MLFQ with CPU=1 and aging time 30 ,40 and 50 ticks.


In the case of my specific laptop, there are instances when the runtime values significantly escalate owing to a CPU-related concern. In order to address this issue, I employ the method of restarting my Linux system.



    
## References (For Scheduling and other xv6 parts)

- [SIGALARM and SIGRETURN Refernce](https://xiayingp.gitbook.io/build_a_os/labs/lab-6-alarm)
- [GetReadCount in xv6 GitHub](https://gist.github.com/bridgesign/e932115f1d58c7e763e6e443500c6561)
- [Scheduling in xv6 GitHub](https://github.com/marf/xv6-scheduling)
- [ChatGPT Prompts (Might not have used ideas from all .)](https://chat.openai.com/share/ea04c065-8a2d-4ae3-a658-e614f72c7445)
                            (https://chat.openai.com/share/8c871fc3-ef8a-44a4-a8a5-db08caa89de8)
