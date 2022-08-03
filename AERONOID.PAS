program aeronoid;
{$G+}
uses grafix,keyboard,dos,utils;

Const Max_Items=46;
		MAXVIDES=10;
		MAX_HISCORES=10;


type t_map=array [1..23,1..25]of char;

     cuc=record
		 x,y:word;
       speed:byte;
     end;

     t_item=record
         x,y:word;
     		tipo:byte;
         num_frame:byte;
         estat:byte; {0=no esta en pantalla 1=esta}
     end;

     t_map_item=array [1..23,1..25]of t_item;

     t_angle=record
     		x,y:integer;
     end;

     t_bola=record
         x,y:word;
         angle:t_angle;
         pegada:byte;
         tipo:byte;
     end;

     t_bandeja=record
     		x:word;
         tipo:byte;
         frame:byte;
         vides:byte;
     end;

     t_bala=record
     	   x,y:word;
         existeix:byte;
     end;

     RGB=array [1..3] of byte;
     T_AUXPAL=array[1..4] of RGB;

     t_matriu=array[1..36,1..40] of byte;

     t_nom=string[7];

     t_puntuacio=record
           pos:byte;
           nom:t_nom;
           punts:word;
     end;

     t_taula_records=array [1..MAX_HISCORES] of t_puntuacio;

     t_pila_clock=record
     		retard,temps,flag_time,time_velocitat:word;
     end;

procedure DesCompresioJGC(fitxer_entrada,fitxer_descompres:string);
var count,i,dada,dada_next:byte;
    f_in,f_out:file of byte;

begin
    assign(f_in,fitxer_entrada);
    reset(f_in);
    assign(f_out,fitxer_descompres);
    rewrite(f_out);

    while not eof(f_in) do
    begin
    read(f_in,count);
    read(f_in,dada);
     for i:=1 to count do
      write(f_out,dada);
    end;
    close(f_in);
    close(f_out);
end;

procedure borrarFitxerMapa;
var f:file of byte;
begin
    assign(f,'fase.map');
    rewrite(f);
    close(f);
end;

function LoadMap(namemap:string;var vecmap:t_map;num_fase:char):byte;
var f:text;
    code:char;
    i,j:byte;
    fase:array [1..2] of char;
begin
    assign(f,namemap);
    reset(f);
    repeat
      Read(f,code);
      fase[1]:=code;
      Read(f,code);
      fase[2]:=code;
      if SeekEoln(f) then readln(f);
    until ((fase[1]=num_fase) and (fase[2]='.')) or (Eof(f));
    i:=1;j:=1;
    if not Eof(f) then
    while (j<=25) do
    begin
     LoadMap:=1;
     if SeekEoln(f) then
      begin
         readln(f);
         inc(j);
      end;
    if j<=25 then
    begin
     Read(f,code);
     vecmap[i,j]:=code;
     inc(i);
     if i>23 then i:=1;
    end;
    end
    else LoadMap:=0;
    close(f);
end;

procedure melt(color:byte);
var cucs:array[1..320] of cuc;
	 i,j:word;
    variacio:integer;
    valid:byte;
begin
    randomize;
    cucs[1].speed:=3+random(3);
    cucs[1].x:=0;
    cucs[1].y:=random(15);
    for i:=2 to 320 do
    begin
     cucs[i].speed:=cucs[1].speed+random(2);
     cucs[i].x:=i-1;
     cucs[i].y:=random(15);
    end;

    for j:=1 to 67 do
    begin
     {espera_vga;}
     for i:=1 to 320 do
     begin
     if cucs[i].y<200 then
     begin
      cucs[i].y:=cucs[i].y+cucs[i].speed;
      Line(cucs[i].x,0,cucs[i].x,cucs[i].y,color,$a000);
     end;
     end;
    end;
end;


procedure disolve(color:byte;espera:byte);
var i,j:word;
	 offset:word;
begin
   randomize;
	for i:=1 to 300 do
   begin
   if espera>=1 then espera_vga;
   for j:=1 to 1000 do
     putpixel(random(320),random(200),color,$a000);
   end;
   cls(color,$a000);
end;


FUNCTION test_colisio(x1,y1,w1,h1, x2,y2,w2,h2 :integer):boolean;
  VAR xd,yd : boolean;
  BEGIN
    ASM
      mov xd,false
      mov yd,false
    END;
    if ((x1 <=x2) and (x1+w1>=x2)) then xd:=true else
      if ((x1 <=x2+w2) and (x1+w1>=x2+w2)) then xd:=true else
        if ((x1 >=x2) and (x1+w1<=x2+w2)) then xd:=true;
    if ((y1 <=y2) and (y1+h1>=y2)) then yd:=true else
      if ((y1 <=y2+h2) and (y1+h1>=y2+h2)) then  yd:=true else
        if ((y1 >=y2) and (y1+h1<=y2+h2)) then yd:=true;
    test_colisio:=xd and yd;
  END;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�}
var scr_front,scr_sprites,scr_back,buffer:ptr_pantalla;
	 p_front,p_sprites,p_back,vga2:word;
    map:t_map;
    MapaItems:t_map_item;
    i_clock,j_clock:byte;
    frame_vides,max:byte;
    vector:pointer;
    retard,mort:byte;
    temps:word;
    item:t_item;
    auxpal:t_auxpal;
    count:byte;
    Time_velocitat:word;
    Flag_time:byte;
    bola:t_bola;
    paleta:t_paleta;
    pause:boolean;
    pila:t_pila_clock;
    time2pageitems:byte;


procedure pintamapa;
var i,j:byte;
    x,y:word;
begin
   for i:=1 to 25 do
     for j:=1 to 23 do
     begin
       if map[j,i]<>'0' then
       begin
        y:=((i-1)*7)+10;
        x:=((j-1)*10)+10;
        if map[j,i]<>'A' then put_sprite(p_sprites,vga2,(ord(map[j,i])-49)*10,10,7,x,y)
         else put_sprite(p_sprites,vga2,90,10,7,x,y);
       end;
     end;
end;

procedure pintafront;
begin
  put_sprite(p_front,vga2,0,320,200,0,0);
end;

procedure pintanoid(noid:t_bandeja);
var xb:byte;
begin
  case noid.tipo of
   1:xb:=0;
   2:xb:=20;
   3:xb:=55;
   4:xb:=75;
   else xb:=0;
  end;
  if noid.tipo=2 then
  begin
    put_sprite(p_sprites,vga2,(320*31)+xb,35,5,noid.x,165);
    put_sprite(p_sprites,vga2,(320*14)+(11*(noid.frame-1)),11,17,noid.x+10,170);
  end
  else
  begin
    put_sprite(p_sprites,vga2,(320*31)+xb,20,5,noid.x,165);
    put_sprite(p_sprites,vga2,(320*14)+(11*(noid.frame-1)),11,17,noid.x+3,170);
  end;
end;

procedure pintabola(bola:t_bola);
begin
  if bola.tipo=1 then
   put_sprite(p_sprites,vga2,320*7,4,4,bola.x,bola.y)
   else put_sprite(p_sprites,vga2,320*7+4,7,7,bola.x,bola.y);
end;

procedure pintabala(bala:t_bala);
begin
   put_sprite(p_sprites,vga2,320*7+11,3,3,bala.x,bala.y);
end;

procedure pintavides(num_vides:byte;var num_frame:byte);
var i,j,x:byte;
begin
  j:=0;x:=1;
  if num_vides>1 then
   for i:=1 to num_vides-1 do
   begin
     if x>3 then begin inc(j);x:=1; end;
     put_sprite(p_sprites,vga2,320*7+(14)+(5*(num_frame-1)),5,7,267+((x-1)*10),43+(j*10));
     inc(x);
   end;
end;

procedure pintamort(num_vides:byte;var num_frame:byte);
var i,j,x:byte;
begin
  j:=0;x:=1;
  if num_vides>1 then
   for i:=1 to num_vides-1 do
   begin
     if x>3 then begin inc(j);x:=1; end;
     put_sprite(p_sprites,vga2,320*7+(34)+(5*(num_frame-1)),5,7,267+((x-1)*10),43+(j*10));
     inc(x);
   end;
end;

procedure Clock;interrupt;
begin
  if mort=0 then
  begin
   if retard=18 then
   begin
	  inc(frame_vides);
     retard:=0;
   end;
   frame_vides:=(frame_vides mod 4)+1;
   inc(retard);
  end
  else
   begin
     inc(frame_vides);
     dec(temps);
     frame_vides:=(frame_vides mod 8)+1;
     if temps=0 then mort:=0;
   end;
   if not pause then
   for j_clock:=1 to 25 do
   for i_clock:=1 to 23 do
   begin
      if (map[i_clock,j_clock]='0') then
      begin
       if MapaItems[i_clock,j_clock].tipo>0 then
       begin
         inc(MapaItems[i_clock,j_clock].num_frame);
         MapaItems[i_clock,j_clock].num_frame:=MapaItems[i_clock,j_clock].num_frame mod 8;
         if MapaItems[i_clock,j_clock].estat=1 then
         begin
           if MapaItems[i_clock,j_clock].y<190 then
           begin
			   inc(MapaItems[i_clock,j_clock].y);
            MapaItems[i_clock,j_clock].x:=MapaItems[i_clock,j_clock].x;
           end
           else MapaItems[i_clock,j_clock].estat:=2;
         end;
       end;
      end;
    end;
   inc(item.num_frame);
   item.num_frame:=item.num_frame mod 8;
   inc(count);
   count:=count mod 12;
   dec(time_velocitat);
   if (time_velocitat=0) and (Flag_time<2) then
   begin
    time_velocitat:=1024;
    case flag_time of
     0:begin
        if bola.angle.x>0 then bola.angle.x:=1;
        if bola.angle.x<0 then bola.angle.x:=-1;
        if bola.angle.y>0 then bola.angle.y:=1;
        if bola.angle.y<0 then bola.angle.y:=-1;
       end;
     1:begin
        if bola.angle.x>0 then bola.angle.x:=2;
        if bola.angle.x<0 then bola.angle.x:=-2;
        if bola.angle.y>0 then bola.angle.y:=2;
        if bola.angle.y<0 then bola.angle.y:=-2;
       end;
     2:begin
        if bola.angle.x>0 then bola.angle.x:=3;
        if bola.angle.x<0 then bola.angle.x:=-3;
        if bola.angle.y>0 then bola.angle.y:=3;
        if bola.angle.y<0 then bola.angle.y:=-3;
       end;
    end;
    inc(Flag_time);
   end;
   dec(time2pageitems);
end;

procedure setclock;
begin
   getintvec($1C,vector);
   setintvec($1C,@clock);
end;

procedure restoreclock;
begin
   setintvec($1C,vector);
end;

procedure dispara(x:word;var bala:t_bala);
begin
   if bala.existeix=0 then
   begin
    bala.x:=x+10;
    bala.y:=163;
    bala.existeix:=1;
   end;
end;

procedure ColisioBalaTaulell(var bala:t_bala;var punts:t_numero);
var x_map,y_map,sum:byte;
begin
    {convertir a coordenades del mapa de taulells}
    x_map:=(bala.x div 10);
    y_map:=(bala.y div 7);
    {comprobar si tenim taulell}
    if (map[x_map,y_map]<>'0') then
    begin
      bala.existeix:=0;
      {gestionar els taulells}
      if (x_map>0) and (x_map<=23) and (y_map>0) and (y_map<=25) then
       if map[x_map,y_map]='9' then map[x_map,y_map]:='A'
        else if (map[x_map,y_map]<>'9') and (map[x_map,y_map]<>'8') then
        begin
         map[x_map,y_map]:='0';
         for sum:=1 to 10 do
			begin
			 inc(punts.uni);
			 comptador_bcd(max,punts);
         end;
        end;
    end;
    {si no tenim taulell no fem res}
end;


procedure _ColisioTaulell{original mes omenys funciona}(var bola:t_bola;var punts:t_numero);
var next_x_map,next_y_map:byte;
    colisio:boolean;
    now_x_map,now_y_map,sum:byte;
    next_x,next_y:integer;
begin
    colisio:=false;
    if bola.angle.x<0 then
    next_x:=bola.x+bola.angle.x
    else next_x:=(bola.x+3)+bola.angle.x;
    if bola.angle.y<0 then
     next_y:=(bola.y+bola.angle.y)-3
    else next_y:=(bola.y+bola.angle.y);
    {convertir a coordenades del mapa de taulells}
    next_x_map:=(next_x div 10);
    next_y_map:=(next_y div 7);
    {comprobar si tenim taulell}
    if (map[next_x_map,next_y_map]<>'0') then
    begin
     if bola.tipo=1 then
     begin
      {calcular sentit del rebot}
      {coordenada actual de la bola}
      if bola.angle.x<0 then
       now_x_map:=(bola.x div 10)
      else now_x_map:=(bola.x+3) div 10;
      if bola.angle.y<0 then
       now_y_map:=(bola.y-3) div 7
      else now_y_map:=(bola.y) div 7;
      {si pega en un canto}
      if (now_x_map<>next_x_map) and (now_y_map<>next_y_map) then
      begin
       if ((now_x_map<next_x_map) and (now_y_map<next_y_map)
		    and (map[next_x_map+1,next_y_map]<>'0')
			 and (map[next_x_map,next_y_map-1]<>'0')) or
          ((now_x_map>next_x_map) and (now_y_map<next_y_map)
			 and (map[next_x_map-1,next_y_map]<>'0')
			 and (map[next_x_map,next_y_map-1]<>'0')) or
          ((now_x_map<next_x_map) and (now_y_map>next_y_map)
			 and (map[next_x_map+1,next_y_map]<>'0')
			 and (map[next_x_map,next_y_map+1]<>'0')) or
          ((now_x_map>next_x_map) and (now_y_map>next_y_map)
			 and (map[next_x_map-1,next_y_map]<>'0')
			 and (map[next_x_map,next_y_map+1]<>'0'))
		 then
		 begin
         bola.angle.y:=-bola.angle.y;
         bola.angle.x:=-bola.angle.x;
		 end
       else
       begin
         if (map[next_x_map,next_y_map]<>'0') then bola.angle.y:=-bola.angle.y
         else
         if (map[next_x_map,next_y_map]<>'0') then bola.angle.x:=-bola.angle.x;
       end;
      end
      {sino pega en ningun borde, pega en el taulell}
      else
      begin
         if (now_x_map=next_x_map) then bola.angle.y:=-bola.angle.y;
         if (now_y_map=next_y_map) then bola.angle.x:=-bola.angle.x;
      end;
     end;
      {gestionar els taulells}
      if (next_x_map>0) and (next_x_map<=23) and (next_y_map>0) and (next_y_map<=25) then
       if map[next_x_map,next_y_map]='9' then map[next_x_map,next_y_map]:='A'
        else if (map[next_x_map,next_y_map]<>'9') and (map[next_x_map,next_y_map]<>'8') then
        begin
         map[next_x_map,next_y_map]:='0';
         for sum:=1 to 10 do
			begin
			 inc(punts.uni);
			 comptador_bcd(max,punts);
         end;
        end;
    end;
    {si no tenim taulell no fem res}
end;

procedure ColisioTaulell(var bola:t_bola;var punts:t_numero);
var next_x_map,next_y_map:byte;
    colisio:boolean;
    now_x_map,now_y_map,sum:byte;
    next_x,next_y:integer;
    costat_bola:byte;

begin
    colisio:=false;

    if bola.angle.x<0 then next_x:=bola.x+bola.angle.x
      else next_x:=(bola.x+3)+bola.angle.x;
    if bola.angle.y<0 then next_y:=(bola.y+bola.angle.y)-3
      else next_y:=(bola.y+bola.angle.y);

    {convertir a coordenades del mapa de taulells}
    next_x_map:=(next_x div 10);
    next_y_map:=(next_y div 7);

    {coordenada actual de la bola}
    if bola.angle.x<0 then now_x_map:=(bola.x div 10)
      else now_x_map:=(bola.x+3) div 10;
    if bola.angle.y<0 then now_y_map:=(bola.y-3) div 7
      else now_y_map:=(bola.y) div 7;
{Fins aci va be ^}
    {comprobar si tenim taulell}

    if (map[next_x_map,next_y_map]<>'0') then
    begin
    if bola.tipo=1 then
    begin
     if map[now_x_map,next_y_map]<>'0' then bola.angle.y:=-bola.angle.y;
     if map[next_x_map,now_y_map]<>'0' then bola.angle.x:=-bola.angle.x;
    end;
    if bola.tipo=2 then
    begin
     if map[now_x_map,next_y_map]='8' then bola.angle.y:=-bola.angle.y;
     if map[next_x_map,now_y_map]='8' then bola.angle.x:=-bola.angle.x;
    end;
{A뇇 d'aci baix va be}
      {gestionar els taulells}
      if (next_x_map>0) and (next_x_map<=23) and (next_y_map>0) and (next_y_map<=25) then
       if map[next_x_map,next_y_map]='9' then map[next_x_map,next_y_map]:='A'
        else if (map[next_x_map,next_y_map]<>'9') and (map[next_x_map,next_y_map]<>'8') then
        begin
         map[next_x_map,next_y_map]:='0';
         for sum:=1 to 10 do
         begin
          inc(punts.uni);
          comptador_bcd(max,punts);
         end;
        end;
    end;
    {si no tenim taulell no fem res}
end;


procedure ColisioMargens(var bola:t_bola);
var next_x,next_y:word;
begin
   {comprobar el proxim moviment de la bola}
   next_x:=bola.x+bola.angle.x;
   next_y:=bola.y+bola.angle.y;
   if (next_x>=236) or (next_x<=10) then bola.angle.x:=-(bola.angle.x);
   if (next_y>=185) or (next_y<=10) then bola.angle.y:=-(bola.angle.y);
end;

procedure ColisioBandeja(var bola:t_bola;noid:t_bandeja);
var next_x,next_y:word;
	 colision:boolean;
begin
  colision:=false;
  {comprobar el proxim moviment de la bola}
   next_x:=bola.x+bola.angle.x;
   next_y:=bola.y+bola.angle.y;
  {Depen de la bandeja tenim una zona o un altra}
  if noid.tipo=2 then
    colision:=test_colisio(next_x+2,next_y+3,1,1,noid.x,170,35,1)
   else colision:=test_colisio(next_x+2,next_y+3,1,1,noid.x,170,20,1);
  if colision then bola.angle.y:=-bola.angle.y;
  if (colision) and (noid.tipo=3) then bola.pegada:=1;
end;

procedure ActualitzarMoviment(var bola:t_bola);
begin
   bola.x:=bola.x+bola.angle.x;
   bola.y:=bola.y+bola.angle.y;
end;

procedure MoureBolaPegada(var bola:t_bola;noid:t_bandeja);
begin
   bola.x:=noid.x+10;
   bola.y:=161;
end;

procedure moubola(var bola:t_bola;noid:t_bandeja;var punts:t_numero);
begin
  if bola.pegada=0 then
  begin
    {ha de rebotar...}
    {en un taulell?}
    ColisioTaulell(bola,punts);
    {en els margens?}
    ColisioMargens(bola);
    {en la bandeja?}
    ColisioBandeja(bola,noid);
    {actualitzar moviment}
    ActualitzarMoviment(bola);
  end
  else MoureBolaPegada(bola,noid);
end;

procedure moubala(var bala:t_bala;var punts:t_numero);
begin
   if bala.y>10 then dec(bala.y,3);
   if bala.y<=10 then bala.existeix:=0;
   if bala.existeix=1 then ColisioBalaTaulell(bala,punts);
end;

procedure mounoid(var noid:t_bandeja;var bola_pegada:byte;var bala:t_bala);
var ample:byte;
begin
   if noid.tipo=2 then ample:=35 else ample:=20;
   if teclapuls(keyarrowleft) then
	 if noid.x>11 then
    begin
	  dec(noid.x,2);
     inc(noid.frame);
    end;
   if noid.frame=5 then noid.frame:=1;
   if teclapuls(keyarrowright) then
	 if noid.x<241-ample then
    begin
	  inc(noid.x,2);
     inc(noid.frame);
    end;
   if noid.frame=5 then noid.frame:=1;
   if (teclapuls(keyspace)) and (bola_pegada=1) then bola_pegada:=0;
   if (teclapuls(keyspace)) and (noid.tipo=4) then dispara(noid.x,bala);
end;

procedure MouNoidAuto(var noid:t_bandeja;var bola:t_bola);
var ample:byte;
begin
   if noid.tipo=2 then ample:=35 else ample:=20;
   if bola.x<noid.x then
	 if noid.x>11 then
    begin
	  dec(noid.x,2);
     inc(noid.frame);
    end;
   if noid.frame=5 then noid.frame:=1;
   if bola.x>noid.x then
	 if noid.x<241-ample then
    begin
	  inc(noid.x,2);
     inc(noid.frame);
    end;
   if noid.frame=5 then noid.frame:=1;
   if (teclapuls(keyspace)) and (bola.pegada=1) then bola.pegada:=0;
end;


procedure initnoid(var noid:t_bandeja;vides:byte);
begin
   noid.x:=20;
   noid.frame:=1;
   noid.tipo:=1;
   noid.vides:=vides;
end;

procedure initbola(var bola:t_bola);
begin
   bola.x:=0;
   bola.y:=0;
   bola.angle.x:=1;
   bola.angle.y:=-1;
   bola.pegada:=1;
   bola.tipo:=1;
end;

procedure initbala(var bala:t_bala);
begin
   bala.existeix:=0;
end;

function BuscarTaulells(map:t_map):byte;
var j,i:byte;
    trobat:boolean;
begin
    j:=1;i:=1;trobat:=false;
    while (j<=25) and (not trobat) do
    begin
      trobat:=(map[i,j]<>'0') and (map[i,j]<>'8');
      inc(i);
      if i=24 then begin i:=1;inc(j); end;
    end;
    if trobat then BuscarTaulells:=1 else BuscarTaulells:=0;
end;

procedure CreaMapaItems(var MapaItem:t_map_Item;map:t_map);
var i,j:byte;
	 item:word;
    items_possats:byte;
begin
   randomize;
   items_possats:=0;
   for j:=25 downto 1 do
    for i:=1 to 23 do
    begin
      if (map[i,j]<>'0') and (map[i,j]<>'8') then
      begin
        item:=random(12);
        if items_possats=Max_Items then item:=0;
        if item>=5 then
        begin
		   inc(items_possats);
         item:=item-4;
         MapaItem[i,j].tipo:=item;
         MapaItem[i,j].estat:=0;
        end
        else
        begin
		   MapaItem[i,j].tipo:=0;
         MapaItem[i,j].estat:=0;
        end;
      end;
    end;
end;

procedure PintaItems(var MapaItem:t_map_item;map:t_map);
var i,j:byte;
    x,y:word;
begin
   for j:=1 to 25 do
    for i:=1 to 23 do
    begin
      if teclapuls(key1) then
		 put_sprite(p_sprites,vga2,320*(36+(MapaItem[i,j].tipo-1)*12)+(MapaItem[i,j].num_frame*11),11,12,i*10,j*7);
      if (map[i,j]='0') then
       if (MapaItem[i,j].tipo>0) and (MapaItem[i,j].estat=0) then
       begin
        MapaItem[i,j].x:=i*10;
        MapaItem[i,j].y:=j*7;
        MapaItem[i,j].estat:=1;
        {put_sprite(p_sprites,vga2,320*(36+(MapaItem[i,j].tipo-1)*12)+(MapaItem[i,j].num_frame*11),11,12,i*10,j*7);}
       end;
    if MapaItem[i,j].estat=1 then
    begin
      x:=MapaItem[i,j].x;
      y:=MapaItem[i,j].y;
      put_sprite(p_sprites,vga2,320*(36+(MapaItem[i,j].tipo-1)*12)+(MapaItem[i,j].num_frame*11),11,12,x,y);
    end;
    end;
end;

procedure AgarrarItem(var MapaItem:t_map_item;var noid:t_bandeja;var bola:t_bola;var punts:t_numero);
var i,j:byte;
    sum:word;
begin
    for j:=1 to 25 do
     for i:=1 to 23 do
     begin
       if MapaItem[i,j].estat=1 then
       begin
         if test_colisio(MapaItem[i,j].x,MapaItem[i,j].y,11,12,noid.x,165,20,10) then
         begin
          case MapaItem[i,j].tipo of
			  1:if noid.vides<MAXVIDES then inc(noid.vides);
           2:begin bola.tipo:=1;noid.tipo:=3;end;
           3:begin bola.pegada:=0;bola.tipo:=1;noid.tipo:=4;end;
           4:begin bola.pegada:=0;bola.tipo:=1;noid.tipo:=2;end;
           5:begin bola.pegada:=0;bola.tipo:=2;end;
           6:for sum:=1 to 300 do
               begin
                inc(punts.uni);
			       comptador_bcd(max,punts);
               end;
           7:begin bola.pegada:=0;noid.tipo:=5;end;
          end;
          MapaItem[i,j].estat:=2;
         end;
       end;
     end;
end;

procedure EliminarItemActiu(var MapaItem:t_map_item);
var i,j:byte;
begin
    for j:=1 to 25 do
     for i:=1 to 23 do
     begin
       if MapaItem[i,j].estat=1 then
       begin
         MapaItem[i,j].estat:=2;
         end;
     end;
end;

procedure EliminarItems(var MapaItem:t_map_item);
var i,j:byte;
begin
    for j:=1 to 25 do
     for i:=1 to 23 do
     begin
        MapaItem[i,j].estat:=2;
        MapaItem[i,j].tipo:=0;
     end;
end;


function passarfase(num_fase:byte):char;
begin
 case num_fase of
   1:passarfase:='1';
   2:passarfase:='2';
   3:passarfase:='3';
   4:passarfase:='4';
   5:passarfase:='5';
   6:passarfase:='6';
   7:passarfase:='7';
   8:passarfase:='8';
   9:passarfase:='9';
  10:passarfase:='A';
  11:passarfase:='B';
  12:passarfase:='C';
  13:passarfase:='D';
  14:passarfase:='E';
  15:passarfase:='F';
  16:passarfase:='G';
  17:passarfase:='H';
  18:passarfase:='I';
  19:passarfase:='J';
  20:passarfase:='K';
 END;
end;


function calcularMaxFases(namemap:string):byte;
var f:text;
    code:char;
    count:byte;

begin
    count:=0;
    assign(f,namemap);
    reset(f);
    repeat
      Read(f,code);
      if code='.' then inc(count);
      if SeekEoln(f) then readln(f);
    until (Eof(f));
    close(f);
    CalcularMaxFases:=count;
end;

procedure MakeGrid;
var i,j:word;
begin
   for j:=1 to 25 do
     line(10,10+(j*7),240,10+(j*7),4,p_back);
   for j:=1 to 23 do
     line(10+(j*10),10,10+(j*10),199,4,p_back);
end;

procedure MostrarPuntuacio(puntuacio:t_numero);
begin
   {decenes de millar}
   put_sprite(p_sprites,vga2,320*120+(puntuacio.ddec*5),5,7,266,20);
   {unitat de millar}
   put_sprite(p_sprites,vga2,320*120+(puntuacio.duni*5),5,7,272,20);
   {centenes}
   put_sprite(p_sprites,vga2,320*120+(puntuacio.cent*5),5,7,278,20);
   {decenes}
   put_sprite(p_sprites,vga2,320*120+(puntuacio.dec*5),5,7,284,20);
   {unitats}
   put_sprite(p_sprites,vga2,320*120+(puntuacio.uni*5),5,7,290,20);
end;

procedure MakeFondo(num_fase:byte);
var i,j:word;
    x,y:word;
begin
    cls(0,p_back);
    if num_fase mod 3 = 0 then begin x:=64;y:=127; end;
    if num_fase mod 3 = 1 then begin x:=0;y:=127; end;
    if num_fase mod 3 = 2 then begin x:=32;y:=127; end;
    for j:=0 to 5 do
     for i:=0 to 9 do
      put_sprite(p_sprites,p_back,320*y+x,32,32,i*32,j*32);
end;

procedure InitPuntuacio(var puntuacio:t_numero);
begin
   puntuacio.uni:=0;
   puntuacio.dec:=0;
   puntuacio.cent:=0;
   puntuacio.duni:=0;
   puntuacio.ddec:=0;
end;

procedure SavePalette;
var r,g,b:byte;
begin
   get_color(14,r,g,b);
   auxpal[1,1]:=r;
   auxpal[1,2]:=g;
   auxpal[1,3]:=b;
   get_color(21,r,g,b);
   auxpal[2,1]:=r;
   auxpal[2,2]:=g;
   auxpal[2,3]:=b;
   get_color(28,r,g,b);
   auxpal[3,1]:=r;
   auxpal[3,2]:=g;
   auxpal[3,3]:=b;
   get_color(35,r,g,b);
   auxpal[4,1]:=r;
   auxpal[4,2]:=g;
   auxpal[4,3]:=b;
end;

procedure RestorePalette;
begin
   set_color(14,auxpal[1,1],auxpal[1,2],auxpal[1,3]);
   set_color(21,auxpal[2,1],auxpal[2,2],auxpal[2,3]);
   set_color(28,auxpal[3,1],auxpal[3,2],auxpal[3,3]);
   set_color(35,auxpal[4,1],auxpal[4,2],auxpal[4,3]);
end;


procedure ShowPageItems(var count:byte);
var r,g,b:byte;
begin
   case count of
     0,1,2:begin
         set_color(14,auxpal[1,1],auxpal[1,2],auxpal[1,3]);
         set_color(21,auxpal[2,1],auxpal[2,2],auxpal[2,3]);
         set_color(28,auxpal[3,1],auxpal[3,2],auxpal[3,3]);
         set_color(35,auxpal[4,1],auxpal[4,2],auxpal[4,3]);
	    end;
     3,4,5:begin
         set_color(21,auxpal[1,1],auxpal[1,2],auxpal[1,3]);
         set_color(28,auxpal[2,1],auxpal[2,2],auxpal[2,3]);
         set_color(35,auxpal[3,1],auxpal[3,2],auxpal[3,3]);
         set_color(14,auxpal[4,1],auxpal[4,2],auxpal[4,3]);
	    end;
     6,7,8:begin
         set_color(28,auxpal[1,1],auxpal[1,2],auxpal[1,3]);
         set_color(35,auxpal[2,1],auxpal[2,2],auxpal[2,3]);
         set_color(14,auxpal[3,1],auxpal[3,2],auxpal[3,3]);
         set_color(21,auxpal[4,1],auxpal[4,2],auxpal[4,3]);
	    end;
     9,10,11:begin
         set_color(35,auxpal[1,1],auxpal[1,2],auxpal[1,3]);
         set_color(14,auxpal[2,1],auxpal[2,2],auxpal[2,3]);
         set_color(21,auxpal[3,1],auxpal[3,2],auxpal[3,3]);
         set_color(28,auxpal[4,1],auxpal[4,2],auxpal[4,3]);
	    end;
   end;
   cls(2,vga2);
   {ITEM}
    put_Sprite(p_sprites,vga2,320*180+40,70,15,120,10);
   {1Up}
    put_sprite(p_sprites,vga2,320*(36+(1-1)*12)+(Item.num_frame*11),11,12,45,50);
    put_Sprite(p_sprites,vga2,320*159,24,7,40,70);
   {Slime}
    put_sprite(p_sprites,vga2,320*(36+(2-1)*12)+(Item.num_frame*11),11,12,115,50);
    put_Sprite(p_sprites,vga2,320*166,33,7,105,70);
   {Shoot}
    put_sprite(p_sprites,vga2,320*(36+(3-1)*12)+(Item.num_frame*11),11,12,185,50);
    put_Sprite(p_sprites,vga2,320*173,34,7,177,70);
   {Long}
    put_sprite(p_sprites,vga2,320*(36+(4-1)*12)+(Item.num_frame*11),11,12,255,50);
    put_Sprite(p_sprites,vga2,320*180,28,7,250,70);
   {Iron}
    put_sprite(p_sprites,vga2,320*(36+(5-1)*12)+(Item.num_frame*11),11,12,85,110);
    put_Sprite(p_sprites,vga2,320*187,27,7,78,130);
   {300 P.}
    put_sprite(p_sprites,vga2,320*(36+(6-1)*12)+(Item.num_frame*11),11,12,155,110);
    put_Sprite(p_sprites,vga2,320*160+40,63,9,130,130);
   {Super}
    put_sprite(p_sprites,vga2,320*(36+(7-1)*12)+(Item.num_frame*11),11,12,225,110);
    put_Sprite(p_sprites,vga2,320*170+40,66,7,200,130);
end;

procedure Title;
var i,j:word;
begin
  cls(0,vga2);
  put_sprite(p_sprites,vga2,100,150,20,75,30);
  volcar_pantalla(vga2,$a000);
  for i:=1 to 40 do espera_vga;
  cls(0,vga2);
end;

function getpixel(mem,x,y:word):byte;
var color:byte;
begin
    asm
     mov es,[mem];
     mov di,x
     mov bx,y
     shl bx,8
     add di,bx
     shr bx,2
     add di,bx
     mov al,es:[di]
     mov color,al
    end;
    getpixel:=color
end;

procedure obtenirKA(var matriu:t_matriu);
var i,j:word;
begin
    for j:=1 to 20 do
     for i:=1 to 36 do
      matriu[i,j]:=getpixel(p_sprites,(139+i-1),j-1);
    for j:=21 to 40 do
     for i:=1 to 36 do
      matriu[i,j]:=0;
end;

procedure BorrarKA(var matriu:t_matriu;var xm,ym,linia,ok:byte);
var i,j,cau:word;
begin
   put_sprite(p_sprites,vga2,100,38,20,75,30);
   put_sprite(p_sprites,vga2,177,73,20,152,30);

   if ym>0 then
   begin
     for cau:=ym+1 to 40 do
     begin
      FOR i:=1 to 36 do
      begin
       {if matriu[i,cau-1]<>0 then
       begin}
        if matriu[i,cau]=0 then
        begin
         matriu[i,cau]:=matriu[i,cau-1];
         matriu[i,cau-1]:=0;
        end;
      end;

      {PINTAR LA MATRIU}
       for j:=1 to 40 do
        for i:=1 to 36 do
         putpixel(i+113,(j-1)+30,matriu[i,j],vga2);

      volcar_pantalla(vga2,$a000);
     end;
     {end;}
   xm:=1;{(xm mod 36)+1;}
   if xm=1 then dec(ym);
   end;
   if ym=0 then ok:=1 else ok:=0;
end;

procedure MoureArNoid(var xAr,xNoid,ok:byte);
begin
   put_sprite(p_sprites,vga2,100,38,20,xAr{75},30);
   put_sprite(p_sprites,vga2,177,73,20,xNoid{152},30);
   dec(xAr);
   inc(xNoid);
   if xAr=55 then ok:=1 else ok:=0;
end;

procedure aspirador(var moviment:word;var ok:byte);
Const BASE_ASPIRADOR_X=0;
      BASE_ASPIRADOR_Y=58;

var bolsa:array[1..4] of word;
    ample,alt:byte;
begin
    bolsa[1]:=110; bolsa[2]:=110+16; bolsa[3]:=110+32; bolsa[4]:=110+64;
     dec(moviment);
     put_sprite(p_sprites,vga2,320*83+109,33,11,BASE_ASPIRADOR_X+moviment,BASE_ASPIRADOR_Y);
     if (moviment mod 2=0) then
      put_sprite(p_sprites,vga2,320*81+89,9,17,BASE_ASPIRADOR_X+8+moviment,BASE_ASPIRADOR_Y-5)
     else put_sprite(p_sprites,vga2,320*81+89+9,9,17,BASE_ASPIRADOR_X+8+moviment,BASE_ASPIRADOR_Y-5);
     put_sprite(p_sprites,vga2,320*94+bolsa[1],16,6,BASE_ASPIRADOR_X+19+moviment,BASE_ASPIRADOR_Y);
    volcar_pantalla(vga2,$a000);
    espera_vga;
    espera_vga;
    for alt:=1 to 20 do
     for ample:=1 to 34 do
      putpixel(Base_ASPIRADOR_X+moviment+(ample-1),Base_ASPIRADOR_Y-5+(alt-1),0,vga2);
    if moviment=150 then ok:=1 else ok:=0;
end;

procedure aspirar(var matriu:t_matriu);
Const BASE_ASPIRADOR_X=0;
      BASE_ASPIRADOR_Y=58;

var moviment:word;
    i,j,x,y,z,esp:byte;
    frame:byte;
    bolsa:array[1..4] of word;
begin
   bolsa[1]:=110; bolsa[2]:=110+16; bolsa[3]:=110+32; bolsa[4]:=110+48;
   {for i:=1 to 4 do
    begin
       put_sprite(p_sprites,vga2,320*94+bolsa[i],16,6,BASE_ASPIRADOR_X+19,BASE_ASPIRADOR_Y);
       for esp:=1 to 10 do espera_vga;
       volcar_pantalla(vga2,$a000);
    end;}
   frame:=0;
   for z:=1 to 20 do
   begin
    inc(frame);
    for y:=40 downto 20 do
    begin
     for x:=1 to 36 do
     begin
      matriu[x,y]:=matriu[x,y-1];
      if matriu[x,y-1]=0 then matriu[x,y]:=0;
     end;
	 {PINTAR LA MATRIU}
     for j:=1 to 40 do
      for i:=1 to 36 do
       putpixel(i+113,(j-1)+30,matriu[i,j],vga2);
     put_sprite(p_sprites,vga2,320*83+109,33,11,BASE_ASPIRADOR_X+150,BASE_ASPIRADOR_Y);
     put_sprite(p_sprites,vga2,320*81+89,9,17,BASE_ASPIRADOR_X+8+150,BASE_ASPIRADOR_Y-5);
     case frame of
      0..4:put_sprite(p_sprites,vga2,320*94+bolsa[1],16,6,BASE_ASPIRADOR_X+19+150,BASE_ASPIRADOR_Y);
      5..9:put_sprite(p_sprites,vga2,320*94+bolsa[2],16,6,BASE_ASPIRADOR_X+19+150,BASE_ASPIRADOR_Y);
      10..14:put_sprite(p_sprites,vga2,320*94+bolsa[3],16,6,BASE_ASPIRADOR_X+19+150,BASE_ASPIRADOR_Y);
      15..20:put_sprite(p_sprites,vga2,320*94+bolsa[4],16,6,BASE_ASPIRADOR_X+19+150,BASE_ASPIRADOR_Y);
     end;
     espera_vga;
     volcar_pantalla(vga2,$a000);
    end;
   end;
end;

procedure anarsen(var moviment:word;var ok:byte);
Const BASE_ASPIRADOR_X=0;
      BASE_ASPIRADOR_Y=58;

var alt,ample:byte;

begin
   put_sprite(p_sprites,vga2,320*83+109,33,11,BASE_ASPIRADOR_X+moviment,BASE_ASPIRADOR_Y);
   if (moviment mod 2=0) then
      put_sprite(p_sprites,vga2,320*81+89,9,17,BASE_ASPIRADOR_X+8+moviment,BASE_ASPIRADOR_Y-5)
     else put_sprite(p_sprites,vga2,320*81+89+9,9,17,BASE_ASPIRADOR_X+8+moviment,BASE_ASPIRADOR_Y-5);
   put_sprite(p_sprites,vga2,320*94+110+48,16,6,BASE_ASPIRADOR_X+19+moviment,BASE_ASPIRADOR_Y);
   espera_vga;
   volcar_pantalla(vga2,$a000);
   for alt:=1 to 20 do
     for ample:=1 to 35 do
      putpixel(Base_ASPIRADOR_X+moviment+(ample-1),Base_ASPIRADOR_Y-5+(alt-1),0,vga2);

   dec(moviment);
   if moviment=0 then ok:=1 else ok:=0;
end;

procedure Hscroll(mem_orig,mem_dest,desp:word);
var x,y:word;
begin
    for y:=0 to 199 do
    begin
     x:=(desp div 2);
     repeat
     if (memw[mem_orig:(320*y)+(x*2)]<>0) or (memw[mem_orig:(320*y)+(x*2)]<>0) then
      memw[mem_dest:(320*y)+319-desp+(x*2)]:=memw[mem_orig:(320*y)+(x*2)];
      if x>0 then dec(x)
     until x=0;
     mem[mem_dest:(320*y)+319-desp+x]:=mem[mem_orig:(320*y)+x];
     x:=319;
     repeat
     if mem[mem_orig:(320*y)+x]<>0 then
      mem[mem_dest:(320*y)+x-desp-1]:=mem[mem_orig:(320*y)+x];
      if x>desp then dec(x)
     until x=desp;
     mem[mem_dest:(320*y)+x-desp-1]:=mem[mem_orig:(320*y)+x];
    end;
end;

procedure intro;
var scr_Stars1,Scr_Stars2:ptr_pantalla;
    Stars1,Stars2:word;
    i,line1,line2:word;
begin
   setup_virtual(scr_Stars1,Stars1);
   setup_virtual(scr_Stars2,Stars2);
   cls(0,Stars1);cls(0,Stars2);
   for i:=1 to 100 do mem[Stars1:random(63999)]:=215;
   for i:=1 to 100 do mem[Stars2:random(63999)]:=129;
   line1:=0;line2:=0;
   repeat
    cls(0,vga2);
    Hscroll(Stars1,vga2,line1);
    Hscroll(Stars2,vga2,line2);
    pinta_cadena(vga2,'Va haver un temps en el que els jailers estaven acabant la seua',p_sprites,320*70+100,0,40,5);
    pinta_cadena(vga2,'carrera, la jail estaria perduda sense una resistencia que fera',p_sprites,320*70+100,0,47,5);
    pinta_cadena(vga2,'front a  Usufons i Brindys es devia  designar uns nous jailers',p_sprites,320*70+100,0,54,5);
    putpixel(312,58,173,vga2);
    pinta_cadena(vga2,'Per poder ser jailers deurien  passar unes  proves molt dures i',p_sprites,320*70+100,0,61,5);
    pinta_cadena(vga2,'una era passar',p_sprites,320*70+100,0,68,5);
    putpixel(70,70,173,vga2);
    putpixel(71,70,173,vga2);
    putpixel(72,70,173,vga2);
    pinta_cadena(vga2,'se el',p_sprites,320*70+100,75,68,5);
    putpixel(100,72,173,vga2);
    putpixel(103,72,173,vga2);
    putpixel(106,72,173,vga2);
    volcar_pantalla(vga2,$a000);
    inc(line1,2);
    inc(line2);
    line1:=line1 mod 320;
    line2:=line2 mod 320;
   until teclapuls(keyenter);
   borrarkb;
   tancar_virtual(scr_Stars1);
   tancar_virtual(scr_Stars2);
end;

{___________________________________________________________}

function byte2char(lletra:byte):char;
begin
   case lletra of
    keya:byte2char:='A';
    keyb:byte2char:='B';
    keyc:byte2char:='C';
    keyd:byte2char:='D';
    keye:byte2char:='E';
    keyf:byte2char:='F';
    keyg:byte2char:='G';
    keyh:byte2char:='H';
    keyi:byte2char:='I';
    keyj:byte2char:='J';
    keyk:byte2char:='K';
    keyl:byte2char:='L';
	 keym:byte2char:='M';
    keyn:byte2char:='N';
    keyo:byte2char:='O';
    keyp:byte2char:='P';
    keyq:byte2char:='Q';
    keyr:byte2char:='R';
    keys:byte2char:='S';
    keyt:byte2char:='T';
    keyu:byte2char:='U';
    keyv:byte2char:='V';
    keyw:byte2char:='W';
    keyx:byte2char:='X';
    keyy:byte2char:='Y';
    keyz:byte2char:='Z';
    keyspace:byte2char:=' ';
  else byte2char:=';';
  end;
end;

procedure obtindre_nom(var cadena:t_nom;var pos:byte);
var tecla:byte;
    i:byte;

begin
   if qteclapuls then
   begin
	 tecla:=agarrartecla;
    if byte2char(tecla)<>';' then
    begin
     cadena[pos]:=byte2char(tecla);
     inc(pos);
	  if pos>7 then pos:=7;
    end;
   end;
   case tecla of
    keybackspace:begin dec(pos);if pos<1 then pos:=1;end;
   end;
   for i:=1 to 7 do espera_vga;
end;

procedure indica_lletra(pos:byte;ranking:byte);
var x,y,i:word;
begin
   case pos of
    1:x:=59;
    2:x:=64;
    3:x:=69;
    4:x:=74;
    5:x:=79;
    6:x:=84;
    7:x:=89;
    8:x:=94;
   end;
   case ranking of
    1:y:=55;
    2:y:=70;
    3:y:=85;
    4:y:=100;
    5:y:=115;
    6:y:=130;
    7:y:=145;
    8:y:=160;
    9:y:=175;
   10:y:=190;
   end;
   for i:=0 to 3 do putpixel(x+i,y,3,vga2);
end;

procedure seleccionar_fila_per_escriure(ranking:byte;var y:word);
begin
   case ranking of
    1:y:=60;
    2:y:=75;
    3:y:=90;
    4:y:=105;
    5:y:=120;
    6:y:=135;
    7:y:=150;
    8:y:=165;
    9:y:=180;
   10:y:=195;
   end;
end;

procedure test_fitxer_hi;
var f:file of t_puntuacio;
    records:t_puntuacio;
begin
  assign(f, 'hiscore.dat');
  {$I-}
  reset(f);
  {$I+}
  if ioresult <> 0 then
  begin
   assign(f, 'hiscore.dat');
   rewrite(f);
   records.pos:=1;
   records.punts:=5120;
   records.nom:='AAAAAAA';
   while records.pos<=MAX_HISCORES do
   begin
     write(f,records);
     inc(records.pos);
     records.punts:=records.punts div 2;
   end;
   close(f);
  end
  else close(f);
end;

procedure llegir_fitxer_hi(var taula:t_taula_records);
var f:file of t_puntuacio;
    records:t_puntuacio;

begin
   assign(f,'hiscore.dat');
   reset(f);
   while (not EOF(f)) do
   begin
     read(f,records);
     taula[records.pos]:=records;
   end;
   close(f);
end;

procedure actualitza_fitxer_hi(nous_records:t_taula_records);
var count:byte;
    f:file of t_puntuacio;
begin
   count:=1;
   assign(f,'hiscore.dat');
   rewrite(f);
   while count<=MAX_HISCORES do
   begin
     write(f,nous_records[count]);
     inc(count);
   end;
   close(f);
end;

procedure actualitza_taula_records(punts:word;var taula:t_taula_records;var ranking:byte);
var i,num:byte;
    menor:boolean;
begin
    {busquem la posicio de ranking}
    i:=0;
    repeat
     inc(i);
     menor:=punts<taula[i].punts
    until (menor=false) or (i=MAX_HISCORES);
    if menor=true then inc(i);
    ranking:=i;

    {actualitzar taula records}
    if ranking<=MAX_HISCORES then
     if ranking=MAX_HISCORES then
      begin
       taula[MAX_HISCORES].punts:=punts;
       taula[MAX_HISCORES].nom:='       ';
      end
     else for i:=MAX_HISCORES-1 downto ranking do
     begin
      taula[i+1].nom:=taula[i].nom;
      taula[i+1].punts:=taula[i].punts;
      if i=ranking then taula[i].nom:='       ';
     end;
    if ranking<=MAX_HISCORES-1 then taula[ranking].punts:=punts;
end;

procedure pinta_puntuacio(punts,fila,vaddr:word);
var mdec,muni,cent,dec,uni:byte;

begin
   mdec:=punts div 10000;
   muni:=(punts mod 10000) div 1000;
   cent:=((punts mod 10000) mod 1000) div 100;
   dec:=(((punts mod 10000) mod 1000) mod 100) div 10;
   uni:=(((punts mod 10000) mod 1000) mod 100) mod 10;
   pinta2(vga2,vaddr,100,120,7,mdec,190,fila-11);
   pinta2(vga2,vaddr,100,120,7,muni,197,fila-11);
   pinta2(vga2,vaddr,100,120,7,cent,197+7,fila-11);
   pinta2(vga2,vaddr,100,120,7,dec,197+14,fila-11);
   pinta2(vga2,vaddr,100,120,7,uni,197+21,fila-11);
end;

function numero2word(punts:t_numero):word;
begin
   numero2word:=punts.ddec*10000+punts.duni*1000+punts.cent*100+punts.dec*10+punts.uni;
end;

{컴컴컴컴컴컴컴컴컴컴컴횲UNCIO횾RINCIPAL컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�}
var noid:t_bandeja;
    bala:t_bala;
    t1,t2:word;
    frames:longint;
    existeix_taulell,error_mapa,auto,num_fase,max_fase,linia:byte;
    puntuacio:t_numero;
    KA:t_matriu;
    xm,ym,ok:byte;
    i,j,moviment:word;

procedure hi_score(puntuacio:t_numero);
var pos,rank,i:byte;
    taula_records:t_taula_records;
    punts,pos_y:word;
begin
    randomize;
    cls(0,vga2);
    punts:=numero2word(puntuacio);
    pos:=1;{posicio del cursor}
    test_fitxer_hi;
    llegir_fitxer_hi(taula_records);
    actualitza_taula_records(punts,taula_records,rank);
    repeat
     put_sprite(p_sprites,vga2,320*100+90,168,18,70,10);
     if rank<=MAX_HISCORES then
     begin
       obtindre_nom(taula_records[rank].nom,pos);
       indica_lletra(pos,taula_records[rank].pos);
     end;

     for i:=1 to MAX_HISCORES do
     begin
      seleccionar_fila_per_escriure(taula_records[i].pos,pos_y);
      pinta_cadena(vga2,taula_records[i].nom,p_sprites,320*70+100,60,pos_y-11,5);
      pinta_puntuacio(taula_records[i].punts,pos_y,p_sprites);
     end;

     volcar_pantalla(vga2,$a000);
     cls(0,vga2);
    until teclapuls(keyenter);
    actualitza_fitxer_hi(taula_records);
end;

procedure PushClock;
begin
   pila.retard:=retard;
   pila.temps:=temps;
   pila.flag_time:=flag_time;
   pila.time_velocitat:=time_velocitat;
end;

procedure PopClock;
begin
   retard:=pila.retard;
   temps:=pila.temps;
   flag_time:=pila.flag_time;
   time_velocitat:=pila.time_velocitat;
end;

procedure pausa;

procedure pintaZ(num_vides,dormir:byte);
var i,j,x:byte;
begin
  j:=0;x:=1;
  if num_vides>1 then
   for i:=1 to num_vides-1 do
   begin
     if x>3 then begin inc(j);x:=1; end;
     put_sprite(p_sprites,vga2,320*7+(74)+(5*(dormir)),5,7,267+((x-1)*10),43+(j*10));
     inc(x);
   end;
end;

const DELAY=15;
var dormir:byte;
    count:byte;
begin
   PushClock;
   pause:=true;
   dormir:=0;
   count:=0;
   repeat
    cls(0,vga2);
    pintamapa;
    pintaitems(mapaitems,map);
    pintabola(bola);
    pintafront;
    Mostrarpuntuacio(puntuacio);
    if count=DELAY then begin inc(dormir);count:=0;dormir:=dormir mod 4;end;
    put_sprite(p_sprites,vga2,320*80+(180)+(21*(dormir)),21,20,noid.x,165);
    pintaZ(noid.vides,dormir);
    espera_vga;
    inc(count);
    volcar_pantalla(vga2,$a000);
   until teclapuls(keyp);
   PopClock;
   pause:=false;
end;

procedure brindys;
var tecla:char;
    i:byte;
begin
   PushClock;
   pause:=true;
   setmode($3);
   write('C:\>');
   repeat
   if qteclapuls then
   begin
	 tecla:=byte2char(Agarrartecla);
    write(tecla);
    for i:=1 to 7 do espera_vga;
   end;
	until teclapuls(keyf12);
   setmode($13);
   set_paleta(paleta);
   PopClock;
   pause:=false;
end;

procedure presentacio;
var adeu:byte;
begin
   adeu:=0;
   title;
   obtenirka(KA);
   xm:=1;ym:=20;
   repeat
    borrarka(KA,xm,ym,linia,ok);
    volcar_pantalla(vga2,$a000);
   until (teclapuls(keyesc)) or (ok=1);
   if teclapuls(keyesc) then adeu:=1 else adeu:=0;
   moviment:=280;
   if adeu=0 then
   repeat
    aspirador(moviment,ok);
   until (teclapuls(keyesc)) or (ok=1);
   if teclapuls(keyesc) and (adeu=0) then adeu:=1 else adeu:=0;
   if not(teclapuls(keyesc)) and (adeu=0) then aspirar(KA);
   moviment:=150;
   if adeu=0 then
   repeat
    anarsen(moviment,ok);
   until (teclapuls(keyesc)) or (ok=1);
   if teclapuls(keyesc) and (adeu=0) then adeu:=1 else adeu:=0;
   cls(0,vga2);
   xm:=75;
   ym:=152;
   if adeu=0 then
   repeat
    cls(0,vga2);
    moureArNoid(xm,ym,ok);
    espera_vga;
    volcar_pantalla(vga2,$a000);
   until (teclapuls(keyesc)) or (ok=1);
   time2pageitems:=182;
   repeat
    cls(0,vga2);
    put_sprite(p_sprites,vga2,100,38,20,55,30);
    put_sprite(p_sprites,vga2,177,73,20,172,30);
    put_sprite(p_sprites,vga2,320*22+101,69,19,97,30);
    put_sprite(p_sprites,vga2,320*20+170,140,8,80,120);
    put_sprite(p_sprites,vga2,320*40+170,74,10,10,180);
    put_sprite(p_sprites,vga2,320*50+100,185,10,100,180);
    volcar_pantalla(vga2,$a000);
    cls(0,vga2);
    if time2pageitems=0 then
    begin
     time2pageitems:=110;
     SavePalette;
     repeat
      showpageitems(count);
	   volcar_pantalla(vga2,$a000);
	  until (qteclapuls) or (time2pageitems=0);
     time2pageitems:=182;
     RestorePalette;
    end;
	until teclapuls(keyenter);
end;

procedure del(fitxer:string);
var f:file;
begin
    assign(f,fitxer);
    erase(f);
end;

begin
   setclock;
   DesCompresioJGC('fase.jgc','fase.map');
   num_fase:=1;
   linia:=0;
   mort:=0;
   auto:=0;
   initnoid(noid,3);
   initbola(bola);
   initbala(bala);
   initpuntuacio(puntuacio);
   retard:=0;
   frame_vides:=0;
	setmode($13);
   instalarkb;
   setup_virtual(scr_front,p_front);
   setup_virtual(scr_sprites,p_sprites);
   setup_virtual(scr_back,p_back);
   setup_virtual(buffer,vga2);
   cls(0,p_back);
   cls(0,p_front);
   cls(0,p_sprites);
   Load_Pcx('sprites.pcx',p_sprites);
   Load_Pcx('front.pcx',p_front);
   get_paleta(paleta);
   frames:=0;
   t1:=gettemps;
   max_fase:=CalcularMaxFases('fase.map');
   count:=0;
   {==

   {==}
repeat
  intro;
  presentacio;
{}repeat
   pause:=false;
   Makefondo(num_fase);
   error_mapa:=LoadMap('fase.map',map,passarfase(num_fase));
   CreaMapaItems(MapaItems,map);
   time_velocitat:=1024; {1024 / 18(int del rellotge)=57 quasi 1 min}
   Flag_time:=0;         {Sols incrementarem 2 vegades la velocitat(mirar clock)}
   repeat
      existeix_taulell:=Buscartaulells(map);
      if teclapuls(keyp) then
      begin
       borrarkb;
		 pausa;
       borrarkb
      end;
      if teclapuls(keyf12) then
      begin
       borrarkb;
		 brindys;
       borrarkb
      end;
      mounoid(noid,bola.pegada,bala);
      if (teclapuls(key0)) or (noid.tipo=5) then auto:=1 else auto:=0;
      if (teclapuls(keyarrowleft)) or (teclapuls(keyarrowright)) then auto:=0;
      if auto=1 then MouNoidAuto(noid,bola);
      moubola(bola,noid,puntuacio);
      moubala(bala,puntuacio);
      volcar_pantalla(p_back,vga2);
      AgarrarItem(MapaItems,noid,bola,puntuacio);
      pintamapa;
      pintaitems(mapaitems,map);
      pintanoid(noid);
      pintabola(bola);
      if bala.existeix=1 then pintabala(bala);
		pintafront;
      Mostrarpuntuacio(puntuacio);
      if bola.y>=180 then mort:=1;
      if mort=0 then pintavides(noid.vides,frame_vides)
      else
      begin
       bala.existeix:=0;
       frame_vides:=0;
       temps:=35;
       EliminarItemActiu(MapaItems);
       repeat
        pintamapa;
        pintanoid(noid);
        pintabola(bola);
        pintafront;
        pintamort(noid.vides,frame_vides);
        Mostrarpuntuacio(puntuacio);
        volcar_pantalla(vga2,$a000);
        inc(frames);
		 until temps=0;
       frame_vides:=1;
       retard:=0;
       initnoid(noid,noid.vides-1);
       initbola(bola);
       repeat until not teclapuls(keyspace);
       time_velocitat:=1024;
       Flag_time:=0;
      end;
      espera_vga;
      volcar_pantalla(vga2,$a000);
      cls(0,vga2);
      inc(frames);
   until (teclapuls(keyesc)) or (noid.vides=0) or (existeix_taulell=0) or (error_mapa=0);
   if noid.vides>0 then
   begin
     if not teclapuls(keyesc) then
     begin
	   disolve(0,1);
      inc(num_fase);
     end;
     EliminarItems(MapaItems);
     cls(0,vga2);
     initnoid(noid,noid.vides);
     initbola(bola);
   end;
  until (teclapuls(keyesc)) or (error_mapa=0) or (num_fase>max_fase) or (noid.vides=0);
  if num_fase>max_fase then
  begin
   cls(0,vga2);
   put_sprite(p_sprites,vga2,320*130+100,183,20,70,90);
   volcar_pantalla(vga2,$a000);
   repeat until qteclapuls;
   hi_score(puntuacio);
  end;
  if noid.vides=0 then
   begin
     EliminarItems(MapaItems);
     disolve(0,1);
     hi_score(puntuacio);
     num_fase:=1;
     mort:=0;
     auto:=0;
     initnoid(noid,3);
     initbola(bola);
     initbala(bala);
     initpuntuacio(puntuacio);
     retard:=0;
     frame_vides:=0;
   end;
until (teclapuls(keyesc));
   if teclapuls(keyesc) then melt(0);
   t2:=gettemps-t1;{}
   tancar_virtual(scr_front);
   tancar_virtual(scr_sprites);
   tancar_virtual(scr_back);
   setmode($3);
   borrarfitxermapa;
   desinstalarkb;
   restoreclock;
   del('fase.map');
   {writeln('Max Fases = ',calcularMaxfases('fase.map'));}
   {writeln('FPS = ',(frames/(t2/100)):10:2);}
end.