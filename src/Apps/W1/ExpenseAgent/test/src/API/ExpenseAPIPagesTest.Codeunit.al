// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Foundation.Attachment;
using Microsoft.HumanResources.Employee;
using System.Security.User;
using System.Utilities;

codeunit 148347 "Expense API Pages Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        IsInitialized: Boolean;
        ExpensesServiceNameTok: Label 'expenses', Locked = true;
        ExpenseReportsServiceNameTok: Label 'expenseReports', Locked = true;
        ExpenseReportLinesServiceNameTok: Label 'expenseReportLines', Locked = true;
        UserConsumptionsServiceNameTok: Label 'userConsumptions', Locked = true;
        ActionReleaseExpenseTok: Label 'Microsoft.NAV.ReleaseExpense', Locked = true;
        ActionReopenExpenseTok: Label 'Microsoft.NAV.ReopenExpense', Locked = true;
        ActionValidateExpenseRuleTok: Label 'Microsoft.NAV.ValidateExpenseRule', Locked = true;
        ActionApplyExpenseRuleTok: Label 'Microsoft.NAV.ApplyExpenseRule', Locked = true;
        ActionReleaseExpenseReportTok: Label 'Microsoft.NAV.ReleaseExpenseReport', Locked = true;
        ActionReopenExpenseReportTok: Label 'Microsoft.NAV.ReopenExpenseReport', Locked = true;
        ActionPendingApprovalTok: Label 'Microsoft.NAV.PendingApprovalExpenseReport', Locked = true;
        ActionReleaseAndPendingApprovalTok: Label 'Microsoft.NAV.ReleaseAndMarkPendingApprovalExpenseReport', Locked = true;
        ActionApprovedTok: Label 'Microsoft.NAV.ApprovedExpenseReport', Locked = true;
        ActionRejectedTok: Label 'Microsoft.NAV.RejectedExpenseReport', Locked = true;
        ActionRejectAndReopenTok: Label 'Microsoft.NAV.RejectAndReopenExpenseReport', Locked = true;
        ActionAddExpenseToReportTok: Label 'Microsoft.NAV.AddExpenseToReport', Locked = true;
        ActionMoveExpenseReportLineTok: Label 'Microsoft.NAV.MoveExpenseReportLine', Locked = true;
        ActionValidateExpenseReportRuleTok: Label 'Microsoft.NAV.ValidateExpenseReportRule', Locked = true;
        ActionApplyExpenseReportRuleTok: Label 'Microsoft.NAV.ApplyExpenseReportRule', Locked = true;
        ActionLogAIConsumptionTok: Label 'Microsoft.NAV.LogAIConsumption', Locked = true;
        ActionCanConsumeTok: Label 'Microsoft.NAV.CanConsume', Locked = true;

    [Test]
    procedure ExpenseRuleViolationIsCreatedAndClearedForItemizationMismatch()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ViolationsValue: Text;
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify through the API that an itemization total mismatch raises a rule violation and that correcting the amount clears it.
        Initialize();

        // [GIVEN] An Itemize expense category with a subcategory.
        Amount := LibraryRandom.RandInt(100);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);

        // [GIVEN] An expense with an itemization whose total does not match the expense amount.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubcategory.Code, '', true, '', Amount);
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubcategory."Expense Category Code", ExpenseSubcategory.Code, WorkDate(), Amount - 1, 1);

        // [WHEN] The ValidateExpenseRule action is invoked through the API.
        InvokeValidateExpenseRuleViaApi(Expense);

        // [THEN] The expanded expenseRuleViolations contain the created violation.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.FindFirst();
        ViolationsValue := GetExpandedRuleViolations(Expense);
        Assert.AreNotEqual(0, StrPos(LowerCase(ViolationsValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseRuleViolation.SystemId)))), 'Expected an itemization mismatch rule violation through the API');

        // [WHEN] The itemization amount is corrected and the rule is re-validated through the API.
        ExpenseItemization.Validate("Daily Rate", Amount);
        ExpenseItemization.Modify(true);
        InvokeValidateExpenseRuleViaApi(Expense);

        // [THEN] The expanded expenseRuleViolations no longer contain the violation.
        ViolationsValue := GetExpandedRuleViolations(Expense);
        Assert.AreEqual(0, StrPos(LowerCase(ViolationsValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseRuleViolation.SystemId)))), 'Rule violation should be cleared after correcting the amount');
    end;

    [Test]
    procedure ExpenseRuleViolationIsCreatedAndClearedForMerchantName()
    var
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ViolationsValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify through the API that a missing mandatory merchant name raises a rule violation and that setting it clears the violation.
        Initialize();

        // [GIVEN] Merchant Name is mandatory in the Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", true);
        ExpenseAgentSetup.Modify(true);

        // [GIVEN] An expense without a merchant name.
        CreateSimpleExpense(Expense);
        Expense.Validate("Merchant Name", '');
        Expense.Modify(true);

        // [WHEN] The ValidateExpenseRule action is invoked through the API.
        InvokeValidateExpenseRuleViaApi(Expense);

        // [THEN] The expanded expenseRuleViolations contain the created violation.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.FindFirst();
        ViolationsValue := GetExpandedRuleViolations(Expense);
        Assert.AreNotEqual(0, StrPos(LowerCase(ViolationsValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseRuleViolation.SystemId)))), 'Expected a merchant name rule violation through the API');

        // [WHEN] A merchant name is provided and the rule is re-validated through the API.
        Expense.Validate("Merchant Name", LibraryUtility.GenerateRandomCode(Expense.FieldNo("Merchant Name"), Database::"Expense"));
        Expense.Modify(true);
        InvokeValidateExpenseRuleViaApi(Expense);

        // [THEN] The expanded expenseRuleViolations no longer contain the violation.
        ViolationsValue := GetExpandedRuleViolations(Expense);
        Assert.AreEqual(0, StrPos(LowerCase(ViolationsValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseRuleViolation.SystemId)))), 'Rule violation should be cleared after setting the merchant name');

        // [GIVEN] Restore the setup so the mandatory flag does not leak into other tests.
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", false);
        ExpenseAgentSetup.Modify(true);
    end;

    [Test]
    procedure ExpenseAgentSetupIsExposedThroughExpenseAgentSetupAPI()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the Expense Agent Setup singleton is exposed through the Expense Agent Setup API.
        Initialize();

        // [GIVEN] Get the Expense Agent Setup record.
        ExpenseAgentSetup.Get();
        Commit();

        // [WHEN] Fetch the setup by id through the API.
        // [THEN] Verify that the API returns the record.
        VerifyRecordVisibleInApi(ExpenseAgentSetup.SystemId, Page::"Expense Agent Setup API", 'expenseAgentSetup');
    end;

    [Test]
    procedure ApproverViewIsExposedThroughApproverViewAPI()
    var
        ExpenseUser: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that Expense User is exposed through the Approver View API.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Commit();

        // [WHEN] Fetch the user by id through the Approver View API.
        // [THEN] Verify that the API returns the record.
        VerifyRecordVisibleInApi(ExpenseUser.SystemId, Page::"Approver View API", 'approverViews');
    end;

    [Test]
    procedure UserConsumptionIsExposedThroughExpenseUserConsAPI()
    var
        ExpenseUser: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that Expense User is exposed through the Expense User Cons. API.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Commit();

        // [WHEN] Fetch the user by id through the User Consumption API.
        // [THEN] Verify that the API returns the record.
        VerifyRecordVisibleInApi(ExpenseUser.SystemId, Page::"Expense User Cons. API", 'userConsumptions');
    end;

    [Test]
    procedure OutboxEmailIsExposedThroughEAOutboxEmailAPI()
    var
        EAOutboxEmail: Record "EA Outbox Email";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that Outbox Email is exposed through the EA Outbox Email API.
        Initialize();

        // [GIVEN] Create Outbox Email.
        CreateOutboxEmail(EAOutboxEmail);
        Commit();

        // [WHEN] Fetch the outbox email by id through the API.
        // [THEN] Verify that the API returns the record.
        VerifyRecordVisibleInApi(EAOutboxEmail.SystemId, Page::"EA Outbox Email API", 'outboxEmails');
    end;

    [Test]
    procedure TenantFeedbackSettingCollectionIsExposedThroughAPI()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the Tenant Feedback Setting API collection endpoint is reachable.
        Initialize();

        // [WHEN] Fetch the tenant feedback setting collection through the API.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Tenant Feedback Setting API", 'tenantFeedbackSettings');

        // [THEN] Verify that the request succeeds (200).
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.AreNotEqual('', ResponseText, 'Tenant Feedback Setting API should return a response');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PostedExpenseReportLineIsExposedThroughPostedExpReportLinesAPI()
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpRepLineItem: Record "Posted Exp. Rep. Line Item";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that Posted Expense Report Line is exposed through the Posted Exp. Report Lines API.
        Initialize();

        // [GIVEN] Create and post an Expense Report.
        CreateAndPostExpenseReport(PostedExpenseReportHeader, PostedExpenseReportLine, PostedExpRepLineItem, DocumentAttachment, false);
        Commit();

        // [WHEN] Fetch the posted expense report line by id through the API.
        // [THEN] Verify that the API returns the record.
        VerifyRecordVisibleInApi(PostedExpenseReportLine.SystemId, Page::"Posted Exp. Report Lines API", 'postedExpenseReportLines');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PostedExpenseReportLineItemIsExposedThroughPostedExpRepLineItemAPI()
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpRepLineItem: Record "Posted Exp. Rep. Line Item";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that Posted Expense Report Line Itemization is exposed through the Posted Exp. Rep. Line Item API.
        Initialize();

        // [GIVEN] Create and post an Expense Report with an Itemization.
        CreateAndPostExpenseReport(PostedExpenseReportHeader, PostedExpenseReportLine, PostedExpRepLineItem, DocumentAttachment, false);
        Commit();

        // [WHEN] Fetch the posted report line itemization by id through the API.
        // [THEN] Verify that the API returns the record.
        VerifyRecordVisibleInApi(PostedExpRepLineItem.SystemId, Page::"Posted Exp. Rep. Line Item API", 'postedExpenseReportLineItemizations');
    end;

    [Test]
    procedure ExpenseCollectionIsExposedThroughExpensesAPI()
    var
        Expense: Record Expense;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the Expenses API collection endpoint returns all expenses.
        Initialize();

        // [GIVEN] Create Expense.
        CreateSimpleExpense(Expense);
        Commit();

        // [WHEN] GET all expenses from the collection endpoint.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expenses API", 'expenses');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains the created expense.
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        Assert.AreNotEqual(0, StrPos(LowerCase(ResponseText), LowerCase(LibraryGraphMgt.StripBrackets(Format(Expense.SystemId)))), 'Response should contain the created expense id');
    end;

    [Test]
    procedure ExpenseUserCollectionIsExposedThroughExpenseUsersAPI()
    var
        ExpenseUser: Record "Expense User";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the Expense Users API collection endpoint returns all expense users.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Commit();

        // [WHEN] GET all expense users from the collection endpoint.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Users API", 'expenseUsers');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains the created expense user.
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        Assert.AreNotEqual(0, StrPos(LowerCase(ResponseText), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseUser.SystemId)))), 'Response should contain the created expense user id');
    end;

    [Test]
    procedure ExpenseItemizationsCanBeExpandedThroughExpensesAPI()
    var
        Expense: Record Expense;
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
        ResponseText: Text;
        TargetURL: Text;
        ItemizationsValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that $expand=expenseItemizations returns itemizations in the Expenses API.
        Initialize();

        // [GIVEN] Create Expense with an Itemization.
        CreateExpenseWithItemizeRule(Expense, ExpenseSubcategory);
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubcategory."Expense Category Code", ExpenseSubcategory.Code, WorkDate(), LibraryRandom.RandInt(50), 1);
        Commit();

        // [WHEN] GET expense with expanded expenseItemizations.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", 'expenses');
        TargetURL := LibraryExpense.AppendExpandToURL(TargetURL, 'expenseItemizations');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains expenseItemizations.
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'expenseItemizations', ItemizationsValue);
        Assert.AreNotEqual('', ItemizationsValue, 'Expanded expenseItemizations should not be blank');
        Assert.AreNotEqual(0, StrPos(LowerCase(ItemizationsValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseItemization.SystemId)))), 'Expanded expenseItemizations should contain the created itemization');
    end;

    [Test]
    procedure ExpenseParticipantsCanBeExpandedThroughExpensesAPI()
    var
        Expense: Record Expense;
        ExpenseParticipant: Record "Expense Participant";
        ResponseText: Text;
        TargetURL: Text;
        ParticipantsValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that $expand=expenseParticipants returns participants in the Expenses API.
        Initialize();

        // [GIVEN] Create Expense with a Participant.
        CreateSimpleExpense(Expense);
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);
        Commit();

        // [WHEN] GET expense with expanded expenseParticipants.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", 'expenses');
        TargetURL := LibraryExpense.AppendExpandToURL(TargetURL, 'expenseParticipants');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains expenseParticipants.
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'expenseParticipants', ParticipantsValue);
        Assert.AreNotEqual('', ParticipantsValue, 'Expanded expenseParticipants should not be blank');
        Assert.AreNotEqual(0, StrPos(LowerCase(ParticipantsValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseParticipant.SystemId)))), 'Expanded expenseParticipants should contain the created participant');
    end;

    [Test]
    procedure ExpenseRuleViolationsCanBeExpandedThroughExpensesAPI()
    var
        Expense: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ResponseText: Text;
        TargetURL: Text;
        ViolationsValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that $expand=expenseRuleViolations returns violations in the Expenses API.
        Initialize();

        // [GIVEN] Create Expense with a Rule Violation.
        CreateSimpleExpense(Expense);
        CreateExpenseRuleViolation(ExpenseRuleViolation, Expense);
        Commit();

        // [WHEN] GET expense with expanded expenseRuleViolations.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", 'expenses');
        TargetURL := LibraryExpense.AppendExpandToURL(TargetURL, 'expenseRuleViolations');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains expenseRuleViolations.
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'expenseRuleViolations', ViolationsValue);
        Assert.AreNotEqual('', ViolationsValue, 'Expanded expenseRuleViolations should not be blank');
        Assert.AreNotEqual(0, StrPos(LowerCase(ViolationsValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseRuleViolation.SystemId)))), 'Expanded expenseRuleViolations should contain the created violation');
    end;

    [Test]
    procedure ExpenseSubcategoriesCanBeExpandedThroughCategoriesAPI()
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ResponseText: Text;
        TargetURL: Text;
        SubcategoriesValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that $expand=expenseSubcategories returns subcategories in the Categories API.
        Initialize();

        // [GIVEN] Create Expense Category with a Subcategory.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        Commit();

        // [WHEN] GET category with expanded expenseSubcategories.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(ExpenseCategory.SystemId), Page::"Expense Categories API", 'expenseCategories');
        TargetURL := LibraryExpense.AppendExpandToURL(TargetURL, 'expenseSubcategories');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains expenseSubcategories.
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'expenseSubcategories', SubcategoriesValue);
        Assert.AreNotEqual('', SubcategoriesValue, 'Expanded expenseSubcategories should not be blank');
        Assert.AreNotEqual(0, StrPos(LowerCase(SubcategoriesValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseSubcategory.SystemId)))), 'Expanded expenseSubcategories should contain the created subcategory');
    end;

    [Test]
    procedure ExpensesCanBeExpandedThroughExpenseUsersAPI()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ResponseText: Text;
        TargetURL: Text;
        ExpensesValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that $expand=expenses returns expenses in the Expense Users API.
        Initialize();

        // [GIVEN] Create Expense User with an Expense.
        CreateExpenseForUser(Expense, ExpenseUser);
        Commit();

        // [WHEN] GET expense user with expanded expenses.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(ExpenseUser.SystemId), Page::"Expense Users API", 'expenseUsers');
        TargetURL := LibraryExpense.AppendExpandToURL(TargetURL, 'expenses');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains expenses.
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'expenses', ExpensesValue);
        Assert.AreNotEqual('', ExpensesValue, 'Expanded expenses should not be blank');
        Assert.AreNotEqual(0, StrPos(LowerCase(ExpensesValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(Expense.SystemId)))), 'Expanded expenses should contain the created expense');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PostedExpReportLinesCanBeExpandedThroughPostedReportsAPI()
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpRepLineItem: Record "Posted Exp. Rep. Line Item";
        DocumentAttachment: Record "Document Attachment";
        ResponseText: Text;
        TargetURL: Text;
        LinesValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that $expand=postedExpenseReportLines returns lines in the Posted Expense Reports API.
        Initialize();

        // [GIVEN] Create and post an Expense Report.
        CreateAndPostExpenseReport(PostedExpenseReportHeader, PostedExpenseReportLine, PostedExpRepLineItem, DocumentAttachment, false);
        Commit();

        // [WHEN] GET posted expense report with expanded postedExpenseReportLines.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(PostedExpenseReportHeader.SystemId), Page::"Posted Expense Reports API", 'postedExpenseReports');
        TargetURL := LibraryExpense.AppendExpandToURL(TargetURL, 'postedExpenseReportLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains postedExpenseReportLines.
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'postedExpenseReportLines', LinesValue);
        Assert.AreNotEqual('', LinesValue, 'Expanded postedExpenseReportLines should not be blank');
        Assert.AreNotEqual(0, StrPos(LowerCase(LinesValue), LowerCase(LibraryGraphMgt.StripBrackets(Format(PostedExpenseReportLine.SystemId)))), 'Expanded postedExpenseReportLines should contain the created line');
    end;

    [Test]
    procedure ExpenseGroupFieldsAreCorrectWhenRetrievedThroughAPI()
    var
        ExpenseGroup: Record "Expense Group";
        ResponseText: Text;
        TargetURL: Text;
        PropertyValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that GET Expense Group by ID returns correct code and description.
        Initialize();

        // [GIVEN] Create Expense Group.
        LibraryExpense.CreateExpenseGroup(ExpenseGroup);
        Commit();

        // [WHEN] GET the expense group by SystemId.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(ExpenseGroup.SystemId), Page::"Expense Groups API", 'expenseGroups');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains the correct code and description.
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'code', PropertyValue);
        Assert.AreEqual(Format(ExpenseGroup.Code), PropertyValue, 'Code should match');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'description', PropertyValue);
        Assert.AreEqual(ExpenseGroup.Description, PropertyValue, 'Description should match');
    end;

    [Test]
    procedure ExpenseFieldsAreCorrectWhenRetrievedThroughAPI()
    var
        Expense: Record Expense;
        ResponseText: Text;
        TargetURL: Text;
        PropertyValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that GET Expense by ID returns correct expense number.
        Initialize();

        // [GIVEN] Create Expense.
        CreateSimpleExpense(Expense);
        Commit();

        // [WHEN] GET the expense by SystemId.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", 'expenses');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains the correct number.
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'number', PropertyValue);
        Assert.AreEqual(Expense."No.", PropertyValue, 'Expense number should match');
    end;

    [Test]
    procedure ExpenseParticipantFieldsAreCorrectWhenRetrievedThroughAPI()
    var
        Expense: Record Expense;
        ExpenseParticipant: Record "Expense Participant";
        ResponseText: Text;
        TargetURL: Text;
        PropertyValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that GET Expense Participant by ID returns correct participant name.
        Initialize();

        // [GIVEN] Create Expense with a Participant.
        CreateSimpleExpense(Expense);
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);
        Commit();

        // [WHEN] GET the participant by SystemId.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(ExpenseParticipant.SystemId), Page::"Expense Participants API", 'expenseParticipants');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains the correct expense number and participant name.
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'expenseNo', PropertyValue);
        Assert.AreEqual(Format(Expense."No."), PropertyValue, 'Expense number should match');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'participantName', PropertyValue);
        Assert.AreEqual(ExpenseParticipant."Participant Name", PropertyValue, 'Participant name should match');
    end;

    [Test]
    procedure ExpenseRuleViolationFieldsAreCorrectWhenRetrievedThroughAPI()
    var
        Expense: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ResponseText: Text;
        TargetURL: Text;
        PropertyValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that GET Expense Rule Violation by ID returns correct description.
        Initialize();

        // [GIVEN] Create Expense with a Rule Violation.
        CreateSimpleExpense(Expense);
        CreateExpenseRuleViolation(ExpenseRuleViolation, Expense);
        Commit();

        // [WHEN] GET the rule violation by SystemId.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(ExpenseRuleViolation.SystemId), Page::"Expense Rule Violations API", 'expenseRuleViolations');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains the correct expense number and description.
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'expenseNo', PropertyValue);
        Assert.AreEqual(Format(Expense."No."), PropertyValue, 'Expense number should match');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'description', PropertyValue);
        Assert.AreEqual(ExpenseRuleViolation.Description, PropertyValue, 'Description should match');
    end;

    [Test]
    procedure ExpenseCategoryFieldsAreCorrectWhenRetrievedThroughAPI()
    var
        ExpenseCategory: Record "Expense Category";
        ResponseText: Text;
        TargetURL: Text;
        PropertyValue: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that GET Expense Category by ID returns correct code and description.
        Initialize();

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        Commit();

        // [WHEN] GET the category by SystemId.
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(ExpenseCategory.SystemId), Page::"Expense Categories API", 'expenseCategories');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] Verify that the response contains the correct code and description.
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'code', PropertyValue);
        Assert.AreEqual(Format(ExpenseCategory.Code), PropertyValue, 'Code should match');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'description', PropertyValue);
        Assert.AreEqual(ExpenseCategory.Description, PropertyValue, 'Description should match');
    end;

    [Test]
    procedure ReleaseExpenseActionChangesStatusToReleased()
    var
        Expense: Record Expense;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ReleaseExpense action changes expense status to Released.
        Initialize();

        // [GIVEN] Create an open Expense.
        CreateSimpleExpense(Expense);
        Expense.Get(Expense."No.");

        // [THEN] The expense status is Open.
        Assert.AreEqual(Expense.Status::Open, Expense.Status, 'Precondition failed: expense should be Open before release action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ReleaseExpense action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok, ActionReleaseExpenseTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The expense status is updated to Released.
        Expense.Get(Expense."No.");
        Assert.AreEqual(Expense.Status::Released, Expense.Status, 'Expense status should be Released');
    end;

    [Test]
    procedure ReopenExpenseActionChangesStatusToOpen()
    var
        Expense: Record Expense;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ReopenExpense action changes expense status back to Open.
        Initialize();

        // [GIVEN] Create a released Expense.
        CreateSimpleExpense(Expense);
        Expense.PerformManualRelease();
        Expense.Get(Expense."No.");

        // [THEN] The expense status is Released.
        Assert.AreEqual(Expense.Status::Released, Expense.Status, 'Precondition failed: expense should be Released before reopen action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ReopenExpense action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok, ActionReopenExpenseTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The expense status is updated to Open.
        Expense.Get(Expense."No.");
        Assert.AreEqual(Expense.Status::Open, Expense.Status, 'Expense status should be Open');
    end;

    [Test]
    procedure ValidateExpenseRuleActionSucceeds()
    var
        Expense: Record Expense;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ValidateExpenseRule action can be invoked via the API.
        Initialize();

        // [GIVEN] Create an Expense.
        CreateSimpleExpense(Expense);
        Expense.Get(Expense."No.");

        // [THEN] The expense status is Open.
        Assert.AreEqual(Expense.Status::Open, Expense.Status, 'Precondition failed: expense should be Open before validate rule action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ValidateExpenseRule action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok, ActionValidateExpenseRuleTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The action completes without error (expense still exists).
        Assert.IsTrue(Expense.Get(Expense."No."), 'Expense should still exist after validation');
    end;

    [Test]
    procedure ApplyExpenseRuleActionSucceeds()
    var
        Expense: Record Expense;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ApplyExpenseRule action can be invoked via the API.
        Initialize();

        // [GIVEN] Create an Expense.
        CreateSimpleExpense(Expense);
        Expense.Get(Expense."No.");

        // [THEN] The expense status is Open.
        Assert.AreEqual(Expense.Status::Open, Expense.Status, 'Precondition failed: expense should be Open before apply rule action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ApplyExpenseRule action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok, ActionApplyExpenseRuleTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The action completes without error (expense still exists).
        Assert.IsTrue(Expense.Get(Expense."No."), 'Expense should still exist after applying rule');
    end;

    [Test]
    procedure ReleaseExpenseReportActionChangesStatusToReleased()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ReleaseExpenseReport action changes report status to Released.
        Initialize();

        // [GIVEN] Create an open Expense Report with a Line.
        CreateExpenseReportHeaderWithLine(ExpenseReportHeader, ExpenseReportLine);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The expense report status is Open.
        Assert.AreEqual(ExpenseReportHeader.Status::Open, ExpenseReportHeader.Status, 'Precondition failed: report should be Open before release action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ReleaseExpenseReport action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionReleaseExpenseReportTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The expense report status is updated to Released.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::Released, ExpenseReportHeader.Status, 'Expense report status should be Released');
    end;

    [Test]
    procedure ReopenExpenseReportActionChangesStatusToOpen()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ReopenExpenseReport action changes report status back to Open.
        Initialize();

        // [GIVEN] Create a released Expense Report.
        CreateExpenseReportHeaderWithLine(ExpenseReportHeader, ExpenseReportLine);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The expense report status is Released.
        Assert.AreEqual(ExpenseReportHeader.Status::Released, ExpenseReportHeader.Status, 'Precondition failed: report should be Released before reopen action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ReopenExpenseReport action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionReopenExpenseReportTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The expense report status is updated to Open.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::Open, ExpenseReportHeader.Status, 'Expense report status should be Open');
    end;

    [Test]
    procedure PendingApprovalExpenseReportActionChangesStatus()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ApproverUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the PendingApprovalExpenseReport action changes report status to Pending Approval.
        Initialize();

        // [GIVEN] Create an Expense Report with a Line for an Expense User.
        CreateExpenseReportWithLineForUser(ExpenseReportHeader, ExpenseReportLine, ExpenseUser);

        // [GIVEN] Create an approver and configure the approval setup.
        LibraryExpense.CreateExpenseUser(ApproverUser);
        SetupApproverExpenseUser(ApproverUser);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser."No.", ApproverUser."No.");

        // [GIVEN] Release the report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Get the released Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The expense report status is Released before the action.
        Assert.AreEqual(ExpenseReportHeader.Status::Released, ExpenseReportHeader.Status, 'Precondition failed: report should be Released before pending approval action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The PendingApprovalExpenseReport action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionPendingApprovalTok);
        JSONBody := LibraryGraphMgt.AddPropertytoJSON('', 'submitterExpenseUserNo', ExpenseUser."No.");
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);

        // [THEN] The expense report status is updated to Pending Approval.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.Status, 'Expense report status should be Pending Approval');
    end;

    [Test]
    procedure ReleaseAndMarkPendingApprovalActionChangesStatus()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ApproverUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ReleaseAndMarkPendingApprovalExpenseReport action changes status to Pending Approval.
        Initialize();

        // [GIVEN] Create an Expense Report with a Line for an Expense User.
        CreateExpenseReportWithLineForUser(ExpenseReportHeader, ExpenseReportLine, ExpenseUser);

        // [GIVEN] Create an approver and configure the approval setup.
        LibraryExpense.CreateExpenseUser(ApproverUser);
        SetupApproverExpenseUser(ApproverUser);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser."No.", ApproverUser."No.");

        // [GIVEN] Get the open Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The expense report status is Open before the action.
        Assert.AreEqual(ExpenseReportHeader.Status::Open, ExpenseReportHeader.Status, 'Precondition failed: report should be Open before release and pending approval action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ReleaseAndMarkPendingApprovalExpenseReport action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionReleaseAndPendingApprovalTok);
        JSONBody := LibraryGraphMgt.AddPropertytoJSON('', 'submitterExpenseUserNo', ExpenseUser."No.");
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);

        // [THEN] The expense report status is updated to Pending Approval.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.Status, 'Expense report status should be Pending Approval');
    end;

    [Test]
    procedure ApprovedExpenseReportActionChangesStatus()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ApproverUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ApprovedExpenseReport action changes report status to Approved.
        Initialize();

        // [GIVEN] Create an Expense Report with a Line for an Expense User.
        CreateExpenseReportWithLineForUser(ExpenseReportHeader, ExpenseReportLine, ExpenseUser);

        // [GIVEN] Create an approver and configure the approval setup.
        LibraryExpense.CreateExpenseUser(ApproverUser);
        SetupApproverExpenseUser(ApproverUser);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser."No.", ApproverUser."No.");

        // [GIVEN] Release the report and mark it Pending Approval.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [GIVEN] Get the Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The expense report status is Pending Approval before the action.
        Assert.AreEqual(ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.Status, 'Precondition failed: report should be Pending Approval before approved action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ApprovedExpenseReport action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionApprovedTok);
        JSONBody := LibraryGraphMgt.AddPropertytoJSON('', 'approverExpenseUserNo', ApproverUser."No.");
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);

        // [THEN] The expense report status is updated to Approved.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::Approved, ExpenseReportHeader.Status, 'Expense report status should be Approved');
    end;

    [Test]
    procedure RejectedExpenseReportActionChangesStatus()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ApproverUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the RejectedExpenseReport action changes report status to Rejected.
        Initialize();

        // [GIVEN] Create an Expense Report with a Line for an Expense User.
        CreateExpenseReportWithLineForUser(ExpenseReportHeader, ExpenseReportLine, ExpenseUser);

        // [GIVEN] Create an approver and configure the approval setup.
        LibraryExpense.CreateExpenseUser(ApproverUser);
        SetupApproverExpenseUser(ApproverUser);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser."No.", ApproverUser."No.");

        // [GIVEN] Release the report and mark it Pending Approval.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [GIVEN] Get the Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The expense report status is Pending Approval before the action.
        Assert.AreEqual(ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.Status, 'Precondition failed: report should be Pending Approval before rejected action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The RejectedExpenseReport action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionRejectedTok);
        JSONBody := LibraryGraphMgt.AddPropertytoJSON('', 'approverExpenseUserNo', ApproverUser."No.");
        JSONBody := LibraryGraphMgt.AddPropertytoJSON(JSONBody, 'rejectReason', 'Test rejection reason');
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);

        // [THEN] The expense report status is updated to Rejected.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::Rejected, ExpenseReportHeader.Status, 'Expense report status should be Rejected');
    end;

    [Test]
    procedure RejectAndReopenExpenseReportActionChangesStatusToOpen()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ApproverUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the RejectAndReopenExpenseReport action changes report status to Open.
        Initialize();

        // [GIVEN] Create an Expense Report with a Line for an Expense User.
        CreateExpenseReportWithLineForUser(ExpenseReportHeader, ExpenseReportLine, ExpenseUser);

        // [GIVEN] Create an approver and configure the approval setup.
        LibraryExpense.CreateExpenseUser(ApproverUser);
        SetupApproverExpenseUser(ApproverUser);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser."No.", ApproverUser."No.");

        // [GIVEN] Release the report and mark it Pending Approval.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [GIVEN] Get the Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The expense report status is Pending Approval before the action.
        Assert.AreEqual(ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.Status, 'Precondition failed: report should be Pending Approval before reject and reopen action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The RejectAndReopenExpenseReport action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionRejectAndReopenTok);
        JSONBody := LibraryGraphMgt.AddPropertytoJSON('', 'approverExpenseUserNo', ApproverUser."No.");
        JSONBody := LibraryGraphMgt.AddPropertytoJSON(JSONBody, 'rejectReason', 'Test rejection reason');
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);

        // [THEN] The expense report status is updated to Open.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::Open, ExpenseReportHeader.Status, 'Expense report status should be Open');
    end;

    [Test]
    procedure AddExpenseToReportActionCreatesReportLine()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the AddExpenseToReport action adds an expense as a report line.
        Initialize();

        // [GIVEN] Create an Expense and an open Expense Report.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubcategory.Code, '', true, '', LibraryRandom.RandInt(100));
        Expense.PerformManualRelease();
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        Expense.Get(Expense."No.");

        // [THEN] The expense status is Released.
        Assert.AreEqual(Expense.Status::Released, Expense.Status, 'Precondition failed: expense should be Released before add to report action');

        // [GIVEN] Get the open Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [THEN] The expense report status is Open.
        Assert.AreEqual(ExpenseReportHeader.Status::Open, ExpenseReportHeader.Status, 'Precondition failed: report should be Open before add to report action');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The AddExpenseToReport action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionAddExpenseToReportTok);
        JSONBody := LibraryGraphMgt.AddPropertytoJSON('', 'expenseId', LibraryGraphMgt.StripBrackets(Format(Expense.SystemId)));
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);

        // [THEN] A report line is created for the expense.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        Assert.RecordIsNotEmpty(ExpenseReportLine);
    end;

    [Test]
    procedure MoveExpenseReportLineActionMovesLineToTargetReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the MoveExpenseReportLine action moves a line to a target report.
        Initialize();

        // [GIVEN] Create two Expense Reports, with a line on the first.
        CreateExpenseReportWithLineForUser(ExpenseReportHeader, ExpenseReportLine, ExpenseUser);
        LibraryExpense.CreateExpenseReport(TargetExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The MoveExpenseReportLine action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportLine.SystemId), Page::"Expense Report Lines API", ExpenseReportLinesServiceNameTok, ActionMoveExpenseReportLineTok);
        JSONBody := LibraryGraphMgt.AddPropertytoJSON('', 'targetExpenseReportId', LibraryGraphMgt.StripBrackets(Format(TargetExpenseReportHeader.SystemId)));
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);

        // [THEN] The line now belongs to the target report.
        ExpenseReportLine.SetRange("Document No.", TargetExpenseReportHeader."No.");
        Assert.RecordIsNotEmpty(ExpenseReportLine);
    end;

    [Test]
    procedure ValidateExpenseReportRuleActionSucceeds()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ValidateExpenseReportRule action can be invoked via the API.
        Initialize();

        // [GIVEN] Create an Expense Report with a Line.
        CreateExpenseReportHeaderWithLine(ExpenseReportHeader, ExpenseReportLine);

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ValidateExpenseReportRule action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportLine.SystemId), Page::"Expense Report Lines API", ExpenseReportLinesServiceNameTok, ActionValidateExpenseReportRuleTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The action completes without error.
        Assert.IsTrue(ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No."), 'Expense report line should still exist after validation');
    end;

    [Test]
    procedure ApplyExpenseReportRuleActionSucceeds()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the ApplyExpenseReportRule action can be invoked via the API.
        Initialize();

        // [GIVEN] Create an Expense Report with a Line.
        CreateExpenseReportHeaderWithLine(ExpenseReportHeader, ExpenseReportLine);

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The ApplyExpenseReportRule action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportLine.SystemId), Page::"Expense Report Lines API", ExpenseReportLinesServiceNameTok, ActionApplyExpenseReportRuleTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The action completes without error.
        Assert.IsTrue(ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No."), 'Expense report line should still exist after applying rule');
    end;

    [Test]
    procedure CanConsumeActionReturnsResult()
    var
        ExpenseUser: Record "Expense User";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the CanConsume action can be invoked via the API.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The CanConsume action is called via the API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseUser.SystemId), Page::"Expense User Cons. API", UserConsumptionsServiceNameTok, ActionCanConsumeTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);

        // [THEN] The action returns a response.
        Assert.AreNotEqual('', ResponseText, 'CanConsume should return a response');
    end;

    [Test]
    procedure LogAIConsumptionActionSucceeds()
    var
        ExpenseUser: Record "Expense User";
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 637260] Verify that the LogAIConsumption action can be invoked via the API.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Commit to save the transaction.
        Commit();

        // [GIVEN] Select the latest version.
        SelectLatestVersion();

        // [WHEN] The LogAIConsumption action is called via the API with required parameters.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseUser.SystemId), Page::"Expense User Cons. API", UserConsumptionsServiceNameTok, ActionLogAIConsumptionTok);
        JSONBody := LibraryGraphMgt.AddPropertytoJSON('', 'copilotQuotaUsageAmount', '100');
        JSONBody := LibraryGraphMgt.AddPropertytoJSON(JSONBody, 'copilotQuotaUsageType', '0');
        JSONBody := LibraryGraphMgt.AddPropertytoJSON(JSONBody, 'actionsSummary', 'Test action summary');
        JSONBody := LibraryGraphMgt.AddPropertytoJSON(JSONBody, 'actionsDescription', 'Test action description');
        JSONBody := LibraryGraphMgt.AddPropertytoJSON(JSONBody, 'consumptionSourceType', '1');
        JSONBody := LibraryGraphMgt.AddPropertytoJSON(JSONBody, 'consumptionSourceSystemId', LibraryGraphMgt.StripBrackets(Format(CreateGuid())));
        JSONBody := LibraryGraphMgt.AddPropertytoJSON(JSONBody, 'consumptionSourceOperationName', 'TestOp');
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);

        // [THEN] The action returns a response.
        Assert.AreNotEqual('', ResponseText, 'LogAIConsumption should return a response');
    end;

    local procedure CreateExpenseReportHeaderWithLine(var ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseUser: Record "Expense User";
    begin
        CreateExpenseReportWithLineForUser(ExpenseReportHeader, ExpenseReportLine, ExpenseUser);
    end;

    local procedure CreateExpenseReportWithLineForUser(var ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line"; var ExpenseUser: Record "Expense User")
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', LibraryRandom.RandInt(100));
    end;

    local procedure SetupApproverExpenseUser(var ApproverUser: Record "Expense User")
    var
        ApproverUserSetup: Record "User Setup";
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        ApproverUser."Can Approve" := true;
        ApproverUser."User Id For Approvals" := ApproverUserSetup."User ID";
        ApproverUser.Modify();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense API Pages Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense API Pages Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense API Pages Test");
    end;

    local procedure CreateSimpleExpense(var Expense: Record Expense)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubcategory.Code, '', true, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreateExpenseForUser(var Expense: Record Expense; var ExpenseUser: Record "Expense User")
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubcategory.Code, '', true, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreateExpenseRuleViolation(var ExpenseRuleViolation: Record "Expense Rule Violation"; var Expense: Record Expense)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", true);
        ExpenseAgentSetup.Modify(true);

        Expense.Validate("Merchant Name", '');
        Expense.Modify(true);
        Expense.ApplyRule();

        ExpenseAgentSetup.Validate("Merchant Name Mandatory", false);
        ExpenseAgentSetup.Modify(true);

        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.FindFirst();
    end;

    local procedure InvokeValidateExpenseRuleViaApi(Expense: Record Expense)
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        Commit();
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok, ActionValidateExpenseRuleTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 200);
    end;

    local procedure GetExpandedRuleViolations(Expense: Record Expense): Text
    var
        ResponseText: Text;
        TargetURL: Text;
        ViolationsValue: Text;
    begin
        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok);
        TargetURL := LibraryExpense.AppendExpandToURL(TargetURL, 'expenseRuleViolations');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'expenseRuleViolations', ViolationsValue);
        exit(ViolationsValue);
    end;

    local procedure CreateOutboxEmail(var EAOutboxEmail: Record "EA Outbox Email")
    begin
        EAOutboxEmail.Init();
        EAOutboxEmail.Validate(Subject, LibraryUtility.GenerateGUID());
        EAOutboxEmail.Insert(true);
    end;

    local procedure CreateExpenseWithItemizeRule(var Expense: Record Expense; var ExpenseSubcategory: Record "Expense Subcategory")
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '',
            ExpenseRuleCondition."Condition Type"::"Max Amount", LibraryRandom.RandInt(100));
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubcategory.Code, '', true, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreateAndPostExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; var PostedExpenseReportLine: Record "Posted Expense Report Line"; var PostedExpRepLineItem: Record "Posted Exp. Rep. Line Item"; var PostedDocumentAttachment: Record "Document Attachment"; AttachToLineBeforePosting: Boolean)
    var
        Employee: Record Employee;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        DocumentAttachment: Record "Document Attachment";
        ExpensePostMgt: Codeunit "Expense Report-Post";
        RecRef: RecordRef;
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);

        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify(true);

        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', LibraryRandom.RandInt(100));

        LibraryExpense.CreateExpenseReportLineItemization(
            ExpenseReportLineItem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubcategory.Code, WorkDate(), LibraryRandom.RandInt(50), 1);

        if AttachToLineBeforePosting then begin
            RecRef.GetTable(ExpenseReportLine);
            CreateDocumentAttachment(DocumentAttachment, RecRef, 'attachment.txt');
        end;

        ExpenseReportHeader.PerformManualRelease();
        ExpensePostMgt.PostExpenseReport(ExpenseReportHeader);

        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        PostedExpenseReportHeader.FindFirst();
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLine.FindFirst();
        PostedExpRepLineItem.SetRange("Expense Report No.", PostedExpenseReportHeader."No.");
        PostedExpRepLineItem.FindFirst();

        if AttachToLineBeforePosting then begin
            PostedDocumentAttachment.SetRange("Table ID", Database::"Posted Expense Report Line");
            PostedDocumentAttachment.SetRange("No.", PostedExpenseReportLine."Document No.");
            PostedDocumentAttachment.SetRange("Line No.", PostedExpenseReportLine."Line No.");
            PostedDocumentAttachment.FindFirst();
        end;
    end;

    local procedure CreateDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('Test attachment content');
        DocumentAttachment.Init();
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
    end;

    local procedure VerifyRecordVisibleInApi(SystemIdValue: Guid; PageId: Integer; EntitySetName: Text)
    var
        TargetURL: Text;
        ResponseText: Text;
        IdTxt: Text;
    begin
        IdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(SystemIdValue)));

        SelectLatestVersion();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(SystemIdValue), PageId, EntitySetName);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        Assert.AreNotEqual(0, StrPos(LowerCase(ResponseText), IdTxt), 'API response should contain the requested record id');
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
