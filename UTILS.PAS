unit utils;

interface
type t_numero=record
        ddec,duni,cent,dec,uni:byte;
     end;

procedure pinta_cadena(mem_dest:word;cadena:string;font_mem,off_ini,x,y,tamany_font:word);
procedure pinta_cadena_ext(mem_dest:word;cadena:string;font_mem,off_ini,x,y,tamany_font:word);
procedure comptador_bcd(var max:byte;var numero:t_numero);
{MAX indica si hem arribat al maxim del comptador}
{pinta nomes es per pintar numeros}
procedure pinta(mem_dest,z_mem,off_ini:word;tamany,num,x,y:byte;posx,posy:word);
procedure pinta2(mem_dest,z_mem,x_ini,y_ini:word;tamany,num:byte;posx,posy:word);
procedure zoom05(mem_orig,mem_dest:word);
procedure zoomx2(mem_orig,mem_dest:word);
procedure flip(mem_orig,mem_dest:word);
procedure mirror(mem_orig,mem_dest:word);
procedure out;
procedure supcase(var cadena:string);
procedure out1(color:byte);
procedure out2(color:byte);
procedure out3(color:byte);
procedure out4(color:byte);
procedure out5(color:byte);
procedure out6(color:byte);
procedure out7(color:byte);
procedure out8(color:byte);
procedure out9(color:byte);
procedure out10(color:byte;separacio:word;velocitat:byte);
procedure crear_finestra(x1,y1,x2,y2:word;color:byte;z_mem:word);
function gettemps:word;
function calcula_refrescos_vertical(repeticions:byte):word;

implementation
uses grafix,crt,dos;

var vscr:ptr_pantalla;
    vaddr:word;

procedure supcase(var cadena:string);
var i:byte;
begin
     for i:=1 to length(cadena) do
     cadena[i]:=upcase(cadena[i]);
end;

procedure pinta_cadena(mem_dest:word;cadena:string;font_mem,off_ini,x,y,tamany_font:word);
const base=65;

var i:byte;
    offset_lletra:word;
begin
    supcase(cadena);
    for i:=1 to length(cadena) do
    begin
       offset_lletra:=(ord(cadena[i])-base)*tamany_font;
       if ord(cadena[i])=32 then offset_lletra:=27*tamany_font;
       put_sprite(font_mem,mem_dest,off_ini+offset_lletra,tamany_font,tamany_font,
                   (i-1)*tamany_font+x,y);
    end;
end;

procedure pinta_cadena_ext(mem_dest:word;cadena:string;font_mem,off_ini,x,y,tamany_font:word);
const base=32;

var i,linia:byte;
    offset_lletra,pos_pantalla,nova_linia_pantalla:word;
begin
    supcase(cadena);
    nova_linia_pantalla:=0;
    pos_pantalla:=0;
    for i:=1 to length(cadena) do
    begin
       offset_lletra:=(ord(cadena[i])-base)*tamany_font;
       linia:=offset_lletra div 320;
       offset_lletra:=offset_lletra mod 320;
       case cadena[i] of
         '`':begin linia:=1;offset_lletra:=184;end;
         '{':begin linia:=1;offset_lletra:=192;end;
         '`':begin linia:=1;offset_lletra:=200;end;
         '}':begin linia:=1;offset_lletra:=208;end;
         '€','‡':begin linia:=1;offset_lletra:=216;end;
         '¥','¤':begin linia:=1;offset_lletra:=224;end;
       end;
       if cadena[i]='$' then
       begin
        inc(nova_linia_pantalla);
        pos_pantalla:=0;
        dec(pos_pantalla);
       end
       else
       put_sprite(font_mem,mem_dest,320*off_ini+offset_lletra+(320*linia*tamany_font),tamany_font,tamany_font,
                   (pos_pantalla)*tamany_font+x,y+(nova_linia_pantalla*(tamany_font+3)));
    inc(pos_pantalla);
    end;
end;


procedure pinta(mem_dest,z_mem,off_ini:word;tamany,num,x,y:byte;posx,posy:word);
var i,j:byte;
begin
   for i:=0 to tamany do
     for j:=0 to tamany do
      mem[mem_dest:320*(i+x+posy)+j+y+posx]:=mem[z_mem:320*(i+off_ini)+num*10+j];
end;

procedure pinta2(mem_dest,z_mem,x_ini,y_ini:word;tamany,num:byte;posx,posy:word);
var i,j:byte;
begin
   for i:=0 to tamany-1 do
     for j:=0 to tamany-1 do
      mem[mem_dest:320*(i+posy)+(j+posx)]:=mem[z_mem:(320*(y_ini+i))+(x_ini+num*tamany+j)];
end;

procedure comptador_bcd(var max:byte;var numero:t_numero);

begin
    if (numero.uni=9) and (numero.dec=9) and (numero.cent=9)
       and (numero.duni=9) and (numero.ddec=9) then max:=1;

    if numero.uni and $0A=$0A then
    begin
       numero.uni:=0;
       inc(numero.dec)
    end;

    if numero.dec and $0A=$0A then
    begin
       numero.dec:=0;
       inc(numero.cent);
    end;

    if numero.cent and $0A=$0A then
    begin
       numero.cent:=0;
       inc(numero.duni);
    end;

    if numero.duni and $0A=$0A then
    begin
       numero.duni:=0;
       inc(numero.ddec);
    end;

    if numero.ddec and $0A=$0A then
    begin
       numero.ddec:=0;
    end;

    if max=1 then
    begin
     numero.ddec:=9;
     numero.duni:=9;
     numero.cent:=9;
     numero.dec:=9;
     numero.uni:=8;
    end;
end;

procedure zoom05(mem_orig,mem_dest:word);
var i,j,offset:word;
begin
   for i:=0 to 159 do
    for j:=0 to 99 do
    begin
     offset:=320*j+i;
     mem[mem_dest:offset]:=mem[mem_orig:320*(j*2)+(i*2)];
     mem[mem_dest:offset+1]:=mem[mem_orig:320*(j*2)+(i*2)];
     mem[mem_dest:offset+320]:=mem[mem_orig:320*(j*2)+(i*2)];
     mem[mem_dest:offset+321]:=mem[mem_orig:320*(j*2)+(i*2)]
    end;
end;

procedure zoomx2(mem_orig,mem_dest:word);
var i,j:word;
begin
   for i:=0 to 159 do
    for j:=0 to 99 do
    begin
     mem[mem_dest:320*(j*2)+(i*2)]:=mem[mem_orig:320*(j)+(i)];
     mem[mem_dest:320*(j*2)+((i*2)+1)]:=mem[mem_orig:320*(j)+(i)];
     mem[mem_dest:320*((j*2)+1)+(i*2)]:=mem[mem_orig:320*(j)+(i)];
     mem[mem_dest:320*((j*2)+1)+((i*2)+1)]:=mem[mem_orig:320*(j)+(i)]
    end;
end;

procedure flip(mem_orig,mem_dest:word);
var i,j:word;
begin
  for i:=0 to 319 do
   for j:=0 to 199 do
   begin
     mem[mem_dest:320*(199-j)+i]:=mem[mem_orig:320*(j)+(i)]
   end;
end;

procedure mirror(mem_orig,mem_dest:word);
var i,j:word;
begin
  for i:=0 to 319 do
   for j:=0 to 199 do
   begin
     mem[mem_dest:320*j+(319-i)]:=mem[mem_orig:320*(j)+(i)]
   end;
end;

procedure out;
var i,j,a:word;
    v:ptr_pantalla;
begin
    setup_virtual(v,a);
    for i:=1 to 8 do
    begin
     espera_vga;
     zoom05($a000,$a000);
    end;
    volcar_pantalla($a000,a);
    for i:=1 to 8 do
    begin
     for j:=1 to 3 do espera_vga;
     zoomx2(a,$a000);
     volcar_pantalla($a000,a);
    end;
    tancar_virtual(v);
end;

procedure out1(color:byte);
var x1:word;
begin
  for x1:=0 to 160 do
   begin
    line(0,199,2*x1,0,color,$a000);
    line(0,199,2*x1+1,0,color,$a000);

    line(0,0,2*x1,199,color,$a000);
    line(0,0,2*x1+1,199,color,$a000);

    line(319,0,319-(2*x1),199,color,$a000);
    line(319,0,319-(2*x1+1),199,color,$a000);

    line(319,199,319-(2*x1),0,color,$a000);
    line(319,199,319-(2*x1+1),0,color,$a000);

    espera_vga;
   end;
end;

procedure out2(color:byte);
var x1:word;
begin
  for x1:=0 to 160 do
   begin
    line(2*x1,199,2*x1,0,color,$a000);
    line(2*x1+1,199,2*x1+1,0,color,$a000);
    espera_vga;
   end;
end;

procedure out3(color:byte);
var x1:word;
begin
  for x1:=0 to 160 do
   begin
    line(319-(2*x1),199,319-(2*x1),0,color,$a000);
    line(319-(2*x1+1),199,319-(2*x1+1),0,color,$a000);
    espera_vga;
   end;
end;

procedure out4(color:byte);
var x1:word;
begin
  for x1:=0 to 100 do
   begin
    line(0,2*x1,319,2*x1,color,$a000);
    line(0,2*x1+1,319,2*x1+1,color,$a000);
    espera_vga;
   end;
end;

procedure out5(color:byte);
var x1:word;
begin
  for x1:=0 to 100 do
   begin
    line(0,199-(2*x1),319,199-(2*x1),color,$a000);
    line(0,199-(2*x1+1),319,199-(2*x1+1),color,$a000);
    espera_vga;
   end;
end;

procedure out6(color:byte);
var x1:word;
begin
  for x1:=0 to 100 do
   begin
    line(0,x1,319,x1,color,$a000);
    line(0,200-(x1+1),319,200-(x1+1),color,$a000);
    espera_vga;
   end;
end;

procedure out7(color:byte);
var x1:word;
begin
  for x1:=0 to 100 do
   begin
    line(0,100-x1,319,100-x1,color,$a000);
    line(0,100+(x1+1),319,100+(x1+1),color,$a000);
    espera_vga;
   end;
end;

procedure out8(color:byte);
var x1:word;
begin
  for x1:=0 to 160 do
   begin
    line(x1,0,x1,199,color,$a000);
    line(320-(x1+1),0,320-(x1+1),199,color,$a000);
    espera_vga;
   end;
end;

procedure out9(color:byte);
var x1:word;
begin
  for x1:=0 to 160 do
   begin
    line(160-x1,0,160-x1,199,color,$a000);
    line(160+(x1+1),0,160+(x1+1),199,color,$a000);
    espera_vga;
   end;
end;

procedure out10(color:byte;separacio:word;velocitat:byte);
var x1,x2,y2,loop:word;
begin
  x2:=320 div separacio;
  y2:=200 div separacio;
  for x1:=0 to separacio do
  begin
   for loop:=0 to x2 do
   begin
    line(x1+(separacio*loop),199,x1+(separacio*loop),0,color,$a000);
   end;
   for loop:=0 to y2 do
   begin
    line(0,x1+(separacio*loop),319,x1+(separacio*loop),color,$a000);
   end;
  for loop:=0 to velocitat do espera_vga;
  end;
end;

procedure crear_finestra(x1,y1,x2,y2:word;color:byte;z_mem:word);assembler;
asm
     mov ax,z_mem;
     mov es,ax;      {ES=Z_MEM}
   {for i:=0 to y1 do line(0,i,319,i,color,z_mem);}
     xor di,di;      {DI=0}

     mov ax,y1;      {AX=Y1}
     shl ax,8;       {AX=256*AX}
     mov cx,ax;      {CX=AX}
     shr ax,2;       {AX=AX div 4}
     add cx,ax;      {CX=CX+AX}

     mov al,color;
     rep stosb;

   {for i:=y2 to 199 do line(0,i,319,i,color,z_mem);}
     mov ax,y2;
     shl ax,8;
     mov di,ax;
     shr ax,2;
     add di,ax;


     mov ax,200;
     sub ax,y2;
     shl ax,8;       {AX=256*AX}
     mov cx,ax;      {CX=AX}
     shr ax,2;       {AX=AX div 4}
     add cx,ax;      {CX=CX+AX}

     mov al,color;
     rep stosb;

   {for i:=0 to x1 do line(i,0+y1,i,199-(199-y2),color,z_mem);}
     mov al,color

     mov cx,y2
     sub cx,y1
   @bucle1:
     mov dx,cx{push cx}
     mov bx,y2
     sub bx,cx
     shl bx,8
     mov di,bx
     shr bx,2
     add di,bx
     mov cx,x1
     rep stosb
     mov cx,dx{pop cx}
     loop @bucle1

   {for i:=x2 to 319 do line(i,0+y1,i,199-(199-y2),color,z_mem);}
     mov al,color

     mov cx,y2
     sub cx,y1

   @bucle2:
     mov dx,cx{push cx}

     mov bx,y2
     sub bx,cx
     shl bx,8
     mov di,bx
     shr bx,2
     add di,bx
     add di,x2

     mov bx,320
     sub bx,x2
     mov cx,bx
     rep stosb
     mov cx,dx{pop cx}
     loop @bucle2
end;

function gettemps:word;
var h,m,s,c:word;
begin
     gettime(h,m,s,c);
     gettemps:=h*60*60*100+m*60*100+s*100+c;
end;

function calcula_refrescos_vertical(repeticions:byte):word;
var refrescos:word;
    t1,t2,rep,total:word;
begin
    total:=0;
    if repeticions<=0 then repeticions:=1;
    for rep:=1 to repeticions do
    begin
     refrescos:=0;
     t1:=gettemps;
     repeat
      espera_vga;
      inc(refrescos);
      t2:=gettemps
     until t2-t1>=100;
     total:=total+refrescos;
    end;
    calcula_refrescos_vertical:=total div repeticions;
end;


end.