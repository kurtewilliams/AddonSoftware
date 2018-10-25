[[ARE_CCPMT.CASH_REC_CD.AVAL]]
rem --- get cash rec code and associated credit card params; if hosted, disable data collection fields

	ars_cc_custsvc=fnget_dev("ARS_CC_CUSTSVC")
	arc_cashcode=fnget_dev("ARC_CASHCODE")

	dim ars_cc_custsvc$:fnget_tpl$("ARS_CC_CUSTSVC")
	dim arc_cashcode$:fnget_tpl$("ARC_CASHCODE")

	cash_cd$=callpoint!.getUserInput()

	readrecord(arc_cashcode,key=firm_id$+"C"+cash_cd$,dom=std_missing_params)arc_cashcode$
	readrecord(ars_cc_custsvc,key=firm_id$+cash_cd$,dom=std_missing_params)ars_cc_custsvc$
	callpoint!.setDevObject("interface_tp",ars_cc_custsvc.interface_tp$)
	if ars_cc_custsvc.interface_tp$="A"
		rem --- Set timer for form when interface_tp$="A" (using internal API, so collecting sensitive info)
		timer_key!=10000
		BBjAPI().createTimer(timer_key!,60,"custom_event")
		enable_flag=1
	else
		enable_flag=0
		callpoint!.setColumnData("ARE_CCPMT.CARD_NO","",1)
		callpoint!.setColumnData("ARE_CCPMT.SECURITY_CD","",1)
		callpoint!.setColumnData("ARE_CCPMT.NAME_FIRST","",1)
		callpoint!.setColumnData("ARE_CCPMT.NAME_LAST","",1)
		callpoint!.setColumnData("ARE_CCPMT.MONTH","",1)
		callpoint!.setColumnData("ARE_CCPMT.YEAR","",1)
	endif
	callpoint!.setColumnEnabled("ARE_CCPMT.ADDRESS_LINE_1",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.ADDRESS_LINE_2",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.CARD_NO",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.CITY",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.CNTRY_ID",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.EMAIL_ADDR",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.MONTH",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.NAME_FIRST",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.NAME_LAST",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.PHONE_NO",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.SECURITY_CD",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.STATE_CODE",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.YEAR",enable_flag)
	callpoint!.setColumnEnabled("ARE_CCPMT.ZIP_CODE",enable_flag)

rem --- load up open invoices

	gosub get_open_invoices
	gosub fill_grid
[[ARE_CCPMT.CASH_REC_CD.BINQ]]
rem --- restrict inquiry to cash rec codes associated with credit card payments

	dim filter_defs$[1,2]
	filter_defs$[0,0]="ARC_CASHCODE.FIRM_ID"
	filter_defs$[0,1]="='"+firm_id$+"'"
	filter_defs$[0,2]="LOCK"
	filter_defs$[1,0]="ARS_CC_CUSTSVC.USE_CUSTSVC_CC"
	filter_defs$[1,1]="='Y'"
	filter_defs$[1,2]="LOCK"

	dim search_defs$[3]

	call stbl("+DIR_SYP")+"bax_query.bbj",
:		gui_dev,
:		Form!,
:		"AR_CREDIT_CODES",
:		"",
:		table_chans$[all],
:		selected_keys$,
:		filter_defs$[all],
:		search_defs$[all],
:		"",
:		""

	if selected_keys$<>""
		call stbl("+DIR_SYP")+"bac_key_template.bbj",
:			"ARC_CASHCODE",
:			"PRIMARY",
:			apc_cashcode_key$,
:			table_chans$[all],
:			status$
		dim apc_cashcode_key$:apc_cashcode_key$
		apc_cashcode_key$=selected_keys$
		callpoint!.setColumnData("ARE_CCPMT.CASH_REC_CD",apc_cashcode_key.cash_rec_cd$,1)
	endif

	callpoint!.setDevObject("cash_rec_cd",selected_keys$)
	callpoint!.setStatus("ACTIVATE-ABORT")

[[ARE_CCPMT.ZIP_CODE.AVAL]]
gosub reset_timer
[[ARE_CCPMT.YEAR.AINV]]
gosub reset_timer
[[ARE_CCPMT.STATE_CODE.AVAL]]
gosub reset_timer
[[ARE_CCPMT.SECURITY_CD.AVAL]]
gosub reset_timer
[[ARE_CCPMT.PHONE_NO.AVAL]]
gosub reset_timer
[[ARE_CCPMT.NAME_LAST.AVAL]]
gosub reset_timer
[[ARE_CCPMT.NAME_FIRST.AVAL]]
gosub reset_timer
[[ARE_CCPMT.MONTH.AVAL]]
rem --- validate month

	month$=cvs(callpoint!.getUserInput(),3)

	if month$<>""
		if num(month$)<1 or num(month$)>12 then callpoint!.setStatus("ABORT")
	endif

	gosub reset_timer
[[ARE_CCPMT.EMAIL_ADDR.AVAL]]
gosub reset_timer
[[ARE_CCPMT.CNTRY_ID.AVAL]]
gosub reset_timer
[[ARE_CCPMT.ADDRESS_LINE_2.AVAL]]
gosub reset_timer
[[ARE_CCPMT.ADDRESS_LINE_1.AVAL]]
gosub reset_timer
[[ARE_CCPMT.BEND]]
rem --- if vectInvoices! contains any selected items, get confirmation that user really wants to exit

	vectInvoices!=callpoint!.getDevObject("vectInvoices")
	grid_cols = num(callpoint!.getDevObject("grid_cols"))
	selected=0
	if vectInvoices!.size(err=*endif)
		for wk=0 to vectInvoices!.size()-1 step grid_cols
			selected=selected+iff(vectInvoices!.get(wk)="Y",1,0)
		next wk
	endif

	if callpoint!.getDevObject("payment_status")="payment"
		msg_id$="GENERIC_WARN"
		dim msg_tokens$[1]
		msg_tokens$[0]=Translate!.getTranslation("AON_PAYMENT_TRANSACTION_IN_PROCESS","Payment transaction in process. Response not yet received.",1)
		gosub disp_message
		callpoint!.setStatus("ABORT")
	endif

	if selected
		msg_id$="GENERIC_WARN_CANCEL"
		dim msg_tokens$[1]
		msg_tokens$[0]=Translate!.getTranslation("AON_EXIT_WITHOUT_PROCESSING_THIS_PAYMENT","Exit without processing this payment?",1)+$0A$+Translate!.getTranslation("AON_SELECT_OK_OR_CANCEL","Select OK to exit, or Cancel to return to the form.",1)
		gosub disp_message
		if msg_opt$<>"O" then callpoint!.setStatus("ABORT")
	endif

	BBjAPI().removeTimer(10000,err=*next)
[[ARE_CCPMT.AREC]]

[[ARE_CCPMT.CARD_NO.AVAL]]
rem ==============================================
rem -- mod10_check; see if card number field contains valid cc# format
rem ==============================================

	cc_digits$ = ""
	cc_curr_digit = 0
	cc_card$=callpoint!.getUserInput()

	if cvs(cc_card$,3)<>""
		for cc_temp = len(cc_card$) to 1 step -1
		cc_curr_digit = cc_curr_digit + 1
		cc_no = num(cc_card$(cc_temp,1)) * iff(mod(cc_curr_digit,2)=0, 2, 1)
		cc_digits$ = str(cc_no) + cc_digits$
		next cc_temp

		cc_total = 0
		for cc_temp = 1 to len(cc_digits$)
		cc_total = cc_total + num(cc_digits$(cc_temp, 1))
		next cc_temp

		if mod(cc_total, 10) <> 0
			callpoint!.setMessage("INVALID_CREDIT_CARD")
			callpoint!.setStatus("ABORT")
		endif
	endif

	gosub reset_timer
[[ARE_CCPMT.ASVA]]
rem --- if using J2Pay (interface_tp$='A'), check for mandatory data, confirm, then process

	interface_tp$=callpoint!.getDevObject("interface_tp")
	if interface_tp$="A"
		if cvs(callpoint!.getColumnData("ARE_CCPMT.ADDRESS_LINE_1"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.CARD_NO"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.CITY"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.CNTRY_ID"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.EMAIL_ADDR"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.FIRM_ID"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.MONTH"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_FIRST"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_LAST"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.PHONE_NO"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.SECURITY_CD"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.STATE_CODE"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.YEAR"),3)="" or
:			cvs(callpoint!.getColumnData("ARE_CCPMT.ZIP_CODE"),3)="" or
:			num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT"))=0

			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_PLEASE_FILL_IN_ALL_REQUIRED_FIELDS")
			msg_id$="GENERIC_WARN"
			gosub disp_message
			callpoint!.setStatus("ABORT-ACTIVATE")
			break
		endif

		curr$=date(0:"%Yd%Mz")
		if curr$>callpoint!.getColumnData("ARE_CCPMT.YEAR")+callpoint!.getColumnData("ARE_CCPMT.MONTH")
			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_ACCORDING_TO_MONTH_AND_YEAR_ENTERED_THIS_CARD_HAS_EXPIRED")
			msg_id$="GENERIC_WARN"
			gosub disp_message
			callpoint!.setStatus("ABORT-ACTIVATE")
			break
		endif

		msg_id$="CONF_CC_PAYMENT"
		msg_opt$=""
		dim msg_tokens$[1]
		msg_tokens$[0]=cvs(str(num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")):callpoint!.getDevObject("ar_a_mask")),3)
		gosub disp_message
		if msg_opt$<>"Y" then callpoint!.setStatus("ABORT-ACTIVATE")
		
		art_resphdr=fnget_dev("ART_RESPHDR")
		art_respdet=fnget_dev("ART_RESPDET")
		are_cashhdr=fnget_dev("ARE_CASHHDR")
		are_cashdet=fnget_dev("ARE_CASHDET")
		are_cashbal=fnget_dev("ARE_CASHBAL")
		ars_cc_custsvc=fnget_dev("ARS_CC_CUSTSVC")
		arc_gatewaydet=fnget_dev("ARC_GATEWAYDET")

		dim art_resphdr$:fnget_tpl$("ART_RESPHDR")
		dim art_respdet$:fnget_tpl$("ART_RESPDET")
		dim are_cashhdr$:fnget_tpl$("ARE_CASHHDR")
		dim are_cashdet$:fnget_tpl$("ARE_CASHDET")
		dim are_cashbal$:fnget_tpl$("ARE_CASHBAL")
		dim ars_cc_custsvc$:fnget_tpl$("ARS_CC_CUSTSVC")
		dim arc_gatewaydet$:fnget_tpl$("ARC_GATEWAYDET")

		encryptor! = new Encryptor()
		config_id$ = "GATEWAY_AUTH"
		encryptor!.setConfiguration(config_id$)

		readrecord(ars_cc_custsvc,key=firm_id$+callpoint!.getColumnData("ARE_CCPMT.CASH_REC_CD"),dom=std_missing_params)ars_cc_custsvc$
		gateway$=ars_cc_custsvc.gateway_id$

		vectInvoices!=callpoint!.getDevObject("vectInvoices")
		apply_amt!=cast(BBjNumber, num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")))
		cust_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")

		rem --- Use J2Pay library
		gw! = new GatewayFactory()
		apiSampleParameters! = new JSONObject()
	
		gateway! = gw!.getGateway(AvailableGateways.valueOf(cvs(gateway$,3)))
		apiSampleParameters! = gateway!.getApiSampleParameters()
		paramKeys! = apiSampleParameters!.keys()

		while paramKeys!.hasNext()
			gw_attrib$=paramKeys!.next()
			read record (arc_gatewaydet,key=firm_id$+gateway$+pad(gw_attrib$,len(arc_gatewaydet.config_attr$)),knum="AO_ATTRIBUTE",err=std_missing_params)arc_gatewaydet$
			apiSampleParameters!.put(gw_attrib$,encryptor!.decryptData(cvs(arc_gatewaydet.config_value$,3)))
		wend
		redim arc_gatewaydet$
		readrecord (arc_gatewaydet,key=firm_id$+gateway$+pad("ip",len(arc_gatewaydet.config_attr$)),knum="AO_ATTRIBUTE",err=*next)arc_gatewaydet$
		if cvs(arc_gatewaydet.config_value$,3)=""
			ip$="127.0.0.1"
		else
			ip$=encryptor!.decryptData(cvs(arc_gatewaydet.config_value$,3))
		endif
		readrecord(arc_gatewaydet,key=firm_id$+gateway$+pad("testMode",len(arc_gatewaydet.config_attr$)),knum="AO_ATTRIBUTE",err=*next)arc_gatewaydet$
		gateway!.setTestMode(Boolean.valueOf(encryptor!.decryptData(cvs(arc_gatewaydet.config_value$,3))))

		customer! = new Customer()
		customer!.setFirstName(cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_FIRST"),3))
		customer!.setLastName(cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_LAST"),3))
		customer!.setCountry(Country.valueOf(cvs(callpoint!.getColumnData("ARE_CCPMT.CNTRY_ID"),3)))
		customer!.setState(cvs(callpoint!.getColumnData("ARE_CCPMT.STATE_CODE"),3))
		customer!.setCity(cvs(callpoint!.getColumnData("ARE_CCPMT.CITY"),3))
		customer!.setAddress(cvs(callpoint!.getColumnData("ARE_CCPMT.ADDRESS_LINE_1"),3)+" "+cvs(callpoint!.getColumnData("ARE_CCPMT.ADDRESS_LINE_2"),3))
		customer!.setZip(cvs(callpoint!.getColumnData("ARE_CCPMT.ZIP_CODE"),3))
		customer!.setPhoneNumber(cvs(callpoint!.getColumnData("ARE_CCPMT.PHONE_NO"),3))
		customer!.setEmail(cvs(callpoint!.getColumnData("ARE_CCPMT.EMAIL_ADDR"),3))
		customer!.setIp(ip$);rem --- only required by BillPro

		customerCard! = new CustomerCard()
		customerCard!.setName(cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_FIRST"),3)+" "+cvs(callpoint!.getColumnData("ARE_CCPMT.NAME_LAST"),3))
		customerCard!.setNumber(cvs(callpoint!.getColumnData("ARE_CCPMT.CARD_NO"),3))
		customerCard!.setCvv(cvs(callpoint!.getColumnData("ARE_CCPMT.SECURITY_CD"),3))
		customerCard!.setExpiryMonth(cvs(callpoint!.getColumnData("ARE_CCPMT.MONTH"),3))
		customerCard!.setExpiryYear(cvs(callpoint!.getColumnData("ARE_CCPMT.YEAR"),3))

		callpoint!.setColumnData("ARE_CCPMT.NAME_FIRST","",1)
		callpoint!.setColumnData("ARE_CCPMT.NAME_LAST","",1)
		callpoint!.setColumnData("ARE_CCPMT.CARD_NO","",1)
		callpoint!.setColumnData("ARE_CCPMT.SECURITY_CD","",1)
		callpoint!.setColumnData("ARE_CCPMT.MONTH","",1)
		callpoint!.setColumnData("ARE_CCPMT.YEAR","",1)

		response! = new HTTPResponse()
		response! = gateway!.purchase(apiSampleParameters!, customer!, customerCard!, Currency.USD, apply_amt!.floatValue())
 
		rem --- process returned response
		trans_id$=""
		trans_msg$=Translate!.getTranslation("AON_NO_RESPONSE","No response received. Transaction not processed.",1)
		cash_msg$=""

		full_response!=response!.getJSONResponse()
		if full_response!<>null()
			trans_id$=full_response!.get("lr").get("transactionId",err=*next)
			trans_msg$=full_response!.get("lr").get("message")

			rem --- if transaction was approved, create cash receipt
			if response!.isSuccessful()
				gosub create_cash_receipt
			endif

			rem --- write response text to art_response
			if trans_id$<>""
				response_text$=full_response!.toString()
				trans_amount$=str(full_response!.get("lr").get("amount",err=*next))
				trans_approved$=iff(response!.isSuccessful(),"A","D");rem A=approved, D=declined
				if trans_approved$="D" and trans_amount$="" then trans_amount$=str(apply_amt!);rem use amount we submitted if it isn't in the return response
				gosub write_to_response_log
			endif
		endif

		dim msg_tokens$[1]
		msg_tokens$[0]=trans_msg$+$0A$+cash_msg$
		msg_id$="GENERIC_OK"
		gosub disp_message
		callpoint!.setStatus("EXIT")
	else
		rem --- interface_tp$="H" (hosted page), check to make sure one or more invoices selected, confirm, then process

		apply_amt!=cast(BBjNumber, num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")))
		masked_amt$=cvs(str(num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")):callpoint!.getDevObject("ar_a_mask")),3)

		if apply_amt!=0
			dim msg_tokens$[1]
			msg_tokens$[0]=Translate!.getTranslation("AON_PLEASE_SELECT_INVOICES_FOR_PAYMENT","Please select invoices for payment.",1)
			msg_id$="GENERIC_WARN"
			gosub disp_message
			callpoint!.setStatus("ABORT-ACTIVATE")
			break
		endif

		msg_id$="CONF_CC_PAYMENT"
		msg_opt$=""
		dim msg_tokens$[1]
		msg_tokens$[0]=masked_amt$
		gosub disp_message

		if msg_opt$<>"Y"
			callpoint!.setStatus("ABORT-ACTIVATE")
		else
			ars_cc_custsvc=fnget_dev("ARS_CC_CUSTSVC")
			arc_gatewaydet=fnget_dev("ARC_GATEWAYDET")

			dim ars_cc_custsvc$:fnget_tpl$("ARS_CC_CUSTSVC")
			dim arc_gatewaydet$:fnget_tpl$("ARC_GATEWAYDET")
		
			readrecord(ars_cc_custsvc,key=firm_id$+callpoint!.getColumnData("ARE_CCPMT.CASH_REC_CD"),dom=std_missing_params)ars_cc_custsvc$
			gateway_id$=ars_cc_custsvc.gateway_id$
			gosub get_gateway_config

			vectInvoices!=callpoint!.getDevObject("vectInvoices")
			cust_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")

		        rem --- using Authorize.net or PayPal hosted page
		        switch gateway_id$
				case "PAYFLOWPRO"
					rem --- set devObject to indicate 'payment' status
					callpoint!.setDevObject("payment_status","payment")

					rem --- get random number to send when requesting secure token
					rem --- set namespace variable using that number
					rem --- PayPal returns that number in the response, so can match number in response to number we're sending to be sure we're processing our payment and not someone else's (multi-user)
					sid!=UUID.randomUUID()
					sid$=sid!.toString()
					callpoint!.setDevObject("sid",sid$)
					ns!=BBjAPI().getNamespace("aon","credit_receipt_payflowpro",1)
					ns!.setValue(sid$,"init")
					ns!.setCallbackForVariableChange(sid$,"custom_event")
		           
					rem --- use BBj's REST API to send sid$ and receive back secure token
					client!=new BBWebClient()
					request!=new BBWebRequest()
					request!.setURI(gw_config!.get("requestTokenURL"))
					request!.setMethod("POST")
					request!.setContent("PARTNER="+gw_config!.get("PARTNER")+"&VENDOR="+gw_config!.get("VENDOR")+"&USER="+gw_config!.get("USER")+"&PWD="+gw_config!.get("PWD")+"&TRXTYPE=S&AMT="+str(apply_amt!:"###,###.00")+"&CREATESECURETOKEN=Y&SECURETOKENID="+sid!.toString())
					response! = client!.sendRequest(request!) 
					content!=response!.getBody()
					response!.close()

					tokenID!=content!.substring(content!.indexOf("SECURETOKEN=")+11)
					tokenID$=tokenID!.substring(1,tokenID!.indexOf("&"))

					rem --- If successful in getting secure token, launch hosted page.
					rem --- PayPal Silent Post configuration will contain return URL that runs a BBJSP servlet once payment is completed (or declined).
					rem --- Servlet updates namespace variable sid$ with response text.
					rem --- Registered callback for namespace variable change will cause PayPal response routine in ACUS to get executed,
					rem --- which will record response in art_response and post cash receipt, if applicable.

					if content!.contains("RESULT=0")
						returnCode=scall("bbj "+$22$+"are_hosted.aon"+$22$+" - -g"+gateway_id$+" -t"+tokenID$+" -s"+sid$+" -l"+gw_config!.get("launchURL"))
					else
						trans_msg$="Unable to acquire secure token from PayPal."
					endif
				break
				case "AUTHORIZE "
					ns!=BBjAPI().getNamespace("aon","credit_receipt_authorize",1)
					ns!.setCallbackForNamespace("custom_event")

					rem --- Create the order object to add to transaction request
					rem --- Currently filling with unique ID so we can link this auth-capture to returned response
					rem --- Authorize.net next API version should allow refID to be passed that will be returned in Webhook, obviating need for unique ID in order

					sid!=UUID.randomUUID()
					sid$=sid!.toString()
					callpoint!.setDevObject("sid",sid$)
					order! = new OrderType()
					order!.setInvoiceNumber(cust_id$)
					order!.setDescription(sid$)

					ApiOperationBase.setEnvironment(Environment.valueOf(gw_config!.get("environment")))

					merchantAuthenticationType!  = new MerchantAuthenticationType() 
					merchantAuthenticationType!.setName(gw_config!.get("name"))
					merchantAuthenticationType!.setTransactionKey(gw_config!.get("transactionKey"))
					ApiOperationBase.setMerchantAuthentication(merchantAuthenticationType!)

					rem Create the payment transaction request
					txnRequest! = new TransactionRequestType()
					txnRequest!.setTransactionType(TransactionTypeEnum.AUTH_CAPTURE_TRANSACTION.value())
					txnRequest!.setAmount(new BigDecimal(apply_amt!).setScale(2, RoundingMode.CEILING))
					txnRequest!.setOrder(order!)

					setting1! = new SettingType()
					setting1!.setSettingName("hostedPaymentButtonOptions")
					setting1!.setSettingValue("{"+$22$+"text"+$22$+": "+$22$+"Pay"+$22$+"}")
	                        
					setting2! = new SettingType()
					setting2!.setSettingName("hostedPaymentOrderOptions")
					setting2!.setSettingValue("{"+$22$+"show"+$22$+": false}")

					setting3! = new SettingType()
					setting3!.setSettingName("hostedPaymentReturnOptions")
					setting3!.setSettingValue("{"+$22$+"showReceipt"+$22$+": true, "+$22$+"url"+$22$+": "+$22$+gw_config!.get("confirmationURL")+$22$+", "+$22$+"urlText"+$22$+": "+$22$+"Continue"+$22$+"}")

					setting4! = new SettingType()
					setting4!.setSettingName("hostedPaymentPaymentOptions")
					setting4!.setSettingValue("{"+$22$+"showBankAccount"+$22$+": false}")

					alist! = new ArrayOfSetting()
					alist!.getSetting().add(setting1!)
					alist!.getSetting().add(setting2!)
					alist!.getSetting().add(setting3!)
					alist!.getSetting().add(setting4!)

					apiRequest! = new GetHostedPaymentPageRequest()
					apiRequest!.setTransactionRequest(txnRequest!)
					apiRequest!.setHostedPaymentSettings(alist!)

					controller! = new GetHostedPaymentPageController(apiRequest!)
					controller!.execute()

					authResponse! = new GetHostedPaymentPageResponse()
					authResponse! = controller!.getApiResponse()

					rem --- if GetHostedPaymentPageResponse() indicates success, launch our 'starter' page.
					rem --- 'starter' page gets passed the token, and has a 'proceed to checkout' button, which does a POST to https://test.authorize.net/payment/payment, passing along the token.
					rem --- Authorize.net is configured with Webhook for the auth-capture transaction. Webhook contains URL that runs our BBJSP servlet.
					rem --- Servlet updates namespace variable 'authresp' with response text
					rem --- registered callback for variable change will cause authorize_response routine to get executed
					rem --- authorize_response will parse trans_id from the webhook, then send a getTransactionDetailsRequest
					rem --- returned getTransactionDetailsResponse should contain order with our sid$ in the order description
					rem --- if sid$ matches saved_sid$, then this is our response (and not someone else's who might also be processing payments)
					rem --- assuming this is our response, record the Webhook response in art_response and create cash receipt, if applicable

					if authResponse!.getMessages().getResultCode()=MessageTypeEnum.OK
						returnCode=scall("bbj "+$22$+"are_hosted.aon"+$22$+" - -g"+gateway_id$+" -t"+authResponse!.getToken()+" -a"+masked_amt$+" -l"+gw_config!.get("launchURL")+" -u"+gw_config!.get("gatewayURL"))
					else
						trans_msg$=Translate!.getTranslation("AON_UNABLE_TO_ACQUIRE_SECURE_TOKEN")+$0a$+authResponse!.getMessages().getMessage().get(0).getCode()+$0a$+authResponse!.getMessages().getMessage().get(0).getText()
					endif
				break
				case default
					rem --- shouldn't get here unless new hosted gateway is specified in params, added to adc_gatewayhdr, and no case has been built for handling it
				break
			swend
		endif
	endif
[[ARE_CCPMT.ACUS]]
rem --- Process custom event -- used in this pgm to select/de-select checkboxes in grid
rem --- See basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem --- This routine is executed when callbacks have been set to run a 'custom event'
rem --- Analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind
rem --- of event it is... in this case, we're toggling checkboxes on/off in form grid control

	dim gui_event$:tmpl(gui_dev)
	dim notify_base$:noticetpl(0,0)
	gui_event$=SysGUI!.getLastEventString()
	ev!=BBjAPI().getLastEvent()

	if ev!.getEventName()="BBjNamespaceEvent"

		art_resphdr=fnget_dev("ART_RESPHDR")
		art_respdet=fnget_dev("ART_RESPDET")
		are_cashhdr=fnget_dev("ARE_CASHHDR")
		are_cashdet=fnget_dev("ARE_CASHDET")
		are_cashbal=fnget_dev("ARE_CASHBAL")

		dim art_resphdr$:fnget_tpl$("ART_RESPHDR")
		dim art_respdet$:fnget_tpl$("ART_RESPDET")
		dim are_cashhdr$:fnget_tpl$("ARE_CASHHDR")
		dim are_cashdet$:fnget_tpl$("ARE_CASHDET")
		dim are_cashbal$:fnget_tpl$("ARE_CASHBAL")

		vectInvoices!=callpoint!.getDevObject("vectInvoices")
		apply_amt!=cast(BBjNumber, num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT")))
		cust_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")

		gw_config!=callpoint!.getDevObject("gw_config")
		gateway_id$=gw_config!.get("gateway_id")

		trans_msg$=Translate!.getTranslation("AON_UNTRAPPED_NAMESPACE_EVENT")
		cash_msg$=""

		ns_name$=ev!.getNamespaceName()
		if pos("authorize"=ns_name$)
			rem --- response (webhook) from Authorize.net
			newValue! = new JSONObject(ev!.getNewValue())
			trans_id$=newValue!.get("payload").get("id")

			ApiOperationBase.setEnvironment(Environment.valueOf(gw_config!.get("environment")))

			merchantAuthenticationType!  = new MerchantAuthenticationType() 
			merchantAuthenticationType!.setName(gw_config!.get("name"))
			merchantAuthenticationType!.setTransactionKey(gw_config!.get("transactionKey"))
			ApiOperationBase.setMerchantAuthentication(merchantAuthenticationType!)

			getRequest! = new GetTransactionDetailsRequest()
			getRequest!.setMerchantAuthentication(merchantAuthenticationType!)
			getRequest!.setTransId(trans_id$)

			controller! = new GetTransactionDetailsController(getRequest!)
			controller!.execute()
			authResponse! = controller!.getApiResponse()
			if authResponse!.getMessages().getResultCode()=MessageTypeEnum.OK
				resp_cust$=authResponse!.getTransaction().getOrder().getInvoiceNumber()
				resp_sid$=authResponse!.getTransaction().getOrder().getDescription()
				resp_code=authResponse!.getTransaction().getResponseCode()
				payment_amt$=str(authResponse!.getTransaction().getAuthAmount())
				trans_msg$=authResponse!.getMessages().getMessage().get(0).getCode()+$0a$+authResponse!.getMessages().getMessage().get(0).getText()

				rem if resp_sid$ matches callpoint!.getDevObject("sid") then this is a response to OUR payment
				rem this is a workaround until Authorize.net returns our assigned refID in the webhook response
				rem until then, don't know if this event got triggered by us, or someone else processing a credit card payment
				rem so we have to put the sid$ in something that gets returned in the full response, and get that full response
				rem instead of just using the returned webhook
				rem may want to always get full response to record in art_response anyway, since webhook payload is abridged   
   
				if resp_sid$=callpoint!.getDevObject("sid")
					response_text$=newValue!.toString()
					trans_amount$=payment_amt$
					trans_approved$=iff(resp_code,"A","D");rem A=approved, D=declined
					if resp_code
						gosub create_cash_receipt
					else
						cash_msg$=""
					endif
					gosub write_to_response_log
				endif
			else
				trans_msg$=Translate!.getTranslation("AON_UNABLE_TO_PROCESS_GETTRANSACTIONDETAILSREQUEST_METHOD")
			endif

		else
			if pos("payflowpro"=ns_name$)
				rem --- response (silent post) from PayPal
				old_value$=ev!.getOldValue()
				if old_value$="init"
					new_value$=ev!.getNewValue()
					trans_id$=fnparse$(new_value$,"PNREF=","&")
					payment_amt$=str(num(fnparse$(new_value$,"AMT=","&")))
					trans_msg$=fnparse$(new_value$,"RESPMSG=","&")
					result$=fnparse$(new_value$,"RESULT=","&")
					if result$="0"
						gosub create_cash_receipt
					else
						cash_msg$=""
					endif
					if cvs(trans_id$,3)<>""
						response_text$=new_value$
						trans_amount$=payment_amt$
						trans_approved$=iff(result$="0","A","D");rem A=approved, D=declined
						gosub write_to_response_log
					endif
					rem --- set devObject to indicate 'response' status
					callpoint!.setDevObject("payment_status","response")
				endif
			endif
		endif
		dim msg_tokens$[1]
		msg_tokens$[0]=trans_msg$+$0A$+cash_msg$
		msg_id$="GENERIC_OK"
		gosub disp_message
		callpoint!.setStatus("EXIT")
	else
		if ev!.getEventName()="BBjTimerEvent" and gui_event.y=10000
			BBjAPI().removeTimer(10000)
			callpoint!.setStatus("EXIT")
		else
			ctl_ID=dec(gui_event.ID$)
			if ctl_ID=num(callpoint!.getDevObject("openInvoicesGridId"))
				if gui_event.code$="N"
					notify_base$=notice(gui_dev,gui_event.x%)
					dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
					notice$=notify_base$
					curr_row = dec(notice.row$)
					curr_col = dec(notice.col$)
				endif
				switch notice.code
					case 12;rem grid_key_press
						if notice.wparam=32 gosub switch_value
					break
					case 14;rem grid_mouse_up
						if notice.col=0 gosub switch_value
					break
					case 7;rem edit stop - can only edit pay and disc taken cols
						if curr_col=num(callpoint!.getDevObject("pay_col")) or curr_col=num(callpoint!.getDevObject("disc_taken_col"))  then
							vectInvoices!=callpoint!.getDevObject("vectInvoices")
							openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
							grid_cols = num(callpoint!.getDevObject("grid_cols"))
							inv_bal_col=num(callpoint!.getDevObject("inv_bal_col"))
							disc_col=num(callpoint!.getDevObject("disc_col"))
							pay_col=num(callpoint!.getDevObject("pay_col"))
							disc_taken_col=num(callpoint!.getDevObject("disc_taken_col"))
							end_bal_col=num(callpoint!.getDevObject("end_bal_col"))
							oa_inv$=callpoint!.getDevObject("oa_inv")
							tot_pay=num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT"))
							vect_pay_amt=num(vectInvoices!.get(curr_row*grid_cols+pay_col))
							vect_disc_taken=num(vectInvoices!.get(curr_row*grid_cols+disc_taken_col))
							vect_inv_bal=num(vectInvoices!.get(curr_row*grid_cols+inv_bal_col))
							grid_pay_amt = num(openInvoicesGrid!.getCellText(curr_row,pay_col))
							grid_disc_taken = num(openInvoicesGrid!.getCellText(curr_row,disc_taken_col))
							if grid_pay_amt<0 then grid_pay_amt=0
							if grid_disc_taken<0 then grid_disc_taken=0
							if grid_pay_amt<=0 then grid_disc_taken=0
							openInvoicesGrid!.setCellText(curr_row,end_bal_col,str(vect_inv_bal-grid_pay_amt-grid_disc_taken))
							if vectInvoices!.get(curr_row*grid_cols+1)<>oa_inv$ and num(openInvoicesGrid!.getCellText(curr_row,end_bal_col))<0
								msg_id$="GENERIC_WARN"
								dim msg_tokens$[1]
								msg_tokens$[1]=Translate!.getTranslation("AON_CREDIT_BALANCE_PLEASE_CORRECT","You have created a credit balance. Please correct the payment or discount amounts.",1)
								gosub disp_message
								grid_pay_amt=0
								grid_disc_taken=0
							endif
							tot_pay=tot_pay-vect_pay_amt+grid_pay_amt
							vectInvoices!.set(curr_row*grid_cols+pay_col,str(grid_pay_amt))
							vectInvoices!.set(curr_row*grid_cols+disc_taken_col,str(grid_disc_taken))
							vectInvoices!.set(curr_row*grid_cols+end_bal_col,str(vect_inv_bal-grid_pay_amt-grid_disc_taken))
							openInvoicesGrid!.setCellText(curr_row,pay_col,str(grid_pay_amt))
							openInvoicesGrid!.setCellText(curr_row,disc_taken_col,str(grid_disc_taken))
							openInvoicesGrid!.setCellText(curr_row,end_bal_col,str(vect_inv_bal-grid_pay_amt-grid_disc_taken))
							callpoint!.setColumnData("<<DISPLAY>>.APPLY_AMT",str(tot_pay),1)
							if grid_pay_amt>0
								vectInvoices!.set(curr_row*grid_cols,"Y")
								openInvoicesGrid!.setCellState(curr_row,0,1)
							else
								vectInvoices!.set(curr_row*grid_cols,"")
								openInvoicesGrid!.setCellState(curr_row,0,0)
							endif
							gosub reset_timer
						endif
					break
					case 8;rem edit start
						grid_cols = num(callpoint!.getDevObject("grid_cols"))
						comment_col=grid_cols-1
		 				if curr_col=comment_col
							vectInvoices!=callpoint!.getDevObject("vectInvoices")
							openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
							disp_text$=openInvoicesGrid!.getCellText(clicked_row,comment_col)
							sv_disp_text$=disp_text$

							editable$="YES"
							force_loc$="NO"
							baseWin!=null()
							startx=0
							starty=0
							shrinkwrap$="NO"
							html$="NO"
							dialog_result$=""
							spellcheck=1

							call stbl("+DIR_SYP")+ "bax_display_text.bbj",
:								"Cash Receipts Detail Comments",
:								disp_text$, 
:								table_chans$[all], 
:								editable$, 
:								force_loc$, 
:								baseWin!, 
:								startx, 
:								starty, 
:								shrinkwrap$, 
:								html$, 
:								dialog_result$,
:								spellcheck

							if disp_text$<>sv_disp_text$
								openInvoicesGrid!.setCellText(curr_row,comment_col,disp_text$)
								vectInvoices!.setItem(curr_row*grid_cols+comment_col,disp_text$)
							endif

							callpoint!.setStatus("ACTIVATE")
						endif
					break
					case default
					break
				swend
			endif
		endif
	endif
[[ARE_CCPMT.ASIZ]]
rem --- Resize grids
	formHeight=Form!.getHeight()
	formWidth=Form!.getWidth()
	openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
	gridYpos=openInvoicesGrid!.getY()
	gridXpos=openInvoicesGrid!.getX()
	availableHeight=formHeight-gridYpos

	openInvoicesGrid!.setSize(formWidth-2*gridXpos,availableHeight-8)
	openInvoicesGrid!.setFitToGrid(1)
[[ARE_CCPMT.AWIN]]
rem --- Declare classes used

	use java.math.BigDecimal
	use java.math.RoundingMode
	use java.util.Iterator
	use java.util.UUID

	use org.json.JSONObject

	use com.tranxactive.j2pay.gateways.parameters.Customer
	use com.tranxactive.j2pay.gateways.parameters.CustomerCard
	use com.tranxactive.j2pay.gateways.parameters.Currency
	use com.tranxactive.j2pay.gateways.parameters.Country

	use com.tranxactive.j2pay.gateways.core.Gateway
	use com.tranxactive.j2pay.gateways.core.GatewayFactory
	use com.tranxactive.j2pay.gateways.core.AvailableGateways
	use com.tranxactive.j2pay.gateways.core.GatewaySampleParameters

	use com.tranxactive.j2pay.net.HTTPResponse
	use com.tranxactive.j2pay.net.JSONHelper

	use net.authorize.Environment
	use net.authorize.api.contract.v1.MerchantAuthenticationType
	use net.authorize.api.contract.v1.TransactionRequestType
	use net.authorize.api.contract.v1.SettingType
	use net.authorize.api.contract.v1.ArrayOfSetting
	use net.authorize.api.contract.v1.MessageTypeEnum
	use net.authorize.api.contract.v1.TransactionTypeEnum
	use net.authorize.api.contract.v1.GetHostedPaymentPageRequest
	use net.authorize.api.contract.v1.GetHostedPaymentPageResponse
	use net.authorize.api.contract.v1.GetTransactionDetailsRequest
	use net.authorize.api.contract.v1.OrderType
	use net.authorize.api.controller.base.ApiOperationBase
	use net.authorize.api.controller.GetHostedPaymentPageController
	use net.authorize.api.controller.GetTransactionDetailsController

	use ::ado_util.src::util	
	use ::sys/prog/bao_encryptor.bbj::Encryptor

	use ::REST/BBWebClient.bbj::BBWebClient
	use ::REST/BBWebClient.bbj::BBWebRequest
	use ::REST/BBWebClient.bbj::BBWebResponse

rem --- get/store mask
	call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","A","",ar_a_mask$,0,0
	callpoint!.setDevObject("ar_a_mask",ar_a_mask$)
	callpoint!.setDevObject("payment_status","")
	callpoint!.setDevObject("vectInvoices","")

rem --- Open files

num_files=8
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="ART_INVHDR",open_opts$[1]="OTA"
open_tables$[2]="ART_RESPHDR",open_opts$[2]="OTA"
open_tables$[3]="ART_RESPDET",open_opts$[3]="OTA"	
open_tables$[4]="ARE_CASHHDR",open_opts$[4]="OTA"
open_tables$[5]="ARE_CASHDET",open_opts$[5]="OTA"
open_tables$[6]="ARE_CASHBAL",open_opts$[6]="OTA"
open_tables$[7]="ARS_CC_CUSTSVC",open_opts$[7]="OTA"
open_tables$[8]="ARC_GATEWAYDET",open_opts$[8]="OTA"

gosub open_tables


rem --- Add open invoice grid to form
	nxt_ctlID = util.getNextControlID()
	tmpCtl!=callpoint!.getControl("ARE_CCPMT.EMAIL_ADDR")
	grid_y=tmpCtl!.getY()+tmpCtl!.getHeight()+5
	openInvoicesGrid! = Form!.addGrid(nxt_ctlID,5,grid_y,895,125); rem --- ID, x, y, width, height
	callpoint!.setDevObject("openInvoicesGrid",openInvoicesGrid!)
	callpoint!.setDevObject("openInvoicesGridId",str(nxt_ctlID))
	callpoint!.setDevObject("grid_cols","12")
	callpoint!.setDevObject("grid_rows","10")
	callpoint!.setDevObject("inv_bal_col","5")
	callpoint!.setDevObject("disc_col","6")
	callpoint!.setDevObject("pay_col","8")
	callpoint!.setDevObject("disc_taken_col","9")
	callpoint!.setDevObject("end_bal_col","10")
	callpoint!.setDevObject("interface_tp","")

	gosub format_grid

	openInvoicesGrid!.setTabAction(SysGUI!.GRID_NAVIGATE_GRID)
	openInvoicesGrid!.setTabActionSkipsNonEditableCells(1)
	openInvoicesGrid!.setColumnEditable(8,1)
	openInvoicesGrid!.setColumnEditable(9,1)
	openInvoicesGrid!.setColumnEditable(11,1)

rem --- Reset window size
	util.resizeWindow(Form!, SysGui!)

rem --- set callbacks - processed in ACUS callpoint
	openInvoicesGrid!.setCallback(openInvoicesGrid!.ON_GRID_KEY_PRESS,"custom_event")
	openInvoicesGrid!.setCallback(openInvoicesGrid!.ON_GRID_MOUSE_UP,"custom_event")
	openInvoicesGrid!.setCallback(openInvoicesGrid!.ON_GRID_EDIT_STOP,"custom_event")
	openInvoicesGrid!.setCallback(openInvoicesGrid!.ON_GRID_EDIT_START,"custom_event")
[[ARE_CCPMT.<CUSTOM>]]
rem ==========================================================================
format_grid: rem --- Let Barista create/format the grid
rem ==========================================================================

	ar_a_mask$=callpoint!.getDevObject("ar_a_mask")

	dim attr_def_col_str$[0,0]
	attr_def_col_str$[0,0] = callpoint!.getColumnAttributeTypes()
	grid_cols = num(callpoint!.getDevObject("grid_cols"))
	grid_rows = num(callpoint!.getDevObject("grid_rows"))
	dim attr_grid_col$[grid_cols,len(attr_def_col_str$[0,0])/5]

	column_no = 1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PAY")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_grid_col$[column_no,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="5"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE_NO"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE_NO")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="INVOICE_DATE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_INVOICE_DATE")
	attr_grid_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_grid_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DUE_DATE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DUE_DATE")
	attr_grid_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_grid_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AMOUNT"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AMOUNT")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="BALANCE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_BALANCE")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="AVAIL_DISC"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_AVAIL_DISC")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_DATE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISC_DATE")
	attr_grid_col$[column_no,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="5"
	attr_grid_col$[column_no,fnstr_pos("STYP",attr_def_col_str$[0,0],5)]="1"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="10"

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="PAY_AMOUNT"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_PAYMENT_AMT")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DISC_TAKEN"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_DISC_AMT")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="END_BALANCE"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_END_BALANCE")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="N"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="20"
	attr_grid_col$[column_no,fnstr_pos("MSKO",attr_def_col_str$[0,0],5)]=ar_a_mask$

	column_no = column_no +1
	attr_grid_col$[column_no,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="COMMENT"
	attr_grid_col$[column_no,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=Translate!.getTranslation("AON_COMMENTS")
	attr_grid_col$[column_no,fnstr_pos("DTYP",attr_def_col_str$[0,0],5)]="C"
	attr_grid_col$[column_no,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="100"

	for curr_attr=1 to grid_cols
		attr_grid_col$[0,1] = attr_grid_col$[0,1] + 
:			pad("ARE_CCPMT." + attr_grid_col$[curr_attr, fnstr_pos("DVAR", attr_def_col_str$[0,0], 5)], 40)
	next curr_attr

	attr_disp_col$=attr_grid_col$[0,1]

	call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,openInvoicesGrid!,"COLH-LINES-LIGHT-AUTO-SIZEC-MULTI-DATES-CHECKS",grid_rows,
:		attr_def_col_str$[all],attr_disp_col$,attr_grid_col$[all]

	return

rem ==========================================================================
get_open_invoices: rem --- create vector of invoices with bal>0, taking into account anything entered but not yet posted
rem ==========================================================================

	art_invhdr=fnget_dev("ART_INVHDR")
	dim art_invhdr$:fnget_tpl$("ART_INVHDR")
	are_cashbal=fnget_dev("ARE_CASHBAL")
	dim are_cashbal$:fnget_tpl$("ARE_CASHBAL")

	cust_id$=callpoint!.getColumnData("ARE_CCPMT.CUSTOMER_ID")
	ar_type$=art_invhdr.ar_type$;rem --- ar_type always '  '

	vectInvoices!=BBjAPI().makeVector()
	oa_inv$="OA"+stbl("+SYSTEM_DATE")(4)
	callpoint!.setDevObject("oa_inv",oa_inv$)
	oa_flag=0

	read (art_invhdr,key=firm_id$+ar_type$+cust_id$,dom=*next)

	while 1
		invky$=key(art_invhdr,end=*break)
		if pos(firm_id$+ar_type$+cust_id$=invky$)<>1 then break
		readrecord(art_invhdr)art_invhdr$
		inv_bal=num(art_invhdr.invoice_bal$)
		if inv_bal and arc_cashcode.disc_flag$="Y" and stbl("+SYSTEM_DATE")<= pad(art_invhdr.disc_date$,8) 
			disc_amt=art_invhdr.disc_allowed-art_invhdr.disc_taken
			if disc_amt<0 then disc_amt=0
		else
			disc_amt=0
		endif

		rem --- applied but not yet posted
		redim are_cashbal$
		read record(are_cashbal,key=firm_id$+ar_type$+are_cashbal.reserved_str$+cust_id$+art_invhdr.ar_inv_no$,dom=*next)are_cashbal$
		if arc_cashcode.disc_flag$="Y" then disc_amt=disc_amt-num(are_cashbal.discount_amt$)
		inv_bal=inv_bal-num(are_cashbal.apply_amt$)-num(are_cashbal.discount_amt$)

		if inv_bal<=0 then continue
		vectInvoices!.add("")
		vectInvoices!.add(art_invhdr.ar_inv_no$)
		vectInvoices!.add(date(jul(art_invhdr.invoice_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add(date(jul(art_invhdr.inv_due_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add(art_invhdr.invoice_amt$)
		vectInvoices!.add(str(inv_bal))
		vectInvoices!.add(str(disc_amt))
		vectInvoices!.add(date(jul(art_invhdr.disc_date$,"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add(str(inv_bal))
		vectInvoices!.add(art_invhdr.memo_1024$)
		if art_invhdr.ar_inv_no$=oa_inv$ then oa_flag=1
	wend
	rem --- add final row (if need-be) to accommodate on-account payment (e.g., taking a deposit or pre-payment)
	if !oa_flag
		vectInvoices!.add("")
		vectInvoices!.add(oa_inv$)
		vectInvoices!.add(date(jul(stbl("+SYSTEM_DATE"),"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add(date(jul(stbl("+SYSTEM_DATE"),"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add(date(jul(stbl("+SYSTEM_DATE"),"%Yd%Mz%Dz"):stbl("+DATE_GRID")))
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add("0")
		vectInvoices!.add("")
	endif

	callpoint!.setDevObject("vectInvoices",vectInvoices!)

	return

rem ==========================================================================
fill_grid: rem --- fill grid with vector of unpaid invoices
rem ==========================================================================
	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(0)
	openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
	if vectInvoices!.size()

		numrow=vectInvoices!.size()/openInvoicesGrid!.getNumColumns()
		openInvoicesGrid!.clearMainGrid()
		openInvoicesGrid!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		openInvoicesGrid!.setNumRows(numrow)
		openInvoicesGrid!.setCellText(0,0,vectInvoices!)
		openInvoicesGrid!.resort()
	endif
	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(1)
return

rem ==========================================================================
switch_value:rem --- Switch Check Values
rem ==========================================================================
	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(0)
	openInvoicesGrid!=callpoint!.getDevObject("openInvoicesGrid")
	vectInvoices!=callpoint!.getDevObject("vectInvoices")
	grid_cols=num(callpoint!.getDevObject("grid_cols"))
	inv_bal_col=num(callpoint!.getDevObject("inv_bal_col"))
	disc_col=num(callpoint!.getDevObject("disc_col"))
	pay_col=num(callpoint!.getDevObject("pay_col"))
	disc_taken_col=num(callpoint!.getDevObject("disc_taken_col"))
	end_bal_col=num(callpoint!.getDevObject("end_bal_col"))

	TempRows!=openInvoicesGrid!.getSelectedRows()
	tot_pay=num(callpoint!.getColumnData("<<DISPLAY>>.APPLY_AMT"))

	if TempRows!.size()>0
		for curr_row=1 to TempRows!.size()
			if openInvoicesGrid!.getCellState(TempRows!.getItem(curr_row-1),0)=0
				openInvoicesGrid!.setCellState(TempRows!.getItem(curr_row-1),0,1)
				inv_disc_taken=num(vectInvoices!.get(TempRows!.getItem(curr_row-1)*grid_cols+disc_col))
				inv_pay=num(vectInvoices!.get(TempRows!.getItem(curr_row-1)*grid_cols+inv_bal_col))-inv_disc_taken
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols,"Y")
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+pay_col,str(inv_pay))
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+disc_taken_col,str(inv_disc_taken))
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+end_bal_col,"0")
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),pay_col,str(inv_pay))
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),disc_taken_col,str(inv_disc_taken))
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),end_bal_col,"0")
				tot_pay=tot_pay+inv_pay
			else
				openInvoicesGrid!.setCellState(num(TempRows!.getItem(curr_row-1)),0,0)
				inv_pay=num(vectInvoices!.get(TempRows!.getItem(curr_row-1)*grid_cols+pay_col))
				inv_bal=num(vectInvoices!.get(TempRows!.getItem(curr_row-1)*grid_cols+inv_bal_col))
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols,"")
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+pay_col,"0")
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+disc_taken_col,"0")
				vectInvoices!.set(TempRows!.getItem(curr_row-1)*grid_cols+end_bal_col,str(inv_bal))
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),pay_col,"0")
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),disc_taken_col,"0")
				openInvoicesGrid!.setCellText(TempRows!.getItem(curr_row-1),end_bal_col,str(inv_bal))
				tot_pay=tot_pay-inv_pay
			endif
		next curr_row
	endif

	callpoint!.setColumnData("<<DISPLAY>>.APPLY_AMT",str(tot_pay),1)

	if info(3,6)<>"5" then SysGUI!.setRepaintEnabled(1)

	gosub reset_timer

	return

rem ==========================================================================
create_cash_receipt:
rem --- in: firm_id$, cust_id$, apply_amt!, trans_id$, vectInvoices!
rem ==========================================================================

    rem --- write are_cashhdr
    rem --- TODO CAH need to read/update, not just create, as >1 payment could have been made so header already exists
    rem --- TODO CAH same for are_cashbal/are_cashdet, don't just create them
    rem --- TODO CAH also need to add logic to use deposit_ID and batch_no, and update ars_cc_custsvc with same
    rem --- TODO CAH if there is already an are_cashdet for this invoice with balance < pay amount, apply on account
	
	deposit_id$=""
	batch_no$="0000000"

	are_cashhdr$.firm_id$=firm_id$
	are_cashhdr.receipt_date$=stbl("+SYSTEM_DATE")
	are_cashhdr.customer_id$=cust_id$
	are_cashhdr.cash_rec_cd$="C"
	are_cashhdr.payment_amt=apply_amt!
	are_cashhdr.batch_no$=batch_no$
	are_cashhdr.deposit_id$=deposit_id$
	are_cashhdr.memo_1024$=$01$
	are_cashhdr$=field(are_cashhdr$)
	writerecord(are_cashhdr)are_cashhdr$

	rem --- now write are_cashdet and are_cashbal recs for each invoice in vectInvoices!
	for inv_row=0 to vectInvoices!.size()-1 step num(callpoint!.getDevObject("grid_cols"))
		pay_flag$=vectInvoices!.get(inv_row)
		if pay_flag$="Y"
			ar_inv_no$=vectInvoices!.get(inv_row+1)
			invoice_bal$=vectInvoices!.get(inv_row+num(callpoint!.getDevObject("inv_bal_col")))
			invoice_pay$=vectInvoices!.get(inv_row+num(callpoint!.getDevObject("pay_col")))
            
			redim are_cashdet$
			redim are_cashbal$

			are_cashdet.firm_id$=firm_id$
			are_cashdet.receipt_date$=are_cashhdr.receipt_date$
			are_cashdet.customer_id$=are_cashhdr.customer_id$
			are_cashdet.cash_rec_cd$=are_cashhdr.cash_rec_cd$
			are_cashdet.ar_inv_no$=ar_inv_no$
			are_cashdet.apply_amt$=invoice_pay$
			are_cashdet.batch_no$=are_cashhdr.batch_no$
			are_cashdet.memo_1024$=$01$
			are_cashdet.firm_id$=field(are_cashdet$)
			writerecord(are_cashdet)are_cashdet$

			are_cashbal.firm_id$=firm_id$
			are_cashbal.customer_id$=are_cashhdr.customer_id$
			are_cashbal.ar_inv_no$=ar_inv_no$
			are_cashbal.apply_amt$=invoice_pay$
			are_cashbal$=field(are_cashbal$)
			writerecord(are_cashbal)are_cashbal$

		endif
	next inv_row
	cash_msg$=Translate!.getTranslation("AON_CASH_RECEIPT_HAS_BEEN_ENTERED","Cash Receipt has been entered.")
    
	return

rem ==========================================================================
write_to_response_log:rem --- write to art_resphdr/det
rem --- in: firm_id$, cust_id$, trans_id$, response_text$, vectInvoices!
rem ==========================================================================

	art_resphdr.firm_id$=firm_id$
	art_resphdr.customer_id$=cust_id$
	art_resphdr.transaction_id$=trans_id$
	art_resphdr.gateway_id$=gateway$
	art_resphdr.amount$=trans_amount$
	art_resphdr.approve_decline$=trans_approved$
	art_resphdr.response_text$=response_text$
	art_resphdr.created_user$=sysinfo.user_id$
	art_resphdr.created_date$=date(0:"%Yd%Mz%Dz")
	art_resphdr.created_time$=date(0:"%Hz%mz")
	art_resphdr.deposit_id$=deposit_id$
	art_resphdr.batch_no$=batch_no$
	art_resphdr$=field(art_resphdr$)
	writerecord(art_resphdr)art_resphdr$

	next_seq=1
	seq_mask$=fill(len(art_respdet.sequence_no$),"0")
	
	for inv_row=0 to vectInvoices!.size()-1 step num(callpoint!.getDevObject("grid_cols"))
		pay_flag$=vectInvoices!.get(inv_row)
		invoice_pay$=vectInvoices!.get(inv_row+num(callpoint!.getDevObject("pay_col")))
		if pay_flag$="Y"
			ar_inv_no$=vectInvoices!.get(inv_row+1)
			redim art_respdet$
			art_respdet.firm_id$=firm_id$
			art_respdet.customer_id$=cust_id$
			art_respdet.transaction_id$=trans_id$
			art_respdet.sequence_no$=str(next_seq:seq_mask$)
			art_respdet.ar_inv_no$=ar_inv_no$;rem actual invoice selected or OAymmdd
			art_respdet.order_no$="";rem for future use by OP
			art_respdet.apply_amt$=invoice_pay$
			art_respdet$=field(art_respdet$)
			writerecord(art_respdet)art_respdet$
			next_seq=next_seq+1
		endif
	next inv_row

	return

rem ==========================================================================
get_gateway_config:rem --- get config for specified gateway
rem --- in: gateway_id$; out: hashmap gw_config! containing config entries
rem ==========================================================================

	encryptor! = new Encryptor()
	config_id$ = "GATEWAY_AUTH"
	encryptor!.setConfiguration(config_id$)

	read(arc_gatewaydet,key=firm_id$+gateway_id$,dom=*next)
	gw_config!=new java.util.HashMap()

	while 1
		readrecord(arc_gatewaydet,end=*break)arc_gatewaydet$
		if pos(firm_id$+gateway_id$=arc_gatewaydet$)<>1 then break
		if gw_config!.get("gateway_id")=null() then gw_config!.put("gateway_id",gateway_id$)
		gw_config!.put(cvs(arc_gatewaydet.config_attr$,3),encryptor!.decryptData(cvs(arc_gatewaydet.config_value$,3)))
	wend

	callpoint!.setDevObject("gw_config",gw_config!)

	return

rem ==========================================================================
reset_timer: rem --- reset timer for another 10 seconds from each AVAL, or from grid switch_value
rem ==========================================================================

rem --- Set timer for form - closes after a minute of inactivity
rem --- Only used when interface_tp$="A" (so sensitive info like credit card number and cvv don't remain visible)

	if callpoint!.getDevObject("interface_tp")="A"
		timer_key!=10000
		BBjAPI().removeTimer(10000)
		BBjAPI().createTimer(timer_key!,60,"custom_event")
	endif

	return

rem =====================================================================
rem --- parse PayPal response text
rem --- wkx0$=response, wkx1$=key to look for, wkx2$=delim used to separate key/value pairs

def fnparse$(wkx0$,wkx1$,wkx2$)

	wkx3$=""
	wk1=pos(wkx1$=wkx0$)
	if wk1
		wkx3$=wkx0$(wk1+len(wkx1$))
		wk2=pos(wkx2$=wkx3$)
		if wk2
			wkx3$=wkx3$(1,wk2-1)
		endif
	endif
	return wkx3$
	fnend

#include std_missing_params.src
