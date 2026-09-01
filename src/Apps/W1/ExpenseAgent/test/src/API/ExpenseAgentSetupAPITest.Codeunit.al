// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.NoSeries;
using System.Agents;
using System.TestLibraries.Utilities;

codeunit 148333 "Expense Agent Setup API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseAgentSetup', Locked = true;
        EmailAddressTok: Label 'emailAddress', Locked = true;
        CopyEmployeesToExpenseUsersQst: Label 'Do you want to copy existing employees to expense users?';

    [Test]
    procedure EmailAddressFieldIsExposedThroughAPI()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TargetURL: Text;
        ResponseText: Text;
        ExpectedEmailValue: Text;
    begin
        // [SCENARIO] Service-side flows (notably the welcome notification) need
        // the inbound receipts email address that admins configure on the
        // Expense Agent Setup. Page 6942 "Expense Agent Setup API" must surface
        // it as ``emailAddress`` so the connector can pull it.
        // Issue: https://microsoft.ghe.com/bic/BC-ExpenseAgent/issues/1677
        Initialize();

        // [GIVEN] an Email Address is configured on the singleton setup record
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;

        ExpenseAgentSetup."Email Address" := 'receipts@contoso.com';
        ExpenseAgentSetup.Modify();
        Commit();

        // [WHEN] the setup is fetched through the API
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Agent Setup API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] the response carries the ``emailAddress`` field with the
        //        configured value (rather than omitting it as before).
        Assert.AreNotEqual(0, StrPos(ResponseText, EmailAddressTok),
            'The Expense Agent Setup API response should include the emailAddress field.');
        ExpectedEmailValue := StrSubstNo('"%1":"%2"', EmailAddressTok, ExpenseAgentSetup."Email Address");
        Assert.AreNotEqual(0, StrPos(ResponseText, ExpectedEmailValue),
            'The emailAddress field should carry the value configured on the Expense Agent Setup record.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure TestHandlerConfigureEnablesExistingDisabledExpenseAgent()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
        AgentSetup: Codeunit "Agent Setup";
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        AgentUserSecurityId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Test handler configuration re-enables an existing disabled Expense Agent
        Initialize();

        // [GIVEN] A configured Expense Agent is disabled
        ClearExpenseAgentSetup();
        EnqueueCopyEmployeesConfirmation();
        ExpenseTestHandlerAPI.Configure();
        LibraryVariableStorage.AssertEmpty();
        ExpenseAgentSetup.Get();
        AgentUserSecurityId := ExpenseAgentSetup."User Security ID";
        AgentSetup.GetSetupRecord(
            TempAgentSetupBuffer,
            AgentUserSecurityId,
            "Agent Metadata Provider"::"Expense Agent",
            '',
            '',
            '');
        TempAgentSetupBuffer.Validate(State, TempAgentSetupBuffer.State::Disabled);
        AgentSetup.SaveChanges(TempAgentSetupBuffer);

        // [WHEN] The E2E test handler configures the company again
        ExpenseTestHandlerAPI.Configure();

        // [THEN] The existing Expense Agent is enabled
        Clear(TempAgentSetupBuffer);
        AgentSetup.GetSetupRecord(
            TempAgentSetupBuffer,
            AgentUserSecurityId,
            "Agent Metadata Provider"::"Expense Agent",
            '',
            '',
            '');
        Assert.AreEqual(
            TempAgentSetupBuffer.State::Enabled,
            TempAgentSetupBuffer.State,
            'The existing Expense Agent must be enabled.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure TestHandlerInitializeCreatesEnabledExpenseAgent()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Agent: Record Agent;
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
        AgentSetup: Codeunit "Agent Setup";
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        FirstAgentUserSecurityId: Guid;
        SecondAgentUserSecurityId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Test handler initialization creates and reuses an enabled Expense Agent
        Initialize();

        // [GIVEN] No Expense Agent setup exists
        ClearExpenseAgentSetup();
        EnqueueCopyEmployeesConfirmation();

        // [WHEN] The E2E test handler initializes the company
        ExpenseTestHandlerAPI.Configure();
        LibraryVariableStorage.AssertEmpty();
        ExpenseAgentSetup.Get();
        FirstAgentUserSecurityId := ExpenseAgentSetup."User Security ID";

        // [WHEN] The E2E test handler initializes the company again
        ExpenseTestHandlerAPI.Configure();
        ExpenseAgentSetup.Get();
        SecondAgentUserSecurityId := ExpenseAgentSetup."User Security ID";

        // [THEN] The same enabled Expense Agent is reused
        Assert.AreEqual(
            FirstAgentUserSecurityId,
            SecondAgentUserSecurityId,
            'Repeated E2E initialization must reuse the same Expense Agent.');
        Assert.IsTrue(Agent.Get(FirstAgentUserSecurityId), 'The Expense Agent must exist.');
        Assert.IsTrue(ExpenseAgentSetup.Get(), 'Expense Agent Setup must exist.');
        Assert.AreEqual(
            FirstAgentUserSecurityId,
            ExpenseAgentSetup."User Security ID",
            'Expense Agent Setup must reference the created agent.');
        Assert.IsTrue(ExpenseAgentSetup."Enable Agent", 'Expense Agent Setup must be enabled.');
        AgentSetup.GetSetupRecord(
            TempAgentSetupBuffer,
            FirstAgentUserSecurityId,
            "Agent Metadata Provider"::"Expense Agent",
            '',
            '',
            '');
        Assert.AreEqual(
            TempAgentSetupBuffer.State::Enabled,
            TempAgentSetupBuffer.State,
            'The underlying Expense Agent state must be enabled.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure TestHandlerInitializeCreatesDefaultMasterData()
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Test handler initialization creates valid default master data
        Initialize();

        // [GIVEN] Required Expense Agent setup data is absent
        ClearRequiredSetupData();
        EnqueueCopyEmployeesConfirmation();

        // [WHEN] The E2E test handler initializes Expense Agent master data
        ExpenseTestHandlerAPI.Configure();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Default number series, payment methods, categories, and posting accounts exist
        VerifyDefaultNumberSeriesExist();
        Assert.IsTrue(ExpensePaymentMethod.Get('CARD'), 'The credit-card payment method must exist.');
        Assert.IsTrue(ExpenseCategory.Get('MEALS'), 'The meals category must exist.');
        Assert.IsTrue(ExpenseCategory.Get('HOTELS'), 'The hotels category must exist.');
        Assert.IsTrue(ExpenseCategory.Get('ENTERTAIN'), 'The entertainment category must exist.');
        Assert.IsTrue(ExpenseCategory.Get('PER-DIEM'), 'The per-diem category must exist.');
        VerifyDefaultPostingGroupAccountsExist();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure TestHandlerInitializeIsIdempotent()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        CategoryCount: Integer;
        PaymentMethodCount: Integer;
        PostingGroupCount: Integer;
        AgentUserSecurityId: Guid;
        PaymentMethodSystemId: Guid;
        CategorySystemId: Guid;
        PostingGroupSystemId: Guid;
        ExpenseNoSeriesCode: Code[20];
        ExpenseUserNoSeriesCode: Code[20];
        ExpenseVendorNoSeriesCode: Code[20];
        ExpenseReportNoSeriesCode: Code[20];
        PostedExpenseReportNoSeriesCode: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Repeated test handler initialization reuses completed setup data
        Initialize();

        // [GIVEN] Required Expense Agent setup data is absent
        ClearRequiredSetupData();
        EnqueueCopyEmployeesConfirmation();

        // [GIVEN] The E2E test handler initializes Expense Agent master data
        ExpenseTestHandlerAPI.Configure();
        LibraryVariableStorage.AssertEmpty();
        ExpenseAgentSetup.Get();
        CategoryCount := ExpenseCategory.Count();
        PaymentMethodCount := ExpensePaymentMethod.Count();
        PostingGroupCount := ExpensePostingGroup.Count();
        AgentUserSecurityId := ExpenseAgentSetup."User Security ID";
        ExpenseNoSeriesCode := ExpenseAgentSetup."Expense Nos.";
        ExpenseUserNoSeriesCode := ExpenseAgentSetup."Expense User Nos.";
        ExpenseVendorNoSeriesCode := ExpenseAgentSetup."Expense Vendor Nos.";
        ExpenseReportNoSeriesCode := ExpenseAgentSetup."Expense Reports Nos.";
        PostedExpenseReportNoSeriesCode := ExpenseAgentSetup."Posted Expense Reports Nos.";
        ExpensePaymentMethod.Get('CARD');
        PaymentMethodSystemId := ExpensePaymentMethod.SystemId;
        ExpenseCategory.Get('MEALS');
        CategorySystemId := ExpenseCategory.SystemId;
        ExpensePostingGroup.FindFirst();
        PostingGroupSystemId := ExpensePostingGroup.SystemId;

        // [WHEN] The E2E test handler initializes the same company again
        ExpenseTestHandlerAPI.Configure();

        // [THEN] The completed setup and default records are reused
        ExpenseAgentSetup.Get();
        Assert.AreEqual(
            AgentUserSecurityId,
            ExpenseAgentSetup."User Security ID",
            'The completed setup must reuse the same Expense Agent.');
        Assert.AreEqual(CategoryCount, ExpenseCategory.Count(), 'Expense categories must not be duplicated.');
        Assert.AreEqual(PaymentMethodCount, ExpensePaymentMethod.Count(), 'Payment methods must not be duplicated.');
        Assert.AreEqual(PostingGroupCount, ExpensePostingGroup.Count(), 'Posting groups must not be duplicated.');
        Assert.AreEqual(ExpenseNoSeriesCode, ExpenseAgentSetup."Expense Nos.", 'Expense number series must be reused.');
        Assert.AreEqual(
            ExpenseUserNoSeriesCode,
            ExpenseAgentSetup."Expense User Nos.",
            'Expense User number series must be reused.');
        Assert.AreEqual(
            ExpenseVendorNoSeriesCode,
            ExpenseAgentSetup."Expense Vendor Nos.",
            'Expense Vendor number series must be reused.');
        Assert.AreEqual(
            ExpenseReportNoSeriesCode,
            ExpenseAgentSetup."Expense Reports Nos.",
            'Expense Report number series must be reused.');
        Assert.AreEqual(
            PostedExpenseReportNoSeriesCode,
            ExpenseAgentSetup."Posted Expense Reports Nos.",
            'Posted Expense Report number series must be reused.');
        Assert.IsTrue(
            ExpensePaymentMethod.GetBySystemId(PaymentMethodSystemId),
            'The CARD payment method must be reused.');
        Assert.IsTrue(ExpenseCategory.GetBySystemId(CategorySystemId), 'The MEALS category must be reused.');
        Assert.IsTrue(
            ExpensePostingGroup.GetBySystemId(PostingGroupSystemId),
            'The default Expense Posting Group must be reused.');
    end;

    [Test]
    procedure TestHandlerInitializeDeletesExpenseVendors()
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        ExpenseVendorNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Test handler initialization removes stale Expense Vendors
        Initialize();

        // [GIVEN] An Expense Vendor exists from a previous test
        LibraryExpense.CreateExpenseVendor(ExpenseVendor);
        ExpenseVendorNo := ExpenseVendor."No.";

        // [WHEN] The E2E test handler initializes the company
        ExpenseTestHandlerAPI.Initialize();

        // [THEN] The stale Expense Vendor is removed
        Assert.IsFalse(
            ExpenseVendor.Get(ExpenseVendorNo),
            'Expense Vendor must be deleted during test initialization.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Agent Setup API Test");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Agent Setup API Test");
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Agent Setup API Test");
    end;

    local procedure ClearExpenseAgentSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if ExpenseAgentSetup.Get() then
            ExpenseAgentSetup.Delete(false);
    end;

    local procedure ClearRequiredSetupData()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseSubcategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CleanTransactionalData();
        ExpenseSubcategory.DeleteAll();
        ExpenseCategory.DeleteAll();
        ExpensePaymentMethod.DeleteAll();
        ExpensePostingGroup.DeleteAll();

        ExpenseAgentSetup.InitRecord();
        ExpenseAgentSetup."Expense Nos." := '';
        ExpenseAgentSetup."Expense User Nos." := '';
        ExpenseAgentSetup."Expense Vendor Nos." := '';
        ExpenseAgentSetup."Expense Reports Nos." := '';
        ExpenseAgentSetup."Posted Expense Reports Nos." := '';
        ExpenseAgentSetup."No. Series Applied" := false;
        ExpenseAgentSetup."Payment Methods Applied" := false;
        ExpenseAgentSetup."Posting Groups Applied" := false;
        ExpenseAgentSetup."Exp. Categories Applied" := false;
        ExpenseAgentSetup."Exp. Locations Applied" := false;
        ExpenseAgentSetup."Management Rules Applied" := false;
        ExpenseAgentSetup."VAT Rates Applied" := false;
        ExpenseAgentSetup.Modify(false);
    end;

    local procedure VerifyDefaultNumberSeriesExist()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        NoSeries: Record "No. Series";
    begin
        ExpenseAgentSetup.Get();
        Assert.IsTrue(NoSeries.Get(ExpenseAgentSetup."Expense Nos."), 'The expense number series must exist.');
        Assert.IsTrue(NoSeries.Get(ExpenseAgentSetup."Expense User Nos."), 'The expense user number series must exist.');
        Assert.IsTrue(NoSeries.Get(ExpenseAgentSetup."Expense Vendor Nos."), 'The expense vendor number series must exist.');
        Assert.IsTrue(NoSeries.Get(ExpenseAgentSetup."Expense Reports Nos."), 'The expense report number series must exist.');
        Assert.IsTrue(NoSeries.Get(ExpenseAgentSetup."Posted Expense Reports Nos."), 'The posted expense report number series must exist.');
    end;

    local procedure EnqueueCopyEmployeesConfirmation()
    begin
        LibraryVariableStorage.Enqueue(CopyEmployeesToExpenseUsersQst);
        LibraryVariableStorage.Enqueue(false);
    end;

    local procedure VerifyDefaultPostingGroupAccountsExist()
    var
        ExpensePostingGroup: Record "Expense Posting Group";
        GLAccount: Record "G/L Account";
    begin
        Assert.IsTrue(ExpensePostingGroup.FindSet(), 'At least one default expense posting group must exist.');
        repeat
            Assert.IsTrue(
                GLAccount.Get(ExpensePostingGroup."Refundable Debit Account"),
                'The refundable debit account must exist.');
            Assert.IsTrue(
                GLAccount.Get(ExpensePostingGroup."Non-Refundable Debit Account"),
                'The non-refundable debit account must exist.');
            Assert.IsTrue(
                GLAccount.Get(ExpensePostingGroup."Prepayment Credit Account"),
                'The prepayment credit account must exist.');
            Assert.IsTrue(
                GLAccount.Get(ExpensePostingGroup."Debit Rounding Account"),
                'The debit rounding account must exist.');
            Assert.IsTrue(
                GLAccount.Get(ExpensePostingGroup."Credit Rounding Account"),
                'The credit rounding account must exist.');
        until ExpensePostingGroup.Next() = 0;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
