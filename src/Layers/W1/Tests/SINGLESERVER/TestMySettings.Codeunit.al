codeunit 139006 "Test My Settings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [My Settings] [Role Center] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        EnabledValue: Boolean;
        ActionToDo: Option SetValue,VerifyValue;
        MyNotificationFilterTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Table18">VERSION(1) SORTING(Field1) WHERE(Field1=1(%1))</DataItem></DataItems></ReportParameters>';

    [Test]
    [HandlerFunctions('AvailableRoleCentersHandlerBlankProfileIsHidden')]
    [Scope('OnPrem')]
    procedure TestBlankRoleCenterIsHiddenOnMySettings()
    var
        UserSettings: TestPage "User Settings";
    begin
        // [WHEN] The user changes the Role Center in "My Settings" window, and chooses OK
        UserSettings.OpenEdit();
        UserSettings.UserRoleCenter.AssistEdit();
        // [THEN] The Blank Role Center is Hidden
        // Verify in AvailableRoleCentersHandlerBlankProfileIsHidden
    end;

    [Scope('OnPrem')]
    procedure TestDefaultRoleCenterShownByDefault()
    var
        AllProfile: Record "All Profile";
        UserSettings: TestPage "User Settings";
        Scope: Option System,Tenant;
        AppID: Guid;
    begin
        // [GIVEN] The user hasn't chosen a Role Center
        Initialize();

        // [THEN] The Default Role Center is shown in "My Settings" page "Role Center" field
        AllProfile.Get(Scope::Tenant, AppID, 'BUSINESS MANAGER');
        AllProfile.Validate("Default Role Center", true);
        AllProfile.Modify(true);
        UserSettings.OpenEdit();
        UserSettings.UserRoleCenter.AssertEquals(AllProfile.Description);
        UserSettings.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostingAfterWorkingDate()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        UserSettings: TestPage "User Settings";
    begin
        // [FEATURE] [Posting After Working Date]
        // [SCENARIO 169269] "My Settings" page saved the value of setup "Posting After Working Date"
        Initialize();

        // [GIVEN] Opened page "My Settings"
        UserSettings.OpenEdit();

        // [WHEN] Set "Posting After Working Date Not Allowed" = False, close "My Settings" page and open once again
        ActionToDo := ActionToDo::VerifyValue;
        EnabledValue := true;
        UserSettings.MyNotificationsLbl.DrillDown();

        // [THEN] Default value of the Posting dialog is True- verified in the MyNotificationsModalPageHandler.

        // [WHEN] Set "Posting After Working Date Not Allowed" = False, close "My Settings" page and open once again
        ActionToDo := ActionToDo::SetValue;
        EnabledValue := false;
        UserSettings.MyNotificationsLbl.DrillDown();
        UserSettings.Close();
        UserSettings.OpenView();

        // [THEN] InstructionMgt
        Assert.IsFalse(InstructionMgt.IsEnabled(InstructionMgt.PostingAfterWorkingDateNotAllowedCode()),
          'Disabling should invoke the OnStateChanged event for MyNotifications.');

        // [THEN] Value of "Posting After Working Date" in "My Settings" page is FALSE
        ActionToDo := ActionToDo::VerifyValue;
        UserSettings.MyNotificationsLbl.DrillDown();
        UserSettings.Close();

        // Tear Down
        InstructionMgt.EnableMessageForCurrentUser(InstructionMgt.PostingAfterWorkingDateNotAllowedCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MyNotificatioPageIsFilteredWithUserID()
    var
        MyNotifications: TestPage "My Notifications";
    begin
        // [FEATURE] [My Notifications] [User] [UT]
        // [SCENARIO 382390] Page 1518 "My Notifications" is filtered with USERID value
        MyNotifications.OpenView();
        Assert.AreEqual(UserId(), MyNotifications.FILTER.GetFilter("User Id"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsForPostingAccountTypesAreVisible()
    var
        MyAccount: Record "My Account";
        MyAccountsTestPage: TestPage "My Accounts";
        GLAccountBalance: array[2] of Decimal;
        GLAccountNo: array[2] of Code[20];
    begin
        // [SCENARIO 211089] "My Accounts" subpage for GLAccount (Posting type) populates the Balance field and drills down with GL Entries filtered for that GLAccount.No.
        Initialize();

        // [GIVEN] G/L Accounts "AC1" and "AC2" with G/L Entries with Amounts = 100 and 200 respectively.
        PrepareTwoGLAccountsWithGLEntries(GLAccountNo, GLAccountBalance);

        // [GIVEN] "AC1" and "AC2" are added to "My Account" table as "MyAcc" record.
        CreateMyAccountRecord(MyAccount, GLAccountNo[1]);
        CreateMyAccountRecord(MyAccount, GLAccountNo[2]);

        // [WHEN] My Accounts page is opened for "MyAcc" for the "AC1" G/L Account.
        MyAccountsTestPage.OpenEdit();
        MyAccountsTestPage.GotoRecord(MyAccount);

        // [THEN] The Balance field is = 100 for "AC1" and 200 for "AC2"
        // [THEN] DrillDown on the Balance field is opening General Ledger Entries with filter for "AC1" or "AC2" accordingly.
        MyAccountsTestPage.First();
        VerifyGLAccountBalanceAndEntriesFilterOnDrillDown(
          MyAccountsTestPage, GLAccountNo[1], GLAccountBalance[1]);
        MyAccountsTestPage.Last();
        VerifyGLAccountBalanceAndEntriesFilterOnDrillDown(
          MyAccountsTestPage, GLAccountNo[2], GLAccountBalance[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsForTotalingAccountTypesAreNotZeroWhenUnselected()
    var
        TotalingGLAccount: Record "G/L Account";
        MyAccount: Record "My Account";
        MyAccountsTestPage: TestPage "My Accounts";
        GLAccountBalance: array[2] of Decimal;
        TotalingBalance: Decimal;
        GLAccountNo: array[2] of Code[20];
    begin
        // [SCENARIO 212332] Balance value is not cleared when the totaling G/L Account has been added to "My Accounts" page and then another account selected.
        Initialize();

        // [GIVEN] G/L Accounts "AC1" and "AC2" with G/L Entries with Amounts = 100 and 200 respectively.
        PrepareTwoGLAccountsWithGLEntries(GLAccountNo, GLAccountBalance);

        // [GIVEN] Totaling G/L Account "ACT" where "ACT".Totaling = "AC1"|"AC2" and "ACT".Balance is 300.
        PrepareTotalingGLAccount(Format(GLAccountNo[1]) + '|' + Format(GLAccountNo[2]), TotalingGLAccount, TotalingBalance);

        // [GIVEN] "AC1" and "AC2" are added to "My Account" table as "MyAcc" record.
        CreateMyAccountRecord(MyAccount, GLAccountNo[1]);
        CreateMyAccountRecord(MyAccount, GLAccountNo[2]);

        // [GIVEN] "My Accounts" page is opened for "MyAcc" record.
        MyAccountsTestPage.OpenEdit();
        MyAccountsTestPage.GotoRecord(MyAccount);

        // [WHEN] "ACT" is added on the "My Accounts" page.
        MyAccountsTestPage.New();
        MyAccountsTestPage."Account No.".SetValue := TotalingGLAccount."No.";
        MyAccountsTestPage.Balance.Activate();

        // [THEN] "ACT" Balance is 300.
        MyAccountsTestPage.Balance.AssertEquals(TotalingBalance);

        // [THEN] Moving through the page and selecting each record, the Balance amounts are not cleared.
        MyAccountsTestPage.First();
        VerifyGLAccountNoAndBalance(MyAccountsTestPage, GLAccountNo[1], GLAccountBalance[1]);
        MyAccountsTestPage.Next();
        VerifyGLAccountNoAndBalance(MyAccountsTestPage, GLAccountNo[2], GLAccountBalance[2]);
        MyAccountsTestPage.Last();
        VerifyGLAccountNoAndBalance(MyAccountsTestPage, TotalingGLAccount."No.", TotalingBalance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMyNotifications_IsEnabledForRecord_IsFalse()
    var
        MyNotifications: Record "My Notifications";
        Customer: array[2] of Record Customer;
        Result: Boolean;
    begin
        // [FEATURE] [My Notifications] [UT]
        // [SCENARIO 220587] MyNotification.IsEnabledForRecord returns FALSE when the record is out of the filters.
        Initialize();
        MyNotifications.DeleteAll();

        // [GIVEN] Two Customers "C1" and "C2"
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] My Notification entry for Customer Credit Limit check with filter for "C1"."No.".
        SetupMyNotificationsForCredirLimitCheck(MyNotifications, Customer[1]."No.");

        // [WHEN] Public function MyNotifications.IsEnabledForRecord is invoked for "C2".
        Result := MyNotifications.IsEnabledForRecord(MyNotifications."Notification Id", Customer[2]);

        // [THEN] The MyNotification.IsEnabledForRecord returns false.
        Assert.IsFalse(Result, 'MyNotifications.IsEnabledForRecord must return FALSE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMyNotifications_IsEnabledForRecord_IsTrue()
    var
        MyNotifications: Record "My Notifications";
        Customer: Record Customer;
        Result: Boolean;
    begin
        // [FEATURE] [My Notifications] [UT]
        // [SCENARIO 220587] MyNotification.IsEnabledForRecord returns TRUE when the record is within the filter.
        Initialize();
        MyNotifications.DeleteAll();

        // [GIVEN] Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] My Notification entry for Customer Credit Limit check with filter for Customer."No.".
        SetupMyNotificationsForCredirLimitCheck(MyNotifications, Customer."No.");

        // [WHEN] Public function MyNotifications.IsEnabledForRecord is invoked for Customer.
        Result := MyNotifications.IsEnabledForRecord(MyNotifications."Notification Id", Customer);

        // [THEN] The MyNotification.IsEnabledForRecord returns true.
        Assert.IsTrue(Result, 'MyNotifications.IsEnabledForRecord must return TRUE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowExternalDocAlreadyExistNotificationDefaultStateTRUE()
    var
        MyNotifications: Record "My Notifications";
        PurchaseHeader: Record "Purchase Header";
        MyNotificationsPage: TestPage "My Notifications";
    begin
        // [FEATURE] [My Notifications] [UT] [Purchase] [External Document No.] [UI]
        // [SCENARIO 272152] "Purchase document with same external document number already exists." is enabled by default
        Initialize();
        MyNotifications.DeleteAll();

        MyNotificationsPage.OpenView();

        Assert.IsTrue(MyNotifications.IsEnabled(PurchaseHeader.GetShowExternalDocAlreadyExistNotificationId()), '');
    end;

    local procedure Initialize()
    var
        UserPersonalization: Record "User Personalization";
        MyAccount: Record "My Account";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        UserPersonalization.Get(UserSecurityId());
        Clear(UserPersonalization."Profile ID");
        Clear(UserPersonalization."App ID");
        Clear(UserPersonalization.Scope);
        UserPersonalization.Modify();
        MyAccount.DeleteAll();
    end;

    local procedure PrepareTwoGLAccountsWithGLEntries(var GLAccountNo: array[2] of Code[20]; var GLAccountBalance: array[2] of Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLAccount: array[2] of Record "G/L Account";
        AccountNo: Integer;
    begin
        for AccountNo := 1 to ArrayLen(GLAccount) do begin
            LibraryERM.CreateGLAccount(GLAccount[AccountNo]);
            GLEntry.Init();
            GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
            GLEntry."G/L Account No." := GLAccount[AccountNo]."No.";
            GLEntry.Amount := LibraryRandom.RandDec(100, 2);
            GLEntry.Insert();
            GLAccountNo[AccountNo] := GLEntry."G/L Account No.";
            GLAccountBalance[AccountNo] := GLEntry.Amount;
        end;
    end;

    local procedure PrepareTotalingGLAccount(TotalingValue: Text[250]; var TotalingGLAccount: Record "G/L Account"; var TotalingBalance: Decimal)
    begin
        LibraryERM.CreateGLAccount(TotalingGLAccount);
        TotalingGLAccount."Account Type" := TotalingGLAccount."Account Type"::"End-Total";
        TotalingGLAccount.Totaling := TotalingValue;
        TotalingGLAccount.Modify();
        TotalingGLAccount.CalcFields(Balance);
        TotalingBalance := TotalingGLAccount.Balance;
    end;

    local procedure CreateMyAccountRecord(var MyAccount: Record "My Account"; GLAccountNo: Code[20])
    begin
        MyAccount.Init();
        MyAccount."User ID" := CopyStr(UserId(), 1, MaxStrLen(MyAccount."User ID"));
        MyAccount.Validate("Account No.", GLAccountNo);
        MyAccount.Insert();
    end;

    local procedure VerifyGLAccountBalanceAndEntriesFilterOnDrillDown(MyAccountsTestPage: TestPage "My Accounts"; GLAccountNo: Code[20]; ExpectedBalance: Decimal)
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        MyAccountsTestPage.Balance.AssertEquals(ExpectedBalance);
        GeneralLedgerEntries.Trap();
        MyAccountsTestPage.Balance.DrillDown();
        Assert.AreEqual(
          Format(GLAccountNo),
          GeneralLedgerEntries.FILTER.GetFilter("G/L Account No."),
          'Filter value for G/L Account is expected.');
    end;

    local procedure VerifyGLAccountNoAndBalance(MyAccountsTestPage: TestPage "My Accounts"; GLAccountNo: Code[20]; Balance: Decimal)
    begin
        MyAccountsTestPage."Account No.".AssertEquals(GLAccountNo);
        MyAccountsTestPage.Balance.AssertEquals(Balance);
    end;

    local procedure SetupMyNotificationsForCredirLimitCheck(var MyNotifications: Record "My Notifications"; FilterValue: Text)
    var
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
        FiltersOutStream: OutStream;
    begin
        MyNotifications.InsertDefaultWithTableNum(
          CustCheckCrLimit.GetCreditLimitNotificationId(),
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(),
          DATABASE::Customer);
        MyNotifications.Enabled := true;
        MyNotifications."Apply to Table Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.Write(StrSubstNo(MyNotificationFilterTxt, FilterValue));
        MyNotifications.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableRoleCentersHandlerBlankProfileIsHidden(var Roles: TestPage Roles)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.Get(AllProfile.Scope::Tenant, '63ca2fa4-4f03-4f2b-a480-172fef340d3f', 'BLANK');
        Assert.IsFalse(Roles.GotoRecord(AllProfile), 'The Blank Profile was not hidden.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MyNotificationsModalPageHandler(var MyNotifications: TestPage "My Notifications")
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        MyNotifications.FILTER.SetFilter("Notification Id", InstructionMgt.GetPostingAfterWorkingDateNotificationId());
        case ActionToDo of
            ActionToDo::SetValue:
                MyNotifications.Enabled.SetValue(EnabledValue);
            ActionToDo::VerifyValue:
                MyNotifications.Enabled.AssertEquals(EnabledValue);
        end;
    end;
}
