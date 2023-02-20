;Code:ShiftJIS
;Computer:NEC PC-98series
;Filesystem:FAT-12
assume cs:code,ds:data,ss:stack,es:extra
data segment
    log db 00,01                     ;0:modeAH/1:1AL
    db 4 dup (00)                    ;2:tarckCH/3:sectorCL/4:headDH/5:driveDL
    db 10 dup (00)                   ;06/07/08/09/0A/0B/0C/0D/0E/0F         ;long 0xF

    lan db '言語を入力します|Input language|輸入語言',13,10,4 dup (32),'日本語(1)',32,32,32,124,32,32,'English(2)',32,32,124,'中国語(3)',13,10,36

    ja0 db '実行するアクションを入力します',13,10,'読み取り(1|書き込み(2',13,10,36
    ja1 db 'トラックを入力します',13,10,36
    ja2 db 'セクタを入力します',13,10,36
    ja3 db 'ヘッド番号を入力します',13,10,36
    ja4 db 'フロッピー ディスク文字を入力しますAB',13,10,36
    ja5 db 'ファイルの名を入力します',13,10,36

    en0 db 'Enter the action you want to take',13,10,'Read(1|Write(2',13,10,36
    en1 db 'Input tarck',13,10,36
    en2 db 'Input sector',13,10,36
    en3 db 'Input head number',13,10,36
    en4 db 'Input floppy drive latterAB',13,10,36
    en5 db 'Input file name',13,10,36

    cn0 db '輸入要進行的操作',13,10,'読取(1|写入(2',13,10,36
    cn1 db '輸入磁道',13,10,36
    cn2 db '輸入扇区',13,10,36
    cn3 db '輸入磁頭号',13,10,36
    cn4 db '輸入盤符AB',13,10,36
    cn5 db '輸入文件名',13,10,36

    err db 'エラー|Error|錯誤',36
    hvi db 13,10,36                    ;0x1FF,511                  
    nos db 'Notsupported',13,10,36
   sora db 4 dup (00)

  filen db 8 dup (20h),'.bin'           ;0x242-0x249,24A~24D
   sect db 512 dup (00)                ;0x24E
   hand dw ?
   ;0x452 
 furagu db 'k'

data ends

stack segment
    dw offset ja0,offset ja1,offset ja2,offset ja3,offset ja4,offset ja5,2 dup (00);00
    dw offset en0,offset en1,offset en2,offset en3,offset en4,offset en5,2 dup (00);10
    dw offset cn0,offset cn1,offset cn2,offset cn3,offset cn4,offset cn5,2 dup (00);20
stack ends

extra segment
    db 512 dup (00)
extra ends

code segment
  start:mov ax,data
        mov ds,ax
        mov ax,stack
        mov ss,ax
        mov ax,extra
        mov es,ax
        mov dx,offset lan
        call moji

        mov ah,1
        int 21h
;-----------------------------------------
        cmp al,49   ;Japanes
        jne eup
        xor sp,sp   ;0
        jmp lang
;-----------------------------------------
    eup:cmp al,50   ;English
        jne cns
        mov sp,16   ;0x10
        jmp lang
;----------------------------------------- 
    cns:cmp al,51   ;Chinese
        jne cr      ;<-----------
        mov sp,32   ;0x20
        jmp lang
;-----------------------------------------
   lang:xor si,si

        pop dx          ;mode   AH
        call moji
        call syo
        mov [si],al

        inc si
        mov di,4

     lo:pop dx          ;track  CH  ;sector CL  ;head   DH  ;dirver DL
        call moji
        call syo
        mov [si],al
        
        dec di
        cmp di,0
        jnz lo


        pop dx          ;file
        call moji
        call syo
        
        mov ax,[0]
        xchg al,ah
        mov cx,[2]
        xchg cl,ch
        mov dx,[4]
        xchg dl,dh

        int 13h

     cr:mov ah,4ch
        int 21h

;------------------------------------------<--END
   moji:mov ah,9
        int 21h
        ret
;-----------------------------------------
    syo:mov ah,1
        int 21h
        mov dx,offset hvi
        call moji
        ret
;-----------------------------------------
    det:mov ah,2
        mov dl,8
        int 21h
        ret
;-----------------------------------------



;-----------------------------------------
   del3:mov cx,4
     d1:shl al,1
        loop d1
        mov cx,4
     d2:shr ax,1
        loop d2
        ret   
;-----------------------------------------
    etd:mov ax,offset data
        mov bx,offset extra
        mov ds,bx
        mov es,ax

        xor si,si
        mov di,offset sect
        mov cx,512
        cld
        rep movsb

        xchg ax,bx
        mov ds,ax
        mov es,bx
        ret    
;-----------------------------------------
   fair:xor cx,cx
        lea dx,filen
        mov ah,3ch
        int 21h

        jc los
        mov hand,ax

        mov bx,hand
        mov cx,512
        lea dx,sect
        mov ah,40h
        int 21h

        jc los

        mov bx,hand
        mov ah,3eh
        int 21h    
        ret

    los:mov dx,offset err
        call moji
        mov ah,4ch
        int 21h
;-----------------------------------------
code ends
end start