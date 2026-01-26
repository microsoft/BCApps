codeunit 144116 "E-Invoice Fin. Ch. Memo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [EHF] [Finance Charge Memo]
    end;

    var
        Assert: Codeunit Assert;
        EInvoiceHelper: Codeunit "E-Invoice Helper";
        EInvoiceFinChMemoHelper: Codeunit "E-Invoice Fin. Ch. Memo Helper";
        EInvoiceXMLXSDValidation: Codeunit "E-Invoice XML XSD Validation";
        NOXMLReadHelper: Codeunit "NO XML Read Helper";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
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
    procedure CreateEInvoiceFinChMemoFile()
    var
        XmlFileName: Text[1024];
    begin
        Initialize();

        XmlFileName := EInvoiceFinChMemo();

        EInvoiceXMLXSDValidation.CheckIfFileExists(XmlFileName);
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cbc:ProfileID', 'urn:www.cenbii.eu:profile:biixy:ver1.0');
        NOXMLReadHelper.VerifyNodeValue(
          '//cbc:CustomizationID',
          'urn:www.cenbii.eu:transaction:biicoretrdm017:ver1.0:#urn:www.cenbii.eu:profile:biixy:ver1.0#urn:www.difi.no:ehf:purring:ver1');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure DocumentReferenceMapping()
    var
        IssuedFinChMemoNo: Code[20];
        XmlFileName: Text[1024];
    begin
        Initialize();

        IssuedFinChMemoNo := EInvoiceFinChMemoHelper.CreateFinChMemo();
        AddLinesToIssuedFinChMemo(IssuedFinChMemoNo);

        XmlFileName := ExecEInvoiceFinChMemo(IssuedFinChMemoNo);

        ValidateBillingReferenceChild(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceFinChMemoEndpointID()
    begin
        Initialize();
        EInvoiceXMLXSDValidation.VerifyEndpointID(EInvoiceFinChMemo());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EmptyDocumentReference()
    var
        IssuedFinChMemoNo: Code[20];
        XmlFileName: Text[1024];
    begin
        Initialize();

        IssuedFinChMemoNo := EInvoiceFinChMemoHelper.CreateFinChMemo();

        XmlFileName := ExecEInvoiceFinChMemo(IssuedFinChMemoNo);

        ValidateBillingReferenceChild(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure FinChMemoFileEntReg()
    var
        CompanyInfo: Record "Company Information";
        FinChHdr: Record "Issued Fin. Charge Memo Header";
        Cust: Record Customer;
        XmlFileName: Text[1024];
        FinchNo: Code[20];
    begin
        Initialize();
        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(true);

        FinchNo := EInvoiceFinChMemoHelper.CreateFinChMemo();
        CompanyInfo.Get();
        FinChHdr.Get(FinchNo);
        Cust.Get(FinChHdr."Customer No.");

        // exercise
        XmlFileName := ExecEInvoiceFinChMemo(FinchNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, FinChHdr.Name,
          EInvoiceExportCommon.WriteCompanyID(CompanyInfo."VAT Registration No."), true); // entRegister = TRUE
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure FinChMemoFileNoEntReg()
    var
        CompanyInfo: Record "Company Information";
        FinChHdr: Record "Issued Fin. Charge Memo Header";
        Cust: Record Customer;
        XmlFileName: Text[1024];
        FinchNo: Code[20];
    begin
        Initialize();
        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(false);

        FinchNo := EInvoiceFinChMemoHelper.CreateFinChMemo();
        CompanyInfo.Get();
        FinChHdr.Get(FinchNo);
        Cust.Get(FinChHdr."Customer No.");

        // exercise
        XmlFileName := ExecEInvoiceFinChMemo(FinchNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, FinChHdr.Name,
          EInvoiceExportCommon.WriteCompanyID(CompanyInfo."VAT Registration No."), false); // entRegister = FALSE;
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure FinChMemoWithOneVATGroup()
    begin
        Initialize();

        FinChMemoWithNoOfVATGroups(1);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure FinChMemoWithTwoVATGroups()
    begin
        Initialize();

        FinChMemoWithNoOfVATGroups(2);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure FinChMemoWithAllVATGroups()
    begin
        Initialize();

        FinChMemoWithNoOfVATGroups(5);
    end;

    local procedure FinChMemoWithNoOfVATGroups(NoOfGroups: Integer)
    var
        FinChMemoHeader: Record "Finance Charge Memo Header";
        TempVATEntry: Record "VAT Entry" temporary;
        FinChMemoNo: Code[20];
        VATRate: array[5] of Decimal;
        XmlFileName: Text;
    begin
        SetVATRates(NoOfGroups, VATRate);
        FinChMemoNo := EInvoiceFinChMemoHelper.CreateFinChMemoWithVATGroups(FinChMemoHeader, VATRate);

        EInvoiceXMLXSDValidation.VerifyVATEntriesCount(
          TempVATEntry."Document Type"::"Finance Charge Memo", FinChMemoNo, NoOfGroups, TempVATEntry);

        XmlFileName := ExecEInvoiceFinChMemo(FinChMemoNo);
        EInvoiceXMLXSDValidation.VerifyVATDataInTaxSubtotal(TempVATEntry, XmlFileName, NoOfGroups);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure NoAccountingCostCodeAdded()
    var
        XmlFileName: Text[1024];
    begin
        Initialize();

        XmlFileName := EInvoiceFinChMemo();

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCostCode');
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCost');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ValidateEInvFinChMemoFile()
    begin
        Initialize();
        EInvoiceFinChMemo();
    end;

    local procedure AddLinesToIssuedFinChMemo(IssuedFinChMemoNo: Code[20])
    var
        IssuedFinChMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChMemoHeader.Get(IssuedFinChMemoNo);

        AddLineToIssuedFinChMemo(IssuedFinChMemoHeader, IssuedFinChMemoLine."Document Type"::Payment);
        AddLineToIssuedFinChMemo(IssuedFinChMemoHeader, IssuedFinChMemoLine."Document Type"::Invoice);
        AddLineToIssuedFinChMemo(IssuedFinChMemoHeader, IssuedFinChMemoLine."Document Type"::"Credit Memo");
        AddLineToIssuedFinChMemo(IssuedFinChMemoHeader, IssuedFinChMemoLine."Document Type"::"Finance Charge Memo");
        AddLineToIssuedFinChMemo(IssuedFinChMemoHeader, IssuedFinChMemoLine."Document Type"::Reminder);
        AddLineToIssuedFinChMemo(IssuedFinChMemoHeader, IssuedFinChMemoLine."Document Type"::Refund);
    end;

    local procedure AddLineToIssuedFinChMemo(IssuedFinChMemoHeader: Record "Issued Fin. Charge Memo Header"; DocumentType: Enum "Gen. Journal Document Type")
    var
        IssuedFinChMemoLine: Record "Issued Fin. Charge Memo Line";
        AmountValue: Decimal;
    begin
        AmountValue := LibraryRandom.RandDec(1000, 2);
        IssuedFinChMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChMemoHeader."No.");
        IssuedFinChMemoLine.FindLast();
        IssuedFinChMemoLine.Init();
        IssuedFinChMemoLine."Line No." := IssuedFinChMemoLine."Line No." + 10000;
        IssuedFinChMemoLine.Type := IssuedFinChMemoLine.Type::"Customer Ledger Entry";
        IssuedFinChMemoLine."Document Type" := DocumentType;
        IssuedFinChMemoLine."Document No." := Format(DocumentType);
        IssuedFinChMemoLine.Description := Format(DocumentType);
        IssuedFinChMemoLine.Amount := AmountValue;
        IssuedFinChMemoLine.Insert();
    end;

    local procedure EInvoiceFinChMemo(): Text[1024]
    var
        IssuedFinChargeMemoNo: Code[20];
    begin
        IssuedFinChargeMemoNo := EInvoiceFinChMemoHelper.CreateFinChMemo();
        exit(ExecEInvoiceFinChMemo(IssuedFinChargeMemoNo));
    end;

    local procedure ExecEInvoiceFinChMemo(IssuedFinChargeMemoNo: Code[20]): Text[1024]
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        Path: Text[250];
    begin
        Path := EInvoiceHelper.GetTempPath();
        EInvoiceHelper.SetupEInvoiceForSales(Path);

        IssuedFinChargeMemoHeader.SetRange("No.", IssuedFinChargeMemoNo);
        REPORT.Run(REPORT::"Create Elec. Fin. Chrg. Memos", false, true, IssuedFinChargeMemoHeader);

        exit(Path + IssuedFinChargeMemoNo + '.xml');
    end;

    local procedure GetDocReferenceTagName(DocType: Enum "Gen. Journal Document Type"): Text[100]
    var
        IssuedFinChMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        case DocType of
            IssuedFinChMemoLine."Document Type"::Invoice,
          IssuedFinChMemoLine."Document Type"::Refund:
                exit('cac:InvoiceDocumentReference');
            IssuedFinChMemoLine."Document Type"::"Credit Memo",
          IssuedFinChMemoLine."Document Type"::Payment:
                exit('cac:CreditNoteDocumentReference');
            IssuedFinChMemoLine."Document Type"::Reminder,
          IssuedFinChMemoLine."Document Type"::"Finance Charge Memo":
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

