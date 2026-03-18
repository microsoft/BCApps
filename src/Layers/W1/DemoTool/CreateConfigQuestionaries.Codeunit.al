codeunit 101934 "Create Config. Questionaries"
{

    trigger OnRun()
    begin
    end;

    var
        XGLTxt: Label 'GL', Locked = true;
        XSRTxt: Label 'SR', Locked = true;
        XPPTxt: Label 'PP', Locked = true;
        XISTxt: Label 'IS', Locked = true;
        XGLAllowPostingFromQst: Label 'If you want to limit the date interval for which posting is allowed, enter the Allow Posting From date here.', Locked = true;
        XGLAllowPostingToQst: Label 'If you want to limit the date interval for which posting is allowed, enter the Allow Posting To date here.', Locked = true;
        XGLRegisterTimeQst: Label 'Do you want to register the amount of a user''s time usage in %1?', Comment = '%1 - product name', Locked = true;
        XGLLocalAddressFormatQst: Label 'What address format do you want to use? Options: 0:Post Code+City, 1:City+Post Code, 2:City+State+Post Code, 3:Blank Line+Post Code+City.', Locked = true;
        XGLLocalContAddrFormatQst: Label 'Where in the address do you want the name of a contact person to be printed? Options: 0:First, 1:After Company Code, 2:Last.', Locked = true;
        XGLInvRoundingPrecisionLCYQst: Label 'What amount of precision rounding do you want to apply to invoices? For example, 0.01 or 0.05.', Locked = true;
        XGLInvRoundingTypeLCYQst: Label 'What invoice rounding type do you want to use? Options: 0:Nearest, 1:Up, 2:Down.', Locked = true;
        XGLAllowGLAccDeletionBeforeQst: Label 'Do you want to specify when general ledger accounts can be deleted?', Locked = true;
        XGLCheckGLAccountUsageQst: Label 'Do you want to check if a general ledger account is used before you delete the account?', Locked = true;
        XGLEMUCurrencyQst: Label 'Is the local currency an EMU currency?', Locked = true;
        XGLLCYCodeQst: Label 'What is the currency code of the local currency (LCY)? For example, the code for US dollar is USD.', Locked = true;
        XGLPmtDiscExclVATQst: Label 'Do you want the payment discount calculated on the basis of the amount excluding VAT?', Locked = true;
        XGLAdjustforPaymentDiscQst: Label 'Do you want VAT amounts to be recalculated when you post payments that trigger payment discounts?', Locked = true;
        XGLUnrealizedVATQst: Label 'Do you want unrealized VAT to be handled?', Locked = true;
        XGLMaxVATDifferenceAllowedQst: Label 'If you want to allow a difference in the VAT amount, enter the maximum allowed difference.', Locked = true;
        XGLVATRoundingTypeQst: Label 'What VAT rounding type do you want to use? Options: 0:Nearest, 1:Up, 2:Down.', Locked = true;
        XGLAdditionalReportingCurrencyQst: Label 'Do you want to be able to show general ledger entries or reports in a secondary currency? Choose one of the default currency codes.', Locked = true;
        XGLVATExchangeRateAdjustmentQst: Label 'If you are using an additional reporting currency, do you want VAT accounts to be adjusted for exchange rate fluctuations? Options: 0:No Adjustment, 1:Adjust Amount, 2:Adjust Additional-Currency Amount.', Locked = true;
        XGLApplnRoundingPrecisionQst: Label 'Do you want to allow rounding differences in the local currency when you apply entries in the local currency to entries in a different currency?', Locked = true;
        XGLPmtDiscToleranceWarningQst: Label 'Do you want a warning if the payment discount tolerance is exceeded?', Locked = true;
        XGLPmtDiscTolerancePostingQst: Label 'Which posting method do you want to use when you post a payment discount tolerance? Options: 0:Payment Tolerance Accounts, 1:Payment Discount Accounts.', Locked = true;
        XGLPaymentDiscountGracePeriodQst: Label 'Do you want to allow a payment discount grace period?', Locked = true;
        XGLPaymentToleranceWarningQst: Label 'Do you want a warning if the maximum payment tolerance is exceeded?', Locked = true;
        XGLPaymentTolerancePostingQst: Label 'Which posting method do you want to use when you post a payment tolerance? Options: 0:Payment Tolerance Accounts, 1:Payment Discount Accounts.', Locked = true;
        XGLPaymentTolerancePctQst: Label 'What percentage payment tolerance do you want to allow for invoices or credit memos?', Locked = true;
        XGLMaxPaymentToleranceAmountQst: Label 'What is the maximum tolerance amount that you want to allow for payments or refunds on invoices or credit memos?', Locked = true;
        XISAutomaticCostPostingQst: Label 'Do you want to use the Automatic Cost Posting function?', Locked = true;
        XISExpectedCostPostingtoGLQst: Label 'Do you want to post expected costs?', Locked = true;
        XISAverageCostCalcTypeQst: Label 'Which method do you want to use to calculate the average cost? If you change the method, all entries will be adjusted. Options: 1 - Item, 2 - Item & Location & Variant', Locked = true;
        XISCopyCommentsOrdertoShptQst: Label 'Do you want to copy comments from transfer orders to transfer shipments?', Locked = true;
        XISCopyCommentsOrdertoRcptQst: Label 'Do you want to copy comments from transfer orders to transfer receipts?', Locked = true;
        XISOutboundWhseHandlingTimeQst: Label 'Enter a date formula for the outbound warehouse handling time for your company.', Locked = true;
        XISInboundWhseHandlingTimeQst: Label 'Enter a date formula for the inbound warehouse handling time for your company.', Locked = true;
        XISLocationMandatoryQst: Label 'Do items require a location code in order to be posted?', Locked = true;
        XPPDiscountPostingQst: Label 'Which type of discount should be posted separately in the general ledger? Options: 0:No Discounts, 1:Invoice Discounts, 2:Line Discounts, 3:All Discounts.', Locked = true;
        XPPReceiptonInvoiceQst: Label 'When you post a direct invoice, do you want to automatically create a posted receipt?', Locked = true;
        XPPReturnShipmentonCreditMemoQst: Label 'When you post a credit memo, do you want to automatically create a posted return shipment and a posted purchase credit memo?', Locked = true;
        XPPInvoiceRoundingQst: Label 'Do you want to automatically round invoice amounts?', Locked = true;
        XPPExtDocNoMandatoryQst: Label 'Are external document numbers required on purchase orders and general journals?', Locked = true;
        XPPAllowVATDifferenceQst: Label 'Do you want to allow manual adjustments of the VAT amount on purchase documents?', Locked = true;
        XPPCalcInvDiscountQst: Label 'If you receive a fixed discount percent from a vendor, do you want the discount to be calculated automatically on the invoice?', Locked = true;
        XPPCalcInvDiscperVATIDQst: Label 'Do you want the invoice discount to be calculated according to VAT identifier?', Locked = true;
        XPPApplnbetweenCurrenciesQst: Label 'For vendors, do you want to allow the application of entries to be in more than one currency?', Locked = true;
        XPPCopyCommentsBlankettoOrderQst: Label 'Do you want to copy comments from blanket orders to purchase orders?', Locked = true;
        XPPCopyCommentsOrdertoInvoiceQst: Label 'Do you want to copy comments from purchase orders to purchase invoices?', Locked = true;
        XPPCopyCommentsOrdertoReceiptQst: Label 'Do you want to copy comments from purchase orders to receipts?', Locked = true;
        XPPCopyCmtsRetOrdtoCrMemoQst: Label 'Do you want to copy comments from return orders to credit memos?', Locked = true;
        XPPCopyCmtsRetOrdtoRetShptQst: Label 'Do you want to copy comments from credit memos to posted return shipments?', Locked = true;
        XPPExactCostReversingMandatoryQst: Label 'Do you want exact cost reversing to be mandatory?', Locked = true;
        XSRDiscountPostingQst: Label 'Which type of discount should be posted separately in the general ledger?', Locked = true;
        XSRCreditWarningsQst: Label 'Do you want a warning about customer credit status when you create a sales order or invoice?', Locked = true;
        XSRStockoutWarningQst: Label 'Do you want a warning when a sale will result in a negative inventory for an inventory item?', Locked = true;
        XSRShipmentonInvoiceQst: Label 'Are shipments done separately from invoicing?', Locked = true;
        XSRReturnReceiptonCreditMemoQst: Label 'When you post a credit memo, do you want to automatically create a posted return receipt and posted sales credit memo?', Locked = true;
        XSRInvoiceRoundingQst: Label 'Do you want sales invoice amounts to be rounded?', Locked = true;
        XSRExtDocNoMandatoryQst: Label 'Are external document numbers required on sales orders?', Locked = true;
        XSRApplnbetweenCurrenciesQst: Label 'For customers, do you want to allow the application of entries to be in more than one currency?', Locked = true;
        XSRCopyCommentsBlankettoOrderQst: Label 'Do you want to copy comments from blanket orders to sales orders?', Locked = true;
        XSRCopyCommentsOrdertoInvoiceQst: Label 'Do you want to copy comments from sales orders to sales invoices?', Locked = true;
        XSRCopyCommentsOrdertoShptQst: Label 'Do you want to copy comments from sales orders to shipments?', Locked = true;
        XSRCopyCmtsRetOrdtoCrMemoQst: Label 'Do you want to copy comments from return orders to credit memos?', Locked = true;
        XSRCopyCmtsRetOrdtoRetRcptQst: Label 'Do you want to copy comments from return orders to return receipts?', Locked = true;
        XSRAllowVATDifferenceQst: Label 'Do you want to allow manual adjustments of VAT amounts in sales documents?', Locked = true;
        XSRCalcInvDiscountQst: Label 'Do you want to automatically calculate the invoice discount amount in connection with sales documents?', Locked = true;
        XSRCalcInvDiscperVATIDQst: Label 'Do you want the invoice discount to be calculated according to the VAT identifier?', Locked = true;
        XSRExactCostReversingMandatoryQst: Label 'Do you want exact cost reversing to be mandatory?', Locked = true;

    local procedure Initialize()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
    begin
        if not ConfigQuestionnaire.IsEmpty() then
            ConfigQuestionnaire.DeleteAll(true);
    end;

    local procedure CreateQuestion(var ConfigQuestion: Record "Config. Question"; ConfigQuestionArea: Record "Config. Question Area"; FieldID: Integer; Question: Text[250])
    var
        ConfigQuestion2: Record "Config. Question";
    begin
        ConfigQuestion2.SetRange("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion2.SetRange("Question Area Code", ConfigQuestionArea.Code);
        if ConfigQuestion2.FindLast() then;

        ConfigQuestion.Init();
        ConfigQuestion.Validate("Questionnaire Code", ConfigQuestionArea."Questionnaire Code");
        ConfigQuestion.Validate("Question Area Code", ConfigQuestionArea.Code);
        ConfigQuestion.Validate("No.", ConfigQuestion2."No." + 1);
        ConfigQuestion.Validate("Table ID", ConfigQuestionArea."Table ID");
        ConfigQuestion.Validate("Field ID", FieldID);
        ConfigQuestion.Validate(Question, Question);
        ConfigQuestion.Insert(true);
    end;

    local procedure CreateQuestionArea(var ConfigQuestionArea: Record "Config. Question Area"; QuestionnaireCode: Code[10]; "Code": Code[10]; Description: Text[50]; TableID: Integer)
    begin
        ConfigQuestionArea.Init();
        ConfigQuestionArea.Validate("Questionnaire Code", QuestionnaireCode);
        ConfigQuestionArea.Validate(Code, Code);
        ConfigQuestionArea.Validate(Description, Description);
        ConfigQuestionArea.Validate("Table ID", TableID);
        ConfigQuestionArea.Insert(true);
    end;

    local procedure CreateQuestionnaire(var ConfigQuestionnaire: Record "Config. Questionnaire"; "Code": Code[10]; Description: Text[50])
    begin
        ConfigQuestionnaire.Init();
        ConfigQuestionnaire.Validate(Code, Code);
        ConfigQuestionnaire.Validate(Description, Description);
        ConfigQuestionnaire.Insert(true);
    end;

    procedure CreateQuestionnaires()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestion: Record "Config. Question";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        InventorySetup: Record "Inventory Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        Initialize();
        GenJnlBatch.SetRange("Template Type", GenJnlBatch."Template Type"::Assets);
        GenJnlBatch.FindFirst();
        CreateQuestionnaire(ConfigQuestionnaire, GenJnlBatch.Name, ConfigQuestionnaire.TableCaption());
        CreateQuestionArea(
          ConfigQuestionArea, ConfigQuestionnaire.Code, XGLTxt, GeneralLedgerSetup.TableCaption(), DATABASE::"General Ledger Setup");
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Allow Posting From"), XGLAllowPostingFromQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Allow Posting To"), XGLAllowPostingToQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Register Time"), StrSubstNo(XGLRegisterTimeQst, PRODUCTNAME.Full()));
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Local Address Format"), XGLLocalAddressFormatQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Local Cont. Addr. Format"), XGLLocalContAddrFormatQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Inv. Rounding Precision (LCY)"), XGLInvRoundingPrecisionLCYQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Inv. Rounding Type (LCY)"), XGLInvRoundingTypeLCYQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Allow G/L Acc. Deletion Before"), XGLAllowGLAccDeletionBeforeQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Check G/L Account Usage"), XGLCheckGLAccountUsageQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("EMU Currency"), XGLEMUCurrencyQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("LCY Code"), XGLLCYCodeQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Pmt. Disc. Excl. VAT"), XGLPmtDiscExclVATQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Adjust for Payment Disc."), XGLAdjustforPaymentDiscQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Unrealized VAT"), XGLUnrealizedVATQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Max. VAT Difference Allowed"), XGLMaxVATDifferenceAllowedQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("VAT Rounding Type"), XGLVATRoundingTypeQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Additional Reporting Currency"),
          XGLAdditionalReportingCurrencyQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("VAT Exchange Rate Adjustment"), XGLVATExchangeRateAdjustmentQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Appln. Rounding Precision"), XGLApplnRoundingPrecisionQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Pmt. Disc. Tolerance Warning"), XGLPmtDiscToleranceWarningQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Pmt. Disc. Tolerance Posting"), XGLPmtDiscTolerancePostingQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Payment Discount Grace Period"),
          XGLPaymentDiscountGracePeriodQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Payment Tolerance Warning"), XGLPaymentToleranceWarningQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Payment Tolerance Posting"), XGLPaymentTolerancePostingQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Payment Tolerance %"), XGLPaymentTolerancePctQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, GeneralLedgerSetup.FieldNo("Max. Payment Tolerance Amount"), XGLMaxPaymentToleranceAmountQst);

        CreateQuestionArea(
          ConfigQuestionArea, ConfigQuestionnaire.Code, XISTxt, InventorySetup.TableCaption(), DATABASE::"Inventory Setup");
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, InventorySetup.FieldNo("Automatic Cost Posting"), XISAutomaticCostPostingQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, InventorySetup.FieldNo("Expected Cost Posting to G/L"), XISExpectedCostPostingtoGLQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, InventorySetup.FieldNo("Average Cost Calc. Type"), XISAverageCostCalcTypeQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, InventorySetup.FieldNo("Copy Comments Order to Shpt."), XISCopyCommentsOrdertoShptQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, InventorySetup.FieldNo("Copy Comments Order to Rcpt."), XISCopyCommentsOrdertoRcptQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, InventorySetup.FieldNo("Outbound Whse. Handling Time"), XISOutboundWhseHandlingTimeQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, InventorySetup.FieldNo("Inbound Whse. Handling Time"), XISInboundWhseHandlingTimeQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, InventorySetup.FieldNo("Location Mandatory"), XISLocationMandatoryQst);

        CreateQuestionArea(
          ConfigQuestionArea, ConfigQuestionnaire.Code, XPPTxt, PurchasesPayablesSetup.TableCaption(), DATABASE::"Purchases & Payables Setup");
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Discount Posting"),
          XPPDiscountPostingQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Receipt on Invoice"),
          XPPReceiptonInvoiceQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Return Shipment on Credit Memo"),
          XPPReturnShipmentonCreditMemoQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Invoice Rounding"),
          XPPInvoiceRoundingQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Ext. Doc. No. Mandatory"),
          XPPExtDocNoMandatoryQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Allow VAT Difference"),
          XPPAllowVATDifferenceQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Calc. Inv. Discount"),
          XPPCalcInvDiscountQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Calc. Inv. Disc. per VAT ID"),
          XPPCalcInvDiscperVATIDQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Appln. between Currencies"),
          XPPApplnbetweenCurrenciesQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Copy Comments Blanket to Order"),
          XPPCopyCommentsBlankettoOrderQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Copy Comments Order to Invoice"),
          XPPCopyCommentsOrdertoInvoiceQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Copy Comments Order to Receipt"),
          XPPCopyCommentsOrdertoReceiptQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Copy Cmts Ret.Ord. to Cr. Memo"),
          XPPCopyCmtsRetOrdtoCrMemoQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Copy Cmts Ret.Ord. to Ret.Shpt"),
          XPPCopyCmtsRetOrdtoRetShptQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, PurchasesPayablesSetup.FieldNo("Exact Cost Reversing Mandatory"),
          XPPExactCostReversingMandatoryQst);

        CreateQuestionArea(
          ConfigQuestionArea, ConfigQuestionnaire.Code, XSRTxt, SalesReceivablesSetup.TableCaption(), DATABASE::"Sales & Receivables Setup");
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Discount Posting"), XSRDiscountPostingQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Credit Warnings"), XSRCreditWarningsQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Stockout Warning"), XSRStockoutWarningQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Shipment on Invoice"), XSRShipmentonInvoiceQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Return Receipt on Credit Memo"),
          XSRReturnReceiptonCreditMemoQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Invoice Rounding"), XSRInvoiceRoundingQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Ext. Doc. No. Mandatory"), XSRExtDocNoMandatoryQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Appln. between Currencies"), XSRApplnbetweenCurrenciesQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Copy Comments Blanket to Order"),
          XSRCopyCommentsBlankettoOrderQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Copy Comments Order to Invoice"),
          XSRCopyCommentsOrdertoInvoiceQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Copy Comments Order to Shpt."),
          XSRCopyCommentsOrdertoShptQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Copy Cmts Ret.Ord. to Cr. Memo"),
          XSRCopyCmtsRetOrdtoCrMemoQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Copy Cmts Ret.Ord. to Ret.Rcpt"),
          XSRCopyCmtsRetOrdtoRetRcptQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Allow VAT Difference"), XSRAllowVATDifferenceQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Calc. Inv. Discount"), XSRCalcInvDiscountQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Calc. Inv. Disc. per VAT ID"), XSRCalcInvDiscperVATIDQst);
        CreateQuestion(
          ConfigQuestion, ConfigQuestionArea, SalesReceivablesSetup.FieldNo("Exact Cost Reversing Mandatory"),
          XSRExactCostReversingMandatoryQst);
    end;
}

