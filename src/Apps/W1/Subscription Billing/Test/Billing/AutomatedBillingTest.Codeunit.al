namespace Microsoft.SubscriptionBilling;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using System.Security.User;
using System.Threading;

codeunit 148455 "Automated Billing Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        ContractTestLibrary: Codeunit "Contract Test Library";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    #region Test

    [Test]
    procedure VerifyAutomatedBillingAuthorization()
    var
        UserSetup: Record "User Setup";
        BillingTemplate: Record "Billing Template";
        AutoContractBillingNotAllowedErr: Label 'You cannot change the auto billing templates because you are not set up as an Auto Contract Billing user in the User Setup.', Locked = true;
    begin
        // [SCENARIO] Verify that only users with Auto Contract Billing permission can set automation on billing templates
        Initialize();

        // [GIVEN] A user without Auto Contract Billing permission
        InitUserSetupWithoutAuthorizationForAutomatedBilling(UserSetup);

        // [WHEN] User tries to create a billing template with automation
        ContractTestLibrary.CreateDefaultRecurringBillingTemplateForServicePartner(BillingTemplate, BillingTemplate.Partner::Customer);
        Commit(); // The Billing Template must be committed before validating the Automation field.

        // [THEN] Setting automation should fail
        asserterror BillingTemplate.Validate(Automation, BillingTemplate.Automation::"Create Billing Proposal and Documents");
        Assert.ExpectedError(AutoContractBillingNotAllowedErr);

        // [GIVEN] A user with Auto Contract Billing permission
        InitUserSetupWithAuthorizationForAutomatedBilling(UserSetup);

        // [WHEN] User tries to set automation
        BillingTemplate.Validate(Automation, BillingTemplate.Automation::"Create Billing Proposal and Documents");
        BillingTemplate.Modify(true);

        // [THEN] Automation should be set successfully
        BillingTemplate.TestField(Automation, BillingTemplate.Automation::"Create Billing Proposal and Documents");
    end;

    [Test]
    procedure CreateJobQueueEntryForBillingTemplate()
    var
        JobQueueEntry: Record "Job Queue Entry";
        BillingTemplate: Record "Billing Template";
    begin
        // [SCENARIO] Verify that a Job Queue Entry is created correctly for a Billing Template with automation settings
        Initialize();

        // [WHEN] Create a Billing Template with automation settings
        CreateBillingTemplateWithAutomation(BillingTemplate);

        // [THEN] Verify Job Queue Entry is created with correct parameters
        JobQueueEntry.Get(BillingTemplate."Batch Recurrent Job Id");
        Assert.AreEqual(JobQueueEntry."Object Type to Run"::Codeunit, JobQueueEntry."Object Type to Run", 'Object Type should be Codeunit.');
        Assert.AreEqual(Codeunit::"Auto Contract Billing", JobQueueEntry."Object ID to Run", 'Object ID should be Auto Contract Billing codeunit.');
        Assert.IsTrue(JobQueueEntry."Recurring Job", 'Job should be recurring');
        Assert.AreEqual(BillingTemplate."Minutes between runs", JobQueueEntry."No. of Minutes between Runs", 'Minutes between runs should match.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExchangeRateSelectionModalPageHandler')]
    procedure RunAutomatedProcessingForNewBillingTemplate()
    var
        CustomerSubscriptionContract: Record "Customer Subscription Contract";
        SubscriptionHeader: Record "Subscription Header";
        BillingTemplate: Record "Billing Template";
        BillingLine: Record "Billing Line";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Verify that automated billing processes contracts correctly for a Billing Template with automation settings
        Initialize();

        // [GIVEN] A Billing Template with automation settings
        CreateBillingTemplateWithAutomation(BillingTemplate);

        // [WHEN] Bill the contracts automatically
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerSubscriptionContract, SubscriptionHeader, '');
        BillingTemplate.BillContractsAutomatically();

        // [THEN] Verify that Sales Header is created for the billed contract
        BillingLine.SetRange("Subscription Contract No.", CustomerSubscriptionContract."No.");
        BillingLine.FindSet();
        BillingLine.TestField("Document No.");
        SalesHeader.Get(BillingLine.GetSalesDocumentTypeFromBillingDocumentType(), BillingLine."Document No.");
        SalesHeader.TestField("Auto Contract Billing", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExchangeRateSelectionModalPageHandler')]
    procedure TestCreationOfContractBillingErrorLog()
    var
        CustomerSubscriptionContract: Record "Customer Subscription Contract";
        SubscriptionHeader: Record "Subscription Header";
        SubscriptionLine: Record "Subscription Line";
        BillingTemplate: Record "Billing Template";
        ContractBillingErrLog: Record "Contract Billing Err. Log";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUOMDoesNotExistErr: Label 'The Unit of Measure of the Subscription (%1) contains a value (%2) that cannot be found in the Item Unit of Measure of the corresponding Invoicing Item (%3).', Comment = '%1 = Subscription No., %2 = Unit Of Measure Code, %3 = Item No.', Locked = true;
    begin
        // [SCENARIO] Verify that a Contract Billing Error Log is created when an error occurs during automated billing
        Initialize();

        // [GIVEN] A Billing Template with automation settings and a contract that will produce an error
        CreateBillingTemplateWithAutomation(BillingTemplate);
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerSubscriptionContract, SubscriptionHeader, '');

        // [GIVEN]Remove Item UOM to cause error during billing
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.FindLast();
        ItemUnitOfMeasure.Get(SubscriptionLine."Invoicing Item No.", SubscriptionHeader."Unit of Measure");
        ItemUnitOfMeasure.Delete();

        // [WHEN] Bill the contracts automatically
        BillingTemplate.BillContractsAutomatically();

        // [THEN] Verify error log is created with correct details
        ContractBillingErrLog.FindLast();
        Assert.AreEqual(StrSubstNo(ItemUOMDoesNotExistErr, SubscriptionHeader."No.", SubscriptionHeader."Unit of Measure", SubscriptionLine."Invoicing Item No."), ContractBillingErrLog."Error Text", 'Error message should match');
    end;

    #endregion

    #region Procedures

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Automated Billing Test");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Automated Billing Test");

        ContractTestLibrary.InitContractsApp();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Automated Billing Test");
    end;

    local procedure CreateBillingTemplateWithAutomation(var BillingTemplate: Record "Billing Template")
    var
        UserSetup: Record "User Setup";
    begin
        ContractTestLibrary.CreateDefaultRecurringBillingTemplateForServicePartner(BillingTemplate, BillingTemplate.Partner::Customer);
        InitUserSetupWithAuthorizationForAutomatedBilling(UserSetup);
        BillingTemplate.Validate(Automation, BillingTemplate.Automation::"Create Billing Proposal and Documents");
        BillingTemplate.Modify(true);
    end;

    local procedure InitUserSetup(var UserSetup: Record "User Setup")
    begin
        if not UserSetup.Get(UserId()) then begin
            UserSetup.Init();
            UserSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID"));
            UserSetup.Insert(true);
        end;
    end;

    local procedure InitUserSetupWithAuthorizationForAutomatedBilling(var UserSetup: Record "User Setup")
    begin
        InitUserSetup(UserSetup);
        UserSetup."Auto Contract Billing" := true;
        UserSetup.Modify(true);
    end;

    local procedure InitUserSetupWithoutAuthorizationForAutomatedBilling(var UserSetup: Record "User Setup")
    begin
        InitUserSetup(UserSetup);
        UserSetup."Auto Contract Billing" := false;
        UserSetup.Modify(true);
    end;

    #endregion

    #region Handlers

    [ModalPageHandler]
    procedure ExchangeRateSelectionModalPageHandler(var ExchangeRateSelectionPage: TestPage "Exchange Rate Selection")
    begin
        ExchangeRateSelectionPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    #endregion
}
