// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using System.Utilities;

/// <summary>
/// Adds released expenses to expense reports as expense report lines, including their participants, itemizations, per diem lines, VAT specifications and attachments.
/// </summary>
codeunit 6983 "Create Expense Report"
{
    var
        ShowExpenseReportQst: Label 'The Expense Report is created as number %1.\\ Do you want to open it now ?', Comment = '%1 - Expense Report No.';
        ShowExpenseReportUpdateQst: Label 'The Expense Report is updated with your expense as number %1.\\ Do you want to open it now ?', Comment = '%1 - Expense Report No.';

    /// <summary>
    /// Adds selected expenses to an expense report as lines
    /// </summary>
    /// <param name="ExpenseReportHeader">Target expense report header</param>
    internal procedure AddExpensesToReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        Expense: Record Expense;
        Expenses: Page Expenses;
        ExpenseCount: Integer;
    begin
        ExpenseReportHeader.TestField("Expense User No.");

        FilterExpense(Expense, ExpenseReportHeader);

        Expenses.LookupMode(true);
        Expenses.SetTableView(Expense);
        if Expenses.RunModal() = Action::LookupOK then begin
            Expenses.SetSelectionFilter(Expense);
            ExpenseCount := Expense.Count();
            if ExpenseCount = 0 then
                exit;
        end else
            exit;

        LoopThruExpenseToAddInReport(Expense, ExpenseReportHeader);
    end;

    internal procedure AddExpensesToReport(var Expense: Record Expense)
    var
        ExpenseReportHeader: Record "Expense Report Header";
        AddExpensesToExpenseReport: Page "Add Expenses To Expense Report";
        ExpenseReportNo: Code[20];
    begin
        Expense.FindFirst();
        AddExpensesToExpenseReport.SetExpenseRecord(Expense);
        AddExpensesToExpenseReport.LookupMode(true);
        if AddExpensesToExpenseReport.RunModal() = Action::LookupOK then
            ExpenseReportNo := AddExpensesToExpenseReport.GetExpenseReportNo()
        else
            Error('');

        ExpenseReportHeader := GetExpenseReportHeader(ExpenseReportNo, Expense."Expense User No.", Expense."VAT Bus. Posting Group");
        LoopThruExpenseToAddInReport(Expense, ExpenseReportHeader);
        ShowExpenseReport(ExpenseReportHeader, ExpenseReportNo <> '');
    end;

    local procedure ShowExpenseReport(ExpenseReportHeader: Record "Expense Report Header"; ShowUpdateMessage: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        MessageToShow: Text;
    begin
        if not GuiAllowed then
            exit;

        if ShowUpdateMessage then
            MessageToShow := StrSubstNo(ShowExpenseReportUpdateQst, ExpenseReportHeader."No.")
        else
            MessageToShow := StrSubstNo(ShowExpenseReportQst, ExpenseReportHeader."No.");

        if not ConfirmManagement.GetResponseOrDefault(MessageToShow, true) then
            exit;

        Commit();
        Page.Run(Page::"Expense Report", ExpenseReportHeader);
    end;

    local procedure GetExpenseReportHeader(ExpenseReportNo: Code[20]; ExpenseUserNo: Code[20]; VATBusPostingGroup: Code[20]): Record "Expense Report Header"
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        if ExpenseReportHeader.Get(ExpenseReportNo) then
            exit(ExpenseReportHeader);

        ExpenseReportHeader.Init();
        ExpenseReportHeader.Validate("Expense User No.", ExpenseUserNo);
        ExpenseReportHeader.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        ExpenseReportHeader.Insert(true);

        exit(ExpenseReportHeader);
    end;

    local procedure LoopThruExpenseToAddInReport(var Expense: Record Expense; ExpenseReportHeader: Record "Expense Report Header")
    begin
        if Expense.FindSet() then
            repeat
                AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
            until Expense.Next() = 0;
    end;

    /// <summary>
    /// Filters expenses to show only those that can be added to the report
    /// </summary>
    /// <param name="Expense">Expense record to filter</param>
    /// <param name="ExpenseReportHeader">Source expense report header</param>
    local procedure FilterExpense(var Expense: Record Expense; ExpenseReportHeader: Record "Expense Report Header")
    begin
        Expense.SetRange("Expense User No.", ExpenseReportHeader."Expense User No.");
        Expense.SetRange("Expense Report No.", '');
        Expense.SetRange(Status, Expense.Status::Released);
    end;

    /// <summary>
    /// Updates the expense with the expense report number
    /// </summary>
    /// <param name="Expense">Expense to update</param>
    /// <param name="ExpenseReportNo">Expense report number</param>
    local procedure UpdateExpenseWithReportNo(var Expense: Record Expense; ExpenseReportNo: Code[20])
    begin
        Expense.Validate("Expense Report No.", ExpenseReportNo);
        Expense.Validate(Status, Expense.Status::Submitted);
        Expense.Modify(true);
    end;

    /// <summary>
    /// Inserts a single expense as an expense report line
    /// </summary>
    /// <param name="ExpenseReportHeader">Target expense report header</param>
    /// <param name="Expense">Source expense</param>
    /// <param name="ExpenseReportLineNo">Line number for the new expense report line</param>
    local procedure InsertExpenseReportLine(ExpenseReportHeader: Record "Expense Report Header"; Expense: Record Expense; ExpenseReportLineNo: Integer): Record "Expense Report Line"
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.Init();
        ExpenseReportLine."Document No." := ExpenseReportHeader."No.";
        ExpenseReportLine."Line No." := ExpenseReportLineNo;
        ExpenseReportLine."Expense No." := Expense."No.";
        ExpenseReportLine.SetSkipRuleApplication(true);
        ExpenseReportLine.Insert(true);

        CopyExpenseFieldsToReportLine(Expense, ExpenseReportLine);
        ExpenseReportLine.UpdateAmounts();
        ExpenseReportLine.Modify(true);

        CopyParticipantsToReportLine(Expense, ExpenseReportLine);
        CopyItemizationsToReportLine(Expense, ExpenseReportLine);
        CopyPerDiemToReportLine(Expense, ExpenseReportLine);
        CopyVATSpecsToReportLine(Expense, ExpenseReportLine);
        ExpenseReportLine.SetSkipRuleApplication(false);

        ExpenseReportLine.ApplyRule(false, true);
        ExpenseReportLine.Modify();

        CopyAttachments(Expense, ExpenseReportLine);

        exit(ExpenseReportLine);
    end;

    /// <summary>
    /// Copies all relevant fields from expense to expense report line
    /// </summary>
    /// <param name="Expense">Source expense</param>
    /// <param name="ExpenseReportLine">Target expense report line</param>
    local procedure CopyExpenseFieldsToReportLine(Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        ExpenseReportLine.Validate("Expense No.", Expense."No.");
        ExpenseReportLine.Validate("Expense Date", Expense."Expense Date");
        ExpenseReportLine.Validate("Expense Time", Expense."Expense Time");
        ExpenseReportLine.Validate("Expense User No.", Expense."Expense User No.");
        ExpenseReportLine.Validate("Expense Category", Expense."Expense Category");
        ExpenseReportLine.Validate("Expense Subcategory Code", Expense."Expense Subcategory");
        ExpenseReportLine.Validate("Expense Location", CopyStr(Expense."Expense Location", 1, MaxStrLen(ExpenseReportLine."Expense Location")));
        if Expense.Description <> '' then
            ExpenseReportLine.Validate(Description, Expense.Description);
        if ExpenseReportLine."Expense Subcategory Code" <> '' then
            ExpenseReportLine.Validate(Description, ExpenseReportLine.UpdatePostingDescription());
        ExpenseReportLine.Validate("Receipt Entry", Expense."Receipt Entry");
        // Unresolved VAT mappings must not prevent submission; posting validates the accounting setup.
        ExpenseReportLine."VAT Bus. Posting Group" := Expense."VAT Bus. Posting Group";
        ExpenseReportLine."VAT Prod. Posting Group" := Expense."VAT Prod. Posting Group";
        if ExpenseReportLine."VAT Prod. Posting Group" <> '' then
            if VATPostingSetup.Get(ExpenseReportLine."VAT Bus. Posting Group", ExpenseReportLine."VAT Prod. Posting Group") then
                if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Normal VAT" then
                    ExpenseReportLine.CopyFromVATPostingSetup(VATPostingSetup);
        ExpenseReportLine.Validate("Unit of Measure Code", Expense."Unit of Measure Code");
        ExpenseReportLine.Validate(Justification, Expense.Justification);
        ExpenseReportLine.Validate("Merchant Name", Expense."Merchant Name");
        ExpenseReportLine.Validate("Merchant Registration No.", Expense."Merchant Registration No.");
        ExpenseReportLine.Validate("Merchant VAT Registration No.", Expense."Merchant VAT Registration No.");
        ExpenseReportLine.Validate("Expense Vendor No.", Expense."Expense Vendor No.");
        ExpenseReportLine.Validate("Payment Method Code", Expense."Payment Method Code");
        ExpenseReportLine.Validate(Billable, Expense.Billable);
        ExpenseReportLine.Validate("Billable to Customer", Expense."Billable to Customer");
        ExpenseReportLine.Validate("Starting Date and Time", Expense."Starting Date and Time");
        ExpenseReportLine.Validate("Ending Date and Time", Expense."Ending Date and Time");
        ExpenseReportLine.Validate(Mileage, Expense.Mileage);
        ExpenseReportLine.Validate("Round Trip", Expense."Round Trip");
        ExpenseReportLine.Validate("Vehicle Type", Expense."Vehicle Type");
        ExpenseReportLine."Starting Point" := Expense."Starting Point";
        ExpenseReportLine."Ending Point" := Expense."Ending Point";
        ExpenseReportLine."Credit Card Feed No." := Expense."Credit Card Feed No.";
        ExpenseReportLine."Corporate Card Id" := Expense."Corporate Card Id";
        ExpenseReportLine.Validate("Reimbursement Type", Expense."Reimbursement Type");
        ExpenseReportLine.Validate("Expense Detail Required", Expense."Expense Detail Required");
        ExpenseReportLine.Validate("Expense Currency Code", Expense."Currency Code");
        ExpenseReportLine.Validate("Job No.", Expense."Job No.");
        ExpenseReportLine.Validate("Job Task No.", Expense."Job Task No.");
        ExpenseReportLine."Shortcut Dimension 1 Code" := Expense."Shortcut Dimension 1 Code";
        ExpenseReportLine."Shortcut Dimension 2 Code" := Expense."Shortcut Dimension 2 Code";
        ExpenseReportLine."Dimension Set ID" := Expense."Dimension Set ID";
        ExpenseReportLine.Amount := Expense.Amount;
        ExpenseReportLine."Amount (LCY)" := Expense."Amount (LCY)";
        ExpenseReportLine."Reimbursable Amount" := Expense."Reimbursable Amount";
        ExpenseReportLine."Reimbursable Amount (LCY)" := Expense."Reimbursable Amount (LCY)";
        ExpenseReportLine.Refundable := Expense.Refundable;
        ExpenseReportLine."Non-Refundable Amount" := Expense."Non-Refundable Amount";
        ExpenseReportLine."Non-Refundable Amount (LCY)" := Expense."Non-Refundable Amount (LCY)";
        ExpenseReportLine."Expense Currency Factor" := Expense."Currency Factor";
        ExpenseReportLine."Amount without VAT" := ExpenseReportLine.Amount - ExpenseReportLine."VAT Amount";
        ExpenseReportLine."Applied Rule Id" := Expense."Applied Rule Id";
        ExpenseReportLine."Expense Ext. Doc. No." := Expense."Expense Ext. Doc. No.";
        ExpenseReportLine."No Receipt Type" := Expense."No Receipt Type";
        ExpenseReportLine."No Receipt Reason" := Expense."No Receipt Reason";
        ExpenseReportLine."No Receipt Declaration ID" := Expense."No Receipt Declaration ID";
        ExpenseReportLine."Compliance Status" := Expense."Compliance Status";
        ExpenseReportLine."No Receipt Generated At" := Expense."No Receipt Generated At";
        ExpenseReportLine."No Receipt Generated By" := Expense."No Receipt Generated By";

        OnAfterCopyExpenseFieldsToReportLine(Expense, ExpenseReportLine);
    end;

    /// <summary>
    /// Copies participants from expense to expense report line
    /// </summary>
    /// <param name="Expense">Source expense</param>
    /// <param name="ExpenseReportLine">Target expense report line</param>
    local procedure CopyParticipantsToReportLine(Expense: Record Expense; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportHelper: Codeunit "Expense Report";
    begin
        ExpenseReportHelper.CopyParticipantsFromExpense(Expense."No.", ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
    end;

    /// <summary>
    /// Copies itemizations from expense to expense report line
    /// </summary>
    /// <param name="Expense">Source expense</param>
    /// <param name="ExpenseReportLine">Target expense report line</param>
    local procedure CopyItemizationsToReportLine(Expense: Record Expense; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportHelper: Codeunit "Expense Report";
    begin
        ExpenseReportHelper.CopyItemizationFromExpense(Expense."No.", ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
    end;

    /// <summary>
    /// Copies per diem from expense to expense report line
    /// </summary>
    /// <param name="Expense">Source expense</param>
    /// <param name="ExpenseReportLine">Target expense report line</param>
    local procedure CopyPerDiemToReportLine(Expense: Record Expense; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportHelper: Codeunit "Expense Report";
    begin
        ExpenseReportHelper.CopyPerDiemFromExpense(Expense."No.", ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
    end;

    /// <summary>
    /// Adds a released expense to an expense report as a new expense report line. The expense's participants, itemizations, per diem lines, VAT specifications and attachments are copied to the line, the expense rules are evaluated and any violations are recorded, and the expense is marked as submitted on the report.
    /// </summary>
    /// <remarks>
    /// The expense must be released, belong to the same expense user as the report, and not already be on an expense report. No user interface is shown.
    /// </remarks>
    /// <param name="Expense">The expense to add.</param>
    /// <param name="ExpenseReportHeader">The expense report to add the expense to.</param>
    /// <returns>The created expense report line.</returns>
    procedure AddSingleExpenseToExpenseReport(Expense: Record Expense; ExpenseReportHeader: Record "Expense Report Header"): Record "Expense Report Line"
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineNo: Integer;
    begin
        ValidateExpense(Expense, ExpenseReportHeader);
        ExpenseReportLineNo := ExpenseReportLine.GetNextExpenseReportLineNo(ExpenseReportHeader."No.");

        ExpenseReportLine := InsertExpenseReportLine(ExpenseReportHeader, Expense, ExpenseReportLineNo);
        UpdateExpenseWithReportNo(Expense, ExpenseReportHeader."No.");

        exit(ExpenseReportLine);
    end;

    local procedure ValidateExpense(Expense: Record Expense; ExpenseReportHeader: Record "Expense Report Header")
    begin
        Expense.TestField("Expense User No.", ExpenseReportHeader."Expense User No.");
        Expense.TestField(Status, Expense.Status::Released);
        Expense.TestField("Expense Report No.", '');
    end;

    /// <summary>
    /// Adds an expense created from a corporate card transaction to an open expense report for the Expense Agent. An open
    /// card expense is released first without requiring an expense category, so the line can be added before the user
    /// picks one; the report still requires a category on every line before it can be released.
    /// </summary>
    /// <param name="Expense">The card expense to add. It must belong to the report's expense user and not be on a report.</param>
    /// <param name="ExpenseReportHeader">The open expense report to add the expense to.</param>
    /// <returns>The created expense report line.</returns>
    internal procedure AddCardExpenseToExpenseReport(var Expense: Record Expense; ExpenseReportHeader: Record "Expense Report Header"): Record "Expense Report Line"
    var
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        Expense.TestField(Source, Expense.Source::CorporateCard);
        Expense.TestField("Credit Card Feed No.");
        Expense.TestField("Expense User No.", ExpenseReportHeader."Expense User No.");
        Expense.TestField("Expense Report No.", '');
        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::Open);

        if Expense.Status = Expense.Status::Open then
            ReleaseExpenseDocument.ReleaseCardExpenseWithoutCategory(Expense);
        Expense.TestField(Status, Expense.Status::Released);

        exit(AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader));
    end;

    local procedure CopyAttachments(Expense: Record Expense; ExpenseReportLine: Record "Expense Report Line")
    var
        DocumentAttachmentMgt: Codeunit "Document Attachment Mgmt";
    begin
        DocumentAttachmentMgt.CopyAttachments(Expense, ExpenseReportLine);
    end;

    /// <summary>
    /// Copies all VAT specification rows from the source Expense to the Expense Report Line.
    /// One <see cref="Exp. Report Line VAT Spec."/> row is created per <see cref="Expense VAT Specification"/> row.
    /// Any pre-existing specs for this report line are removed first.
    /// </summary>
    local procedure CopyVATSpecsToReportLine(Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseVATSpec: Record "Expense VAT Specification";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
    begin
        ExpenseVATSpec.SetRange("Expense No.", Expense."No.");
        if not ExpenseVATSpec.FindSet() then
            exit;

        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportLine."Document No.");
        ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLineVATSpec.DeleteAll();

        repeat
            ExpenseReportLineVATSpec.Init();
            ExpenseReportLineVATSpec."Document No." := ExpenseReportLine."Document No.";
            ExpenseReportLineVATSpec."Document Line No." := ExpenseReportLine."Line No.";
            ExpenseReportLineVATSpec."Line No." := ExpenseVATSpec."Line No.";
            ExpenseReportLineVATSpec."Expense Category" := ExpenseVATSpec."Expense Category";
            ExpenseReportLineVATSpec."Expense Subcategory" := ExpenseVATSpec."Expense Subcategory";
            ExpenseReportLineVATSpec."VAT %" := ExpenseVATSpec."VAT %";
            ExpenseReportLineVATSpec."VAT Base Amount" := ExpenseVATSpec."VAT Base Amount";
            ExpenseReportLineVATSpec."VAT Amount" := ExpenseVATSpec."VAT Amount";
            ExpenseReportLineVATSpec.Amount := ExpenseVATSpec.Amount;
            ExpenseReportLineVATSpec."VAT Difference" := ExpenseVATSpec."VAT Difference";
            ExpenseReportLineVATSpec."Currency Code" := Expense."Currency Code";
            ExpenseReportLineVATSpec."Currency Factor" := Expense."Currency Factor";
            ExpenseReportLineVATSpec."VAT Bus. Posting Group" := ExpenseVATSpec."VAT Bus. Posting Group";
            ExpenseReportLineVATSpec."VAT Prod. Posting Group" := ExpenseVATSpec."VAT Prod. Posting Group";
            ExpenseReportLineVATSpec."VAT Amount (LCY)" := ExpenseVATSpec."VAT Amount (LCY)";
            ExpenseReportLineVATSpec."VAT Base Amount (LCY)" := ExpenseVATSpec."VAT Base Amount (LCY)";
            ExpenseReportLineVATSpec."Amount (LCY)" := ExpenseVATSpec."Amount (LCY)";
            ExpenseReportLineVATSpec.Source := ExpenseVATSpec.Source;
            ExpenseReportLineVATSpec.Confidence := ExpenseVATSpec.Confidence;
            ExpenseReportLineVATSpec."Source Spec Line No." := ExpenseVATSpec."Line No.";
            if ExpenseSubcategory.Get(ExpenseVATSpec."Expense Category", ExpenseVATSpec."Expense Subcategory") then
                ExpenseReportLineVATSpec.Validate("Reclaim %", ExpenseSubcategory."Default VAT Reclaim %")
            else
                if ExpenseCategory.Get(ExpenseVATSpec."Expense Category") then
                    ExpenseReportLineVATSpec.Validate("Reclaim %", ExpenseCategory."Default VAT Reclaim %");
            ExpenseReportLineVATSpec.UpdateReimbursementAmounts();
            ExpenseReportLineVATSpec.Insert();
        until ExpenseVATSpec.Next() = 0;

        // Spec rows exist — ensure the line is marked as VAT liable so posting picks up the VAT amounts.
        if not ExpenseReportLine."VAT Liable" then begin
            ExpenseReportLine."VAT Liable" := true;
            ExpenseReportLine.Modify();
        end;
    end;

    /// <summary>
    /// Raised after the fields of an expense are copied to a new expense report line, before the line amounts are recalculated and the line is saved.
    /// </summary>
    /// <remarks>
    /// Use this event to copy values from fields that an extension adds to the Expense table to the corresponding fields on the Expense Report Line table. Changes to the expense report line are saved by the caller. The event is raised inside the transaction that adds the expense to the report.
    /// </remarks>
    /// <param name="Expense">The expense that is added to the expense report.</param>
    /// <param name="ExpenseReportLine">The new expense report line. Changes to this record are saved.</param>
    [CommitBehavior(CommitBehavior::Ignore)]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyExpenseFieldsToReportLine(Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line")
    begin
    end;
}