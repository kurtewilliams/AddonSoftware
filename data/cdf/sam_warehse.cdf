[[SAM_WAREHSE.ARAR]]
rem --- Create totals

	gosub calc_totals
[[SAM_WAREHSE.AREC]]
rem --- Enable key fields
	ctl_name$="SAM_WAREHSE.YEAR"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_WAREHSE.WAREHOUSE_ID"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_WAREHSE.PRODUCT_TYPE"
	ctl_stat$=""
	gosub disable_fields
	ctl_name$="SAM_WAREHSE.ITEM_ID"
	ctl_stat$=""
	gosub disable_fields
	callpoint!.setColumnData("<<DISPLAY>>.TCST","0")
	callpoint!.setColumnData("<<DISPLAY>>.TQTY","0")
	callpoint!.setColumnData("<<DISPLAY>>.TSLS","0")
	callpoint!.setStatus("REFRESH")
[[SAM_WAREHSE.BSHO]]
rem --- disable total elements
	ctl_name$="<<DISPLAY>>.TQTY"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="<<DISPLAY>>.TCST"
	ctl_stat$="I"
	gosub disable_fields
	ctl_name$="<<DISPLAY>>.TSLS"
	ctl_stat$="I"
	gosub disable_fields
	callpoint!.setStatus("ABLEMAP-ACTIVATE-REFRESH")
[[SAM_WAREHSE.<CUSTOM>]]
disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable

	wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
	wmap$=callpoint!.getAbleMap()
	wpos=pos(wctl$=wmap$,8)
	wmap$(wpos+6,1)=ctl_stat$
	callpoint!.setAbleMap(wmap$)

	return

calc_totals:
	
	tcst=0
	tqty=0
	tsls=0
	For x=1 to 13
		tcst=tcst+num(callpoint!.getColumnData("SAM_WAREHSE.TOTAL_COST_"+str(x:"00")))
		tqty=tqty+num(callpoint!.getColumnData("SAM_WAREHSE.QTY_SHIPPED_"+str(x:"00")))
		tsls=tsls+num(callpoint!.getColumnData("SAM_WAREHSE.TOTAL_SALES_"+str(x:"00")))
	next x
	callpoint!.setColumnData("<<DISPLAY>>.TCST",str(tcst))
	callpoint!.setColumnData("<<DISPLAY>>.TQTY",str(tqty))
	callpoint!.setColumnData("<<DISPLAY>>.TSLS",str(tsls))
	callpoint!.setStatus("REFRESH")

	return
[[SAM_WAREHSE.AOPT-SALU]]
rem -- call inquiry program to view Sales Analysis records

syspgmdir$=stbl("+DIR_SYP",err=*next)

key_pfx$=firm_id$
if cvs(callpoint!.getColumnData("SAM_WAREHSE.YEAR"),2) <>"" then
	key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_WAREHSE.YEAR")
	if cvs(callpoint!.getColumnData("SAM_WAREHSE.WAREHOUSE_ID"),2) <>"" then
		key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_WAREHSE.WAREHOUSE_ID")
		if cvs(callpoint!.getColumnData("SAM_WAREHSE.PRODUCT_TYPE"),2) <>"" then
			key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_WAREHSE.PRODUCT_TYPE")
			if cvs(callpoint!.getColumnData("SAM_WAREHSE.ITEM_ID"),2) <>"" then
				key_pfx$=key_pfx$+callpoint!.getColumnData("SAM_WAREHSE.ITEM_ID")
			endif
		endif
	endif
endif

call syspgmdir$+"bac_key_template.bbj","SAM_WAREHSE","PRIMARY",key_temp$,table_chans$[all],rd_stat$
dim rd_key$:key_temp$
call syspgmdir$+"bam_inquiry.bbj",
:	gui_dev,
:	Form!,
:	"SAM_WAREHSE",
:	"LOOKUP",
:	table_chans$[all],
:	key_pfx$,
:	"PRIMARY",
:	rd_key$

rem --- get record and redisplay

sam_tpl$=fnget_tpl$("SAM_WAREHSE")
dim sam_tpl$:sam_tpl$
while 1
	readrecord(fnget_dev("SAM_WAREHSE"),key=rd_key$,dom=*break)sam_tpl$
	callpoint!.setColumnData("SAM_WAREHSE.YEAR",rd_key.year$)
	callpoint!.setColumnData("SAM_WAREHSE.WAREHOUSE_ID",rd_key.warehouse_id$)
	callpoint!.setColumnData("SAM_WAREHSE.PRODUCT_TYPE",rd_key.product_type$)
	callpoint!.setColumnData("SAM_WAREHSE.ITEM_ID",rd_key.item_id$)
	For x=1 to 13
		callpoint!.setColumnData("SAM_WAREHSE.QTY_SHIPPED_"+str(x:"00"),FIELD(sam_tpl$,"qty_shipped_"+str(x:"00")))
		callpoint!.setColumnData("SAM_WAREHSE.TOTAL_COST_"+str(x:"00"),FIELD(sam_tpl$,"total_cost_"+str(x:"00")))
		callpoint!.setColumnData("SAM_WAREHSE.TOTAL_SALES_"+str(x:"00"),FIELD(sam_tpl$,"total_sales_"+str(x:"00")))
	next x
	gosub calc_totals
	ctl_name$="SAM_WAREHSE.YEAR"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="SAM_WAREHSE.WAREHOUSE_ID"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="SAM_WAREHSE.PRODUCT_TYPE"
	ctl_stat$="D"
	gosub disable_fields
	ctl_name$="SAM_WAREHSE.ITEM_ID"
	ctl_stat$="D"
	gosub disable_fields
	callpoint!.setRecordStatus("CLEAR")
	callpoint!.setStatus("ABLEMAP-ACTIVATE-REFRESH")
	break
wend
