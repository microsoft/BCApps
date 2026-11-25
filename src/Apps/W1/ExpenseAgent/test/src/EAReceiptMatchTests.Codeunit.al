// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Foundation.Attachment;
using System.Utilities;

// [FEATURE] [Expense Agent] [Corporate Card] [Receipt Matching]
codeunit 148370 EAReceiptMatchTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        ReceiptExpenseMatch: Codeunit "EA Receipt Expense Match";
        CardReceiptDataApply: Codeunit "EA Card Receipt Data Apply";
        CannotDeleteCardExpenseErr: Label 'You cannot delete expense %1 because it is linked to a corporate card transaction.', Comment = '%1 = Expense No.';
        CardExpenseSourceFieldCannotChangeErr: Label '%1 cannot be changed on an expense linked to a corporate card transaction.', Comment = '%1 = field caption';
        NotCardExpenseErr: Label 'Receipt data can only be applied to expense %1 when it was created from a corporate card transaction.', Comment = '%1 = Expense No.';
        NotWaitingForReceiptErr: Label 'Expense %1 is not waiting for a receipt.', Comment = '%1 = Expense No.';
        OpenExpenseAttachmentErr: Label 'You can only import and delete attachments on %1 %2 when the %3 is Open.', Comment = '%1 = Expense No. caption, %2 = expense number, %3 = status caption';
        ReceiptRequiredErr: Label 'Upload the receipt file and its file name before you apply the receipt data.';
        ReceiptNoMandatoryOnExpenseErr: Label 'Receipt No. is mandatory on Expense No. %1', Comment = '%1 = Expense No.';
        ReceiptNoMandatoryOnReportLineErr: Label 'Receipt No. is mandatory on Expense Report No. %1, Line No. %2', Comment = '%1 = Expense Report No., %2 = Line No.';
        MerchantNameMandatoryOnReportLineErr: Label 'Merchant Name is mandatory on Expense Report No. %1, Line No. %2', Comment = '%1 = Expense Report No., %2 = Line No.';
        RuleViolationPresentOnLineErr: Label 'There are one or more rule violations in this expense report. Check the expenses marked for review before submitting again.';
        ExpenseDocumentAttachmentMandatoryMsg: Label 'Document Attachment is mandatory on Expense No. %1', Comment = '%1 = Expense No.';
        ERLDocumentAttachmentMandatoryMsg: Label 'Document Attachment is mandatory on Expense Report No. %1 Line No. %2', Comment = '%1 = Expense Report No., %2 = Line No.';
        ItemizationTotalMismatchErr: Label 'Itemization total %1 must be equal to expense amount %2.', Comment = '%1 = Itemization total amount, %2 = Expense amount';
        JustificationRequiredErr: Label 'Justification is required for this expense based on your organization''s rule.';
        MaxAmountErr: Label 'Amount must not exceed %1 as defined by rule.', Comment = '%1 = Maximum allowed amount';
        NoReceiptDeclarationNotCurrentErr: Label 'The no receipt declaration for expense %1 is missing or no longer current.', Comment = '%1 = Expense No.';

    [Test]
    procedure ReceiptMatchesCardExpenseWithinDateWindow()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A receipt with the same amount and currency matches the card expense that is still waiting for a receipt.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt dated within the date window is matched.
        // [THEN] The card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate() + 2, 20), 'The card expense must match the receipt.');
    end;

    [Test]
    procedure ReceiptWithDifferentAmountDoesNotMatch()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] The receipt amount must match the card expense amount exactly.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt of 21 on the same date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 21)), 'A different amount must not match.');
    end;

    [Test]
    procedure ReceiptDateOutsideWindowDoesNotMatch()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] The receipt date must be within the date window of the card expense.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt of 20 dated 8 days later, outside the 7-day window, is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate() + 8, 20)), 'A date outside the window must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchExpenseThatAlreadyHasReceipt()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card expenses that already have a receipt are not candidates.
        Initialize();

        // [GIVEN] A card expense that already has a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense."Receipt Attached" := true;
        Expense.Modify();

        // [WHEN] A receipt with the same amount and date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20)), 'An expense with a receipt must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchLostReceiptCardExpense()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card expenses declared as lost receipt are not candidates.
        Initialize();

        // [GIVEN] A card expense declared as lost receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense."No Receipt Type" := Expense."No Receipt Type"::"Lost Receipt";
        Expense.Modify();

        // [WHEN] A receipt with the same amount and date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20)), 'A lost receipt expense must not match.');
    end;

    [Test]
    procedure ReceiptMatchesReceiptNotNeededCardExpense()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card expenses that do not need a receipt are still candidates, so a receipt can be added anyway.
        Initialize();

        // [GIVEN] A card expense marked as receipt not needed.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense."No Receipt Type" := Expense."No Receipt Type"::"Receipt not needed";
        Expense.Modify();

        // [WHEN] A receipt with the same amount and date is matched.
        // [THEN] The card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20), 'An expense that does not need a receipt must still match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchManualExpenseLinkedToTransaction()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Only card-created expenses are candidates; a manual expense already has its own receipt flow.
        Initialize();

        // [GIVEN] A manual expense without a receipt linked to a card transaction.
        CreateLinkedManualExpense(Expense);

        // [WHEN] A receipt with the same amount and date is matched.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, Expense."Expense Date", Expense.Amount)), 'A manual expense must not match.');
    end;

    [Test]
    procedure ReceiptDoesNotMatchOtherUsersCardExpense()
    var
        Expense: Record Expense;
        OtherCorpCard: Record "EA Corp Card";
        OtherExpenseUser: Record "Expense User";
    begin
        // [SCENARIO] Only the expense user's own card expenses are candidates.
        Initialize();

        // [GIVEN] A card expense waiting for a receipt and another expense user with their own card.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        OtherCorpCard.Get('CORPCARD-0002');
        OtherExpenseUser.Get(OtherCorpCard."Expense User No.");

        // [WHEN] The receipt is matched for the other expense user.
        // [THEN] No expense is returned.
        Assert.IsTrue(
            IsNullGuid(ReceiptExpenseMatch.FindMatchingExpense(OtherExpenseUser.SystemId, WorkDate(), 20, '', 'CONTOSO COFFEE', '')),
            'Another user''s expense must not match.');
    end;

    [Test]
    procedure ReceiptMatchesClosestDateAndMerchant()
    var
        FartherExpense: Record Expense;
        CloserExpense: Record Expense;
    begin
        // [SCENARIO] When several card expenses qualify, the closest date and most similar merchant win.
        Initialize();

        // [GIVEN] Two card expenses of 20: one 3 days earlier from another merchant, one on the receipt date from the same merchant.
        CreateCardExpense(FartherExpense, 'CORPCARD-0001', WorkDate() - 3, 'FABRIKAM TAXI');
        CreateCardExpense(CloserExpense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is matched.
        // [THEN] The expense with the same date and merchant is returned.
        Assert.AreEqual(CloserExpense.SystemId, FindMatch(CloserExpense, WorkDate(), 20), 'The closest candidate must match.');
    end;

    [Test]
    procedure ReceiptFromUnrelatedMerchantDoesNotMatch()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Without card digits, a receipt from an unrelated merchant does not match a card expense with the same amount and date.
        Initialize();

        // [GIVEN] A card expense of 20 from a taxi company waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO TAXI');

        // [WHEN] A lunch receipt of 20 on the same date from a restaurant is matched without card digits.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20, 'Fabrikam Bistro', '')), 'An unrelated merchant must not match.');
    end;

    [Test]
    procedure ReceiptFromUnrelatedMerchantMatchesWhenCardLast4Matches()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card digits that match the expense's card prove the payment, so the merchant name is not required to be similar.
        Initialize();

        // [GIVEN] A card expense of 20 paid with the card ending in 0001.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO TAXI');

        // [WHEN] A receipt of 20 from a differently named merchant is matched with card last four digits 0001.
        // [THEN] The card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20, 'Fabrikam Bistro', '0001'), 'Matching card digits must match.');
    end;

    [Test]
    procedure ReceiptMerchantMatchesStatementNameWithSuffix()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A receipt merchant name matches a statement merchant name that adds a location suffix.
        Initialize();

        // [GIVEN] A card expense of 20 whose statement merchant name has a location suffix.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'FOURTH COFFEE CANARY WHARF');

        // [WHEN] A receipt of 20 from Fourth Coffee is matched without card digits.
        // [THEN] The card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20, 'Fourth Coffee', ''), 'The merchant name with a suffix must match.');
    end;

    [Test]
    procedure CategoryCanBeSetOnCardExpenseWithoutChangingCardValues()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO] A pending card expense gets its category from the user; amount, currency, date and card payment come from the card and stay unchanged.
        Initialize();

        // [GIVEN] A card expense waiting for a receipt and an employee-paid category.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        PaymentMethodCode := Expense."Payment Method Code";
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [WHEN] The category is changed to an employee-paid category.
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Modify(true);

        // [THEN] The category is saved and the card values are kept.
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Category", ExpenseCategory.Code);
        Expense.TestField(Amount, 20);
        Expense.TestField("Currency Code", '');
        Expense.TestField("Expense Date", WorkDate());
        Expense.TestField("Reimbursement Type", Expense."Reimbursement Type"::"Credit Card");
        Expense.TestField("Payment Method Code", PaymentMethodCode);
    end;

    [Test]
    procedure ClearingCategoryOnManualExpenseKeepsCurrency()
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] Clearing the category on a manual expense resets the amount but keeps the currency.
        Initialize();

        // [GIVEN] A manual expense of 20 in a foreign currency.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 1);
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.CreateExpense(Expense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, CurrencyCode, 20, false);

        // [WHEN] The category is cleared.
        Expense.Validate("Expense Category", '');
        Expense.Modify(true);

        // [THEN] The amount is reset and the currency is kept.
        Expense.Get(Expense."No.");
        Expense.TestField(Source, Expense.Source::Manual);
        Expense.TestField(Amount, 0);
        Expense.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    procedure CheckReturnsExpenseWhenReceiptFits()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Checking a receipt against a given card expense returns that expense when the receipt fits it.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt of 20 dated within the window is checked against the expense.
        // [THEN] The expense is returned.
        Assert.AreEqual(Expense.SystemId, CheckMatch(Expense, Expense.SystemId, WorkDate() + 2, 20), 'The receipt must fit the card expense.');
    end;

    [Test]
    procedure CheckReturnsEmptyWhenAmountDiffers()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Checking a receipt with another amount against a given card expense returns no match.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt of 21 is checked against the expense.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(CheckMatch(Expense, Expense.SystemId, WorkDate(), 21)), 'A different amount must not fit.');
    end;

    [Test]
    procedure CheckReturnsEmptyForOtherUsersExpense()
    var
        Expense: Record Expense;
        OtherExpense: Record Expense;
    begin
        // [SCENARIO] A receipt cannot be checked against another expense user's card expense.
        Initialize();

        // [GIVEN] A card expense for the expense user and a card expense with the same values for another expense user.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        CreateCardExpense(OtherExpense, 'CORPCARD-0002', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is checked for the expense user against the other user's expense.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(CheckMatch(Expense, OtherExpense.SystemId, WorkDate(), 20)), 'Another user''s expense must not fit.');
    end;

    [Test]
    procedure ReceiptCardLast4SelectsExpensePaidWithThatCard()
    var
        Expense: Record Expense;
        OtherCardExpense: Record Expense;
    begin
        // [SCENARIO] When the receipt shows the card's last four digits, only expenses paid with a card ending in those digits match.
        Initialize();

        // [GIVEN] Two equal card expenses of the same expense user, paid with cards ending in 0001 and 7777.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        CreateCardExpense(OtherCardExpense, CreateAdditionalCard('CORPCARD-0001', '****7777'), WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is matched with card last four digits 7777.
        // [THEN] The expense paid with the card ending in 7777 is returned.
        Assert.AreEqual(OtherCardExpense.SystemId, FindMatch(Expense, WorkDate(), 20, '7777'), 'The expense paid with the receipt card must match.');
    end;

    [Test]
    procedure ReceiptCardLast4OfNoUserCardDoesNotMatch()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A receipt paid with a card the expense user does not have matches no expense.
        Initialize();

        // [GIVEN] A card expense paid with the card ending in 0001.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is matched with card last four digits 9999.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(FindMatch(Expense, WorkDate(), 20, '9999')), 'Another card must not match.');
    end;

    [Test]
    procedure ReceiptInvalidCardLast4IsIgnored()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Card digits that are not exactly four digits are ignored.
        Initialize();

        // [GIVEN] A card expense paid with the card ending in 0001.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The receipt is matched with card last four digits 12A4.
        // [THEN] The card expense is returned.
        Assert.AreEqual(Expense.SystemId, FindMatch(Expense, WorkDate(), 20, '12A4'), 'Invalid card digits must be ignored.');
    end;

    [Test]
    procedure CheckReturnsExpenseWhenCardLast4Matches()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Checking a receipt paid with the expense's card against that card expense returns the expense.
        Initialize();

        // [GIVEN] A card expense paid with the card ending in 0001.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] A receipt with card last four digits 0001 is checked against the expense.
        // [THEN] The expense is returned.
        Assert.AreEqual(Expense.SystemId, CheckMatch(Expense, Expense.SystemId, WorkDate(), 20, '0001'), 'The receipt paid with the expense card must fit.');
    end;

    [Test]
    procedure CheckReturnsEmptyWhenCardLast4Differs()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Checking a receipt paid with another card of the same expense user against a given card expense returns no match.
        Initialize();

        // [GIVEN] A card expense paid with the card ending in 0001 and another card of the same expense user ending in 7777.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        CreateAdditionalCard('CORPCARD-0001', '****7777');

        // [WHEN] A receipt with card last four digits 7777 is checked against the expense.
        // [THEN] No expense is returned.
        Assert.IsTrue(IsNullGuid(CheckMatch(Expense, Expense.SystemId, WorkDate(), 20, '7777')), 'A receipt paid with another card must not fit.');
    end;

    [Test]
    procedure OpenCardExpenseWithoutCategoryCanBeAddedToReport()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] A card expense from a transaction is added to a report while it is still open and has no category.
        Initialize();

        // [GIVEN] An open card expense without a category.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        ClearCategory(Expense);
        Expense.CalcFields("Card Expense Awaiting Report");
        Expense.TestField("Card Expense Awaiting Report", true);

        // [WHEN] The card-specific add releases and adds the expense in one operation.
        AddCardExpenseToReport(Expense, ExpenseReportLine);

        // [THEN] The line has the card values, and the expense is submitted and no longer pending.
        ExpenseReportLine.TestField(Amount, 20);
        ExpenseReportLine.TestField("Credit Card Feed No.", Expense."Credit Card Feed No.");
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Submitted);
        Expense.CalcFields("Card Expense Awaiting Report");
        Expense.TestField("Card Expense Awaiting Report", false);
    end;

    [Test]
    procedure CategoryChangeOnCardLineKeepsCardValues()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO] Setting the category on a card line keeps the card amount, reimbursement type and payment method.
        Initialize();

        // [GIVEN] A card line without a category and an employee-paid category.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        ClearCategory(Expense);
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        PaymentMethodCode := ExpenseReportLine."Payment Method Code";
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [WHEN] The category is set on the line.
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Modify(true);

        // [THEN] The card values are kept.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.TestField(Amount, 20);
        ExpenseReportLine.TestField("Reimbursement Type", ExpenseReportLine."Reimbursement Type"::"Credit Card");
        ExpenseReportLine.TestField("Payment Method Code", PaymentMethodCode);
    end;

    [Test]
    procedure RemovingCardLineLeavesCardExpenseReleased()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Removing a card line keeps the expense released and linked for another report.
        Initialize();

        // [GIVEN] A card expense on a report.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);

        // [WHEN] The line is deleted.
        ExpenseReportLine.Delete(true);

        // [THEN] The released expense is off-report, still linked to the transaction and awaiting another report.
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
        Expense.TestField("Credit Card Feed No.", ExpenseReportLine."Credit Card Feed No.");
        Expense.CalcFields("Card Expense Awaiting Report");
        Expense.TestField("Card Expense Awaiting Report", true);
    end;

    [Test]
    procedure CardExpenseCannotBeDeleted()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] An expense linked to a card transaction cannot be deleted.
        Initialize();

        // [GIVEN] A card expense.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');

        // [WHEN] The expense is deleted.
        asserterror Expense.Delete(true);

        // [THEN] An error says it is linked to a card transaction.
        Assert.ExpectedError(StrSubstNo(CannotDeleteCardExpenseErr, Expense."No."));
    end;

    [Test]
    procedure ApplyReceiptDataFillsEmptyFieldsOnExpenseAndLine()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CardReceiptData: Record "EA Card Receipt Data";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
    begin
        // [SCENARIO] Applying receipt data to a card line attaches the receipt to the expense and the line, and fills only empty fields.
        Initialize();

        // [GIVEN] A card expense on an open report, with a justification entered by the user on the line.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        ExpenseReportLine.Validate(Justification, 'User justification');
        ExpenseReportLine.Modify(true);

        // [GIVEN] Receipt data with a justification, a merchant VAT registration number, a different amount and a participant.
        CreateCardReceiptData(CardReceiptData, Expense);
        CardReceiptData.Justification := 'Receipt justification';
        CardReceiptData."Merchant VAT Registration No." := 'DK12345678';
        CardReceiptData.Modify();
        AddCardReceiptParticipant(CardReceiptData, 'Jane Doe');

        // [WHEN] The receipt data is applied.
        CardReceiptDataApply.Apply(CardReceiptData);

        // [THEN] The expense gets the receipt and the receipt values, and keeps its card amount and status.
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Submitted);
        Expense.TestField(Amount, 20);
        Expense.TestField("Receipt Attached", true);
        Expense.TestField(Justification, 'Receipt justification');
        Expense.TestField("Merchant VAT Registration No.", 'DK12345678');
        Assert.AreEqual(1, CountAttachments(Database::Expense, Expense."No.", 0), 'The receipt must be attached to the expense.');
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        Assert.AreEqual(1, ExpenseParticipant.Count(), 'The participant must be added to the expense.');

        // [THEN] The line gets the receipt and the empty fields, and keeps the user's justification and the card amount.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField(Amount, 20);
        ExpenseReportLine.TestField("Receipt Attached", true);
        ExpenseReportLine.TestField(Justification, 'User justification');
        ExpenseReportLine.TestField("Merchant VAT Registration No.", 'DK12345678');
        Assert.AreEqual(1, CountAttachments(Database::"Expense Report Line", ExpenseReportLine."Document No.", ExpenseReportLine."Line No."), 'The receipt must be attached to the line.');
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLineParticip.Count(), 'The participant must be added to the line.');

        // [THEN] The receipt data is deleted.
        Assert.IsFalse(CardReceiptData.Get(CardReceiptData.Id), 'The receipt data must be deleted after it is applied.');
    end;

    [Test]
    procedure ReceiptDataCannotBeAppliedAgainToSubmittedExpense()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CardReceiptData: Record "EA Card Receipt Data";
        RetryCardReceiptData: Record "EA Card Receipt Data";
    begin
        // [SCENARIO] The missing-receipt exception cannot be used again after a receipt has been applied.
        Initialize();

        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        CreateCardReceiptData(CardReceiptData, Expense);
        CreateCardReceiptData(RetryCardReceiptData, Expense);
        CardReceiptDataApply.Apply(CardReceiptData);
        Commit();

        asserterror CardReceiptDataApply.Apply(RetryCardReceiptData);

        Assert.ExpectedError(StrSubstNo(NotWaitingForReceiptErr, Expense."No."));
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Submitted);
        Assert.AreEqual(1, CountAttachments(Database::Expense, Expense."No.", 0), 'The expense must keep its single receipt.');
        Assert.AreEqual(1, CountAttachments(Database::"Expense Report Line", ExpenseReportLine."Document No.", ExpenseReportLine."Line No."), 'The line must keep its single receipt.');
    end;

    [Test]
    procedure AppliedCardReceiptCanBeReplacedAfterManualReopen()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CardReceiptData: Record "EA Card Receipt Data";
        DocumentAttachment: Record "Document Attachment";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ReplacementInStream: InStream;
    begin
        // [SCENARIO] A receipt follows the normal attachment rules once its expense is open and no longer on a report.
        Initialize();

        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        CreateCardReceiptData(CardReceiptData, Expense);
        CardReceiptDataApply.Apply(CardReceiptData);
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Submitted);

        ExpenseReportLine.Delete(true);
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
        DocumentAttachment.SetRange("Table ID", Database::Expense);
        DocumentAttachment.SetRange("No.", Expense."No.");
        DocumentAttachment.FindFirst();
        Commit();
        asserterror DocumentAttachment.Delete(true);
        Assert.ExpectedError(StrSubstNo(OpenExpenseAttachmentErr, ExpenseReportLine.FieldCaption("Expense No."), Expense."No.", Expense.FieldCaption(Status)));

        DocumentAttachment.FindFirst();
        Expense.Get(Expense."No.");
        ReleaseExpenseDocument.PerformManualReopen(Expense);
        CreateCardReceiptData(CardReceiptData, Expense);
        CardReceiptData.CalcFields("Attachment Content");
        CardReceiptData."Attachment Content".CreateInStream(ReplacementInStream);
        DocumentAttachment.ImportFromStream(ReplacementInStream, 'replacement.pdf');
        DocumentAttachment.Modify(true);
        DocumentAttachment.Delete(true);

        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Open);
        Expense.TestField("Receipt Attached", false);
        Assert.AreEqual(0, CountAttachments(Database::Expense, Expense."No.", 0), 'The open expense must allow its receipt to be deleted.');
    end;

    [Test]
    procedure ApplyReceiptDataAddsItemizationToLineWhenCategoryDoesNotRequireIt()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        CardReceiptData: Record "EA Card Receipt Data";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportLineItem: Record "Expense Report Line Item";
    begin
        // [SCENARIO] Itemization from the receipt is added to the line even when it doesn't add up to the card amount, and to the expense only when its category requires it.
        Initialize();

        // [GIVEN] A card expense without a category on an open report.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        ClearCategory(Expense);
        AddCardExpenseToReport(Expense, ExpenseReportLine);

        // [GIVEN] Receipt data with a category that doesn't require itemization, and an item of 15 that doesn't add up to the card amount of 20.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        CreateCardReceiptData(CardReceiptData, Expense);
        CardReceiptData."Expense Category" := ExpenseCategory.Code;
        CardReceiptData.Modify();
        AddCardReceiptItem(CardReceiptData, ExpenseSubcategory.Code, 15);

        // [WHEN] The receipt data is applied.
        CardReceiptDataApply.Apply(CardReceiptData);

        // [THEN] The line has the category, the card amount and the item.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.TestField(Amount, 20);
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLineItem.Count(), 'The item must be added to the line.');

        // [THEN] The expense has the category but no itemization.
        Expense.Get(Expense."No.");
        Expense.TestField("Expense Category", ExpenseCategory.Code);
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        Assert.IsTrue(ExpenseItemization.IsEmpty(), 'The expense must not get itemization its category does not require.');
    end;

    [Test]
    procedure ApplyReceiptDataToCardExpenseNotOnReport()
    var
        Expense: Record Expense;
        CardReceiptData: Record "EA Card Receipt Data";
    begin
        // [SCENARIO] Receipt data can be applied to a card expense that is not on a report yet.
        Initialize();

        // [GIVEN] An open card expense not on a report, and receipt data with a justification.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        CreateCardReceiptData(CardReceiptData, Expense);
        CardReceiptData.Justification := 'Receipt justification';
        CardReceiptData.Modify();

        // [WHEN] The receipt data is applied.
        CardReceiptDataApply.Apply(CardReceiptData);

        // [THEN] The expense stays open with the receipt and the justification.
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Open);
        Expense.TestField(Amount, 20);
        Expense.TestField("Receipt Attached", true);
        Expense.TestField(Justification, 'Receipt justification');
        Assert.AreEqual(1, CountAttachments(Database::Expense, Expense."No.", 0), 'The receipt must be attached to the expense.');
    end;

    [Test]
    procedure ApplyReceiptDataToReleasedCardExpenseNotOnReport()
    var
        Expense: Record Expense;
        CardReceiptData: Record "EA Card Receipt Data";
        FeedNo: Integer;
        CardId: Code[50];
    begin
        // [SCENARIO] The missing receipt can be applied to a card expense that was released but not added to a report.
        Initialize();

        // [GIVEN] A categorized card expense with a user description, released through the standard flow and not on a report.
        CreateReleasedCardExpenseNotOnReport(Expense);
        Expense.TestField(Justification, '');
        FeedNo := Expense."Credit Card Feed No.";
        CardId := Expense."Corporate Card Id";

        // [GIVEN] Receipt data with a justification and another description.
        CreateCardReceiptData(CardReceiptData, Expense);
        CardReceiptData.Justification := 'Receipt justification';
        CardReceiptData.Description := 'Receipt description';
        CardReceiptData.Modify();

        // [WHEN] The receipt data is applied.
        CardReceiptDataApply.Apply(CardReceiptData);

        // [THEN] The expense stays released, off the report and on the same transaction, with one receipt.
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
        Expense.TestField("Credit Card Feed No.", FeedNo);
        Expense.TestField("Corporate Card Id", CardId);
        Expense.TestField("Receipt Attached", true);
        Assert.AreEqual(1, CountAttachments(Database::Expense, Expense."No.", 0), 'The receipt must be attached to the expense once.');

        // [THEN] The empty justification is filled, and the user's description is kept.
        Expense.TestField(Justification, 'Receipt justification');
        Expense.TestField(Description, 'User description');
    end;

    [Test]
    procedure ReleasedCardExpenseGoesThroughReleaseChecksWhenReceiptIsApplied()
    var
        Expense: Record Expense;
        CorpCard: Record "EA Corp Card";
        CardReceiptData: Record "EA Card Receipt Data";
    begin
        // [SCENARIO] Receipt data applied to a released card expense must pass the release checks before the expense is released again.
        Initialize();

        // [GIVEN] A released card expense that is not on a report, whose card was blocked afterwards, and receipt data for it.
        CreateReleasedCardExpenseNotOnReport(Expense);
        CorpCard.Get(Expense."Corporate Card Id");
        CorpCard.Blocked := true;
        CorpCard.Modify();
        CreateCardReceiptData(CardReceiptData, Expense);
        CardReceiptData.Justification := 'Receipt justification';
        CardReceiptData.Modify();
        Commit();

        // [WHEN] The receipt data is applied.
        asserterror CardReceiptDataApply.Apply(CardReceiptData);

        // [THEN] The release check rejects the blocked card, and the expense stays released without the receipt or the justification.
        Assert.ExpectedTestFieldError(CorpCard.FieldCaption(Blocked), Format(false));
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Receipt Attached", false);
        Expense.TestField(Justification, '');
    end;

    [Test]
    procedure ReceiptDataCannotBeStagedForManualExpense()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] Receipt data is only for expenses created from a card transaction.
        Initialize();

        // [GIVEN] A manual expense linked to a card transaction.
        CreateLinkedManualExpense(Expense);

        // [WHEN] Receipt data is staged for it.
        asserterror CardReceiptDataApply.GetCardExpense(Expense.SystemId, Expense);

        // [THEN] An error says the expense was not created from a card transaction.
        Assert.ExpectedError(StrSubstNo(NotCardExpenseErr, Expense."No."));
    end;

    [Test]
    procedure ReceiptDataCannotBeAppliedWhenReportIsNotOpen()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        CardReceiptData: Record "EA Card Receipt Data";
    begin
        // [SCENARIO] Receipt data cannot be applied once the report of the card line is no longer open.
        Initialize();

        // [GIVEN] Receipt data for a card expense whose report was then released.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        Expense.Get(Expense."No.");
        CreateCardReceiptData(CardReceiptData, Expense);
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Released;
        ExpenseReportHeader.Modify();

        // [WHEN] The receipt data is applied.
        asserterror CardReceiptDataApply.Apply(CardReceiptData);

        // [THEN] An error says the expense is not waiting for a receipt.
        Assert.ExpectedError(StrSubstNo(NotWaitingForReceiptErr, Expense."No."));
    end;

    [Test]
    procedure ReceiptDataCannotBeAppliedWithoutReceiptFile()
    var
        Expense: Record Expense;
        CardReceiptData: Record "EA Card Receipt Data";
    begin
        // [SCENARIO] Receipt data must include the receipt file.
        Initialize();

        // [GIVEN] Receipt data for a card expense without file content.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        CardReceiptData.Init();
        CardReceiptData."Expense SystemId" := Expense.SystemId;
        CardReceiptData."Expense No." := Expense."No.";
        CardReceiptData."File Name" := 'receipt.pdf';
        CardReceiptData.Insert(true);

        // [WHEN] The receipt data is applied.
        asserterror CardReceiptDataApply.Apply(CardReceiptData);

        // [THEN] An error asks for the receipt file.
        Assert.ExpectedError(ReceiptRequiredErr);
    end;

    [Test]
    procedure CardLineWaitingForReceiptSkipsReceiptRules()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [SCENARIO] A card expense and line waiting for a receipt are not checked for the receipt number.
        Initialize();
        EnableReceiptNoRule();

        // [GIVEN] A card expense without receipt on an open report.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);

        // [WHEN] The expense and the line are validated against the rules.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] Neither has the receipt number violation, and the missing receipt is not reported when the category doesn't enforce it.
        Assert.IsFalse(HasExpenseViolation(Expense, StrSubstNo(ReceiptNoMandatoryOnExpenseErr, Expense."No.")), 'A card expense waiting for a receipt must not require a receipt number.');
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, StrSubstNo(ReceiptNoMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line waiting for a receipt must not require a receipt number.');
        Assert.IsFalse(HasExpenseViolation(Expense, StrSubstNo(ExpenseDocumentAttachmentMandatoryMsg, Expense."No.")), 'A card expense must report a missing receipt only when its category enforces it.');
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, StrSubstNo(ERLDocumentAttachmentMandatoryMsg, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line must report a missing receipt only when its category enforces it.');
    end;

    [Test]
    procedure CardLineWaitingForReceiptSkipsItemizationTotal()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [SCENARIO] The itemization total is checked on a card line only once it has a receipt.
        Initialize();
        EnableReceiptNoRule();

        // [GIVEN] A card line waiting for a receipt, with a category that requires itemization and no items.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseCategory.Code, true);
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Modify(true);

        // [WHEN] The line is validated against the rules.
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] The line has no itemization total violation.
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, StrSubstNo(ItemizationTotalMismatchErr, 0, ExpenseReportLine.Amount)), 'A card line waiting for a receipt must not check the itemization total.');

        // [WHEN] The line gets a receipt and is validated again.
        ExpenseReportLine."Receipt Attached" := true;
        ExpenseReportLine.Modify();
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] The line has the itemization total violation.
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, StrSubstNo(ItemizationTotalMismatchErr, 0, ExpenseReportLine.Amount)), 'A card line with a receipt must check the itemization total.');
    end;

    [Test]
    procedure ReceiptAttachedDirectlyToCardLineRunsAllRules()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        TempBlob: Codeunit "Temp Blob";
        LineRecordRef: RecordRef;
        ReceiptInStream: InStream;
        ReceiptOutStream: OutStream;
    begin
        // [SCENARIO] Attaching a receipt directly to a card line checks the line against all rules right away.
        Initialize();
        EnableReceiptNoRule();

        // [GIVEN] A card line waiting for a receipt on an open report.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [WHEN] A receipt is attached directly to the line.
        TempBlob.CreateOutStream(ReceiptOutStream);
        ReceiptOutStream.WriteText('Receipt');
        TempBlob.CreateInStream(ReceiptInStream);
        LineRecordRef.GetTable(ExpenseReportLine);
        DocumentAttachment.InitFieldsFromRecRef(LineRecordRef);
        DocumentAttachment.SaveAttachmentFromStream(ReceiptInStream, LineRecordRef, 'receipt.txt');

        // [THEN] The missing receipt violation is gone and the receipt number rule applies.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("Receipt Attached", true);
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, StrSubstNo(ERLDocumentAttachmentMandatoryMsg, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line with a receipt must not report a missing receipt.');
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, StrSubstNo(ReceiptNoMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line with a receipt must require a receipt number.');
    end;

    [Test]
    procedure CardLineGetsAllRulesAfterReceiptIsApplied()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CardReceiptData: Record "EA Card Receipt Data";
    begin
        // [SCENARIO] Once the receipt is applied, the card line is checked against all rules.
        Initialize();
        EnableReceiptNoRule();

        // [GIVEN] A card expense on an open report, and receipt data without a receipt number.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        CreateCardReceiptData(CardReceiptData, Expense);

        // [WHEN] The receipt data is applied.
        CardReceiptDataApply.Apply(CardReceiptData);

        // [THEN] The line has the receipt number violation.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, StrSubstNo(ReceiptNoMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line with a receipt must require a receipt number.');
    end;

    [Test]
    procedure ReceiptNotNeededCardLineGetsAllRules()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [SCENARIO] A card line that doesn't need a receipt is checked against all rules right away.
        Initialize();
        EnableReceiptNoRule();

        // [GIVEN] A card line on an open report that doesn't need a receipt.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        ExpenseReportLine."No Receipt Type" := ExpenseReportLine."No Receipt Type"::"Receipt not needed";
        ExpenseReportLine.Modify();

        // [WHEN] The line is validated against the rules.
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] The line has the receipt number violation.
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, StrSubstNo(ReceiptNoMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line that does not need a receipt must require a receipt number.');
    end;

    [Test]
    procedure ReleasingReportChecksMerchantOnCardLineWaitingForReceipt()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseCategory: Record "Expense Category";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [SCENARIO] Report release enforces the merchant rule even when the card receipt is still missing.
        Initialize();
        EnableReceiptAndMerchantRules();

        // [GIVEN] A card line with a category but without receipt on an open report.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), '');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Description := 'CONTOSO COFFEE';
        ExpenseReportLine.Modify(true);
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
        AssertCardLineMerchantNotReceiptNoViolation(ExpenseReportLine);

        // [WHEN] The report is released.
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        asserterror Codeunit.Run(Codeunit::"Release Exp. Report Document", ExpenseReportHeader);

        // [THEN] Release rejects the outstanding rule violation.
        Assert.ExpectedError(RuleViolationPresentOnLineErr);
    end;

    [Test]
    procedure FilledBlankMerchantLetsCardLineReportBeReleased()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO] A merchant the card feed left blank can be filled on the card line, and the report can then be released.
        Initialize();
        EnableReceiptAndMerchantRules();

        // [GIVEN] A card line without a merchant and receipt, with a category and description, on an open report.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), '');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Description := 'CONTOSO COFFEE';
        ExpenseReportLine.Modify(true);

        // [WHEN] The user fills in the merchant.
        ExpenseReportLine.Validate("Merchant Name", 'CONTOSO COFFEE');
        ExpenseReportLine.Modify(true);

        // [THEN] The merchant is kept and no longer flagged, and the report can be released.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.TestField("Merchant Name", 'CONTOSO COFFEE');
        Assert.IsFalse(
            HasLineViolation(ExpenseReportLine, StrSubstNo(MerchantNameMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")),
            'The filled merchant must satisfy the merchant rule.');
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        Codeunit.Run(Codeunit::"Release Exp. Report Document", ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::Released);
    end;

    [Test]
    procedure BlankFeedMerchantCanBeFilledOnceOnCardExpense()
    var
        Expense: Record Expense;
    begin
        // [SCENARIO] A merchant the card feed left blank can be filled on the card expense; after that it is kept.
        Initialize();

        // [GIVEN] An open card expense whose transaction has no merchant.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), '');

        // [WHEN] The user fills in the merchant.
        Expense.Validate("Merchant Name", 'CONTOSO COFFEE');
        Expense.Modify(true);

        // [THEN] The merchant is saved, and changing it again is rejected.
        Expense.Get(Expense."No.");
        Expense.TestField("Merchant Name", 'CONTOSO COFFEE');
        asserterror Expense.Validate("Merchant Name", 'OTHER MERCHANT');
        Assert.ExpectedError(StrSubstNo(CardExpenseSourceFieldCannotChangeErr, Expense.FieldCaption("Merchant Name")));
    end;

    [Test]
    procedure ExpenseWithoutCardTransactionCannotBeAddedAsCardExpense()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO] The card-specific add requires the expense to be linked to a card transaction.
        Initialize();

        // [GIVEN] A card-origin expense that is no longer linked to a card transaction, and an open report.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense."Credit Card Feed No." := 0;
        Expense.Modify();
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");

        // [WHEN] The expense is added with the card-specific add.
        asserterror CreateExpenseReport.AddCardExpenseToExpenseReport(Expense, ExpenseReportHeader);

        // [THEN] An error says the card transaction is missing.
        Assert.ExpectedTestFieldError(Expense.FieldCaption("Credit Card Feed No."), '');
    end;

    [Test]
    procedure ReportWithCardLineWaitingForReceiptCanBeReleased()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO] Releasing a report doesn't check the receipt number on card lines still waiting for a receipt.
        Initialize();
        EnableReceiptNoRule();

        // [GIVEN] A card line with a category but without receipt on an open report.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Description := 'CONTOSO COFFEE';
        ExpenseReportLine.Modify(true);

        // [WHEN] The report is released.
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        Codeunit.Run(Codeunit::"Release Exp. Report Document", ExpenseReportHeader);

        // [THEN] The report is released.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::Released);
    end;

    [Test]
    procedure ReceiptNotNeededCardLineNeedsReceiptNoAndJustification()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [SCENARIO] A card line that will never get a receipt no longer waits for one, so all rules apply, including the receipt
        // number and the justification. Its locked amount exceeds the maximum, and a justification accepts it.
        Initialize();
        EnableReceiptNoRule();

        // [GIVEN] A rule for a category that requires a justification from 15 and allows at most 10.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', 0D, ExpenseRuleHeader."Justification Required"::"Against Conditions", '', '',
            ExpenseRuleCondition."Condition Type"::"Max Amount", 10);
        LibraryExpense.CreateExpenseRuleCondition(ExpenseRuleCondition, ExpenseRuleHeader, ExpenseRuleCondition."Condition Type"::"At Least Justification Needed", 15);

        // [GIVEN] An itemized card line of 20 in that category on an open report, and the card expense and line don't need a receipt.
        // Amount conditions are evaluated for itemized, participant and mileage lines.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        Expense."No Receipt Type" := Expense."No Receipt Type"::"Receipt not needed";
        Expense.Modify();
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Modify(true);
        ExpenseReportLine."Expense Detail Required" := ExpenseReportLine."Expense Detail Required"::Itemize;
        ExpenseReportLine."No Receipt Type" := ExpenseReportLine."No Receipt Type"::"Receipt not needed";
        ExpenseReportLine.Modify();

        // [WHEN] The line is validated against the rules.
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] Neither waits for a receipt, so the receipt number, the justification and the maximum are all flagged.
        Assert.IsFalse(ExpenseRuleValidation.IsCardExpenseWaitingForReceipt(Expense), 'A card expense that needs no receipt must not wait for one.');
        Assert.IsFalse(ExpenseRuleValidation.IsCardLineWaitingForReceipt(ExpenseReportLine), 'A card line that needs no receipt must not wait for one.');
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, StrSubstNo(ReceiptNoMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line that does not wait for a receipt must require a receipt number.');
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, JustificationRequiredErr), 'The justification rule must apply to a card line that does not wait for a receipt.');
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, StrSubstNo(MaxAmountErr, 10)), 'Without a justification, the exceeded maximum must be flagged.');

        // [WHEN] The user enters the receipt number and a justification.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine."Expense Ext. Doc. No." := 'R-0001';
        ExpenseReportLine.Justification := 'Client dinner';
        ExpenseReportLine.Modify();
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] The receipt number, the justification and the locked amount are no longer flagged.
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, StrSubstNo(ReceiptNoMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'The entered receipt number must satisfy the receipt number rule.');
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, JustificationRequiredErr), 'The entered justification must satisfy the justification rule.');
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, StrSubstNo(MaxAmountErr, 10)), 'A justification must accept the locked card amount.');
    end;

    [Test]
    procedure LostReceiptCardLineCannotBeReleasedWithoutDeclaration()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO] A card line marked as lost receipt doesn't wait for a receipt, but the report needs a current no receipt
        // declaration for it.
        Initialize();

        // [GIVEN] A card line on an open report, marked as lost receipt without a declaration.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        ExpenseReportLine."No Receipt Type" := ExpenseReportLine."No Receipt Type"::"Lost Receipt";
        ExpenseReportLine."No Receipt Reason" := 'Receipt was lost';
        ExpenseReportLine.Modify();

        // [WHEN] The report is released.
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        asserterror Codeunit.Run(Codeunit::"Release Exp. Report Document", ExpenseReportHeader);

        // [THEN] Release asks for the declaration.
        Assert.ExpectedError(StrSubstNo(NoReceiptDeclarationNotCurrentErr, Expense."No."));
    end;

    [Test]
    procedure LostReceiptCardExpenseWithDeclarationCanBeReleasedOnReport()
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        NoReceiptDeclarationMgt: Codeunit "No Receipt Declaration Mgt.";
    begin
        // [SCENARIO] A card expense whose receipt was lost gets a no receipt declaration, is added with the card action, and its
        // report can be released.
        Initialize();
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Allow No Receipt" := true;
        ExpenseAgentSetup.Modify();

        // [GIVEN] An open card expense with a description and a no receipt declaration.
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        Expense.Validate(Description, 'Coffee with a client');
        Expense.Modify(true);
        NoReceiptDeclarationMgt.CreateDeclaration(Expense, 'Receipt was lost', true);
        Expense.Get(Expense."No.");
        Expense.TestField("No Receipt Type", Expense."No Receipt Type"::"Lost Receipt");

        // [WHEN] The card expense is added to a report, and the report is released.
        AddCardExpenseToReport(Expense, ExpenseReportLine);
        ExpenseReportLine.TestField("No Receipt Type", ExpenseReportLine."No Receipt Type"::"Lost Receipt");
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        Codeunit.Run(Codeunit::"Release Exp. Report Document", ExpenseReportHeader);

        // [THEN] The report is released.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::Released);
    end;

    local procedure EnableReceiptNoRule()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Use Rules" := true;
        ExpenseAgentSetup."Receipt No. Mandatory" := true;
        ExpenseAgentSetup.Modify();
    end;

    local procedure EnableReceiptAndMerchantRules()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        EnableReceiptNoRule();
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Merchant Name Mandatory" := true;
        ExpenseAgentSetup.Modify();
    end;

    local procedure AssertCardLineMerchantNotReceiptNoViolation(ExpenseReportLine: Record "Expense Report Line")
    begin
        Assert.IsTrue(HasLineViolation(ExpenseReportLine, StrSubstNo(MerchantNameMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line must require the missing merchant.');
        Assert.IsFalse(HasLineViolation(ExpenseReportLine, StrSubstNo(ReceiptNoMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.")), 'A card line must not require a receipt number.');
    end;

    local procedure HasExpenseViolation(Expense: Record Expense; Violation: Text): Boolean
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.SetRange(Description, CopyStr(Violation, 1, MaxStrLen(ExpenseRuleViolation.Description)));
        exit(not ExpenseRuleViolation.IsEmpty());
    end;

    local procedure HasLineViolation(ExpenseReportLine: Record "Expense Report Line"; Violation: Text): Boolean
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportRuleViolation.SetRange(Description, CopyStr(Violation, 1, MaxStrLen(ExpenseReportRuleViolation.Description)));
        exit(not ExpenseReportRuleViolation.IsEmpty());
    end;

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
    end;

    local procedure FindMatch(Expense: Record Expense; ReceiptDate: Date; ReceiptAmount: Decimal): Guid
    begin
        exit(FindMatch(Expense, ReceiptDate, ReceiptAmount, ''));
    end;

    local procedure FindMatch(Expense: Record Expense; ReceiptDate: Date; ReceiptAmount: Decimal; CardLast4: Text): Guid
    begin
        exit(FindMatch(Expense, ReceiptDate, ReceiptAmount, Expense."Merchant Name", CardLast4));
    end;

    local procedure FindMatch(Expense: Record Expense; ReceiptDate: Date; ReceiptAmount: Decimal; ReceiptMerchantName: Text[100]; CardLast4: Text): Guid
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        exit(ReceiptExpenseMatch.FindMatchingExpense(ExpenseUser.SystemId, ReceiptDate, ReceiptAmount, '', ReceiptMerchantName, CardLast4));
    end;

    local procedure CheckMatch(Expense: Record Expense; ExpenseSystemId: Guid; ReceiptDate: Date; ReceiptAmount: Decimal): Guid
    begin
        exit(CheckMatch(Expense, ExpenseSystemId, ReceiptDate, ReceiptAmount, ''));
    end;

    // Checks the receipt for the expense user of Expense against the expense identified by ExpenseSystemId.
    local procedure CheckMatch(Expense: Record Expense; ExpenseSystemId: Guid; ReceiptDate: Date; ReceiptAmount: Decimal; CardLast4: Text): Guid
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        exit(ReceiptExpenseMatch.CheckMatchingExpense(ExpenseUser.SystemId, ExpenseSystemId, ReceiptDate, ReceiptAmount, '', CardLast4));
    end;

    local procedure CreateAdditionalCard(CardId: Code[50]; MaskedCardNo: Text[30]): Code[50]
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.Get(CardId);
        exit(CorpCardTestLib.CreateAdditionalCard(CorpCard, MaskedCardNo));
    end;

    local procedure CreateCardExpense(var Expense: Record Expense; CardId: Code[50]; ExpenseDate: Date; MerchantName: Text[100])
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        CorpCard.Get(CardId);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        Expense.Get(ExpenseNo);
        Expense."Expense Date" := ExpenseDate;
        Expense."Merchant Name" := MerchantName;
        Expense.Modify();
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
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.CreateExpense(Expense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, '', 20);
        Expense.Validate("Corporate Card Id", CorpCard."Card Id");
        Expense.Modify(true);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        CorpCardExpenseMatch.LinkExpense(CorpCardTrans, Expense."No.");
        CorpCardTrans.Modify(true);
        Expense.Get(Expense."No.");
        Expense.TestField(Source, Expense.Source::Manual);
        Expense.TestField("Receipt Attached", false);
    end;

    local procedure ClearCategory(var Expense: Record Expense)
    begin
        Expense."Expense Category" := '';
        Expense."Expense Subcategory" := '';
        Expense.Modify();
    end;

    local procedure CreateReleasedCardExpenseNotOnReport(var Expense: Record Expense)
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        CreateCardExpense(Expense, 'CORPCARD-0001', WorkDate(), 'CONTOSO COFFEE');
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Credit Card", ExpenseCategory."Expense Detail Required"::" ", ExpensePaymentMethod.Code);
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Validate(Description, 'User description');
        Expense.Modify(true);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        Expense.Get(Expense."No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
        Expense.TestField("Receipt Attached", false);
    end;

    local procedure AddCardExpenseToReport(var Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        Expense.Get(Expense."No.");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        ExpenseReportLine := CreateExpenseReport.AddCardExpenseToExpenseReport(Expense, ExpenseReportHeader);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Expense.Get(Expense."No.");
    end;

    local procedure CreateCardReceiptData(var CardReceiptData: Record "EA Card Receipt Data"; Expense: Record Expense)
    var
        ContentOutStream: OutStream;
    begin
        CardReceiptData.Init();
        CardReceiptData."Expense SystemId" := Expense.SystemId;
        CardReceiptData."Expense No." := Expense."No.";
        CardReceiptData."File Name" := 'receipt.pdf';
        CardReceiptData."Attachment Content".CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText('receipt');
        CardReceiptData.Insert(true);
    end;

    local procedure AddCardReceiptParticipant(CardReceiptData: Record "EA Card Receipt Data"; ParticipantName: Text[100])
    var
        CardReceiptParticipant: Record "EA Card Receipt Participant";
    begin
        CardReceiptParticipant.Init();
        CardReceiptParticipant."Receipt Data Id" := CardReceiptData.Id;
        CardReceiptParticipant."Line No." := 10000;
        CardReceiptParticipant."Participant Type" := CardReceiptParticipant."Participant Type"::External;
        CardReceiptParticipant."Participant Name" := ParticipantName;
        CardReceiptParticipant.Insert(true);
    end;

    local procedure AddCardReceiptItem(CardReceiptData: Record "EA Card Receipt Data"; ExpenseSubcategoryCode: Code[20]; ItemAmount: Decimal)
    var
        CardReceiptItem: Record "EA Card Receipt Item";
    begin
        CardReceiptItem.Init();
        CardReceiptItem."Receipt Data Id" := CardReceiptData.Id;
        CardReceiptItem."Line No." := 10000;
        CardReceiptItem."Expense Subcategory Code" := ExpenseSubcategoryCode;
        CardReceiptItem."Start Date" := WorkDate();
        CardReceiptItem.Quantity := 1;
        CardReceiptItem."Daily Rate" := ItemAmount;
        CardReceiptItem.Insert(true);
    end;

    local procedure CountAttachments(TableId: Integer; No: Code[20]; LineNo: Integer): Integer
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", No);
        DocumentAttachment.SetRange("Line No.", LineNo);
        exit(DocumentAttachment.Count());
    end;
}
