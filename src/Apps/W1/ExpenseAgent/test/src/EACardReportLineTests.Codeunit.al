// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

// [FEATURE] [Expense Agent] [Corporate Card] [Report Lines]
// Card transactions become expense report lines before a receipt exists. These tests describe the target behavior
// (changes B1, B3, B4, B5 and B7 of the corporate card report line design). Tests that need a change that is not
// implemented yet are listed in src/DisabledTests/Expense_Agent_Tests until the change lands.
codeunit 148350 "EA Card Report Line Tests"
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
        OtherCardIdTok: Label 'CORPCARD-0002', Locked = true;
        MerchantNameTok: Label 'CONTOSO COFFEE', Locked = true;

    // ---------------------------------------------------------------------------------------------
    // B1: an open card expense without a category can be added to a report
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure OpenCardExpenseWithoutCategoryCanBeAddedToReport()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] B1: A card expense created from a transaction can be added to a report while it is open and has no category.
        Initialize();

        // [GIVEN] An open card expense of 20 without a category.
        CreateCardExpense(Expense, CardIdTok);
        ClearCategory(Expense);
        CreateReportForExpense(ExpenseReportHeader, Expense);

        // [WHEN] The expense is added to an open report.
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [THEN] The line carries the card values and the expense is submitted on the report.
        VerifyCardLine(ExpenseReportLine, Expense);
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Report No.", ExpenseReportHeader."No.");
        Expense.TestField(Status, Expense.Status::Submitted);
    end;

    [Test]
    procedure OpenManualExpenseStillCannotBeAddedToReport()
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO] B1: Only card expenses are relaxed; an open manual expense must still be released first.
        Initialize();

        // [GIVEN] An open manual expense paid with the card.
        CorpCard.Get(CardIdTok);
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        CreateReportForExpense(ExpenseReportHeader, Expense);

        // [WHEN] The expense is added to a report.
        asserterror CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [THEN] The expense must be released.
        Assert.ExpectedError(Expense.FieldCaption(Status));
    end;

    [Test]
    procedure OpenLinkedManualExpenseStillCannotBeAddedToReport()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO] B1: A manual expense linked to a transaction keeps the normal flow and must be released first.
        Initialize();

        // [GIVEN] An open manual expense linked to a card transaction.
        CreateLinkedManualExpense(Expense);
        CreateReportForExpense(ExpenseReportHeader, Expense);

        // [WHEN] The expense is added to a report.
        asserterror CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [THEN] The expense must be released.
        Assert.ExpectedError(Expense.FieldCaption(Status));
    end;

    [Test]
    procedure ReportWithCardLineWithoutCategoryCannotBeReleased()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] B1: The relaxed add does not relax report release; the user must set a category first.
        Initialize();

        // [GIVEN] A card expense without a category on an open report.
        CreateCardExpense(Expense, CardIdTok);
        ClearCategory(Expense);
        CreateReportForExpense(ExpenseReportHeader, Expense);
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [WHEN] The report is released.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] The missing category blocks the release.
        Assert.ExpectedError(ExpenseReportLine.FieldCaption("Expense Category"));
    end;

    [Test]
    procedure OtherUsersCardExpenseCannotBeAddedToReport()
    var
        Expense: Record Expense;
        OtherExpense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO] B1: A card expense of another expense user cannot be added to the report.
        Initialize();

        // [GIVEN] A report of the first expense user and a card expense of another expense user.
        CreateCardExpense(Expense, CardIdTok);
        CreateCardExpense(OtherExpense, OtherCardIdTok);
        CreateReportForExpense(ExpenseReportHeader, Expense);

        // [WHEN] The other user's expense is added to the report.
        asserterror CreateExpenseReport.AddSingleExpenseToExpenseReport(OtherExpense, ExpenseReportHeader);

        // [THEN] The expense user must match.
        Assert.ExpectedError(OtherExpense.FieldCaption("Expense User No."));
    end;

    // ---------------------------------------------------------------------------------------------
    // B3: a category change on a card line keeps the card values
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure CategoryChangeOnCardLineKeepsCardValues()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        EmployeePaidCategory: Record "Expense Category";
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO] B3: Changing the category on a card line keeps the amount, currency, reimbursement type and payment method.
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
        // [SCENARIO] B3: Clearing the category on a card line keeps the card amount and currency.
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
        // [SCENARIO] B3 regression: A category change on a line that is not linked to a card transaction still resets the amount.
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
    // B4: "Receipt not needed" is recalculated on lines
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure LineCategoryUnderNoReceiptLimitSetsReceiptNotNeeded()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO] B4: Setting a category whose no-receipt limit is above the line amount marks the line as not needing a receipt.
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
        // [SCENARIO] B4: Changing to a category whose limit is below the line amount requires a receipt again.
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
        // [SCENARIO] B4: Without Allow No Receipt, a category limit never removes the receipt requirement.
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
        // [SCENARIO] B4: Like on the expense, a lost receipt declaration is kept when the category limit is below the amount.
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
    // B5: receipt matching finds card lines on open reports
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure ReceiptMatchesCardExpenseOnOpenReport()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] B5: A receipt uploaded through the general flow finds the card expense that is already on an open report.
        Initialize();

        // [GIVEN] A card line of 20 without a receipt on an open report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);

        // [WHEN] A receipt of 20 from the same merchant is matched.
        // [THEN] The card expense is returned, so no duplicate expense is created.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20), 'A card expense on an open report must match the receipt.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchCardExpenseOnReleasedReport()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] B5: Card expenses on a report that is no longer open are not candidates.
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
        // [SCENARIO] B5: A card line that already has a receipt is not a candidate.
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
        // [SCENARIO] B5: Checking a receipt against a card expense that is on an open report returns the expense.
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
    // B7: removing a card line returns the expense to the pending list; card expenses cannot be deleted
    // ---------------------------------------------------------------------------------------------

    [Test]
    procedure DeletingCardLineReturnsExpenseToOpen()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        FeedNo: Integer;
    begin
        // [SCENARIO] B7: "Remove from report" deletes the card line and puts the expense back in the pending list.
        Initialize();

        // [GIVEN] A card line on an open report.
        CreateCardLine(Expense, ExpenseReportLine, CardIdTok);
        FeedNo := Expense."Credit Card Feed No.";

        // [WHEN] The line is deleted.
        ExpenseReportLine.Delete(true);

        // [THEN] The expense is open, off the report and still linked to its transaction.
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Open);
        Expense.TestField("Expense Report No.", '');
        Expense.TestField("Credit Card Feed No.", FeedNo);
        CorpCardTrans.Get(FeedNo);
        CorpCardTrans.TestField("Expense No.", Expense."No.");
    end;

    [Test]
    procedure DeletingManualLineReturnsExpenseToReleased()
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [SCENARIO] B7 regression: Deleting a line of a manual expense still sets the expense back to Released.
        Initialize();

        // [GIVEN] A released manual card-paid expense on an open report.
        CorpCard.Get(CardIdTok);
        CorpCardTestLib.InsertExpense(Expense, CorpCard);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        CreateReportForExpense(ExpenseReportHeader, Expense);
        ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [WHEN] The line is deleted.
        ExpenseReportLine.Delete(true);

        // [THEN] The expense is released and off the report.
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
    end;

    [Test]
    procedure CardLinkedExpenseCannotBeDeleted()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] B7: A card expense cannot be deleted, so its transaction never points to a missing expense.
        Initialize();

        // [GIVEN] An open card expense that is not on a report.
        CreateCardExpense(Expense, CardIdTok);

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
        // [SCENARIO] B7 + B1: After "Remove from report" the open card expense can be added to a report again.
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

    // Creates a card expense and adds it to an open report through the existing released path, so the line exists
    // regardless of change B1.
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
            ExpenseCategory.Validate("Amount Limit for No Receipt", NoReceiptLimit);
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
        Expense.TestField(Source, Expense.Source::Manual);
    end;

    local procedure SetAllowNoReceipt(AllowNoReceipt: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Allow No Receipt" := AllowNoReceipt;
        ExpenseAgentSetup.Modify();
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
