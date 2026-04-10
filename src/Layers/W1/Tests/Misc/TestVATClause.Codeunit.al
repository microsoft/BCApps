codeunit 134067 "Test VAT Clause"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Clause]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        RefVATClauseDocumentType: enum "VAT Clause Document Type";
        VATClauseTextErr: Label 'Wrong VATClauseText on VAT Clause %1! Expected ID: %2, Actual ID: %3';

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestSalesLineVATClauseDefaultValue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acc. criteria 6 - When a Sales Document is created, then the VAT Clause is defaulted to the correct value on the Sales Line.
        Initialize();

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup, VATClause);

        // exercise
        CreateSalesDoc(SalesHeader, VATPostingSetup, '', SalesHeader."Document Type"::Invoice); // LanguageCode = ''

        // verify
        FindSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.TestField("VAT Clause Code", VATClause.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestSalesLineVATClauseVATProdPosGrChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATClause1: Record "VAT Clause";
        VATClause2: Record "VAT Clause";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        // acc. criteria 7 - When the VAT Prod. Posting Group is changed on a Sales Line, then the VAT Clause is updated correctly.
        Initialize();

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup1, VATClause1);

        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup1."VAT Bus. Posting Group", VATProdPostingGroup.Code);
        VATPostingSetup2.Validate("VAT Identifier",
          CopyStr(LibraryERM.CreateRandomVATIdentifierAndGetCode(), 1, MaxStrLen(VATPostingSetup2."VAT Identifier")));
        VATPostingSetup2.Modify(true);

        AssignVATClauseToVATPostingSetup(VATPostingSetup2, VATClause2);

        // exercise
        CreateSalesDoc(SalesHeader, VATPostingSetup1, '', SalesHeader."Document Type"::Invoice);
        FindSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        // verify
        SalesLine.TestField("VAT Clause Code", VATClause2.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestSalesLineVATClauseVATBusPosGrChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATClause1: Record "VAT Clause";
        VATClause2: Record "VAT Clause";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        // acc. criteria 7 - When the VAT Bus. Posting group is changed on a Sales Line, then the VAT Clause is updated correctly.
        Initialize();

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup1, VATClause1);

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATBusinessPostingGroup.Code, VATPostingSetup1."VAT Prod. Posting Group");
        VATPostingSetup2.Validate("VAT Identifier",
          CopyStr(LibraryERM.CreateRandomVATIdentifierAndGetCode(), 1, MaxStrLen(VATPostingSetup2."VAT Identifier")));
        VATPostingSetup2.Modify(true);
        AssignVATClauseToVATPostingSetup(VATPostingSetup2, VATClause2);

        // exercise
        CreateSalesDoc(SalesHeader, VATPostingSetup1, '', SalesHeader."Document Type"::Invoice);  // LanguageCode = ''
        FindSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate("VAT Bus. Posting Group", VATPostingSetup2."VAT Bus. Posting Group");
        SalesLine.Modify(true);

        // verify
        SalesLine.TestField("VAT Clause Code", VATClause2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATClauseCodeField()
    var
        SalesLine: Record "Sales Line";
        SalesLineArchive: Record "Sales Line Archive";
        ServiceLine: Record "Service Line";
        VATClause: Record "VAT Clause";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 259058] "VAT Clause Code" field has same FIELDNO in "Sales Line", "Service Line" and "Sales Line Archive", and all "VAT Clause Code" fields have length = length of field Code in "VAT Clause"
        Initialize();

        Assert.AreEqual(SalesLine.FieldNo("VAT Clause Code"), SalesLineArchive.FieldNo("VAT Clause Code"), '');
        Assert.AreEqual(SalesLine.FieldNo("VAT Clause Code"), ServiceLine.FieldNo("VAT Clause Code"), '');
        Assert.AreEqual(MaxStrLen(VATClause.Code), MaxStrLen(SalesLine."VAT Clause Code"), '');
        Assert.AreEqual(MaxStrLen(VATClause.Code), MaxStrLen(SalesLineArchive."VAT Clause Code"), '');
        Assert.AreEqual(MaxStrLen(VATClause.Code), MaxStrLen(ServiceLine."VAT Clause Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDescription_VATClauseOnly()
    var
        VATClause: Record "VAT Clause";
        SavedVATClause: Record "VAT Clause";
        SalesHeader: Record "Sales Header";
        VATClauseText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 303986] Function GetDescription does not change descriptions when VAT Clause does not have translations and document type setup
        Initialize();

        // [GIVEN] Create VAT Clause with descriptions "D1" and "D2"
        CreateVATClause(VATClause);
        SavedVATClause := VATClause;

        // [WHEN] Function GetDescription is being run
        VATClauseText := VATClause.GetDescriptionText(SalesHeader);

        // [THEN] VAT Clause has same descriptions "D1" and "D2"
        VATClause.TestField(Description, SavedVATClause.Description);
        VATClause.TestField("Description 2", SavedVATClause."Description 2");
        Assert.AreEqual(SavedVATClause.Description + ' ' + SavedVATClause."Description 2", VATClauseText,
            StrSubstNo(VATClauseTextErr, VATClause.Code, SavedVATClause.Description + ' ' + SavedVATClause."Description 2", VATClauseText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDescription_VATClauseTranslation()
    var
        VATClause: Record "VAT Clause";
        VATClauseTranslation: Record "VAT Clause Translation";
        SalesHeader: Record "Sales Header";
        VATClauseText: Text;
    begin
        // [FEATURE] [UT] [Invoice]
        // [SCENARIO 303986] Function GetDescription sets descriptions from VAT Clause Translation
        Initialize();

        // [GIVEN] Create VAT Clause with descriptions "D1" and "D2"
        CreateVATClause(VATClause);
        // [GIVEN] Create VAT Clause Translation for language "L" with descriptions "DT1" and "DT2"
        CreateVATClauseTranslation(VATClauseTranslation, VATClause);
        // [GIVEN] Create sales invoice with "Language Code" = "L"
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader."Language Code" := VATClauseTranslation."Language Code";
        SalesHeader.Modify();

        // [WHEN] Function GetDescription is being run
        VATClauseText := VATClause.GetDescriptionText(SalesHeader);

        // [THEN] VAT Clause has descriptions "DT1" and "DT2"
        VATClause.TestField(Description, VATClauseTranslation.Description);
        VATClause.TestField("Description 2", VATClauseTranslation."Description 2");
        Assert.AreEqual(VATClauseTranslation.Description + ' ' + VATClauseTranslation."Description 2", VATClauseText,
            StrSubstNo(VATClauseTextErr, VATClause.Code, VATClauseTranslation.Description + ' ' + VATClauseTranslation."Description 2", VATClauseText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDescription_VATClauseByDocType()
    var
        VATClause: Record "VAT Clause";
        VATClauseByDocType: Record "VAT Clause by Doc. Type";
        SalesHeader: Record "Sales Header";
        VATClauseText: Text;
    begin
        // [FEATURE] [UT] [Invoice]
        // [SCENARIO 303986] Function GetDescription sets descriptions from VAT Clause by Document Type
        Initialize();

        // [GIVEN] Create VAT Clause with descriptions "D1" and "D2"
        CreateVATClause(VATClause);
        // [GIVEN] Create VAT Clause by Doc. Type with descriptions "DI1" and "DI2"
        CreateVATClauseByDocType(VATClauseByDocType, RefVATClauseDocumentType::Invoice, VATClause);
        // [GIVEN] Create sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] Function GetDescription is being run
        VATClauseText := VATClause.GetDescriptionText(SalesHeader);

        // [THEN] VAT Clause has same descriptions "DI1" and "DI2"
        VATClause.TestField(Description, VATClauseByDocType.Description);
        VATClause.TestField("Description 2", VATClauseByDocType."Description 2");
        Assert.AreEqual(VATClauseByDocType.Description + ' ' + VATClauseByDocType."Description 2", VATClauseText,
            StrSubstNo(VATClauseTextErr, VATClause.Code, VATClauseByDocType.Description + ' ' + VATClauseByDocType."Description 2", VATClauseText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDescription_VATClauseByDocTypeTranslation()
    var
        VATClause: Record "VAT Clause";
        VATClauseByDocType: Record "VAT Clause by Doc. Type";
        VATClauseByDocTypeTrans: Record "VAT Clause by Doc. Type Trans.";
        SalesHeader: Record "Sales Header";
        VATClauseText: Text;
    begin
        // [FEATURE] [UT] [Invoice]
        // [SCENARIO 303986] Function GetDescription sets descriptions from VAT Clause by Document Type Translation
        Initialize();

        // [GIVEN] Create VAT Clause with descriptions "D1" and "D2"
        CreateVATClause(VATClause);

        // [GIVEN] Create VAT Clause by Doc. Type Translation for language "L" with descriptions "DIT1" and "DIT2"
        CreateVATClauseByDocType(VATClauseByDocType, RefVATClauseDocumentType::Invoice, VATClause);
        CreateVATClauseByDocTypeTranslation(VATClauseByDocTypeTrans, VATClauseByDocType);

        // [GIVEN] Create sales invoice with "Language Code" = "L"
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader."Language Code" := VATClauseByDocTypeTrans."Language Code";
        SalesHeader.Modify();

        // [WHEN] Function GetDescription is being run
        VATClauseText := VATClause.GetDescriptionText(SalesHeader);

        // [THEN] VAT Clause has same descriptions "DIT1" and "DIT2"
        VATClause.TestField(Description, VATClauseByDocTypeTrans.Description);
        VATClause.TestField("Description 2", VATClauseByDocTypeTrans."Description 2");
        Assert.AreEqual(VATClauseByDocTypeTrans.Description + ' ' + VATClauseByDocTypeTrans."Description 2", VATClauseText,
            StrSubstNo(VATClauseTextErr, VATClause.Code, VATClauseByDocTypeTrans.Description + ' ' + VATClauseByDocTypeTrans."Description 2", VATClauseText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDescription_CrMemoVATClauseByDocTypeTranslation()
    var
        VATClause: Record "VAT Clause";
        VATClauseByDocType: Record "VAT Clause by Doc. Type";
        VATClauseByDocTypeTrans: Record "VAT Clause by Doc. Type Trans.";
        SalesHeader: Record "Sales Header";
        VATClauseText: Text;
    begin
        // [FEATURE] [UT] [Credit Memo]
        // [SCENARIO 303986] Function GetDescription sets descriptions from VAT Clause by Document Type Translation for credit memo
        Initialize();

        // [GIVEN] Create VAT Clause with descriptions "D1" and "D2"
        CreateVATClause(VATClause);

        // [GIVEN] Create VAT Clause by Doc. Type Translation for language "L" with descriptions "DIT1" and "DIT2"
        CreateVATClauseByDocType(VATClauseByDocType, RefVATClauseDocumentType::"Credit Memo", VATClause);
        CreateVATClauseByDocTypeTranslation(VATClauseByDocTypeTrans, VATClauseByDocType);

        // [GIVEN] Create sales invoice with "Language Code" = "L"
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesHeader."Language Code" := VATClauseByDocTypeTrans."Language Code";
        SalesHeader.Modify();

        // [WHEN] Function GetDescription is being run
        VATClauseText := VATClause.GetDescriptionText(SalesHeader);

        // [THEN] VAT Clause has same descriptions "DIT1" and "DIT2"
        VATClause.TestField(Description, VATClauseByDocTypeTrans.Description);
        VATClause.TestField("Description 2", VATClauseByDocTypeTrans."Description 2");
        Assert.AreEqual(VATClauseByDocTypeTrans.Description + ' ' + VATClauseByDocTypeTrans."Description 2", VATClauseText,
            StrSubstNo(VATClauseTextErr, VATClause.Code, VATClauseByDocTypeTrans.Description + ' ' + VATClauseByDocTypeTrans."Description 2", VATClauseText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDescription_ReminderVATClauseByDocTypeTranslation()
    var
        VATClause: Record "VAT Clause";
        VATClauseByDocType: Record "VAT Clause by Doc. Type";
        VATClauseByDocTypeTrans: Record "VAT Clause by Doc. Type Trans.";
        IssuedReminderHeader: Record "Issued Reminder Header";
        VATClauseText: Text;
    begin
        // [FEATURE] [UT] [Reminder]
        // [SCENARIO 303986] Function GetDescription sets descriptions from VAT Clause by Document Type Translation for reminder
        Initialize();

        // [GIVEN] Create VAT Clause with descriptions "D1" and "D2"
        CreateVATClause(VATClause);

        // [GIVEN] Create VAT Clause by Doc. Type Translation for language "L" with descriptions "DIT1" and "DIT2"
        CreateVATClauseByDocType(VATClauseByDocType, RefVATClauseDocumentType::Reminder, VATClause);
        CreateVATClauseByDocTypeTranslation(VATClauseByDocTypeTrans, VATClauseByDocType);

        // [GIVEN] Mock issued reminder with "Language Code" = "L"
        IssuedReminderHeader."Language Code" := VATClauseByDocTypeTrans."Language Code";

        // [WHEN] Function GetDescription is being run
        VATClauseText := VATClause.GetDescriptionText(IssuedReminderHeader);

        // [THEN] VAT Clause has same descriptions "DIT1" and "DIT2"
        VATClause.TestField(Description, VATClauseByDocTypeTrans.Description);
        VATClause.TestField("Description 2", VATClauseByDocTypeTrans."Description 2");
        Assert.AreEqual(VATClauseByDocTypeTrans.Description + ' ' + VATClauseByDocTypeTrans."Description 2", VATClauseText,
           StrSubstNo(VATClauseTextErr, VATClause.Code, VATClauseByDocTypeTrans.Description + ' ' + VATClauseByDocTypeTrans."Description 2", VATClauseText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDescription_FinChargeMemoVATClauseByDocTypeTranslation()
    var
        VATClause: Record "VAT Clause";
        VATClauseByDocType: Record "VAT Clause by Doc. Type";
        VATClauseByDocTypeTrans: Record "VAT Clause by Doc. Type Trans.";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        VATClauseText: Text;
    begin
        // [FEATURE] [UT] [Finance Charge Memo]
        // [SCENARIO 303986] Function GetDescription sets descriptions from VAT Clause by Document Type Translation for finance charge memo
        Initialize();

        // [GIVEN] Create VAT Clause with descriptions "D1" and "D2"
        CreateVATClause(VATClause);

        // [GIVEN] Create VAT Clause by Doc. Type Translation for language "L" with descriptions "DIT1" and "DIT2"
        CreateVATClauseByDocType(VATClauseByDocType, RefVATClauseDocumentType::"Finance Charge Memo", VATClause);
        CreateVATClauseByDocTypeTranslation(VATClauseByDocTypeTrans, VATClauseByDocType);

        // [GIVEN] Mock issued finance charge memo with "Language Code" = "L"
        IssuedFinChargeMemoHeader."Language Code" := VATClauseByDocTypeTrans."Language Code";

        // [WHEN] Function GetDescription is being run
        VATClauseText := VATClause.GetDescriptionText(IssuedFinChargeMemoHeader);

        // [THEN] VAT Clause has same descriptions "DIT1" and "DIT2"
        VATClause.TestField(Description, VATClauseByDocTypeTrans.Description);
        VATClause.TestField("Description 2", VATClauseByDocTypeTrans."Description 2");
        Assert.AreEqual(VATClauseByDocTypeTrans.Description + ' ' + VATClauseByDocTypeTrans."Description 2", VATClauseText,
            StrSubstNo(VATClauseTextErr, VATClause.Code, VATClauseByDocTypeTrans.Description + ' ' + VATClauseByDocTypeTrans."Description 2", VATClauseText));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test VAT Clause");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test VAT Clause");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetInvoiceRounding(false);
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test VAT Clause");
    end;

    local procedure AssignVATClauseToVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var VATClause: Record "VAT Clause")
    begin
        CreateVATClause(VATClause);
        VATPostingSetup.Validate("VAT Clause Code", VATClause.Code);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; LanguageCode: Code[10]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType,
          CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group", LanguageCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
    end;

    local procedure CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode: Code[20]; LanguageCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Validate("Language Code", LanguageCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVATClause(var VATClause: Record "VAT Clause")
    begin
        VATClause.Init();
        VATClause.Validate(Code, CopyStr(LibraryUtility.GenerateRandomCode(VATClause.FieldNo(Code), DATABASE::"VAT Clause"),
            1, LibraryUtility.GetFieldLength(DATABASE::"VAT Clause", VATClause.FieldNo(Code))));
        VATClause.Validate(Description, GenerateVATClauseDescription());
        VATClause.Validate("Description 2", GenerateVATClauseDescription());
        VATClause.Insert(true);
    end;

    local procedure CreateVATClauseTranslation(var VATClauseTranslation: Record "VAT Clause Translation"; VATClause: Record "VAT Clause")
    begin
        VATClauseTranslation.Init();
        VATClauseTranslation.Validate("VAT Clause Code", VATClause.Code);
        VATClauseTranslation.Validate("Language Code", LibraryERM.GetAnyLanguageDifferentFromCurrent());
        VATClauseTranslation.Validate(Description, GenerateVATClauseDescription());
        VATClauseTranslation.Validate("Description 2", GenerateVATClauseDescription());
        VATClauseTranslation.Insert(true);
    end;

    local procedure CreateVATClauseByDocType(var VATClauseByDocType: Record "VAT Clause by Doc. Type"; DocumentType: Enum "VAT Clause Document Type"; VATClause: Record "VAT Clause")
    begin
        VATClauseByDocType.Init();
        VATClauseByDocType.Validate("VAT Clause Code", VATClause.Code);
        VATClauseByDocType.Validate("Document Type", DocumentType);
        VATClauseByDocType.Validate(Description, GenerateVATClauseDescription());
        VATClauseByDocType.Validate("Description 2", GenerateVATClauseDescription());
        VATClauseByDocType.Insert(true);
    end;

    local procedure CreateVATClauseByDocTypeTranslation(var VATClauseByDocTypeTrans: Record "VAT Clause by Doc. Type Trans."; VATClauseByDocType: Record "VAT Clause by Doc. Type")
    begin
        VATClauseByDocTypeTrans.Init();
        VATClauseByDocTypeTrans.Validate("VAT Clause Code", VATClauseByDocType."VAT Clause Code");
        VATClauseByDocTypeTrans.Validate("Document Type", VATClauseByDocType."Document Type");
        VATClauseByDocTypeTrans.Validate("Language Code", LibraryERM.GetAnyLanguageDifferentFromCurrent());
        VATClauseByDocTypeTrans.Validate(Description, GenerateVATClauseDescription());
        VATClauseByDocTypeTrans.Validate("Description 2", GenerateVATClauseDescription());
        VATClauseByDocTypeTrans.Insert(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
    end;

    local procedure CreateVATPostingSetupAndAssignVATClause(var VATPostingSetup: Record "VAT Posting Setup"; var VATClause: Record "VAT Clause")
    begin
        CreateVATPostingSetup(VATPostingSetup);
        AssignVATClauseToVATPostingSetup(VATPostingSetup, VATClause);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeaderNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindFirst();
    end;

    local procedure GenerateVATClauseDescription(): Text[250]
    var
        VATClause: Record "VAT Clause";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomCode(VATClause.FieldNo(Description), DATABASE::"VAT Clause"),
            1, LibraryUtility.GetFieldLength(DATABASE::"VAT Clause", VATClause.FieldNo(Description))));
    end;

    local procedure CreateItemWithVATProdPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.")
    end;
}
