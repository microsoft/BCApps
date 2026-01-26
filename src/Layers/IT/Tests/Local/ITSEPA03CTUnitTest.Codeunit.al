codeunit 144016 "IT - SEPA.03 CT Unit Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        FieldBlankErr: Label 'The Recipient Bank Account field must be filled.', Comment = '%1=table name, %2=field name. Example: Customer must have a value in Name.';
        LegacyExpError: Label 'The value "" can''t be evaluated into type Integer.';
        GenJnlLineExpError: Label 'Your export format is not set up to export vendor bills with this function. Use the function in the Vendor Bill List Sent Card window instead.';
        HasErrorsErr: Label 'The file export has one or more errors.';
        CumulativeInvoiceTxt: Label 'Sundry Invoices';

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithErrors()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBillLine: Record "Vendor Bill Line";
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, false);
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.Next(LibraryRandom.RandInt(VendorBillLine.Count));
        VendorBillLine."Vendor Bank Acc. No." := '';
        VendorBillLine.Modify();

        // Must be record in Tab81 with same Document No.
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJournalTemplate.Name, GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
            "Gen. Journal Account Type"::"G/L Account", '', 0);
        GenJnlLine."Document No." := VendorBillHeader."No.";
        GenJnlLine.Modify();

        // Exercise.
        asserterror VendorBillHeader.ExportToFile();

        // Verify.
        Assert.ExpectedError(HasErrorsErr);
        VerifyPaymentErrors(VendorBillHeader."No.", VendorBillLine."Line No.", FieldBlankErr, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBillLineErrorsAreDeleted()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBillLine: Record "Vendor Bill Line";
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, false);
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.Next(LibraryRandom.RandInt(VendorBillLine.Count));
        VendorBillLine."Vendor Bank Acc. No." := '';
        VendorBillLine.Modify();
        asserterror VendorBillHeader.ExportToFile();

        // Exercise.
        VendorBillLine.Delete(true);

        // Verify.
        VerifyPaymentErrors(VendorBillHeader."No.", VendorBillLine."Line No.", FieldBlankErr, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorsDeletedBetweenFormats()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBillLine: Record "Vendor Bill Line";
        BankAccount: Record "Bank Account";
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, false);
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.Next(LibraryRandom.RandInt(VendorBillLine.Count));
        VendorBillLine."Vendor Bank Acc. No." := '';
        VendorBillLine.Modify();
        asserterror VendorBillHeader.ExportToFile();
        VerifyPaymentErrors(VendorBillHeader."No.", VendorBillLine."Line No.", FieldBlankErr, 1);
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Vendor Bills Floppy", 0);
        BankAccount.Get(VendorBillHeader."Bank Account No.");
        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify();
        asserterror VendorBillHeader.ExportToFile();

        // Verify.
        VerifyPaymentErrors(VendorBillHeader."No.", VendorBillLine."Line No.", FieldBlankErr, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillBufferSunshine()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        PaymentExportData: Record "Payment Export Data";
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, false);

        // Exercise.
        FillExportBuffer(VendorBillHeader."No.", PaymentExportData);

        // Verify.
        Assert.AreEqual(TempVendorBillLine.Count, PaymentExportData.Count, 'Incomplete data in buffer.');
        VerifyPaymentExportData(TempVendorBillLine, PaymentExportData, VendorBillHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LegacyFormat()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Vendor Bills Floppy", 0);
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, false);

        // Exercise.
        asserterror VendorBillHeader.ExportToFile();

        // Verify.
        Assert.ExpectedError(LegacyExpError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LegacyFormatFromGenJnlLine()
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Vendor Bills Floppy", 0);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify();
        GenJnlBatch.DeleteAll(true);
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        GenJnlBatch."Allow Payment Export" := true;
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"Bank Account";
        GenJnlBatch."Bal. Account No." := BankAccount."No.";
        GenJnlBatch.Modify();
        GenJnlLine.DeleteAll();
        LibraryERM.CreateGeneralJnlLine(GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(100, 2));
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := BankAccount."No.";
        GenJnlLine.Modify();

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Export Payment File (Yes/No)", GenJnlLine);

        // Verify.
        Assert.ExpectedError(GenJnlLineExpError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CumulativeLinesDiffVendorBankAcc()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBillLine: Record "Vendor Bill Line";
        PaymentExportData: Record "Payment Export Data";
        TotalFirstBankAcc: Decimal;
        TotalLastBankAcc: Decimal;
        i: Integer;
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, true);
        TempVendorBillLine.CalcSums("Amount to Pay");
        TotalFirstBankAcc := TempVendorBillLine."Amount to Pay";
        TempVendorBillLine.FindLast();

        CreateVendorBankAccount(VendorBankAccount, TempVendorBillLine."Vendor No.");
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            CreateVendorBillLine(VendorBillLine, VendorBillHeader, VendorBankAccount, TempVendorBillLine."Line No." + i * 10000, true);
            TotalLastBankAcc += VendorBillLine."Amount to Pay";
        end;

        // Exercise.
        FillExportBuffer(VendorBillHeader."No.", PaymentExportData);

        // Verify.
        Assert.AreEqual(2, PaymentExportData.Count, 'Wrong aggregation of lines.');
        VerifyPaymentLine(PaymentExportData, TempVendorBillLine, VendorBillHeader, TotalFirstBankAcc);
        VerifyPaymentLine(PaymentExportData, VendorBillLine, VendorBillHeader, TotalLastBankAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CumulativeLinesDiffVendors()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBillLine: Record "Vendor Bill Line";
        PaymentExportData: Record "Payment Export Data";
        TotalFirstBankAcc: Decimal;
        TotalLastBankAcc: Decimal;
        i: Integer;
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, true);
        TempVendorBillLine.CalcSums("Amount to Pay");
        TotalFirstBankAcc := TempVendorBillLine."Amount to Pay";
        TempVendorBillLine.FindLast();

        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            CreateVendorBillLine(VendorBillLine, VendorBillHeader, VendorBankAccount, TempVendorBillLine."Line No." + i * 10000, true);
            TotalLastBankAcc += VendorBillLine."Amount to Pay";
        end;

        // Exercise.
        FillExportBuffer(VendorBillHeader."No.", PaymentExportData);

        // Verify.
        Assert.AreEqual(2, PaymentExportData.Count, 'Wrong aggregation of lines.');
        VerifyPaymentLine(PaymentExportData, TempVendorBillLine, VendorBillHeader, TotalFirstBankAcc);
        VerifyPaymentLine(PaymentExportData, VendorBillLine, VendorBillHeader, TotalLastBankAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CumulativeLinesMixed()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBillLine: Record "Vendor Bill Line";
        PaymentExportData: Record "Payment Export Data";
        TotalLastBankAcc: Decimal;
        i: Integer;
    begin
        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, false);
        CreateVendorBankAccount(VendorBankAccount, TempVendorBillLine."Vendor No.");
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            CreateVendorBillLine(VendorBillLine, VendorBillHeader, VendorBankAccount, TempVendorBillLine."Line No." + i * 10000, true);
            TotalLastBankAcc += VendorBillLine."Amount to Pay";
        end;

        // Exercise.
        FillExportBuffer(VendorBillHeader."No.", PaymentExportData);

        // Verify.
        Assert.AreEqual(TempVendorBillLine.Count + 1, PaymentExportData.Count, 'Wrong aggregation of lines.');
        VerifyPaymentExportData(TempVendorBillLine, PaymentExportData, VendorBillHeader);
        VerifyPaymentLine(PaymentExportData, VendorBillLine, VendorBillHeader, TotalLastBankAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CumulativeDescriptionText()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        TempPaymentExportData: Record "Payment Export Data" temporary;
    begin
        // [SCENARIO 109049.1] Check Remittance text contains "Cumulative Invoice" text in case of several cumulative bills
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");

        // [GIVEN] Vendor Bill Card with several cumulative bill lines
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, true);

        // [WHEN] run SEPA CT-Fill Export Buffer
        FillExportBuffer(VendorBillHeader."No.", TempPaymentExportData);

        // [THEN] Payment Export Remittance Text contain "Cumulative Invoice" text
        VerifyPmtExportRmtText(TempPaymentExportData, CumulativeInvoiceTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonCumulativeDescriptionText()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        TempPaymentExportData: Record "Payment Export Data" temporary;
        ExpectedText: Text;
    begin
        // [SCENARIO 109049.2] Check Remittance text contains External Doc. Type and No. text in case of several non-cumulative bills
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03");

        // [GIVEN] Vendor Bill Card with several non-cumulative bill lines
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, false);

        // [WHEN] run SEPA CT-Fill Export Buffer
        FillExportBuffer(VendorBillHeader."No.", TempPaymentExportData);

        // [THEN] Payment Export Remittance Text contain External Doc Type and No text
        TempVendorBillLine.FindFirst();
        ExpectedText := StrSubstNo('%1 %2', Format(TempVendorBillLine."Document Type"), TempVendorBillLine."External Document No.");
        VerifyPmtExportRmtText(TempPaymentExportData, ExpectedText);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReportVendorBillsFloppyPrintVendorsName()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBillsFloppy: Report "Vendor Bills Floppy";
        ITSEPA03CTUnitTest: Codeunit "IT - SEPA.03 CT Unit Test";
    begin
        // [GIVEN] Vendor Bill with Bank Import/Export Setup = Codeunit::"Vendor Bills Floppy"
        // [GIVEN] Setup ABI, CAB and IBAN for Banc Account
        // [GIVEN] Setup ABI, CAB and IBAN for Vendor Banc Account
        // [GIVEN] Setup Name and Name2 for Vendor
        PrepareVendorBillHeaderForFloppyReport(VendorBillHeader, TempVendorBillLine);

        // [WHEN] Run report 12175 "Vendor Bills Floppy"
        BindSubscription(ITSEPA03CTUnitTest);
        VendorBillHeader.SetRecFilter();
        VendorBillsFloppy.UseRequestPage := false;
        VendorBillsFloppy.SetTableView(VendorBillHeader);
        VendorBillsFloppy.Run();

        // [THEN] SixthLine of created file contain Vendor.Name and Vendor."Name 2"
        VerifyVendorFloppyFileContainsNameOfVendor(ITSEPA03CTUnitTest, TempVendorBillLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_VendorBillFloppyReportRunOnExportBillListToFileAction()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        ITSEPA03CTUnitTest: Codeunit "IT - SEPA.03 CT Unit Test";
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 369534] A "Vendor Bills Floppy" report runs when Stan press action "Export Bill List To File" from the "Vendor Bill List Sent Card" page

        // [GIVEN] Vendor Bill with Bank Import/Export Setup = Codeunit::"Vendor Bills Floppy"
        // [GIVEN] Setup ABI, CAB and IBAN for Banc Account
        // [GIVEN] Setup ABI, CAB and IBAN for Vendor Banc Account
        // [GIVEN] Setup Name and Name2 for Vendor
        PrepareVendorBillHeaderForFloppyReport(VendorBillHeader, TempVendorBillLine);

        BindSubscription(ITSEPA03CTUnitTest);

        // [GIVEN] Opened "Vendor Bill List Sent Card" page with created Vendor Bill
        VendorBillListSentCard.OpenEdit();
        VendorBillListSentCard.FILTER.SetFilter("No.", VendorBillHeader."No.");

        // [WHEN] Stan press action "Export Bill List To File"
        VendorBillListSentCard.ExportBillListToFile.Invoke();

        // [THEN] Sixth line of created file contain Vendor.Name and Vendor."Name 2"
        VerifyVendorFloppyFileContainsNameOfVendor(ITSEPA03CTUnitTest, TempVendorBillLine);
    end;

    local procedure FillExportBuffer(PaymentDocNo: Code[20]; var PaymentExportData: Record "Payment Export Data")
    var
        GenJnlLine: Record "Gen. Journal Line";
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        SEPAFormat: Option pain,CBI,AMC;
    begin
        PaymentExportData.DeleteAll();
        GenJnlLine.SetRange("Document No.", PaymentDocNo);
        SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, PaymentExportData, SEPAFormat::pain);
    end;

    local procedure PrepareVendorBillHeaderForFloppyReport(var VendorBillHeader: Record "Vendor Bill Header"; var TempVendorBillLine: Record "Vendor Bill Line" temporary)
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        AbiCabCodes: Record "ABI/CAB Codes";
        VendorBankAccount: Record "Vendor Bank Account";
        Name1: Text;
        Name2: Text;
    begin
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Vendor Bills Floppy", 0);
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, BankExportImportSetup.Code, false);
        BankAccount.Get(VendorBillHeader."Bank Account No.");
        CreateAbiCabCode(AbiCabCodes);
        BankAccount.Validate(ABI, AbiCabCodes.ABI);
        BankAccount.Validate(CAB, AbiCabCodes.CAB);
        BankAccount.Validate(IBAN, LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);

        VendorBankAccount.Get(TempVendorBillLine."Vendor No.", TempVendorBillLine."Vendor Bank Acc. No.");
        VendorBankAccount.Validate(ABI, AbiCabCodes.ABI);
        VendorBankAccount.Validate(CAB, AbiCabCodes.CAB);
        VendorBankAccount.Validate(IBAN, LibraryUtility.GenerateGUID());
        VendorBankAccount.Modify(true);

        Name1 := LibraryRandom.RandText(30);
        Name2 := LibraryRandom.RandText(30);
        Vendor.Get(TempVendorBillLine."Vendor No.");
        Vendor.Validate(Name, Format(Name1, 30));
        Vendor.Validate("Name 2", Format(Name2, 30));
        Vendor.Modify(true);
    end;

    local procedure CreateVendorBill(var VendorBillHeader: Record "Vendor Bill Header"; var TempVendorBillLines: Record "Vendor Bill Line" temporary; BankExpImpFormat: Code[20]; CumulativeLines: Boolean)
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        VendorBillLine: Record "Vendor Bill Line";
        i: Integer;
    begin
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Payment Export Format" := BankExpImpFormat;
        BankAccount."Bank Account No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Account No."), DATABASE::"Bank Account");
        BankAccount.IBAN :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(IBAN), DATABASE::"Bank Account");
        BankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account");
        BankAccount."Credit Transfer Msg. Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        BankAccount.Modify();
        VendorBillHeader."Bank Account No." := BankAccount."No.";
        VendorBillHeader."List Status" := VendorBillHeader."List Status"::Sent;
        VendorBillHeader.Modify();

        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            CreateVendorBillLine(VendorBillLine, VendorBillHeader, VendorBankAccount, i * 10000, CumulativeLines);
            TempVendorBillLines := VendorBillLine;
            TempVendorBillLines.Insert();
        end;
    end;

    [Normal]
    local procedure CreateVendorBillLine(var VendorBillLine: Record "Vendor Bill Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBankAccount: Record "Vendor Bank Account"; LineNo: Integer; Cumulative: Boolean)
    begin
        VendorBillLine.Init();
        VendorBillLine."Vendor Bill List No." := VendorBillHeader."No.";
        VendorBillLine."Line No." := LineNo;
        VendorBillLine.Description :=
          LibraryUtility.GenerateRandomCode(VendorBillLine.FieldNo(Description), DATABASE::"Vendor Bill Line");
        VendorBillLine."Description 2" :=
          LibraryUtility.GenerateRandomCode(VendorBillLine.FieldNo("Description 2"), DATABASE::"Vendor Bill Line");
        VendorBillLine."Vendor No." := VendorBankAccount."Vendor No.";
        VendorBillLine."Vendor Bank Acc. No." := VendorBankAccount.Code;
        VendorBillLine."Document Type" := VendorBillLine."Document Type"::Invoice;
        VendorBillLine."Document No." :=
          LibraryUtility.GenerateRandomCode(VendorBillLine.FieldNo("Document No."), DATABASE::"Vendor Bill Line");
        VendorBillLine."External Document No." :=
          LibraryUtility.GenerateRandomCode(VendorBillLine.FieldNo("External Document No."), DATABASE::"Vendor Bill Line");
        VendorBillLine."Amount to Pay" := LibraryRandom.RandDec(100, 2);
        VendorBillLine."Cumulative Transfers" := Cumulative;
        VendorBillLine."Manual Line" := true;
        VendorBillLine.Insert();
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.IBAN :=
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(IBAN), DATABASE::"Vendor Bank Account");
        VendorBankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("SWIFT Code"), DATABASE::"Vendor Bank Account");
        VendorBankAccount.Modify();
    end;

    local procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; ProcessingCodeunitId: Integer; ProcessingXmlPortId: Integer)
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup."Preserve Non-Latin Characters" := true;
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunitId;
        BankExportImportSetup."Processing XMLport ID" := ProcessingXmlPortId;
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA CT-Check Line";
        BankExportImportSetup.Insert();
    end;

    local procedure CreateAbiCabCode(var ABICABCodes: Record "ABI/CAB Codes")
    begin
        ABICABCodes.Init();
        ABICABCodes.Validate(ABI, LibraryUtility.GenerateRandomCode(ABICABCodes.FieldNo(ABI), DATABASE::"ABI/CAB Codes"));
        ABICABCodes.Validate(CAB, LibraryUtility.GenerateRandomCode(ABICABCodes.FieldNo(CAB), DATABASE::"ABI/CAB Codes"));
        ABICABCodes.Insert(true);
    end;

    procedure DequeueFileName(var FileName: Text)
    begin
        FileName := LibraryVariableStorage.DequeueText();
    end;

    procedure AssertVariableStorageIsEmpty()
    begin
        LibraryVariableStorage.AssertEmpty();
    end;

    [Normal]
    local procedure VerifyPaymentExportData(var TempVendorBillLine: Record "Vendor Bill Line" temporary; PaymentExportData: Record "Payment Export Data"; VendorBillHeader: Record "Vendor Bill Header")
    begin
        TempVendorBillLine.FindSet();
        repeat
            VerifyPaymentLine(PaymentExportData, TempVendorBillLine, VendorBillHeader, TempVendorBillLine."Amount to Pay");
        until TempVendorBillLine.Next() = 0;
    end;

    local procedure VerifyPaymentErrors(PaymentDocNo: Code[20]; LineNo: Integer; ExpErrorText: Text; ExpCount: Integer)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Document No.", PaymentDocNo);
        PaymentJnlExportErrorText.SetRange("Journal Line No.", LineNo);
        PaymentJnlExportErrorText.SetRange("Error Text", ExpErrorText);
        Assert.AreEqual(ExpCount, PaymentJnlExportErrorText.Count, 'Error was encountered unexpectedly.');
    end;

    local procedure VerifyPaymentLine(var PaymentExportData: Record "Payment Export Data"; VendorBillLine: Record "Vendor Bill Line"; VendorBillHeader: Record "Vendor Bill Header"; AmountToPay: Decimal)
    var
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
    begin
        PaymentExportData.SetRange("Document No.", VendorBillLine."Vendor Bill List No.");
        PaymentExportData.SetRange("Transfer Date", VendorBillHeader."Posting Date");
        PaymentExportData.SetRange("Currency Code", 'EUR');
        VendorBankAccount.Get(VendorBillLine."Vendor No.", VendorBillLine."Vendor Bank Acc. No.");
        PaymentExportData.SetRange("Recipient Bank Acc. No.", VendorBankAccount.IBAN);
        PaymentExportData.SetRange("Recipient Bank BIC", VendorBankAccount."SWIFT Code");
        PaymentExportData.SetRange("Sender Bank Account Code", VendorBillHeader."Bank Account No.");
        BankAccount.Get(VendorBillHeader."Bank Account No.");
        PaymentExportData.SetRange("Sender Bank Account No.", BankAccount.IBAN);
        PaymentExportData.SetRange("Sender Bank BIC", BankAccount."SWIFT Code");
        PaymentExportData.SetRange(Amount, AmountToPay);
        Assert.AreEqual(1, PaymentExportData.Count, PaymentExportData.GetFilters);
    end;

    local procedure VerifyPmtExportRmtText(var PaymentExportData: Record "Payment Export Data"; ExpectedText: Text)
    var
        TempPaymentExportRemittanceText: Record "Payment Export Remittance Text" temporary;
    begin
        PaymentExportData.GetRemittanceTexts(TempPaymentExportRemittanceText);
        TempPaymentExportRemittanceText.FindFirst();
        Assert.ExpectedMessage(ExpectedText, TempPaymentExportRemittanceText.Text);
    end;

    local procedure VerifyVendorFloppyFileContainsNameOfVendor(var ITSEPA03CTUnitTest: Codeunit "IT - SEPA.03 CT Unit Test"; TempVendorBillLine: Record "Vendor Bill Line" temporary)
    var
        Vendor: Record Vendor;
        TextLine: Text;
        FileName: Text;
    begin
        Vendor.Get(TempVendorBillLine."Vendor No.");
        ITSEPA03CTUnitTest.DequeueFileName(FileName);
        TextLine := LibraryTextFileValidation.FindLineWithValue(FileName, 11, 30, Vendor.Name);
        Assert.AreEqual(CopyStr(TextLine, 11, 30), Vendor.Name, '');
        Assert.AreEqual(CopyStr(TextLine, 41, 30), Vendor."Name 2", '');
        ITSEPA03CTUnitTest.AssertVariableStorageIsEmpty();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure SetFileNameOnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FromFileName);
        IsHandled := true;
    end;
}

