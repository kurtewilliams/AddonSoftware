[[APE_MANCHECKDET.AREC]]
rem --- Enable/disable RET_FLAG column
	if user_tpl.ret_flag$="Y"
		callpoint!.setColumnEnabled(-1,"APE_MANCHECKDET.RETENTION",1)
	else
		callpoint!.setColumnEnabled(-1,"APE_MANCHECKDET.RETENTION",0)
	endif
[[APE_MANCHECKDET.ADGE]]
rem --- Enable/disable RET_FLAG column
	if user_tpl.ret_flag$="Y"
		callpoint!.setColumnEnabled(-1,"APE_MANCHECKDET.RETENTION",1)
	else
		callpoint!.setColumnEnabled(-1,"APE_MANCHECKDET.RETENTION",0)
	endif
[[APE_MANCHECKDET.AGDR]]
rem --- Enable/disable current INVOICE_DATE and AP_DIST_CODE cells
	apt_invoicehdr_dev=fnget_dev("APT_INVOICEHDR")
	ap_type$=callpoint!.getHeaderColumnData("APE_MANCHECKHDR.AP_TYPE")
	vendor_id$=callpoint!.getHeaderColumnData("APE_MANCHECKHDR.VENDOR_ID")
	invoice_no$=callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
	invoice_found=0
	find(apt_invoicehdr_dev,key=firm_id$+ap_type$+vendor_id$+invoice_no$, dom=*next); invoice_found=1

	if invoice_found then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.INVOICE_DATE",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",0)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.INVOICE_DATE",1)
		if user_tpl.multi_dist$="Y"
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",1)
		else
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",0)
		endif
	endif
[[APE_MANCHECKDET.AGRN]]
rem --- Enable Load Image and View Images options as needed

	curr_row=callpoint!.getValidationRow()
	rowstatus$ = callpoint!.getGridRowNewStatus(curr_row) + callpoint!.getGridRowModifyStatus(curr_row) + callpoint!.getGridRowDeleteStatus(curr_row)

	if callpoint!.getDevObject("use_pay_auth") and callpoint!.getDevObject("scan_docs_to")<>"NOT" and pos("Y"=rowstatus$)=0 then
		callpoint!.setOptionEnabled("VIMG",1)
		callpoint!.setOptionEnabled("LIMG",1)
	else
		callpoint!.setOptionEnabled("VIMG",0)
		callpoint!.setOptionEnabled("LIMG",0)
	endif
[[APE_MANCHECKDET.AOPT-VIMG]]
rem --- Displaye invoice images in the browser
	curr_row=callpoint!.getValidationRow()
	rowstatus$ = callpoint!.getGridRowNewStatus(curr_row) + callpoint!.getGridRowModifyStatus(curr_row) + callpoint!.getGridRowDeleteStatus(curr_row)

	if pos("Y" = rowstatus$) = 0 then 
		invimage_dev=fnget_dev("1APT_INVIMAGE")
		dim invimage$:fnget_tpl$("1APT_INVIMAGE")
		vendor_id$ = callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")
		ap_inv_no$ = callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")

		read record(invimage_dev, key=firm_id$+vendor_id$+ap_inv_no$, dom=*next)
		while 1
			invimage_key$=key(invimage_dev,end=*break)
			if pos(firm_id$+vendor_id$+ap_inv_no$=invimage_key$)<>1 then break
			invimage$=fattr(invimage$)
			read record(invimage_dev)invimage$

			switch (BBjAPI().TRUE)
				case invimage.scan_docs_to$="BDA"
					rem --- Do Barista Doc Archive
					sslReq = BBUtils.isWebServerSSLEnabled()
					url$ = BBUtils.copyFileToWebServer(cvs(invimage.doc_url$,2),"appreviewtemp", sslReq)
					BBjAPI().getThinClient().browse(url$)
					urlVect!=callpoint!.getDevObject("urlVect")
					urlVect!.add(url$)
					callpoint!.setDevObject("urlVect",urlVect!)
					break
				case invimage.scan_docs_to$="GD "
					rem --- Do Google Docs
					BBjAPI().getThinClient().browse(cvs(invimage.doc_url$,2))
					break
				case default
					rem --- Unknown ... skip
					break
			swend
		wend
	endif
[[APE_MANCHECKDET.AOPT-LIMG]]
rem --- Select invoice image and upload for current grid row
	curr_row=callpoint!.getValidationRow()
	rowstatus$ = callpoint!.getGridRowNewStatus(curr_row) + callpoint!.getGridRowModifyStatus(curr_row) + callpoint!.getGridRowDeleteStatus(curr_row)

	if pos("Y" = rowstatus$) = 0 then 
		files=2
		dim channels[files],templates$[files]
		channels[1]=fnget_dev("APM_VENDMAST"),templates$[1]=fnget_tpl$("APM_VENDMAST")
		channels[2]=fnget_dev("1APT_INVIMAGE"),templates$[2]=fnget_tpl$("1APT_INVIMAGE")
		ap_type$ = callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE")
		vendor_id$ = callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")
		ap_inv_no$ = callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
		man_check$ ="Y"
		scan_docs_to$=callpoint!.getDevObject("scan_docs_to")

	call "apc_imageupload.aon", channels[all],templates$[all],ap_type$,vendor_id$,ap_inv_no$,man_check$,scan_docs_to$,status
	endif
[[APE_MANCHECKDET.BDGX]]
rem --- Disable buttons when going to header

	callpoint!.setOptionEnabled("OINV",0)
	callpoint!.setOptionEnabled("VIMG",0)
	callpoint!.setOptionEnabled("LIMG",0)
[[APE_MANCHECKDET.AP_INV_NO.BINP]]
rem --- Should Open Invoice button be enabled?

	trans_type$ = callpoint!.getHeaderColumnData("APE_MANCHECKHDR.TRANS_TYPE")
	invoice_no$ = callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")

	if trans_type$ = "M" and cvs(invoice_no$, 2) = "" then
		callpoint!.setOptionEnabled("OINV",1)
	else
		callpoint!.setOptionEnabled("OINV",0)
	endif
[[APE_MANCHECKDET.BGDS]]
rem --- Inits

	use ::ado_util.src::util
	use ::BBUtils.bbj::BBUtils


	
[[APE_MANCHECKDET.AOPT-OINV]]
rem -- Call inquiry program to view open invoices this vendor
rem -- only allow if trans_type is manual (vs reversal/void)
	trans_type$ = callpoint!.getHeaderColumnData("APE_MANCHECKHDR.TRANS_TYPE")
	if trans_type$ = "M" then 
		ap_type$    = callpoint!.getHeaderColumnData("APE_MANCHECKHDR.AP_TYPE")
		vendor_id$  = callpoint!.getHeaderColumnData("APE_MANCHECKHDR.VENDOR_ID")

		rem --- Select an open invoice
		if cvs(ap_type$, 2) <> "" and cvs(vendor_id$, 2) <> "" then
			dim filter_defs$[4,2]
			filter_defs$[1,0]="APT_INVOICEHDR.FIRM_ID"
			filter_defs$[1,1]="='"+firm_id$+"'"
			filter_defs$[1,2]="LOCK"
			filter_defs$[2,0]="APT_INVOICEHDR.AP_TYPE"
			filter_defs$[2,1]="='"+ap_type$+"'"
			filter_defs$[2,2]="LOCK"
			filter_defs$[3,0]="APT_INVOICEHDR.VENDOR_ID"
			filter_defs$[3,1]="='"+vendor_id$+"'"
			filter_defs$[3,2]="LOCK"
			filter_defs$[4,0]="APT_INVOICEHDR.INVOICE_BAL"
			filter_defs$[4,1]="<>0"
			filter_defs$[4,2]="LOCK"
			call stbl("+DIR_SYP")+"bax_query.bbj",gui_dev,form!,"APT_INVOICEHDR","BUILD",table_chans$[all],apt_invoicehdr_key$,filter_defs$[all]

			if apt_invoicehdr_key$ <>"" then
				call stbl("+DIR_SYP")+"bac_key_template.bbj","APT_INVOICEHDR","PRIMARY",key_tpl$,rd_table_chans$[all],status$
				dim rd_key$:key_tpl$
				apt_invoicehdr_key$=apt_invoicehdr_key$+pad(" ",len(rd_key$))
				rd_key$=apt_invoicehdr_key$(1,len(rd_key$))

				apt01_dev = fnget_dev("APT_INVOICEHDR")
				dim apt01a$:fnget_tpl$("APT_INVOICEHDR")

				apt11_dev = fnget_dev("APT_INVOICEDET")
				dim apt11a$:fnget_tpl$("APT_INVOICEDET")

				ape22_dev1 = user_tpl.ape22_dev1
				dim ape22a$:fnget_tpl$("APE_MANCHECKDET")

				call stbl("+DIR_SYP")+"bac_key_template.bbj",
:					"APE_MANCHECKDET",
:					"AO_VEND_INV",
:					ape22_key1_tmpl$,
:					table_chans$[all],
:					status$

			rem --- Get open invoice record

				while 1
					read record (apt01_dev, key=rd_key$, dom=*break) apt01a$
					print "---found rd_key$ (apt-01)..."; rem debug

					if apt01a.selected_for_pay$="Y"
						callpoint!.setMessage("AP_INV_ON_CHK_REGSTR")
						break
					endif

					dim ape22_key$:ape22_key1_tmpl$
					read (ape22_dev1, key=firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$, knum="AO_VEND_INV", dom=*next)
					ape22_key$ = key(ape22_dev1, end=*next)

					if pos(firm_id$+ap_type$+vendor_id$+apt01a.ap_inv_no$ = ape22_key$) = 1 and
:						ape22_key.check_no$ <> callpoint!.getHeaderColumnData("APE_MANCHECKHDR.CHECK_NO")
:					then
						callpoint!.setMessage("AP_INV_IN_USE:Manual Check")
						break
					endif

					print "---Found an ape22 key..."; rem debug

				rem --- Set invoice as default
			
					rem callpoint!.setTableColumnAttribute("APE_MANCHECKDET.AP_INV_NO","DFLT",apt01a.ap_inv_no$)
					callpoint!.setColumnData("APE_MANCHECKDET.AP_INV_NO",apt01a.ap_inv_no$,1)
					callpoint!.setFocus(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_INV_NO",1)

				rem --- Total open invoice amounts

					apt01_key$ = firm_id$+ap_type$+vendor_id$+apt01a.ap_inv_no$
					inv_amt    = num(apt01a.invoice_amt$)
					disc_amt   = num(apt01a.discount_amt$)
					ret_amt    = num(apt01a.retention$)

					apt11_key$=apt01_key$
					read(apt11_dev, key=apt11_key$, dom=*next)

					while 1
						read record(apt11_dev, end=*break) apt11a$

						if pos(apt11_key$ = apt11a$) = 1 then
							print "---Found an apt11 key..."; rem debug
							inv_amt  = inv_amt  + num(apt11a.trans_amt$)
							disc_amt = disc_amt + num(apt11a.trans_disc$)
							ret_amt  = ret_amt  + num(apt11a.trans_ret$)
						else
							break
						endif
					wend

				rem --- Totals

					gosub calc_tots
					gosub disp_tots

					break
				wend
			endif
		else
			callpoint!.setMessage("AP_NO_TYPE_OR_VENDOR")
			callpoint!.setStatus("ABORT")
		endif
	else
		callpoint!.setMessage("AP_NO_INV_INQ")
		callpoint!.setStatus("ABORT")
	endif
[[APE_MANCHECKDET.AGRE]]
gosub calc_tots
gosub disp_tots
[[APE_MANCHECKDET.AGCL]]
rem --- Set preset val for batch_no

	callpoint!.setTableColumnAttribute("APE_MANCHECKDET.BATCH_NO","PVAL",$22$+stbl("+BATCH_NO")+$22$)
[[APE_MANCHECKDET.AUDE]]
rem --- Recalc totals for header
	gosub calc_tots
	gosub disp_tots

rem --- Enable/disable current INVOICE_DATE and AP_DIST_CODE cells
	apt_invoicehdr_dev=fnget_dev("APT_INVOICEHDR")
	ap_type$=callpoint!.getHeaderColumnData("APE_MANCHECKHDR.AP_TYPE")
	vendor_id$=callpoint!.getHeaderColumnData("APE_MANCHECKHDR.VENDOR_ID")
	invoice_no$=callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
	invoice_found=0
	find(apt_invoicehdr_dev,key=firm_id$+ap_type$+vendor_id$+invoice_no$, dom=*next); invoice_found=1

	if invoice_found then
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.INVOICE_DATE",0)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",0)
	else
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.INVOICE_DATE",1)
		if user_tpl.multi_dist$="Y"
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",1)
		else
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",0)
		endif
	endif

rem --- Enable/disable RET_FLAG column
	if user_tpl.ret_flag$="Y"
		callpoint!.setColumnEnabled(-1,"APE_MANCHECKDET.RETENTION",1)
	else
		callpoint!.setColumnEnabled(-1,"APE_MANCHECKDET.RETENTION",0)
	endif
[[APE_MANCHECKDET.BDEL]]
rem --- need to delete the GL dist recs here (but don't try if nothing in grid row/rec_data$)
if cvs(rec_data$,3)<>"" gosub delete_gldist
	
	
[[APE_MANCHECKDET.INVOICE_AMT.AVEC]]
gosub calc_tots
gosub disp_tots
[[APE_MANCHECKDET.ADEL]]
rem --- Recalc totals for header
	gosub calc_tots
	gosub disp_tots
[[APE_MANCHECKDET.DISCOUNT_AMT.AVEC]]
gosub calc_tots
gosub disp_tots
[[APE_MANCHECKDET.DISCOUNT_AMT.AVAL]]
net_paid=num(callpoint!.getColumnData("APE_MANCHECKDET.INVOICE_AMT"))-num(callpoint!.getUserInput())
callpoint!.setColumnData("APE_MANCHECKDET.NET_PAID_AMT",str(net_paid))

callpoint!.setDevObject("dist_amt",callpoint!.getColumnData("APE_MANCHECKDET.INVOICE_AMT"))
callpoint!.setDevObject("dflt_dist",user_tpl.dflt_dist_cd$)
callpoint!.setDevObject("dflt_gl",user_tpl.dflt_gl_account$)
callpoint!.setDevObject("tot_inv",callpoint!.getColumnData("APE_MANCHECKDET.INVOICE_AMT"))
callpoint!.setStatus("MODIFIED-REFRESH")
[[APE_MANCHECKDET.INVOICE_AMT.AVAL]]
rem --- if invoice # isn't in open invoice file, invoke GL Dist grid

net_paid=num(callpoint!.getUserInput())-num(callpoint!.getColumnData("APE_MANCHECKDET.DISCOUNT_AMT"))
callpoint!.setColumnData("APE_MANCHECKDET.NET_PAID_AMT",str(net_paid))

callpoint!.setDevObject("dist_amt",callpoint!.getUserInput())
callpoint!.setDevObject("dflt_dist",user_tpl.dflt_dist_cd$)
callpoint!.setDevObject("dflt_gl",user_tpl.dflt_gl_account$)
callpoint!.setDevObject("tot_inv",callpoint!.getUserInput())

apt_invoicehdr_dev=fnget_dev("APT_INVOICEHDR")			
dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
ap_type$=field(apt01a$,"AP_TYPE")
vendor_id$=field(apt01a$,"VENDOR_ID")
ap_type$(1)=UserObj!.getItem(num(user_tpl.ap_type_vpos$)).getText()
vendor_id$(1)=UserObj!.getItem(num(user_tpl.vendor_id_vpos$)).getText()

apt01ak1$=firm_id$+ap_type$+vendor_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")

readrecord(apt_invoicehdr_dev,key=apt01ak1$,dom=*next)apt01a$
if apt01a$(1,len(apt01ak1$))<>apt01ak1$ and num(callpoint!.getUserInput())<>0

	rem --- make sure fields (ap type, vendor ID, check#) needed to build GL Dist recs are present, and that AP type/Vendor go together
	dont_allow$=""	
	gosub validate_mandatory_data

	if dont_allow$="Y"
		msg_id$="AP_MANCHKWRITE"
		gosub disp_message
	else	
		rem --- Save current context so we'll know where to return from GL Dist
		declare BBjStandardGrid grid!
		grid! = util.getGrid(Form!)
		grid_ctx=grid!.getContextID()
		curr_row=grid!.getSelectedRow()
		curr_col=grid!.getSelectedColumn()
		rem --- invoke GL Dist form
		gosub get_gl_tots
		callpoint!.setDevObject("invoice_amt",callpoint!.getUserInput())
		user_id$=stbl("+USER_ID")
		dim dflt_data$[1,1]
		dflt_data$[1,0]="GL_ACCOUNT"
		dflt_data$[1,1]=user_tpl.dflt_gl_account$
		key_pfx$=callpoint!.getColumnData("APE_MANCHECKDET.FIRM_ID")+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE")+
:			callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO")+callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")+
:			callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
		callpoint!.setDevObject("key_pfx",key_pfx$)
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:			"APE_MANCHECKDIST",
:			user_id$,
:			"MNT",
:			key_pfx$,
:			table_chans$[all],
:			"",
:			dflt_data$[all]
		rem --- Reset focus on detail row where GL Dist was executed
		sysgui!.setContext(grid_ctx)
		grid!.startEdit(curr_row,curr_col)
		callpoint!.setStatus("ACTIVATE")
	endif	
endif
callpoint!.setStatus("MODIFIED-REFRESH")

[[APE_MANCHECKDET.AP_INV_NO.AVAL]]
rem --- Skip AVAL if AP_INV_NO wasn't changed to avoid re-initializing INVOICE_AMT, etc.
	if callpoint!.getUserInput()=callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO") and
:		callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then break

rem --- Check to make sure Invoice isn't already in the grid

	this_inv$=callpoint!.getUserInput()
	this_row=callpoint!.getValidationRow()
	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	break_out=0
	if numrecs>0
		for reccnt=0 to numrecs-1
			if reccnt=this_row then continue
			if callpoint!.getGridRowDeleteStatus(reccnt)="Y" then continue
			gridrec$=recVect!.getItem(reccnt)
			if cvs(gridrec$,3)<> ""
				if gridrec.ap_inv_no$=this_inv$
					msg_id$="AP_DUPE_INV"
					gosub disp_message
					callpoint!.setStatus("ABORT")
					break_out=1
					break
				endif
			endif
		next reccnt
	endif
	if break_out=1 break

rem --- Look for Open Invoice

	apt_invoicehdr_dev = fnget_dev("APT_INVOICEHDR")
	apt_invoicedet_dev = fnget_dev("APT_INVOICEDET")
	dim apt01a$:fnget_tpl$("APT_INVOICEHDR")
	dim apt11a$:fnget_tpl$("APT_INVOICEDET")

	inv_amt  = 0
	disc_amt = 0
	ret_amt  = 0

	ap_type$    = callpoint!.getHeaderColumnData("APE_MANCHECKHDR.AP_TYPE")
	vendor_id$  = callpoint!.getHeaderColumnData("APE_MANCHECKHDR.VENDOR_ID")
	invoice_no$ = callpoint!.getUserInput()
	check_no$   = callpoint!.getHeaderColumnData("APE_MANCHECKHDR.CHECK_NO")

	ape02_key$ = firm_id$ + ap_type$ + check_no$ + vendor_id$
	apt01ak1$ = firm_id$ + ap_type$ + vendor_id$ + invoice_no$ 
	ape22_dev1 = user_tpl.ape22_dev1

	call stbl("+DIR_SYP")+"bac_key_template.bbj",
:		"APE_MANCHECKDET",
:		"AO_VEND_INV",
:		ape22_key1_tmpl$,
:		table_chans$[all],
:		status$

	read record (apt_invoicehdr_dev, key=apt01ak1$, dom=*next) apt01a$

	if pos(apt01ak1$ = apt01a$) = 1 then

	rem --- Open Invoice record found

		if apt01a.selected_for_pay$ = "Y" then
			callpoint!.setMessage("AP_INV_ON_CHK_REGSTR")
			callpoint!.setStatus("ABORT-RECORD:["+ape02_key$+"]")
			goto end_of_inv_aval
		endif

		if apt01a.hold_flag$ = "Y" then
			callpoint!.setMessage("AP_INV_HOLD")
			callpoint!.setStatus("ABORT-RECORD:["+ape02_key$+"]")
			goto end_of_inv_aval		
		endif

		print "---not select for pay; not on hold..."; rem debug

		rem --- Is invoice already in ape_mancheckdet?
		dim ape22_key$:ape22_key1_tmpl$
		read (ape22_dev1, key=firm_id$+ap_type$+vendor_id$+invoice_no$, knum="AO_VEND_INV", dom=*next)
		ape22_key$ = key(ape22_dev1, end=*next)
		if pos(firm_id$+ap_type$+vendor_id$+invoice_no$ = ape22_key$) = 1 and
:			ape22_key.check_no$ <> check_no$
:		then
			callpoint!.setMessage("AP_INV_IN_USE:Manual Check")
			callpoint!.setStatus("ABORT-RECORD:["+ape02_key$+"]")
			goto end_of_inv_aval
		endif

	rem --- Accumulate totals

		inv_amt  = num(apt01a.invoice_amt$)
		disc_amt = num(apt01a.discount_amt$)
		ret_amt  = num(apt01a.retention$)

		apt11ak1$=apt01a.firm_id$+apt01a.ap_type$+apt01a.vendor_id$+apt01a.ap_inv_no$

		more_dtl=1
		read (apt_invoicedet_dev, key=apt11ak1$, dom=*next)	
							
		while more_dtl
			read record (apt_invoicedet_dev, end=*break) apt11a$

			if pos(apt11ak1$ = apt11a$) = 1 then 
				inv_amt  = inv_amt  + num(apt11a.trans_amt$)
				disc_amt = disc_amt + num(apt11a.trans_disc$)
				ret_amt  = ret_amt  + num(apt11a.trans_ret$)			
			else
				more_dtl=0
			endif
		wend

		callpoint!.setColumnData("APE_MANCHECKDET.INVOICE_DATE",apt01a.invoice_date$)
		callpoint!.setColumnData("APE_MANCHECKDET.AP_DIST_CODE",apt01a.ap_dist_code$)

		if inv_amt=0
			callpoint!.setMessage("AP_INVOICE_PAID")
		endif

	rem --- Disable inv date/dist code, leaving only inv amt/disc amt enabled for open invoice

		w!=Form!.getChildWindow(1109)
		c!=w!.getControl(5900)
		c!.startEdit(c!.getSelectedRow(),4)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.INVOICE_DATE",1)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",0)

	else

		rem --- Is invoice already in ape_mancheckdet?
		dim ape22_key$:ape22_key1_tmpl$
		read (ape22_dev1, key=firm_id$+ap_type$+vendor_id$+invoice_no$, knum="AO_VEND_INV", dom=*next)
		ape22_key$ = key(ape22_dev1, end=*next)
		if pos(firm_id$+ap_type$+vendor_id$+invoice_no$ = ape22_key$) = 1 and
:			ape22_key.check_no$ <> check_no$
:		then
			callpoint!.setMessage("AP_INV_IN_USE:Manual Check")
			callpoint!.setStatus("ABORT-RECORD:["+ape02_key$+"]")
			goto end_of_inv_aval
		endif

	rem --- Enable inv date/dist code if on invoice not in open invoice file
	rem --- Also have user confirm that the invoice wasn't found in Open Invoice file

		msg_id$="AP_EXT_INV"
		gosub disp_message

		w!=Form!.getChildWindow(1109)
		c!=w!.getControl(5900)
		c!.startEdit(c!.getSelectedRow(),1)
		callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.INVOICE_DATE",1)
		if user_tpl.multi_dist$="Y"
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",1)
		else
			callpoint!.setColumnEnabled(callpoint!.getValidationRow(),"APE_MANCHECKDET.AP_DIST_CODE",0)
		endif
		callpoint!.setColumnData("APE_MANCHECKDET.AP_DIST_CODE",user_tpl.dflt_dist_cd$)
		callpoint!.setColumnData("APE_MANCHECKDET.INVOICE_DATE",callpoint!.getHeaderColumnData("APE_MANCHECKHDR.CHECK_DATE"))

	endif

	callpoint!.setColumnData("APE_MANCHECKDET.INVOICE_AMT",str(inv_amt))
	callpoint!.setColumnData("APE_MANCHECKDET.DISCOUNT_AMT",str(disc_amt))
	callpoint!.setColumnData("APE_MANCHECKDET.RETENTION",str(ret_amt))
	callpoint!.setColumnData("APE_MANCHECKDET.NET_PAID_AMT",str(inv_amt-disc_amt))

	callpoint!.setOptionEnabled("OINV",0)

	callpoint!.setStatus("MODIFIED-REFRESH")

end_of_inv_aval:
[[APE_MANCHECKDET.<CUSTOM>]]
calc_tots:
	recVect!=GridVect!.getItem(0)
	dim gridrec$:dtlg_param$[1,3]
	numrecs=recVect!.size()
	tinv=0,tdisc=0,tret=0
	if numrecs>0
		for reccnt=0 to numrecs-1			
				gridrec$=recVect!.getItem(reccnt)
				if cvs(gridrec$,3)<> "" and callpoint!.getGridRowDeleteStatus(reccnt)<>"Y" 
					tinv=tinv+num(gridrec.invoice_amt$)
					tdisc=tdisc+num(gridrec.discount_amt$)
					tret=tret+num(gridrec.retention$)
				endif
		next reccnt
	endif
return

disp_tots:
    rem --- get context and ID of display controls for totals, and redisplay w/ amts from calc_tots
    rem --- also setHeaderColumnData so Barista's values for these display controls will stay in sync
    
    tinv!=UserObj!.getItem(num(user_tpl.tinv_vpos$))
    tinv!.setValue(tinv)
    callpoint!.setHeaderColumnData("<<DISPLAY>>.DISP_TOT_INV",str(tinv))
    tdisc!=UserObj!.getItem(num(user_tpl.tdisc_vpos$))
    tdisc!.setValue(tdisc)
    callpoint!.setHeaderColumnData("<<DISPLAY>>.DISP_TOT_DISC",str(tdisc))
    tret!=UserObj!.getItem(num(user_tpl.tret_vpos$))
    tret!.setValue(tret)
    callpoint!.setHeaderColumnData("<<DISPLAY>>.DISP_TOT_RETEN",str(tret))
    tchk!=UserObj!.getItem(num(user_tpl.tchk_vpos$))
    tchk!.setValue(tinv-tdisc-tret)
    callpoint!.setHeaderColumnData("<<DISPLAY>>.DISP_TOT_CHECK",str(tinv-tdisc-tret))
return

get_gl_tots:
	ape12_dev=fnget_dev("APE_MANCHECKDIST")				
	dim ape12a$:fnget_tpl$("APE_MANCHECKDIST")
	amt_dist=0
	ape12ak1$=firm_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE")+
:	callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO")+callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID")+
:	callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
	read(ape12_dev,key=ape12ak1$,dom=*next)
	more_dtl=1
	while more_dtl
		read record(ape12_dev,end=*break)ape12a$
		if ape12a$(1,len(ape12ak1$))=ape12ak1$
			amt_dist=amt_dist+num(ape12a.gl_post_amt$)
		else
			more_dtl=0
		endif
	wend
	callpoint!.setDevObject("dist_amt",str(amt_dist))
return

delete_gldist:
	ape12_dev=fnget_dev("APE_MANCHECKDIST")
	dim ape12a$:fnget_tpl$("APE_MANCHECKDIST")
	remove_ky$=firm_id$+callpoint!.getColumnData("APE_MANCHECKDET.AP_TYPE") +
:		callpoint!.getColumnData("APE_MANCHECKDET.CHECK_NO") +
:		callpoint!.getColumnData("APE_MANCHECKDET.VENDOR_ID") +
:		callpoint!.getColumnData("APE_MANCHECKDET.AP_INV_NO")
	read (ape12_dev,key=remove_ky$,dom=*next)
	while 1
		k$=key(ape12_dev,end=*break)
		if pos(remove_ky$=k$)<>1 then break
		remove(ape12_dev,key=k$)
	wend
return

validate_mandatory_data:

	dont_allow$=""

	if cvs(callpoint!.getHeaderColumnData("APE_MANCHECKHDR.CHECK_DATE"),3)="" or
:		cvs(callpoint!.getHeaderColumnData("APE_MANCHECKHDR.CHECK_NO"),3)="" or
:		cvs(callpoint!.getHeaderColumnData("APE_MANCHECKHDR.VENDOR_ID"),3)="" then dont_allow$="Y"

	vend_hist$=""
	tmp_vendor_id$=callpoint!.getHeaderColumnData("APE_MANCHECKHDR.VENDOR_ID")
	gosub get_vendor_history
	if vend_hist$<>"Y" then dont_allow$="Y"

return

get_vendor_history:
	apm02_dev=fnget_dev("APM_VENDHIST")				
	dim apm02a$:fnget_tpl$("APM_VENDHIST")
	vend_hist$=""
	readrecord(apm02_dev,key=firm_id$+tmp_vendor_id$+
:		callpoint!.getHeaderColumnData("APE_MANCHECKHDR.AP_TYPE"),dom=*next)apm02a$
	if apm02a.firm_id$+apm02a.vendor_id$+apm02a.ap_type$=firm_id$+tmp_vendor_id$+
:		callpoint!.getHeaderColumnData("APE_MANCHECKHDR.AP_TYPE")
			vend_hist$="Y"
	endif
return
