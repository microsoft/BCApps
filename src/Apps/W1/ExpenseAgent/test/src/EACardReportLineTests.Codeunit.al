// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Foundation.Attachment;
using System.Utilities;

// [FEATURE] [Expense Agent] [Corporate Card] [Report Lines]
// Card transactions become expense report lines before a receipt exists. These tests describe the target behavior.
// Tests that need a change that is not implemented yet fail until the change lands; they are intentionally not disabled.
codeunit 148373 "EA Card Report Line Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryExpense: Codeunit "Library - Expense";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReceiptExpenseMatch: Codeunit "EA Receipt Expense Match";
        CardIdTok: Label 'CORPCARD-0001', Locked = true;
        MerchantNameTok: Label 'CONTOSO COFFEE', Locked = true;
        AttachmentMandatoryTok: Label 'Document Attachment is mandatory', Locked = true;
        MerchantMandatoryTok: Label 'Merchant Name is mandatory', Locked = true;
        ReceiptNoMandatoryTok: Label 'Receipt No. is mandatory', Locked = true;
        JustificationRequiredTok: Label 'Justification is required', Locked = true;
        DuplicateTok: Label 'already exists', Locked = true;
        MaxAmountTok: Label 'must not exceed', Locked = true;
        ReceiptFileNameTok: Label 'receipt.png', Locked = true;
        OnePixelPngBase64Tok: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAen63NgAAAAASUVORK5CYII=', Locked = true;

    // ---------------------------------------------------------------------------------------------
    // Without the Expense Agent, card expenses follow the standard BC flow: release with the existing rules, then add
    // to a report. Adding a card expense without a category is only possible through the Expense Agent action, which
    // the API tests cover.
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure CardExpenseWithoutCategoryStillCannotBeReleasedInBC()
    var
        Expense: Record Expense;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO] Regression: Releasing a card expense through the standard release keeps the existing rules, so a
        // category is required.
        Initialize();

        // [GIVEN] An open card expense without a category.
        CreateCardExpense(Expense, CardIdTok);
        ClearCategory(Expense);

        // [WHEN] The expense is released.
        asserterror ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [THEN] The category is required.
        Assert.ExpectedError(Expense.FieldCaption("Expense Category"));
    end;
    [Test]
    procedure OpenCardExpenseStillMustBeReleasedBeforeAddingToReport()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO] Regression: Adding to a report still requires a released expense, also for card expenses.
        Initialize();

        // [GIVEN] An open card expense.
        CreateCardExpense(Expense, CardIdTok);
        CreateReportForExpense(ExpenseReportHeader, Expense);

        // [WHEN] The expense is added to a report.
        asserterror CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [THEN] The expense must be released.
        Assert.ExpectedError(Expense.FieldCaption(Status));
    end;

    // ---------------------------------------------------------------------------------------------
    // A category change on a card line keeps the card values
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure CategoryChangeOnCardLineKeepsCardValues()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        EmployeePaidCategory: Record "Expense Category";
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO] Changing the category on a card line keeps the amount, currency, reimbursement type and payment method.
        Initialize();

        // [GIVEN] A card line of 20 and an employee-paid category.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        PaymentMethodCode := ExpenseReportLine."Payment Method Code";
        LibraryExpense.CreateExpenseCategory(
            EmployeePaidCategory, EmployeePaidCategory."Reimbursement Type"::"Employee Paid", EmployeePaidCategory."Expense Detail Required"::" ");

        // [WHEN] The line category is changed to the employee-paid category.
        ExpenseReportLine.Validate("Expense Category", EmployeePaidCategory.Code);
        ExpenseReportLine.Modify(true);

        // [THEN] The category is saved and the card values are kept.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("Expense Category", EmployeePaidCategory.Code);
        ExpenseReportLine.TestField(Amount, Expense.Amount);
        ExpenseReportLine.TestField("Expense Currency Code", Expense."Currency Code");
        ExpenseReportLine.TestField("Reimbursement Type", ExpenseReportLine."Reimbursement Type"::"Credit Card");
        ExpenseReportLine.TestField("Payment Method Code", PaymentMethodCode);
    end;

    [Test]
    procedure ClearingCategoryOnCardLineKeepsAmount()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Clearing the category on a card line keeps the card amount and currency.
        Initialize();

        // [GIVEN] A card line of 20.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);

        // [WHEN] The line category is cleared.
        ExpenseReportLine.Validate("Expense Category", '');
        ExpenseReportLine.Modify(true);

        // [THEN] The amount and currency are kept.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField(Amount, Expense.Amount);
        ExpenseReportLine.TestField("Expense Currency Code", Expense."Currency Code");
    end;

    [Test]
    procedure CategoryChangeOnManualLineStillResetsAmount()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseCategory: Record "Expense Category";
        OtherCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Regression: A category change on a line that is not linked to a card transaction still resets the amount.
        Initialize();

        // [GIVEN] A standalone line of 20 without a card transaction.
        CorpCard.Get(CardIdTok);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseCategory(OtherCategory, OtherCategory."Reimbursement Type"::"Employee Paid", OtherCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, CorpCard."Expense User No.", '', '');
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, CorpCard."Expense User No.", ExpenseCategory.Code, '', true, '', 20);

        // [WHEN] The line category is changed.
        ExpenseReportLine.Validate("Expense Category", OtherCategory.Code);
        ExpenseReportLine.Modify(true);

        // [THEN] The amount is reset as today.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField(Amount, 0);
    end;

    // ---------------------------------------------------------------------------------------------
    // "Receipt not needed" is recalculated on lines
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure LineCategoryUnderNoReceiptLimitSetsReceiptNotNeeded()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO] Setting a category whose no-receipt limit is above the line amount marks the line as not needing a receipt.
        Initialize();
        SetAllowNoReceipt(true);

        // [GIVEN] A card line of 20 and a card category with a no-receipt limit of 100.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        CreateCardCategory(ExpenseCategory, 100);

        // [WHEN] The line category is changed to that category.
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Modify(true);

        // [THEN] The line does not need a receipt.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("No Receipt Type", ExpenseReportLine."No Receipt Type"::"Receipt not needed");
    end;

    [Test]
    procedure LineCategoryAboveNoReceiptLimitClearsReceiptNotNeeded()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO] Changing to a category whose limit is below the line amount requires a receipt again.
        Initialize();
        SetAllowNoReceipt(true);

        // [GIVEN] A card line of 20 that does not need a receipt and a card category with a no-receipt limit of 10.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportLine."No Receipt Type" := ExpenseReportLine."No Receipt Type"::"Receipt not needed";
        ExpenseReportLine.Modify();
        CreateCardCategory(ExpenseCategory, 10);

        // [WHEN] The line category is changed to that category.
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Modify(true);

        // [THEN] The line needs a receipt.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("No Receipt Type", ExpenseReportLine."No Receipt Type"::" ");
    end;

    [Test]
    procedure LineNeverGetsReceiptNotNeededWhenNoReceiptIsNotAllowed()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO] Without Allow No Receipt, a category limit never removes the receipt requirement.
        Initialize();
        SetAllowNoReceipt(false);

        // [GIVEN] A card line of 20 and a card category with a no-receipt limit of 100.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        CreateCardCategory(ExpenseCategory, 100);

        // [WHEN] The line category is changed to that category.
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Modify(true);

        // [THEN] The line still needs a receipt.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("No Receipt Type", ExpenseReportLine."No Receipt Type"::" ");
    end;

    [Test]
    procedure LostReceiptOnLineIsKeptAboveNoReceiptLimit()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO] Like on the expense, a lost receipt declaration is kept when the category limit is below the amount.
        Initialize();
        SetAllowNoReceipt(true);

        // [GIVEN] A card line of 20 declared as lost receipt and a card category with a no-receipt limit of 10.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportLine."No Receipt Type" := ExpenseReportLine."No Receipt Type"::"Lost Receipt";
        ExpenseReportLine.Modify();
        CreateCardCategory(ExpenseCategory, 10);

        // [WHEN] The line category is changed to that category.
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Modify(true);

        // [THEN] The lost receipt declaration is kept.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("No Receipt Type", ExpenseReportLine."No Receipt Type"::"Lost Receipt");
    end;

    // ---------------------------------------------------------------------------------------------
    // Receipt matching finds card lines on open reports
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure ReceiptMatchesCardExpenseOnOpenReport()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] A receipt uploaded through the general flow finds the card expense that is already on an open report.
        Initialize();

        // [GIVEN] A card line of 20 without a receipt on an open report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);

        // [WHEN] A receipt of 20 from the same merchant is matched.
        // [THEN] The card expense is returned, so no duplicate expense is created.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20), 'A card expense on an open report must match the receipt.');
    end;

    [Test]
    procedure ReceiptMatchesReleasedCardExpenseOffReport()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO] A card expense can match a receipt after release, before it is added to any report.
        Initialize();

        // [GIVEN] A card expense released through the standard flow, without adding or removing a report line.
        CreateCardExpense(Expense, CardIdTok);
        CreateCardCategory(ExpenseCategory, 0);
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Modify(true);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
        Expense.TestField("Receipt Attached", false);

        // [WHEN] A receipt with the same amount, date and merchant is matched.
        // [THEN] The matcher returns the released expense itself.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20), 'The receipt must match the released off-report expense.');
    end;

    [Test]
    procedure ReceiptMatchesReleasedCardExpenseRemovedFromReport()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] After "Remove from report" the card expense is released and waits for a report. A receipt uploaded
        // through the general flow still finds it, so no duplicate expense is created.
        Initialize();

        // [GIVEN] A card line of 20 without a receipt that was removed from its report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportLine.Delete(true);
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);

        // [WHEN] A receipt of 20 from the same merchant is matched.
        // [THEN] The released card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20), 'A released card expense that waits for a report must match the receipt.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchCardExpenseOnReleasedReport()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Card expenses on a report that is no longer open are not candidates.
        Initialize();

        // [GIVEN] A card line of 20 on a released report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Released;
        ExpenseReportHeader.Modify();

        // [WHEN] A receipt of 20 is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20)), 'A card expense on a released report must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchCardLineThatHasReceipt()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] A card line that already has a receipt is not a candidate.
        Initialize();

        // [GIVEN] A card line of 20 with a receipt on an open report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportLine."Receipt Attached" := true;
        ExpenseReportLine.Modify();

        // [WHEN] A receipt of 20 is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20)), 'A card line with a receipt must not match.');
    end;

    [Test]
    procedure CheckReturnsCardExpenseOnOpenReport()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO] Checking a receipt against a card expense that is on an open report returns the expense.
        Initialize();

        // [GIVEN] A card line of 20 without a receipt on an open report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseUser.Get(Expense."Expense User No.");

        // [WHEN] A receipt of 20 is checked against the expense.
        // [THEN] The expense is returned.
        Assert.AreEqual(
            Expense.SystemId,
            ReceiptExpenseMatch.CheckMatchingExpense(ExpenseUser.SystemId, Expense.SystemId, WorkDate(), 20, '', ''),
            'The receipt must fit the card expense on the open report.');
    end;

    // ---------------------------------------------------------------------------------------------
    // Removing a card line keeps the expense released and waiting for a report; card expenses cannot be deleted
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure DeletingCardLineKeepsExpenseReleasedAndLinked()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        FeedNo: Integer;
    begin
        // [SCENARIO] "Remove from report" deletes the card line; the expense is released again, waits for a report and stays linked.
        Initialize();

        // [GIVEN] A card line on an open report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        FeedNo := Expense."Credit Card Feed No.";

        // [WHEN] The line is deleted.
        ExpenseReportLine.Delete(true);

        // [THEN] The expense is released, off the report and still linked to its transaction.
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
        Expense.TestField("Credit Card Feed No.", FeedNo);
        CorpCardTrans.Get(FeedNo);
        CorpCardTrans.TestField("Expense No.", Expense."No.");
    end;

    [Test]
    procedure CardLinkedExpenseCannotBeDeleted()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A card expense cannot be deleted, so its transaction never points to a missing expense.
        Initialize();

        // [GIVEN] An open card expense that is not on a report.
        CreateCardExpense(Expense, CardIdTok);
        Commit();

        // [WHEN] The expense is deleted.
        asserterror Expense.Delete(true);

        // [THEN] The delete is blocked and the expense still exists.
        Assert.IsTrue(Expense.Get(Expense."No."), 'The card expense must not be deleted.');
    end;

    [Test]
    procedure RemovedCardExpenseCanBeAddedToReportAgain()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] After "Remove from report" the released card expense can be added to a report again.
        Initialize();

        // [GIVEN] A card line that was removed from its report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportLine.Delete(true);
        Expense.Get(Expense."No.");
        CreateReportForExpense(ExpenseReportHeader, Expense);

        // [WHEN] The expense is added to a report again.
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [THEN] A new card line is created with the card values.
        VerifyCardLine(ExpenseReportLine, Expense);
    end;

    [Test]
    procedure DeletingReportWithCardLineKeepsExpenseReleasedAndLinked()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        FeedNo: Integer;
    begin
        // [SCENARIO] Deleting a whole draft report keeps its card expenses released and waiting for a report,
        // so no card transaction points to a deleted expense.
        Initialize();

        // [GIVEN] A card line on an open report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        FeedNo := Expense."Credit Card Feed No.";

        // [WHEN] The report is deleted.
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        ExpenseReportHeader.Delete(true);

        // [THEN] The expense is released, off the report and still linked to its transaction.
        Assert.IsTrue(Expense.Get(Expense."No."), 'The card expense must not be deleted with its report.');
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
        Expense.TestField("Credit Card Feed No.", FeedNo);
        CorpCardTrans.Get(FeedNo);
        CorpCardTrans.TestField("Expense No.", Expense."No.");
    end;

    // ---------------------------------------------------------------------------------------------
    // Moving a card line to another report keeps the card link and the receipt; the moved line can still be removed
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure MovingCardLineKeepsCardLinkAndReceipt()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        SourceLine: Record "Expense Report Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReceipt: Record "Document Attachment";
        LineReceipt: Record "Document Attachment";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        FeedNo: Integer;
    begin
        // [SCENARIO] Moving a card line with its expense and receipt to another open report keeps the card values, the
        // link to the transaction and the receipt. The move must not be treated as "Remove from report".
        Initialize();

        // [GIVEN] A card expense of 20 with a receipt, released and added to an open report, and a second open report.
        CreateCardExpense(Expense, CardIdTok);
        CreateCardCategory(ExpenseCategory, 0);
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Modify(true);
        AttachReceiptToExpense(Expense);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        CreateReportForExpense(SourceExpenseReportHeader, Expense);
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, SourceExpenseReportHeader);
        CreateReportForExpense(TargetExpenseReportHeader, Expense);
        FeedNo := Expense."Credit Card Feed No.";

        // [WHEN] The line is moved to the second report.
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        // [THEN] The source report has no line left and the moved line keeps the card values and the transaction link.
        SourceLine.SetRange("Document No.", SourceExpenseReportHeader."No.");
        Assert.RecordIsEmpty(SourceLine);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("Document No.", TargetExpenseReportHeader."No.");
        ExpenseReportLine.TestField("Credit Card Feed No.", FeedNo);
        ExpenseReportLine.TestField("Corporate Card Id", CardIdTok);
        ExpenseReportLine.TestField(Amount, 20);
        ExpenseReportLine.TestField("Receipt Attached", true);

        // [THEN] The expense is submitted on the target report and still linked to its transaction.
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Report No.", TargetExpenseReportHeader."No.");
        Expense.TestField(Status, Expense.Status::Submitted);
        Expense.TestField("Credit Card Feed No.", FeedNo);
        CorpCardTrans.Get(FeedNo);
        CorpCardTrans.TestField("Expense No.", Expense."No.");

        // [THEN] The moved line has one receipt, and it refers to the expense's receipt.
        FindExpenseReceipt(Expense, ExpenseReceipt);
        FindLineReceipt(ExpenseReportLine, LineReceipt);
        Assert.AreEqual(1, LineReceipt.Count(), 'The moved line must have a single receipt.');
        Assert.AreEqual(Format(ExpenseReceipt."Document Reference ID"), Format(LineReceipt."Document Reference ID"), 'The moved line receipt must refer to the expense receipt.');
    end;

    [Test]
    procedure MovedCardLineCanBeRemovedFromReport()
    var
        Expense: Record Expense;
        TargetExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        FeedNo: Integer;
    begin
        // [SCENARIO] A card line that was moved to another report can still be removed from that report; the expense is
        // released again, waits for a report and stays linked to its transaction.
        Initialize();

        // [GIVEN] A card line that was moved to a second open report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        CreateReportForExpense(TargetExpenseReportHeader, Expense);
        ExpenseReportLine.MoveToExpenseReport(TargetExpenseReportHeader."No.");
        FeedNo := Expense."Credit Card Feed No.";

        // [WHEN] The moved line is deleted.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.Delete(true);

        // [THEN] The expense is released, off the report and still linked to its transaction.
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
        Expense.TestField("Credit Card Feed No.", FeedNo);
        CorpCardTrans.Get(FeedNo);
        CorpCardTrans.TestField("Expense No.", Expense."No.");
    end;

    // ---------------------------------------------------------------------------------------------
    // Expense rules on card lines (Use Rules on, credit card feed on)
    // Kept as is: attachment enforcement, merchant name mandatory, justification conditions, and duplicate
    // detection against non-card lines. Relaxed for card lines: duplicates between different card transactions,
    // Receipt No. Mandatory, and amount conditions the user cannot fix because the card amount is locked.
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure CardLineWithoutReceiptGetsAttachmentViolation()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Rules kept: a card line without a receipt is flagged when its category requires an attachment.
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);

        // [GIVEN] A card line whose category enforces attachments.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        SetAttachmentEnforcement(ExpenseReportLine."Expense Category", Enum::"Expense Attachment Enforcement"::Error);

        // [WHEN] The line is validated against the rules.
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] The missing receipt is a rule violation.
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, AttachmentMandatoryTok), 'A card line without a receipt must be flagged.');
    end;

    [Test]
    procedure CardLineNotNeedingReceiptHasNoAttachmentViolation()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Rules kept: "Receipt not needed" satisfies attachment enforcement on a card line.
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);

        // [GIVEN] A card line that does not need a receipt, whose category enforces attachments.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        SetAttachmentEnforcement(ExpenseReportLine."Expense Category", Enum::"Expense Attachment Enforcement"::Error);
        ExpenseReportLine."No Receipt Type" := ExpenseReportLine."No Receipt Type"::"Receipt not needed";
        ExpenseReportLine.Modify();

        // [WHEN] The line is validated against the rules.
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] There is no attachment violation.
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, AttachmentMandatoryTok), 'A card line that does not need a receipt must not be flagged.');
    end;

    [Test]
    procedure CardLineSatisfiesMerchantNameMandatory()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO] Rules kept: the merchant from the card transaction satisfies Merchant Name Mandatory.
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Merchant Name Mandatory" := true;
        ExpenseAgentSetup.Modify();

        // [GIVEN] A card line with the transaction's merchant.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);

        // [WHEN] The line is validated against the rules.
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] There is no merchant name violation.
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, MerchantMandatoryTok), 'The card merchant must satisfy Merchant Name Mandatory.');
    end;

    [Test]
    procedure JustificationConditionAppliesToCardLine()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
    begin
        // [SCENARIO] Rules kept: a justification threshold applies to card lines, and the user can satisfy it.
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);

        // [GIVEN] A card line of 20 that doesn't wait for its receipt, and a rule that needs a justification from 10.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportLine."No Receipt Type" := ExpenseReportLine."No Receipt Type"::"Receipt not needed";
        ExpenseReportLine.Modify();
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseReportLine."Expense Category", '', WorkDate() - 30,
            ExpenseRuleHeader."Justification Required"::"Against Conditions", '', '', ExpenseRuleCondition."Condition Type"::"At Least Justification Needed", 10);

        // [WHEN] The line is validated without and then with a justification.
        ValidateLineAgainstRules(ExpenseReportLine);
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, JustificationRequiredTok), 'The card line must need a justification.');
        ExpenseReportLine.Justification := 'Client lunch';
        ExpenseReportLine.Modify();
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] The justification satisfies the rule.
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, JustificationRequiredTok), 'The justification must satisfy the rule.');
    end;

    [Test]
    procedure CardLineAndManualLineWithSameValuesAreDuplicates()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ManualLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO] Rules kept: a manual line with the same date, merchant and amount as a card line is still a duplicate,
        // because the same purchase was probably entered twice.
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);

        // [GIVEN] A card line and a manual line with the same date, merchant and amount.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        LibraryExpense.CreateExpenseReportLine(
            ManualLine, ExpenseReportHeader, Expense."Expense User No.", ExpenseReportLine."Expense Category", '', true, '', ExpenseReportLine.Amount);
        ManualLine."Expense Ext. Doc. No." := ExpenseReportLine."Expense Ext. Doc. No.";
        ManualLine."Merchant Name" := ExpenseReportLine."Merchant Name";
        ManualLine."Expense Date" := ExpenseReportLine."Expense Date";
        ManualLine.Modify();

        // [WHEN] The card line is validated against the rules.
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] It is flagged as a possible duplicate.
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, DuplicateTok), 'A manual line with the same values must be a duplicate.');
    end;

    [Test]
    procedure CardLineAboveMaxAmountWithoutJustificationIsFlagged()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
    begin
        // [SCENARIO] Rules kept: a card line above the category's maximum amount cannot be released silently.
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);

        // [GIVEN] A card line of 20 and a rule with a maximum amount of 10.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseReportLine."Expense Category", '', WorkDate() - 30,
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", 10);
        SetLineDetailRequired(ExpenseReportLine, ExpenseReportLine."Expense Detail Required"::Itemize);

        // [WHEN] The line is validated against the rules without a justification.
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] The line has a maximum amount violation.
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, MaxAmountTok), 'A card line above the maximum amount must be flagged.');
    end;

    [Test]
    procedure CardLinesFromDifferentTransactionsAreNotDuplicates()
    var
        Expense: Record Expense;
        OtherExpense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        OtherLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Relaxed: two card transactions on the same day at the same merchant for the same amount (two coffees)
        // are two purchases. Each has its own transaction, so they are not duplicates.
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);

        // [GIVEN] Two card lines from different transactions with the same date, merchant and amount.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        CreateCardLine(OtherExpense, OtherLine, CardIdTok);
        Assert.AreNotEqual(Expense."Credit Card Feed No.", OtherExpense."Credit Card Feed No.", 'The lines must come from different transactions.');

        // [WHEN] The first line is validated against the rules.
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] It is not flagged as a duplicate.
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, DuplicateTok), 'Different card transactions must not be duplicates.');
    end;

    [Test]
    procedure CardLineDoesNotNeedReceiptNumber()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO] Relaxed: the card transaction identifies the purchase, so Receipt No. Mandatory does not apply to card
        // lines (a lost or not-needed receipt would otherwise block the report for good).
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Receipt No. Mandatory" := true;
        ExpenseAgentSetup.Modify();

        // [GIVEN] A card line without a receipt number.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        ExpenseReportLine.TestField("Expense Ext. Doc. No.", '');

        // [WHEN] The line is validated against the rules.
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] There is no receipt number violation.
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, ReceiptNoMandatoryTok), 'A card line must not need a receipt number.');
    end;

    [Test]
    procedure CardLineAboveMaxAmountIsAcceptedWithJustification()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
    begin
        // [SCENARIO] Relaxed: the card amount is locked, so an amount condition cannot be fixed by the user. On a card line it
        // asks for a justification instead of blocking the report.
        Initialize();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);

        // [GIVEN] A card line of 20 with a justification and a rule with a maximum amount of 10.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseReportLine."Expense Category", '', WorkDate() - 30,
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", 10);
        SetLineDetailRequired(ExpenseReportLine, ExpenseReportLine."Expense Detail Required"::Itemize);
        ExpenseReportLine.Justification := 'Team dinner approved by manager';
        ExpenseReportLine.Modify();

        // [WHEN] The line is validated against the rules.
        ValidateLineAgainstRules(ExpenseReportLine);

        // [THEN] The line has no maximum amount violation.
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, MaxAmountTok), 'A justified card line above the maximum amount must not be blocked.');
    end;

    // ---------------------------------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------------------------------

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
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

    // Creates a card expense and adds it to an open report through the standard BC flow (category, release, add).
    local procedure CreateCardLine(var Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line"; CardId: Code[50])
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        CreateCardExpense(Expense, CardId);
        CreateCardCategory(ExpenseCategory, 0);
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Modify(true);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        CreateReportForExpense(ExpenseReportHeader, Expense);
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
        Expense.Get(Expense."No.");
    end;

    local procedure CreateCardCategory(var ExpenseCategory: Record "Expense Category"; NoReceiptLimit: Decimal)
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Credit Card", ExpenseCategory."Expense Detail Required"::" ", ExpensePaymentMethod.Code);
        if NoReceiptLimit <> 0 then begin
            // Assigned directly: validating the limit requires Allow No Receipt, which some tests turn off on purpose.
            ExpenseCategory."Amount Limit for No Receipt" := NoReceiptLimit;
            ExpenseCategory.Modify(true);
        end;
    end;

    local procedure ClearCategory(var Expense: Record Expense)
    begin
        if Expense."Expense Category" = '' then
            exit;
        Expense.Validate("Expense Category", '');
        Expense.Modify(true);
    end;

    local procedure CreateReportForExpense(var ExpenseReportHeader: Record "Expense Report Header"; Expense: Record Expense)
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
    end;

    local procedure ValidateLineAgainstRules(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
    end;

    local procedure HasLineViolation(ExpenseReportLine: Record "Expense Report Line"; DescriptionPart: Text): Boolean
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportRuleViolation.SetFilter(Description, '@*' + DescriptionPart + '*');
        exit(not ExpenseReportRuleViolation.IsEmpty());
    end;

    // Amount conditions are evaluated for itemized, participant and mileage lines.
    local procedure SetLineDetailRequired(var ExpenseReportLine: Record "Expense Report Line"; DetailRequired: Enum "Expense Detail Needed")
    begin
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine."Expense Detail Required" := DetailRequired;
        ExpenseReportLine.Modify();
    end;

    local procedure SetAttachmentEnforcement(CategoryCode: Code[20]; AttachmentEnforcement: Enum "Expense Attachment Enforcement")
    var
        ExpenseCategory: Record "Expense Category";
    begin
        ExpenseCategory.Get(CategoryCode);
        ExpenseCategory."Attachment Enforcement" := AttachmentEnforcement;
        ExpenseCategory.Modify();
    end;

    local procedure SetAllowNoReceipt(AllowNoReceipt: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Allow No Receipt" := AllowNoReceipt;
        ExpenseAgentSetup.Modify();
    end;

    // Attaches a real one-pixel image as the receipt, built without DotNet like "Library - Expense".CreateTempBLOBWithImageOfType on main.
    local procedure AttachReceiptToExpense(var Expense: Record Expense)
    var
        DocumentAttachment: Record "Document Attachment";
        Image: Codeunit Image;
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStream: OutStream;
        InStream: InStream;
    begin
        Image.FromBase64(OnePixelPngBase64Tok);
        Image.SetFormat(Enum::"Image Format"::Png);
        TempBlob.CreateOutStream(OutStream);
        Image.Save(OutStream);
        TempBlob.CreateInStream(InStream);
        RecRef.GetTable(Expense);
        DocumentAttachment.SaveAttachmentFromStream(InStream, RecRef, ReceiptFileNameTok);
        Expense.Get(Expense."No.");
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

    local procedure FindMatch(Expense: Record Expense; ReceiptDate: Date; ReceiptAmount: Decimal): Guid
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        exit(ReceiptExpenseMatch.FindMatchingExpense(ExpenseUser.SystemId, ReceiptDate, ReceiptAmount, '', MerchantNameTok, ''));
    end;

    local procedure VerifyCardLine(ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    begin
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("Expense No.", Expense."No.");
        ExpenseReportLine.TestField(Amount, Expense.Amount);
        ExpenseReportLine.TestField("Expense Currency Code", Expense."Currency Code");
        ExpenseReportLine.TestField("Expense Date", Expense."Expense Date");
        ExpenseReportLine.TestField("Credit Card Feed No.", Expense."Credit Card Feed No.");
        ExpenseReportLine.TestField("Corporate Card Id", Expense."Corporate Card Id");
        ExpenseReportLine.TestField("Reimbursement Type", ExpenseReportLine."Reimbursement Type"::"Credit Card");
    end;
}
