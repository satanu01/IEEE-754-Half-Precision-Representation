.data
	str1: .asciiz "Enter the floating number: "
	str2: .asciiz "The number is: "
	str3: .asciiz "\nIEEE 754 Format: "
	num: .float 0.0
	zval:	.float 0.0
	binval:	.float	2.0
	temp:	.word	0, 0, 0, 0, 0, 0, 0, 0, 0, 0	# Maximum 10 (index-9 max)
	ieee:	.word	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	# Maximum 16
	lookuptable:	.asciiz	"0123456789ABCDEF"
	msg:	.asciiz	"\nRepresentation in hexadecimal is: 0x"

.text
.globl main
main:

# Print msg1.
	li $v0, 4
	la $a0, str1
	syscall

# Get the number from user.
	li $v0, 6
	syscall
	s.s $f0, num	# Store Floating-point word in num.

# Check Number if it less then zero or not.
	mov.s $f2, $f0
	la $t1, zval
	l.s $f4, ($t1)
	c.lt.s $f2, $f4
	bc1f next         # If >0 then jump to next.

# Set Sign Bit in ieee.
	li $t2, 1
	la $t0, ieee
	sw $t2, 0($t0)

	abs.s $f0, $f0	# Convert to positive number.

next:

# Split into Int($t3) and Dec($f6).
	mov.s $f1, $f0
	cvt.w.s $f5, $f1
	mfc1 $t3, $f5
	cvt.s.w $f6, $f5
	sub.s $f6, $f1, $f6

# Calculate Int part to Binary.
	la $t1, temp
	li $t2, 0	# Temp Counter

calint:
	rem $t4, $t3, 2
	div $t3, $t3, 2
	sw $t4, 0($t1)
	addi $t1, $t1, 4
	add $t2, $t2, 1
	bne $t3, $zero, calint

	# Store Exponent Val
	addi $t4, $t2, -1

	la $t0, ieee
	addi $t0, $t0, 20	# Start from location 5, that will overwrite by exponent.
	addi $t1, $t1, -4

storeint:
	lw $t7, 0($t1)
	sw $t7, 0($t0)
	addi $t0, $t0, 4
	addi $t1, $t1, -4
	addi $t2, $t2, -1
	bne $t2, $zero, storeint

# Calculate Dec part to Binary
	l.s $f7, binval

dec:
	mul.s $f6, $f6, $f7
	mov.s $f8, $f6
	cvt.w.s $f9, $f8
	mfc1 $t3, $f9
	cvt.s.w $f10, $f9
	sub.s $f6, $f6, $f10

	sw $t3, 0($t0)
	addi $t0, $t0, 4

	l.s $f4, zval
	c.eq.s $f6, $f4
	bc1t calexponent
	j dec 

calexponent:
	addi $t4, $t4, 15
	la $t0, ieee
	addi $t0, $t0, 20	# Start from location 5, that will overwrite by exponent.
	
loop:
	rem $t6, $t4, 2
	div $t4, $t4, 2
	sw $t6, 0($t0)
	addi $t0, $t0, -4
	bne $t4, $zero, loop

# Print overall in binary bits.
	li $v0, 4
	la $a0, str3
	syscall
	
	la $t0, ieee
	li $t1, 16
print:
	li $v0, 1
	lw $a0, 0($t0)
	syscall
	addi $t0, $t0, 4
	addi $t1, $t1, -1
	bne $t1, $zero, print

# First form the binary number in a register.
	la $t0, ieee	# Load the binary data into a register.
    	li $t2, 0		# $t2 will carry the whole binary value at a time. So, set the initial value to 0.
    
    	li $t3, 0	# Increment Counter.
    	li $t4, 16  	# Number of binary digits in a word.
    
loop1:
    	lw $t5, ($t0)		# Load the next binary digit.
    	sll $t2, $t2, 1		# Shift the current value to the left by 1.
    	add $t2, $t2, $t5	# Add the binary digit to the shifted value.
    
    	addi $t0, $t0, 4	# Increment address of binary data to get next binary digit.
    	addi $t3, $t3, 1	# Increment the loop counter.
    	blt $t3, $t4, loop1     # Repeat until all 16 binary digits are processed.
    

# Printing to display hexadecimal number.
	li $v0, 4	# system call code for print string.
	la $a0, msg	# loads address of prompt into $a0.
	syscall		# print the prompt message.

	li $t3, 4	# Initializing loop counter $t3 (bcz 4 hexadecimal digit).

loop2:
	srl $t5, $t2, 12	# Get first 4 binary bits of 16 binary bits in $t5.
	sll $t2, $t2, 4		# Get rest binary bits
	or $t2, $t2, $t5	# Append gotted first 4 bits to rest binary bits
	andi $t6, $t2, 15	# Finally get first 4 bits at $t6.

	la $t1, lookuptable	# Load hexadecimal lookup table.
	add $t1, $t1, $t6	# Increment the current place in hexadecimal table.
	lb $t1, 0($t1)		# Load Byte of current character of hexadecimal table.
	move $a0, $t1
	
	li $v0, 11 	# Print the character result in a0.
	syscall 

	sub $t3, $t3, 1		# Decrement loop2 counter.
	bne $t3, $zero, loop2


# Stop the program.
	li $v0, 10
	syscall 	# Return
