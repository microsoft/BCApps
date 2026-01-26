codeunit 147590 "Test VAT Statement"
{
    // // [FEATURE] [VAT Statement]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVATStatement: Codeunit "Library VAT Statement";
        LibraryInventory: Codeunit "Library - Inventory";
        FileManagement: Codeunit "File Management";
        Assert: Codeunit Assert;
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;
        KnownFailureUnexpErr: Label 'Unexpected value';
        WrongValueErr: Label 'Wrong value in generated txt file';
        WrongFileEndSymbErr: Label 'Wrong symbol in the end of file';
        TotalAmtTok: Label 'TotalAmt';
        TotalVATAmtTok: Label 'TotalVATAmt';
        TotalBaseTok: Label 'TotalBase';
        TotalECAmtTok: Label 'TotalECAmt';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        AEATTransferenceValueErr: Label 'Value of 80 character should be accepted in AEATTransference File.';
        ECPercentErr: Label 'EC % must be %1 in %2.', Comment = '%1= Field Value, %2= Table Caption.';

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementFiltering()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
    begin
        // [FEATURE] [UI]
        Initialize();

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineDescription(VATStatementLine, VATStatementName);

        // Exercise
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatement.OpenEdit(); // selects the template in the modal handler

        // Verify
        VerifyVATStatementLines(VATStatement, VATStatementName.Name);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTFiltering()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        VATStatement: TestPage "VAT Statement";
        TransferenceFormat: TestPage "Transference Format";
    begin
        // [FEATURE] [UI]
        Initialize();

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineDescription(VATStatementLine, VATStatementName);
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, 2, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::" ", '', '');

        // Exercise
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatement.OpenEdit(); // selects the template in the modal handler
        TransferenceFormat.Trap();
        VATStatement."Design txt file".Invoke();

        // Verify
        VerifyTransferenceTXT(TransferenceFormat, VATStatementName.Name, false);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLFiltering()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        VATStatement: TestPage "VAT Statement";
        XMLTransferenceFormat: TestPage "XML Transference Format";
    begin
        // [FEATURE] [UI]
        Initialize();

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineDescription(VATStatementLine, VATStatementName);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 1,
          LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description), DATABASE::"AEAT Transference Format XML"),
          AEATTransferenceFormatXML."Line Type"::Element, 1, 0, AEATTransferenceFormatXML."Value Type"::" ", '1', '', false);

        // Exercise
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatement.OpenEdit(); // selects the template in the modal handler
        XMLTransferenceFormat.Trap();
        VATStatement."Design XML file".Invoke();

        // Verify
        VerifyTransferenceXML(XMLTransferenceFormat, VATStatementName.Name, false);
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerWithVerify')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTAskCanBeFilled()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        AccountNo: Code[20];
    begin
        // Setup
        Initialize();

        AccountNo := CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, AccountNo, VATStatementLine."Amount Type"::" ", '');
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, 2, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::" ", '', '');
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          2, 2, 2, AEATTransferenceFormat.Type::Ask, AEATTransferenceFormat.Subtype::" ", '', '');

        // Exercise - call report for default request options
        RunTelematicVATDeclaration(VATStatementLine, 0, 0, false);

        // Verify - Will hapen in the TransferenceTxtModalPageHandler
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler,TransferenceXMLModalPageHandlerWithVerify')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLAskCanBeFilled()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        AccountNo: Code[20];
    begin
        // Setup
        Initialize();

        AccountNo := CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, AccountNo, VATStatementLine."Amount Type"::" ", '');
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 1,
          LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description), DATABASE::"AEAT Transference Format XML"),
          AEATTransferenceFormatXML."Line Type"::Element, 1, 0, AEATTransferenceFormatXML."Value Type"::" ", '', '', false); // ask FALSE
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 2,
          LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description), DATABASE::"AEAT Transference Format XML"),
          AEATTransferenceFormatXML."Line Type"::Element, 2, 1, AEATTransferenceFormatXML."Value Type"::" ", '', '', true); // ask TRUE

        // Exercise - call report for default request options
        RunXMLVATDeclaration(VATStatementLine, 0, 0, false);

        // Verify - Will hapen in the TransferenceXMLModalPageHandlerWithVerify
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerWithSetAskField')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTAskIsFilledAndInFile()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        AskFieldValue: Variant;
        AccountNo: Code[20];
        FileName: Text[1024];
        FieldValue: Code[250];
    begin
        // Setup
        Initialize();

        RecRef.GetTable(AEATTransferenceFormat);
        FieldRef := RecRef.Field(AEATTransferenceFormat.FieldNo(Value));
        AccountNo := CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        FieldValue := LibraryUtility.GenerateRandomCode(AEATTransferenceFormat.FieldNo(Value), DATABASE::"AEAT Transference Format");

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, AccountNo, VATStatementLine."Amount Type"::" ", '');
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, FieldRef.Length, AEATTransferenceFormat.Type::Ask, AEATTransferenceFormat.Subtype::" ",
          LibraryUtility.GenerateRandomCode(AEATTransferenceFormat.FieldNo(Value), DATABASE::"AEAT Transference Format"), '');
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          2, FieldRef.Length + 1, StrLen(FieldValue) + 1, AEATTransferenceFormat.Type::Fix, AEATTransferenceFormat.Subtype::" ",
          FieldValue, '');

        // Exercise - call report for default request options
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify
        // Code will be "pass" in the end in TransferenceTXTModalPageHandlerWithSetAskField handler
        // new value set will be passed over
        LibraryVariableStorage.Dequeue(AskFieldValue);
        Assert.AreEqual(Format(PadStr(AskFieldValue, FieldRef.Length, ' ')),
          Format(LibraryTextFileValidation.ReadValueFromLine(FileName, 1, 1, FieldRef.Length)),
          'Value field is not set correctly for modified ask type option.');
        Assert.AreEqual(FieldValue,
          Format(LibraryTextFileValidation.ReadValueFromLine(FileName, 1, FieldRef.Length + 1, StrLen(FieldValue))),
          'Value field is not set correctly for not modified ask type option.');
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTCheckAccTotalingIntegerAndDecimal()
    var
        AEATTransferenceFormat: Record "AEAT Transference Format";
    begin
        TransferenceTXTCheckAccTotaling(AEATTransferenceFormat.Subtype::"Integer and Decimal Part", 2, false);
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTCheckAccTotalingInteger()
    var
        AEATTransferenceFormat: Record "AEAT Transference Format";
    begin
        TransferenceTXTCheckAccTotaling(AEATTransferenceFormat.Subtype::"Integer Part", 2, false);
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTCheckAccTotalingDecimal()
    var
        AEATTransferenceFormat: Record "AEAT Transference Format";
    begin
        TransferenceTXTCheckAccTotaling(AEATTransferenceFormat.Subtype::"Decimal Part", 2, false);
    end;

    local procedure TransferenceTXTCheckAccTotaling(IntegerDecimalPart: Option; Precision: Integer; FillVATBusProdPostGroups: Boolean)
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        FileName: Text[1024];
        Box: Code[5];
        Amount: Decimal;
        BaseAmount: Decimal;
        Length: Integer;
        PadString: Text[1];
    begin
        // Setup
        Initialize();

        Box := '1';
        Length := 10;
        PadString := '0';
        AccountNo := CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        Amount := -LibraryRandom.RandDec(100, 2);
        BaseAmount := Round(Amount / (1 + VATPostingSetup."VAT+EC %" / 100), GLSetup."Amount Rounding Precision");

        CreateVATStatement(VATStatementName);
        if not FillVATBusProdPostGroups then
            Clear(VATPostingSetup);
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, AccountNo, VATStatementLine."Amount Type"::" ", Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, Length, AEATTransferenceFormat.Type::Numerical, IntegerDecimalPart, '', Box);

        // Exercise
        // Create and post to Gen ledger
        // call report for default request options
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Vendor, Vendor."No.",
          AccountNo, -Amount);

        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify - check the account amount printed in file
        Assert.AreEqual(
          PadDecimalToString(
            BaseAmount, Precision, Length, PadString,
            IntegerDecimalPart = AEATTransferenceFormat.Subtype::"Decimal Part",
            IntegerDecimalPart = AEATTransferenceFormat.Subtype::"Integer Part"),
          Format(LibraryTextFileValidation.ReadValueFromLine(FileName, 1, 1, Length)),
          'Amount is not set correctly.');
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLCheckAccTotalingIntegerAndDecimal_Attribute()
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
    begin
        TransferenceXMLCheckAccTotaling(AEATTransferenceFormatXML."Line Type"::Attribute,
          AEATTransferenceFormatXML."Value Type"::"Integer and Decimal Part", 2, false);
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLCheckAccTotalingInteger_Attribute()
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
    begin
        TransferenceXMLCheckAccTotaling(AEATTransferenceFormatXML."Line Type"::Attribute,
          AEATTransferenceFormatXML."Value Type"::"Integer Part", 0, false);
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLCheckAccTotalingDecimal_Element()
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
    begin
        TransferenceXMLCheckAccTotaling(AEATTransferenceFormatXML."Line Type"::Element,
          AEATTransferenceFormatXML."Value Type"::"Decimal Part", 2, false);
    end;

    local procedure TransferenceXMLCheckAccTotaling(NodeType: Option; IntegerDecimalPart: Option; Precision: Integer; FillVATBusProdPostGroups: Boolean)
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        FileName: Text[1024];
        Box: Code[5];
        Amount: Decimal;
        BaseAmount: Decimal;
        BaseAmountText: Text;
        NodeName: Text[250];
        RootNodeName: Text[250];
    begin
        // Setup
        Initialize();

        Box := '1';
        AccountNo := CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        Amount := LibraryRandom.RandDec(100, 2);
        BaseAmount := Round(Amount / (1 + VATPostingSetup."VAT+EC %" / 100), GLSetup."Amount Rounding Precision");
        NodeName := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description),
            DATABASE::"AEAT Transference Format XML");
        RootNodeName := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description),
            DATABASE::"AEAT Transference Format XML");

        CreateVATStatement(VATStatementName);
        if not FillVATBusProdPostGroups then
            Clear(VATPostingSetup);
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, AccountNo, VATStatementLine."Amount Type"::" ", Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 1,
          RootNodeName, AEATTransferenceFormatXML."Line Type"::Element, 1, 0, IntegerDecimalPart, '', '', false);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 2,
          NodeName, NodeType, 2, 1, IntegerDecimalPart, '', Box, false);

        // Exercise
        // Create and post to Gen ledger
        // call report for default request options
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Customer, Customer."No.",
          AccountNo, Amount);

        FileName := CopyStr(RunXMLVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify - check the account amount printed in file
        LibraryXMLRead.Initialize(FileName);
        case IntegerDecimalPart of
            AEATTransferenceFormatXML."Value Type"::"Integer and Decimal Part":
                BaseAmountText := ConvertStr(DelChr(Format(BaseAmount, 0, '<Precision,' +
                        Format(Precision) + '><Integer><Decimal>'), '=', '.'), ',', '.');
            AEATTransferenceFormatXML."Value Type"::"Integer Part":
                BaseAmountText := ConvertStr(DelChr(Format(BaseAmount, 0, '<Integer>'), '=', '.'), ',', '.');
            AEATTransferenceFormatXML."Value Type"::"Decimal Part":
                BaseAmountText := '0.' + DelChr(DelChr(Format(BaseAmount, 0, '<Decimal>'), '=', '.'), '=', ',');
        end;

        if NodeType = AEATTransferenceFormatXML."Line Type"::Attribute then
            asserterror LibraryXMLRead.VerifyAttributeValue(RootNodeName, NodeName, BaseAmountText) // Bug
        else
            LibraryXMLRead.VerifyNodeValueInSubtree(RootNodeName, NodeName, BaseAmountText);
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTCheckRowTotaling()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetupSale: Record "VAT Posting Setup";
        VATPostingSetupPurch: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        Vendor: Record Vendor;
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo1: Code[20];
        AccountNo2: Code[20];
        FileName: Text[1024];
        Box: Code[5];
        Amount: Decimal;
        BaseAmount: Decimal;
        Length: Integer;
        PadString: Text[1];
    begin
        // Setup
        Initialize();

        Box := '1';
        Length := 10;
        PadString := '0';
        AccountNo1 := CreateGLAccountWithVATPostingSetup(VATPostingSetupPurch, GLAccount."Gen. Posting Type"::Purchase);
        AccountNo2 := CreateGLAccountWithVATPostingSetup(VATPostingSetupSale, GLAccount."Gen. Posting Type"::Sale);
        Amount := LibraryRandom.RandDec(100, 2);

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetupPurch, AccountNo1, VATStatementLine."Amount Type"::" ", '');
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '2',
          VATPostingSetupSale, AccountNo2, VATStatementLine."Amount Type"::" ", '');
        CreateVATStatementLineRowTotalling(VATStatementLine, VATStatementName, '3',
          '1|2', Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, Length, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::"Integer and Decimal Part",
          '', Box);

        // Exercise
        // Create and post to Gen ledger
        // call report for default request options
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Vendor, Vendor."No.",
          AccountNo1, -2 * Amount);
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Customer, Customer."No.",
          AccountNo2, Amount);

        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify - check the account amount printed in file
        // Should be base amount as positive is 2 * the negative amount
        // Calculate this way so we don't get into rounding issues
        BaseAmount := Round(2 * Amount / (1 + VATPostingSetupSale."VAT+EC %" / 100), GLSetup."Amount Rounding Precision");
        BaseAmount := BaseAmount - Round(Amount / (1 + VATPostingSetupSale."VAT+EC %" / 100), GLSetup."Amount Rounding Precision");

        Assert.AreEqual(PadDecimalToString(BaseAmount, 2, Length, PadString, false, false),
          Format(LibraryTextFileValidation.ReadValueFromLine(FileName, 1, 1, Length)),
          'Amount is not set correctly.');
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLCheckRowTotaling()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetupSale: Record "VAT Posting Setup";
        VATPostingSetupPurch: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        Vendor: Record Vendor;
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo1: Code[20];
        AccountNo2: Code[20];
        FileName: Text[1024];
        Box: Code[5];
        Amount: Decimal;
        BaseAmount: Decimal;
        RootNodeName: Text[250];
    begin
        // Setup
        Initialize();

        Box := '1';
        AccountNo1 := CreateGLAccountWithVATPostingSetup(VATPostingSetupPurch, GLAccount."Gen. Posting Type"::Purchase);
        AccountNo2 := CreateGLAccountWithVATPostingSetup(VATPostingSetupSale, GLAccount."Gen. Posting Type"::Sale);
        Amount := LibraryRandom.RandDec(100, 2);
        RootNodeName := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description),
            DATABASE::"AEAT Transference Format XML");

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetupPurch, AccountNo1, VATStatementLine."Amount Type"::" ", '');
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '2',
          VATPostingSetupSale, AccountNo2, VATStatementLine."Amount Type"::" ", '');
        CreateVATStatementLineRowTotalling(VATStatementLine, VATStatementName, '3',
          '1|2', Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 1,
          RootNodeName, AEATTransferenceFormatXML."Line Type"::Element, 1, 0,
          AEATTransferenceFormatXML."Value Type"::" ", '', '', false);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 2,
          RootNodeName, AEATTransferenceFormatXML."Line Type"::Element, 2, 1,
          AEATTransferenceFormatXML."Value Type"::"Integer and Decimal Part", '', Box, false);

        // Exercise
        // Create and post to Gen ledger
        // call report for default request options
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Vendor, Vendor."No.",
          AccountNo1, -2 * Amount);
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Customer, Customer."No.",
          AccountNo2, Amount);

        FileName := CopyStr(RunXMLVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify - check the account amount printed in file
        LibraryXMLRead.Initialize(FileName);

        // Verify - check the account amount printed in file
        // Should be base amount as positive is 2 * the negative amount
        // calculate this way so don't get into rounding issues
        BaseAmount := Round(2 * Amount / (1 + VATPostingSetupSale."VAT+EC %" / 100), GLSetup."Amount Rounding Precision");
        BaseAmount := BaseAmount - Round(Amount / (1 + VATPostingSetupSale."VAT+EC %" / 100), GLSetup."Amount Rounding Precision");

        LibraryXMLRead.VerifyNodeValue(RootNodeName,
          ConvertStr(DelChr(Format(BaseAmount, 0, '<Precision,2><Integer><Decimal>'), '=', '.'), ',', '.'));
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTCheckECTotaling()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        FileName: Text[1024];
        Amount: Decimal;
        BaseAmount: Decimal;
        ECAmount: Decimal;
        Length: Integer;
        PadString: Text[1];
        Box: Code[5];
    begin
        // Setup
        Initialize();

        Box := '1';
        Length := 10;
        PadString := '0';

        CreateVATPostingSetup(VATPostingSetup);
        AccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        Amount := 100 + LibraryRandom.RandDec(100, 2);
        BaseAmount := Amount / (1 + VATPostingSetup."VAT+EC %" / 100);
        ECAmount := Round(VATPostingSetup."EC %" * BaseAmount / 100, GLSetup."Amount Rounding Precision");

        // VAT statement
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineECTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, Length, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::"Integer and Decimal Part",
          '', Box);

        // Exercise
        // Create and post to Gen ledger
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Vendor, Vendor."No.",
          AccountNo, -Amount);

        // call report for default request options
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify - check the account amount printed in file
        Assert.AreEqual(PadDecimalToString(ECAmount, 2, Length, PadString, false, false),
          Format(LibraryTextFileValidation.ReadValueFromLine(FileName, 1, 1, Length)),
          'Amount is not set correctly.');
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLCheckECTotaling()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        FileName: Text[1024];
        Box: Code[5];
        Amount: Decimal;
        BaseAmount: Decimal;
        ECAmount: Decimal;
        RootNodeName: Text[250];
    begin
        // Setup
        Initialize();

        Box := '1';

        CreateVATPostingSetup(VATPostingSetup);
        AccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        Amount := 100 + LibraryRandom.RandDec(100, 2);
        BaseAmount := Amount / (1 + VATPostingSetup."VAT+EC %" / 100);
        ECAmount := Round(VATPostingSetup."EC %" * BaseAmount / 100, GLSetup."Amount Rounding Precision");
        RootNodeName := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description),
            DATABASE::"AEAT Transference Format XML");

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineECTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 1,
          RootNodeName, AEATTransferenceFormatXML."Line Type"::Element, 1, 0,
          AEATTransferenceFormatXML."Value Type"::" ", '', '', false);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 2,
          RootNodeName, AEATTransferenceFormatXML."Line Type"::Element, 2, 1,
          AEATTransferenceFormatXML."Value Type"::"Integer and Decimal Part", '', Box, false);

        // Exercise
        // Create and post to Gen ledger
        // call report for default request options
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Vendor, Vendor."No.",
          AccountNo, -Amount);

        FileName := CopyStr(RunXMLVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify - check the account amount printed in file
        LibraryXMLRead.Initialize(FileName);

        // Verify - check the account amount printed in file
        LibraryXMLRead.VerifyNodeValue(RootNodeName,
          ConvertStr(DelChr(Format(ECAmount, 0, '<Precision,2><Integer><Decimal>'), '=', '.'), ',', '.'));
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTCheckVATTotaling()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        FileName: Text[1024];
        Amount: Decimal;
        BaseAmount: Decimal;
        VATAmount: Decimal;
        Length: Integer;
        PadString: Text[1];
        Box: Code[5];
    begin
        // Setup
        Initialize();

        Box := '1';
        Length := 10;
        PadString := '0';

        CreateVATPostingSetup(VATPostingSetup);
        AccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        Amount := 100 + LibraryRandom.RandDec(100, 2);
        BaseAmount := Amount / (1 + VATPostingSetup."VAT+EC %" / 100);
        VATAmount := Round(VATPostingSetup."VAT %" * BaseAmount / 100, GLSetup."Amount Rounding Precision");

        // VAT statement
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, Length, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::"Integer and Decimal Part",
          '', Box);

        // Exercise
        // Create and post to Gen ledger
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Vendor, Vendor."No.",
          AccountNo, -Amount);

        // call report for default request options
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify - check the account amount printed in file
        Assert.AreEqual(PadDecimalToString(VATAmount, 2, Length, PadString, false, false),
          Format(LibraryTextFileValidation.ReadValueFromLine(FileName, 1, 1, Length)),
          'Amount is not set correctly.');
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLCheckVATTotaling()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        FileName: Text[1024];
        Box: Code[5];
        Amount: Decimal;
        BaseAmount: Decimal;
        VATAmount: Decimal;
        RootNodeName: Text[250];
    begin
        // Setup
        Initialize();

        Box := '1';

        CreateVATPostingSetup(VATPostingSetup);
        AccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        Amount := 100 + LibraryRandom.RandDec(100, 2);
        BaseAmount := Amount / (1 + VATPostingSetup."VAT+EC %" / 100);
        VATAmount := Round(VATPostingSetup."VAT %" * BaseAmount / 100, GLSetup."Amount Rounding Precision");
        RootNodeName := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description),
            DATABASE::"AEAT Transference Format XML");

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 1,
          RootNodeName, AEATTransferenceFormatXML."Line Type"::Element, 1, 0,
          AEATTransferenceFormatXML."Value Type"::" ", '', '', false);
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 2,
          RootNodeName, AEATTransferenceFormatXML."Line Type"::Element, 2, 1,
          AEATTransferenceFormatXML."Value Type"::"Integer and Decimal Part", '', Box, false);

        // Exercise
        // Create and post to Gen ledger
        // call report for default request options
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Vendor, Vendor."No.",
          AccountNo, -Amount);

        FileName := CopyStr(RunXMLVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify - check the account amount printed in file
        LibraryXMLRead.Initialize(FileName);

        // Verify - check the account amount printed in file
        LibraryXMLRead.VerifyNodeValue(RootNodeName,
          ConvertStr(DelChr(Format(VATAmount, 0, '<Precision,2><Integer><Decimal>'), '=', '.'), ',', '.'));
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler,TransferenceXMLModalPageHandlerWithSetAskField')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLAskIsFilledAndInFile_Element()
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
    begin
        TransferenceXMLAskIsFilledAndInFile(AEATTransferenceFormatXML."Line Type"::Element);
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler,TransferenceXMLModalPageHandlerWithSetAskField')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLAskIsFilledAndInFile_Attribute()
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
    begin
        TransferenceXMLAskIsFilledAndInFile(AEATTransferenceFormatXML."Line Type"::Attribute);
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTCheckAccTotalingWithoutVATSetup()
    var
        AEATTransferenceFormat: Record "AEAT Transference Format";
    begin
        // Test VAT Statement Line with type Account Totalling exported to Txt when
        // fields VAT Bus. Posting Group/VAT Prod. Posting Group are empty
        TransferenceTXTCheckAccTotaling(AEATTransferenceFormat.Subtype::"Decimal Part", 2, false);
    end;

    [Test]
    [HandlerFunctions('TransferenceXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferenceXMLCheckAccTotalingWithoutVATSetup()
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
    begin
        // Test VAT Statement Line with type Account Totalling exported to XML when
        // fields VAT Bus. Posting Group/VAT Prod. Posting Group are empty
        TransferenceXMLCheckAccTotaling(AEATTransferenceFormatXML."Line Type"::Attribute,
          AEATTransferenceFormatXML."Value Type"::"Integer Part", 0, false);
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTAlphanumericalInFile()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        FileName: Text[1024];
        Description: Text[250];
        Length: Integer;
    begin
        // [SCENARIO 121853] VAT Statement Transference Format with type Alphanumerical is exported to txt file
        Initialize();

        // [GIVEN] VAT Statement with new line in Transference Format with type Alphanumerical
        Length := LibraryRandom.RandIntInRange(2, 10);
        Description := CopyStr(LibraryUtility.GenerateRandomText(Length), 1, 250);

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineDescription(VATStatementLine, VATStatementName);
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, Length, AEATTransferenceFormat.Type::Alphanumerical, AEATTransferenceFormat.Subtype::" ", Description, '');

        // [WHEN] Generate txt file for VAT Statement
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // [THEN] Description from Transfered Format is fully printed in txt file
        Assert.AreEqual(
          Description, Format(LibraryTextFileValidation.ReadLine(FileName, 1)),
          WrongValueErr);
        // [THEN] There is no symbol Null in the End of file
        Assert.AreNotEqual(0, GetLastCharCode(FileName), WrongFileEndSymbErr);
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTFullVATWithTypeAmount()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Length: Integer;
        AccountNo: Code[20];
        Box: Code[5];
        FileName: Text[1024];
    begin
        // [FEATURE] [VAT Statement] [Export]
        // [SCENARIO 121806] Amount generated in VAT declaration when Full VAT is involved
        Initialize();

        // [GIVEN] Post Purchase Invoice with Full VAT Amount = "X"
        AccountNo := CreateGLAccountWithFullVATPostingSetupPurch(VATPostingSetup);
        Amount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGeneralJournalLineToBalAccount(GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          AccountNo, -Amount);

        // [GIVEN] Setup VAT Statement Line with "Amount Type" = Amount and Design Txt File
        Box := '1';
        Length := 10;
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, Box);
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, Length, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::"Integer and Decimal Part",
          '', Box);

        // [WHEN] Run Telematic VAT Declaration
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // [THEN] Invoice's data is exported. "VAT Amount" = "X"
        Assert.AreEqual(
          PadDecimalToString(Amount, 2, Length, '0', false, false),
          Format(LibraryTextFileValidation.ReadLine(FileName, 1)),
          WrongValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATStatementWithFullVATBase()
    var
        VATEntry: Record "VAT Entry";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementLine2: Record "VAT Statement Line";
        VATStatementReport: Report "VAT Statement";
        ColumnAmount: Decimal;
        ColumnBase: Decimal;
    begin
        // [SCENARIO 378865] Check Columns Amount in VAT Statement when Ful VAT is involved and with Amount type = Base and Type = "VAT Entry Totaling"
        Initialize();

        // [GIVEN] Create VAT Entry where VAT Calculation Type = "Full VAT", Amount = 100, Base = 0
        CreateVATEntryWithPostingGroups(VATEntry, LibraryRandom.RandDec(100, 2), 0, VATEntry."VAT Calculation Type"::"Full VAT");
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"One Column Report");
        CreateVATStatementLine(VATStatementLine, VATStatementName, VATEntry, VATStatementLine."Amount Type"::Base);
        CreateVATStatementLine(VATStatementLine2, VATStatementName, VATEntry, VATStatementLine."Amount Type"::Amount);

        // [WHEN] Run VAT Statement report
        VATStatementReport.CalcLineTotal(VATStatementLine, ColumnBase, 0);
        VATStatementReport.CalcLineTotal(VATStatementLine2, ColumnAmount, 0);

        // [THEN] Check that value of field Column Amount = 0 for line with Amount type = Base
        // [THEN] Check that value of field Column Amount = 100 for line with Amount type = Amount
        Assert.AreEqual(VATEntry.Base, ColumnBase, 'ColumnValue incorrect.');
        Assert.AreEqual(VATEntry.Amount, ColumnAmount, 'ColumnValue incorrect.');
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementTwoColumnsTemplateAmount()
    var
        VATEntry: Record "VAT Entry";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382380] Check Columns Amount in VAT Statement when Full VAT is involved, Template Type = Two Columns, Amount type = Amount
        Initialize();

        // [GIVEN] VAT Entry with Amount = 100, Base = 200, "VAT Calculation Type" = "Full VAT"
        CreateVATEntryWithPostingGroups(
          VATEntry, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), VATEntry."VAT Calculation Type"::"Full VAT");

        // [GIVEN] VAT Statement Name with "Template Type" = "Two Columns Report";
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"Two Columns Report");

        // [GIVEN] VAT Statement Line with "Amount Type" = Amount
        // [GIVEN] VAT Bus./Prod. Posting Groups = "VAT Entry".VAT Bus./Prod. Posting Groups
        CreateVATStatementLine(VATStatementLine, VATStatementName, VATEntry, VATStatementLine."Amount Type"::Amount);
        Commit();

        // [WHEN] Run VAT Statement report
        RunVatStatementReport(VATStatementLine, VATStatementName);

        // [THEN] Value of field Total Amount = 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmtTok, VATEntry.Amount);
        // [THEN] Value of field Total VAT Amount = 100
        LibraryReportDataset.AssertElementWithValueExists(TotalVATAmtTok, VATEntry.Amount);
        // [THEN] Value of Total Base = 0
        LibraryReportDataset.AssertElementWithValueExists(TotalBaseTok, 0);
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementTwoColumnsTemplateBase()
    var
        VATEntry: Record "VAT Entry";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 213195] Check Columns Amount in VAT Statement when Full VAT is involved, Template Type = Two Columns, Amount type = Base
        Initialize();

        // [GIVEN] VAT Entry with Amount = 100, Base = 200, "VAT Calculation Type" = "Full VAT"
        CreateVATEntryWithPostingGroups(
          VATEntry, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), VATEntry."VAT Calculation Type"::"Full VAT");

        // [GIVEN] VAT Statement Name with "Template Type" = "Two Columns Report";
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"Two Columns Report");

        // [GIVEN] VAT Statement Line with "Amount Type" = Base
        // [GIVEN] VAT Bus./Prod. Posting Groups = "VAT Entry".VAT Bus./Prod. Posting Groups
        CreateVATStatementLine(VATStatementLine, VATStatementName, VATEntry, VATStatementLine."Amount Type"::Base);
        Commit();

        // [WHEN] Run VAT Statement report
        RunVatStatementReport(VATStatementLine, VATStatementName);

        // [THEN] Value of Total Amount = 0
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmtTok, 0);
        // [THEN] Value of Total VAT Amount = 0
        LibraryReportDataset.AssertElementWithValueExists(TotalVATAmtTok, 0);
        // [THEN] Value of Total Base = 200
        LibraryReportDataset.AssertElementWithValueExists(TotalBaseTok, VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementTwoColumnsTemplateAmountBaseFullVAT()
    var
        VATEntry: Record "VAT Entry";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382380] Check Columns Amount in VAT Statement when Full VAT is involved, Template Type = Two Columns, Amount type = Amount + Base
        Initialize();

        // [GIVEN] VAT Entry with Amount = 100, Base = 200, "VAT Calculation Type" = "Full VAT"
        CreateVATEntryWithPostingGroups(
          VATEntry, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), VATEntry."VAT Calculation Type"::"Full VAT");

        // [GIVEN] VAT Statement Name with "Template Type" = "Two Columns Report";
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"Two Columns Report");

        // [GIVEN] VAT Statement Line with "Amount Type" = Amount + Base
        // [GIVEN] VAT Bus./Prod. Posting Groups = "VAT Entry".VAT Bus./Prod. Posting Groups
        CreateVATStatementLine(VATStatementLine, VATStatementName, VATEntry, VATStatementLine."Amount Type"::"Amount+Base");
        Commit();

        // [WHEN] Run VAT Statement report
        RunVatStatementReport(VATStatementLine, VATStatementName);

        // [THEN] Value of Total Amount = 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmtTok, VATEntry.Amount);
        // [THEN] Value of Total VAT Amount = 100
        LibraryReportDataset.AssertElementWithValueExists(TotalVATAmtTok, VATEntry.Amount);
        // [THEN] Value of Total Base = 0
        LibraryReportDataset.AssertElementWithValueExists(TotalBaseTok, 0);
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementTwoColumnsTemplateAmountBase()
    var
        VATEntry: Record "VAT Entry";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382380] Check Columns Amount in VAT Statement when Full VAT doesn't involved, Template Type = Two Columns, Amount type = Amount + Base
        Initialize();

        // [GIVEN] VAT Entry with Amount = 100, Base = 200, "VAT Calculation Type" = "Normal VAT"
        CreateVATEntryWithPostingGroups(
          VATEntry, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), VATEntry."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] VAT Statement Name with "Template Type" = "Two Columns Report";
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"Two Columns Report");

        // [GIVEN] VAT Statement Line with "Amount Type" = Amount + Base
        // [GIVEN] VAT Bus./Prod. Posting Groups = "VAT Entry".VAT Bus./Prod. Posting Groups
        CreateVATStatementLine(VATStatementLine, VATStatementName, VATEntry, VATStatementLine."Amount Type"::"Amount+Base");
        Commit();

        // [WHEN] Run VAT Statement report
        RunVatStatementReport(VATStatementLine, VATStatementName);

        // [THEN] Value of Total Amount = 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmtTok, VATEntry.Amount);
        // [THEN] Value of Total VAT Amount = 100
        LibraryReportDataset.AssertElementWithValueExists(TotalVATAmtTok, VATEntry.Amount);
        // [THEN] Value of Total Base = 100
        LibraryReportDataset.AssertElementWithValueExists(TotalBaseTok, VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTelematicFileGenerationForTransFormatWithLargeLength()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        GeneratedTextFromFile: BigText;
        FileName: Text[1024];
    begin
        // [FEATURE] [Report]
        // [SCENARIO 259535] Telematic VAT Declaration Report generates file for AEAT Transference Format with Length more than 5000.
        Initialize();

        // [GIVEN] VAT Statement with Line.
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineDescription(VATStatementLine, VATStatementName);

        // [GIVEN] AEAT Transreference Format for VAT Statement with Length > 5000.
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, LibraryRandom.RandIntInRange(5000, 100000), AEATTransferenceFormat.Type::Ask, AEATTransferenceFormat.Subtype::" ", '', '');

        // [WHEN] Run Telematic VAT Declaration Report.
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // [THEN] Generated file has length = AEAT Transreference Format Length.
        LibraryTextFileValidation.ReadTextFile(FileName, GeneratedTextFromFile);
        Assert.AreEqual(AEATTransferenceFormat.Length, GeneratedTextFromFile.Length, 'Amount is not set correctly.');
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementPreviewNoTaxablePurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        NoTaxableEntries: TestPage "No Taxable Entries";
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO 399436] Drilldown purchase No Taxable entries from VAT Statement Preview
        Initialize();

        // [GIVEN] Two purchase invoices with No Taxable VAT and amount of 100 and 200
        CreateVATPostingSetupNoTaxable(VATPostingSetup);
        CreatePostPurchInvoice(PurchaseHeader1, VATPostingSetup);
        CreatePostPurchInvoice(PurchaseHeader2, VATPostingSetup);

        // [GIVEN] VAT Statement Lines for No Taxable VAT Posting Setup with Amount type = Amount and Base
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '2', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, '');

        // [GIVEN] VAT Statement Preview shows 0 and 300 in VAT Statement Lines lines respectively
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatementPreview.Trap();
        NoTaxableEntries.Trap();
        VATStatement.OpenEdit();
        VATStatement."P&review".Invoke();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(0);
        VATStatementPreview.VATStatementLineSubForm.Next();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(PurchaseHeader1.Amount + PurchaseHeader2.Amount);

        // [WHEN] Drill Down on Column Value of 'Base' line
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.DrillDown();

        // [THEN] No Taxable Entries opened with two lines according to posted invoices of amount = 100 and 200
        NoTaxableEntries.First();
        NoTaxableEntries.Base.AssertEquals(PurchaseHeader1.Amount);
        NoTaxableEntries.Next();
        NoTaxableEntries.Base.AssertEquals(PurchaseHeader2.Amount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementPreviewNoTaxableSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        NoTaxableEntries: TestPage "No Taxable Entries";
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 399436] Drilldown sales No Taxable entries from VAT Statement Preview
        Initialize();

        // [GIVEN] Two sales invoices with No Taxable VAT and amount of 100 and 200
        CreateVATPostingSetupNoTaxable(VATPostingSetup);
        CreatePostSalesInvoice(SalesHeader1, VATPostingSetup);
        CreatePostSalesInvoice(SalesHeader2, VATPostingSetup);

        // [GIVEN] VAT Statement Lines for No Taxable VAT Posting Setup with Amount type = Amount and Base
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '2', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, '');

        // [GIVEN] VAT Statement Preview shows 0 and -300 in VAT Statement Lines lines respectively
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatementPreview.Trap();
        NoTaxableEntries.Trap();
        VATStatement.OpenEdit();
        VATStatement."P&review".Invoke();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(0);
        VATStatementPreview.VATStatementLineSubForm.Next();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(-SalesHeader1.Amount - SalesHeader2.Amount);

        // [WHEN] Drill Down on Column Value of 'Base' line
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.DrillDown();

        // [THEN] No Taxable Entries opened with two lines according to posted invoices of amount = -100 and -200
        NoTaxableEntries.First();
        NoTaxableEntries.Base.AssertEquals(-SalesHeader1.Amount);
        NoTaxableEntries.Next();
        NoTaxableEntries.Base.AssertEquals(-SalesHeader2.Amount);
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementTwoColumnsNoTaxable()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupNormal: Record "VAT Posting Setup";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 399436] VAT Statement report for No Taxable VAT with Template Type = Two Columns
        Initialize();

        // [GIVEN] Purchase Invoice of Normal VAT with VAT Amount = 50
        CreateVATPostingSetup(VATPostingSetupNormal);
        VATPostingSetupNormal.Validate("EC %", 0);
        VATPostingSetupNormal.Modify(true);
        CreatePostPurchInvoice(PurchaseHeader, VATPostingSetupNormal);

        // [GIVEN] Two sales invoices with No Taxable VAT of amounts 100 and 200
        CreateVATPostingSetupNoTaxable(VATPostingSetup);
        CreatePostSalesInvoice(SalesHeader1, VATPostingSetup);
        CreatePostSalesInvoice(SalesHeader2, VATPostingSetup);
        // [GIVEN] Two purchase invoices with No Taxable VAT of amounts 300 and 400
        CreatePostPurchInvoice(PurchaseHeader1, VATPostingSetup);
        CreatePostPurchInvoice(PurchaseHeader2, VATPostingSetup);

        // [GIVEN] VAT Statement Name with "Template Type" = "Two Columns Report"
        // [GIVEN] VAT Statement Lines for purchase with normal VAT with "Amount Type" = Amount
        // [GIVEN] Two VAT Statement Lines for sales with "Amount Type" = Amount, Base
        // [GIVEN] Two VAT Statement Lines for purchases with "Amount Type" = Amount, Base
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"Two Columns Report");
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '0', VATPostingSetupNormal,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '2', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '3', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '4', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, '');
        Commit();

        // [WHEN] Run VAT Statement report
        RunVatStatementReport(VATStatementLine, VATStatementName);

        // [THEN] TotalAmount from VAT Statement Line for purchase with normal VAT = 50
        // [THEN] VAT Statement Lines for sales with No Taxable VAT has 'TotalAmount' = 0, 'TotalBase' type = 300
        // [THEN] VAT Statement Lines for purchase with No Taxable VAT has 'TotalAmount' = 0, 'TotalBase' type = 700
        LibraryReportDataset.LoadDataSetFile();
        VerifyVATStatementLineForRow(PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount, 0, '0');
        VerifyVATStatementLineForRow(0, 0, '1');
        VerifyVATStatementLineForRow(0, -SalesHeader1.Amount - SalesHeader2.Amount, '2');
        VerifyVATStatementLineForRow(0, 0, '3');
        VerifyVATStatementLineForRow(0, PurchaseHeader1.Amount + PurchaseHeader2.Amount, '4');
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandlerDefault')]
    [Scope('OnPrem')]
    procedure TestVATStatementTwoColumnsTemplateVATAmountECAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        Amount: Decimal;
        BaseAmount: Decimal;
        ECAmount: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 415480] Check Columns VAT Amount and EC Amount in VAT Statement when Normal VAT is involved, Template Type = Two Columns, Amount type = Amount
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT %" = 16, "EC %" = 5
        CreateVATPostingSetup(VATPostingSetup);
        // [GIVEN] Prepare invoice amount with VAT Amount = 160 and EC Amount = 50
        BaseAmount := 1000 * LibraryRandom.RandInt(5);
        Amount := Round(VATPostingSetup."VAT %" * BaseAmount / 100, GLSetup."Amount Rounding Precision");
        ECAmount := Round(VATPostingSetup."EC %" * BaseAmount / 100, GLSetup."Amount Rounding Precision");

        // [GIVEN] VAT statement with Two Columns Report
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"Two Columns Report");
        // [GIVEN] VAT Statement line with Type = "EC Entry Totaling", "Amount Type" = Amount
        CreateVATStatementLineECTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, '');

        // [GIVEN] Create and post purchase invoice for full amount 1210 (1000 + 160 + 50)
        CreateAndPostGeneralJournalLineToBalAccount(
            "Gen. Journal Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(),
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase),
            -(Amount + BaseAmount + ECAmount));
        Commit();

        // [WHEN] Run VAT Statement report
        RunVatStatementReportAndLoad(VATStatementLine, VATStatementName);

        // [THEN] Value of Total VAT Amount = 160
        LibraryReportDataset.AssertElementWithValueExists(TotalVATAmtTok, Amount);
        // [THEN] Value of Total EC Amount = 50
        LibraryReportDataset.AssertElementWithValueExists(TotalECAmtTok, ECAmount);
        // [THEN] Value of Total Base = 0
        LibraryReportDataset.AssertElementWithValueExists(TotalBaseTok, 0);
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandlerDefault')]
    [Scope('OnPrem')]
    procedure TestVATStatementVATAmountECAmountRounding()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetupNormal: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        VATAmount: Decimal;
        ECAmount: Decimal;
    begin
        // [SCENARIO 462144] Totals in VAT Statement are not correctly calculated due to rounding if there is EC amount in Spanish Version
        Initialize();

        // [GIVEN] Create VAT Posting Setup with "VAT %" and "EC %"
        CreateVATPostingSetup(VATPostingSetupNormal);
        VATPostingSetupNormal.Validate("VAT %", LibraryRandom.RandDecInRange(10, 20, 2));
        VATPostingSetupNormal.Validate("EC %", LibraryRandom.RandDecInDecimalRange(5, 15, 2));
        VATPostingSetupNormal.Modify(true);

        // [GIVEN] Create Sales invoice with VAT and save VAT Amount and EC Amount in variable
        CreatePostSalesInvoice(SalesHeader, VATPostingSetupNormal);
        GLSetup.Get();
        VATAmount := Round(SalesHeader.Amount * VATPostingSetupNormal."VAT %" / 100, GlSetup."Amount Rounding Precision");
        ECAmount := Round(SalesHeader.Amount * VATPostingSetupNormal."EC %" / 100, GlSetup."Amount Rounding Precision");

        // [GIVEN] Create VAT Statement Line for Sales with "Amount Type" = Amount
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"Two Columns Report");
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '0', VATPostingSetupNormal,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, '');
        Commit();

        // [WHEN] Run VAT Statement report
        RunVatStatementReportAndLoad(VATStatementLine, VATStatementName);

        // [VERIFY] Verify the VAT Amount and EC Amount
        LibraryReportDataset.AssertElementWithValueExists(TotalVATAmtTok, -VATAmount);
        LibraryReportDataset.AssertElementWithValueExists(TotalECAmtTok, -ECAmount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementPreviewNoTaxableClosed()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        NoTaxableEntry: Record "No Taxable Entry";
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        NoTaxableEntries: TestPage "No Taxable Entries";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [No Taxable] [UI] [Sales]
        // [SCENARIO 437076] Drilldown closed No Taxable entries from VAT Statement Preview
        Initialize();

        // [GIVEN] Two sales invoices with No Taxable VAT and amount of 100 (closed) and 200 (open)
        CreateVATPostingSetupNoTaxable(VATPostingSetup);
        DocumentNo := CreatePostSalesInvoice(SalesHeader1, VATPostingSetup);
        CreatePostSalesInvoice(SalesHeader2, VATPostingSetup);
        NoTaxableEntry.SetRange("Document No.", DocumentNo);
        NoTaxableEntry.FindFirst();
        NoTaxableEntry.Closed := true;
        NoTaxableEntry.Modify();

        // [GIVEN] VAT Statement Line for No Taxable VAT Posting Setup with Amount type = Base
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, '');

        // [GIVEN] VAT Statement Preview shows -100 in VAT Statement Line for Include VAT Entries: Closed
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatementPreview.Trap();
        NoTaxableEntries.Trap();
        VATStatement.OpenEdit();
        VATStatement."P&review".Invoke();
        VATStatementPreview.Selection.SetValue(1); // Closed
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(-SalesHeader1.Amount);

        // [WHEN] Drill Down on Column Value of 'Base' line
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.DrillDown();

        // [THEN] No Taxable Entries show line for first invoice of amount = -100
        NoTaxableEntries.Base.AssertEquals(-SalesHeader1.Amount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementPreviewNoTaxableOpenedAndClosed()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        NoTaxableEntry: Record "No Taxable Entry";
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        NoTaxableEntries: TestPage "No Taxable Entries";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [No Taxable] [UI] [Sales]
        // [SCENARIO 437076] Drilldown opened and closed No Taxable entries from VAT Statement Preview
        Initialize();

        // [GIVEN] Two sales invoices with No Taxable VAT and amount of 100 (closed) and 200 (open)
        CreateVATPostingSetupNoTaxable(VATPostingSetup);
        DocumentNo := CreatePostSalesInvoice(SalesHeader1, VATPostingSetup);
        CreatePostSalesInvoice(SalesHeader2, VATPostingSetup);
        NoTaxableEntry.SetRange("Document No.", DocumentNo);
        NoTaxableEntry.FindFirst();
        NoTaxableEntry.Closed := true;
        NoTaxableEntry.Modify();

        // [GIVEN] VAT Statement Line for No Taxable VAT Posting Setup with Amount type = Base
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, '');

        // [GIVEN] VAT Statement Preview shows -300 in VAT Statement Line for Include VAT Entries: Closed
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatementPreview.Trap();
        NoTaxableEntries.Trap();
        VATStatement.OpenEdit();
        VATStatement."P&review".Invoke();
        VATStatementPreview.Selection.SetValue(2); // Opened and Closed
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(-SalesHeader1.Amount - SalesHeader2.Amount);

        // [WHEN] Drill Down on Column Value of 'Base' line
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.DrillDown();

        // [THEN] No Taxable Entries show line for first invoice of amount = -100 and for second invoice = -200
        NoTaxableEntries.Base.AssertEquals(-SalesHeader1.Amount);
        NoTaxableEntries.Next();
        NoTaxableEntries.Base.AssertEquals(-SalesHeader2.Amount);
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandlerDefault')]
    [Scope('OnPrem')]
    procedure TestVATStatementReportNoTaxableOpened()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        NoTaxableEntry: Record "No Taxable Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [No Taxable]
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 437076] VAT Statement report for closed No Taxable entries
        Initialize();

        // [GIVEN] Two sales invoices with No Taxable VAT and amount of 100 (closed) and 200 (open)
        CreateVATPostingSetupNoTaxable(VATPostingSetup);
        DocumentNo := CreatePostSalesInvoice(SalesHeader1, VATPostingSetup);
        CreatePostSalesInvoice(SalesHeader2, VATPostingSetup);
        NoTaxableEntry.SetRange("Document No.", DocumentNo);
        NoTaxableEntry.FindFirst();
        NoTaxableEntry.Closed := true;
        NoTaxableEntry.Modify();

        // [GIVEN] VAT Statement Line for No Taxable VAT Posting Setup with Amount type = Base
        CreateVATStatementNameWithTemplateType(VATStatementName, VATStatementName."Template Type"::"Two Columns Report");
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '2', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, '');
        Commit();

        // [WHEN] Run VAT Statement report with open entries
        RunVatStatementReportAndLoad(VATStatementLine, VATStatementName);

        // [THEN] VAT Statement Line is exported with Base = 200 for the second document
        LibraryReportDataset.AssertElementWithValueExists(TotalAmtTok, 0);
        LibraryReportDataset.AssertElementWithValueExists(TotalBaseTok, -SalesHeader2.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAndPostVATSettlementNoTaxable()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        // [FEATURE] [No Taxable] [Sales] [Purchase]
        // [SCENARIO 437076] Stan can close the No Taxable Entries with the "Calc. and Post VAT Settlement" batch job
        Initialize();

        // [GIVEN] Two sales invoices with different No Taxable VAT "NT1" and "NT2" of amounts 100 and 200
        CreateVATPostingSetupNoTaxable(VATPostingSetup1);
        CreateVATPostingSetupNoTaxable(VATPostingSetup2);
        CreatePostSalesInvoice(SalesHeader1, VATPostingSetup1);
        CreatePostSalesInvoice(SalesHeader2, VATPostingSetup2);
        // [GIVEN] Two purchase invoices with different No Taxable VAT "NT1" and "NT2" of amounts 300 and 400
        CreatePostPurchInvoice(PurchaseHeader1, VATPostingSetup1);
        CreatePostPurchInvoice(PurchaseHeader2, VATPostingSetup2);

        // [WHEN] Run Calc and Post VAT Settlement report for VAT Posting Group "NT1" with Post = Yes
        VATPostingSetup1.SetRecFilter();
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup1);
        CalcAndPostVATSettlement.InitializeRequest(
          WorkDate(), WorkDate(), WorkDate(), LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), false, true);
        CalcAndPostVATSettlement.UseRequestPage(false);
        CalcAndPostVATSettlement.SaveAsXml(FileManagement.ServerTempFileName('xml'));

        // [THEN] No Taxable Entries are closed for VAT Posting Group "NT1"
        VerifyNoTaxableCount(VATPostingSetup1."VAT Bus. Posting Group", true, 2);
        // [THEN] No Taxable Entries are open for VAT Posting Group "NT2"
        VerifyNoTaxableCount(VATPostingSetup2."VAT Bus. Posting Group", false, 2);
    end;

    [Test]
    [HandlerFunctions('CalcPostVATSettlemetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestCalcAndPostVATSettlementNoTaxableDataset()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        SalesDoc1: Code[20];
        SalesDoc2: Code[20];
        PurchDoc1: Code[20];
        PurchDoc2: Code[20];
        RequestPageXML: Text;
    begin
        // [FEATURE] [No Taxable] [Report]
        // [SCENARIO 437076] "Calc. and Post VAT Settlement" report prints the No Taxable Entries
        Initialize();

        // [GIVEN] Two sales invoices with different No Taxable VAT "NT1" and "NT2" of amounts 100 and 200
        CreateVATPostingSetupNoTaxable(VATPostingSetup1);
        CreateVATPostingSetupNoTaxable(VATPostingSetup2);
        SalesDoc1 := CreatePostSalesInvoice(SalesHeader1, VATPostingSetup1);
        SalesDoc2 := CreatePostSalesInvoice(SalesHeader2, VATPostingSetup2);
        // [GIVEN] Two purchase invoices with different No Taxable VAT "NT1" and "NT2" of amounts 300 and 400
        PurchDoc1 := CreatePostPurchInvoice(PurchaseHeader1, VATPostingSetup1);
        PurchDoc2 := CreatePostPurchInvoice(PurchaseHeader2, VATPostingSetup2);

        // [WHEN] Run Calc and Post VAT Settlement report for VAT Posting Group "NT1" with "Print VAT Entries" = true
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNo());
        Commit();
        VATPostingSetup1.SetRecFilter();
        RequestPageXML := Report.RunRequestPage(Report::"Calc. and Post VAT Settlement");
        LibraryReportDataset.RunReportAndLoad(Report::"Calc. and Post VAT Settlement", VATPostingSetup1, RequestPageXML);

        // [THEN] No Taxable VAT Entries are exported for documents with No Taxable VAT "NT1" with amounts 100 and 300
        LibraryReportDataset.AssertElementWithValueNotExist('DocumentNo_NoTaxableEntry', SalesDoc2);
        LibraryReportDataset.AssertElementWithValueNotExist('DocumentNo_NoTaxableEntry', PurchDoc2);
        LibraryReportDataset.AssertElementWithValueExists('DocumentNo_NoTaxableEntry', SalesDoc1);
        LibraryReportDataset.AssertElementWithValueExists('DocumentNo_NoTaxableEntry', PurchDoc1);
        LibraryReportDataset.AssertElementWithValueExists('Base_NoTaxableEntry', -SalesHeader1.Amount);
        LibraryReportDataset.AssertElementWithValueExists('Base_NoTaxableEntry', PurchaseHeader1.Amount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementPreviewNoTaxablePurchaseFCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        NoTaxableEntries: TestPage "No Taxable Entries";
        ExchangeRateAmount: Decimal;
    begin
        // [FEATURE] Purchase]
        // [SCENARIO 488609] FCY Purchase No Taxable entry shown in foreign currency is shown in LCY in the VAT Statement Preview

        Initialize();

        // [GIVEN] The FCY purchase invoice with No Taxable VAT, Amount = 100 and Amount (LCY) = 50
        CreateVATPostingSetupNoTaxable(VATPostingSetup);
        ExchangeRateAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        CreatePostPurchInvoiceWithCurrency(
          PurchaseHeader, VATPostingSetup,
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount));

        // [GIVEN] VAT Statement Lines for No Taxable VAT Posting Setup with Amount type = Amount and Base
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '2', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, '');

        // [THEN] VAT Statement Preview shows 0 and 50 in VAT Statement Lines lines respectively
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatementPreview.Trap();
        NoTaxableEntries.Trap();
        VATStatement.OpenEdit();
        VATStatement."P&review".Invoke();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(0);
        VATStatementPreview.VATStatementLineSubForm.Next();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(PurchaseHeader.Amount / ExchangeRateAmount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATStatementPreviewNoTaxableSalesFCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        NoTaxableEntries: TestPage "No Taxable Entries";
        ExchangeRateAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 488609] FCY Sales No Taxable entry shown in foreign currency is shown in LCY in the VAT Statement Preview
        Initialize();

        // [GIVEN] The FCY sales invoice with No Taxable VAT, Amount = 100 and Amount (LCY) = 50
        CreateVATPostingSetupNoTaxable(VATPostingSetup);
        ExchangeRateAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        CreatePostSalesInvoiceWithCurrency(
          SalesHeader, VATPostingSetup,
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount));

        // [GIVEN] VAT Statement Lines for No Taxable VAT Posting Setup with Amount type = Amount and Base
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Amount, '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '2', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Sale, VATStatementLine."Amount Type"::Base, '');

        // [THEN] VAT Statement Preview shows 0 and -50 in VAT Statement Lines lines respectively
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatementPreview.Trap();
        NoTaxableEntries.Trap();
        VATStatement.OpenEdit();
        VATStatement."P&review".Invoke();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(0);
        VATStatementPreview.VATStatementLineSubForm.Next();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(-SalesHeader.Amount / ExchangeRateAmount);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure NonDeductibleVATBaseAndAmountShouldShowCorrectFigures()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATSetup: Record "VAT Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VatEntry: Record "VAT Entry";
        LibraryInventory: Codeunit "Library - Inventory";
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        NoTaxableEntries: TestPage "No Taxable Entries";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 533499] VAT Declaration does not show the right figures for "Non-Deductible Base" and "Non-Deductible Amount" Amount Types in the Spanish version.
        Initialize();

        // [GIVEN] Validate Enable Non-Deductible VAT in VAT Setup.
        VATSetup.Get();
        VATSetup."Enable Non-Deductible VAT" := true;
        VATSetup.Modify();

        // [GIVEN] Create VAT Posting Setup with Non-Deductible VAT.
        CreateVATPostingSetupWithNonDeductibleVAT(VATPostingSetup);

        // [GIVEN] Generate and save Vendor in a Variable.
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create an Item and Validate VAT Prod. Posting Group.
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Create a Purchase Header and Validate Vendor Invoice No.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryRandom.RandText(2));
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a Purchase Line and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine.Modify(true);

        // [THEN] Post Purchase Invoice.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [WHEN] VAT Statement Lines for No Taxable VAT Posting Setup with Amount type = Amount and Base
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '1', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::"Non-Deductible Base", '');
        CreateVATStatementLineVATTotalling(
          VATStatementLine, VATStatementName, '2', VATPostingSetup,
          VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::"Non-Deductible Amount", '');

        VatEntry.SetRange(Type, VatEntry.Type::Purchase);
        VatEntry.SetRange("Document No.", PostedDocNo);
        VatEntry.FindFirst();

        // [THEN] Verify: VAT Statement Preview shows correct Non-Deducatible VAT Base and Amount in VAT Statement Lines lines respectively
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatementPreview.Trap();
        NoTaxableEntries.Trap();
        VATStatement.OpenEdit();
        VATStatement."P&review".Invoke();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(VatEntry."Non-Deductible VAT Base");
        VATStatementPreview.VATStatementLineSubForm.Next();
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(VatEntry."Non-Deductible VAT Amount");
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure TestTransferenceTXTCheckVATTotalingForNoTaxableEntries()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        SalesHeader: array[3] of Record "Sales Header";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        AEATTransferenceFormat: array[3] of Record "AEAT Transference Format";
        VATAmount: array[3] of Decimal;
        Box: array[3] of Code[5];
        FileName: Text[1024];
        PadString: Text[1];
        Length: Integer;
    begin
        // [SCENARIO 537453] Amount of No Taxable Entry table are not taken into account in the Telematic VAT Declaration in the Spanish version.
        Initialize();

        // [GIVEN] Generate Random Boxes value.
        Box[1] := Format(LibraryRandom.RandInt(1));
        Box[2] := Format(LibraryRandom.RandIntInRange(2, 2));
        Box[3] := Format(LibraryRandom.RandIntInRange(3, 3));

        // [GIVEN] Generate Random Length and padstring.
        Length := LibraryRandom.RandIntInRange(15, 15);
        PadString := Format(LibraryRandom.RandIntInRange(0, 0));

        // [GIVEN] Create VAT Posting Setup.
        CreateVATPostingSetup(VATPostingSetup[1]);
        VATPostingSetup[1].Validate("EC %", 0);
        VATPostingSetup[1].Modify(true);

        // [GIVEN] Create multiple VAT Posting Setup with VAT Calculation Type = "No Taxable".
        CreateVATPostingSetupNoTaxable(VATPostingSetup[2]);
        CreateVATPostingSetupNoTaxable(VATPostingSetup[3]);

        // [GIVEN] Create and Post Sales Invoice with VAT and No Taxable VAT.
        VATAmount[1] := GetVATAmount(CreatePostSalesInvoice(SalesHeader[1], VATPostingSetup[1]));
        VATAmount[2] := GetTaxableAmount(CreatePostSalesInvoice(SalesHeader[2], VATPostingSetup[2]));
        VATAmount[3] := GetTaxableAmount(CreatePostSalesInvoice(SalesHeader[3], VATPostingSetup[3]));

        // [GIVEN] Create a VAT statement.
        CreateVATStatement(VATStatementName);

        // [GIVEN] Create VAT Statement Line with VAT Posting Setup for "Box 1".
        CreateVATStatementLineVATTotalling(
          VATStatementLine,
          VATStatementName,
          Format(LibraryRandom.RandIntInRange(1, 1)),
          VATPostingSetup[1],
          VATStatementLine."Gen. Posting Type"::Sale,
          VATStatementLine."Amount Type"::Amount,
          Box[1]);

        // [GIVEN] Create VAT Statement Line with No taxable VAT Posting Setup for "Box 2".
        CreateVATStatementLineVATTotalling(
          VATStatementLine,
          VATStatementName,
          Format(LibraryRandom.RandIntInRange(2, 2)),
          VATPostingSetup[2],
          VATStatementLine."Gen. Posting Type"::Sale,
          VATStatementLine."Amount Type"::Base,
          Box[2]);

        // [GIVEN] Create VAT Statement Line with No taxable VAT Posting Setup for "Box 3".
        CreateVATStatementLineVATTotalling(
          VATStatementLine,
          VATStatementName,
          Format(LibraryRandom.RandIntInRange(3, 3)),
          VATPostingSetup[3],
          VATStatementLine."Gen. Posting Type"::Sale,
          VATStatementLine."Amount Type"::Base,
          Box[3]);

        // [GIVEN] Create Transreference Format Line for "Box 1".
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(
          AEATTransferenceFormat[1],
          VATStatementName.Name,
          LibraryRandom.RandIntInRange(1, 1),
          LibraryRandom.RandIntInRange(1, 1),
          Length,
          AEATTransferenceFormat[1].Type::Numerical,
          AEATTransferenceFormat[1].Subtype::"Integer and Decimal Part",
          '',
          Box[1]);

        // [GIVEN] Create Transreference Format Line for "Box 2".
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(
          AEATTransferenceFormat[2],
          VATStatementName.Name,
          LibraryRandom.RandIntInRange(2, 2),
          LibraryRandom.RandIntInRange(20, 20),
          Length,
          AEATTransferenceFormat[2].Type::Numerical,
          AEATTransferenceFormat[2].Subtype::"Integer and Decimal Part",
          '',
          Box[2]);

        // [GIVEN] Create Transreference Format Line for "Box 3".
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(
          AEATTransferenceFormat[3],
          VATStatementName.Name,
          LibraryRandom.RandIntInRange(3, 3),
          LibraryRandom.RandIntInRange(40, 40),
          Length,
          AEATTransferenceFormat[3].Type::Numerical,
          AEATTransferenceFormat[3].Subtype::"Integer and Decimal Part",
          '',
          Box[3]);

        // [WHEN] Run Telematic VAT Declaration Report. 
        VATStatementLine.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.SetRange("Statement Name", VATStatementName.Name);
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 1, false), 1, 1024);

        // [VERIFY] Verify amount of No Taxable Entries are taken into account in the Telematic VAT Declaration.
        Assert.AreEqual(
          PadDecimalToString(VATAmount[1], LibraryRandom.RandIntInRange(2, 2), Length, PadString, false, false),
          Format(
            LibraryTextFileValidation.ReadValueFromLine(
              FileName,
              AEATTransferenceFormat[1]."No.",
              AEATTransferenceFormat[1].Position,
              Length)),
          StrSubstNo(
                ValueMustBeEqualErr,
                AEATTransferenceFormat[1].FieldCaption(value),
                PadDecimalToString(VATAmount[1], LibraryRandom.RandIntInRange(2, 2), Length, PadString, false, false),
                AEATTransferenceFormat[1].TableCaption()));

        Assert.AreEqual(
          PadDecimalToString(VATAmount[2], LibraryRandom.RandIntInRange(2, 2), Length, PadString, false, false),
          Format(
            LibraryTextFileValidation.ReadValueFromLine(
              FileName,
              AEATTransferenceFormat[1]."No.",
              AEATTransferenceFormat[2].Position,
              Length)),
          StrSubstNo(
                ValueMustBeEqualErr,
                AEATTransferenceFormat[2].FieldCaption(value),
                PadDecimalToString(VATAmount[2], LibraryRandom.RandIntInRange(2, 2), Length, PadString, false, false),
                AEATTransferenceFormat[2].TableCaption()));

        Assert.AreEqual(
          PadDecimalToString(VATAmount[3], LibraryRandom.RandIntInRange(2, 2), Length, PadString, false, false),
          Format(
            LibraryTextFileValidation.ReadValueFromLine(
              FileName,
              AEATTransferenceFormat[1]."No.",
              AEATTransferenceFormat[3].Position, Length)),
          StrSubstNo(
                ValueMustBeEqualErr,
                AEATTransferenceFormat[3].FieldCaption(value),
                PadDecimalToString(VATAmount[3], LibraryRandom.RandIntInRange(2, 2), Length, PadString, false, false),
                AEATTransferenceFormat[3].TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleVATBaseShouldShowCorrectFigureAfterPostingVATSettlement()
    var
        Item: Record Item;
        VATSetup: Record "VAT Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VatEntry: Record "VAT Entry";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        LibraryInventory: Codeunit "Library - Inventory";
        VendorNo: Code[20];
        NewDocNo: Code[20];
        NonDeductibleVATBase: Decimal;
    begin
        // [SCENARIO 539438] The Non-Deductible VAT Base field on the Vat Entries is showing an incorrect amount after Calc. and Post VAT Settlement in the Spanish version.
        Initialize();

        // [GIVEN] Enable Non-Deductible VAT, and also enable Show Non-Ded. VAT In Lines in VAT Setup.
        VATSetup.Get();
        VATSetup."Enable Non-Deductible VAT" := true;
        VATSetup."Show Non-Ded. VAT In Lines" := true;
        VATSetup.Modify();

        // [GIVEN] Create VAT Posting Setup with Non-Deductible VAT
        VATPostingSetup.DeleteAll();
        CreateVATPostingSetupWithNonDeductibleVAT(VATPostingSetup);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(21, 21));
        VATPostingSetup.Validate("Non-Deductible VAT %", LibraryRandom.RandIntInRange(10, 10));
        VATPostingSetup.Modify((true));

        // [GIVEN] Generate and save Vendor in a Variable.
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create an Item and Validate VAT Prod. Posting Group.
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Create and Post Purchase Invoice with Direct Unit Cost = X
        NonDeductibleVATBase := CreateAndPostPurchaseInvoice(Item."No.", VendorNo, LibraryRandom.RandIntInRange(1000, 1000));

        // [GIVEN] Create and Post Purchase Invoice with Direct Unit Cost = X
        NonDeductibleVATBase += CreateAndPostPurchaseInvoice(Item."No.", VendorNo, LibraryRandom.RandIntInRange(2000, 2000));

        // [WHEN] Run Calc and Post VAT Settlement report for VAT Posting Group "VP1" with Post = Yes
        NewDocNo := LibraryUtility.GenerateGUID();
        VATPostingSetup.SetRecFilter();
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(
          WorkDate(), WorkDate(), WorkDate(), NewDocNo, LibraryERM.CreateGLAccountNo(), false, true);
        CalcAndPostVATSettlement.UseRequestPage(false);
        CalcAndPostVATSettlement.SaveAsXml(FileManagement.ServerTempFileName('xml'));

        // [THEN] Verify: Non-Deductibale VAT Base is correct after posting VAT Settlement
        VatEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VatEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VatEntry.SetRange("Document No.", NewDocNo);
        VatEntry.FindLast();
        Assert.AreEqual(
          -NonDeductibleVATBase,
          VatEntry."Non-Deductible VAT Base",
          StrSubstNo(ValueMustBeEqualErr, VatEntry.FieldCaption("Non-Deductible VAT Base"), -NonDeductibleVATBase, VatEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    procedure TelematicFileGenerationForTransFormatWithLargeForValueField()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        GeneratedTextFromFile: BigText;
        FileName: Text[1024];
        Value: Text[80];
    begin
        // [SCENARIO 543195] Telematic VAT Declaration Report generates file for AEAT Transference Format with Value Length equal to 80.
        Initialize();

        // [GIVEN] VAT Statement with Line.
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineDescription(VATStatementLine, VATStatementName);

        // [GIVEN] Assign Random Text of 80 Character to Value.
        Value := LibraryRandom.RandText(80);

        // [GIVEN] AEAT Transreference Format for VAT Statement with Length 80.
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(
          AEATTransferenceFormat,
          VATStatementName.Name,
          1,
          1,
          80,
          AEATTransferenceFormat.Type::Alphanumerical,
          AEATTransferenceFormat.Subtype::" ",
          Value,
          '');

        // [WHEN] Run Telematic VAT Declaration Report.
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // [THEN] Generated file has value length accepts 80 Character.
        LibraryTextFileValidation.ReadTextFile(FileName, GeneratedTextFromFile);
        Assert.AreEqual(
          AEATTransferenceFormat.Value,
          Format(GeneratedTextFromFile),
          AEATTransferenceValueErr);
    end;

    [Test]
    procedure GetPostedDocumentLinesToReverseInPostedSalesShipmentBringSEquivalenceCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        VATPostingSetupNormal: Record "VAT Posting Setup";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        // [SCENARIO 566248] Get Posted Document Lines to Reverse action from the Posted Sales Shipment brings the Equivalence Charge correctly.
        Initialize();

        // [GIVEN] Create VAT Posting Setup with "VAT %" and "EC %".
        CreateVATPostingSetup(VATPostingSetupNormal);
        VATPostingSetupNormal.Validate("VAT %", LibraryRandom.RandDecInRange(10, 20, 2));
        VATPostingSetupNormal.Validate("EC %", LibraryRandom.RandDecInDecimalRange(5, 15, 2));
        VATPostingSetupNormal.Modify(true);

        // [GIVEN] Create Sales Invoice with VAT Posting Setup.
        CreatePostSalesInvoice(SalesHeader, VATPostingSetupNormal);

        // [GIVEN] Create Sales Credit Memo and Validate "VAT Bus. Posting Group".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetupNormal."VAT Bus. Posting Group");
        SalesHeader.Modify(true);

        // [WHEN] "Get Posted Document Lines to Reverse" from Sales Credit Memo.
        SalesShipmentLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        CopyDocumentMgt.SetProperties(false, false, false, false, true, true, false);
        CopyDocumentMgt.CopySalesShptLinesToDoc(SalesHeader, SalesShipmentLine, LinesNotCopied, MissingExCostRevLink);

        // [THEN] EC % must be populated in Sales Credit Memo Line.
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.FindFirst();
        Assert.AreEqual(
          VATPostingSetupNormal."EC %",
          SalesLine."EC %",
          StrSubstNo(
            ECPercentErr,
            VATPostingSetupNormal."EC %",
            SalesLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('TransferenceTXTWithDateFilterRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    procedure TestTransferenceTXTVATEntryTotalingWithVATSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FileName: Text[1024];
        PadString: Text[1];
        VendorNo: Code[20];
        ItemNo: Code[20];
        VATReportingDate: Date;
    begin
        // [SCENARIO 576379] Generate txt file from VAT statement filters by Posting Date and not by VAT Date in the Spanish version.
        Initialize();

        // [GIVEN] Create VAT Posting Setup With 21%
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 21);

        // [GIVEN] Create Vendor and Item
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create Purchase Header with Invoice Document Type and change the VAT Date to next month
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        VATReportingDate := CalcDate('<1M>', PurchaseHeader."VAT Reporting Date");
        PurchaseHeader.Validate("VAT Reporting Date", VATReportingDate);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create the Purchase Line with 1000 Unit Cost
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, ItemNo, 1000, 1);

        // [GIVEN] Post the Purchase Document
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Create VAT Statement Template, Declaration and VAT Statement Line
        PadString := '0';
        CreateVATStatement(VATStatementName);
        CreateVATStatementLineVATTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Base, '1');
        CreateVATStatementLineVATTotalling(VATStatementLine, VATStatementName, '2',
          VATPostingSetup, VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::Amount, '2');

        // [GIVEN] Design the Text File Transference Format
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          1, 1, 17, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::"Integer and Decimal Part",
          '', '1');
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
          2, 18, 35, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::"Integer and Decimal Part",
          '', '2');

        // [WHEN] Run the Telematic VAT Declaration Report with Date Filter
        FileName := CopyStr(RunTelematicVATDeclarationWithDateFilter(VATStatementLine, 0, 1, false, Format(VATReportingDate)), 1, 1024);

        // [THEN] Verify - check the account amount printed in file
        Assert.AreEqual(PadDecimalToString(1000, 2, 17, PadString, false, false),
          Format(LibraryTextFileValidation.ReadValueFromLine(FileName, 1, 1, 17)),
          'Amount is not set correctly.');
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionModalPageHandler,TransferenceTXTRequestPageHandler,TransferenceTXTModalPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure NonDeductibleVATAmountinTransferenceTxtFile()
    var
        VATSetup: Record "VAT Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        AEATTransferenceFormat: Record "AEAT Transference Format";
        TelematicVATDeclaration: Report "Telematic VAT Declaration";
        VendorNo: Code[20];
        ItemNo: Code[20];
        NonDeductibleVATAmount: Decimal;
        GeneratedTextFromFile: BigText;
        FileName: Text[1024];
    begin
        // [SCENARIO 592275] Test Non-Deductible VAT shown in txt file
        Initialize();

        // [GIVEN] Enable Non-Deductible VAT in VAT Setup 
        VATSetup.Get();
        VATSetup."Enable Non-Deductible VAT" := true;
        VATSetup."Show Non-Ded. VAT In Lines" := true;
        VATSetup.Modify();

        // [GIVEN] Create VAT VAT Posting Setup with Non-Deductible VAT
        CreateVATPostingSetupWithNonDeductibleVAT(VATPostingSetup);

        // [GIVEN] Create Vendor with VAT Bus Posting Group 
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create Item with VAT Product Posting Group 
        ItemNo := LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create and post Purchase Invoice 
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create VAT Statement Name '103' 
        CreateVATStatement(VATStatementName);
        VATStatementName.Validate("Template Type", VATStatementName."Template Type"::"One Column Report");
        VATStatementName.Modify();

        // [GIVEN] Create two VAT Statement Lines for Non-Deductible VAT Amount
        CreateVATStatementLineVATTotalling(VATStatementLine, VATStatementName, '1', VATPostingSetup,
            VATStatementLine."Gen. Posting Type"::Purchase, VATStatementLine."Amount Type"::"Non-Deductible Amount", '1');

        // [GIVEN] Create Transference Format 
        LibraryVATStatement.CreateAEATTransreferenceFormatTxt(AEATTransferenceFormat, VATStatementName.Name,
            1, 1, 17, AEATTransferenceFormat.Type::Numerical, AEATTransferenceFormat.Subtype::"Integer and Decimal Part", '00000000000000000', '1');

        // [GIVEN] Get Non-Deductible VAT Amount from VAT Statement Preview
        NonDeductibleVATAmount := GetNonDeductibelVATAmountfromPreview(VATStatementName."Statement Template Name");

        // [GIVEN] Load Non-Deductible VAT Amount into AEAT Transference Format
        TelematicVATDeclaration.LoadValue(AEATTransferenceFormat, NonDeductibleVATAmount);

        // [WHEN] Run Telematic VAT Declaration Report
        FileName := CopyStr(RunTelematicVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // [THEN] Verify - check the Non-Deductible VAT Amount printed in file
        LibraryTextFileValidation.ReadTextFile(FileName, GeneratedTextFromFile);
        Assert.AreEqual(
          AEATTransferenceFormat.Value,
          Format(GeneratedTextFromFile),
          AEATTransferenceValueErr);
    end;

    local procedure GetVATAmount(DocNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.CalcSums(Amount);

        exit((VATEntry.Amount));
    end;

    local procedure GetTaxableAmount(DocNo: Code[20]): Decimal
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.CalcSums(Base);

        exit((NoTaxableEntry.Base));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySetupStorage.SaveVATSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GLSetup.Get();

        IsInitialized := true;
        Commit();
    end;

    local procedure TransferenceXMLAskIsFilledAndInFile(Type: Option)
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        AskFieldValue: Variant;
        AccountNo: Code[20];
        FileName: Text[1024];
        FieldValue: Code[250];
        Node1: Text[250];
        NodeOrAttribute2: Text[250];
    begin
        // Setup
        Initialize();

        AccountNo := CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        FieldValue := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Value),
            DATABASE::"AEAT Transference Format XML");
        Node1 := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description),
            DATABASE::"AEAT Transference Format XML");
        NodeOrAttribute2 := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Description),
            DATABASE::"AEAT Transference Format XML");

        CreateVATStatement(VATStatementName);
        CreateVATStatementLineAcctTotalling(VATStatementLine, VATStatementName, '1',
          VATPostingSetup, AccountNo, VATStatementLine."Amount Type"::" ", '');
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 1,
          Node1, AEATTransferenceFormatXML."Line Type"::Element, 1, 0, AEATTransferenceFormatXML."Value Type"::" ",
          LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Value),
            DATABASE::"AEAT Transference Format XML"), '', true); // ask TRUE
        LibraryVATStatement.CreateAEATTransreferenceFormatXML(AEATTransferenceFormatXML, VATStatementName.Name, 2,
          NodeOrAttribute2, Type, 2, 1, AEATTransferenceFormatXML."Value Type"::" ", FieldValue, '', false); // ask FALSE

        // Exercise - call report for default request options
        FileName := CopyStr(RunXMLVATDeclaration(VATStatementLine, 0, 0, false), 1, 1024);

        // Verify
        // Code will be "pass" in the end in TransferenceTXTModalPageHandlerWithSetAskField handler
        // new value set will be passed over
        LibraryVariableStorage.Dequeue(AskFieldValue);
        LibraryXMLRead.Initialize(FileName);
        asserterror LibraryXMLRead.VerifyNodeValue(Node1, AskFieldValue);
        Assert.ExpectedError(KnownFailureUnexpErr); // Bug exists as the value is not saved while changing in the page handler
        if Type = AEATTransferenceFormatXML."Line Type"::Element then
            LibraryXMLRead.VerifyNodeValueInSubtree(Node1, NodeOrAttribute2, FieldValue)
        else
            LibraryXMLRead.VerifyAttributeValue(Node1, NodeOrAttribute2, FieldValue);
    end;

    local procedure VerifyVATStatementLines(VATStatement: TestPage "VAT Statement"; StatementName: Code[10])
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.SetRange("Statement Name", StatementName);
        VATStatementLine.FindSet();
        VATStatement.First();

        repeat
            Assert.AreEqual(StatementName, VATStatement.CurrentStmtName.Value,
              'Name is not filtered correctly.');
            Assert.AreEqual(VATStatementLine."Row No.", VATStatement."Row No.".Value,
              'Row No is not correct.');
            Assert.AreEqual(Format(VATStatementLine.Type), VATStatement.Type.Value,
              'Type is not correct.');

            Assert.AreEqual(VATStatementLine.Description, VATStatement.Description.Value,
              'Description is not correct.');
            Assert.AreEqual(VATStatementLine."Account Totaling", VATStatement."Account Totaling".Value,
              'Account totaling is not correct.');

            Assert.AreEqual(Format(VATStatementLine."Gen. Posting Type"), VATStatement."Gen. Posting Type".Value,
              'Posting type is not correct.');

            Assert.AreEqual(VATStatementLine."VAT Bus. Posting Group", VATStatement."VAT Bus. Posting Group".Value,
              'VAT Bus posting Group is not correct.');
            Assert.AreEqual(VATStatementLine."VAT Prod. Posting Group", VATStatement."VAT Prod. Posting Group".Value,
              'VAT Prod. Posting Group is not correct.');
            Assert.AreEqual(Format(VATStatementLine."Amount Type"), VATStatement."Amount Type".Value,
              'Amount Type is not correct.');

            Assert.AreEqual(VATStatementLine."Row Totaling", VATStatement."Row Totaling".Value,
              'Row Totaling is not correct.');
            Assert.AreEqual(VATStatementLine.Box, VATStatement.Box.Value,
              'Box is not correct.');

            VATStatement.Next();
        until VATStatementLine.Next() = 0;
    end;

    local procedure VerifyTransferenceTXT(TransferenceFormat: TestPage "Transference Format"; StatementName: Code[10]; AskMode: Boolean)
    var
        AEATTransferenceFormat: Record "AEAT Transference Format";
        Box: Code[5];
    begin
        AEATTransferenceFormat.SetRange("VAT Statement Name", StatementName);
        if AskMode then
            AEATTransferenceFormat.SetRange(Type, AEATTransferenceFormat.Type::Ask);
        AEATTransferenceFormat.FindSet();
        TransferenceFormat.First();

        repeat
            Assert.AreEqual(AEATTransferenceFormat."VAT Statement Name", TransferenceFormat.VATStmtCode.Value,
              'Name is not filtered correctly.');
            Assert.AreEqual(AEATTransferenceFormat."No.", TransferenceFormat."No.".AsInteger(),
              'No is not correct.');
            Assert.AreEqual(AEATTransferenceFormat.Position, TransferenceFormat.Position.AsInteger(),
              'Position is not correct.');

            Assert.AreEqual(AEATTransferenceFormat.Length, TransferenceFormat.Length.AsInteger(),
              'Length is not correct.');
            Assert.AreEqual(Format(AEATTransferenceFormat.Type), TransferenceFormat.Type.Value,
              'Type is not correct.');
            Assert.AreEqual(Format(AEATTransferenceFormat.Subtype), TransferenceFormat.Subtype.Value,
              'Subtype is not correct.');

            Assert.AreEqual(AEATTransferenceFormat.Description, TransferenceFormat.Description.Value,
              'Description is not correct.');
            Assert.AreEqual(AEATTransferenceFormat.Value, TransferenceFormat.Value.Value,
              'Value is not correct.');

            Box := AEATTransferenceFormat.Box;
            if AskMode and (Box = '') then
                Box := '**';
            Assert.AreEqual(Box, TransferenceFormat.Box.Value,
              'Box is not correct.');

            TransferenceFormat.Next();
        until AEATTransferenceFormat.Next() = 0;
    end;

    local procedure VerifyTransferenceXML(XMLTransferenceFormat: TestPage "XML Transference Format"; StatementName: Code[10]; AskMode: Boolean)
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        Box: Code[5];
    begin
        AEATTransferenceFormatXML.SetRange("VAT Statement Name", StatementName);
        AEATTransferenceFormatXML.SetRange(Ask, AskMode);
        AEATTransferenceFormatXML.FindSet();
        XMLTransferenceFormat.First();

        repeat
            Assert.AreEqual(AEATTransferenceFormatXML."VAT Statement Name", XMLTransferenceFormat.VATStmtCode.Value,
              'Name is not filtered correctly.');
            Assert.AreEqual(AEATTransferenceFormatXML."No.", XMLTransferenceFormat."No.".AsInteger(),
              'No is not correct.');
            Assert.AreEqual(AEATTransferenceFormatXML."Indentation Level", XMLTransferenceFormat."Indentation Level".AsInteger(),
              'Indentation level is not correct.');

            Assert.AreEqual(Format(AEATTransferenceFormatXML."Line Type"), XMLTransferenceFormat."Line Type".Value,
              'Type is not correct.');
            Assert.AreEqual(AEATTransferenceFormatXML."Parent Line No.", XMLTransferenceFormat."Parent Line No.".AsInteger(),
              'No is not correct.');
            Assert.AreEqual(Format(AEATTransferenceFormatXML."Value Type"), XMLTransferenceFormat."Value Type".Value,
              'Value Type is not correct.');

            Assert.AreEqual(AEATTransferenceFormatXML.Description, XMLTransferenceFormat.Description.Value,
              'Description is not correct.');
            Assert.AreEqual(AEATTransferenceFormatXML.Value, XMLTransferenceFormat.Value.Value,
              'Value is not correct.');
            Assert.AreEqual(AEATTransferenceFormatXML.Ask, XMLTransferenceFormat.Ask.AsBoolean(),
              'Ask is not correct.');

            Box := AEATTransferenceFormatXML.Box;
            if AskMode and (Box = '') then
                Box := '**';
            Assert.AreEqual(AEATTransferenceFormatXML.Box, XMLTransferenceFormat.Box.Value,
              'Box is not correct.');

            XMLTransferenceFormat.Next();
        until AEATTransferenceFormatXML.Next() = 0;
    end;

    local procedure CreateVATStatement(var VATStatementName: Record "VAT Statement Name")
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        VATStatementName.Validate("Template Type", VATStatementName."Template Type"::"One Column Report");
        VATStatementName.Modify(true);
    end;

    local procedure CreateVATStatementLineAcctTotalling(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; RowNo: Code[10]; VATPostingSetup: Record "VAT Posting Setup"; AccountTotaling: Text[30]; AmountType: Enum "VAT Statement Line Amount Type"; Box: Code[5])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VATStatementLine);

        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"Account Totaling");
        VATStatementLine.Validate("Account Totaling", AccountTotaling);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Amount Type", AmountType);
        VATStatementLine.Validate(Box, Box);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateVATStatementLineRowTotalling(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; RowNo: Code[10]; RowTotaling: Text[30]; Box: Code[5])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VATStatementLine);

        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"Row Totaling");
        VATStatementLine.Validate("Row Totaling", RowTotaling);
        VATStatementLine.Validate(Box, Box);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateVATStatementLineECTotalling(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; RowNo: Code[10]; VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type"; AmountType: Enum "VAT Statement Line Amount Type"; Box: Code[5])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VATStatementLine);

        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"EC Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", GenPostingType);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Amount Type", AmountType);
        VATStatementLine.Validate(Box, Box);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateVATStatementLineVATTotalling(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; RowNo: Code[10]; VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type"; AmountType: Enum "VAT Statement Line Amount Type"; Box: Code[5])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VATStatementLine);

        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", GenPostingType);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Amount Type", AmountType);
        VATStatementLine.Validate(Box, Box);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateVATStatementLineDescription(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VATStatementLine);

        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Description,
          LibraryUtility.GenerateRandomCode(VATStatementName.FieldNo(Name), DATABASE::"VAT Statement Name"));
        VATStatementLine.Modify(true);
    end;

    local procedure CreateAndPostGeneralJournalLineToBalAccount(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccount: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocType: Enum "Gen. Journal Document Type";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        DocType := GenJournalLine."Document Type"::Invoice;
        if (AccountType = GenJournalLine."Account Type"::Vendor) and (Amount >= 0) then
            DocType := GenJournalLine."Document Type"::"Credit Memo";

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", BalAccount);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        CopyFromVATPostingSetup: Record "VAT Posting Setup";
    begin
        CopyFromVATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(CopyFromVATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales VAT Account", CopyFromVATPostingSetup."Sales VAT Account");
        VATPostingSetup.Validate("Purchase VAT Account", CopyFromVATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(20));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandInt(3));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupNoTaxable(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGLAccountWithVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; PostingType: Enum "General Posting Type"): Code[20]
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, PostingType));
    end;

    local procedure CreateGLAccountWithFullVATPostingSetupPurch(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Validate("Purchase VAT Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."Purchase VAT Account");
    end;

    local procedure PadDecimalToString(Amount: Decimal; Precision: Integer; Length: Integer; PadWith: Text[1]; IgnoreIntegerPart: Boolean; IgnoreDecimalPart: Boolean): Text
    var
        TextAmount: Text;
        IntegerPart: Text;
        DecimalPart: Text;
        PaddingText: Text;
    begin
        // Convert to text
        TextAmount := ConvertStr(Format(Amount, 0, '<Precision,' + Format(Precision) + '><Integer><Decimals>'), '.', ',');

        // take integer and decimal parts
        IntegerPart := SelectStr(1, TextAmount);
        DecimalPart := '';
        if Precision > 0 then
            DecimalPart := SelectStr(2, TextAmount);

        if IgnoreIntegerPart then
            IntegerPart := '';

        if IgnoreDecimalPart then
            DecimalPart := '';

        if PadWith = '' then // no padding
            exit(IntegerPart + DecimalPart);

        if Amount >= 0 then
            PaddingText := PadStr(PadWith, Length - StrLen(IntegerPart + DecimalPart), PadWith)
        else
            PaddingText := 'N' + PadStr(PadWith, Length - StrLen(IntegerPart + DecimalPart) - 1, PadWith);

        exit(PaddingText + IntegerPart + DecimalPart);
    end;

    local procedure RunTelematicVATDeclaration(var VATStatementLine: Record "VAT Statement Line"; EntryType: Option; EntryPeriod: Option; AddtnlCurrency: Boolean) ServerFileName: Text
    var
        TelematicVATDeclaration: Report "Telematic VAT Declaration";
    begin
        ServerFileName := FileManagement.ServerTempFileName('txt');

        TelematicVATDeclaration.CurrentAsign(VATStatementLine);
        TelematicVATDeclaration.SetSilentMode(ServerFileName);

        // enqueue for the modal request page
        LibraryVariableStorage.Enqueue(EntryType); // open entries
        LibraryVariableStorage.Enqueue(EntryPeriod); // before and within period
        LibraryVariableStorage.Enqueue(AddtnlCurrency); // additional currency
        // enqueue for the modal page handler
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");

        Commit();
        TelematicVATDeclaration.RunModal();
        Clear(TelematicVATDeclaration);
    end;

    local procedure RunXMLVATDeclaration(var VATStatementLine: Record "VAT Statement Line"; EntryType: Option; EntryPeriod: Option; AddtnlCurrency: Boolean) ServerFileName: Text
    var
        XMLVATDeclaration: Report "XML VAT Declaration";
    begin
        ServerFileName := FileManagement.ServerTempFileName('txt');

        XMLVATDeclaration.CurrentAssign(VATStatementLine);
        XMLVATDeclaration.SetSilentMode(ServerFileName);

        // enqueue for the modal request page
        LibraryVariableStorage.Enqueue(EntryType); // open entries
        LibraryVariableStorage.Enqueue(EntryPeriod); // before and within period
        LibraryVariableStorage.Enqueue(AddtnlCurrency); // additional currency
        // enqueue for the modal page handler
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");

        Commit();
        XMLVATDeclaration.RunModal();
        Clear(XMLVATDeclaration);
    end;

    local procedure GetLastCharCode(FileName: Text) CharCode: Integer
    var
        File: File;
        InStream: InStream;
        FileChar: Char;
    begin
        File.Open(FileName);
        File.CreateInStream(InStream);
        while not InStream.EOS do
            InStream.Read(FileChar);
        CharCode := FileChar;
        File.Close();
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; VATAmount: Decimal; VATBase: Decimal; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        VATEntry."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATEntry."Posting Date" := WorkDate();
        VATEntry.Amount := VATAmount;
        VATEntry.Base := VATBase;
        VATEntry."VAT Calculation Type" := VATCalculationType;
        VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry.Insert();
    end;

    local procedure CreateVATEntryWithPostingGroups(var VATEntry: Record "VAT Entry"; VATAmount: Decimal; VATBase: Decimal; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATEntry(VATEntry, VATAmount, VATBase, VATCalculationType);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATStatementNameWithTemplateType(var VATStatementName: Record "VAT Statement Name"; TemplateType: Option)
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        VATStatementName."Template Type" := TemplateType;
        VATStatementName.Modify();
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; VATEntry: Record "VAT Entry"; AmountType: Enum "VAT Statement Line Amount Type")
    begin
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Type := VATStatementLine.Type::"VAT Entry Totaling";
        VATStatementLine."Gen. Posting Type" := VATStatementLine."Gen. Posting Type"::Purchase;
        VATStatementLine."VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
        VATStatementLine."VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
        VATStatementLine."Amount Type" := AmountType;
        VATStatementLine.Print := true;
        VATStatementLine.Modify();
    end;

    local procedure CreatePostPurchInvoice(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        exit(CreatePostCustomPurchInvoice(PurchaseHeader, VATPostingSetup, ''));
    end;

    local procedure CreatePostPurchInvoiceWithCurrency(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20]
    begin
        exit(CreatePostCustomPurchInvoice(PurchaseHeader, VATPostingSetup, CurrencyCode));
    end;

    local procedure CreatePostCustomPurchInvoice(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostSalesInvoice(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        exit(CreatePostCustomSalesInvoice(SalesHeader, VATPostingSetup, ''));
    end;

    local procedure CreatePostSalesInvoiceWithCurrency(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20]
    begin
        exit(CreatePostCustomSalesInvoice(SalesHeader, VATPostingSetup, CurrencyCode));
    end;

    local procedure CreatePostCustomSalesInvoice(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20]
    var
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        SalesHeader.CalcFields(Amount);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure RunVatStatementReport(VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name")
    begin
        VATStatementLine.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.SetRange("Statement Name", VATStatementName.Name);
        REPORT.Run(REPORT::"VAT Statement", true, false, VATStatementLine);
    end;

    local procedure RunVatStatementReportAndLoad(VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name")
    var
        RequestPageXML: Text;
    begin
        VATStatementLine.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.SetRange("Statement Name", VATStatementName.Name);
        RequestPageXML := Report.RunRequestPage(Report::"VAT Statement");
        LibraryReportDataset.RunReportAndLoad(Report::"VAT Statement", VATStatementLine, RequestPageXML);
    end;

    local procedure VerifyNoTaxableCount(VATBusPostGr: Code[20]; IsClosed: Boolean; Qty: Integer)
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.SetRange("VAT Bus. Posting Group", VATBusPostGr);
        NoTaxableEntry.SetRange(Closed, IsClosed);
        Assert.RecordCount(NoTaxableEntry, Qty);
    end;

    local procedure VerifyVATStatementLineForRow(TotalAmount: Decimal; TotalBase: Decimal; RowNo: Variant)
    begin
        LibraryReportDataset.SetRange('RowNo_VATStatementLine', RowNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalAmtTok, TotalAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalBaseTok, TotalBase);
    end;

    local procedure CreateVATPostingSetupWithNonDeductibleVAT(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(2, 2));
        VATPostingSetup.Validate("VAT Identifier", LibraryRandom.RandText(10));
        VATPostingSetup.Validate("Allow Non-Deductible VAT", VATPostingSetup."Allow Non-Deductible VAT"::Allow);
        VATPostingSetup.Validate("Non-Deductible VAT %", LibraryRandom.RandIntInRange(3, 3));
        VATPostingSetup.Validate("Non-Ded. Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VatPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VatPostingSetup.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(ItemNo: Code[20]; VendorNo: Code[20]; DirectUnitCost: Decimal) NonDeductibleVATBase: Decimal;
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryRandom.RandText(20));
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        NonDeductibleVATBase := PurchaseLine."Non-Deductible VAT Base";

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);
    end;

    local procedure GetNonDeductibelVATAmountfromPreview(StatementTemplateName: Code[10]): Decimal
    var
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        NonDeductibleVATAmount: Decimal;
    begin
        LibraryVariableStorage.Enqueue(StatementTemplateName);
        VATStatement.OpenEdit();
        VATStatementPreview.Trap();
        VATStatement."P&review".Invoke();
        Evaluate(NonDeductibleVATAmount, VATStatementPreview.VATStatementLineSubForm.ColumnValue.Value);
        VATStatementPreview.Close();

        exit(NonDeductibleVATAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectionModalPageHandler(var VATStatementTemplateList: TestPage "VAT Statement Template List")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        TemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        VATStatementTemplate.Get(TemplateName);
        VATStatementTemplateList.GotoRecord(VATStatementTemplate);

        VATStatementTemplateList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferenceTXTRequestPageHandler(var TelematicVATDeclaration: TestRequestPage "Telematic VAT Declaration")
    var
        EntryType: Variant;
        EntryPeriod: Variant;
        Currency: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryType);
        LibraryVariableStorage.Dequeue(EntryPeriod);
        LibraryVariableStorage.Dequeue(Currency);

        TelematicVATDeclaration.EntryType.SetValue(EntryType);
        TelematicVATDeclaration.EntryPeriod.SetValue(EntryPeriod);
        TelematicVATDeclaration.AddtnlCurrency.SetValue(Currency);
        
        TelematicVATDeclaration.OK().Invoke(); // code will "jump" to TransferenceTXTModalPageHandlerWithVerify
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransferenceTXTModalPageHandlerSimple(var TransferenceFormat: TestPage "Transference Format")
    begin
        // No handling
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransferenceTXTModalPageHandlerWithVerify(var TransferenceFormat: TestPage "Transference Format")
    var
        StatementName: Variant;
    begin
        LibraryVariableStorage.Dequeue(StatementName);
        VerifyTransferenceTXT(TransferenceFormat, StatementName, true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransferenceTXTModalPageHandlerWithSetAskField(var TransferenceFormat: TestPage "Transference Format")
    var
        AEATTransferenceFormat: Record "AEAT Transference Format";
        StatementName: Variant;
        AskFieldValue: Text[250];
    begin
        LibraryVariableStorage.Dequeue(StatementName); // this will not be used. Is only to avoid creating a new request page handler
        AskFieldValue := LibraryUtility.GenerateRandomCode(AEATTransferenceFormat.FieldNo(Value),
            DATABASE::"AEAT Transference Format");

        TransferenceFormat.First();
        TransferenceFormat.Value.SetValue(AskFieldValue);
        TransferenceFormat.Next();
        LibraryVariableStorage.Enqueue(AskFieldValue); // pass it back to caller for validation
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferenceXMLRequestPageHandler(var XMLVATDeclaration: TestRequestPage "XML VAT Declaration")
    var
        EntryType: Variant;
        EntryPeriod: Variant;
        Currency: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryType);
        LibraryVariableStorage.Dequeue(EntryPeriod);
        LibraryVariableStorage.Dequeue(Currency);

        XMLVATDeclaration.EntryType.SetValue(EntryType);
        XMLVATDeclaration.EntryPeriod.SetValue(EntryPeriod);
        XMLVATDeclaration.AddtnlCurrency.SetValue(Currency);

        XMLVATDeclaration.OK().Invoke(); // code will "jump" to TransferenceXMLModalPageHandlerWithVerify
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransferenceXMLModalPageHandlerWithVerify(var XMLTransferenceFormat: TestPage "XML Transference Format")
    var
        StatementName: Variant;
    begin
        LibraryVariableStorage.Dequeue(StatementName);
        VerifyTransferenceXML(XMLTransferenceFormat, StatementName, true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransferenceXMLModalPageHandlerWithSetAskField(var XMLTransferenceFormat: TestPage "XML Transference Format")
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        StatementName: Variant;
        AskFieldValue: Text[250];
    begin
        LibraryVariableStorage.Dequeue(StatementName); // this will not be used. Is only to avoid creating a new request page handler
        AskFieldValue := LibraryUtility.GenerateRandomCode(AEATTransferenceFormatXML.FieldNo(Value),
            DATABASE::"AEAT Transference Format XML");

        XMLTransferenceFormat.First();
        XMLTransferenceFormat.Value.SetValue(AskFieldValue);
        XMLTransferenceFormat.Next();
        LibraryVariableStorage.Enqueue(AskFieldValue); // pass it back to caller for validation
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementRequestPageHandler(var VATStatement: TestRequestPage "VAT Statement")
    begin
        VATStatement.Selection.SetValue(0); // Open
        VATStatement.PeriodSelection.SetValue(0); // Before and Within Period
        VATStatement.ShowAmtInAddCurr.SetValue(false);
        VATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementRequestPageHandlerDefault(var VATStatement: TestRequestPage "VAT Statement")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlemetRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.StartingDate.SetValue(WorkDate());
        CalcAndPostVATSettlement.EndingDate.SetValue(WorkDate());
        CalcAndPostVATSettlement.PostingDt.SetValue(WorkDate());
        CalcAndPostVATSettlement.ShowVATEntries.SetValue(true);
        CalcAndPostVATSettlement.Post.SetValue(false);
        CalcAndPostVATSettlement.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CalcAndPostVATSettlement.SettlementAcc.SetValue(LibraryVariableStorage.DequeueText());
        CalcAndPostVATSettlement.OK().Invoke();
    end;

    local procedure RunTelematicVATDeclarationWithDateFilter(var VATStatementLine: Record "VAT Statement Line"; EntryType: Option; EntryPeriod: Option; AddtnlCurrency: Boolean; LineDateFilter: Text[100]) ServerFileName: Text
    var
        TelematicVATDeclaration: Report "Telematic VAT Declaration";
    begin
        ServerFileName := FileManagement.ServerTempFileName('txt');

        TelematicVATDeclaration.CurrentAsign(VATStatementLine);
        TelematicVATDeclaration.SetSilentMode(ServerFileName);

        // enqueue for the modal request page
        LibraryVariableStorage.Enqueue(EntryType); // open entries
        LibraryVariableStorage.Enqueue(EntryPeriod); // before and within period
        LibraryVariableStorage.Enqueue(AddtnlCurrency); // additional currency
        LibraryVariableStorage.Enqueue(LineDateFilter);
        // enqueue for the modal page handler
        LibraryVariableStorage.Enqueue(VATStatementLine."Statement Name");

        Commit();
        TelematicVATDeclaration.RunModal();
        Clear(TelematicVATDeclaration);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferenceTXTWithDateFilterRequestPageHandler(var TelematicVATDeclaration: TestRequestPage "Telematic VAT Declaration")
    var
        EntryType: Variant;
        EntryPeriod: Variant;
        Currency: Variant;
        LineDateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryType);
        LibraryVariableStorage.Dequeue(EntryPeriod);
        LibraryVariableStorage.Dequeue(Currency);
        LibraryVariableStorage.Dequeue(LineDateFilter);

        TelematicVATDeclaration.EntryType.SetValue(EntryType);
        TelematicVATDeclaration.EntryPeriod.SetValue(EntryPeriod);
        TelematicVATDeclaration.AddtnlCurrency.SetValue(Currency);
        TelematicVATDeclaration."VAT Declaration Line".SetFilter("Date Filter", LineDateFilter);
        TelematicVATDeclaration.OK().Invoke(); // code will "jump" to TransferenceTXTModalPageHandlerWithVerify
    end;
}

