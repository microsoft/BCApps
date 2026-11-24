// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Foundation.Attachment;
using System.Text;
using System.Utilities;

// [FEATURE] [Expense Agent] [Corporate Card] [Report Lines] [API]
// API-level tests for corporate card transactions as expense report lines. The cardExpenseAwaitingReport field
// (replaces pendingCardExpense), the expenseReportLineId response property and the addCardExpenseToReport and
// attachCardReceipt actions are PLACEHOLDERS for APIs that do not exist yet. Both actions are Expense Agent entry
// points; without the Expense Agent, card expenses follow the standard BC flow. Their names and payload are defined once in the labels and request
// builders below, so they can be aligned with the final API in one place. Tests that need an unimplemented change
// fail until the change lands; they are intentionally not disabled.
codeunit 148374 "EA Card Report Line API Tests"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
        ExpensesServiceNameTok: Label 'expenses', Locked = true;
        ExpenseReportsServiceNameTok: Label 'expenseReports', Locked = true;
        ExpenseReportLinesServiceNameTok: Label 'expenseReportLines', Locked = true;
        CardExpenseMatchesServiceNameTok: Label 'cardExpenseMatches', Locked = true;
        // Placeholders for APIs that do not exist yet.
        AddCardExpenseToReportActionTok: Label 'Microsoft.NAV.addCardExpenseToReport', Locked = true;
        AttachCardReceiptActionTok: Label 'Microsoft.NAV.attachCardReceipt', Locked = true;
        CardExpenseAwaitingReportFieldTok: Label 'cardExpenseAwaitingReport', Locked = true;
        ExpenseReportLineIdPropertyTok: Label 'expenseReportLineId', Locked = true;
        CardIdTok: Label 'CORPCARD-0001', Locked = true;
        OtherCardIdTok: Label 'CORPCARD-0002', Locked = true;
        MerchantNameTok: Label 'CONTOSO COFFEE', Locked = true;
        ReceiptFileNameTok: Label 'receipt.png', Locked = true;
        OtherReceiptFileNameTok: Label 'other-receipt.jpg', Locked = true;
        RejectedByBusinessRuleTok: Label 'Response code is 400', Locked = true;
        OnePixelPngBase64Tok: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAen63NgAAAAASUVORK5CYII=', Locked = true;

    // ---------------------------------------------------------------------------------------------
    // Adding card expenses to reports and listing card expenses that wait for a report
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure AddCardExpenseToReportAPIAddsOpenCardExpenseWithoutCategory()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
    begin
        // [SCENARIO] "Create reports" adds an open card expense without a category through the Expense Agent action, which
        // releases it with the relaxed category rule and adds it to the report in one call.
        Initialize();

        // [GIVEN] An open card expense without a category and an open report.
        CreateCardExpense(Expense);
        ClearCategory(Expense);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        Commit();

        // [WHEN] addCardExpenseToReport is called with the expense id.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetReportActionURL(ExpenseReportHeader, AddCardExpenseToReportActionTok), CreateAddExpenseRequest(Expense), ResponseText, 200);

        // [THEN] The report has a card line without a category and the expense is submitted on the report.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseReportLine, 1);
        ExpenseReportLine.FindFirst();
        ExpenseReportLine.TestField("Credit Card Feed No.", Expense."Credit Card Feed No.");
        ExpenseReportLine.TestField(Amount, Expense.Amount);
        ExpenseReportLine.TestField("Expense Category", '');
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Submitted);
        CompleteTest();
    end;

    [Test]
    procedure AddCardExpenseToReportAPIAddsReleasedCardExpense()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ResponseText: Text;
    begin
        // [SCENARIO] A card expense that is already released, for example after "Remove from report", is added again by
        // the same action.
        Initialize();

        // [GIVEN] A released card expense with a category and an open report.
        CreateCardExpense(Expense);
        CreateCardCategory(ExpenseCategory);
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Modify(true);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        Commit();

        // [WHEN] addCardExpenseToReport is called with the expense id.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetReportActionURL(ExpenseReportHeader, AddCardExpenseToReportActionTok), CreateAddExpenseRequest(Expense), ResponseText, 200);

        // [THEN] The report has a card line for the expense.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseReportLine, 1);
        CompleteTest();
    end;

    [Test]
    procedure AddCardExpenseToReportAPIRejectsLinkedManualExpense()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
    begin
        // [SCENARIO] The Expense Agent action is only for expenses created from a card transaction. A manual expense that
        // is linked to a transaction follows the standard flow.
        Initialize();

        // [GIVEN] An open manual expense linked to a card transaction and an open report.
        CreateLinkedManualExpense(Expense);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        Commit();

        // [WHEN] addCardExpenseToReport is called with the linked manual expense.
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetReportActionURL(ExpenseReportHeader, AddCardExpenseToReportActionTok), CreateAddExpenseRequest(Expense), ResponseText, 200);
        AssertRejectedByBusinessRule();

        // [THEN] The expense is not added and stays open.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        Assert.RecordIsEmpty(ExpenseReportLine);
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Open);
        CompleteTest();
    end;

    [Test]
    procedure AddCardExpenseToReportAPIRejectsOtherUsersCardExpense()
    var
        Expense: Record Expense;
        OtherExpense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
    begin
        // [SCENARIO] The Expense Agent action only adds card expenses of the report's expense user.
        Initialize();

        // [GIVEN] A report of the first expense user and an open card expense of another expense user.
        CreateCardExpense(Expense);
        CreateCardExpense(OtherExpense, OtherCardIdTok);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        Commit();

        // [WHEN] addCardExpenseToReport is called with the other user's expense.
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetReportActionURL(ExpenseReportHeader, AddCardExpenseToReportActionTok), CreateAddExpenseRequest(OtherExpense), ResponseText, 200);
        AssertRejectedByBusinessRule();

        // [THEN] The expense is not added and stays open.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        Assert.RecordIsEmpty(ExpenseReportLine);
        OtherExpense.Get(OtherExpense."No.");
        OtherExpense.TestField(Status, OtherExpense.Status::Open);
        CompleteTest();
    end;

    [Test]
    procedure ReportWithCardLineWithoutCategoryCannotBeReleased()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] A card line added without a category does not relax report release; the user must set a category on
        // the line first.
        Initialize();

        // [GIVEN] A card line without a category, added through "Create reports".
        CreateCardLineWithoutCategory(Expense, ExpenseReportLine);
        Commit();

        // [WHEN] The report is released.
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] The missing category blocks the release.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption("Expense Category"));
        CompleteTest();
    end;
    [Test]
    procedure ExpensesAPICardExpenseAwaitingReportListsOnlyCardExpensesNotOnReport()
    var
        AwaitingExpense: Record Expense;
        ReleasedAwaitingExpense: Record Expense;
        OnReportExpense: Record Expense;
        LinkedManualExpense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseIds: List of [Guid];
        ResponseText: Text;
    begin
        // [SCENARIO] cardExpenseAwaitingReport, which the pending page filters on, is true only for card expenses
        // (Source = CorporateCard) that are not on a report, open or released.
        Initialize();

        // [GIVEN] An open and a released card expense not on a report, a card expense on a report and a manual expense
        // linked to a transaction.
        CreateCardExpense(AwaitingExpense);
        CreateCardExpense(ReleasedAwaitingExpense);
        CreateCardCategory(ExpenseCategory);
        ReleasedAwaitingExpense.Validate("Expense Category", ExpenseCategory.Code);
        ReleasedAwaitingExpense.Modify(true);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(ReleasedAwaitingExpense);
        CreateCardLine(OnReportExpense, ExpenseReportLine);
        CreateLinkedManualExpense(LinkedManualExpense);
        Commit();

        // [WHEN] The expenses of the expense user are filtered on cardExpenseAwaitingReport eq true.
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(
            ResponseText,
            LibraryGraphMgt.AppendQueryParameterToTargetURL(
                GetUserScopedURL(AwaitingExpense, ExpensesServiceNameTok), '$filter=' + CardExpenseAwaitingReportFieldTok + ' eq true'),
            200);

        // [THEN] Only the card expenses that are not on a report are returned, open or released.
        GetIds(ResponseText, 'value', ExpenseIds);
        Assert.AreEqual(2, ExpenseIds.Count(), 'Only card expenses that are not on a report must wait for a report.');
        Assert.IsTrue(ExpenseIds.Contains(AwaitingExpense.SystemId), 'The open card expense that is not on a report must be listed.');
        Assert.IsTrue(ExpenseIds.Contains(ReleasedAwaitingExpense.SystemId), 'The released card expense that is not on a report must be listed.');
        CompleteTest();
    end;

    // ---------------------------------------------------------------------------------------------
    // cardExpenseMatches finds card lines on open reports
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure CardExpenseMatchesAPIReturnsCardLineOnOpenReport()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
    begin
        // [SCENARIO] A receipt from the general upload flow is matched to the card line that is already on an open report.
        Initialize();

        // [GIVEN] A card line of 20 without a receipt on an open report.
        CreateCardLine(Expense, ExpenseReportLine);
        Commit();

        // [WHEN] The receipt data is posted to cardExpenseMatches.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetUserScopedURL(Expense, CardExpenseMatchesServiceNameTok), CreateMatchRequest(WorkDate(), 20), ResponseText, 201);

        // [THEN] The response identifies the expense and its report line.
        Assert.AreEqual(Expense.SystemId, GetGuidProperty(ResponseText, 'expenseId'), 'The card expense on the open report must match.');
        Assert.AreEqual(
            ExpenseReportLine.SystemId, GetGuidProperty(ResponseText, ExpenseReportLineIdPropertyTok), 'The response must identify the report line.');
        CompleteTest();
    end;

    // ---------------------------------------------------------------------------------------------
    // attachCardReceipt: OCR fills only empty fields and never changes card values
    // Rule: OCR fills empty fields on the expense (so BC user edits on the expense win), then copies to the line only
    // the fields that are empty on the line (so web user edits win). Card fields never change.
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure AttachCardReceiptAttachesReceiptToExpenseAndLine()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] The receipt is attached to the submitted expense and to its line.
        Initialize();

        // [GIVEN] A card line without a receipt; its expense is submitted.
        CreateCardLine(Expense, ExpenseReportLine);
        Commit();

        // [WHEN] A receipt is attached to the card line.
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails('', 0, 0D));

        // [THEN] Both the expense and the line have the receipt.
        VerifyReceiptAttached(Expense, ExpenseReportLine);
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptFillsEmptyFieldsOnExpenseAndLine()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ReceiptDetails: JsonObject;
    begin
        // [SCENARIO] On an untouched card line, OCR fills the empty category and participants on the expense and the line.
        Initialize();

        // [GIVEN] A card line without a category, added through "Create reports".
        CreateCardLineWithoutCategory(Expense, ExpenseReportLine);
        CreateCardCategory(ExpenseCategory);
        Commit();

        // [WHEN] A receipt with a category and two participants is attached.
        ReceiptDetails := CreateReceiptDetails(ExpenseCategory.Code, 0, 0D);
        AddParticipant(ReceiptDetails, 'Alicia Thornber');
        AddParticipant(ReceiptDetails, 'Jim Glynn');
        AttachCardReceipt(ExpenseReportLine, ReceiptDetails);

        // [THEN] The expense and the line have the OCR category and participants, and keep the card amount.
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Category", ExpenseCategory.Code);
        Expense.TestField(Amount, 20);
        GetLine(ExpenseReportLine);
        ExpenseReportLine.TestField("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.TestField(Amount, 20);
        Assert.AreEqual(2, CountExpenseParticipants(Expense), 'The expense must get the OCR participants.');
        Assert.AreEqual(2, CountLineParticipants(ExpenseReportLine), 'The empty line must get the OCR participants.');
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptKeepsCategorySetOnLineByUser()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        UserCategory: Record "Expense Category";
        OcrCategory: Record "Expense Category";
    begin
        // [SCENARIO] A category the web user set on the line wins; the expense keeps the OCR category as the agent trace.
        Initialize();

        // [GIVEN] A card line without a category on which the user sets a category.
        CreateCardLineWithoutCategory(Expense, ExpenseReportLine);
        CreateCardCategory(UserCategory);
        CreateCardCategory(OcrCategory);
        ExpenseReportLine.Validate("Expense Category", UserCategory.Code);
        ExpenseReportLine.Modify(true);
        Commit();

        // [WHEN] A receipt with another category is attached.
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails(OcrCategory.Code, 0, 0D));

        // [THEN] The line keeps the user's category and the expense gets the OCR category.
        GetLine(ExpenseReportLine);
        ExpenseReportLine.TestField("Expense Category", UserCategory.Code);
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Category", OcrCategory.Code);
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptKeepsCategorySetOnExpenseByBCUser()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        BCUserCategory: Record "Expense Category";
        OcrCategory: Record "Expense Category";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO] A category a BC user set on the expense before it was added to a report is not overwritten by OCR.
        Initialize();

        // [GIVEN] A card expense whose category a BC user set, added to a report.
        CreateCardExpense(Expense);
        CreateCardCategory(BCUserCategory);
        CreateCardCategory(OcrCategory);
        Expense.Validate("Expense Category", BCUserCategory.Code);
        Expense.Modify(true);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Commit();

        // [WHEN] A receipt with another category is attached.
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails(OcrCategory.Code, 0, 0D));

        // [THEN] The expense and the line keep the BC user's category.
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Category", BCUserCategory.Code);
        GetLine(ExpenseReportLine);
        ExpenseReportLine.TestField("Expense Category", BCUserCategory.Code);
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptKeepsParticipantsOnLine()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ReceiptDetails: JsonObject;
    begin
        // [SCENARIO] Participants the user added on the line are kept; OCR participants go to the expense only.
        Initialize();

        // [GIVEN] A card line with one participant added by the user.
        CreateCardLineWithoutCategory(Expense, ExpenseReportLine);
        InsertLineParticipant(ExpenseReportLine, 'Alicia Thornber');
        Commit();

        // [WHEN] A receipt with two participants is attached.
        ReceiptDetails := CreateReceiptDetails('', 0, 0D);
        AddParticipant(ReceiptDetails, 'Jim Glynn');
        AddParticipant(ReceiptDetails, 'Sara Davis');
        AttachCardReceipt(ExpenseReportLine, ReceiptDetails);

        // [THEN] The line keeps its single participant and the expense gets the OCR participants.
        Assert.AreEqual(1, CountLineParticipants(ExpenseReportLine), 'The participants on the line must be kept.');
        Assert.AreEqual(2, CountExpenseParticipants(Expense), 'The expense must get the OCR participants.');
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptNeverChangesCardFields()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseDate: Date;
        MerchantName: Text[100];
    begin
        // [SCENARIO] OCR values for amount, date, currency and merchant never change the card values.
        Initialize();

        // [GIVEN] A card line of 20.
        CreateCardLine(Expense, ExpenseReportLine);
        ExpenseDate := Expense."Expense Date";
        MerchantName := Expense."Merchant Name";
        Commit();

        // [WHEN] A receipt of 25, dated three days later in another currency from another merchant, is attached.
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails('', 25, ExpenseDate + 3));

        // [THEN] The expense and the line keep the card values.
        Expense.Get(Expense."No.");
        Expense.TestField(Amount, 20);
        Expense.TestField("Expense Date", ExpenseDate);
        Expense.TestField("Currency Code", '');
        Expense.TestField("Merchant Name", MerchantName);
        GetLine(ExpenseReportLine);
        ExpenseReportLine.TestField(Amount, 20);
        ExpenseReportLine.TestField("Expense Date", ExpenseDate);
        ExpenseReportLine.TestField("Expense Currency Code", '');
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptWithEmptyValuesClearsNothing()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CategoryCode: Code[20];
        Description: Text[100];
    begin
        // [SCENARIO] Empty OCR values never clear existing values on the expense or the line.
        Initialize();

        // [GIVEN] A card line with a category and description.
        CreateCardLine(Expense, ExpenseReportLine);
        CategoryCode := ExpenseReportLine."Expense Category";
        Description := ExpenseReportLine.Description;
        Commit();

        // [WHEN] A receipt with no extracted values is attached.
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails('', 0, 0D));

        // [THEN] Nothing is cleared.
        GetLine(ExpenseReportLine);
        ExpenseReportLine.TestField("Expense Category", CategoryCode);
        ExpenseReportLine.TestField(Description, Description);
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Category", CategoryCode);
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptIsRejectedForManualLine()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
    begin
        // [SCENARIO] The action is only for lines linked to a card transaction.
        Initialize();

        // [GIVEN] A standalone line that is not linked to a card transaction.
        CorpCard.Get(CardIdTok);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, CorpCard."Expense User No.", '', '');
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, CorpCard."Expense User No.", ExpenseCategory.Code, '', true, '', 20);
        Commit();

        // [WHEN] A receipt is attached through attachCardReceipt.
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetAttachCardReceiptURL(ExpenseReportLine), CreateAttachCardReceiptRequest(CreateReceiptDetails('', 0, 0D)), ResponseText, 200);
        AssertRejectedByBusinessRule();

        // [THEN] The request is rejected and nothing is attached.
        Assert.AreEqual(0, CountLineAttachments(ExpenseReportLine), 'No receipt must be attached to a manual line.');
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptIsRejectedWhenReportIsNotOpen()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
    begin
        // [SCENARIO] Receipts cannot be attached to card lines of a submitted report.
        Initialize();

        // [GIVEN] A card line on a released report.
        CreateCardLine(Expense, ExpenseReportLine);
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Released;
        ExpenseReportHeader.Modify();
        Commit();

        // [WHEN] A receipt is attached.
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetAttachCardReceiptURL(ExpenseReportLine), CreateAttachCardReceiptRequest(CreateReceiptDetails('', 0, 0D)), ResponseText, 200);
        AssertRejectedByBusinessRule();

        // [THEN] The request is rejected and nothing is attached.
        Assert.AreEqual(0, CountLineAttachments(ExpenseReportLine), 'No receipt must be attached to a line of a released report.');
        Assert.AreEqual(0, CountExpenseAttachments(Expense), 'No receipt must be attached to the expense of a released report.');
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptTwiceDoesNotDuplicateAttachment()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ResponseText: Text;
    begin
        // [SCENARIO] Retrying the same receipt does not create a second attachment.
        Initialize();

        // [GIVEN] A card line with a receipt attached through the action.
        CreateCardLine(Expense, ExpenseReportLine);
        Commit();
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails('', 0, 0D));

        // [WHEN] The same receipt is sent again; the action may accept or reject the retry.
        LibraryGraphMgt.PostToWebService(
            GetAttachCardReceiptURL(ExpenseReportLine), CreateAttachCardReceiptRequest(CreateReceiptDetails('', 0, 0D)), ResponseText);

        // [THEN] The expense and the line each have one receipt.
        Assert.AreEqual(1, CountExpenseAttachments(Expense), 'The expense must have a single receipt.');
        Assert.AreEqual(1, CountLineAttachments(ExpenseReportLine), 'The line must have a single receipt.');
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptWithAnotherReceiptIsRejected()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        ResponseText: Text;
    begin
        // [SCENARIO] Once a card expense has its receipt, a different receipt cannot be attached through the action.
        Initialize();

        // [GIVEN] A card line with a receipt attached through the action.
        CreateCardLine(Expense, ExpenseReportLine);
        Commit();
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails('', 0, 0D));

        // [WHEN] Another receipt is attached.
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetAttachCardReceiptURL(ExpenseReportLine),
            CreateAttachCardReceiptRequest(CreateReceiptDetails('', 0, 0D), OtherReceiptFileNameTok, Enum::"Image Format"::Jpeg), ResponseText, 200);
        AssertRejectedByBusinessRule();

        // [THEN] The request is rejected and the first receipt is kept.
        Assert.AreEqual(1, CountExpenseAttachments(Expense), 'The expense must keep its single receipt.');
        Assert.AreEqual(1, CountLineAttachments(ExpenseReportLine), 'The line must keep its single receipt.');
        FindExpenseReceipt(Expense, DocumentAttachment);
        Assert.AreEqual(ReceiptFileNameTok, DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension", 'The first receipt must be kept.');
        CompleteTest();
    end;

    [Test]
    procedure AttachedCardReceiptCannotBeDeletedFromExpense()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] The receipt attached through the action is locked on the expense; it cannot be deleted later.
        Initialize();

        // [GIVEN] A card line with a receipt attached through the action.
        CreateCardLine(Expense, ExpenseReportLine);
        Commit();
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails('', 0, 0D));

        // [WHEN] The receipt is deleted from the expense.
        FindExpenseReceipt(Expense, DocumentAttachment);
        asserterror DocumentAttachment.Delete(true);

        // [THEN] The receipt is still attached to the expense and the line.
        VerifyReceiptAttached(Expense, ExpenseReportLine);
        CompleteTest();
    end;

    [Test]
    procedure AttachCardReceiptLinksLineReceiptToExpenseReceipt()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReceipt: Record "Document Attachment";
        LineReceipt: Record "Document Attachment";
    begin
        // [SCENARIO] The line gets the same receipt as the expense, so it cannot be removed from the line on its own.
        Initialize();

        // [GIVEN] A card line without a receipt.
        CreateCardLine(Expense, ExpenseReportLine);
        Commit();

        // [WHEN] A receipt is attached to the card line.
        AttachCardReceipt(ExpenseReportLine, CreateReceiptDetails('', 0, 0D));

        // [THEN] The line's receipt refers to the same document as the expense's receipt.
        FindExpenseReceipt(Expense, ExpenseReceipt);
        FindLineReceipt(ExpenseReportLine, LineReceipt);
        Assert.AreEqual(Format(ExpenseReceipt."Document Reference ID"), Format(LineReceipt."Document Reference ID"), 'The line receipt must refer to the expense receipt.');

        // [THEN] Deleting the receipt from the line is rejected.
        asserterror LineReceipt.Delete(true);
        LineReceipt.SetRecFilter();
        Assert.RecordIsNotEmpty(LineReceipt);
        CompleteTest();
    end;

    // ---------------------------------------------------------------------------------------------
    // The service's delete of a line and its expense cannot orphan the card transaction
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure DeletingCardLineAndExpenseThroughAPIKeepsTransactionLinked()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        ResponseText: Text;
    begin
        // [SCENARIO] The service deletes a line and then its expense. The line delete works, the expense delete is
        // refused, so the card transaction never points to a deleted expense.
        Initialize();

        // [GIVEN] A card line on an open report.
        CreateCardLine(Expense, ExpenseReportLine);
        Commit();

        // [WHEN] The line and then the expense are deleted through the API.
        LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(GetLineURL(ExpenseReportLine), '', ResponseText, 204);
        asserterror LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(
            LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok), '', ResponseText, 204);

        // [THEN] The expense still exists, is released again and is still linked to its transaction.
        Assert.IsTrue(Expense.Get(Expense."No."), 'The card expense must not be deleted.');
        Expense.TestField(Status, Expense.Status::Released);
        CorpCardTrans.Get(Expense."Credit Card Feed No.");
        CorpCardTrans.TestField("Expense No.", Expense."No.");
        CompleteTest();
    end;

    // ---------------------------------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------------------------------

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
    end;

    local procedure CompleteTest()
    begin
        CorpCardTestLib.DeleteCorpCardTransactionalData();
        LibraryExpense.CleanUpBeforeTesting();
        Commit();
    end;

    local procedure CreateCardExpense(var Expense: Record Expense)
    begin
        CreateCardExpense(Expense, CardIdTok);
    end;

    local procedure CreateCardExpense(var Expense: Record Expense; CardId: Code[50])
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        CorpCard.Get(CardId);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        CorpCardTrans.Modify(true);
        Expense.Get(ExpenseNo);
        Expense."Merchant Name" := MerchantNameTok;
        Expense.Modify();
    end;

    // Card line through the existing released path; works with the current add-to-report rules.
    local procedure CreateCardLine(var Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        CreateCardExpense(Expense);
        CreateCardCategory(ExpenseCategory);
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Modify(true);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense.Get(Expense."No.");
    end;

    // Card line without a category, as "Create reports" creates it through the addCardExpenseToReport action.
    local procedure CreateCardLineWithoutCategory(var Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ResponseText: Text;
    begin
        CreateCardExpense(Expense);
        ClearCategory(Expense);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        Commit();
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetReportActionURL(ExpenseReportHeader, AddCardExpenseToReportActionTok), CreateAddExpenseRequest(Expense), ResponseText, 200);
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        ExpenseReportLine.FindFirst();
        Expense.Get(Expense."No.");
    end;

    local procedure CreateLinkedManualExpense(var Expense: Record Expense)
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCardExpenseMatch: Codeunit "EA Corp Card Expense Match";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Require Corporate Card", false);
        ExpenseAgentSetup.Modify(true);
        CorpCard.Get(CardIdTok);
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");
        CorpCardTrans.Modify(true);
        Expense.Get(Expense."No.");
    end;

    local procedure CreateCardCategory(var ExpenseCategory: Record "Expense Category")
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Credit Card", ExpenseCategory."Expense Detail Required"::" ", ExpensePaymentMethod.Code);
    end;

    local procedure ClearCategory(var Expense: Record Expense)
    begin
        if Expense."Expense Category" = '' then
            exit;
        Expense.Validate("Expense Category", '');
        Expense.Modify(true);
    end;

    local procedure InsertLineParticipant(ExpenseReportLine: Record "Expense Report Line"; ParticipantName: Text[100])
    var
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
    begin
        ExpenseReportLineParticip.Init();
        ExpenseReportLineParticip."Expense Report No." := ExpenseReportLine."Document No.";
        ExpenseReportLineParticip."Expense Report Line No." := ExpenseReportLine."Line No.";
        ExpenseReportLineParticip."Line No." := 10000;
        ExpenseReportLineParticip."Expense No." := ExpenseReportLine."Expense No.";
        ExpenseReportLineParticip."Participant Type" := ExpenseReportLineParticip."Participant Type"::External;
        ExpenseReportLineParticip."Participant Name" := ParticipantName;
        ExpenseReportLineParticip.Insert();
    end;

    local procedure GetLine(var ExpenseReportLine: Record "Expense Report Line")
    begin
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
    end;

    local procedure CountExpenseParticipants(Expense: Record Expense): Integer
    var
        ExpenseParticipant: Record "Expense Participant";
    begin
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        exit(ExpenseParticipant.Count());
    end;

    local procedure CountLineParticipants(ExpenseReportLine: Record "Expense Report Line"): Integer
    var
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
    begin
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        exit(ExpenseReportLineParticip.Count());
    end;

    local procedure CountExpenseAttachments(Expense: Record Expense): Integer
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", Database::Expense);
        DocumentAttachment.SetRange("No.", Expense."No.");
        DocumentAttachment.SetRange("No Receipt Declaration", false);
        exit(DocumentAttachment.Count());
    end;

    local procedure CountLineAttachments(ExpenseReportLine: Record "Expense Report Line"): Integer
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", ExpenseReportLine."Document No.");
        DocumentAttachment.SetRange("Line No.", ExpenseReportLine."Line No.");
        DocumentAttachment.SetRange("No Receipt Declaration", false);
        exit(DocumentAttachment.Count());
    end;

    local procedure VerifyReceiptAttached(Expense: Record Expense; ExpenseReportLine: Record "Expense Report Line")
    begin
        Assert.AreEqual(1, CountExpenseAttachments(Expense), 'The receipt must be attached to the expense.');
        Assert.AreEqual(1, CountLineAttachments(ExpenseReportLine), 'The receipt must be attached to the line.');
        Expense.Get(Expense."No.");
        Expense.TestField("Receipt Attached", true);
        GetLine(ExpenseReportLine);
        ExpenseReportLine.TestField("Receipt Attached", true);
    end;

    // PLACEHOLDER contract for the attachCardReceipt action.
    local procedure AttachCardReceipt(ExpenseReportLine: Record "Expense Report Line"; ReceiptDetails: JsonObject)
    var
        ResponseText: Text;
    begin
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetAttachCardReceiptURL(ExpenseReportLine), CreateAttachCardReceiptRequest(ReceiptDetails), ResponseText, 200);
    end;

    local procedure CreateAttachCardReceiptRequest(ReceiptDetails: JsonObject): Text
    begin
        exit(CreateAttachCardReceiptRequest(ReceiptDetails, ReceiptFileNameTok, Enum::"Image Format"::Png));
    end;

    local procedure CreateAttachCardReceiptRequest(ReceiptDetails: JsonObject; FileName: Text; ImageFormat: Enum "Image Format"): Text
    var
        Request: JsonObject;
        ReceiptDetailsText: Text;
        RequestText: Text;
    begin
        ReceiptDetails.WriteTo(ReceiptDetailsText);
        Request.Add('fileName', FileName);
        Request.Add('fileContent', GetReceiptImageBase64(ImageFormat));
        Request.Add('receiptDetails', ReceiptDetailsText);
        Request.WriteTo(RequestText);
        exit(RequestText);
    end;

    // A real one-pixel image, built without DotNet like "Library - Expense".CreateTempBLOBWithImageOfType on main.
    local procedure GetReceiptImageBase64(ImageFormat: Enum "Image Format"): Text
    var
        Image: Codeunit Image;
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
    begin
        Image.FromBase64(OnePixelPngBase64Tok);
        Image.SetFormat(ImageFormat);
        TempBlob.CreateOutStream(OutStream);
        Image.Save(OutStream);
        TempBlob.CreateInStream(InStream);
        exit(Base64Convert.ToBase64(InStream));
    end;

    local procedure FindExpenseReceipt(Expense: Record Expense; var DocumentAttachment: Record "Document Attachment")
    begin
        DocumentAttachment.SetRange("Table ID", Database::Expense);
        DocumentAttachment.SetRange("No.", Expense."No.");
        DocumentAttachment.SetRange("No Receipt Declaration", false);
        DocumentAttachment.FindFirst();
    end;

    local procedure FindLineReceipt(ExpenseReportLine: Record "Expense Report Line"; var DocumentAttachment: Record "Document Attachment")
    begin
        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", ExpenseReportLine."Document No.");
        DocumentAttachment.SetRange("Line No.", ExpenseReportLine."Line No.");
        DocumentAttachment.SetRange("No Receipt Declaration", false);
        DocumentAttachment.FindFirst();
    end;

    // OCR details as the service extracts them. Empty values mean "not extracted".
    local procedure CreateReceiptDetails(CategoryCode: Code[20]; Amount: Decimal; ExpenseDate: Date) ReceiptDetails: JsonObject
    var
        Participants: JsonArray;
    begin
        ReceiptDetails.Add('expenseCategory', CategoryCode);
        ReceiptDetails.Add('description', '');
        if Amount <> 0 then begin
            ReceiptDetails.Add('amount', Amount);
            ReceiptDetails.Add('currencyCode', 'EUR');
            ReceiptDetails.Add('merchantName', 'Fabrikam Restaurant');
        end;
        if ExpenseDate <> 0D then
            ReceiptDetails.Add('expenseDate', Format(ExpenseDate, 0, 9));
        ReceiptDetails.Add('participants', Participants);
    end;

    local procedure AddParticipant(var ReceiptDetails: JsonObject; ParticipantName: Text)
    var
        ParticipantsToken: JsonToken;
        Participant: JsonObject;
    begin
        ReceiptDetails.Get('participants', ParticipantsToken);
        Participant.Add('participantType', 'External');
        Participant.Add('participantName', ParticipantName);
        ParticipantsToken.AsArray().Add(Participant);
    end;

    // The action must reject the request with a validation error (400), not fail because it does not exist (404).
    local procedure AssertRejectedByBusinessRule()
    begin
        Assert.ExpectedError(RejectedByBusinessRuleTok);
    end;

    local procedure GetLineURL(ExpenseReportLine: Record "Expense Report Line"): Text
    var
        ExpenseReportHeader: Record "Expense Report Header";
        TargetURL: Text;
    begin
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ExpenseReportLinesServiceNameTok);
        exit(LibraryGraphMgt.AppendPathToTargetURL(TargetURL, '(' + LibraryGraphMgt.StripBrackets(Format(ExpenseReportLine.SystemId)) + ')'));
    end;

    local procedure GetAttachCardReceiptURL(ExpenseReportLine: Record "Expense Report Line"): Text
    begin
        exit(LibraryGraphMgt.AppendPathToTargetURL(GetLineURL(ExpenseReportLine), '/' + AttachCardReceiptActionTok));
    end;

    local procedure GetReportActionURL(ExpenseReportHeader: Record "Expense Report Header"; ActionName: Text): Text
    begin
        exit(LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok, ActionName));
    end;

    local procedure GetUserScopedURL(Expense: Record Expense; SubpageServiceName: Text): Text
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        exit(LibraryGraphMgt.CreateTargetURLWithSubpage(Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok, SubpageServiceName));
    end;

    local procedure CreateAddExpenseRequest(Expense: Record Expense): Text
    var
        Request: JsonObject;
        RequestText: Text;
    begin
        Request.Add('expenseId', LibraryGraphMgt.StripBrackets(Format(Expense.SystemId)));
        Request.WriteTo(RequestText);
        exit(RequestText);
    end;

    local procedure CreateMatchRequest(ReceiptDate: Date; ReceiptAmount: Decimal): Text
    var
        Request: JsonObject;
        RequestText: Text;
    begin
        Request.Add('expenseDate', Format(ReceiptDate, 0, 9));
        Request.Add('amount', ReceiptAmount);
        Request.Add('merchantName', MerchantNameTok);
        Request.WriteTo(RequestText);
        exit(RequestText);
    end;

    local procedure GetIds(ResponseText: Text; ArrayName: Text; var Ids: List of [Guid])
    var
        Response: JsonObject;
        Rows: JsonToken;
        Row: JsonToken;
        IdToken: JsonToken;
        Id: Guid;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get(ArrayName, Rows);
        foreach Row in Rows.AsArray() do begin
            Row.AsObject().Get('id', IdToken);
            Evaluate(Id, IdToken.AsValue().AsText());
            Ids.Add(Id);
        end;
    end;

    local procedure GetGuidProperty(ResponseText: Text; PropertyName: Text) Value: Guid
    var
        Response: JsonObject;
        ValueToken: JsonToken;
    begin
        Response.ReadFrom(ResponseText);
        if not Response.Get(PropertyName, ValueToken) then
            exit;
        Evaluate(Value, ValueToken.AsValue().AsText());
    end;
}
