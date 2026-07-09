// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

codeunit 134363 "Approvals Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        User: Record User;
        User2: Record User;
        User3: Record User;
        User4: Record User;
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryApproval: Codeunit "Library - Document Approvals";
        LibraryRandom: Codeunit "Library - Random";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        IsInitialized: Boolean;

    procedure Initialize()
    begin
        if not IsInitialized then begin
            LibraryPermissions.CreateUser(User, 'User 1', false);
            LibraryPermissions.CreateUser(User2, 'User 2', false);
            LibraryPermissions.CreateUser(User3, 'User 3', false);
            LibraryPermissions.CreateUser(User4, 'User 4', false);
            IsInitialized := true;
        end;

        CreateApprovalEntryDataSet();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalUserOverviewForSpecificApprover()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        UserSetup: Record "User Setup";
        ApprovalUserOverview: TestPage "Approval User Overview";
        EntryPointEventID: Integer;
        ResponseID: Integer;
    begin
        // [SCENARIO] User Approval User Setup shown for Workflow with a specific approver
        // [GIVEN] A workflow exists
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);

        // [GIVEN] A user setup exists for multiple users
        UserSetup.Init();
        UserSetup."User ID" := User."User Name";
        UserSetup.Insert();

        UserSetup.Init();
        UserSetup."User ID" := User2."User Name";
        UserSetup.Insert();

        UserSetup.Init();
        UserSetup."User ID" := User3."User Name";
        UserSetup.Insert();

        // [GIVEN] The workflow has an approval step for a specific approver
        EntryPointEventID := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
        ResponseID := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode(), EntryPointEventID);
        WorkflowStep.Get(Workflow.Code, ResponseID);
        LibraryWorkflow.InsertApprovalArgument(ResponseID, Enum::"Workflow Approver Type"::Approver, enum::"Workflow Approver Limit Type"::"Specific Approver", '', true);
        LibraryWorkflow.UpdateWorkflowStepArgumentApproverLimitType(WorkflowStep.Argument, Enum::"Workflow Approver Type"::Approver, enum::"Workflow Approver Limit Type"::"Specific Approver", '', User."User Name");

        // [GIVEN] The workflow is enabled
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] Open the Approval User Overview page
        ApprovalUserOverview.OpenView();

        // [WHEN] Relevant workflow is selected
        ApprovalUserOverview.GoToRecord(Workflow);

        // [THEN] The Approval user Setup part is visible
        Assert.IsTrue(ApprovalUserOverview."Approval Users".Visible(), 'Approval Users part should be visible when there is a specific approver in the workflow.');

        // [THEN] The Workflow User Group Members part is not visible
        Assert.IsFalse(ApprovalUserOverview."Workflow User Group Members".Visible(), 'Workflow User Group Members part should not be visible when there is a specific approver in the workflow.');

        // [THEN] The Approval Users part should have 1 user
        ApprovalUserOverview."Approval Users".First();
        Assert.AreEqual(User."User Name", ApprovalUserOverview."Approval Users"."User ID".Value, 'Approver User Name does not match the expected user.');
        Assert.IsFalse(ApprovalUserOverview."Approval Users".Next(), 'There should be only one approver in the Approval Users part.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalUserOverviewForWorkflowUserGroup()
    var
        Workflow: Record Workflow;
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowStep: Record "Workflow Step";
        ApprovalUserOverview: TestPage "Approval User Overview";
        EntryPointEventID: Integer;
        ResponseID: Integer;
    begin
        // [SCENARIO] User Approval User Setup shown for Workflow with a specific approver
        // [GIVEN] A workflow exists
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);

        // [GIVEN] A workflow user group with two users exists
        LibraryApproval.CreateWorkflowUserGroup(WorkflowUserGroup);
        LibraryApproval.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, User."User Name", 1);
        LibraryApproval.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, User2."User Name", 2);

        // [GIVEN] The workflow has an approval step for a workflow user group
        EntryPointEventID := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
        ResponseID := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode(), EntryPointEventID);
        WorkflowStep.Get(Workflow.Code, ResponseID);
        LibraryWorkflow.InsertApprovalArgument(ResponseID, Enum::"Workflow Approver Type"::"Workflow User Group", enum::"Workflow Approver Limit Type"::"Approver Chain", WorkflowUserGroup.Code, true);
        LibraryWorkflow.UpdateWorkflowStepArgumentApproverLimitType(WorkflowStep.Argument, Enum::"Workflow Approver Type"::"Workflow User Group", enum::"Workflow Approver Limit Type"::"Approver Chain", WorkflowUserGroup.Code, '');

        //GIVEN] The workflow is enabled
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The Approval User Overview page is opened
        ApprovalUserOverview.OpenView();

        // [WHEN] Relevant workflow is selected
        ApprovalUserOverview.GoToRecord(Workflow);

        // [THEN] The Workflow User Group Members part is visible
        Assert.IsTrue(ApprovalUserOverview."Workflow User Group Members".Visible(), 'Workflow User Group members part should be visible when the workflow has a workflow user group approver type.');

        // [THEN] The Approval user Setup part is not visible
        Assert.IsFalse(ApprovalUserOverview."Approval Users".Visible(), 'Approval User Setup part should not be visible when the workflow has a workflow user group approver type.');

        // [THEN] The Workflow User Group Members part should have 2 users
        ApprovalUserOverview."Workflow User Group Members".First();

        Assert.AreEqual(User."User Name", ApprovalUserOverview."Workflow User Group Members"."User Name".Value, 'Approver User Name does not match the expected user.');
        Assert.IsTrue(ApprovalUserOverview."Workflow User Group Members".Next(), 'There should be a second approver in the Workflow User Group Members part.');
        Assert.AreEqual(User2."User Name", ApprovalUserOverview."Workflow User Group Members"."User Name".Value, 'Approver User Name does not match the expected user.');
        Assert.IsFalse(ApprovalUserOverview."Workflow User Group Members".Next(), 'There should be only two approvers in the Workflow User Group Members part.');
    end;

    [Test]
    procedure TransferFieldAlignment()
    begin
        Initialize();
        ValidateFieldAlignment(Database::"Approval Entry", Database::"Approval Entry Buffer");
        ValidateFieldAlignment(Database::"Posted Approval Entry", Database::"Approval Entry Buffer");
    end;

    procedure ValidateFieldAlignment(TableA: Integer; TableB: Integer)
    var
        FieldA: Record Field;
        FieldB: Record Field;
    begin
        FieldA.SetRange(TableNo, TableA);
        if FieldA.FindSet() then
            repeat
                if FieldB.Get(TableB, FieldA."No.") then begin
                    Assert.AreEqual(FieldA.Type, FieldB.Type, StrSubstNo('field %1 does not match on tables %2 and %3', FieldA."No.", TableA, TableB));
                    Assert.AreEqual(FieldA.Len, FieldB.Len, StrSubstNo('field %1 length does not match on tables %2 and %3', FieldA."No.", TableA, TableB));
                    Assert.AreEqual(FieldA.ObsoleteState, FieldB.ObsoleteState, StrSubstNo('field %1 obsolete state does not match on tables %2 and %3', FieldA."No.", TableA, TableB));
                    Assert.AreEqual(FieldA.RelationTableNo, FieldB.RelationTableNo, StrSubstNo('field %1 relation table does not match on tables %2 and %3', FieldA."No.", TableA, TableB));
                end;
            until FieldA.Next() = 0;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalEntryOverviewTableFilter()
    var
        ApprovalEntryBuffer: Record "Approval Entry Buffer";
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ApprovalEntryOverview: TestPage "Approval Entry Overview";
        ApprovalEntryTables: List of [Integer];
        i: Integer;
        TableId: Integer;
    begin
        // [SCENARIO] Table Name Filter Correctly Filters Approval Entries by table
        // [GIVEN] various approval entries exist
        Initialize();
        ApprovalEntryBuffer.FillBuffer(ApprovalEntry);
        ApprovalEntryBuffer.FillBuffer(PostedApprovalEntry);

        // [WHEN] The Approval Entry Overview page is opened
        ApprovalEntryOverview.OpenEdit();

        ApprovalEntryTables.AddRange(0, 17, 18, 23, 27, 36, 38, 45, 81, 110, 112, 114, 120, 122, 124, 130, 232, 245, 472, 5900, 6650, 6660);
        for i := 1 to ApprovalEntryTables.Count() do begin
            TableId := ApprovalEntryTables.Get(i);
            if TableId = 0 then continue;

            // [WHEN] Table Name filter is applied
            ApprovalEntryBuffer."Table ID" := TableId;
            ApprovalEntryOverview.TableFilter.SetValue(TableId);
            ApprovalEntryOverview.ApplyFilters.Invoke();
            ApprovalEntryBuffer.SetRange("Table ID", TableId);

            if ApprovalEntryBuffer.IsEmpty() then
                // [THEN] For tables with no approval entries, the approval entry overview is empty
                Assert.IsFalse(ApprovalEntryOverview.First(), 'Approval overview should be empty for tables with no approval entries.')
            else begin
                // [THEN] For tables with approval entries, only approval entries for the selected table are shown
                ApprovalEntryOverview.First();
                Assert.AreEqual(Format(ApprovalEntryBuffer."Table ID"), ApprovalEntryOverview."Table ID".Value, 'Table name filter not applied correctly.');
                ApprovalEntryOverview.Next();
                Assert.AreEqual(Format(ApprovalEntryBuffer."Table ID"), ApprovalEntryOverview."Table ID".Value, 'Table name filter not applied correctly.');
                ApprovalEntryOverview.Last();
                Assert.AreEqual(Format(ApprovalEntryBuffer."Table ID"), ApprovalEntryOverview."Table ID".Value, 'Table name filter not applied correctly.');
            end;
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalEntryOverviewNoFilter()
    var
        ApprovalEntryBuffer: Record "Approval Entry Buffer";
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        Customer: Record Customer;
        ApprovalEntryOverview: TestPage "Approval Entry Overview";
    begin
        // [SCENARIO] No. Filter Correctly Filters Approval Entries by Record ID
        // [GIVEN] various approval entries exist
        Initialize();
        ApprovalEntryBuffer.FillBuffer(ApprovalEntry);
        ApprovalEntryBuffer.FillBuffer(PostedApprovalEntry);

        // [WHEN] The Approval Entry Overview page is opened
        ApprovalEntryOverview.OpenEdit();

        // [WHEN] No. filter is applied using a record ID
        Customer.Init();
        Customer."No." := 'CUST001';
        Customer.Insert();
        ApprovalEntryBuffer."Record ID" := Customer.RecordId();
        ApprovalEntryOverview.TableFilter.SetValue(Database::Customer);
        ApprovalEntryOverview.NoFilter.SetValue(Customer."No.");
        ApprovalEntryOverview.ApplyFilters.Invoke();
        ApprovalEntryBuffer.SetRange("Record ID", Customer.RecordId());

        // [THEN] Only 1 approval entries for Customer CUST001 are shown
        ApprovalEntryOverview.First();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Record ID"), ApprovalEntryOverview.RecordIDText.Value, 'No. filter not applied correctly.');
        ApprovalEntryOverview.Next();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Record ID"), ApprovalEntryOverview.RecordIDText.Value, 'No. filter not applied correctly.');
        ApprovalEntryOverview.Last();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Record ID"), ApprovalEntryOverview.RecordIDText.Value, 'No. filter not applied correctly.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalEntryOverviewDocumentTypeFilter()
    var
        ApprovalEntryBuffer: Record "Approval Entry Buffer";
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ApprovalEntryOverview: TestPage "Approval Entry Overview";
        ApprovalEntryDocumentType: Enum "Approval Document Type";
        PostedFilter: Option All,"Approval Entries","Posted Approval Entries";
        i: Integer;
    begin
        // [SCENARIO] Document Type Filter Correctly Filters Approval Entries by Document Type
        // [GIVEN] various approval entries exist
        Initialize();
        ApprovalEntryBuffer.FillBuffer(ApprovalEntry);
        ApprovalEntryBuffer.FillBuffer(PostedApprovalEntry);

        // [WHEN] The Approval Entry Overview page is opened
        ApprovalEntryOverview.OpenEdit();
        // [GIVEN] Posted filter is set as the document type filter does not get applied to posted approval entries
        ApprovalEntryOverview.PostedFilter.SetValue(PostedFilter::"Approval Entries");

        for i := ApprovalEntryDocumentType::Quote.AsInteger() to ApprovalEntryDocumentType::Payment.AsInteger() do begin
            ApprovalEntryBuffer."Document Type" := Enum::"Approval Document Type".FromInteger(i);
            if ApprovalEntryBuffer."Document Type" = Enum::"Approval Document Type"::" " then
                continue;

            // [WHEN] Document Type filter is applied
            ApprovalEntryDocumentType := Enum::"Approval Document Type".FromInteger(i);
            ApprovalEntryOverview.DocumentTypeFilter.SetValue(ApprovalEntryDocumentType);
            ApprovalEntryOverview.ApplyFilters.Invoke();
            ApprovalEntryBuffer.SetRange("Document Type", ApprovalEntryDocumentType);

            if ApprovalEntryBuffer.IsEmpty() then
                // [THEN] For Document Types with no approval entries, the approval entry overview is empty
                Assert.IsFalse(ApprovalEntryOverview.First(), 'Approval overview should be empty for Document Types with no approval entries.')
            else begin
                // [THEN] For Document Types with approval entries, only approval entries for the selected Document Type are shown
                ApprovalEntryOverview.First();
                Assert.AreEqual(Format(ApprovalEntryBuffer."Document Type"), ApprovalEntryOverview."Document Type".Value, 'Document type filter not applied correctly.');
                ApprovalEntryOverview.Next();
                Assert.AreEqual(Format(ApprovalEntryBuffer."Document Type"), ApprovalEntryOverview."Document Type".Value, 'Document type filter not applied correctly.');
                ApprovalEntryOverview.Last();
                Assert.AreEqual(Format(ApprovalEntryBuffer."Document Type"), ApprovalEntryOverview."Document Type".Value, 'Document type filter not applied correctly.');
            end;
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalEntryOverviewDocumentNoFilter()
    var
        ApprovalEntryBuffer: Record "Approval Entry Buffer";
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ApprovalEntryOverview: TestPage "Approval Entry Overview";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Document No. Filter Correctly Filters Approval Entries by Document No.
        // [GIVEN] various approval entries exist
        Initialize();
        ApprovalEntryBuffer.FillBuffer(ApprovalEntry);
        ApprovalEntryBuffer.FillBuffer(PostedApprovalEntry);

        // [WHEN] The Approval Entry Overview page is opened
        ApprovalEntryOverview.OpenEdit();

        // [WHEN] Document No. filter is applied
        DocumentNo := 'SALES001';
        ApprovalEntryBuffer."Document No." := DocumentNo;
        ApprovalEntryOverview.DocumentNoFilter.SetValue(DocumentNo);
        ApprovalEntryOverview.ApplyFilters.Invoke();
        ApprovalEntryBuffer.SetRange("Document No.", DocumentNo);

        // [THEN] For Document Numbers with approval entries, only approval entries for the selected Document No. are shown
        ApprovalEntryOverview.First();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Document No."), ApprovalEntryOverview."Document No.".Value, 'Document No. filter not applied correctly.');
        ApprovalEntryOverview.Next();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Document No."), ApprovalEntryOverview."Document No.".Value, 'Document No. filter not applied correctly.');
        ApprovalEntryOverview.Last();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Document No."), ApprovalEntryOverview."Document No.".Value, 'Document No. filter not applied correctly.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalEntryOverviewPostedFilter()
    var
        ApprovalEntryBuffer: Record "Approval Entry Buffer";
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ApprovalEntryOverview: TestPage "Approval Entry Overview";
        PostedFilter: Option All,"Approval Entries","Posted Approval Entries";
    begin
        // [SCENARIO] Posted Filter Correctly Filters Approval Entries by posted status
        // [GIVEN] various approval entries exist
        Initialize();
        ApprovalEntryBuffer.FillBuffer(ApprovalEntry);
        ApprovalEntryBuffer.FillBuffer(PostedApprovalEntry);

        // [WHEN] The Approval Entry Overview page is opened
        ApprovalEntryOverview.OpenEdit();


        // [WHEN] Posted filter of "Approval Entries" is applied
        ApprovalEntryOverview.PostedFilter.SetValue(PostedFilter::"Approval Entries");
        ApprovalEntryOverview.ApplyFilters.Invoke();
        ApprovalEntryBuffer.SetRange(Posted, false);

        // [THEN] If there are unposted approval entries, the only the unposted approval entries are shown
        ApprovalEntryOverview.First();
        Assert.AreEqual(Format(false), ApprovalEntryOverview.Posted.Value, 'Posted filter not applied correctly.');
        ApprovalEntryOverview.Next();
        Assert.AreEqual(Format(false), ApprovalEntryOverview.Posted.Value, 'Posted filter not applied correctly.');
        ApprovalEntryOverview.Last();
        Assert.AreEqual(Format(false), ApprovalEntryOverview.Posted.Value, 'Posted filter not applied correctly.');

        // [WHEN] Posted filter of "Approval Entries" is applied
        ApprovalEntryOverview.PostedFilter.SetValue(PostedFilter::"Posted Approval Entries");
        ApprovalEntryOverview.ApplyFilters.Invoke();
        ApprovalEntryBuffer.SetRange(Posted, true);

        // [THEN] If there are posted approval entries, the only the posted approval entries are shown
        ApprovalEntryOverview.First();
        Assert.AreEqual(Format(true), ApprovalEntryOverview.Posted.Value, 'Posted filter not applied correctly.');
        ApprovalEntryOverview.Next();
        Assert.AreEqual(Format(true), ApprovalEntryOverview.Posted.Value, 'Posted filter not applied correctly.');
        ApprovalEntryOverview.Last();
        Assert.AreEqual(Format(true), ApprovalEntryOverview.Posted.Value, 'Posted filter not applied correctly.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalEntryOverviewSenderIDFilter()
    var
        ApprovalEntryBuffer: Record "Approval Entry Buffer";
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ApprovalEntryOverview: TestPage "Approval Entry Overview";
    begin
        // [SCENARIO] Sender ID Filter Correctly Filters Approval Entries by Sender ID
        // [GIVEN] various approval entries exist
        Initialize();
        ApprovalEntryBuffer.FillBuffer(ApprovalEntry);
        ApprovalEntryBuffer.FillBuffer(PostedApprovalEntry);

        // [WHEN] The Approval Entry Overview page is opened
        ApprovalEntryOverview.OpenEdit();

        // [WHEN] Sender ID filter is applied
        ApprovalEntryBuffer."Sender ID" := User."User Name";
        ApprovalEntryOverview.SenderIDFilter.SetValue(User."User Name");
        ApprovalEntryOverview.ApplyFilters.Invoke();
        ApprovalEntryBuffer.SetRange("Sender ID", User."User Name");

        // [THEN] For Sender IDs with approval entries, only approval entries for the selected Sender ID are shown
        ApprovalEntryOverview.First();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Sender ID"), ApprovalEntryOverview."Sender ID".Value, 'Sender ID filter not applied correctly.');
        ApprovalEntryOverview.Next();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Sender ID"), ApprovalEntryOverview."Sender ID".Value, 'Sender ID filter not applied correctly.');
        ApprovalEntryOverview.Last();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Sender ID"), ApprovalEntryOverview."Sender ID".Value, 'Sender ID filter not applied correctly.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalEntryOverviewSenderApproverIDFilter()
    var
        ApprovalEntryBuffer: Record "Approval Entry Buffer";
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ApprovalEntryOverview: TestPage "Approval Entry Overview";
    begin
        // [SCENARIO] Approver ID Filter Correctly Filters Approval Entries by Approver ID
        // [GIVEN] various approval entries exist
        Initialize();
        ApprovalEntryBuffer.FillBuffer(ApprovalEntry);
        ApprovalEntryBuffer.FillBuffer(PostedApprovalEntry);

        // [WHEN] The Approval Entry Overview page is opened
        ApprovalEntryOverview.OpenEdit();

        // [WHEN] Approver ID filter is applied
        ApprovalEntryBuffer."Approver ID" := User3."User Name";
        ApprovalEntryOverview.ApproverIDFilter.SetValue(User3."User Name");
        ApprovalEntryOverview.ApplyFilters.Invoke();
        ApprovalEntryBuffer.SetRange("Approver ID", User3."User Name");

        // [THEN] For Approver IDs with approval entries, only approval entries for the selected Approver ID are shown
        ApprovalEntryOverview.First();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Approver ID"), ApprovalEntryOverview."Approver ID".Value, 'Approver ID filter not applied correctly.');
        ApprovalEntryOverview.Next();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Approver ID"), ApprovalEntryOverview."Approver ID".Value, 'Approver ID filter not applied correctly.');
        ApprovalEntryOverview.Last();
        Assert.AreEqual(Format(ApprovalEntryBuffer."Approver ID"), ApprovalEntryOverview."Approver ID".Value, 'Approver ID filter not applied correctly.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApprovalEntryOverviewDateFilter()

    var
        ApprovalEntryBuffer: Record "Approval Entry Buffer";
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ApprovalEntryOverview: TestPage "Approval Entry Overview";
        PreviousDate: Date;
        ApprovalOverviewDate: Date;
        DateFilter: Text;
    begin
        // [SCENARIO] Date Filter Correctly Filters Approval Entries by date
        // [GIVEN] various approval entries exist
        Initialize();

        ApprovalEntryBuffer.FillBuffer(ApprovalEntry);
        ApprovalEntryBuffer.FillBuffer(PostedApprovalEntry);

        // [WHEN] The Approval Entry Overview page is opened
        ApprovalEntryOverview.OpenEdit();

        // [WHEN] Date filter is applied
        PreviousDate := CalcDate('<-1D>', CurrentDateTime().Date);
        DateFilter := '>' + Format(PreviousDate);
        ApprovalEntryOverview.DateFilter.SetValue(DateFilter);
        ApprovalEntryOverview.ApplyFilters.Invoke();

        // [THEN] For approval entries within the date filter, only approval entries within the date range are shown
        ApprovalEntryOverview.First();
        Evaluate(ApprovalOverviewDate, ApprovalEntryOverview."Last Date-Time Modified".Value);

        Assert.IsTrue(ApprovalOverviewDate > PreviousDate, 'Date filter not applied correctly.');
        ApprovalEntryOverview.Next();
        Assert.IsTrue(ApprovalOverviewDate > PreviousDate, 'Date filter not applied correctly.');
        ApprovalEntryOverview.Last();
        Assert.IsTrue(ApprovalOverviewDate > PreviousDate, 'Date filter not applied correctly.');
    end;

    procedure CreateApprovalEntryDataSet()
    var
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvHeader: Record "Purch. Inv. Header";
        CurrentDate: DateTime;
        PreviousDate: DateTime;
    begin
        CurrentDate := CurrentDateTime();
        PreviousDate := CurrentDateTime - (24 * 3600 * 1000);

        CreateApprovalEntryBasic(ApprovalEntry, Database::"Sales Header", Enum::"Approval Document Type"::Order, 'SALES001', Enum::"Approval Status"::Approved, Enum::"Workflow Approval Limit Type"::"Approval Limits", SalesHeader.RecordId(), Enum::"Workflow Approval Type"::Approver, User."User Name", User2."User Name", Today(), CurrentDate, 1000);
        CreateApprovalEntryBasic(ApprovalEntry, Database::"Sales Header", Enum::"Approval Document Type"::Order, 'SALES002', Enum::"Approval Status"::Approved, Enum::"Workflow Approval Limit Type"::"Approval Limits", SalesHeader.RecordId(), Enum::"Workflow Approval Type"::Approver, User."User Name", User2."User Name", Today(), PreviousDate, 1500);
        CreateApprovalEntryBasic(ApprovalEntry, Database::"Sales Header", Enum::"Approval Document Type"::Quote, 'SALES003', Enum::"Approval Status"::Approved, Enum::"Workflow Approval Limit Type"::"Approval Limits", SalesHeader.RecordId(), Enum::"Workflow Approval Type"::Approver, User."User Name", User2."User Name", Today(), PreviousDate, 1500);
        CreateApprovalEntryBasic(ApprovalEntry, Database::"Sales Header", Enum::"Approval Document Type"::Invoice, 'SALES004', Enum::"Approval Status"::Approved, Enum::"Workflow Approval Limit Type"::"Approval Limits", SalesHeader.RecordId(), Enum::"Workflow Approval Type"::Approver, User."User Name", User2."User Name", Today(), PreviousDate, 1500);
        CreatePostedApprovalEntryBasic(PostedApprovalEntry, Database::"Sales Invoice Header", Enum::"Approval Document Type"::" ", 'SALESINV001', Enum::"Approval Status"::Approved, Enum::"Workflow Approval Limit Type"::"Approval Limits", SalesInvHeader.RecordId(), Enum::"Workflow Approval Type"::Approver, User."User Name", User2."User Name", Today(), CurrentDate, 1500);

        //Need to create customer records to get a valid Record ID
        Customer.Init();
        Customer."No." := 'CUST001';
        CreateApprovalEntryBasic(ApprovalEntry, Database::Customer, Enum::"Approval Document Type"::" ", Customer."No.", Enum::"Approval Status"::Open, Enum::"Workflow Approval Limit Type"::"Approval Limits", Customer.RecordId(), Enum::"Workflow Approval Type"::Approver, User3."User Name", User4."User Name", Today(), CurrentDate, 2000);
        Clear(Customer);
        CreatePostedApprovalEntryBasic(PostedApprovalEntry, Database::Customer, Enum::"Approval Document Type"::" ", 'CUST002', Enum::"Approval Status"::Open, Enum::"Workflow Approval Limit Type"::"Approval Limits", Customer.RecordId(), Enum::"Workflow Approval Type"::Approver, User2."User Name", User4."User Name", Today(), PreviousDate, 3000);

        CreateApprovalEntryBasic(ApprovalEntry, Database::Item, Enum::"Approval Document Type"::" ", 'ITEM001', Enum::"Approval Status"::Approved, Enum::"Workflow Approval Limit Type"::"Approval Limits", Item.RecordId(), Enum::"Workflow Approval Type"::Approver, User."User Name", User3."User Name", Today(), CurrentDate, 500);
        CreatePostedApprovalEntryBasic(PostedApprovalEntry, Database::Item, Enum::"Approval Document Type"::" ", 'ITEM002', Enum::"Approval Status"::Approved, Enum::"Workflow Approval Limit Type"::"Approval Limits", Item.RecordId(), Enum::"Workflow Approval Type"::Approver, User2."User Name", User3."User Name", Today(), PreviousDate, 750);

        CreateApprovalEntryBasic(ApprovalEntry, Database::"Purchase Header", Enum::"Approval Document Type"::Order, 'PURCH001', Enum::"Approval Status"::Open, Enum::"Workflow Approval Limit Type"::"Approval Limits", PurchaseHeader.RecordId(), Enum::"Workflow Approval Type"::Approver, User4."User Name", User."User Name", Today(), CurrentDate, 1200);
        CreateApprovalEntryBasic(ApprovalEntry, Database::"Purchase Header", Enum::"Approval Document Type"::Quote, 'PURCH002', Enum::"Approval Status"::Open, Enum::"Workflow Approval Limit Type"::"Approval Limits", PurchaseHeader.RecordId(), Enum::"Workflow Approval Type"::Approver, User4."User Name", User."User Name", Today(), CurrentDate, 1200);
        CreatePostedApprovalEntryBasic(PostedApprovalEntry, Database::"Purch. Inv. Header", Enum::"Approval Document Type"::" ", 'PURCHINV001', Enum::"Approval Status"::Open, Enum::"Workflow Approval Limit Type"::"Approval Limits", PurchaseInvHeader.RecordId(), Enum::"Workflow Approval Type"::Approver, User3."User Name", User2."User Name", Today(), PreviousDate, 1800);
    end;

    procedure CreateApprovalEntryBasic(var ApprovalEntry: Record "Approval Entry"; TableId: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20]; StatusOption: Enum "Approval Status"; LimitType: Enum "Workflow Approval Limit Type"; RecID: RecordID; ApprovalType: Enum "Workflow Approval Type"; Approver: Code[50]; Requestor: Code[50]; DueDate: Date; LastModifiedDateTime: DateTime; AmountDec: Decimal)
    begin
        Clear(ApprovalEntry);
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := TableId;
        ApprovalEntry."Document Type" := DocumentType;
        ApprovalEntry."Document No." := DocumentNo;
        ApprovalEntry."Sequence No." := LibraryRandom.RandIntInRange(10000, 100000);
        ApprovalEntry.Status := StatusOption;
        ApprovalEntry."Limit Type" := LimitType;
        ApprovalEntry."Record ID to Approve" := RecID;
        ApprovalEntry."Approval Type" := ApprovalType;
        ApprovalEntry."Due Date" := DueDate;
        ApprovalEntry.Amount := AmountDec;
        ApprovalEntry."Approver ID" := Approver;
        ApprovalEntry."Sender ID" := Requestor;
        ApprovalEntry."Last Date-Time Modified" := LastModifiedDateTime;
        ApprovalEntry.Insert();
    end;

    procedure CreatePostedApprovalEntryBasic(var PostedApprovalEntry: Record "Posted Approval Entry"; TableId: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20]; StatusOption: Enum "Approval Status"; LimitType: Enum "Workflow Approval Limit Type"; RecID: RecordID; ApprovalType: Enum "Workflow Approval Type"; Approver: Code[50]; Requestor: Code[50]; DueDate: Date; LastModifiedDateTime: DateTime; AmountDec: Decimal)
    begin
        Clear(PostedApprovalEntry);
        PostedApprovalEntry.Init();
        PostedApprovalEntry."Table ID" := TableId;
        PostedApprovalEntry."Document No." := DocumentNo;
        PostedApprovalEntry."Sequence No." := LibraryRandom.RandIntInRange(10000, 100000);
        PostedApprovalEntry.Status := StatusOption;
        PostedApprovalEntry."Limit Type" := LimitType;
        PostedApprovalEntry."Posted Record ID" := RecID;
        PostedApprovalEntry."Approval Type" := ApprovalType;
        PostedApprovalEntry."Due Date" := DueDate;
        PostedApprovalEntry.Amount := AmountDec;
        PostedApprovalEntry."Approver ID" := Approver;
        PostedApprovalEntry."Sender ID" := Requestor;
        PostedApprovalEntry."Last Date-Time Modified" := LastModifiedDateTime;
        PostedApprovalEntry.Insert();
    end;
}