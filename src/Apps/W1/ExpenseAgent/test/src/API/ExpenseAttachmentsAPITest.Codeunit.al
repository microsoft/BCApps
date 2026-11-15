// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Foundation.Attachment;
using Microsoft.Integration.Graph;

codeunit 148354 "Expense Attachments API Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ExpensesServiceNameTok: Label 'expenses', Locked = true;
        AttachmentsServiceNameTok: Label 'expenseAttachments', Locked = true;
        ResourceNotFoundTok: Label 'BadRequest_ResourceNotFound', Locked = true;
        ResponseCodeTok: Label 'Response code is %1 (', Comment = '%1 = HTTP status code', Locked = true;
        ExpenseNotFoundErr: Label 'Expense with ID %1 not found.', Comment = '%1 = Expense ID', Locked = true;
        ExpenseReportLineNotFoundErr: Label 'Expense Report Line with ID %1 not found.', Comment = '%1 = Expense Report Line ID', Locked = true;
        PostedExpenseReportLineNotFoundErr: Label 'Posted Expense Report Line with ID %1 not found.', Comment = '%1 = Posted Expense Report Line ID', Locked = true;

    [Test]
    procedure LinkedLoadSkipsParentDeletedAfterItWasRead()
    var
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        ExpAttachBufferHandler: Codeunit "Exp. Attach. Buffer Handler";
        TableIds: List of [Integer];
        TableId: Integer;
        MissingParentId: Guid;
    begin
        // [SCENARIO 3249] Expanding attachments of a parent that was deleted after the platform read it returns no attachments instead of failing the request.
        TableIds.Add(Database::Expense);
        TableIds.Add(Database::"Expense Report Line");
        TableIds.Add(Database::"Posted Expense Report Line");
        foreach TableId in TableIds do begin
            // [GIVEN] The parent filter is set by the parent page's SubPageLink, as for $expand, and the parent doesn't exist.
            MissingParentId := CreateGuid();
            SetParentLinkFilter(TempAttachmentEntityBuffer, MissingParentId);
            Assert.IsTrue(ExpAttachBufferHandler.IsFilteredByParentLink(TempAttachmentEntityBuffer), 'The SubPageLink filter must be detected.');

            // [WHEN] The attachments are loaded for the linked parent.
            ExpAttachBufferHandler.LoadAttachments(
                TempAttachmentEntityBuffer, TableId, Format(MissingParentId), '', ExpAttachBufferHandler.IsFilteredByParentLink(TempAttachmentEntityBuffer));

            // [THEN] No error is raised and no attachments are returned.
            TempAttachmentEntityBuffer.Reset();
            Assert.RecordIsEmpty(TempAttachmentEntityBuffer);
        end;
    end;

    [Test]
    procedure DirectFilterOnMissingParentStillFails()
    var
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        ExpAttachBufferHandler: Codeunit "Exp. Attach. Buffer Handler";
        MissingParentId: Guid;
    begin
        // [SCENARIO 3249] A direct filter on a parent that doesn't exist still reports that the parent wasn't found.
        // [GIVEN] The parent filter comes from the request, not from the parent page's SubPageLink.
        MissingParentId := CreateGuid();
        TempAttachmentEntityBuffer.SetRange("Document Id", MissingParentId);
        Assert.IsFalse(ExpAttachBufferHandler.IsFilteredByParentLink(TempAttachmentEntityBuffer), 'A request filter must not be treated as a SubPageLink filter.');

        // [WHEN] The attachments are loaded for each parent type.
        // [THEN] The missing parent error is raised.
        asserterror ExpAttachBufferHandler.LoadAttachments(
            TempAttachmentEntityBuffer, Database::Expense, Format(MissingParentId), '', ExpAttachBufferHandler.IsFilteredByParentLink(TempAttachmentEntityBuffer));
        Assert.ExpectedError(StrSubstNo(ExpenseNotFoundErr, MissingParentId));

        asserterror ExpAttachBufferHandler.LoadAttachments(
            TempAttachmentEntityBuffer, Database::"Expense Report Line", Format(MissingParentId), '', ExpAttachBufferHandler.IsFilteredByParentLink(TempAttachmentEntityBuffer));
        Assert.ExpectedError(StrSubstNo(ExpenseReportLineNotFoundErr, MissingParentId));

        asserterror ExpAttachBufferHandler.LoadAttachments(
            TempAttachmentEntityBuffer, Database::"Posted Expense Report Line", Format(MissingParentId), '', ExpAttachBufferHandler.IsFilteredByParentLink(TempAttachmentEntityBuffer));
        Assert.ExpectedError(StrSubstNo(PostedExpenseReportLineNotFoundErr, MissingParentId));
    end;

    [Test]
    procedure ExpandedExpenseReturnsAttachments()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 3249] Expanding the attachments of an existing expense returns its attachments.
        Initialize();

        // [GIVEN] An expense with an attachment.
        CreateExpenseWithAttachment(Expense, DocumentAttachment);
        Commit();

        // [WHEN] The expense is requested with its attachments expanded.
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok);
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(TargetURL, '$expand=' + AttachmentsServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The response contains the attachment.
        Assert.AreNotEqual(
            0,
            StrPos(LowerCase(ResponseText), LowerCase(LibraryGraphMgt.StripBrackets(Format(DocumentAttachment.SystemId)))),
            'The expanded attachments must contain the attachment. Response: ' + ResponseText);
    end;

    [Test]
    procedure ExpandSkipsExpenseDeletedAfterItWasRead()
    var
        Expense: Record Expense;
        DeletedExpense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        DeletedDocumentAttachment: Record "Document Attachment";
        ExpAttachmentsAPIRaceHook: Codeunit "Exp. Attachments API Race Hook";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 3249] A list with expanded attachments doesn't fail when one of its expenses is deleted after the list read it.
        Initialize();

        // [GIVEN] Two expenses with attachments. The race hook deletes the second one after the Expenses API reads it.
        CreateExpenseWithAttachment(Expense, DocumentAttachment);
        CreateExpenseWithAttachment(DeletedExpense, DeletedDocumentAttachment);
        DeletedExpense.Description := ExpAttachmentsAPIRaceHook.DeleteWhileReadMarker();
        DeletedExpense.Modify();
        Commit();

        // [WHEN] The expenses are requested with their attachments expanded.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expenses API", ExpensesServiceNameTok);
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(
            TargetURL, '$filter=number eq ''' + Expense."No." + ''' or number eq ''' + DeletedExpense."No." + '''');
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(TargetURL, '$expand=' + AttachmentsServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The request succeeds, the remaining expense has its attachment and the deleted expense has none.
        SelectLatestVersion();
        Assert.IsFalse(DeletedExpense.GetBySystemId(DeletedExpense.SystemId), 'The race hook must have deleted the expense during the request.');
        Assert.AreNotEqual(
            0,
            StrPos(LowerCase(ResponseText), LowerCase(LibraryGraphMgt.StripBrackets(Format(DocumentAttachment.SystemId)))),
            'The expanded attachments must contain the attachment of the remaining expense. Response: ' + ResponseText);
        Assert.AreEqual(
            0,
            StrPos(LowerCase(ResponseText), LowerCase(LibraryGraphMgt.StripBrackets(Format(DeletedDocumentAttachment.SystemId)))),
            'The expanded attachments must not contain the attachment of the deleted expense. Response: ' + ResponseText);
    end;

    [Test]
    procedure DeletedExpenseIsNotFoundForDirectRequests()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ExpenseId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 3249] Direct requests for the attachments of a deleted expense still fail.
        Initialize();

        // [GIVEN] An expense with an attachment that is then deleted.
        CreateExpenseWithAttachment(Expense, DocumentAttachment);
        ExpenseId := Expense.SystemId;
        Expense.Delete(true);
        Commit();

        // [WHEN] The attachments are requested through the deleted expense.
        // [THEN] The platform reports that the expense doesn't exist.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(Format(ExpenseId), Page::"Expenses API", ExpensesServiceNameTok, AttachmentsServiceNameTok);
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 404);
        Assert.ExpectedError(StrSubstNo(ResponseCodeTok, 404));
        Assert.ExpectedError(ResourceNotFoundTok);

        // [WHEN] The attachments are filtered by the deleted expense.
        // [THEN] The missing expense error is returned.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Attachments API", AttachmentsServiceNameTok);
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(TargetURL, '$filter=expenseId eq ' + LibraryGraphMgt.StripBrackets(Format(ExpenseId)));
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 400);
        Assert.ExpectedError(StrSubstNo(ResponseCodeTok, 400));
        Assert.ExpectedError(StrSubstNo(ExpenseNotFoundErr, ExpenseId));
    end;

    [Test]
    procedure MissingAttachmentIsNotFound()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 3249] Requesting an attachment that doesn't exist on an existing expense still fails.
        Initialize();

        // [GIVEN] An expense with an attachment.
        CreateExpenseWithAttachment(Expense, DocumentAttachment);
        Commit();

        // [WHEN] An attachment that doesn't exist is requested through the expense.
        // [THEN] The platform reports that the attachment doesn't exist.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok, AttachmentsServiceNameTok);
        TargetURL := LibraryGraphMgt.AppendPathToTargetURL(TargetURL, '(' + LibraryGraphMgt.StripBrackets(Format(CreateGuid())) + ')');
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 404);
        Assert.ExpectedError(StrSubstNo(ResponseCodeTok, 404));
        Assert.ExpectedError(ResourceNotFoundTok);
    end;

    local procedure SetParentLinkFilter(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; ParentId: Guid)
    begin
        // The platform applies the SubPageLink in filter group 4 and copies it to the current filter group.
        TempAttachmentEntityBuffer.Reset();
        TempAttachmentEntityBuffer.FilterGroup(4);
        TempAttachmentEntityBuffer.SetRange("Document Id", ParentId);
        TempAttachmentEntityBuffer.FilterGroup(0);
        TempAttachmentEntityBuffer.SetRange("Document Id", ParentId);
    end;

    local procedure CreateExpenseWithAttachment(var Expense: Record Expense; var DocumentAttachment: Record "Document Attachment")
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', 100);

        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::Expense;
        DocumentAttachment."No." := Expense."No.";
        DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Expense;
        DocumentAttachment."File Name" := 'receipt';
        DocumentAttachment."File Extension" := 'txt';
        DocumentAttachment.Insert();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Attachments API Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Attachments API Test");
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Attachments API Test");
    end;
}
