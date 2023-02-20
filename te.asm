;Code:ShiftJIS
;Computer:NEC PC-98series
;Filesystem:FAT-12
assume cs:code,ds:data,ss:stack,es:extra
data segment
    log db 00,01                     ;0:modeAH/1:1AL
    db 4 dup (00)                    ;2:tarckCH/3:sectorCL/4:headDH/5:driveDL
    db 10 dup (00)                   ;06/07/08/09/0A/0B/0C/0D/0E/0F
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

  filen db 8 dup (00),'.bin'           ;0x242-0x249,24A~24D
   sect db 512 dup (00)                ;0x24E
   hand dw ?
   ;0x452 
 furagu db 'koko'

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
   lang:mov dx,offset hvi
        call moji

        xor si,si

        pop dx
        call moji   ;modeAH
        call syo
        call del4
        mov [si],al
        test al,2
        jne next1
        mov dx,offset nos
        call moji
        mov al,1
        mov [si],al
        
        inc si
        inc si
        mov di,4
        jmp next1
;----------------|
     cr:jmp clos;|
;----------------|
  next1:pop dx
        call moji   ;di4 tarckCH;di3 sectorCL;di2 headDH;di1 driveDL
        call syo
        call del4
        db 162,06,00                      ;mov [0006],al
        cmp bl,255
        je kuro
        call syo
        jmp kara
   kuro:mov al,48
   kara:call del4
        db 138,38,06,00                   ;mov ah,[0006]
        call del3
        mov [si],al

        xor bx,bx
        inc si
        dec di
        cmp di,0
        jne next1
;-----------------------------------------<<<<<<<<<<<<
        mov si,578
        mov cx,8
        pop dx
    fua:call moji   ;file name
        call syo
        cmp al,13
        je ok
        mov [si],al
        inc si
        loop fua
     ok:inc si
        mov bx,586
        mov cx,4
    ok2:mov al,[bx]
        mov [si],al
        inc si
        inc bx
        loop ok2    
;-----------------------------------------
        db 138,38,00,00                   ;mov ah,[0000]
        db 138,46,02,00                   ;mov ch,[0002]
        db 138,14,03,00                   ;mov cl,[0003]
        db 138,54,04,00                   ;mov dh,[0004]
        db 138,22,05,00                   ;mov dl,[0005]
        xor bx,bx
        int 13h
;-----------------------------------------
        call etd
;-----------------------------------------
        call fair
;-----------------------------------------;
        jmp clo                           ;  
                                          ;
   clos:mov dx,offset err                 ;
        call moji                         ;
    clo:mov ah,4ch                        ;
        int 21h                           ;
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
   del4:cmp al,13       ;Enter
        je ne5

        cmp al,48       ;'0'30
        jae ne1
        call det        ;<---Bug
        call syo
        jmp del4
    ne1:cmp al,57       ;'9'0x39
        ja ne2
        jmp re
    ne2:cmp al,65       ;'A'
        jbe ne3
        call det
        call syo
        jmp del4
    ne3:cmp al,70       ;'F'
        jbe ne4
        call det
        call syo
        jmp del4
    ne5:mov al,55
        mov bl,255
    ne4:sub al,7
     re:sub al,48       ;0x30
        ret
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