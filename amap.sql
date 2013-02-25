set serveroutput on
SET VERIFY OFF

declare
getops   varchar2(100);

begin

getops := '&1';

if (getops = 'list') then

dbms_output.put_line('== ASM FILE ALIAS LIST ==');

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

dbms_output.put_line('NAME: ' || asm_files.aname || '  [DG=+'||asm_files.gname||';FN='||asm_files.file_number||';GN='|| asm_files.group_number || ']');

END LOOP; 

ELSE


dbms_output.put_line('[GROUP_NUMBER ; DISKNUMBER ; FILENUMBER ; FILE_EXTENT_NUMBER ; RELATIVE_AU_POS]'); 

for asm_ext IN (
select distinct GROUP_KFFXP,DISK_KFFXP,NUMBER_KFFXP,XNUM_KFFXP,DECODE(LXN_KFFXP, '0', 'PRIMARY EXTENT', '1', 'MIRROR EXTENT','2', '2ND MIRROR EXTENT') EXTP, AU_KFFXP  
from x$kffxp
where number_kffxp=(select file_number from v$asm_alias where name=getops)     
and GROUP_KFFXP=(select group_number from v$asm_alias where name=getops)           
order by NUMBER_KFFXP, AU_KFFXP)

LOOP
dbms_output.put_line('[' || asm_ext.GROUP_KFFXP || ' ; ' || asm_ext.DISK_KFFXP || ' ; ' || asm_ext.NUMBER_KFFXP || ' ; ' || asm_ext.XNUM_KFFXP || ' ; ' || asm_ext.EXTP || ' ; ' || asm_ext.AU_KFFXP || ']');

END LOOP;

END IF;

end;
/