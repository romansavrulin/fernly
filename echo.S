.text

.global _start
_start:
disable_interrupts:
	mrs	r0, cpsr
	mov	r1, #0xc0
	orr	r0, r0, r1
	msr	cpsr_cxsf, r0

relocate_stack:
        ldr     r0, =0x7000bffc // stack_start
	mov     sp, r0

echo:
@ prompt
        adr     r0, prompt
        bl      uart_puts

@ read
        adr     r0, buffer
        mov     r1, =BUFFER_SIZE
        mov     r2, #0          // no timeout
        bl      readline 

@ print
        adr     r0, buffer
        bl      uart_puts

        adr     r0, newline
        bl      uart_puts

@ loop
        b      echo


        .set BUFFER_SIZE,4096
        .align 12
buffer:
        .space BUFFER_SIZE

        .align	4
prompt: 
        .asciz	"\r\necho> "

        .align 4
newline:     
        .asciz "\r\n"

.align	4

readline:
#       void uart_readline(void *buffer, int max_bytes, int timeout)
# same as uart_read but will return only up until the first newline character to 
# simulate unistd read as in jonesforth.
# puts a zero at the end of the buffer to make it a "string"
        push    {lr}
        mov     r3, r0      /* r3 has buffer address */
        mov     r4, r1      /* r4 has max_bytes */

        
@ read 1 char
        mov     r1, #1      /* read 1 byte at a time */
        ldr     r5, =0xfff03639
        blx     r5

@ compare byte read to newline char, if so, then add 0 at index+1 and return
@ else increment index and if less than max_bytes loop to read another byte

        pop     {pc}
        

uart_read:
#	void usb_uart_read(void *buffer, int bytes, int timeout)
	ldr	r3, =0xfff03639
	blx	r3

	pop	{pc}

uart_puts:
	push	{lr}
	mov	r3, r0
	mov	r1, #0

uart_puts_count_chars_loop:
	ldrb	r2, [r3], #1
	cmp	r2, #0
	beq	uart_puts_print
	add	r1, r1, #1
	b	uart_puts_count_chars_loop
uart_puts_print:
	mvn	r2, #0

# Call:
# void usb_uart_write(char *data, int bytes, int timeout)
	ldr	r3, =0xfff03653
	blx	r3

# Call:
# void usb_uart_flush(void)
	ldr	r3, =0xfff04845
	blx	r3

uart_puts_exit:
	pop	{pc}