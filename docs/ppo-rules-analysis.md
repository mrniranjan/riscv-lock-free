### Program Order 

#### Description:  Program Order (PO) is the order in which instrudction appear in single harts dynamic execution


```yaml
1. sw t1, 0(s0)
2. sw t2, 0(s1)

3. lw a0, 0(s0)
4. lw a1, 0(s1) 

Program Order: 1->2->3->4
```

#### Preserved Program order

#### Definition: Global Memory order for any given execution of a program respects some but not all of each harts program order

#### Example: 
Consider to memory instruction **a** & **b** where **a** precedes **b** in preserved program order(& hence in GMO). 
if **a** precedes b in program order a & b both access main memory , if the following holds:

### 
1. b is a store &  a & b accesss overlapping memory address 

```yaml
Rule 1 applie:mple of preserved program order Rule 1
        # b is a store and a and b access overlapping memory address

        .section .data
        .align 3

var:
        .dword 43
        .section .text
        .globl _start
_start:
        la t0, var
        lw a0, 0(t0)
        sw a0, 2(t0)
exit:
        li x17, 93
        ecall 

b is a store, a and b overlap - a before b in PPO
# -> hardware must not let the store become visible before the load complete
```

Rule 1 applie any time the load(a) and store(b) share at least 1 byte regardless of register width
or access size



2. a & b are loads, x is a byte read by both a & b



