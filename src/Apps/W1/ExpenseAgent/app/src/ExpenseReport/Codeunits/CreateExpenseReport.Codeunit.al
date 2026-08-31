// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;
using System.Utilities;

codeunit 6983 "Create Expense Report"
{
    Access = Internal;

    var
        ShowExpenseReportQst: Label 'The Expense Report is created as number %1.\\ Do you want to open it now ?', Comment = '%1 - Expense Report No.';
        ShowExpenseReportUpdateQst: Label 'The Expense Report is updated with your expense as number %1.\\ Do you want to open it now ?', Comment = '%1 - Expense Report No.';

    /// <summary>
    /// Adds selected expenses to an expense report as lines
    /// </summary>
    /// <param name="ExpenseReportHeader">Target expense report header</param>
    procedure AddExpensesToReport(var ExpenseReportHeader: Record "Expense Report Header")
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

    procedure AddExpensesToReport(var Expense: Record Expense)
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

        ExpenseReportHeader := GetExpenseReportHeader(ExpenseReportNo, Expense."Expense User No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");
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

    local procedure GetExpenseReportHeader(ExpenseReportNo: Code[20]; ExpenseUserNo: Code[20]; CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Record "Expense Report Header"
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        if ExpenseReportHeader.Get(ExpenseReportNo) then
            exit(ExpenseReportHeader);

        ExpenseReportHeader.Init();
        ExpenseReportHeader.Validate("Expense User No.", ExpenseUserNo);
        ExpenseReportHeader.Validate("Reimbursement Currency Code", CurrencyCode);
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
    begin
        ExpenseReportLine.Validate("Expense No.", Expense."No.");
        ExpenseReportLine.Validate("Expense Date", Expense."Expense Date");
        ExpenseReportLine.Validate("Expense Time", Expense."Expense Time");
        ExpenseReportLine.Validate("Expense User No.", Expense."Expense User No.");
        ExpenseReportLine.Validate("Expense Category", Expense."Expense Category");
        ExpenseReportLine.Validate("Expense Subcategory Code", Expense."Expense Subcategory");
        ExpenseReportLine.Validate("Expense Location", CopyStr(Expense."Expense Location", 1, 20));
        if Expense.Description <> '' then
            ExpenseReportLine.Validate(Description, Expense.Description);
        if ExpenseReportLine."Expense Subcategory Code" <> '' then
            ExpenseReportLine.Validate(Description, ExpenseReportLine.UpdatePostingDescription());
        ExpenseReportLine.Validate("Receipt Entry", Expense."Receipt Entry");
        ExpenseReportLine.Validate("VAT Bus. Posting Group", Expense."VAT Bus. Posting Group");
        ExpenseReportLine.Validate("VAT Prod. Posting Group", Expense."VAT Prod. Posting Group");
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
    /// Adds a single expense to an expense report as a line
    /// </summary>
    /// <param name="Expense">Source expense</param>
    /// <param name="ExpenseReportHeader">Target expense report header</param>
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
        Expense.TestField("VAT Bus. Posting Group", ExpenseReportHeader."VAT Bus. Posting Group");
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
            ExpenseVATSpec.TestField("VAT Bus. Posting Group");
            ExpenseVATSpec.TestField("VAT Prod. Posting Group");

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
}