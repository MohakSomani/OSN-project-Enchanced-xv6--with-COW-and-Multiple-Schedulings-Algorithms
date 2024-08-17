# Enhanced xv6 with Advanced Scheduling and Copy-on-Write

This project enhances the xv6 operating system with advanced scheduling algorithms and Copy-on-Write (COW) fork implementation. It was developed as part of the Operating Systems and Networks (OSN) course.

## Features

### Part 1: Scheduling Algorithms

- **First Come First Serve (FCFS)**: Non-preemptive scheduling based on process creation time.
- **Multi-Level Feedback Queue (MLFQ)**: 4-level priority queue with aging mechanism to prevent starvation.
- **Round Robin (RR)**: Default xv6 scheduling algorithm.

### Part 2: Additional Enhancements

- **Priority Based Scheduling (PBS)**: Preemptive scheduler using static and dynamic priorities.
- **Copy-on-Write (COW) Fork**: Optimized fork() implementation for efficient memory usage.

## Running the Project

To run xv6 with different scheduling policies:

    RR:    make qemu

    FCFS:  make qemu SCHEDULER=FCFS

    MLFQ:  make qemu SCHEDULER=MLFQ CPUS=1

    PBS:   make qemu SCHEDULER=PBS

Note: MLFQ should be run with only 1 CPU.

## Implementation Details

### FCFS (First-Come-First-Serve)

- Selects the process with the lowest creation time (ctime) for execution.
- Non-preemptive: runs until completion or voluntary yield.

### MLFQ (Multi-Level Feedback Queue)

- 4 priority queues with different time slices.
- Implements aging mechanism to prevent starvation.
- Preemptive: higher priority processes can interrupt lower priority ones.

### PBS (Priority Based Scheduler)

- Uses both Static Priority (SP) and Dynamic Priority (DP).
- DP calculation considers Recent Behavior Index (RBI).
- `set_priority()` system call allows users to set process SP.

### COW (Copy-on-Write) Fork

- Optimizes `fork()` by sharing physical memory until modification.
- Implements page fault handler for COW pages.
- Efficient memory usage for forked processes.

## Performance Comparison

| Scheduler | Run Time | Wait Time |
|-----------|----------|-----------|
| RR        | 19       | 175       |
| FCFS      | 18       | 137       |
| MLFQ      | 18       | 176       |
| PBS       | -        | -         |

(Times in ticks, tested on a standard PC configuration)



# Detailed documentation for each component, including implementation details, assumptions, references and analysis, is available in the project directories.
