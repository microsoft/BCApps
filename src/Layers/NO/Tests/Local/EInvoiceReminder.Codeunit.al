codeunit 144118 "E-Invoice Reminder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [EHF] [Reminder]
    end;

    var
        Assert: Codeunit Assert;
        EInvoiceHelper: Codeunit "E-Invoice Helper";
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
        LibraryERM: Codeunit "Library - ERM";
        EInvoiceReminderHelper: Codeunit "E-Invoice Reminder Helper";
        EInvoiceXMLXSDValidation: Codeunit "E-Invoice XML XSD Validation";
        NOXMLReadHelper: Codeunit "NO XML Read Helper";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        SuccessfullyCreatedMsg: Label 'Successfully created ';
        NoTaxRate: Decimal;
        LowRate: Decimal;
        ReducedRate: Decimal;
        HighRate: Decimal;
        StandardRate: Decimal;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure CreateEInvoiceReminderFile()
    var
        XmlFileName: Text[1024];
    begin
        Initialize();

        XmlFileName := EInvoiceReminder();

        EInvoiceXMLXSDValidation.CheckIfFileExists(XmlFileName);
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cbc:ProfileID', 'urn:www.cenbii.eu:profile:biixy:ver1.0');
        NOXMLReadHelper.VerifyNodeValue('//cbc:CustomizationID', GetCustomizationID());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure DocumentReferenceMapping()
    var
        IssuedReminderNo: Code[20];
        XmlFileName: Text[1024];
    begin
        Initialize();

        IssuedReminderNo := EInvoiceReminderHelper.CreateReminder();
        AddLinesToIssuedReminder(IssuedReminderNo);

        XmlFileName := ExecEInvoiceReminder(IssuedReminderNo);

        ValidateBillingReferenceChild(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceReminderEndpointID()
    begin
        Initialize();
        EInvoiceXMLXSDValidation.VerifyEndpointID(EInvoiceReminder());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceReminderFileEntReg()
    var
        CompanyInfo: Record "Company Information";
        IssReminderHdr: Record "Issued Reminder Header";
        XmlFileName: Text[1024];
        IssReminderNo: Code[20];
    begin
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(true);
        IssReminderNo := EInvoiceReminderHelper.CreateReminder();
        IssReminderHdr.Get(IssReminderNo);
        CompanyInfo.Get();

        // exercise
        XmlFileName := ExecEInvoiceReminder(IssReminderNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, IssReminderHdr.Name,
          EInvoiceExportCommon.WriteCompanyID(CompanyInfo."VAT Registration No."), true); // EntRegister = TRUE
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceReminderFileNonEntReg()
    var
        CompanyInfo: Record "Company Information";
        IssReminderHdr: Record "Issued Reminder Header";
        XmlFileName: Text[1024];
        IssReminderNo: Code[20];
    begin
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(false);
        IssReminderNo := EInvoiceReminderHelper.CreateReminder();
        IssReminderHdr.Get(IssReminderNo);
        CompanyInfo.Get();

        // exercise
        XmlFileName := ExecEInvoiceReminder(IssReminderNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, IssReminderHdr.Name,
          EInvoiceExportCommon.WriteCompanyID(CompanyInfo."VAT Registration No."), false); // EntRegister = FALSE
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EmptyDocumentReference()
    var
        IssuedReminderNo: Code[20];
        XmlFileName: Text[1024];
    begin
        Initialize();

        IssuedReminderNo := EInvoiceReminderHelper.CreateReminder();

        XmlFileName := ExecEInvoiceReminder(IssuedReminderNo);

        ValidateBillingReferenceChild(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure NoAccountingCostCodeAdded()
    var
        XmlFileName: Text[1024];
    begin
        Initialize();

        XmlFileName := EInvoiceReminder();

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCostCode');
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCost');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithAllVATGroups()
    begin
        Initialize();

        ReminderWithNoOfVATGroups(5);
    end;

    local procedure ReminderWithNoOfVATGroups(NoOfGroups: Integer)
    var
        ReminderHeader: Record "Reminder Header";
        TempVATEntry: Record "VAT Entry" temporary;
        ReminderNo: Code[20];
        VATRate: array[5] of Decimal;
        XmlFileName: Text;
    begin
        SetVATRates(NoOfGroups, VATRate);
        ReminderNo := EInvoiceReminderHelper.CreateReminderWithVATGroups(ReminderHeader, VATRate);

        EInvoiceXMLXSDValidation.VerifyVATEntriesCount(TempVATEntry."Document Type"::Reminder, ReminderNo, NoOfGroups, TempVATEntry);

        XmlFileName := ExecEInvoiceReminder(ReminderNo);
        EInvoiceXMLXSDValidation.VerifyVATDataInTaxSubtotal(TempVATEntry, XmlFileName, NoOfGroups);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithOneVATGroup()
    begin
        Initialize();
        ReminderWithNoOfVATGroups(1);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithTwoVATGroups()
    begin
        Initialize();
        ReminderWithNoOfVATGroups(2);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ValidateEInvReminderFile()
    begin
        Initialize();
        EInvoiceReminder();
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithVATExemption()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderLineFee: Record "Reminder Line";
        IssuedReminderNo: Code[20];
        XmlFileName: Text;
        LineNo: Integer;
    begin
        // [SCENARIO 302996] Tax subtotals created for reminder lines if VAT Prod. Posting Group is not empty
        Initialize();

        // [GIVEN] Zero VAT Posting Setup with Description = "ZeroVAT"
        // [GIVEN] Reminder where first line is fee line of zero VAT and one line with Description = "Fee" and Amount = 1000
        // [GIVEN] Second line is Cust. Ledger Entry line with Description = "CLE" and "Remaining amount" = 150
        EInvoiceReminderHelper.CreateReminderHeader(ReminderHeader);
        EInvoiceReminderHelper.CreateReminderLines(
          ReminderHeader."No.", 1, CreateZeroVATPostingSetup(ReminderHeader."VAT Bus. Posting Group"), LineNo);
        ReminderLineFee.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderLineFee.FindFirst();
        AddCustLedgerEntryReminderLine(ReminderLine, ReminderHeader);
        IssuedReminderNo := EInvoiceReminderHelper.IssueReminder(ReminderHeader."No.");

        // [WHEN] Create Electronic Reminder
        XmlFileName := ExecEInvoiceReminder(IssuedReminderNo);

        // [THEN] One TaxSubtotal is exported with TaxAmount = 0 and TaxExemptionReason = "ZeroVAT"
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount', FormatAmount(0));
        NOXMLReadHelper.VerifyNodeValue(
          '//cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReason', ReminderLineFee."VAT Prod. Posting Group");
        asserterror NOXMLReadHelper.VerifyNextNodeValue('//cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount', FormatAmount(0), 1);
        Assert.ExpectedError('Node count is wrong');

        // [THEN] Fee reminder line is exported with Description = "Fee" and Amount = 1000
        NOXMLReadHelper.VerifyNodeValue(
          '//cac:ReminderLine/cbc:Note', ReminderLineFee.Description + FormatAmount(ReminderLineFee."Remaining Amount"));
        NOXMLReadHelper.VerifyNodeValue('//cac:ReminderLine/cbc:DebitLineAmount', FormatAmount(ReminderLineFee.Amount));
        // [THEN] Cust. Ledger Entry reminder line is exported with Description = "CLE" and "Remaining amount" = 150
        NOXMLReadHelper.VerifyNextNodeValue(
          '//cac:ReminderLine/cbc:Note', ReminderLine.Description + FormatAmount(ReminderLine."Remaining Amount"), 1);
        NOXMLReadHelper.VerifyNextNodeValue('//cac:ReminderLine/cbc:DebitLineAmount', Format(0), 1);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithCustomerVATAndGLN()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        XmlFileName: Text;
    begin
        // [SCENARIO 303015] AccountingCustomerParty/Party/EndpointID is taken from Customer's VAT Registration No. when GLN is not blank
        Initialize();

        // [GIVEN] Reminder with GLN = '01234123456789' and 'VAT Reg. No.' = 'NO123456000'
        IssuedReminderHeader.Get(EInvoiceReminderHelper.CreateReminder());
        IssuedReminderHeader.GLN := LibraryUtility.GenerateGUID();
        IssuedReminderHeader."VAT Registration No." := LibraryUtility.GenerateGUID();
        IssuedReminderHeader.Modify();

        // [WHEN] Create Electronic Reminder
        XmlFileName := ExecEInvoiceReminder(IssuedReminderHeader."No.");

        // [THEN] 'EndpointID' is exported as '123456000'
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue(
          '//cac:AccountingCustomerParty/cac:Party/cbc:EndpointID',
          EInvoiceDocumentEncode.GetVATRegNo(IssuedReminderHeader."VAT Registration No.", false));
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithCustomerGLN()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        XmlFileName: Text;
    begin
        // [SCENARIO 303015] AccountingCustomerParty/Party/EndpointID is taken from Customer's GLN when VAT Registration No. is blank
        Initialize();

        // [GIVEN] Reminder with GLN = '01234123456789' 'VAT Reg. No.' = blank
        IssuedReminderHeader.Get(EInvoiceReminderHelper.CreateReminder());
        IssuedReminderHeader.GLN := LibraryUtility.GenerateGUID();
        IssuedReminderHeader."VAT Registration No." := '';
        IssuedReminderHeader.Modify();

        // [WHEN] Create Electronic Reminder
        XmlFileName := ExecEInvoiceReminder(IssuedReminderHeader."No.");

        // [THEN] 'EndpointID' is exported as '9908:01234123456789'
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue(
          '//cac:AccountingCustomerParty/cac:Party/cbc:EndpointID', '9908:' + IssuedReminderHeader.GLN);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithCompanyInfoVATAndGLN()
    var
        CompanyInformation: Record "Company Information";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        IssuedReminderNo: Code[20];
        XmlFileName: Text;
    begin
        // [SCENARIO 303015] AccountingSupplierParty/Party/EndpointID is taken from Company's VAT Registration No. when GLN is not blank
        Initialize();

        // [GIVEN] Company Information with GLN = '01234123456789' and 'VAT Reg. No.' = 'NO123456000'
        CompanyInformation.Get();
        CompanyInformation.GLN := LibraryUtility.GenerateGUID();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify();
        IssuedReminderNo := EInvoiceReminderHelper.CreateReminder();

        // [WHEN] Create Electronic Reminder
        XmlFileName := ExecEInvoiceReminder(IssuedReminderNo);

        // [THEN] 'EndpointID' is exported as '123456000'
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue(
          '//cac:AccountingSupplierParty/cac:Party/cbc:EndpointID',
          EInvoiceDocumentEncode.GetVATRegNo(CompanyInformation."VAT Registration No.", false));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        InitGlobalVATRates();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        isInitialized := true;
    end;

    local procedure AddLineToIssuedReminder(IssuedReminderHeader: Record "Issued Reminder Header"; DocumentType: Enum "Gen. Journal Document Type")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        AmountValue: Decimal;
    begin
        AmountValue := LibraryRandom.RandDec(1000, 2);
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.FindLast();
        IssuedReminderLine.Init();
        IssuedReminderLine."Line No." := IssuedReminderLine."Line No." + 10000;
        IssuedReminderLine.Type := IssuedReminderLine.Type::"Customer Ledger Entry";
        IssuedReminderLine."Document Type" := DocumentType;
        IssuedReminderLine."Document No." := Format(DocumentType);
        IssuedReminderLine.Description := Format(DocumentType);
        IssuedReminderLine.Amount := AmountValue;
        IssuedReminderLine.Insert();
    end;

    local procedure AddLinesToIssuedReminder(IssuedReminderNo: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderHeader.Get(IssuedReminderNo);

        AddLineToIssuedReminder(IssuedReminderHeader, IssuedReminderLine."Document Type"::Payment);
        AddLineToIssuedReminder(IssuedReminderHeader, IssuedReminderLine."Document Type"::Invoice);
        AddLineToIssuedReminder(IssuedReminderHeader, IssuedReminderLine."Document Type"::"Credit Memo");
        AddLineToIssuedReminder(IssuedReminderHeader, IssuedReminderLine."Document Type"::"Finance Charge Memo");
        AddLineToIssuedReminder(IssuedReminderHeader, IssuedReminderLine."Document Type"::Reminder);
        AddLineToIssuedReminder(IssuedReminderHeader, IssuedReminderLine."Document Type"::Refund);
    end;

    local procedure AddCustLedgerEntryReminderLine(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header")
    begin
        ReminderLine.Init();
        ReminderLine."Reminder No." := ReminderHeader."No.";
        ReminderLine."Line No." := LibraryUtility.GetNewRecNo(ReminderLine, ReminderLine.FieldNo("Line No."));
        ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
        ReminderLine."Entry No." := MockCustLedgerEntry(ReminderHeader."Customer No.");
        ReminderLine.Description := LibraryUtility.GenerateGUID();
        ReminderLine."Remaining Amount" := LibraryRandom.RandInt(1000);
        ReminderLine.Insert();
    end;

    local procedure CreateZeroVATPostingSetup(VATBusPostGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostGroupCode;
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup.Insert();
        exit(VATProductPostingGroup.Code);
    end;

    local procedure EInvoiceReminder(): Text[1024]
    var
        IssuedReminderNo: Code[20];
    begin
        IssuedReminderNo := EInvoiceReminderHelper.CreateReminder();
        exit(ExecEInvoiceReminder(IssuedReminderNo));
    end;

    local procedure ExecEInvoiceReminder(IssuedReminderNo: Code[20]): Text[1024]
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        Path: Text[250];
    begin
        Path := EInvoiceHelper.GetTempPath();
        EInvoiceHelper.SetupEInvoiceForSales(Path);

        IssuedReminderHeader.SetRange("No.", IssuedReminderNo);
        REPORT.Run(REPORT::"Create Electronic Reminders", false, true, IssuedReminderHeader);

        exit(Path + IssuedReminderNo + '.xml');
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    local procedure GetCustomizationID(): Text[250]
    begin
        exit(
          'urn:www.cenbii.eu:transaction:biicoretrdm017:ver1.0:#urn:www.cenbii.eu:profile:biixy:ver1.0#urn:www.difi.no:ehf:purring:ver1');
    end;

    local procedure GetDocReferenceTagName(DocType: Enum "Gen. Journal Document Type"): Text[100]
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        case DocType of
            IssuedReminderLine."Document Type"::Invoice,
          IssuedReminderLine."Document Type"::Refund:
                exit('cac:InvoiceDocumentReference');
            IssuedReminderLine."Document Type"::"Credit Memo",
          IssuedReminderLine."Document Type"::Payment:
                exit('cac:CreditNoteDocumentReference');
            IssuedReminderLine."Document Type"::Reminder,
          IssuedReminderLine."Document Type"::"Finance Charge Memo":
                exit('cac:ReminderDocumentReference');
        end;
    end;

    local procedure InitGlobalVATRates()
    begin
        NoTaxRate := 0;
        LowRate := 10;
        ReducedRate := 11.11;
        HighRate := 15;
        StandardRate := 25;
    end;

    local procedure MockCustLedgerEntry(CustomerNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure SetVATRates(NoOfGroups: Integer; var VATRate: array[5] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATRate) do
            VATRate[i] := -1;

        if NoOfGroups > 0 then
            VATRate[1] := StandardRate;
        if NoOfGroups > 1 then
            VATRate[2] := LowRate;
        if NoOfGroups > 2 then
            VATRate[3] := NoTaxRate;
        if NoOfGroups > 3 then
            VATRate[4] := ReducedRate;
        if NoOfGroups > 4 then
            VATRate[5] := HighRate;
    end;

    local procedure ValidateBillingReferenceChild(FullFilePath: Text[1024])
    var
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
        i: Integer;
        ReferenceName: Text[100];
        IdValue: Integer;
    begin
        NOXMLReadHelper.Initialize(FullFilePath);
        NOXMLReadHelper.GetNodeListByElementName('//cac:BillingReference', NodeList);
        Assert.AreNotEqual(0, NodeList.Count, 'There must be BillingReference section');
        for i := 0 to NodeList.Count - 1 do begin
            Node := NodeList.Item(i);
            if Node.ChildNodes.Count <> 0 then begin
                Assert.AreEqual(1, Node.ChildNodes.Count, 'Should be only one child in BillingReference node');
                Node := Node.FirstChild;
                ReferenceName := Node.Name;
                Evaluate(IdValue, NOXMLReadHelper.GetElementValueInCurrNode(Node, 'cbc:ID'));
                Assert.AreEqual(GetDocReferenceTagName("Gen. Journal Document Type".FromInteger(IdValue)), ReferenceName, 'Wrong reference name');
            end;
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SuccessMsgHandler(Text: Text[1024])
    begin
        Assert.ExpectedMessage(SuccessfullyCreatedMsg, Text);
    end;
}

