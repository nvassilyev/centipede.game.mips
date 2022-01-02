 # - Unit width in pixels: 8
 # - Unit height in pixels: 8
 # - Display width in pixels: 256
 # - Display height in pixels: 256
 # - Base Address for Display: 0x10008000 ($gp)
.data
	displayAddress: .word 0x10008000
	screenWidth: .word 128
	screenHeight: .word 128
	
	centipedePositions: .word 0:10
	centipedeDirections: .word 0:10
	bugLocation: .word 4032
	blastPositions: .word 0:5
	fleaLocation: .word 160
	
	centipedeLives: .word 3
	
	mushroomColor: .word 0xa020f0
	centipedeColor: .word 0xff6680
	blastColor: .word 0xffffff
	backgroundColor: .word 0x000000
	headColor: .word 0xb3001e
	playerColor: .word 0x4dffff
	fleaColor: .word 0xffdead
	byeColor:  .word 0xccb3ff
	
.globl main
.text
main:
	lw   $t0, displayAddress	# t0 address = displayAddress	
	li   $t1, 0
	jal wipe_background
	
	#reset centipede lives
	la  $t8, centipedeLives
	li  $t9, 3
	sw $t9, ($t8)
	
	lw   $t2, playerColor
	lw   $t3, bugLocation
	add $t3, $t3, $t0
	sw  $t2, ($t3) 
	
	li   $t1, 0		# t1, i = 0
	jal  draw_mushroom
	li   $a1, 0
	
	li   $t1, 0
	jal  initialize_centipede
	
	li  $t1, 0
	jal draw_centipede
	
	la $t2, fleaLocation    #t2 = address of flea position
	li $t3, 0
	sw $t3, ($t2)
	j game_loop

game_loop:
	lw, $t0, displayAddress
	li $t1, 0
	jal draw_blasts
	
	j update_flea
continue:
	# Remove Centipede
	li $t1, 0
	jal remove_centipede
				
	# Update centipede
	li   $t1, 0
	jal update_centipede
			
	# Draw
	li $t1, 0
	jal draw_centipede
	
	# remove player
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
finish_game_loop:
	li   $v0, 32
	li   $a0, 50  #Sleep
	syscall
	
skip_movement:
	lw, $t0, displayAddress
	j game_loop
	
game_over:
	jal wipe_background
	jal bye
game_over_continue:
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input2
	jal bye
	
	j game_over_continue
	
draw_mushroom:
	bge  $t1, 3712, return	
	add  $t3, $t0, $t1	# t3 = displayAddress + offset
	addi $t1, $t1, 4	# i ++
	
	li   $v0, 42
	li   $a0, 0
	li   $a1, 40
	syscall			# a0 = random.range(0, 40)

	bge  $a0, 3, draw_mushroom # if (a0 >= 3) continue
	
	lw   $t2, mushroomColor	# t1 word = mushroomColor
	sw   $t2, ($t3)		# displayAddress[0] = t1
	
	j draw_mushroom
	
wipe_background:
	bge  $t1, 4096, return	
	addi $t1, $t1, 4
	add  $t2, $t0, $t1
	lw   $t3, backgroundColor
	sw   $t3, ($t2)
	j wipe_background
	
initialize_centipede:
	bge  $t1, 40, return	
	
	la   $t2, centipedePositions 	# t2 = address of centipedePositions[0]
	add  $t3, $t2, $t1		# t3 = address of centipedePositions[i]
	addi $t5, $t1, 0
	sw   $t5, ($t3)
	
	la   $t2, centipedeDirections 	# t2 = address of centipedePositions[0]
	add  $t3, $t2, $t1		# t3 = address of centipedePositions[i]
	li   $t5, 4
	sw   $t5, ($t3)
	addi $t1, $t1, 4
	j initialize_centipede

draw_centipede:
	bge  $t1, 40, return	
	
	la   $t2, centipedePositions 	# t2 = address of centipedePositions[0]
	add  $t3, $t2, $t1		# t3 = address of centipedePositions[i]
	lw   $t4, ($t3)			# t4 = value at centipedePositions[i]
	
	addi $t1, $t1, 4
	
	beq  $t1, 40, colour_head
	lw   $t5, centipedeColor
	add  $t6, $t4, $t0
	sw   $t5, ($t6)
	
	j draw_centipede
	
colour_head:
	lw   $t5, headColor
	add  $t6, $t4, $t0
	sw   $t5, ($t6)
	
	j draw_centipede
	
update_centipede:
	bge  $t1, 40, return
	la   $t2, centipedePositions	# t2 = address centipedePositions 
	la   $t3, centipedeDirections	# t3 = address centipedeDirections 

	add  $t4, $t2, $t1		# t4 = address centipedePositions[i]
	add  $t5, $t3, $t1		# t5 = address centipedeDirections[i]
	addi $t1, $t1, 4		# i++
	lw   $t6, ($t4)			# t6 = value centipedePositions[i]
	lw   $t7, ($t5)			# t7 = value centipedeDirections[i]
	# switch dir just moved down
	beq $t7, 128, switch_dir_centipede
	
	# update centipedePositions[i] = centipedePositions[i] + centipedeDirections[i]
	add  $t8, $t6, $t7		
	# if hit right wall
	lw $t9, screenWidth 
	# newPos % 128 == 0
	div $t8, $t9
	mfhi $t9
		
	beq $t9, 0, centipede_down
	# centipede goes down now

	add  $t8, $t6, $t7		
	add $t9, $t0, $t8
	lw $t8, ($t9)
	lw $t9, mushroomColor
	
	lw $t2, playerColor
	beq $t2, $t8, game_over
	
	beq $t9, $t8 centipede_down 
	add $t8, $t6, $t7		
	sw $t8, ($t4)
	j update_centipede

switch_dir_centipede:
	add  $t8, $t6, $t7	#position + direction	 
	# if hit wall
	lw $t9, screenWidth  
	# newPos % 128 == 0
	addi $t8, $t8, -4
	div $t8, $t9
	mfhi $t9
	addi $t8, $t8, 4
	beq $t9, 0, switch_dir_centipede_right
	
switch_dir_centipede_left:
	li $t7, -4
	sw $t7, ($t5)	
	add $t8, $t6, $t7
	sw $t8, ($t4)
	j update_centipede
	
switch_dir_centipede_right:
	li $t7, 4
	sw $t7, ($t5)	
	add $t8, $t6, $t7
	sw $t8, ($t4)
	j update_centipede
	
centipede_down:
	addi $t8, $t6, 128
	sw $t8, ($t4) 
	
	lw $t7, screenWidth
	sw $t7, ($t5)
	j update_centipede
	
remove_centipede:
	bge  $t1, 40, return
	
	la   $t2, centipedePositions	# t2 = address centipedePositions
	add  $t3, $t2, $t1		# t4 = address centipedePositions[i]
	lw   $t3, ($t2)
	add  $t4, $t0, $t3
	
	addi $t1, $t1, 4		# i++
	
	lw   $t2, backgroundColor
	sw   $t2, ($t4) 
	j remove_centipede
make_flea:
	#generate random number from 1-32
	#flea position would be at 0
	li   $v0, 42
	li   $a0, 1
	li   $a1, 31
	syscall			# a0 = random.range(0, 31)
	sll $t2, $a0, 2         #multiplying by 4 to get position between 1-128
	li $a1, 0
	la  $t3, fleaLocation   #t3 = address of flea position
	sw  $t2, ($t3)     	#set value of flea position to t2
draw_flea:
	la $t3, fleaLocation   #t3 = address of flea position
	lw  $t2, ($t3)     	#set value of flea position to t2
	add $t2, $t2, $t0
	lw  $t6, fleaColor
	sw  $t6, ($t2)  #color pixel flea color
	j continue
	
update_flea:
	la $t2, fleaLocation    #t2 = address of flea position
	lw $t3, ($t2)		#t3 = value of flea position
	beq $t3, 0, make_flea   #if flea does not exist
	#j draw_flea
	bge $t3, 4096, make_flea 
	
	add $t4, $t3, $t0
	lw $t6, mushroomColor
	lw $t8, ($t4)
	beq $t6, $t8, flea_mushroom
	lw $t6, backgroundColor	#erase previous block blast pixel
	sw $t6, ($t4)
flea_continue:
	addi $t3, $t3, 128
	sw $t3, ($t2)
	
	#check for collisions
	add $t3, $t3, $t0
	lw $t5, ($t3)  #current color at flea position
	
	lw $t6, blastColor
	beq $t6, $t5, make_flea
	
	lw $t6, mushroomColor
	beq $t6, $t5, continue
	
	lw $t6, centipedeColor
	beq $t6, $t5, continue
	
	lw $t6, headColor
	beq $t6, $t5, continue
	
	lw $t6, playerColor
	beq $t6, $t5, game_over
	
	j draw_flea
	j continue
flea_mushroom:
	sw $t8, ($t4)
	j flea_continue
	
# function to get the input key
get_keyboard_input:
	lw $t2, 0xffff0004
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x71,  respond_to_q
	beq $t2, 0x72,  respond_to_r
	
	j finish_game_loop
	
get_keyboard_input2:
	lw $t2, 0xffff0004	
	beq $t2, 0x71,  respond_to_q
	beq $t2, 0x72,  respond_to_r
	
	j game_over
		
respond_to_j:
	la  $t2, bugLocation  #address of bug location
	lw $t4, ($t2)	 

	beq $t4, 3968, finish_game_loop  #prevent the bug from getting out of the canvas
	
	add $t6, $t4, $t0
	lw $t5, backgroundColor
	sw $t5, ($t6)		#paints previous block black
	
	addi $t4, $t4, -4   #updates position
	sw $t4, ($t2)
	add $t4, $t4, $t0
	lw $t3, playerColor
	sw $t3, ($t4)  #paint new block bug color
	
	j finish_game_loop
	
respond_to_k:
	la  $t2, bugLocation  #address of bug location
	lw $t4, ($t2)	 

	beq $t4, 4092, finish_game_loop  #prevent the bug from getting out of the canvas
	
	add $t6, $t4, $t0
	lw $t5, backgroundColor
	sw $t5, ($t6)		#paints previous block black
	
	addi $t4, $t4, 4   #updates position
	sw $t4, ($t2)
	add $t4, $t4, $t0
	lw $t3, playerColor
	sw $t3, ($t4)  #paint new block bug color
	
	j finish_game_loop

	
respond_to_x:
	li $t1, 0
	jal shoot_blast
	
	j game_loop

shoot_blast:
	# add blast to available location
	beq $t1, 20, return
	la $t2, blastPositions
	add $t3, $t2, $t1
	lw $t4, ($t3)
	addi $t1, $t1, 4
	beq $t4, 0, create_blast
	
	j shoot_blast	
create_blast:
	# save -128 of bugLocation to t3
	# get bugLocation
	la $t5, bugLocation
	lw $t6, ($t5)
	addi $t5, $t6, -128
	sw $t5, ($t3)

	j finish_game_loop
draw_blasts:
	beq $t1, 20, return		# i < 5
	la $t2, blastPositions		# t2 = address blast 0
	add $t3, $t2, $t1		# t3 = address blast i
	addi $t1, $t1, 4		# i++
	lw $t4, ($t3)			# t4 = value blast i
	beq $t4, 0, draw_blasts		# if there is no blast here, continue
	 
	add $t5, $t4, $t0		# getting where blast should be on screen
	lw $t6, backgroundColor		#erase previous block blast pixel
	sw $t6, ($t5)
	
	# move it up now
	addi $t4, $t4, -128
	add  $t5, $t4, $t0      #new blast location
	
	# t5 == mushroomColor
	lw $t6, mushroomColor
	lw $t7, ($t5)
	beq $t7, $t6, erase_mushroom
	
	# t5 == centipedeColor
	lw $t6, centipedeColor
	lw $t7, ($t5)
	beq $t7, $t6, hurt_centipede
	
	# t5 == headColor
	lw $t6, headColor
	lw $t7, ($t5)
	beq $t7, $t6, hurt_centipede

	#top of the screen boundary check
	ble $t4, 0, kill_blast
	
	lw   $t6, blastColor
	sw   $t6, ($t5)
	
	sw $t4, ($t3)
	
	j draw_blasts
erase_mushroom:
	lw $t6, backgroundColor
	sw   $t6, ($t5)
	j kill_blast
hurt_centipede:
	la  $t8, centipedeLives
	lw  $t9, ($t8)
	addi $t9, $t9, -1  #centipede loses a life
	sw $t9, ($t8)
	ble $t9, 0, game_over 
	
	j kill_blast
kill_blast:
	li $t6, 0
	sw $t6, ($t3)
	j draw_blasts
	
respond_to_q:
	jal wipe_background
	jal bye
	j exit
	
respond_to_r:
	j main
	
return:
	jr $ra
exit:
	li $v0, 10   # terminate the program gracefully
 	syscall
bye:
	addi $t0, $t0, 1576
	lw $t1, byeColor
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 512($t0)
	sw $t1, 640($t0)
	sw $t1, 644($t0)
	sw $t1, 648($t0)
	#draw y
	sw $t1, 400($t0)
	sw $t1, 528($t0)
	sw $t1, 656($t0)
	sw $t1, 408($t0)
	sw $t1, 536($t0)
	sw $t1, 660($t0)
	sw $t1, 664($t0)
	sw $t1, 792($t0)
	sw $t1, 920($t0)
	sw $t1, 916($t0)
	sw $t1, 912($t0)
	#draw E
	sw $t1, 672($t0)
	sw $t1, 676($t0)
	sw $t1, 680($t0)
	sw $t1, 544($t0)
	sw $t1, 416($t0)
	sw $t1, 420($t0)
	sw $t1, 424($t0)
	sw $t1, 288($t0)
	sw $t1, 160($t0)
	sw $t1, 164($t0)
	sw $t1, 168($t0)
	#draw !
	sw $t1, 176($t0)
	sw $t1, 304($t0)
	sw $t1, 432($t0)
	sw $t1, 688($t0)
	li $t1, 0
	lw $t0, displayAddress
	jr $ra
