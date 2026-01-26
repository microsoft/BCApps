codeunit 135407 "Prepayments Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [Prepayments] [UI] [User Group Plan]
    end;

    var
        Assert: Codeunit Assert;
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        TeamMemberErr: Label 'You are logged in as a Team Member role, so you cannot complete this task.';

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,SelectCustomerTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsBusinessManager()
    var
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as a Business Manager

        Initialize();
        // [GIVEN] An item
        ItemNo := CreateItem();
        // [GIVEN] A user with Business Manager Plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent);

        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,SelectCustomerTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsExternalAccountant()
    var
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as a Business Manager

        Initialize();
        // [GIVEN] An item
        ItemNo := CreateItem();
        // [GIVEN] A user with External Accountant Plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent);

        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,SelectCustomerTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsTeamMember()
    var
        ErrorMessagesPage: TestPage "Error Messages";
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as a Business Manager

        Initialize();
        // [GIVEN] An item
        ItemNo := CreateItem();
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent);
        Commit();

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        asserterror CreateSalesOrder(CustomerNo, ItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        Commit();

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        ErrorMessagesPage.Trap();
        PostSalesOrder(SalesOrderNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(TeamMemberErr, ErrorMessagesPage.Description.Value);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,SelectCustomerTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsEssentialISVEmbUser()
    var
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as an Essential ISV Emb User

        Initialize();
        // [GIVEN] An item
        ItemNo := CreateItem();
        // [GIVEN] A user with Essential ISV Plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent);

        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,SelectCustomerTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsTeamMemberISVEmb()
    var
        ErrorMessagesPage: TestPage "Error Messages";
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as a Team Member ISV Emb

        Initialize();
        // [GIVEN] An item
        ItemNo := CreateItem();
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent);
        Commit();

        // [GIVEN] A user with Team Member ISV Emb Plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        asserterror CreateSalesOrder(CustomerNo, ItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('TestValidation');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        Commit();

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        ErrorMessagesPage.Trap();
        PostSalesOrder(SalesOrderNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(TeamMemberErr, ErrorMessagesPage.Description.Value);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,SelectCustomerTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler')]
    [Scope('OnPrem')]
    procedure TestPrepaymentsInSalesOrderAsDeviceISVEmbUser()
    var
        PrepaymentPercent: Decimal;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SalesOrderNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order containing Prepayments as an Device ISV Emb User

        Initialize();
        // [GIVEN] An item
        ItemNo := CreateItem();
        // [GIVEN] A user with Device ISV Plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();
        // [GIVEN] A customer with a Prepayment Setup
        CustomerNo := CreateCustomer(PrepaymentPercent);

        // [WHEN] A sales order is created, the lines are automatically filled with a prepayment amount
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [WHEN] The prepayment invoice and the sales order are posted
        PostSalesOrderPrepayments(SalesOrderNo);
        PostedSalesInvoiceNo := PostSalesOrder(SalesOrderNo, false);
        // [THEN] The posted sales invoice contains lines deducting the prepayment amount
        VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo, PrepaymentPercent);
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Prepayments Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        LibraryVariableStorage.Clear();

        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Prepayments Plan-based E2E");

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        LibraryERMCountryData.CreateVATData();

        CreateSalesPrepmtInvNosInSetup();
        SetupNewSalesPrepaymentAccount();
        CreatePurchPrepmtInvNosInSetup();
        SetupNewPurchPrepaymentAccount();
        LibraryTemplates.UpdateTemplatesVATGroups();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Prepayments Plan-based E2E");
    end;

    local procedure CreateSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]) SalesOrderNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer No.".SetValue(CustomerNo);
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 10));
        SalesOrder.SalesLines."Unit Price".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        SalesOrderNo := SalesOrder."No.".Value();
        SalesOrder.OK().Invoke();
    end;

    local procedure PostSalesOrderPrepayments(SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesOrder.PostPrepaymentInvoice.Invoke();
        SalesOrder.Close();
    end;

    local procedure PostSalesOrder(SalesOrderNo: Code[20]; ExpectFailure: Boolean) PostedSalesOrderNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesOrder.Post.Invoke();
        if not ExpectFailure then
            PostedSalesOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(PostedSalesOrderNo));
    end;

    local procedure CreateItem() ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        ItemNo := ItemCard."No.".Value();
        ItemCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateCustomer(var PrepaymentPercentage: Decimal) CustomerNo: Code[20]
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        PrepaymentPercentage := LibraryRandom.RandDecInRange(1, 100, 2);
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        CustomerCard."Prepayment %".SetValue(PrepaymentPercentage);
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.OK().Invoke();
        Commit();
    end;

    local procedure VerifyPostedSalesInvoicePrepayment(PostedSalesInvoiceNo: Code[20]; ExpectedPrepaymentPercentage: Decimal)
    var
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PrepaymentAmount: Decimal;
        ItemLineAmount: Decimal;
        ExpectedPrepaymentAmount: Decimal;
    begin
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoKey(PostedSalesInvoiceNo);
        PostedSalesInvoice.SalesInvLines.Next();
        Assert.AreEqual(Format(SalesLine.Type::Item), PostedSalesInvoice.SalesInvLines.FilteredTypeField.Value, '');
        Assert.IsTrue(
          Evaluate(ItemLineAmount, PostedSalesInvoice.SalesInvLines."Line Amount".Value), 'Evaluate Failed On Item Line Amount');
        ExpectedPrepaymentAmount := -ItemLineAmount * ExpectedPrepaymentPercentage / 100.0;
        PostedSalesInvoice.SalesInvLines.Next();
        Assert.AreEqual(Format(SalesLine.Type::"G/L Account"), PostedSalesInvoice.SalesInvLines.FilteredTypeField.Value, '');
        Assert.IsTrue(
          Evaluate(PrepaymentAmount, PostedSalesInvoice.SalesInvLines."Line Amount".Value), 'Evaluate Failed On Prepayment Amount');
        Assert.AreNotEqual(0.0, PrepaymentAmount, '');
        Assert.AreNearlyEqual(ExpectedPrepaymentAmount, PrepaymentAmount, 0.01, '');
        PostedSalesInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListModalPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorTemplListModalPageHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        SelectVendorTemplList.First();
        SelectVendorTemplList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OrderPostActionHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3 // Receive/Ship & Invoice
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvoice."No.".Value);
        PostedSalesInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicePageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedPurchaseInvoice."No.".Value);
        PostedPurchaseInvoice.Close();
    end;

    local procedure CreateSalesPrepmtInvNosInSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Inv. Nos.", SalesReceivablesSetup."Posted Invoice Nos.");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetupNewSalesPrepaymentAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        GeneralPostingSetup.FindSet();
        repeat
            AttachSalesPrepaymentAccountInSetup(GeneralPostingSetup, GLAccountNo);
        until GeneralPostingSetup.Next() = 0;
    end;

    local procedure AttachSalesPrepaymentAccountInSetup(var GeneralPostingSetup: Record "General Posting Setup"; SalesPrepaymentsAccount: Code[20]) SalesPrepaymentsAccountOld: Code[20]
    begin
        SalesPrepaymentsAccountOld := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreatePurchPrepmtInvNosInSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Prepmt. Inv. Nos.", PurchasesPayablesSetup."Posted Invoice Nos.");
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure SetupNewPurchPrepaymentAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        GeneralPostingSetup.FindSet();
        repeat
            AttachPurchPrepaymentAccountInSetup(GeneralPostingSetup, GLAccountNo);
        until GeneralPostingSetup.Next() = 0;
    end;

    local procedure AttachPurchPrepaymentAccountInSetup(var GeneralPostingSetup: Record "General Posting Setup"; PurchPrepaymentsAccount: Code[20]) PurchPrepaymentsAccountOld: Code[20]
    begin
        PurchPrepaymentsAccountOld := GeneralPostingSetup."Purch. Prepayments Account";
        GeneralPostingSetup.Validate("Purch. Prepayments Account", PurchPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;
}
