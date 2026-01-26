codeunit 144061 "ERM Test SEPA CT 09 APC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        InvalidLengthTxt: Label 'The lengths are not identical';
        NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';
        LibraryRandom: Codeunit "Library - Random";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        Initialized: Boolean;
        DefaultLineAmount: Decimal;
        EURCode: Code[10];
        BadDocNoTxt: Label 'abc123';
        GenJnlLineEmptyErr: Label 'The Gen. Journal Line table is empty.';
        MessageToRecipientNotIdenticalErr: Label 'The Message To Recipient is not identical.';

    [Test]
    [Scope('OnPrem')]
    procedure MessageToRecipient()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        NodeList: DotNet XmlNodeList;
        RequiredMessageLength: Integer;
    begin
        // [SCENARIO TFS=109389] Message to recipient is stored in the exported file
        Init();
        ClearGenJnlLine(GenJnlLine);
        RequiredMessageLength := 140;

        // [GIVEN] A Payment Journal Line
        // [GIVEN] bal. bank account is using SEPA CT APC export format
        CreateGenJnlLine(GenJnlLine);

        // [GIVEN] Message to recipient is 140 characters long
        GenJnlLine.Validate("Message to Recipient", LibraryUtility.GenerateRandomXMLText(RequiredMessageLength));
        GenJnlLine.Modify(true);
        Assert.AreEqual(RequiredMessageLength, StrLen(GenJnlLine."Message to Recipient"), InvalidLengthTxt);

        // [WHEN] The Payment Journal Line is exported
        GenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");
        GenJnlLine.SetRange("Document Type", GenJnlLine."Document Type");
        ExportGenJnlLines(TempBlob, GenJnlLine);

        // [THEN] The exported file contains a single ustrd tag with all 140 characters
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.GetNodeList('//Ustrd', NodeList);
        Assert.AreEqual(1, NodeList.Count, InvalidLengthTxt);
        Assert.AreEqual(
          CopyStr(StrSubstNo('%1; %2', GenJnlLine.Description, GenJnlLine."Message to Recipient"), 1, 140),
          NodeList.Item(0).InnerText, MessageToRecipientNotIdenticalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO TFS=109389] Export Single Line and verify APC requirements in XML file
        Init();
        ClearGenJnlLine(GenJnlLine);

        // [GIVEN] A Payment Journal Line
        // [GIVEN] bal. bank account is using SEPA CT APC export format
        CreateGenJnlLine(GenJnlLine);

        // [WHEN] The Payment Journal Line is exported
        GenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");
        GenJnlLine.SetRange("Document Type", GenJnlLine."Document Type");
        ExportGenJnlLines(TempBlob, GenJnlLine);

        // [THEN] The exported file does not contain any PstlAddr tags
        // [THEN] The exported file does not contain the InitgPty/Nm tag
        // [THEN] There is only one ustrd tag inside each RmtInf tag
        VerifyApcRequirements(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleLines()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
    begin
        // [SCENARIO TFS=109389] Export Multiple Lines and verify APC requirements in XML file
        Init();
        ClearGenJnlLine(GenJnlLine);

        // [GIVEN] Two Payment Journal Lines
        // [GIVEN] both lines use the same bal. bank account, which is using SEPA CT APC export format
        CreateGenJnlLine(GenJnlLine);
        DocumentNo := GenJnlLine."Document No.";
        CreateGenJnlLine(GenJnlLine);

        // [WHEN] The Payment Journal Line is exported
        GenJnlLine.SetRange("Document No.", DocumentNo, GenJnlLine."Document No.");
        GenJnlLine.SetRange("Document Type", GenJnlLine."Document Type");
        ExportGenJnlLines(TempBlob, GenJnlLine);

        // [THEN] The exported file does not contain any PstlAddr tags
        // [THEN] The exported file does not contain the InitgPty/Nm tag
        // [THEN] There is only one ustrd tag inside each RmtInf tag
        VerifyApcRequirements(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportEmptyPaymentJournal()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO TFS=109389] Verify that errors are thrown all the way to the UI
        Init();
        ClearGenJnlLine(GenJnlLine);

        // [GIVEN] An empty payment Journal
        GenJnlLine.SetRange("Document No.", BadDocNoTxt);
        GenJnlLine.SetRange("Document Type", GenJnlLine."Document Type");
        GenJnlLine.DeleteAll();

        // [GIVEN] Bal. Account has been set up
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", BankAccount."No.");

        // [WHEN] The empty payment Journal is exported using SEPA CT APC export format
        asserterror CODEUNIT.Run(CODEUNIT::"SEPA CT APC-Export File", GenJnlLine);

        // [THEN] The export will fail with error message "The Gen. Journal Line table is empty."
        Assert.ExpectedError(GenJnlLineEmptyErr);
    end;

    local procedure ExportGenJnlLines(var TempBlob: Codeunit "Temp Blob"; var GenJnlLine: Record "Gen. Journal Line")
    var
        SEPA_CT_APCExportFile: Codeunit "SEPA CT APC-Export File";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);
        SEPA_CT_APCExportFile.PostProcessXMLDocument(TempBlob, BankAccount.GetPaymentExportXMLPortID());
    end;

    local procedure Init()
    var
        GLSetup: Record "General Ledger Setup";
        NoSeries: Record "No. Series";
    begin
        if Initialized then
            exit;

        GLSetup.Get();
        EURCode := GLSetup.GetCurrencyCode('EUR');
        DefaultLineAmount := LibraryRandom.RandDec(1000, 2);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateBankAccount(BankAccount);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalTemplate."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount."Bank Account No." := '1234567890';
        VendorBankAccount.IBAN := 'AL47 2121 1009 0000 0002 3569 8741';
        VendorBankAccount.Modify(true);

        NoSeries.FindFirst();
        CreateBankExpSetup();
        BankAccount."Bank Account No." := '1234 12345678';
        BankAccount.IBAN := 'AT61 1904 3002 3457 3201';
        BankAccount."Credit Transfer Msg. Nos." := NoSeries.Code;
        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify(true);
        Initialized := true;
    end;

    local procedure ClearGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        // Clear the General Journal Line
        GenJnlLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine.DeleteAll();
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.Init();
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor, Vendor."No.", 1);

        GenJnlLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJnlLine.Validate("Currency Code", EURCode);
        GenJnlLine.Validate(Amount, DefaultLineAmount);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJnlLine.Validate("Message to Recipient", LibraryUtility.GenerateGUID());
        GenJnlLine.Modify(true);
    end;

    local procedure CreateBankExpSetup()
    begin
        if BankExportImportSetup.Find() then
            BankExportImportSetup.Delete(true);
        BankExportImportSetup.Code := 'SEPA-TEST';
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::Export);
        BankExportImportSetup.Validate("Processing Codeunit ID", CODEUNIT::"SEPA CT APC-Export File");
        BankExportImportSetup.Validate("Processing XMLport ID", XMLPORT::"SEPA CT pain.001.001.09");
        BankExportImportSetup.Validate("Check Export Codeunit", CODEUNIT::"SEPA CT-Check Line");
        BankExportImportSetup.Insert(true);
    end;

    local procedure VerifyApcRequirements(TempBlob: Codeunit "Temp Blob")
    var
        NodeList: DotNet XmlNodeList;
        i: Integer;
    begin
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeAbsence('//PstlAddr');

        LibraryXPathXMLReader.VerifyNodeAbsence('//InitgPty/Nm');

        LibraryXPathXMLReader.GetNodeList('//RmtInf', NodeList);
        for i := 1 to NodeList.Count do
            Assert.AreEqual(1, NodeList.Item(i - 1).ChildNodes.Count, InvalidLengthTxt);
    end;
}

