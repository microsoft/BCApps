codeunit 144020 "IT - SEPA CBI CT Test"
{
    // // [FEATURE] [CBI SEPA]

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
        LibraryRandom: Codeunit "Library - Random";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        UnexpectedEmptyNodeErr: Label 'Unexpected empty value for node <%1> of subtree <%2>.';
        JournalLineErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        PostingDateInPastErr: Label 'The earliest possible transfer date is today.';
        CdtrAgtNodeTxt: Label '/CBIPaymentRequest/PmtInf/CdtTrfTxInf/CdtrAgt';
        FinInstnIdBICTxt: Label '/CBIPaymentRequest/PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/BIC';
        LibraryPaymentExport: Codeunit "Library - Payment Export";

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCBIFormat()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
    begin
        // [SCENARIO CBI1] Name="Validate CBI format-based XML
        // [GIVEN] Issued Vendor Bill
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, false);

        // [WHEN] Export to File - CBI Format action is run
        ExportVendorBill(VendorBillHeader);

        // [THEN] Exported XML file contains Vendor Bill data
        // [THEN] Exported XML file is compliant with CBI format
        VerifyXML(VendorBillHeader, TempVendorBillLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateInPastError()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
    begin
        // [SCENARIO CBI21] If Posting Date is in past, then Export File Error is logged
        // [GIVEN] Posting Date is in past
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, false);
        VendorBillHeader.Validate("Posting Date", CalcDate('<-7D>', VendorBillHeader."Posting Date"));
        VendorBillHeader.Modify(true);

        // [WHEN] Export to File - CBI Format action is run
        // [THEN] Export File Error is logged
        asserterror ExportVendorBill(VendorBillHeader);
        Assert.ExpectedError(JournalLineErr);

        FindExportErrors(VendorBillHeader."No.", PaymentJnlExportErrorText);
        Assert.AreEqual(Format(PostingDateInPastErr), PaymentJnlExportErrorText."Error Text", '')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure RecipientBankAccIBANBlankErr()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        // [SCENARIO CBI22] If Recipient Bank Account has no IBAN then Export File Error is logged
        // [GIVEN] Recipient Bank Account in the Vendor Bill has no IBAN
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, false);
        SetVendorBankAccountIBAN(TempVendorBillLine."Vendor No.", TempVendorBillLine."Vendor Bank Acc. No.", '');

        // [WHEN] Export to File - CBI Format action is run
        // [THEN] Export File Error is logged
        asserterror ExportVendorBill(VendorBillHeader);
        Assert.ExpectedTestFieldError(VendorBankAcc.FieldCaption(IBAN), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccSWIFTBlank()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
    begin
        // [SCENARIO CBI23] If Recipient Bank Account has no SWIFT then file is successfully exported
        // [GIVEN] Issued Vendor Bill, Swift code on Recipient Bank Account is blank
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, false);
        SetVendorBankAccountSWIFT(TempVendorBillLine."Vendor No.", TempVendorBillLine."Vendor Bank Acc. No.", '');

        // [WHEN] 'Export to File - CBI Format' action is run
        ExportVendorBill(VendorBillHeader);

        // [THEN] Exported XML file contains Vendor Bill data
        // [THEN] Exported XML file is compliant with CBI format
        VerifyXML(VendorBillHeader, TempVendorBillLine);

        // [THEN] CdtrAgt Node is absent in exported file
        LibraryXPathXMLReader.VerifyNodeCountByXPath(CdtrAgtNodeTxt, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccSWIFTNotBlank()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        LineCount: Integer;
    begin
        // [SCENARIO 375378] SEPA CBI BIC Nodes exported only for Vendor Bank Accounts with filled SWIFT
        // [GIVEN] Issued Vendor Bill, Vendor "A" Bank Account has empty SWIFT, Vendor "B" Bank Account has filled SWIFT
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, false);
        ResetVendorPostalAddress(TempVendorBillLine."Vendor No.");
        SetVendorBankAccountSWIFT(TempVendorBillLine."Vendor No.", TempVendorBillLine."Vendor Bank Acc. No.", '');

        // [GIVEN] Issued Vendor Bill has "X" lines for Vendor "B"
        LineCount := LibraryRandom.RandIntInRange(10, 15);
        CreateVendorAndAddBillLines(VendorBillHeader, TempVendorBillLine, false, LineCount);

        // [GIVEN] Vendor postal address fields are empty
        ResetVendorPostalAddress(TempVendorBillLine."Vendor No.");

        // [WHEN] 'Export to File - CBI Format' action is run
        ExportVendorBill(VendorBillHeader);

        // [THEN] Exported XML file contains "X" BIC Nodes
        LibraryXPathXMLReader.VerifyNodeCountByXPath(FinInstnIdBICTxt, LineCount);

        // [THEN] No tags are generated for vendor postal address fields (TFS 378932)
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/CBIPaymentRequest/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/StrtNm', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/CBIPaymentRequest/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/PstCd', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/CBIPaymentRequest/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/TwnNm', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/CBIPaymentRequest/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/Ctry', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SenderBankAccSWIFTBlank()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
    begin
        // [SCENARIO CBI13] If Sender Bank Account has no SWIFT then file is successfully exported
        // [GIVEN] Issued Vendor Bill, SWIFT in Sender Bank Account is blank
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, false);
        SetBankAccountSWIFT(VendorBillHeader."Bank Account No.", '');

        // [WHEN] Export to File - CBI Format action is run
        ExportVendorBill(VendorBillHeader);

        // [THEN] Exported XML file contains Vendor Bill data
        // [THEN] Exported XML file is compliant with CBI format
        VerifyXML(VendorBillHeader, TempVendorBillLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SenderBankAccountABIBlankError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO CBI11] If Sender Bank Account doesn't have ABI filled in, error message is thrown
        // [GIVEN] Sender Bank Account doesn't have ABI filled in
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, false);
        SetBankAccountABI(VendorBillHeader."Bank Account No.", '');

        // [WHEN] Export to File - CBI Format action is run
        // [THEN] Error is thrown stating that ABI filed is mandatory
        asserterror ExportVendorBill(VendorBillHeader);
        Assert.ExpectedTestFieldError(BankAccount.FieldCaption(ABI), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SenderBankAccountIBANBlankErr()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        // [SCENARIO CBI12] If Sender Bank Account has no IBAN then Export File Error is logged
        // [GIVEN] Sender Bank Account used to create Vendor Bill has no IBAN
        CreateVendorBill(VendorBillHeader, TempVendorBillLine, false);
        SetBankAccountIBAN(VendorBillHeader."Bank Account No.", '');

        // [WHEN] Export to File - CBI Format action is run
        // [THEN] Error is thrown
        asserterror ExportVendorBill(VendorBillHeader);
        Assert.ExpectedTestFieldError(VendorBankAcc.FieldCaption(IBAN), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportTwoPaymentsWithDiffVendorsButSameBankSetupCombined()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: array[2] of Code[20];
        BankAccountNo: Code[20];
        VendBankAccountCode: array[2] of Code[20];
        i: Integer;
    begin
        // [SCENARIO 203084] Two payments with different Vendors and Bank Accounts but same Bank Account Setup are combined when export as CBI Payment Request

        // [GIVEN] Bank Account "GIRO" with Bank Account Setup to export payment via "CBI Payment Request" and IBAN = "I"
        // [GIVEN] Vendor "X" with Vendor Bank Account "A" and Vendor "Y" with Vendor Bank Account "B". IBAN in both "A" and "B" is "I"
        CreateTwoVendorsWithDiffBanksButSameBankAccountSetup(VendNo, VendBankAccountCode, BankAccountNo);

        // [GIVEN] Two general journal lines with same Bank Account "GIRO" but different Vendors and Recipient Bank Accounts according to setup described above
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryPaymentExport.SelectPaymentJournalTemplate());
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJournalBatch.Modify(true);
        for i := 1 to ArrayLen(VendNo) do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJnlLine."Document Type"::Payment,
              GenJnlLine."Account Type"::Vendor, VendNo[i], LibraryRandom.RandDec(1000, 2));
            GenJnlLine.Validate("Recipient Bank Account", VendBankAccountCode[i]);
            GenJnlLine.Modify(true);
        end;

        // [WHEN] Export payment via "CBI Payment Request"
        ExportGenJnlLinesToCBIPaymentRequest(GenJnlLine);

        // [THEN] XML file generated contains only one root element '/CBIPaymentRequest' meaning two payments combined into one
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/CBIPaymentRequest', 1);
    end;

    local procedure CreateBankExportImportFormat(): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Validate(Code, LibraryUtility.GenerateGUID());
        BankExportImportSetup.Validate(Name, LibraryUtility.GenerateGUID());
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::Export);
        BankExportImportSetup.Validate("Processing Codeunit ID", CODEUNIT::"SEPA CT-Export File");
        BankExportImportSetup.Validate("Processing XMLport ID", XMLPORT::"CBI Payment Request.00.04.00");
        BankExportImportSetup.Validate("Check Export Codeunit", CODEUNIT::"SEPA CT CBI-Check Line");

        BankExportImportSetup.Insert(true);
        exit(BankExportImportSetup.Code)
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate("Country/Region Code", 'IT');
        Vendor.Validate("Post Code", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Post Code"), DATABASE::Vendor));
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Modify(true);
    end;

    local procedure CreateVendorAndAddBillLines(VendorBillHeader: Record "Vendor Bill Header"; var TempVendorBillLine: Record "Vendor Bill Line" temporary; CumulativeLines: Boolean; LineCount: Integer)
    var
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        VendorBillLine: Record "Vendor Bill Line";
        i: Integer;
    begin
        CreateVendor(Vendor);
        CreateVendorBankAccount(
          VendorBankAccount, Vendor."No.",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(IBAN), DATABASE::"Vendor Bank Account"));
        for i := 1 to LineCount do begin
            CreateVendorBillLine(VendorBillLine, VendorBillHeader, VendorBankAccount, CumulativeLines);
            TempVendorBillLine := VendorBillLine;
            TempVendorBillLine.Insert();
        end;
    end;

    local procedure CreateVendorBill(var VendorBillHeader: Record "Vendor Bill Header"; var TempVendorBillLines: Record "Vendor Bill Line" temporary; CumulativeLines: Boolean)
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        LibraryERM.CreateBankAccount(BankAccount);
        UpdateBankAccount(
          BankAccount, LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(IBAN), DATABASE::"Bank Account"),
          CreateBankExportImportFormat());
        VendorBillHeader."Bank Account No." := BankAccount."No.";
        VendorBillHeader."Posting Date" := Today;
        VendorBillHeader.Modify();

        CreateVendorAndAddBillLines(
          VendorBillHeader, TempVendorBillLines, CumulativeLines, LibraryRandom.RandIntInRange(5, 10));
    end;

    local procedure CreateVendorBillLine(var VendorBillLine: Record "Vendor Bill Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBankAccount: Record "Vendor Bank Account"; Cumulative: Boolean)
    begin
        VendorBillLine.Init();
        VendorBillLine."Vendor Bill List No." := VendorBillHeader."No.";
        VendorBillLine."Line No." := LibraryUtility.GetNewRecNo(VendorBillLine, VendorBillLine.FieldNo("Line No."));
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
        VendorBillLine."Due Date" := Today;
        VendorBillLine.Insert();
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; IBAN: Code[50])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.IBAN := IBAN;
        VendorBankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("SWIFT Code"), DATABASE::"Vendor Bank Account");
        VendorBankAccount.Modify();
    end;

    local procedure CreateTwoVendorsWithDiffBanksButSameBankAccountSetup(var VendNo: array[2] of Code[20]; var VendBankAccountCode: array[2] of Code[20]; var BankAccountNo: Code[20])
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        BankImportSetupCode: Code[20];
        IBAN: Code[50];
        i: Integer;
    begin
        BankImportSetupCode := CreateBankExportImportFormat();
        IBAN := LibraryUtility.GenerateGUID();
        LibraryERM.CreateBankAccount(BankAccount);
        UpdateBankAccount(BankAccount, IBAN, BankImportSetupCode);
        BankAccountNo := BankAccount."No.";
        for i := 1 to ArrayLen(VendNo) do begin
            CreateVendor(Vendor);
            CreateVendorBankAccount(VendorBankAccount, Vendor."No.", IBAN);
            VendNo[i] := Vendor."No.";
            VendBankAccountCode[i] := VendorBankAccount.Code;
        end;
    end;

    local procedure UpdateBankAccount(var BankAccount: Record "Bank Account"; IBAN: Code[50]; PaymentExportCode: Code[20])
    begin
        BankAccount."Bank Account No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Account No."), DATABASE::"Bank Account");
        BankAccount.IBAN := IBAN;
        BankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account");
        BankAccount."Credit Transfer Msg. Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        BankAccount.ABI :=
          CopyStr(LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(ABI), DATABASE::"Bank Account"), 1, MaxStrLen(BankAccount.ABI));
        BankAccount.CUC :=
          CopyStr(LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(CUC), DATABASE::"Bank Account"), 1, MaxStrLen(BankAccount.CUC));
        BankAccount."Payment Export Format" := PaymentExportCode;
        BankAccount.Modify();
    end;

    local procedure ExportVendorBill(VendorBillHeader: Record "Vendor Bill Header")
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        GenJnlLine.SetRange("Document No.", VendorBillHeader."No.");
        GenJnlLine."Bal. Account No." := VendorBillHeader."Bank Account No.";

        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"CBI Payment Request.00.04.00", OutStr, GenJnlLine);

        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, 'urn:CBI:xsd:CBIPaymentRequest.00.04.00');
    end;

    local procedure ExportGenJnlLinesToCBIPaymentRequest(var GenJnlLine: Record "Gen. Journal Line")
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");

        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"CBI Payment Request.00.04.00", OutStr, GenJnlLine);

        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, 'urn:CBI:xsd:CBIPaymentRequest.00.04.00');
    end;

    local procedure FindExportErrors(DocumentNo: Code[20]; var PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text")
    begin
        PaymentJnlExportErrorText.SetRange("Journal Template Name", '');
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", '');
        PaymentJnlExportErrorText.SetRange("Document No.", DocumentNo);
        PaymentJnlExportErrorText.FindSet();
    end;

    local procedure SetBankAccountABI(BankAccountCode: Code[20]; ABIValue: Code[5])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountCode);
        BankAccount.ABI := ABIValue;
        BankAccount.Modify(true)
    end;

    local procedure SetBankAccountIBAN(BankAccountCode: Code[20]; IBANValue: Code[5])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountCode);
        BankAccount.Validate(IBAN, IBANValue);
        BankAccount.Modify(true)
    end;

    local procedure SetBankAccountSWIFT(BankAccountCode: Code[20]; SWIFTValue: Code[5])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountCode);
        BankAccount.Validate("SWIFT Code", SWIFTValue);
        BankAccount.Modify(true)
    end;

    local procedure SetVendorBankAccountIBAN(VendorNo: Code[20]; BankAccountCode: Code[20]; IBANValue: Code[5])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Get(VendorNo, BankAccountCode);
        VendorBankAccount.Validate(IBAN, IBANValue);
        VendorBankAccount.Modify(true)
    end;

    local procedure SetVendorBankAccountSWIFT(VendorNo: Code[20]; BankAccountCode: Code[20]; SWIFTValue: Code[5])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Get(VendorNo, BankAccountCode);
        VendorBankAccount.Validate("SWIFT Code", SWIFTValue);
        VendorBankAccount.Modify(true)
    end;

    local procedure ResetVendorPostalAddress(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate(Address, '');
        Vendor.Validate("Country/Region Code", '');
        Vendor.Validate("Post Code", '');
        Vendor.Validate(City, '');
        Vendor.Modify(true);
    end;

    local procedure VerifyXML(VendorBillHeader: Record "Vendor Bill Header"; var VendorBillLine: Record "Vendor Bill Line")
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        XMLNode: DotNet XmlNode;
        Counter: Integer;
    begin
        VendorBillHeader.CalcFields("Total Amount");
        Vendor.Get(VendorBillLine."Vendor No.");
        CompanyInformation.Get();

        LibraryXPathXMLReader.GetNodeByXPath('/CBIPaymentRequest', XMLNode);
        VerifyNamespace();
        VerifyGroupHeader(VendorBillHeader, VendorBillLine.Count, CompanyInformation.Name);
        VerifyPaymentInformationHeader(VendorBillHeader);
        VerifyDebitor(VendorBillHeader."Bank Account No.", CompanyInformation);
        VerifyChrgBr();

        VendorBillLine.FindFirst();
        Counter := 1;
        repeat
            VerifyCdtTrxInf(VendorBillLine, Vendor, Counter);
            Counter += 1;
        until VendorBillLine.Next() = 0;

        Assert.AreEqual('CBIPaymentRequest', XMLNode.Name, 'CBIPaymentRequest');
    end;

    local procedure VerifyDebitor(BankAccountNo: Code[20]; CompanyInformation: Record "Company Information")
    var
        BankAccount: Record "Bank Account";
        DbtrPrefix: Text[250];
    begin
        DbtrPrefix := '/CBIPaymentRequest/PmtInf/Dbtr/';
        LibraryXPathXMLReader.VerifyNodeValueByXPath(DbtrPrefix + 'Nm', CompanyInformation.Name);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(DbtrPrefix + 'Id/OrgId/Othr/Id', CompanyInformation."VAT Registration No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(DbtrPrefix + 'Id/OrgId/Othr/Issr', 'ADE');

        VerifyCompanyNameAndPostalAddr(DbtrPrefix + 'PstlAdr/', CompanyInformation);
        BankAccount.Get(BankAccountNo);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/CBIPaymentRequest/PmtInf/DbtrAcct/Id/IBAN', BankAccount.IBAN);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/CBIPaymentRequest/PmtInf/DbtrAgt/FinInstnId/ClrSysMmbId/MmbId', BankAccount.ABI);
    end;

    local procedure VerifyCreditor(Vendor: Record Vendor; CdtTrxInfPath: Text[150])
    var
        CdtrPrefix: Text[250];
    begin
        CdtrPrefix := CdtTrxInfPath + '/Cdtr/';
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CdtrPrefix + 'Nm', Vendor.Name);

        VerifyPostalAddress(
          CdtrPrefix + 'PstlAdr/', Vendor.Address, Vendor."Post Code", Vendor.City, Vendor."Country/Region Code");
    end;

    local procedure VerifyCdtrAgt(VendorNo: Code[20]; VendorBankAccountNo: Code[20])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Get(VendorNo, VendorBankAccountNo);
        if VendorBankAccount."SWIFT Code" <> '' then
            LibraryXPathXMLReader.VerifyNodeValueByXPath('/CBIPaymentRequest/PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/BIC',
              VendorBankAccount."SWIFT Code");
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/CBIPaymentRequest/PmtInf/CdtTrfTxInf/CdtrAcct/Id/IBAN',
          VendorBankAccount.IBAN);
    end;

    local procedure VerifyChrgBr()
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/CBIPaymentRequest/PmtInf/ChrgBr', 'SLEV');
    end;

    local procedure VerifyGroupHeader(VendorBillHeader: Record "Vendor Bill Header"; PaymentCount: Integer; CompanyInformationName: Text[100])
    var
        GroupHeaderPath: Text[250];
    begin
        // Mandatory/required elements
        GroupHeaderPath := '/CBIPaymentRequest/GrpHdr/';
        VerifyNodeExistsAndNotEmpty(GroupHeaderPath, 'MsgId');
        VerifyNodeExistsAndNotEmpty(GroupHeaderPath, 'CreDtTm');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(GroupHeaderPath + 'NbOfTxs', Format(PaymentCount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(GroupHeaderPath + 'CtrlSum', Format(VendorBillHeader."Total Amount", 0, 9));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(GroupHeaderPath + 'InitgPty/Nm', CompanyInformationName);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(GroupHeaderPath + 'InitgPty/Id/OrgId/Othr/Issr', 'CBI');
    end;

    local procedure VerifyNamespace()
    begin
        LibraryXPathXMLReader.VerifyAttributeValue('/CBIPaymentRequest', 'xmlns', 'urn:CBI:xsd:CBIPaymentRequest.00.04.00');
    end;

    local procedure VerifyPaymentInformationHeader(VendorBillHeader: Record "Vendor Bill Header")
    var
        PmtInfPrefix: Text[250];
    begin
        // Mandatory elements
        PmtInfPrefix := '/CBIPaymentRequest/PmtInf/';
        VerifyNodeExistsAndNotEmpty(PmtInfPrefix, 'PmtInfId');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(PmtInfPrefix + 'PmtMtd', 'TRF');

        // Optional element
        LibraryXPathXMLReader.VerifyNodeValueByXPath(PmtInfPrefix + 'BtchBookg', 'false');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(PmtInfPrefix + 'PmtTpInf/InstrPrty', 'NORM');

        // Mandatory element
        LibraryXPathXMLReader.VerifyNodeValueByXPath(PmtInfPrefix + 'ReqdExctnDt', Format(VendorBillHeader."Posting Date", 0, 9));
    end;

    local procedure VerifyCompanyNameAndPostalAddr(ParentNodePath: Text[250]; CompanyInformation: Record "Company Information")
    begin
        VerifyPostalAddress(
          ParentNodePath, CompanyInformation.Address,
          CompanyInformation."Post Code", CompanyInformation.City, CompanyInformation."Country/Region Code");
    end;

    local procedure VerifyPostalAddress(SubtreeRootNodeName: Text[250]; Address: Text[250]; PostCode: Text[30]; City: Text[250]; CountryRegionCode: Text[30])
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath(SubtreeRootNodeName + 'StrtNm', Address);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(SubtreeRootNodeName + 'PstCd', PostCode);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(SubtreeRootNodeName + 'TwnNm', City);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(SubtreeRootNodeName + 'Ctry', CountryRegionCode);
    end;

    local procedure VerifyNodeExistsAndNotEmpty(ParentNodePath: Text[250]; NodeName: Text[30])
    var
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(ParentNodePath + NodeName, Node);
        Assert.AreNotEqual(
          '',
          Node.InnerText,
          StrSubstNo(UnexpectedEmptyNodeErr, NodeName, ParentNodePath));
    end;

    local procedure VerifyCdtTrxInf(VendorBillLine: Record "Vendor Bill Line"; Vendor: Record Vendor; Counter: Integer)
    var
        CdtTrxInfPath: Text[150];
    begin
        CdtTrxInfPath := '/CBIPaymentRequest/PmtInf/CdtTrfTxInf[' + Format(Counter) + ']';
        VerifyNodeExistsAndNotEmpty(CdtTrxInfPath + '/PmtId/', 'EndToEndId');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CdtTrxInfPath + '/Amt/InstdAmt', Format(VendorBillLine."Amount to Pay", 0, 9));

        VerifyCdtrAgt(VendorBillLine."Vendor No.", VendorBillLine."Vendor Bank Acc. No.");
        VerifyCreditor(Vendor, CdtTrxInfPath);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;
}

