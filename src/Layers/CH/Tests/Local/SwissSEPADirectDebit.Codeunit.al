codeunit 144085 "Swiss SEPA Direct Debit"
{
    // // [FEATURE] [SEPA] [Direct Debit]

    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        StringConversionMgt: Codeunit StringConversionManagement;
        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure IsSEPADDExportForW1Export()
    var
        CHMgt: Codeunit CHMgt;
        DDCollectionNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222118] IsSwissSEPADDExport returns FALSE when "SEPA Direct Debit Exp. Format" is set up with W1 processing codeunit
        DDCollectionNo := CreateMockBankAccWithDDSetup(GetW1ProcCodeunitID());
        Assert.IsFalse(CHMgt.IsSwissSEPADDExport(DDCollectionNo), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsSEPADDExportForSwissExport()
    var
        CHMgt: Codeunit CHMgt;
        DDCollectionNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222118] IsSwissSEPADDExport returns FALSE when "SEPA Direct Debit Exp. Format" is set up with Swiss processing codeunit
        DDCollectionNo := CreateMockBankAccWithDDSetup(GetSwissProcCodeunitID());
        Assert.IsTrue(CHMgt.IsSwissSEPADDExport(DDCollectionNo), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSwissDDCollectionCHF()
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SEPADDExportFile: Codeunit "SEPA DD-Export File";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 222118] Export Direct Debit Collection with ch03 xml schema for invoice in local currency
        Initialize();

        // [GIVEN] LCY Currency set to 'CHF' in G/L Setup
        LibraryERM.SetLCYCode('CHF');

        // [GIVEN] Bank Account with Direct Debit Export Setup
        BankAccountNo := CreateBankWithDDSetup();

        // [GIVEN] Local Customer with Posted Sales Invoice in LCY
        CreateCustomerAndPostInvoice(Customer, SEPADirectDebitMandate, CustLedgerEntry);
        CustLedgerEntry.TestField("Currency Code", '');

        // [GIVEN] Direct Debit Collection Entry
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgerEntry, BankAccountNo);

        // [WHEN] When run SEPA DD Export File
        SEPADDExportFile.EnableExportToServerFile();
        SEPADDExportFile.Run(DirectDebitCollectionEntry);

        // [THEN] Export completed without errors
        // [THEN] Direct Debit Collection updated with Status "File Created"
        DirectDebitCollection.Find();
        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::"File Created");
        DirectDebitCollectionEntry.Find();
        DirectDebitCollectionEntry.TestField(Status, DirectDebitCollectionEntry.Status::"File Created");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSwissDDCollectionVerifyXML()
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 222118] Create xml via Export Direct Debit Collection with ch03 xml schema
        Initialize();

        // [GIVEN] LCY Currency set to 'CHF' in G/L Setup
        LibraryERM.SetLCYCode('CHF');

        // [GIVEN] Bank Account with Direct Debit Export Setup
        BankAccountNo := CreateBankWithDDSetup();

        // [GIVEN] Direct Debit Collection Entry for local Customer with Posted Sales Invoice in LCY
        CreateCustomerAndPostInvoice(Customer, SEPADirectDebitMandate, CustLedgerEntry);
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgerEntry, BankAccountNo);

        // [WHEN] Export XML via 'SEPA DD pain.008.001.02.ch03' xml port
        ExportSwissSEPADD(DirectDebitCollectionEntry, TempBlob);

        // [THEN] Namespace and tags match to posted data in exported XML
        VerifySepaDDXML(DirectDebitCollectionEntry, TempBlob);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Swiss SEPA Direct Debit");
        LibrarySetupStorage.Restore();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Swiss SEPA Direct Debit");

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Swiss SEPA Direct Debit");
    end;

    local procedure ExportSwissSEPADD(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
        TempBlob.CreateOutStream(OutStream);
        XMLPORT.Export(GetSEPADDExportXMLPortID(), OutStream, DirectDebitCollectionEntry);
    end;

    local procedure GetIBAN(): Code[50]
    begin
        exit('CH9581320000001998736');
    end;

    local procedure GetIBANCust(): Code[50]
    begin
        exit('CH0400235235X98765432');
    end;

    local procedure GetSWIFT(): Code[20]
    begin
        exit('MUDABAABC');
    end;

    local procedure GetSWIFTCUst(): Code[20]
    begin
        exit('DKDABAKK');
    end;

    local procedure GetRSPID(): Code[35]
    begin
        exit('41101000000465011');
    end;

    local procedure GetW1ProcCodeunitID(): Integer
    begin
        exit(CODEUNIT::"SEPA DD-Export File");
    end;

    local procedure GetSwissProcCodeunitID(): Integer
    begin
        exit(CODEUNIT::"Swiss SEPA DD-Export File");
    end;

    local procedure GetSEPADDExportXMLPortID(): Integer
    begin
        exit(XMLPORT::"SEPA DD pain.008.001.02.ch03");
    end;

    local procedure CreateBankWithDDSetup(): Code[20]
    begin
        UpdateDDNosOnSalesSetup();
        exit(
          CreateBankAccount(CreateBankExpImpSetup()));
    end;

    local procedure CreateBankExpImpSetup(): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        BankExportImportSetup."Processing Codeunit ID" := GetSwissProcCodeunitID();
        BankExportImportSetup."Processing XMLport ID" := GetSEPADDExportXMLPortID();
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA DD-Check Line";
        BankExportImportSetup.Insert();
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateBankAccount(BankExpImpCode: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."SEPA Direct Debit Exp. Format" := BankExpImpCode;
        BankAccount."Direct Debit Msg. Nos." := LibraryERM.CreateNoSeriesCode();
        BankAccount.IBAN := GetIBAN();
        BankAccount."SWIFT Code" := GetSWIFT();
        BankAccount."Creditor No." := GetRSPID();
        BankAccount.Modify();
        exit(BankAccount."No.");
    end;

    local procedure CreateMockBankAccWithDDSetup(ProcessingCodeunitID: Integer): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunitID;
        BankExportImportSetup.Insert();
        DirectDebitCollection.Init();
        DirectDebitCollection."No." := LibraryUtility.GetNewRecNo(DirectDebitCollection, DirectDebitCollection.FieldNo("No."));
        DirectDebitCollection."To Bank Account No." := CreateBankAccount(BankExportImportSetup.Code);
        DirectDebitCollection.Insert();
        exit(DirectDebitCollection."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.IBAN := GetIBANCust();
        CustomerBankAccount."SWIFT Code" := GetSWIFTCUst();
        CustomerBankAccount.Modify();
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateCustomerWithDDMandate(var Customer: Record Customer; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    var
        CustBankAccCode: Code[10];
    begin
        LibrarySales.CreateCustomer(Customer);
        CustBankAccCode := CreateCustomerBankAccount(Customer."No.");
        Customer."Preferred Bank Account Code" := CustBankAccCode;
        Customer."Partner Type" := Customer."Partner Type"::Company;
        Customer.Address := LibraryUtility.GenerateGUID();
        Customer.Modify();

        CreateMandate(SEPADirectDebitMandate, Customer."No.");
        SEPADirectDebitMandate."Customer Bank Account Code" := CustBankAccCode;
        SEPADirectDebitMandate.Modify();
    end;

    local procedure CreateCustomerAndPostInvoice(var Customer: Record Customer; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        InvoiceNo: Code[20];
    begin
        CreateCustomerWithDDMandate(Customer, SEPADirectDebitMandate);
        InvoiceNo := PostCustGenJnlLine(Customer."No.", SEPADirectDebitMandate.ID);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure CreateDirectDebitCollectionEntry(var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; BankAccountNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustLedgerEntry."Customer No.");
        DirectDebitCollection.CreateRecord(
          LibraryUtility.GenerateGUID(), BankAccountNo, Customer."Partner Type");

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.CreateNew(DirectDebitCollection."No.", CustLedgerEntry);

        DirectDebitCollectionEntry."Transfer Amount" := CustLedgerEntry."Remaining Amount";
        DirectDebitCollectionEntry.Modify();
    end;

    local procedure PostCustGenJnlLine(CustomerNo: Code[20]; DirectDebitMandateID: Code[35]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Direct Debit Mandate ID", DirectDebitMandateID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateMandate(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CustNo: Code[20])
    begin
        SEPADirectDebitMandate.ID := LibraryUtility.GenerateGUID();
        SEPADirectDebitMandate."Customer No." := CustNo;
        SEPADirectDebitMandate."Type of Payment" := SEPADirectDebitMandate."Type of Payment"::Recurrent;
        SEPADirectDebitMandate."Expected Number of Debits" := 10;
        SEPADirectDebitMandate."Date of Signature" := Today;
        SEPADirectDebitMandate.Insert();
    end;

    local procedure GetCreditorNo(BankAccNo: Code[20]): Text
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);
        exit(BankAccount."Creditor No.");
    end;

    local procedure UpdateDDNosOnSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Direct Debit Mandate Nos." := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup.Modify();
    end;

    local procedure VerifySepaDDXML(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var TempBlob: Codeunit "Temp Blob")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        XMLNode: DotNet XmlNode;
    begin
        DirectDebitCollection.Get(DirectDebitCollectionEntry."Direct Debit Collection No.");

        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, 'http://www.six-interbank-clearing.com/de/pain.008.001.02.ch.03.xsd');
        VerifyXMLHeader();
        LibraryXPathXMLReader.GetNodeByXPath('/Document/CstmrDrctDbtInitn', XMLNode);
        VerifyGrpHdrAndInitgPty(DirectDebitCollectionEntry, DirectDebitCollection."Message ID");
        VerifyPmtInf(GetCreditorNo(DirectDebitCollection."To Bank Account No."), DirectDebitCollectionEntry."Transfer Date");
    end;

    local procedure VerifyXMLHeader()
    begin
        LibraryXPathXMLReader.VerifyXMLDeclaration('1.0', 'UTF-8', 'no');
    end;

    local procedure VerifyGrpHdrAndInitgPty(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; MessageID: Text)
    var
        CompanyInformation: Record "Company Information";
        CreDtTmTxt: Text;
        DtTm: DateTime;
    begin
        DirectDebitCollectionEntry.CalcSums("Transfer Amount");
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//GrpHdr/MsgId', MessageID);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//GrpHdr/NbOfTxs', Format(DirectDebitCollectionEntry.Count, 0, 9));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '//GrpHdr/CtrlSum', Format(DirectDebitCollectionEntry."Transfer Amount", 0, '<Precision,2:2><Standard Format,9>'));

        CreDtTmTxt := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//GrpHdr/CreDtTm', 0);
        Evaluate(DtTm, CreDtTmTxt, 9);
        Assert.AreNearlyEqual(0, CurrentDateTime - DtTm, 60000, 'Wrong CreDtTm.');
        Assert.AreEqual(19, StrLen(CreDtTmTxt), 'Wrong CreDtTm length');

        CompanyInformation.Get();
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//InitgPty/Nm', CompanyInformation.Name);
        LibraryXPathXMLReader.VerifyNodeAbsence('CtctDtls');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//InitgPty/Id', GetRSPID());
    end;

    local procedure VerifyPmtInf(ExpectedCreditorNo: Text; ExpectedDate: Date)
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/PmtInfId', XMLNode);
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/CdtrAcct', XMLNode);
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/CdtrAgt', XMLNode);
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/CdtrAgt/FinInstnId', XMLNode);
        LibraryXPathXMLReader.VerifyNodeAbsence('//PmtInf/CdtrAgt/FinInstnId/Othr');

        LibraryXPathXMLReader.VerifyNodeValueByXPath('//PmtInf/PmtMtd', 'DD');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//PmtInf/ReqdColltnDt', Format(ExpectedDate, 0, '<Standard Format,9>'));

        VerifyPmtTpInf(); // <PmtInf><PmtTpInf>
        VerifyCdtr(); // <PmtInf><Cdtr>
        VerifyCdtrSchmeId(ExpectedCreditorNo);  // <PmtInf><CdtrSchmeId>
        VerifyDrctDbtTxInf(); // <PmtInf><DrctDbtTxInf>
    end;

    local procedure VerifyCdtr()
    var
        CompanyInfo: Record "Company Information";
        XMLNode: DotNet XmlNode;
    begin
        CompanyInfo.Get();
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//PmtInf/Cdtr/Nm', StringConversionMgt.WindowsToASCII(CompanyInfo.Name));
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/Cdtr/PstlAdr', XMLNode);
    end;

    local procedure VerifyCdtrSchmeId(ExpectedCreditorNo: Text)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//PmtInf/CdtrSchmeId/Id/PrvtId/Othr/Id', ExpectedCreditorNo);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//PmtInf/CdtrSchmeId/Id/PrvtId/Othr/SchmeNm/Prtry', 'CHDD');
    end;

    local procedure VerifyDrctDbtTxInf()
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/DrctDbtTxInf/PmtId', XMLNode);
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/DrctDbtTxInf/InstdAmt', XMLNode);
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/DrctDbtTxInf/Dbtr', XMLNode);
        LibraryXPathXMLReader.GetNodeByXPath('//PmtInf/DrctDbtTxInf/RmtInf', XMLNode);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//PmtInf/DrctDbtTxInf/DbtrAcct/Id/IBAN', GetIBANCust());
    end;

    local procedure VerifyPmtTpInf()
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//PmtInf/PmtTpInf/SvcLvl', 'CHDD');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//PmtInf/PmtTpInf/LclInstrm', 'DDCOR1');
    end;
}

