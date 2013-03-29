--
--
--    _     _      _     _      _     _      _     _   
--   (c).-.(c)    (c).-.(c)    (c).-.(c)    (c).-.(c)  
--    / ._. \      / ._. \      / ._. \      / ._. \   
--  __\( Y )/__  __\( Y )/__  __\( Y )/__  __\( Y )/__ 
-- (_.-/'-'\-._)(_.-/'-'\-._)(_.-/'-'\-._)(_.-/'-'\-._)
--    || A ||      || M ||      || A ||      || P ||   
--  _.' `-' '._  _.' `-' '._  _.' `-' '._  _.' `-' '._ 
-- (.-./`-'\.-.)(.-./`-'\.-.)(.-./`-'\.-.)(.-./`-'\.-.)
--  `-'     `-'  `-'     `-'  `-'     `-'  `-'     `-' 
-- AMAP - ASM Mapping Utility v0.3.1
-- Author: Luis Marques (lcarapinha@gmail)
-- Website: http://lcmarques.com
-- Twitter: @drune
-- Based on Lucas Canali work on ASM internals

-- USAGE: @amap list DGNAME
--        @amap free DGNAME
-- 	      @amap ASMFILENAME
--        @amap metadata DGNAME


set serveroutput on format wrapped
SET VERIFY OFF
SET FEEDBACK OFF
set pagesize 0
set linesize 9999


declare

getops   varchar2(50) := '';
getops2  varchar(50) := '';

begin

getops := '&1';
getops2 := '&2';

if (getops = 'metadata') then

DBMS_OUTPUT.put_line('DISKNUMBER FILENUMBER FILE EXTENT NUMBER          METADATA DESC         EXTENT MIRRORING RELATIVE AU POSITION');
DBMS_OUTPUT.put_line('---------- ---------- ------------------ ------------------------------ ---------------- --------------------');
	
FOR asm_meta IN (
select distinct 
ff.DISK_KFFXP,
ff.NUMBER_KFFXP,
ff.XNUM_KFFXP,
DECODE(ff.NUMBER_KFFXP, '1', 'FILE DIRECTORY',
					  '2', 'DISK DIRECTORY',
					  '3', 'ACTIVE CHG DIRECTORY (ACD)',
					  '4', 'CONT OPERATION DIR (COD)',
					  '5', 'TEMPLATE DIRECTORY',
					  '6', 'ALIAS DIRECTORY',
					  '9', 'ATTRIBUTE DIRECTORY',
					  '12', 'STALENESS REGISTRY',
					  '253', 'ASM SPFILE',
					  '254', 'STALENESS REGISTRY',
					  '255', 'OCR FILE ASM',
					  'UNKNOW') META_DESC,
DECODE(ff.LXN_KFFXP, '0', 'PRIMARY EXT', '1', '1st MIRROR EXT','2', '2nd MIRROR EXT') EXTP, 
ff.AU_KFFXP
from x$kffxp ff, x$kffil fi
where ff.NUMBER_KFFXP = fi.number_kffil
and ff.GROUP_KFFXP = fi.group_kffil
and ff.GROUP_KFFXP = (select distinct group_number from V$ASM_DISKGROUP where name=getops2)
and number_kffxp < 256
)

LOOP

dbms_output.put_line(lpad(asm_meta.DISK_KFFXP, 10)  || ' ' ||  rpad(asm_meta.NUMBER_KFFXP,10) || ' ' || rpad(asm_meta.XNUM_KFFXP,18) || ' ' || rpad(asm_meta.META_DESC,30) || ' ' || rpad(asm_meta.extp,16) || ' ' || rpad(asm_meta.au_kffxp,20));


END LOOP;


elsif (getops = 'free') then
	 
      DBMS_OUTPUT.put_line('     DISKGROUP       DISKNUMBER AU STATUS   AU COUNT  ');
  	  DBMS_OUTPUT.put_line('-------------------- ---------- --------- ------------');

	  if (getops2 = '*') then

		FOR free_au IN (
		select a.name, number_kfdat, decode(v_kfdat, 'V', 'USED AU', 'FREE AU') as status_au, count(*) as num_au
			from x$kfdat d, v$asm_diskgroup a
			where d.group_kfdat = a.group_number
			group by a.name, number_kfdat, v_kfdat)


			LOOP
    dbms_output.put_line(lpad(free_au.name, 20) || ' ' ||  rpad(free_au.number_kfdat, 10)  || ' ' ||  rpad(free_au.status_au,9) || ' ' || rpad(free_au.num_au,12));
        		END LOOP;
	else
		FOR free_au IN (
                select a.name, number_kfdat, decode(v_kfdat, 'V','USED AU','FREE AU') as status_au , count(*) as num_au
                        from x$kfdat d, v$asm_diskgroup a
                        where d.group_kfdat = a.group_number
			and a.name = getops2
                        group by a.name, number_kfdat, v_kfdat)

	
			LOOP

  dbms_output.put_line(lpad(free_au.name, 20) || ' ' ||  rpad(free_au.number_kfdat, 10)  || ' ' ||  rpad(free_au.status_au,9) || ' ' || rpad(free_au.num_au,12));
			END LOOP;  

	END IF;

elsif (getops = 'list')  then
	  
	  DBMS_OUTPUT.put_line('     ASM FILE NAME                   DISKGROUP      FILENUMBER GROUPNUMBER');
          DBMS_OUTPUT.put_line('------------------------------ -------------------- ---------- ------------');


	if (getops2 = '*') then

	FOR asm_files IN (
		SELECT file_number, aname, dir, gname, group_number   
		FROM (
 			SELECT file_number, aname, dir, gname, group_number 
 			FROM (
			  SELECT g.name gname, 
			   a.group_number,
			   a.parent_index pindex,
			   a.file_number, 
			   a.name aname,
			   a.reference_index rindex, 
			   a.alias_directory dir, 
 			  a.system_created sys 
			  FROM v$asm_alias a, v$asm_diskgroup g 
 			 WHERE a.group_number = g.group_number
 				 )
		 where dir = 'N'
 			START WITH (mod(pindex, power(2, 24))) = 0
 CONNECT BY PRIOR rindex = pindex
 ORDER BY dir desc)
)
LOOP


dbms_output.put_line(lpad(asm_files.aname, 30) || ' ' ||  rpad(asm_files.gname, 20)  || ' ' ||  rpad(asm_files.file_number,10) || ' ' || rpad(asm_files.group_number,12));

END LOOP; 

ELSE 

FOR asm_files IN (
SELECT file_number, aname, dir, gname, group_number   
FROM (
 SELECT file_number, aname, dir, gname, group_number 
 FROM (
  SELECT g.name gname, 
   a.group_number,
   a.parent_index pindex,
   a.file_number, 
   a.name aname,
   a.reference_index rindex, 
   a.alias_directory dir, 
   a.system_created sys 
  FROM v$asm_alias a, v$asm_diskgroup g 
  WHERE a.group_number = g.group_number 
  )
 where dir = 'N'
 and gname = getops2
 START WITH (mod(pindex, power(2, 24))) = 0
 CONNECT BY PRIOR rindex = pindex
 ORDER BY dir desc)
)

LOOP
dbms_output.put_line(lpad(asm_files.aname, 30) || ' ' ||  rpad(asm_files.gname, 20)  || ' ' ||  rpad(asm_files.file_number,10) || ' ' || rpad(asm_files.group_number,12));

END LOOP;

END IF;


ELSE

DBMS_OUTPUT.put_line('GROUPNUMBER DISKNUMBER FILENUMBER FILE EXTENT NUMBER EXTENT MIRRORING RELATIVE AU POSITION');
DBMS_OUTPUT.put_line('----------- ---------- ---------- ------------------ ---------------- --------------------');
DBMS_OUTPUT.ENABLE(200000);

for asm_ext IN (
select distinct GROUP_KFFXP,DISK_KFFXP,NUMBER_KFFXP,XNUM_KFFXP,DECODE(LXN_KFFXP, '0', 'PRIMARY EXT', '1', '1st MIRROR EXT','2', '2nd MIRROR EXT') EXTP, AU_KFFXP  
from x$kffxp
where number_kffxp=(select file_number from v$asm_alias where name=getops)     
and GROUP_KFFXP=(select group_number from v$asm_alias where name=getops)           
order by NUMBER_KFFXP, AU_KFFXP)

LOOP


dbms_output.put_line(lpad(asm_ext.GROUP_KFFXP, 11) || ' ' ||  rpad(asm_ext.DISK_KFFXP, 10)  || ' ' ||  rpad(asm_ext.NUMBER_KFFXP,10) || ' ' || rpad(asm_ext.XNUM_KFFXP,18) || ' ' ||rpad(asm_ext.extp,16) || ' ' || rpad(asm_ext.au_kffxp,20));


END LOOP;

END IF;

end;
/
