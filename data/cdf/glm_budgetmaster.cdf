[[GLM_BUDGETMASTER.ADIS]]
rem --- Revision_src does not match ListButton codes, so must select the appropriate index.
	revision_src$=callpoint!.getColumnData("GLM_BUDGETMASTER.REVISION_SRC")
	record_id$=revision_src$(1,len(revision_src$)-1)
	amt_or_units$=revision_src$(len(revision_src$))
	temp_id$=cvs(record_id$,2)
	if len(temp_id$)=1 and pos(temp_id$="012345") then record_id$=temp_id$

	index=0
	codes!=callpoint!.getDevObject("codes")
	for i=0 to codes!.size()-1
		if codes!.getItem(i)=record_id$+amt_or_units$ then
			index=i
			break
		endif
	next i

	revisionListButton!=callpoint!.getControl("GLM_BUDGETMASTER.REVISION_SRC")
	revisionListButton!.selectIndex(index)
[[GLM_BUDGETMASTER.BFMC]]
rem --- Initialize displayColumns! object
	use ::glo_DisplayColumns.aon::DisplayColumns
	displayColumns!=new DisplayColumns(firm_id$)

rem --- Initialize revision_src ListButton
	ldat_list$=displayColumns!.getStringButtonList()
	callpoint!.setTableColumnAttribute("GLM_BUDGETMASTER.REVISION_SRC","LDAT",ldat_list$)

rem --- Make vector of ListButton codes for quick searching
	codes!=SysGUI!.makeVector()
	while len(ldat_list$)>0
		xpos=pos(";"=ldat_list$)
		this_button$=ldat_list$(1,xpos)
		ldat_list$=ldat_list$(xpos+1)

		record_id$=this_button$(pos("~"=this_button$)+1)
		record_id$=record_id$(1,len(record_id$)-2)
		amt_or_units$=this_button$(len(this_button$)-1,1)
		codes!.addItem(record_id$+amt_or_units$)
	wend
	callpoint!.setDevObject("codes",codes!)
[[GLM_BUDGETMASTER.GL_WILDCARD.AVAL]]
rem --- Check length of wildcard against defined mask for GL Account
	if callpoint!.getUserInput()<>""
		call "adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,m0
		if len(callpoint!.getUserInput())>len(m0$)
			msg_id$="GL_WILDCARD_LONG"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
[[GLM_BUDGETMASTER.ASHO]]
num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
gosub open_tables
gls01_dev=num(open_chans$[1])
dim gls01a$:open_tpls$[1]
readrecord(gls01_dev,key=firm_id$+"GL00",err=std_missing_params)gls01a$
if gls01a.budget_flag$<>"Y"
	msg_id$="GL_NO_BUDG"
	gosub disp_message
	rem --- remove process bar:
	bbjAPI!=bbjAPI()
	rdFuncSpace!=bbjAPI!.getGroupNamespace()
	rdFuncSpace!.setValue("+build_task","OFF")
	release
endif
[[GLM_BUDGETMASTER.AOPT-BREV]]
rem --- Get user approval to Create Budget Revision
if callpoint!.getRecordStatus()<>"M"
	if cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.BUDGET_CODE"),3)<>"" and
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.AMT_OR_UNITS"),3)<>"" and
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.DESCRIPTION"),3)<>"" and
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.AMTPCT_VAL"),3)<>"" and 
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.REVISION_SRC"),3)<>"" and
:	cvs(callpoint!.getColumnData("GLM_BUDGETMASTER.REV_TITLE"),3)<>""
		prompt$=Translate!.getTranslation("AON_DO_YOU_WANT_TO_CREATE_A_BUDGET_REVISION?")
		call pgmdir$+"adc_yesno.aon",0,prompt$,0,answer$,fkey
		     
		if answer$="YES" 
			run stbl("+DIR_PGM")+"glu_createbudget.aon"
		else
			callpoint!.setStatus("ABORT")
		endif
	endif
endif
[[GLM_BUDGETMASTER.BWRI]]
rev_src$=callpoint!.getColumnData("GLM_BUDGETMASTER.REVISION_SRC")
gosub validate_revision_source
[[GLM_BUDGETMASTER.<CUSTOM>]]
validate_revision_source:
	rem --- rev_src$ set prior to gosub
	amt_units$=callpoint!.getColumnData("GLM_BUDGETMASTER.AMT_OR_UNITS")
	if cvs(rev_src$,3)<>"" and cvs(amt_units$,3)<>""
		if rev_src$(len(rev_src$),1)<>amt_units$ or cvs(rev_src$(1,len(rev_src$)-1),2)<"0" or cvs(rev_src$(1,len(rev_src$)-1),2)>"5"
			msg_id$="GL_BAD_RECID"
			gosub disp_message
			callpoint!.setStatus("ABORT")
		endif
	endif
return
#include std_missing_params.src
[[GLM_BUDGETMASTER.REVISION_SRC.AVAL]]
rev_src$=callpoint!.getUserInput()
gosub validate_revision_source
[[GLM_BUDGETMASTER.BUDGET_CODE.AVAL]]
if callpoint!.getUserInput()<="5"
	msg_id$="GL_RECID"
	gosub disp_message
	callpoint!.setStatus("ABORT")
endif
