codeunit 134442 "GL Acct. Categories Page Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account] [Account Category]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        WrongAccSchedErr: Label 'Wrong Acc. Sched.';
        CannotDeleteSystemCategoryErr: Label '%1 is a system generated category and cannot be deleted.';
        AccSchedUpdateNeededNotificationMsg: Label 'You have changed one or more G/L account categories that financial reports use. We recommend that you update the financial reports with your changes by choosing the Generate Financial Reports action.';
        AccSchedUpdateNeededNotificationAction: Option "Check Message","Generate Account Schedules","Disable Notification";

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateNewAccountCategorySiblingToARootCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        NewGLAccountCategory: Record "G/L Account Category";
    begin
        // Setup
        FindFirstParentGLAccountCategory(GLAccountCategory);

        // Exercise
        NewGLAccountCategory.Get(GLAccountCategory.InsertRow());

        // Verify
        NewGLAccountCategory.CalcFields("Has Children");
        NewGLAccountCategory.TestField("Has Children", false);
        NewGLAccountCategory.TestField(Indentation, GLAccountCategory.Indentation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateNewAccountCategoryUnderARootCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        NewGLAccountCategory: Record "G/L Account Category";
    begin
        // Setup
        FindFirstParentGLAccountCategory(GLAccountCategory);
        GLAccountCategory.SetRange("Parent Entry No.", GLAccountCategory."Entry No.");
        GLAccountCategory.FindFirst();

        // Exercise
        NewGLAccountCategory.Get(GLAccountCategory.InsertRow());

        // Verify
        NewGLAccountCategory.CalcFields("Has Children");
        NewGLAccountCategory.TestField("Has Children", false);
        NewGLAccountCategory.TestField(Indentation, GLAccountCategory.Indentation);
        NewGLAccountCategory.TestField("Parent Entry No.", GLAccountCategory."Parent Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGenerateAccountSchedules()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // Setup
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        GeneralLedgerSetup.Validate("Fin. Rep. for Balance Sheet", '');
        GeneralLedgerSetup.Validate("Fin. Rep. for Cash Flow Stmt", '');
        GeneralLedgerSetup.Validate("Fin. Rep. for Income Stmt.", '');
        GeneralLedgerSetup.Validate("Fin. Rep. for Retained Earn.", '');
        GeneralLedgerSetup.Modify(true);

        // Exercise
        GLAccountCategories.OpenView();
        GLAccountCategories.GenerateAccSched.Invoke();

        // Verify
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        Assert.AreNotEqual('', GeneralLedgerSetup."Fin. Rep. for Balance Sheet", WrongAccSchedErr);
        Assert.AreNotEqual('', GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt", WrongAccSchedErr);
        Assert.AreNotEqual('', GeneralLedgerSetup."Fin. Rep. for Income Stmt.", WrongAccSchedErr);
        Assert.AreNotEqual('', GeneralLedgerSetup."Fin. Rep. for Retained Earn.", WrongAccSchedErr);

        VerfiyCashFlowStatementAccountScheduleLines();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotIndentOrOutdentParentCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        // Setup
        FindFirstParentGLAccountCategory(GLAccountCategory);

        // Exercise
        GLAccountCategory.MakeChildOfPreviousSibling();

        // Verify
        GLAccountCategory.TestField(Indentation, 0);

        // Exercise
        GLAccountCategory.MakeSiblingOfParent();

        // Verify
        GLAccountCategory.TestField(Indentation, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMoveDownAndUpOfCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        InitialSquenceNo: Integer;
    begin
        // Setuo
        GLAccountCategory.SetFilter("Parent Entry No.", '<>0');
        GLAccountCategory.FindFirst();
        InitialSquenceNo := GLAccountCategory."Sibling Sequence No.";

        // Exercise
        GLAccountCategory.MoveDown();

        // Verify
        Assert.IsTrue(InitialSquenceNo < GLAccountCategory."Sibling Sequence No.", 'Wrong sequence no');

        GLAccountCategory.MoveUp();

        // Verify
        Assert.AreEqual(InitialSquenceNo, GLAccountCategory."Sibling Sequence No.", 'Wrong sequence no');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIndentAndOutdentChildCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        ChildGLAccountCategory: Record "G/L Account Category";
    begin
        // Setup
        FindFirstParentGLAccountCategory(GLAccountCategory);
        ChildGLAccountCategory.SetRange("Parent Entry No.", GLAccountCategory."Entry No.");
        ChildGLAccountCategory.FindFirst();

        // Exercise
        ChildGLAccountCategory.MakeSiblingOfParent();

        // Verify
        ChildGLAccountCategory.TestField("Parent Entry No.", GLAccountCategory."Parent Entry No.");
        ChildGLAccountCategory.TestField(Indentation, GLAccountCategory.Indentation);

        // Exercise
        ChildGLAccountCategory.MakeChildOfPreviousSibling();
        ChildGLAccountCategory.TestField(Indentation, GLAccountCategory.Indentation + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotDeleteSystemGLAccountCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        // Setup
        FindFirstParentGLAccountCategory(GLAccountCategory);

        // Exercise
        asserterror GLAccountCategory.Delete(true);

        // Verify
        Assert.ExpectedError(StrSubstNo(CannotDeleteSystemCategoryErr, GLAccountCategory."Account Category"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotDeleteUsedGLAccountCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
    begin
        // Setup
        GLAccount.SetFilter("Account Subcategory Entry No.", '<>0');
        GLAccount.FindFirst();
        GLAccountCategory.Get(GLAccount."Account Subcategory Entry No.");

        // Exercise
        asserterror GLAccountCategory.DeleteRow();

        // Verify
        Assert.ExpectedError('You cannot delete G/L Account Category');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteUserGLAccountCategoryWithChildrenCategories()
    var
        GLAccountCategory: Record "G/L Account Category";
        UserGLAccountCategory: Record "G/L Account Category";
        ChildGLAccountCategory: Record "G/L Account Category";
        BeforeDelCategoriesCount: Integer;
    begin
        // Setup
        FindFirstParentGLAccountCategory(GLAccountCategory);
        UserGLAccountCategory.Get(GLAccountCategory.InsertRow());

        ChildGLAccountCategory.Get(UserGLAccountCategory.InsertRow());
        ChildGLAccountCategory.MakeChildOfPreviousSibling();
        ChildGLAccountCategory.Get(UserGLAccountCategory.InsertRow());
        ChildGLAccountCategory.MakeChildOfPreviousSibling();
        Clear(GLAccountCategory);
        BeforeDelCategoriesCount := GLAccountCategory.Count();

        // Exercise - Delete user created parent category
        // Child categories are not deleted.
        UserGLAccountCategory.DeleteRow();

        // Verify
        Assert.AreEqual(BeforeDelCategoriesCount - 3, GLAccountCategory.Count, 'Wrong number of categories');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCategorySetsSpecificIncomeBalanceValue()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        // Setup
        GLAccountCategory.Init();

        // Exercise and Verify
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccountCategory, GLAccountCategory."Account Category"::Assets,
          GLAccountCategory."Income/Balance"::"Balance Sheet");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccountCategory, GLAccountCategory."Account Category"::"Cost of Goods Sold",
          GLAccountCategory."Income/Balance"::"Income Statement");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccountCategory, GLAccountCategory."Account Category"::Equity,
          GLAccountCategory."Income/Balance"::"Balance Sheet");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccountCategory, GLAccountCategory."Account Category"::Expense,
          GLAccountCategory."Income/Balance"::"Income Statement");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccountCategory, GLAccountCategory."Account Category"::Income,
          GLAccountCategory."Income/Balance"::"Income Statement");
        SetAccountCategoryAndValidateIncomeBalanceField(GLAccountCategory, GLAccountCategory."Account Category"::Liabilities,
          GLAccountCategory."Income/Balance"::"Balance Sheet");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetTotalingGLAccountCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountNo1: Code[20];
        GLAccountNo2: Code[20];
        Totaling: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 273745] Get Totaling in G/L Account Category returns filter for related G/L Accounts

        // [GIVEN] G/L Account Category with "Entry No." = 1
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);

        // [GIVEN] G/L Account "GL1" with "Account Subcategory Entry No." = 1
        GLAccountNo1 := CreateGLAccountWithAccountSubcategoryEntryNo(GLAccountCategory."Entry No.");

        // [GIVEN] G/L Account "GL2" with "Account Subcategory Entry No." = 1
        GLAccountNo2 := CreateGLAccountWithAccountSubcategoryEntryNo(GLAccountCategory."Entry No.");

        // [WHEN] Get Totaling from G/L Account Category
        Totaling := GLAccountCategory.GetTotaling();

        // [THEN] Totaling equals to 'GL1..GL2'
        Assert.AreEqual(GLAccountNo1 + '..' + GLAccountNo2, Totaling, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTotalingGLAccountCategoryWhenNewTotalingIsSame()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountNo: Code[20];
        OldTotaling: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 273745] When Validate Totaling in G/L Account Category with New Totaling = Old Totaling then related G/L Account "Account Subcategory Entry No." is not changed

        // [GIVEN] G/L Account Category with "Entry No." = 1
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);

        // [GIVEN] G/L Account with "Account Subcategory Entry No." = 1
        GLAccountNo := CreateGLAccountWithAccountSubcategoryEntryNo(GLAccountCategory."Entry No.");

        // [GIVEN] Got Old Totaling from G/L Account Category
        OldTotaling := GLAccountCategory.GetTotaling();

        // [WHEN] Validate Totaling in G/L Account Category with New Totaling = Old Totaling
        GLAccountCategory.ValidateTotaling(OldTotaling);

        // [THEN] G/L Account has "Account Subcategory Entry No." = 1
        VerifyGLAccountAccountSubcategoryEntryNo(GLAccountNo, GLAccountCategory."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTotalingGLAccountCategoryWhenNewTotalingBlank()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 273745] When Validate Totaling in G/L Account Category with New Totaling = <blank> then related G/L Account "Account Subcategory Entry No." is cleared

        // [GIVEN] G/L Account Category with "Entry No." = 1
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);

        // [GIVEN] G/L Account with "Account Subcategory Entry No." = 1
        GLAccountNo := CreateGLAccountWithAccountSubcategoryEntryNo(GLAccountCategory."Entry No.");

        // [WHEN] Validate Totaling in G/L Account Category with NewTotaling = <blank>
        GLAccountCategory.ValidateTotaling('');

        // [THEN] G/L Account has "Account Subcategory Entry No." = 0
        VerifyGLAccountAccountSubcategoryEntryNo(GLAccountNo, 0);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTotalingGLAccountCategoryWhenNewTotalingDiff()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountNo1: Code[20];
        GLAccountNo2: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 273745] When Validate Totaling in G/L Account Category with New Totaling = G/L Account No. then related G/L Accounts' "Account Subcategory Entry No." is updated with respect to New Totaling

        // [GIVEN] G/L Account Category with "Entry No." = 1
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);

        // [GIVEN] G/L Account "GL1" with "Account Subcategory Entry No." = 1
        GLAccountNo1 := CreateGLAccountWithAccountSubcategoryEntryNo(GLAccountCategory."Entry No.");

        // [GIVEN] G/L Account "GL2" with "Account Subcategory Entry No." = 1
        GLAccountNo2 := CreateGLAccountWithAccountSubcategoryEntryNo(GLAccountCategory."Entry No.");

        // [WHEN] Validate Totaling in G/L Account Category with NewTotaling = 'GL2'
        GLAccountCategory.ValidateTotaling(GLAccountNo2);

        // [THEN] G/L Account "GL1" has "Account Subcategory Entry No." = 0
        VerifyGLAccountAccountSubcategoryEntryNo(GLAccountNo1, 0);

        // [THEN] G/L Account "GL2" has "Account Subcategory Entry No." = 1
        VerifyGLAccountAccountSubcategoryEntryNo(GLAccountNo2, GLAccountCategory."Entry No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTotalingGLAccountCategoryWhenOldTotalingBlank()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountNo1: Code[20];
        GLAccountNo2: Code[20];
        GLAccountCategoryEntryNo1: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 277436] When Validate Totaling in G/L Account Category with <blank> Totaling, then Totaling in other G/L Account Category is not cleared

        // [GIVEN] G/L Account Category "C1" with "Entry No." = 1
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);
        GLAccountCategoryEntryNo1 := GLAccountCategory."Entry No.";

        // [GIVEN] G/L Account "GL1" with "Account Subcategory Entry No." = 1
        GLAccountNo1 := CreateGLAccountWithAccountSubcategoryEntryNo(GLAccountCategory."Entry No.");

        // [GIVEN] G/L Account Category "C2" with "Entry No." = 2
        GLAccountCategory.Validate("Entry No.", LibraryUtility.GetNewRecNo(GLAccountCategory, GLAccountCategory.FieldNo("Entry No.")));
        GLAccountCategory.Insert(true);

        // [GIVEN] G/L Account "GL2" with "Account Subcategory Entry No." = <blank>
        GLAccountNo2 := CreateGLAccountWithAccountSubcategoryEntryNo(0);

        // [WHEN] Validate Totaling in G/L Account Category "C2" with NewTotaling = 'GL2'
        GLAccountCategory.ValidateTotaling(GLAccountNo2);

        // [THEN] G/L Account "GL1" has "Account Subcategory Entry No." = 1
        VerifyGLAccountAccountSubcategoryEntryNo(GLAccountNo1, GLAccountCategoryEntryNo1);

        // [THEN] G/L Account "GL2" has "Account Subcategory Entry No." = 2
        VerifyGLAccountAccountSubcategoryEntryNo(GLAccountNo2, GLAccountCategory."Entry No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('GLAccountCategoryNotificationHandler')]
    [Scope('OnPrem')]
    procedure GLAccountCategoriesModifyGLAccTotaling()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377715] User receive notification "You changed G/L Account categories which you are using in Account Schedules" after modify record in G/L Account Categories page

        // [GIVEN] G/L Account Category "C1" opened in page "G/L Account Categories"
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);
        GLAccountCategories.OpenEdit();
        GLAccountCategories.Filter.SetFilter("Entry No.", Format(GLAccountCategory."Entry No."));

        // [WHEN] G/L Accounts in Category changed to "ACC"
        LibraryVariableStorage.Enqueue(AccSchedUpdateNeededNotificationAction::"Check Message");
        GLAccountCategories.GLAccTotaling.SetValue(CreateBalanceSheetGLAccountNo());

        // [THEN] Notification "You changed G/L Account categories which you are using in Account Schedules"

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('GLAccountCategoryNotificationHandler,OptionDialogForGenerateAccountSchedules')]
    [Scope('OnPrem')]
    procedure GLAccountCategoriesGenerateAccSchedFromNotification()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377715] User can generate account schedules from notification "You changed G/L Account categories which you are using in Account Schedules" after modify record in G/L Account Categories page

        // [GIVEN] G/L Account Category "C1" opened in page "G/L Account Categories"
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);
        GLAccountCategory."Additional Report Definition" := GLAccountCategory."Additional Report Definition"::" ";
        GLAccountCategory.Description := CopyStr(Format(CreateGuid()), 1, MaxStrLen((GLAccountCategory.Description)));
        GLAccountCategory.Modify();
        GLAccountCategories.OpenEdit();
        GLAccountCategories.Filter.SetFilter("Entry No.", Format(GLAccountCategory."Entry No."));

        // [WHEN] G/L Accounts in Category changed to "ACC" and "Generate Account Schedules" action picked on notification
        LibraryVariableStorage.Enqueue(AccSchedUpdateNeededNotificationAction::"Generate Account Schedules");
        LibraryVariableStorage.Enqueue(2);
        GLAccountCategories.GLAccTotaling.SetValue(CreateBalanceSheetGLAccountNo());
        Commit();

        // [THEN] Account schedule "Balance Sheet" contains new account category "C1"
        VerfiyBalanceSheetAccountScheduleLine(GLAccountCategory);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('GLAccountCategoryNotificationHandler')]
    [Scope('OnPrem')]
    procedure GLAccountCategoriesSkipShowNotification()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377715] User can disable notification "You changed G/L Account categories which you are using in Account Schedules" after modify record in G/L Account Categories page

        // [GIVEN] G/L Account Category "C1" opened in page "G/L Account Categories"
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);
        GLAccountCategories.OpenEdit();
        GLAccountCategories.Filter.SetFilter("Entry No.", Format(GLAccountCategory."Entry No."));

        // [WHEN] G/L Accounts in Category changed to "ACC" and "Don't show again" action picked
        LibraryVariableStorage.Enqueue(AccSchedUpdateNeededNotificationAction::"Disable Notification");
        GLAccountCategories.GLAccTotaling.SetValue(CreateBalanceSheetGLAccountNo());

        // [THEN] Notification is switched off for current user
        VerifyMyNotificationsAccSchedUpdateNeeded();

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('GLAccountCategoryNotificationHandler')]
    [Scope('OnPrem')]
    procedure GLAccountCategoryDelete()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        // [FEATURE] 
        // [SCENARIO 377715] User receive notification "You changed G/L Account categories which you are using in Account Schedules" after delete record in G/L Account Categories page

        // [GIVEN] G/L Account Category "C1" 
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);

        // [WHEN] Account Category "C1" is being deleted
        LibraryVariableStorage.Enqueue(AccSchedUpdateNeededNotificationAction::"Check Message");
        GLAccountCategory.Delete(true);

        // [THEN] Notification "You changed G/L Account categories which you are using in Account Schedules"

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('GLAccountCategoryNotificationHandler')]
    [Scope('OnPrem')]
    procedure ChangeGLAccountSubCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
        GLAccountCard: TestPage "G/L Account Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377715] User receive notification "You changed G/L Account categories which you are using in Account Schedules" after change Account Subcategory on G/L Account

        // [GIVEN] G/L Account Category "C1" with "G/L Accounts in Category" = "A1"
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);
        GLAccount.Get(CreateBalanceSheetGLAccountNo());
        GLAccount.Validate("Account Category", GLAccountCategory."Account Category");
        GLAccount.Validate("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        GLAccount.Modify();

        // [WHEN] Account Subcategory is being cleared for account "A1"
        LibraryVariableStorage.Enqueue(AccSchedUpdateNeededNotificationAction::"Check Message");
        GLAccountCard.OpenEdit();
        GLAccountCard.Filter.SetFilter("No.", GLAccount."No.");
        GLAccountCard.SubCategoryDescription.SetValue('');

        // [THEN] Notification "You changed G/L Account categories which you are using in Account Schedules"

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure CreateGLAccountWithAccountSubcategoryEntryNo(AccountSubcategoryEntryNo: Integer): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Account Subcategory Entry No.", AccountSubcategoryEntryNo);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateBalanceSheetGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure MockGenerateAccountSchedules()
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        GLAccountCategoryMgt.ConfirmAndRunGenerateAccountSchedules();
    end;

    local procedure MockDisableNotification(var Notification: Notification)
    var
        CategGenerateAccSchedules: Codeunit "Categ. Generate Acc. Schedules";
    begin
        CategGenerateAccSchedules.HideAccSchedUpdateNeededNotificationForCurrentUser(Notification);
    end;

    local procedure SetAccountCategoryAndValidateIncomeBalanceField(GLAccountCategory: Record "G/L Account Category"; AccountCategory: Option; IncomeBalance: Enum "G/L Account Report Type")
    begin
        GLAccountCategory.Validate("Account Category", AccountCategory);
        GLAccountCategory.TestField("Income/Balance", IncomeBalance);
        GLAccountCategory.TestField(Description, Format(GLAccountCategory."Account Category"));
    end;

    local procedure FindFirstParentGLAccountCategory(var GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.SetRange("Parent Entry No.", 0);
        GLAccountCategory.FindFirst();
    end;

    local procedure VerifyGLAccountAccountSubcategoryEntryNo(GLAccountNo: Code[20]; ExpectedAccountSubcategoryEntryNo: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.TestField("Account Subcategory Entry No.", ExpectedAccountSubcategoryEntryNo);
    end;

    local procedure VerfiyCashFlowStatementAccountScheduleLines()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        AccScheduleLineArray: array[3] of Record "Acc. Schedule Line";
    begin
        GeneralLedgerSetup.Get();
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt");
        AccScheduleLine.SetRange("Schedule Name", FinancialReport."Financial Report Row Group");
        AccScheduleLine.FindSet();
        AccScheduleLine.Next();
        AccScheduleLineArray[1] := AccScheduleLine;
        AccScheduleLine.Next();
        AccScheduleLineArray[2] := AccScheduleLine;
        AccScheduleLine.Next(5);
        AccScheduleLineArray[3] := AccScheduleLine;
        AccScheduleLine.Next();
        AccScheduleLine.TestField(
          Totaling,
          StrSubstNo(
            '%1+%2..%3',
            AccScheduleLineArray[1]."Row No.", AccScheduleLineArray[2]."Row No.", AccScheduleLineArray[3]."Row No."));

        AccScheduleLine.Next(12);
        AccScheduleLineArray[1] := AccScheduleLine;
        AccScheduleLine.TestField("Show Opposite Sign", true);

        AccScheduleLine.Next();
        AccScheduleLineArray[2] := AccScheduleLine;

        AccScheduleLine.Next();
        AccScheduleLine.TestField(
          Totaling,
          StrSubstNo('-%1+%2', AccScheduleLineArray[1]."Row No.", AccScheduleLineArray[2]."Row No."));
    end;

    local procedure VerfiyBalanceSheetAccountScheduleLine(GLAccountCategory: Record "G/L Account Category")
    var
        GLSetup: Record "General Ledger Setup";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
    begin
        GLSetup.Get();
        FinancialReport.Get(GLSetup."Fin. Rep. for Balance Sheet");
        AccScheduleLine.SetRange("Schedule Name", FinancialReport."Financial Report Row Group");
        AccScheduleLine.SetRange(Description, GLAccountCategory.Description);
        AccScheduleLine.FindFirst();
        AccScheduleLine.TestField(Totaling, GLAccountCategory.GetTotaling());
    end;

    local procedure VerifyMyNotificationsAccSchedUpdateNeeded()
    var
        GLAccountCategory: Record "G/L Account Category";
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Get(UserId(), GLAccountCategory.GetAccSchedUpdateNeededNotificationId());
        MyNotifications.TestField(Enabled, false);
        MyNotifications.Delete();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure GLAccountCategoryNotificationHandler(var Notification: Notification): Boolean
    begin
        case LibraryVariableStorage.DequeueInteger() of
            AccSchedUpdateNeededNotificationAction::"Check Message":
                Assert.AreEqual(AccSchedUpdateNeededNotificationMsg, Notification.Message, 'A different notification is being sent.');
            AccSchedUpdateNeededNotificationAction::"Generate Account Schedules":
                MockGenerateAccountSchedules();
            AccSchedUpdateNeededNotificationAction::"Disable Notification":
                MockDisableNotification(Notification);
        end;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OptionDialogForGenerateAccountSchedules(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;
}

