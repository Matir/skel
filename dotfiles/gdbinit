# General options
set verbose off
set disassembly-flavor intel
set output-radix 0x10
set input-radix 10.

# helpful shortcuts
define lsbp
  info breakpoints
end
document lsbp
List all breakpoints
end

define iframe
  info frame
  info args
  info locals
end
define reg
  info registers
end

# __________________gdb options_________________

# set to 1 to have ARM target debugging as default, use the "arm" command to switch inside gdb
set $ARM = 0
# set to 0 if you have problems with the colorized prompt - reported by Plouj with Ubuntu gdb 7.2
set $COLOUREDPROMPT = 0
# Colour the first line of the disassembly - default is green, if you want to change it search for
# SETCOLOUR1STLINE and modify it :-)
set $SETCOLOUR1STLINE = 0
# set to 0 to remove display of objectivec messages (default is 1)
set $SHOWOBJECTIVEC = 1
# set to 0 to remove display of cpu registers (default is 1)
set $SHOWCPUREGISTERS = 1
# set to 1 to enable display of stack (default is 0)
set $SHOWSTACK = 1
# set to 1 to show 4 bytes of the stack at a time for 32bit and 8 bytes for 64bit
set $STACK_WORDSIZE = 1
# set to 1 to enable display of data window (default is 0)
set $SHOWDATAWIN = 0
# set to 0 to disable coloured display of changed registers
set $SHOWREGCHANGES = 1
# set to 1 so skip command to execute the instruction at the new location
# by default it EIP/RIP will be modified and update the new context but not execute the instruction
set $SKIPEXECUTE = 0
# if $SKIPEXECUTE is 1 configure the type of execution
# 1 = use stepo (do not get into calls), 0 = use stepi (step into calls)
set $SKIPSTEP = 1
# show the ARM opcodes - change to 0 if you don't want such thing (in x/i command)
set $ARMOPCODES = 1
# x86 disassembly flavor: 0 for Intel, 1 for AT&T
set $X86FLAVOR = 0
# use colorized output or not
set $USECOLOR = 0
# 64 bit options
set $64BITS = 0
# Remote 64 bit debugging
set $KDP64BITS = -1

set confirm off
set verbose off

set output-radix 0x10
set input-radix 0x10

# These make gdb never pause in its output
set height 0
set width 0

set $SHOW_CONTEXT = 1
set $SHOW_NEST_INSN = 0

set $CONTEXTSIZE_STACK = 6
set $CONTEXTSIZE_DATA  = 8
set $CONTEXTSIZE_CODE  = 8

# __________________end gdb options_________________
#

source ~/.reverser-gdbinit
