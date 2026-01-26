codeunit 144137 "ERM Norge SEPA CT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Credit Transfer]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';
        ExportHasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        ALotOfRegRepCodesNotAllowedErr: Label 'It is not allowed to have more than 10 regulatory reporting codes.';
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryRemittance: Codeunit "Library - Remittance";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure RegRepCodeCreateNew()
    var
        RegulatoryReportingCode: Record "Regulatory Reporting Code";
        RegulatoryReportingCodes: TestPage "Regulatory Reporting Codes";
        RegCode: Code[10];
        RegDescr: Text[35];
    begin
        // [FEATURE] [Regulatory Reporting Code] [UI]
        // [SCENARIO 221200] Add new Regulatory Reporting Code via page
        RegCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(
              RegulatoryReportingCode.FieldNo(Code), DATABASE::"Regulatory Reporting Code"),
            1, MaxStrLen(RegulatoryReportingCode.Code));
        RegDescr := LibraryUtility.GenerateGUID();
        Commit();

        RegulatoryReportingCodes.OpenNew();
        RegulatoryReportingCodes.Code.SetValue(RegCode);
        RegulatoryReportingCodes.Description.SetValue(RegDescr);
        RegulatoryReportingCodes.Close();

        RegulatoryReportingCode.Get(RegCode);
        RegulatoryReportingCode.TestField(Description, RegDescr);
    end;

    [Test]
    [HandlerFunctions('GenJnlRegPerCodesPageHandler')]
    [Scope('OnPrem')]
    procedure GenJnlLineRegRepCodeCreateNew()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlLineRegRepCode: Record "Gen. Jnl. Line Reg. Rep. Code";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PaymentJournal: TestPage "Payment Journal";
        RegCode: Code[10];
    begin
        // [FEATURE] [Regulatory Reporting Code] [UI]
        // [SCENARIO 221200] Add Regulatory Reporting Code to Gen Journal Line via page
        CreatePaymentGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(100, 2));
        RegCode := CreateRegRepCode();
        LibraryVariableStorage.Enqueue(RegCode);
        Commit();
        PaymentJournal.Trap();

        GeneralJournalBatches.OpenView();
        GeneralJournalBatches.FILTER.SetFilter("Journal Template Name", GenJournalBatch."Journal Template Name");
        GeneralJournalBatches.EditJournal.Invoke();

        PaymentJournal.CurrentJnlBatchName.AssertEquals(GenJournalBatch.Name);
        PaymentJournal."Regulatory Reporting Codes".Invoke();

        FilterGenJnlRegRepCode(GenJnlLineRegRepCode, GenJournalLine);
        GenJnlLineRegRepCode.FindFirst();
        GenJnlLineRegRepCode.TestField("Reg. Code", RegCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankExportimportSetupRegThreshAmt()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        BankExportImportSetupPage: TestPage "Bank Export/Import Setup";
        ThreshAmt: Decimal;
    begin
        // [FEATURE] [Regulatory Reporting Threshold] [UI]
        // [SCENARIO 221200] Update Reg.Reporting Thresh.Amt (LCY) on Bank Export/Import Setup page
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup.Insert();
        ThreshAmt := LibraryRandom.RandDec(100, 2);

        BankExportImportSetupPage.OpenEdit();
        BankExportImportSetupPage.GotoRecord(BankExportImportSetup);
        BankExportImportSetupPage.RegReportingThreshAmtLCY.SetValue(ThreshAmt);
        BankExportImportSetupPage.Close();

        BankExportImportSetup.Find();
        BankExportImportSetup.TestField("Reg.Reporting Thresh.Amt (LCY)", ThreshAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsNorgeExport()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentTools: Codeunit DocumentTools;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 221200] IsNorgeSEPACT returns TRUE for Norge Bank Export/Import Setup
        CreatePaymentGenJnlBatch(GenJournalBatch);
        MockGenJnlLine(GenJournalLine, GenJournalBatch, CreateNorgeBankExportImportSetup(0));
        GenJournalBatch."Bal. Account No." := GenJournalLine."Bal. Account No.";
        GenJournalBatch.Modify();
        Assert.IsTrue(DocumentTools.IsNorgeSEPACT(GenJournalLine), 'It should be Norge Export');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsNorgeExportFalse()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentTools: Codeunit DocumentTools;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 221200] IsNorgeSEPACT returns FALSE for any Bank Export/Import Setup
        CreatePaymentGenJnlBatch(GenJournalBatch);
        MockGenJnlLine(GenJournalLine, GenJournalBatch, LibraryUtility.GenerateGUID());
        GenJournalBatch."Bal. Account No." := GenJournalLine."Bal. Account No.";
        GenJournalBatch.Modify();
        Assert.IsFalse(DocumentTools.IsNorgeSEPACT(GenJournalLine), 'It should not be Norge Export');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportBufferRegRepThreshAmtFalse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        Amount: Decimal;
    begin
        // [FEATURE] [Regulatory Reporting Threshold]
        // [SCENARIO 221200] Payment Export Buffer with Reg.Rep. Thresh.Amt Exceeded FALSE
        // [GIVEN] Bank Export/Import Setup with 'Reg.Reporting Thresh.Amt (LCY)' = 1000
        // [GIVEN] Gen. Journal Line with Amount = 500
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(Amount * 2)),
          Amount, 1);

        // [WHEN] Fill Export Buffer
        SEPACTFillExportBuffer.FillExportBuffer(GenJournalLine, TempPaymentExportData);

        // [THEN] 'Reg.Rep. Thresh.Amt Exceeded' is false
        TempPaymentExportData.TestField("Reg.Rep. Thresh.Amt Exceeded", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportBufferRegRepThreshAmtTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        Amount: Decimal;
    begin
        // [FEATURE] [Regulatory Reporting Threshold]
        // [SCENARIO 221200] Payment Export Buffer with Reg.Rep. Thresh.Amt Exceeded TRUE
        // [GIVEN] Bank Export/Import Setup with 'Reg.Reporting Thresh.Amt (LCY)' = 1000
        // [GIVEN] Gen. Journal Line with Amount = 2000
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(Amount)),
          Amount * 2, 1);

        // [WHEN] Fill Export Buffer
        SEPACTFillExportBuffer.FillExportBuffer(GenJournalLine, TempPaymentExportData);

        // [THEN] 'Reg.Rep. Thresh.Amt Exceeded' is false
        TempPaymentExportData.TestField("Reg.Rep. Thresh.Amt Exceeded", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportBufferTooMuchRegCodes()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        GenJournalLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        i: Integer;
    begin
        // [FEATURE] [Regulatory Reporting Code]
        // [SCENARIO 221200] Not allowed to make export when more that 10 Reg.Reporting Codes assigned to Gen. Jnl. line.
        // [GIVEN] Gen. Journal Line with 11 Reg.Reporting Codes
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(LibraryRandom.RandDec(100, 2))),
          LibraryRandom.RandDec(100, 2), 1);
        for i := 1 to LibraryRandom.RandIntInRange(15, 20) do
            CreateGenJnlLineRegRepCode(GenJournalLine);

        // [WHEN] Fill Export Buffer
        asserterror SEPACTFillExportBuffer.FillExportBuffer(GenJournalLine, TempPaymentExportData);

        // [THEN] Error 'It is not allowed to have more than 10 Regulatory Reporting Codes.'
        Assert.ExpectedError(ExportHasErrorsErr);
        Assert.ExpectedErrorCode('Dialog');
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJournalLine."Line No.");
        PaymentJnlExportErrorText.FindFirst();
        PaymentJnlExportErrorText.TestField("Error Text", ALotOfRegRepCodesNotAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXmlWhenThreshAmtNotExceeded()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Amount: Decimal;
    begin
        // [FEATURE] [Regulatory Reporting Threshold]
        // [SCENARIO 221200] Export Gen. Jnl. Line that does not exceed Reg. Rep. Thrash. Amount with Reg. Rep. Code

        // [GIVEN] Gen. Journal Line that does not exceed Reg. Rep. Thrash. Amount with Reg. Rep. Code
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(Amount * 2)),
          Amount, 1);
        CreateGenJnlLineRegRepCode(GenJournalLine);

        TempBlob.CreateOutStream(OutStr);
        BankAccount.Get(GenJournalLine."Bal. Account No.");

        // [WHEN] Export Gen. Journal Line with SEPA CT pain.001.001.09 port
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJournalLine);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);

        // [THEN] 'RgltryRptg' tag is not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('//RgltryRptg');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXmlWhenThreshAmtExceeded()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GenJnlLineRegRepCode: Record "Gen. Jnl. Line Reg. Rep. Code";
        TempBlob: Codeunit "Temp Blob";
        NodeList: DotNet XmlNodeList;
        OutStr: OutStream;
        EndToEndId: array[2] of Text;
        Amount: Decimal;
    begin
        // [FEATURE] [Regulatory Reporting Threshold]
        // [SCENARIO 221200] Export Gen. Journal Line that exceeded Reg. Rep. Thrash. Amount with two Reg. Rep. Code

        // [GIVEN] One regular Gen. Journal Line "G2"
        // [GIVEN] One Gen. Journal Line "G1" that exceeded Reg. Rep. Thrash. Amount with two Reg. Rep. Code
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(Amount)),
          Amount * 2, 2);
        CreateGenJnlLineRegRepCode(GenJournalLine);
        CreateGenJnlLineRegRepCode(GenJournalLine);

        TempBlob.CreateOutStream(OutStr);
        BankAccount.Get(GenJournalLine."Bal. Account No.");

        // [WHEN] Export Gen. Journal Line with SEPA CT pain.001.001.09 port
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJournalLine);

        // [THEN] Xml file contains 2 tags 'RgltryRptg' for "G1"
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.GetNodeList('//RgltryRptg', NodeList);
        Assert.AreEqual(2, NodeList.Count, 'Should be 2 nodes');

        // [THEN] Each 'RgltryRptg' tag contains Gen. Jnl. Line Reg. Rep. Code with Description
        FilterGenJnlRegRepCode(GenJnlLineRegRepCode, GenJournalLine);
        GenJnlLineRegRepCode.FindFirst();
        VerifyTagRgltryRptg(NodeList.Item(0).FirstChild, GenJnlLineRegRepCode);
        GenJnlLineRegRepCode.FindLast();
        VerifyTagRgltryRptg(NodeList.Item(1).FirstChild, GenJnlLineRegRepCode);

        // [THEN] <InstrId> tag contains a GUID value (TFS 306878)
        LibraryXPathXMLReader.VerifyNodeValueIsGuid('//InstrId');

        // [THEN] <EndToEndId> tag value isn't repeated for "G1" and "G2" (TFS 306878)
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//EndToEndId', 2);
        EndToEndId[1] := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//EndToEndId', 0);
        EndToEndId[2] := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//EndToEndId', 1);
        Assert.AreNotEqual(EndToEndId[1], EndToEndId[2],
          'Unexpectedly repeating value in xml file for element ''EndToEndId''.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunSuggestVendorPaymentsWithRemittance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLinePmt: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [FEATURE] [Remittance]
        // [SCENARIO 231423] Run Suggest Vendor Payment report for Vendor with Remittance
        Initialize();

        // [GIVEN] Vendor with Remittance Account = "A" and Remittance Agreement = "B"
        VendorNo := CreateVendorWithBankAcc();
        UpdateVendorWithRemittance(VendorNo, CreateRemittanceAccountWithAgreement());

        // [GIVEN] Posted Purchase Invoice for the vendor
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Suggest Vendor Payment
        InitGenJournalLine(GenJournalLinePmt);
        RunSuggestVendorPayments(GenJournalLinePmt, VendorNo);

        // [THEN] Suggested payment line has Remittance Account = "A" and Remittance Agreement = "B"
        Vendor.Get(VendorNo);
        GenJournalLinePmt.SetRange("Account No.", VendorNo);
        GenJournalLinePmt.FindFirst();
        GenJournalLinePmt.TestField("Remittance Account Code", Vendor."Remittance Account Code");
        GenJournalLinePmt.TestField("Remittance Agreement Code", Vendor."Remittance Agreement Code");
        // [THEN] "External Document No." and "Applies-to Ext. Doc. No." created from the Invoice's "External Document No." (TFS 230901)
        GenJournalLinePmt.TestField("External Document No.", GenJournalLine."External Document No.");
        GenJournalLinePmt.TestField("Applies-to Ext. Doc. No.", GenJournalLine."External Document No.");
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsRequestPageHandler,MessageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestRemittancePaymentsFillsGenJournalLineBalanceAndTotalsOnPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineInvoice: Record "Gen. Journal Line";
        GenJournalLinePayment: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Suggest Remittance Payments] [Payment Journal] [UI]
        // [SCENARIO 233092] When push "Remittance Suggestion" on "Payment Journal" page ribbon then Total Balance and Balance are populated on page.
        Initialize();

        // [GIVEN] Payment template "T" and batch "B"
        CreatePaymentJnlBatchWithBankAccount(GenJournalBatch);

        // [GIVEN] Posted Purchase Invoice for Vendor with Remittance, Line Amount = 100
        PostPurchaseInvoiceForVendorWithRemittance(GenJournalLineInvoice, GenJournalBatch);

        // [GIVEN] General Journal Line "P" with template "T" and batch "B", with "Bal. Account Type" = Bank Account and non-empty "Bal. Account No."
        InitGenJournalLineForPaymentJournalsPage(GenJournalLinePayment, GenJournalBatch);

        // [GIVEN] Payment Journal page is opened for template "T" and batch "B", and record "P" is selected on page
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLinePayment."Journal Batch Name");
        PaymentJournal.GotoRecord(GenJournalLinePayment);

        // [WHEN] Push "Remittance Suggestion" on page ribbon
        LibraryVariableStorage.Enqueue(GenJournalLineInvoice."Account No.");
        LibraryVariableStorage.Enqueue(GetRemittanceAccountForVendor(GenJournalLineInvoice."Account No."));
        LibraryVariableStorage.Enqueue(WorkDate());

        PaymentJournal.SuggestRemittancePayments.Invoke();

        // [THEN] Created Payment Journal Line has "Balance (LCY)" = 100
        GenJournalLinePayment.SetRange("Account Type", GenJournalLinePayment."Account Type"::Vendor);
        GenJournalLinePayment.SetRange("Account No.", GenJournalLineInvoice."Account No.");
        Assert.RecordCount(GenJournalLinePayment, 1);
        GenJournalLinePayment.FindFirst();
        GenJournalLinePayment.TestField("Balance (LCY)", -GenJournalLineInvoice.Amount);

        // [THEN] Total Balance = 100 on Payment Journal page
        PaymentJournal.TotalBalance.AssertEquals(-GenJournalLineInvoice.Amount);

        // [THEN] Balance = 100 on Payment Journal page for created line
        PaymentJournal.GotoRecord(GenJournalLinePayment);
        PaymentJournal.Balance.AssertEquals(-GenJournalLineInvoice.Amount);

        PaymentJournal.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PopulatedKIDforPaymentJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        KundeID: Code[30];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Suggest Vendor Payments] [KID]
        // [SCENARIO 305007] Report Suggest Vendor Payments populates Payment Journal Line KID field from posted document
        Initialize();

        KundeID := '12345678911';
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Posted Purchase Invoice for the vendor with populated KID
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate(KID, KundeID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Suggest Vendor Payments report
        InitGenJournalLine(GenJournalLine);
        RunSuggestVendorPayments(GenJournalLine, VendorNo);

        // [THEN] Payment Journal Line has KID value assigned from posted Purchase Invoice
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField(KID, KundeID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PopulatedKIDExtDocNoforPaymentJournalExport()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        KundeID: Code[30];
        ExtDocNo: Code[35];
    begin
        // [FEATURE] [KID] [UT]
        // [SCENARIO 305007] Payment Journal Line KID field value is stored in PaymentExportRemittanceText table when running SEPACTFillExportBuffer.FillExportBuffer
        Initialize();

        KundeID := '12345678911';
        ExtDocNo := '0987654321';
        Vendor.Get(CreateVendorWithBankAcc());

        CreatePaymentGenJnlBatch(GenJournalBatch);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(0));
        GenJournalBatch.Modify();

        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          Vendor."No.", GenJournalBatch."Bal. Account Type", GenJournalBatch."Bal. Account No.",
          LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Recipient Bank Account", Vendor."Preferred Bank Account Code");
        GenJournalLine.Validate(KID, KundeID);
        GenJournalLine.Validate("External Document No.");
        GenJournalLine.Modify(true);

        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        SEPACTFillExportBuffer.FillExportBuffer(GenJournalLine, TempPaymentExportData);

        TempPaymentExportData.TestField(KID, GenJournalLine.KID);
        TempPaymentExportData.TestField("External Document No.", GenJournalLine."External Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXmlCheckOrderOfRmtInfRgltryRptgTags()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
        NodeList: DotNet XmlNodeList;
        OutStr: OutStream;
        Amount: Decimal;
        KundeID: Code[30];
        RmtInfIndex: Integer;
        RgltryRptgIndex: Integer;
    begin
        // [FEATURE] [Regulatory Reporting Threshold] [KID] [UT]
        // [SCENARIO 309201] In SEPA CT pain.001.001.09 port 'RmtInf' goes after 'RgltryRptg' tag

        // [GIVEN] Gen. Journal Line "G1" with Reg. Rep. Code and KID
        Amount := LibraryRandom.RandDec(100, 2);
        KundeID := '12345678911';
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(Amount)),
          Amount * 2, 1);
        CreateGenJnlLineRegRepCode(GenJournalLine);
        GenJournalLine.Validate(KID, KundeID);
        GenJournalLine.Modify(true);

        TempBlob.CreateOutStream(OutStr);

        BankAccount.Get(GenJournalLine."Bal. Account No.");

        // [WHEN] Export Gen. Journal Line with SEPA CT pain.001.001.09 port
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJournalLine);

        // [THEN] Xml file contains 'RgltryRptg' and 'RmtInf' tags
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.GetNodeList('//RgltryRptg', NodeList);
        Assert.AreEqual(1, NodeList.Count, 'Should be 1 nodes');
        LibraryXPathXMLReader.GetNodeList('//RmtInf', NodeList);
        Assert.AreEqual(1, NodeList.Count, 'Should be 1 nodes');

        // [THEN] 'RmtInf' goes after 'RgltryRptg' tag
        RmtInfIndex := LibraryXPathXMLReader.GetNodeIndexInSubtree('//CdtTrfTxInf', 'RmtInf');
        RgltryRptgIndex := LibraryXPathXMLReader.GetNodeIndexInSubtree('//CdtTrfTxInf', 'RgltryRptg');
        Assert.IsTrue(RgltryRptgIndex < RmtInfIndex, 'RmtInf should go after RgltryRptg tag');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WaitingJournalPmtInfIdGetsUpdated()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
        NodeList: DotNet XmlNodeList;
        OutStr: OutStream;
        PaymentInfId: array[2] of Text;
        ReqdExctnDt: array[2] of Date;
    begin
        // [FEATURE] [Waiting Journal]
        // [SCENARIO 311097] Waiting Journal "SEPA Payment Inf ID" gets updated after the pre-export grouping by date

        // [GIVEN] GenJnl Lines: GJL1 with "Posting Date" := WorkDate(), GJL2 and GJL3 with "Posting Date" := WorkDate() - 1D
        CreateGenJnlLineWithDateGrouping(GenJournalLine);

        // [WHEN] Export Gen. Journal Line with SEPA CT pain.001.001.09 port
        TempBlob.CreateOutStream(OutStr);

        BankAccount.Get(GenJournalLine."Bal. Account No.");
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJournalLine);

        // [THEN] Xml file contains 2 Payment Groups: first with GJL2 and GJL3, second with GJL1
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.GetNodeList('//PmtInfId', NodeList);
        Assert.AreEqual(2, NodeList.Count, 'Should be 2 nodes');

        // [THEN] Waiting journal values for "SEPA Payment Inf ID" are the same as in the exported file
        PaymentInfId[1] := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//PmtInfId', 0);
        PaymentInfId[2] := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//PmtInfId', 1);
        Evaluate(ReqdExctnDt[1], LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//ReqdExctnDt', 0), 9);
        Evaluate(ReqdExctnDt[2], LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//ReqdExctnDt', 1), 9);

        // [THEN] WaitingJournal."Sepa Payment Inf ID" matches the value in XML
        ValidateWaitingJournal(
          GenJournalLine."Account Type", GenJournalLine."Account No.",
          ReqdExctnDt[1], LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//EndToEndId', 0), PaymentInfId[1]);
        ValidateWaitingJournal(
          GenJournalLine."Account Type", GenJournalLine."Account No.",
          ReqdExctnDt[1], LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//EndToEndId', 1), PaymentInfId[1]);
        ValidateWaitingJournal(
          GenJournalLine."Account Type", GenJournalLine."Account No.",
          ReqdExctnDt[2], LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//EndToEndId', 2), PaymentInfId[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXmlCheckKIDStructure()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
        NodeList: DotNet XmlNodeList;
        OutStr: OutStream;
        Amount: Decimal;
        KundeID: Code[30];
    begin
        // [FEATURE] [Regulatory Reporting Threshold] [KID] [UT]
        // [SCENARIO 318353] In SEPA CT pain.001.001.09 there's structure around KID value

        // [GIVEN] Gen. Journal Line "G1" with  KID
        Amount := LibraryRandom.RandDec(100, 2);
        KundeID := '12345678911';
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(Amount)),
          Amount * 2, 1);
        CreateGenJnlLineRegRepCode(GenJournalLine);
        GenJournalLine.Validate(KID, KundeID);
        GenJournalLine.Modify(true);

        TempBlob.CreateOutStream(OutStr);
        BankAccount.Get(GenJournalLine."Bal. Account No.");

        // [WHEN] Export Gen. Journal Line with SEPA CT pain.001.001.09 port
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJournalLine);

        // [THEN] Xml file contains 'SCOR' and KID value in structure
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.GetNodeList('//RmtInf/Strd/CdtrRefInf/Tp/CdOrPrtry/Cd', NodeList);
        Assert.AreEqual(1, NodeList.Count, 'Should be 1 nodes');
        Assert.AreEqual('SCOR',
          LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//RmtInf/Strd/CdtrRefInf/Tp/CdOrPrtry/Cd', 0), '');

        LibraryXPathXMLReader.GetNodeList('//RmtInf/Strd/CdtrRefInf/Ref', NodeList);
        Assert.AreEqual(1, NodeList.Count, 'Should be 1 nodes');
        Assert.AreEqual(KundeID,
          LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//RmtInf/Strd/CdtrRefInf/Ref', 0), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXmlCheckExtDocNoStructure()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
        NodeList: DotNet XmlNodeList;
        OutStr: OutStream;
        Amount: Decimal;
        ExtDocNo: Code[35];
    begin
        // [SCENARIO 418639] SEPA CT pain.001.001.09 "Ref" tag should contain "External Document No." if "KID" is empty
        // [GIVEN] Gen. Journal Line "G1" with "External Document No." = "ExtDocNo", "KID" not specified
        Amount := LibraryRandom.RandDec(100, 2);
        ExtDocNo := '12345678911';
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(Amount)),
          Amount * 2, 1);
        CreateGenJnlLineRegRepCode(GenJournalLine);
        GenJournalLine.Validate(KID, '');
        GenJournalLine.Validate("External Document No.", ExtDocNo);
        GenJournalLine.Modify(true);

        TempBlob.CreateOutStream(OutStr);
        BankAccount.Get(GenJournalLine."Bal. Account No.");

        // [WHEN] Export Gen. Journal Line with SEPA CT pain.001.001.09 port
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJournalLine);

        // [THEN] Xml file contains 'SCOR' and External Document No." value in structure
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.GetNodeList('//RmtInf/Strd/CdtrRefInf/Tp/CdOrPrtry/Cd', NodeList);
        Assert.AreEqual(1, NodeList.Count, 'Should be 1 nodes');
        Assert.AreEqual('SCOR',
          LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//RmtInf/Strd/CdtrRefInf/Tp/CdOrPrtry/Cd', 0), '');

        LibraryXPathXMLReader.GetNodeList('//RmtInf/Strd/CdtrRefInf/Ref', NodeList);
        Assert.AreEqual(1, NodeList.Count, 'Should be 1 nodes');

        // [THEN] Value of "Ref" = "ExtDocNo"
        Assert.AreEqual(ExtDocNo,
          LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//RmtInf/Strd/CdtrRefInf/Ref', 0), '');
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryERMCountryData.UpdateLocalData();
        isInitialized := true;
    end;

    local procedure PostPurchaseInvoiceForVendorWithRemittance(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        VendorNo: Code[20];
    begin
        VendorNo := CreateVendorWithBankAcc();
        UpdateVendorWithRemittance(VendorNo, CreateRemittanceAccountWithAgreement());
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          -LibraryRandom.RandDecInRange(1000, 2000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetRemittanceAccountForVendor(VendorNo: Code[20]): Code[10]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        exit(Vendor."Remittance Account Code");
    end;

    local procedure CreateBankAccountWithExportSetup(BankExpImpSetup: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.IBAN := 'SE6795000099604247929021';
        BankAccount."SWIFT Code" := 'NDEASESS';
        BankAccount."Payment Export Format" := BankExpImpSetup;
        BankAccount."Credit Transfer Msg. Nos." := LibraryERM.CreateNoSeriesCode();
        BankAccount.Modify();
        exit(BankAccount."No.");
    end;

    local procedure CreateNorgeBankExportImportSetup(ThreshAmt: Decimal): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        BankExportImportSetup."Processing Codeunit ID" := CODEUNIT::"Norge SEPA CC-Export File";
        BankExportImportSetup."Processing XMLport ID" := XMLPORT::"SEPA CT pain.001.001.09";
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA CT-Check Line";
        BankExportImportSetup."Reg.Reporting Thresh.Amt (LCY)" := ThreshAmt;
        BankExportImportSetup.Insert();
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateRegRepCode(): Code[10]
    var
        RegulatoryReportingCode: Record "Regulatory Reporting Code";
    begin
        RegulatoryReportingCode.Code :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(RegulatoryReportingCode.FieldNo(Code), DATABASE::"Regulatory Reporting Code"),
            1, MaxStrLen(RegulatoryReportingCode.Code));
        RegulatoryReportingCode.Description := LibraryUtility.GenerateGUID();
        RegulatoryReportingCode.Insert();
        exit(RegulatoryReportingCode.Code);
    end;

    local procedure CreateGenJnlLineRegRepCode(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlLineRegRepCode: Record "Gen. Jnl. Line Reg. Rep. Code";
    begin
        GenJnlLineRegRepCode."Journal Template Name" := GenJournalLine."Journal Template Name";
        GenJnlLineRegRepCode."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        GenJnlLineRegRepCode."Line No." := GenJournalLine."Line No.";
        GenJnlLineRegRepCode."Reg. Code" := CreateRegRepCode();
        GenJnlLineRegRepCode.Insert();
    end;

    local procedure CreatePaymentGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccCode: Code[20]; Amount: Decimal; NumberOfLines: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorNo: Code[20];
        i: Integer;
    begin
        CreatePaymentGenJnlBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccCode);
        GenJournalBatch.Modify(true);
        VendorNo := CreateVendorWithBankAcc();
        for i := 1 to NumberOfLines do begin
            LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
                GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
            GenJournalLine.Validate("Amount (LCY)", Amount);
            GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
            GenJournalLine.Modify(true);
        end;
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
    end;

    local procedure CreatePaymentJnlBatchWithBankAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Payments);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateVendorWithBankAcc(): Code[20]
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.IBAN := 'SE6795000099604247929021';
        VendorBankAccount."Currency Code" := LibraryERM.CreateCurrencyWithRandomExchRates();
        VendorBankAccount.Modify();
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateRemittanceAccountWithAgreement(): Code[10]
    var
        RemittanceAccount: Record "Remittance Account";
        RemittanceAgreement: Record "Remittance Agreement";
    begin
        LibraryRemittance.CreateRemittanceAgreement(RemittanceAgreement, RemittanceAgreement."Payment System"::"Other bank");
        LibraryRemittance.CreateDomesticRemittanceAccount(RemittanceAgreement.Code, RemittanceAccount);
        exit(RemittanceAccount.Code);
    end;

    local procedure CreateGenJnlLineWithDateGrouping(var GenJournalLine: Record "Gen. Journal Line")
    var
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGenJnlLine(
          GenJournalLine,
          CreateBankAccountWithExportSetup(CreateNorgeBankExportImportSetup(Amount)),
          Amount * 2, 3);
        GenJournalLine.FindFirst();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine.Modify(true);
        GenJournalLine.Next();
        GenJournalLine."Posting Date" := CalcDate('<-1D>', WorkDate());
        GenJournalLine.Modify(true);
        GenJournalLine.Next();
        GenJournalLine."Posting Date" := CalcDate('<-1D>', WorkDate());
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateVendorWithRemittance(VendorNo: Code[20]; RemittanceAccountCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate(Remittance, true);
        Vendor.Validate("Remittance Account Code", RemittanceAccountCode);
        Vendor.Modify(true);
    end;

    local procedure InitGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
    end;

    local procedure InitGenJournalLineForPaymentJournalsPage(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
    end;

    local procedure RunSuggestVendorPayments(GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.InitializeRequest(
          WorkDate(), false, 0, false, WorkDate(), LibraryUtility.GenerateGUID(), false, "Gen. Journal Account Type"::"G/L Account", '', "Bank Payment Type"::" ");
        Vendor.SetRange("No.", VendorNo);
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure FilterGenJnlRegRepCode(var GenJnlLineRegRepCode: Record "Gen. Jnl. Line Reg. Rep. Code"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJnlLineRegRepCode.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlLineRegRepCode.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlLineRegRepCode.SetRange("Line No.", GenJournalLine."Line No.");
    end;

    local procedure MockGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; BankExportImportSetupCode: Code[20])
    begin
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := CreateBankAccountWithExportSetup(BankExportImportSetupCode);
    end;

    local procedure VerifyTagRgltryRptg(XMLParentNode: DotNet XmlNode; GenJnlLineRegRepCode: Record "Gen. Jnl. Line Reg. Rep. Code")
    var
        XMLNode: DotNet XmlNode;
    begin
        Assert.AreEqual('Dtls', XMLParentNode.Name, '<RgltryRptg><Dtls>');
        XMLNode := XMLParentNode.FirstChild;
        Assert.AreEqual('Cd', XMLNode.Name, '<RgltryRptg><Dtls><Cd>');
        Assert.AreEqual(GenJnlLineRegRepCode."Reg. Code", XMLNode.InnerText, '<RgltryRptg><Dtls><Cd>');
        XMLNode := XMLParentNode.LastChild;
        Assert.AreEqual('Inf', XMLNode.Name, '<RgltryRptg><Dtls><Inf>');
        GenJnlLineRegRepCode.CalcFields("Reg. Code Description");
        Assert.AreEqual(GenJnlLineRegRepCode."Reg. Code Description", XMLNode.InnerText, '<RgltryRptg><Dtls><Inf>');
    end;

    local procedure ValidateWaitingJournal(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date; SepaEndToEndId: Text; SepaPmtInfId: Text)
    var
        WaitingJournal: Record "Waiting Journal";
    begin
        WaitingJournal.Reset();
        WaitingJournal.SetRange("Account Type", AccountType);
        WaitingJournal.SetRange("Account No.", AccountNo);
        WaitingJournal.SetRange("Posting Date", PostingDate);
        WaitingJournal.SetRange("SEPA End To End ID", SepaEndToEndId);
        WaitingJournal.FindFirst();
        WaitingJournal.TestField("SEPA Payment Inf ID", SepaPmtInfId);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GenJnlRegPerCodesPageHandler(var GenJnlLineRegRepCodes: TestPage "Gen. Jnl. Line Reg. Rep. Codes")
    begin
        GenJnlLineRegRepCodes."Reg. Code".SetValue(LibraryVariableStorage.DequeueText());
        GenJnlLineRegRepCodes.Close();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestRemittancePaymentsRequestPageHandler(var SuggestRemittancePayments: TestRequestPage "Suggest Remittance Payments")
    begin
        SuggestRemittancePayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestRemittancePayments.Vendor.SetFilter("Remittance Account Code", LibraryVariableStorage.DequeueText());
        SuggestRemittancePayments.LastPaymentDate.SetValue(LibraryVariableStorage.DequeueDate());
        SuggestRemittancePayments.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.GotoKey(LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;
}

