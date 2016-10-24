[[ARE_INVDET.GL_ACCOUNT.AVAL]]
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*break) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
[[ARE_INVDET.GL_ACCOUNT.BINP]]
rem --- pre-fill with gl sales account for the distribution code

if user_tpl.glint$="Y"

	this_row = callpoint!.getValidationRow()

	if this_row=0 and cvs(callpoint!.getColumnData("ARE_INVDET.GL_ACCOUNT"),3)=""
		dflt_gl_account$ = callpoint!.getDevObject("dflt_gl_account")
		callpoint!.setColumnData("ARE_INVDET.GL_ACCOUNT",dflt_gl_account$)
		callpoint!.setStatus("MODIFIED-REFRESH:ARE_INVDET.GL_ACCOUNT")
	endif

endif
[[ARE_INVDET.AGCL]]
rem --- set preset val for batch_no
callpoint!.setTableColumnAttribute("ARE_INVDET.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[ARE_INVDET.AUDE]]
rem --- after deleting a row from detail grid, recalc/redisplay balance left to distribute
gosub calc_grid_tots
gosub disp_totals
[[ARE_INVDET.ADEL]]
rem --- after deleting a row from detail grid, recalc/redisplay balance left to distribute
gosub calc_grid_tots
gosub disp_totals
[[ARE_INVDET.UNITS.AVAL]]
newqty=num(callpoint!.getUserInput())                       
unit_price=num(callpoint!.getColumnData("ARE_INVDET.UNIT_PRICE"))               
new_ext_price=newqty*unit_price

callpoint!.setColumnData("ARE_INVDET.EXT_PRICE",str(new_ext_price))
callpoint!.setStatus("MODIFIED-REFRESH")
[[ARE_INVDET.UNITS.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[ARE_INVDET.UNIT_PRICE.AVAL]]
new_unit_price=num(callpoint!.getUserInput())
units=num(callpoint!.getColumnData("ARE_INVDET.UNITS"))               
new_ext_price=units*new_unit_price

callpoint!.setColumnData("ARE_INVDET.EXT_PRICE",str(new_ext_price))
callpoint!.setStatus("MODIFIED-REFRESH")
[[ARE_INVDET.UNIT_PRICE.AVEC]]
gosub calc_grid_tots
gosub disp_totals
[[ARE_INVDET.<CUSTOM>]]
#include std_functions.src
calc_grid_tots:

	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	if numrecs then
		for reccnt=0 to numrecs-1
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3)<>"" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y"
				tqty=tqty+gridrec.units
				tamt=tamt+gridrec.ext_price
			endif
		next reccnt
		user_tpl.totqty$=str(tqty)
		user_tpl.totamt$=str(tamt)
	endif
	return

disp_totals:

rem --- get context and ID of total quantity/amount display controls, and redisplay w/ amts from calc_tots
    
	tqty!=UserObj!.getItem(0)
	tqty!.setValue(num(user_tpl.totqty$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.TOT_QTY",user_tpl.totqty$)

	tamt!=UserObj!.getItem(1)
	tamt!.setValue(num(user_tpl.totamt$))
	callpoint!.setHeaderColumnData("<<DISPLAY>>.TOT_AMT",user_tpl.totamt$)

	return

#include std_missing_params.src
