codeunit 134440 "G/L Acct. Category - Demo Data"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account] [Account Category]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NoAccountCategoryMatchErr: Label 'There is no subcategory description for %1 that matches ''%2''.', Comment = '%1=account category value, %2=the user input.';
        NotAValidValueTxt: Label 'Not a valid value';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        TotalAssetsTxt: Label 'Total Assets';
        TotatLiabilitiesTxt: Label 'Total Liabilities';
        TotalEquityTxt: Label 'Total Equity';

    [Test]
    [Scope('OnPrem')]
    procedure TestAllGLAccountsHaveCategory()
    var
        GLAccount: Record "G/L Account";
    begin
        // Setup
        Initialize();
        FindFirstPostingGLAccount(GLAccount);

        // Verify
        repeat
            GLAccount.TestField("Account Category");
        until GLAccount.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWrongSubCategoryErrorForGLAccountCategory()
    var
        GLAccount: Record "G/L Account";
        GLAccountCard: TestPage "G/L Account Card";
    begin
        // Setup
        FindFirstPostingGLAccount(GLAccount);

        // Exercise
        GLAccountCard.OpenEdit();
        GLAccountCard.GotoRecord(GLAccount);
        asserterror GLAccountCard.SubCategoryDescription.SetValue(NotAValidValueTxt);

        // Verify
        Assert.ExpectedError(StrSubstNo(NoAccountCategoryMatchErr, GLAccountCard."Account Category", NotAValidValueTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptySubCategoryAllowedForGLAccountCategory()
    var
        GLAccount: Record "G/L Account";
        GLAccountCard: TestPage "G/L Account Card";
        InitialCategory: Text;
    begin
        // Setup
        Initialize();
        FindFirstPostingGLAccount(GLAccount);

        // Exercise
        GLAccountCard.OpenEdit();
        GLAccountCard.GotoRecord(GLAccount);
        InitialCategory := GLAccountCard."Account Category".Value();
        GLAccountCard.SubCategoryDescription.SetValue('');

        // Verify
        GLAccountCard."Account Category".AssertEquals(InitialCategory);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindFirstSubCategoryForGLAccountCategory()
    var
        GLAccount: Record "G/L Account";
        GLAccountCard: TestPage "G/L Account Card";
        InitialSubCategory: Text;
    begin
        // Setup
        Initialize();
        FindFirstPostingGLAccount(GLAccount);
        GLAccount.SetFilter("Account Subcategory Descript.", '<>%1', '');
        GLAccount.FindFirst();

        GLAccountCard.OpenEdit();
        GLAccountCard.GotoRecord(GLAccount);
        InitialSubCategory := GLAccountCard.SubCategoryDescription.Value();

        // Exercise
        GLAccountCard.SubCategoryDescription.SetValue(CopyStr(InitialSubCategory, 1, StrLen(InitialSubCategory) - 2));

        // Verify
        Assert.AreEqual(InitialSubCategory, GLAccountCard.SubCategoryDescription.Value, 'Wrong subcategory');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSameSubCategoryAllowedForGLAccountCategory()
    var
        GLAccount: Record "G/L Account";
        GLAccountCard: TestPage "G/L Account Card";
        InitialCategory: Text;
    begin
        // Setup
        Initialize();
        FindFirstPostingGLAccount(GLAccount);

        GLAccountCard.OpenEdit();
        GLAccountCard.GotoRecord(GLAccount);

        InitialCategory := GLAccountCard."Account Category".Value();

        // Exercise
        GLAccountCard.SubCategoryDescription.SetValue(GLAccountCard.SubCategoryDescription.Value);

        // Verify
        Assert.AreEqual(InitialCategory, GLAccountCard."Account Category".Value, 'Wrong category');
    end;

    [Test]
    [HandlerFunctions('FirstAccountSubCategoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestLookupFirstSubCategoryForGLAccountCategory()
    var
        GLAccount: Record "G/L Account";
        GLAccountCard: TestPage "G/L Account Card";
    begin
        // Setup
        Initialize();
        FindFirstPostingGLAccount(GLAccount);

        GLAccountCard.OpenEdit();
        GLAccountCard.GotoRecord(GLAccount);
        GLAccountCard.SubCategoryDescription.SetValue('');

        // Exercise - Value will be selected in the modal page handler
        GLAccountCard.SubCategoryDescription.Lookup();

        // Verify
        Assert.AreNotEqual('', GLAccountCard.SubCategoryDescription.Value, 'No subcategory selected');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SpecificAccountSubCategoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestLookupSpecificSubCategoryForGLAccountCategory()
    var
        GLAccount: Record "G/L Account";
        GLAccountCard: TestPage "G/L Account Card";
        InitialSubCategory: Text;
    begin
        // Setup
        Initialize();
        FindFirstPostingGLAccount(GLAccount);

        GLAccountCard.OpenEdit();
        GLAccountCard.GotoRecord(GLAccount);
        InitialSubCategory := GLAccountCard.SubCategoryDescription.Value();
        LibraryVariableStorage.Enqueue(InitialSubCategory);
        GLAccountCard.SubCategoryDescription.SetValue('');

        // Exercise - Value will be selected in the modal page handler
        GLAccountCard.SubCategoryDescription.Lookup();

        // Verify
        Assert.AreEqual(InitialSubCategory, GLAccountCard.SubCategoryDescription.Value, 'Wrong subcategory selected');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCategorySetsSpecificIncomeBalanceValue()
    var
        GLAccount: Record "G/L Account";
    begin
        // Setup
        Initialize();
        GLAccount.Init();

        // Exercise and Verify
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccount, GLAccount."Account Category"::Assets,
          GLAccount."Income/Balance"::"Balance Sheet");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccount, GLAccount."Account Category"::"Cost of Goods Sold",
          GLAccount."Income/Balance"::"Income Statement");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccount, GLAccount."Account Category"::Equity,
          GLAccount."Income/Balance"::"Balance Sheet");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccount, GLAccount."Account Category"::Expense,
          GLAccount."Income/Balance"::"Income Statement");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccount, GLAccount."Account Category"::Income,
          GLAccount."Income/Balance"::"Income Statement");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccount, GLAccount."Account Category"::Liabilities,
          GLAccount."Income/Balance"::"Balance Sheet");
    end;

    [Test]
    [HandlerFunctions('FirstAccountSubCategoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSubCategoryLookUpNotEmpty()
    var
        GLAccount: Record "G/L Account";
        LibraryUtility: Codeunit "Library - Utility";
        GLAccountCard: TestPage "G/L Account Card";
        AccountNumber: Code[20];
    begin
        // Setup
        Initialize();
        AccountNumber := LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account");
        GLAccount.Init();
        GLAccount."No." := AccountNumber;
        GLAccount.Insert();

        GLAccountCard.OpenEdit();
        GLAccountCard.GotoRecord(GLAccount);

        // Exercise
        GLAccountCard.SubCategoryDescription.Lookup();

        // Verify - Done in modal page handler

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBalanceSheetBalances()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FinancialReport: Record "Financial Report";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccScheduleName: Record "Acc. Schedule Name";
        AccSchedManagement: Codeunit AccSchedManagement;
        TotalAssets: Decimal;
        TotalLiabilities: Decimal;
        TotalEquity: Decimal;
    begin
        // Setup
        Initialize();
        GeneralLedgerSetup.Get();
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        AccScheduleLine.SetRange("Schedule Name", FinancialReport."Financial Report Row Group");
        AccScheduleLine.SetRange("Totaling Type", AccScheduleLine."Totaling Type"::Formula);
        AccScheduleLine.SetRange("Date Filter", Today);

        // Execute - Calculate Total Assets
        AccScheduleLine.SetRange(Description, TotalAssetsTxt);
        AccScheduleLine.FindFirst();
        AccScheduleName.Get(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");

        ColumnLayout.SetRange("Column Layout Name", FinancialReport."Financial Report Column Group");
        ColumnLayout.FindFirst();
        TotalAssets := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // Execute - Calculate Total Liabilities
        AccScheduleLine.SetRange(Description, TotatLiabilitiesTxt);
        AccScheduleLine.FindFirst();
        TotalLiabilities := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // Execute - Calculate Total Equity
        AccScheduleLine.SetRange(Description, TotalEquityTxt);
        AccScheduleLine.FindFirst();
        TotalEquity := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // Verify - Total Assets = Total Liabilities + Total Equity
        Assert.AreEqual(TotalAssets, TotalLiabilities + TotalEquity, 'Balance sheet is not balanced.');
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"G/L Acct. Category - Demo Data");
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure FindFirstPostingGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.FindFirst();
    end;

    local procedure SetAccountCategoryAndValidateIncomeBalanceField(GLAccount: Record "G/L Account"; AccountCategory: Enum "G/L Account Category"; IncomeBalance: Enum "G/L Account Report Type")
    begin
        GLAccount.Validate("Account Category", AccountCategory);
        GLAccount.TestField("Income/Balance", IncomeBalance);
        GLAccount.TestField("Account Subcategory Entry No.", 0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FirstAccountSubCategoryModalPageHandler(var GLAccountCategories: TestPage "G/L Account Categories")
    begin
        Assert.IsTrue(GLAccountCategories.First(), 'GL Account Categories is empty');
        GLAccountCategories.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SpecificAccountSubCategoryModalPageHandler(var GLAccountCategories: TestPage "G/L Account Categories")
    var
        SubcategoryDesc: Text;
    begin
        SubcategoryDesc := LibraryVariableStorage.DequeueText();
        GLAccountCategories.Expand(true);
        GLAccountCategories.First();
        repeat
            if GLAccountCategories.FindFirstField(Description, SubcategoryDesc) then
                break;
            if not GLAccountCategories.IsExpanded then
                GLAccountCategories.Expand(true);
        until not GLAccountCategories.Next();
        GLAccountCategories.OK().Invoke();
    end;
}

