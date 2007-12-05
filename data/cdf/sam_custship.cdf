[[SAM_CUSTSHIP.AOPT-SALU]]
rem -- call inquiry program to view Sales Analysis records

syspgmdir$=stbl("+DIR_SYP",err=*next)

key_pfx$=firm_id$
if cvs(callpoint!.getColumnData("SAM_CUSTSHIP.YEAR"),2) <>"" then
	key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_CUSTSHIP.YEAR")
	if cvs(callpoint!.getColumnData("SAM_CUSTSHIP.CUSTOMER_ID"),2) <>"" then
		key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_CUSTSHIP.CUSTOMER_ID")
		if cvs(callpoint!.getColumnData("SAM_CUSTSHIP.SHIPTO_NO"),2) <>"" then
			key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_CUSTSHIP.SHIPTO_NO")
			if cvs(callpoint!.getColumnData("SAM_CUSTSHIP.ITEM_ID"),2) <>"" then
				key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_CUSTSHIP.ITEM_ID")
			endif
		endif
	endif
endif

call syspgmdir$+"bac_key_template.bbj","SAM_CUSTSHIP","PRIMARY",key_temp$,table_chans$[all],rd_stat$
dim rd_key$:key_temp$
call syspgmdir$+"bam_inquiry.bbj",
:	gui_dev,
:	Form!,
:	"SAM_CUSTSHIP",
:	"LOOKUP",
:	table_chans$[all],
:	key_pfx$,
:	"PRIMARY",
:	rd_key$

rem --- get record and redisplay

sam_tpl$=fnget_tpl$("SAM_CUSTSHIP")
dim sam_tpl$:sam_tpl$
while 1
	readrecord(fnget_dev("SAM_CUSTSHIP"),key=rd_key$,dom=*break)sam_tpl$
	callpoint!.setColumnData("SAM_CUSTSHIP.YEAR",rd_key.year$)
	callpoint!.setColumnData("SAM_CUSTSHIP.CUSTOMER_ID",rd_key.customer_id$)
	callpoint!.setColumnData("SAM_CUSTSHIP.SHIPTO_NO",rd_key.shipto_no$)
	callpoint!.setColumnData("SAM_CUSTSHIP.ITEM_ID",rd_key.item_id$)
	For x=1 to 13
		callpoint!.setColumnData("SAM_CUSTSHIP.QTY_SHIPPED_"+str(x:"00"),FIELD(sam_tpl$,"qty_shipped_"+str(x:"00")))
		callpoint!.setColumnData("SAM_CUSTSHIP.TOTAL_COST_"+str(x:"00"),FIELD(sam_tpl$,"total_cost_"+str(x:"00")))
		callpoint!.setColumnData("SAM_CUSTSHIP.TOTAL_SALES_"+str(x:"00"),FIELD(sam_tpl$,"total_sales_"+str(x:"00")))
	next x
	callpoint!.setStatus("REFRESH")
	break
wend
