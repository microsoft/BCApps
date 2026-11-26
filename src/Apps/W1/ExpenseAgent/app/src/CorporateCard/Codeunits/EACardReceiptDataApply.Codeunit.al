// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;
using System.IO;

/// <summary>
/// Applies staged receipt data to a corporate card expense that is waiting for a receipt and, when the expense is on an
/// open expense report, to its expense report line.
/// The card transaction is the source of truth: amount, currency, date, merchant, card and payment method never change.
/// Scalar fields are filled only where the target is empty. Participants and VAT specification lines are added only to a
/// target that has none. Itemization is added to the line when it has none, and to the expense only when its category
/// requires itemization. Expense policies flag any data that does not fit.
/// Only a missing receipt can be applied. The expense keeps its original status, and subsequent attachment changes follow
/// the normal expense status and expense report restrictions.
/// </summary>
codeunit 7450 "EA Card Receipt Data Apply"
{
    Access = Internal;

    var
        ExpenseNotFoundErr: Label 'Expense %1 was not found.', Comment = '%1 = Expense system ID';
        NotCardExpenseErr: Label 'Receipt data can only be applied to expense %1 when it was created from a corporate card transaction.', Comment = '%1 = Expense No.';
        NotWaitingForReceiptErr: Label 'Expense %1 is not waiting for a receipt. It must be open or released and not on an expense report, or on an open expense report with no receipt on its line.', Comment = '%1 = Expense No.';
        ReceiptAlreadyAttachedErr: Label 'Expense %1 already has a receipt.', Comment = '%1 = Expense No.';
        ReceiptRequiredErr: Label 'Upload the receipt file and its file name before you apply the receipt data.';
        ReportLineNotFoundErr: Label 'No line for expense %1 was found on expense report %2.', Comment = '%1 = Expense No., %2 = Expense Report No.';

    /// <summary>
    /// Checks that receipt data can be staged for the expense and returns the expense.
    /// </summary>
    internal procedure GetCardExpense(ExpenseSystemId: Guid; var Expense: Record Expense)
    var
        ReceiptExpenseMatch: Codeunit "EA Receipt Expense Match";
    begin
        if not Expense.GetBySystemId(ExpenseSystemId) then
            Error(ExpenseNotFoundErr, ExpenseSystemId);
        if (Expense.Source <> Expense.Source::CorporateCard) or (Expense."Credit Card Feed No." = 0) then
            Error(NotCardExpenseErr, Expense."No.");

        if not ReceiptExpenseMatch.IsWaitingForReceipt(Expense) then
            Error(NotWaitingForReceiptErr, Expense."No.");
        if Expense."Receipt Attached" then
            Error(ReceiptAlreadyAttachedErr, Expense."No.");
    end;

    /// <summary>
    /// Applies the missing receipt and its data to the expense and its expense report line, preserves the expense status,
    /// then deletes the receipt data.
    /// </summary>
    internal procedure Apply(var CardReceiptData: Record "EA Card Receipt Data")
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        DocumentAttachment: Record "Document Attachment";
        TempExpenseParticipant: Record "Expense Participant" temporary;
        TempExpenseReportLineParticip: Record "Expense Report Line Particip." temporary;
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseVATLineNos: Dictionary of [Integer, Integer];
        OriginalStatus: Enum "Expense Status";
        OnReport: Boolean;
    begin
        GetCardExpense(CardReceiptData."Expense SystemId", Expense);
        CardReceiptData.CalcFields("Attachment Content");
        if (CardReceiptData."File Name" = '') or (not CardReceiptData."Attachment Content".HasValue()) then
            Error(ReceiptRequiredErr);

        OnReport := Expense."Expense Report No." <> '';
        if OnReport then
            FindReportLine(Expense, ExpenseReportLine);

        // A card expense on a report is Submitted. Reopen it inside this transaction so the expense validations accept the receipt data.
        OriginalStatus := Expense.Status;
        if OriginalStatus <> Expense.Status::Open then
            SetExpenseStatus(Expense, Expense.Status::Open);

        AttachReceiptToExpense(CardReceiptData, Expense, DocumentAttachment);
        Expense.Get(Expense."No.");
        SaveExpenseParticipants(Expense, TempExpenseParticipant);
        FillExpenseFields(CardReceiptData, Expense);
        Expense.Modify(true);
        RestoreExpenseParticipants(Expense, TempExpenseParticipant);
        if TempExpenseParticipant.IsEmpty() then
            AddExpenseParticipants(CardReceiptData, Expense);
        AddExpenseItemization(CardReceiptData, Expense);
        AddExpenseVATSpecs(CardReceiptData, Expense, ExpenseVATLineNos);
        Expense.Get(Expense."No.");
        Expense.ApplyRule(false, true);

        if OnReport then begin
            CopyReceiptToReportLine(DocumentAttachment, ExpenseReportLine);
            ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
            SaveReportLineParticipants(ExpenseReportLine, TempExpenseReportLineParticip);
            FillReportLineFields(CardReceiptData, ExpenseReportLine);
            ExpenseReportLine.Modify(true);
            RestoreReportLineParticipants(ExpenseReportLine, TempExpenseReportLineParticip);
            if TempExpenseReportLineParticip.IsEmpty() then
                AddReportLineParticipants(CardReceiptData, ExpenseReportLine);
            AddReportLineItemization(CardReceiptData, ExpenseReportLine);
            AddReportLineVATSpecs(CardReceiptData, ExpenseReportLine, ExpenseVATLineNos);
            ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
            ExpenseReportLine.ApplyRule(false, true);
        end;

        // A released expense goes back through the release checks, so receipt data can't leave it in a state release would reject.
        if OriginalStatus = Expense.Status::Released then begin
            Expense.Get(Expense."No.");
            ReleaseExpenseDocument.ReleaseCardExpenseWithoutCategory(Expense);
        end else
            if OriginalStatus <> Expense.Status::Open then begin
                Expense.Get(Expense."No.");
                SetExpenseStatus(Expense, OriginalStatus);
            end;

        CardReceiptData.Delete(true);
    end;

    local procedure FindReportLine(Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line")
    begin
        ExpenseReportLine.SetRange("Document No.", Expense."Expense Report No.");
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        if not ExpenseReportLine.FindFirst() then
            Error(ReportLineNotFoundErr, Expense."No.", Expense."Expense Report No.");
        ExpenseReportLine.TestStatusOpen();
    end;

    local procedure SetExpenseStatus(var Expense: Record Expense; NewStatus: Enum "Expense Status")
    begin
        Expense.Status := NewStatus;
        Expense.Modify(false);
    end;

    // Imports the content directly instead of through ImportFromStream, because the attachment restriction on that
    // event blocks expenses that are on an expense report.
    local procedure AttachReceiptToExpense(var CardReceiptData: Record "EA Card Receipt Data"; Expense: Record Expense; var DocumentAttachment: Record "Document Attachment")
    var
        FileManagement: Codeunit "File Management";
        ContentInStream: InStream;
    begin
        DocumentAttachment.Init();
        DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Expense;
        DocumentAttachment."Table ID" := Database::Expense;
        DocumentAttachment."No." := Expense."No.";
        DocumentAttachment."Line No." := 0;
        DocumentAttachment.Validate("File Extension", CopyStr(FileManagement.GetExtension(CardReceiptData."File Name"), 1, MaxStrLen(DocumentAttachment."File Extension")));
        DocumentAttachment.Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(CardReceiptData."File Name"), 1, MaxStrLen(DocumentAttachment."File Name")));
        CardReceiptData."Attachment Content".CreateInStream(ContentInStream);
        DocumentAttachment."Document Reference ID".ImportStream(ContentInStream, '', '', CardReceiptData."File Name");
        DocumentAttachment.Insert(true);
    end;

    // The line attachment shares the media of the expense attachment, like Document Attachment Mgmt.CopyAttachments.
    local procedure CopyReceiptToReportLine(ExpenseDocumentAttachment: Record "Document Attachment"; ExpenseReportLine: Record "Expense Report Line")
    var
        LineDocumentAttachment: Record "Document Attachment";
    begin
        ExpenseDocumentAttachment.Get(ExpenseDocumentAttachment."Table ID", ExpenseDocumentAttachment."No.", ExpenseDocumentAttachment."Document Type", ExpenseDocumentAttachment."Line No.", ExpenseDocumentAttachment.ID);
        LineDocumentAttachment.Init();
        LineDocumentAttachment.TransferFields(ExpenseDocumentAttachment);
        LineDocumentAttachment."Table ID" := Database::"Expense Report Line";
        LineDocumentAttachment."No." := ExpenseReportLine."Document No.";
        LineDocumentAttachment."Line No." := ExpenseReportLine."Line No.";
        LineDocumentAttachment.Insert(true);
    end;

    local procedure FillExpenseFields(CardReceiptData: Record "EA Card Receipt Data"; var Expense: Record Expense)
    begin
        if (Expense."Expense Category" = '') and (CardReceiptData."Expense Category" <> '') then
            Expense.Validate("Expense Category", CardReceiptData."Expense Category");
        if (Expense.Description = '') and (CardReceiptData.Description <> '') then
            Expense.Validate(Description, CardReceiptData.Description);
        if (Expense.Justification = '') and (CardReceiptData.Justification <> '') then
            Expense.Validate(Justification, CardReceiptData.Justification);
        if (Expense."Expense Ext. Doc. No." = '') and (CardReceiptData."Expense Ext. Doc. No." <> '') then
            Expense.Validate("Expense Ext. Doc. No.", CardReceiptData."Expense Ext. Doc. No.");
        if (Expense."Merchant Registration No." = '') and (CardReceiptData."Merchant Registration No." <> '') then
            Expense.Validate("Merchant Registration No.", CardReceiptData."Merchant Registration No.");
        if (Expense."Merchant VAT Registration No." = '') and (CardReceiptData."Merchant VAT Registration No." <> '') then
            Expense.Validate("Merchant VAT Registration No.", CardReceiptData."Merchant VAT Registration No.");
    end;

    local procedure FillReportLineFields(CardReceiptData: Record "EA Card Receipt Data"; var ExpenseReportLine: Record "Expense Report Line")
    begin
        if (ExpenseReportLine."Expense Category" = '') and (CardReceiptData."Expense Category" <> '') then
            ExpenseReportLine.Validate("Expense Category", CardReceiptData."Expense Category");
        if (ExpenseReportLine.Description = '') and (CardReceiptData.Description <> '') then
            ExpenseReportLine.Validate(Description, CardReceiptData.Description);
        if (ExpenseReportLine.Justification = '') and (CardReceiptData.Justification <> '') then
            ExpenseReportLine.Validate(Justification, CardReceiptData.Justification);
        if (ExpenseReportLine."Expense Ext. Doc. No." = '') and (CardReceiptData."Expense Ext. Doc. No." <> '') then
            ExpenseReportLine.Validate("Expense Ext. Doc. No.", CardReceiptData."Expense Ext. Doc. No.");
        if (ExpenseReportLine."Merchant Registration No." = '') and (CardReceiptData."Merchant Registration No." <> '') then
            ExpenseReportLine.Validate("Merchant Registration No.", CardReceiptData."Merchant Registration No.");
        if (ExpenseReportLine."Merchant VAT Registration No." = '') and (CardReceiptData."Merchant VAT Registration No." <> '') then
            ExpenseReportLine.Validate("Merchant VAT Registration No.", CardReceiptData."Merchant VAT Registration No.");
    end;

    // Filling a missing category deletes the participants through the category validation. When the new category uses
    // participants, the ones the user already entered are put back. Otherwise they stay removed, like on a manual category
    // change. The receipt only adds participants where the user had none.
    local procedure SaveExpenseParticipants(Expense: Record Expense; var TempExpenseParticipant: Record "Expense Participant" temporary)
    var
        ExpenseParticipant: Record "Expense Participant";
    begin
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        if ExpenseParticipant.FindSet() then
            repeat
                TempExpenseParticipant := ExpenseParticipant;
                TempExpenseParticipant.Insert();
            until ExpenseParticipant.Next() = 0;
    end;

    local procedure RestoreExpenseParticipants(Expense: Record Expense; var TempExpenseParticipant: Record "Expense Participant" temporary)
    var
        ExpenseParticipant: Record "Expense Participant";
    begin
        if Expense."Expense Detail Required" <> Expense."Expense Detail Required"::Participants then
            exit;
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        if not ExpenseParticipant.IsEmpty() then
            exit;
        if TempExpenseParticipant.FindSet() then
            repeat
                ExpenseParticipant := TempExpenseParticipant;
                ExpenseParticipant."Expense Category Code" := Expense."Expense Category";
                ExpenseParticipant."Expense Subcategory Code" := Expense."Expense Subcategory";
                ExpenseParticipant.Insert(true);
            until TempExpenseParticipant.Next() = 0;
    end;

    local procedure SaveReportLineParticipants(ExpenseReportLine: Record "Expense Report Line"; var TempExpenseReportLineParticip: Record "Expense Report Line Particip." temporary)
    var
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
    begin
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLineParticip.FindSet() then
            repeat
                TempExpenseReportLineParticip := ExpenseReportLineParticip;
                TempExpenseReportLineParticip.Insert();
            until ExpenseReportLineParticip.Next() = 0;
    end;

    local procedure RestoreReportLineParticipants(ExpenseReportLine: Record "Expense Report Line"; var TempExpenseReportLineParticip: Record "Expense Report Line Particip." temporary)
    var
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
    begin
        if ExpenseReportLine."Expense Detail Required" <> ExpenseReportLine."Expense Detail Required"::Participants then
            exit;
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineParticip.IsEmpty() then
            exit;
        if TempExpenseReportLineParticip.FindSet() then
            repeat
                ExpenseReportLineParticip := TempExpenseReportLineParticip;
                ExpenseReportLineParticip."Expense Subcategory Code" := ExpenseReportLine."Expense Subcategory Code";
                ExpenseReportLineParticip.Insert(true);
            until TempExpenseReportLineParticip.Next() = 0;
    end;

    local procedure AddExpenseParticipants(CardReceiptData: Record "EA Card Receipt Data"; Expense: Record Expense)
    var
        CardReceiptParticipant: Record "EA Card Receipt Participant";
        ExpenseParticipant: Record "Expense Participant";
        LineNo: Integer;
    begin
        if Expense."Expense Detail Required" <> Expense."Expense Detail Required"::Participants then
            exit;
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        if not ExpenseParticipant.IsEmpty() then
            exit;
        CardReceiptParticipant.SetRange("Receipt Data Id", CardReceiptData.Id);
        if not CardReceiptParticipant.FindSet() then
            exit;
        repeat
            LineNo += 10000;
            ExpenseParticipant.Init();
            ExpenseParticipant."Expense No." := Expense."No.";
            ExpenseParticipant."Line No." := LineNo;
            ExpenseParticipant."Expense Category Code" := Expense."Expense Category";
            ExpenseParticipant."Expense Subcategory Code" := Expense."Expense Subcategory";
            ExpenseParticipant."Participant Type" := CardReceiptParticipant."Participant Type";
            ExpenseParticipant."Participant Employee No." := CardReceiptParticipant."Participant Employee No.";
            ExpenseParticipant."Participant Name" := CardReceiptParticipant."Participant Name";
            ExpenseParticipant."Participant Organization" := CardReceiptParticipant."Participant Organization";
            ExpenseParticipant."Participant Email" := CardReceiptParticipant."Participant Email";
            ExpenseParticipant.Insert(true);
        until CardReceiptParticipant.Next() = 0;
    end;

    local procedure AddReportLineParticipants(CardReceiptData: Record "EA Card Receipt Data"; ExpenseReportLine: Record "Expense Report Line")
    var
        CardReceiptParticipant: Record "EA Card Receipt Participant";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        LineNo: Integer;
    begin
        if ExpenseReportLine."Expense Detail Required" <> ExpenseReportLine."Expense Detail Required"::Participants then
            exit;
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineParticip.IsEmpty() then
            exit;
        CardReceiptParticipant.SetRange("Receipt Data Id", CardReceiptData.Id);
        if not CardReceiptParticipant.FindSet() then
            exit;
        repeat
            LineNo += 10000;
            ExpenseReportLineParticip.Init();
            ExpenseReportLineParticip."Expense Report No." := ExpenseReportLine."Document No.";
            ExpenseReportLineParticip."Expense Report Line No." := ExpenseReportLine."Line No.";
            ExpenseReportLineParticip."Line No." := LineNo;
            ExpenseReportLineParticip."Expense Subcategory Code" := ExpenseReportLine."Expense Subcategory Code";
            ExpenseReportLineParticip."Participant Type" := CardReceiptParticipant."Participant Type";
            ExpenseReportLineParticip."Participant Employee No." := CardReceiptParticipant."Participant Employee No.";
            ExpenseReportLineParticip."Participant Name" := CardReceiptParticipant."Participant Name";
            ExpenseReportLineParticip."Participant Organization" := CardReceiptParticipant."Participant Organization";
            ExpenseReportLineParticip."Participant Email" := CardReceiptParticipant."Participant Email";
            ExpenseReportLineParticip.Insert(true);
        until CardReceiptParticipant.Next() = 0;
    end;

    // Expense itemization is only allowed when the expense category requires it.
    local procedure AddExpenseItemization(CardReceiptData: Record "EA Card Receipt Data"; Expense: Record Expense)
    var
        CardReceiptItem: Record "EA Card Receipt Item";
        ExpenseItemization: Record "Expense Itemization";
        LineNo: Integer;
    begin
        if not Expense.IsItemizationRequired() then
            exit;
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        if not ExpenseItemization.IsEmpty() then
            exit;
        CardReceiptItem.SetRange("Receipt Data Id", CardReceiptData.Id);
        if not CardReceiptItem.FindSet() then
            exit;
        repeat
            LineNo += 10000;
            ExpenseItemization.Init();
            ExpenseItemization."Expense No." := Expense."No.";
            ExpenseItemization."Line No." := LineNo;
            ExpenseItemization."Expense Category Code" := Expense."Expense Category";
            ExpenseItemization."Currency Code" := Expense."Currency Code";
            if CardReceiptItem."Expense Subcategory Code" <> '' then
                ExpenseItemization.Validate("Expense Subcategory Code", CardReceiptItem."Expense Subcategory Code");
            if CardReceiptItem.Description <> '' then
                ExpenseItemization.Validate(Description, CardReceiptItem.Description);
            ExpenseItemization.Validate("Start Date", CardReceiptItem."Start Date");
            ExpenseItemization.Quantity := CardReceiptItem.Quantity;
            if CardReceiptItem."Daily Rate" <> 0 then
                ExpenseItemization.Validate("Daily Rate", CardReceiptItem."Daily Rate");
            ExpenseItemization.Insert(true);
        until CardReceiptItem.Next() = 0;
    end;

    // A line itemization needs a category on the line, so nothing is added while the line has none.
    local procedure AddReportLineItemization(CardReceiptData: Record "EA Card Receipt Data"; ExpenseReportLine: Record "Expense Report Line")
    var
        CardReceiptItem: Record "EA Card Receipt Item";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        LineNo: Integer;
    begin
        if ExpenseReportLine."Expense Category" = '' then
            exit;
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineItem.IsEmpty() then
            exit;
        CardReceiptItem.SetRange("Receipt Data Id", CardReceiptData.Id);
        if not CardReceiptItem.FindSet() then
            exit;
        repeat
            LineNo += 10000;
            ExpenseReportLineItem.Init();
            ExpenseReportLineItem."Expense Report No." := ExpenseReportLine."Document No.";
            ExpenseReportLineItem."Expense Report Line No." := ExpenseReportLine."Line No.";
            ExpenseReportLineItem."Line No." := LineNo;
            ExpenseReportLineItem."Expense Category Code" := ExpenseReportLine."Expense Category";
            ExpenseReportLineItem."Currency Code" := ExpenseReportLine."Expense Currency Code";
            if CardReceiptItem."Expense Subcategory Code" <> '' then
                ExpenseReportLineItem.Validate("Expense Subcategory Code", CardReceiptItem."Expense Subcategory Code");
            if CardReceiptItem.Description <> '' then
                ExpenseReportLineItem.Validate(Description, CardReceiptItem.Description);
            ExpenseReportLineItem.Validate("Start Date", CardReceiptItem."Start Date");
            ExpenseReportLineItem.Quantity := CardReceiptItem.Quantity;
            if CardReceiptItem."Daily Rate" <> 0 then
                ExpenseReportLineItem.Validate("Daily Rate", CardReceiptItem."Daily Rate");
            ExpenseReportLineItem.Insert(true);
        until CardReceiptItem.Next() = 0;
    end;

    local procedure AddExpenseVATSpecs(CardReceiptData: Record "EA Card Receipt Data"; Expense: Record Expense; var ExpenseVATLineNos: Dictionary of [Integer, Integer])
    var
        CardReceiptVATSpec: Record "EA Card Receipt VAT Spec.";
        ExpenseVATSpecification: Record "Expense VAT Specification";
    begin
        ExpenseVATSpecification.SetRange("Expense No.", Expense."No.");
        if not ExpenseVATSpecification.IsEmpty() then
            exit;
        CardReceiptVATSpec.SetRange("Receipt Data Id", CardReceiptData.Id);
        if not CardReceiptVATSpec.FindSet() then
            exit;
        repeat
            ExpenseVATSpecification.Init();
            ExpenseVATSpecification."Expense No." := Expense."No.";
            ExpenseVATSpecification."Line No." := 0;
            ExpenseVATSpecification.Source := ExpenseVATSpecification.Source::Agent;
            ExpenseVATSpecification."Expense Category" := Expense."Expense Category";
            ExpenseVATSpecification."Expense Subcategory" := Expense."Expense Subcategory";
            ExpenseVATSpecification."VAT %" := CardReceiptVATSpec."VAT %";
            ExpenseVATSpecification."VAT Base Amount" := CardReceiptVATSpec."VAT Base Amount";
            ExpenseVATSpecification."VAT Amount" := CardReceiptVATSpec."VAT Amount";
            ExpenseVATSpecification.Amount := CardReceiptVATSpec.Amount;
            ExpenseVATSpecification."VAT Amount (LCY)" := GetAmountLCY(CardReceiptVATSpec."VAT Amount", Expense."Currency Code", Expense."Currency Factor");
            ExpenseVATSpecification."VAT Base Amount (LCY)" := GetAmountLCY(CardReceiptVATSpec."VAT Base Amount", Expense."Currency Code", Expense."Currency Factor");
            ExpenseVATSpecification."Amount (LCY)" := GetAmountLCY(CardReceiptVATSpec.Amount, Expense."Currency Code", Expense."Currency Factor");
            ExpenseVATSpecification.Insert(true);
            ExpenseVATLineNos.Add(CardReceiptVATSpec."Line No.", ExpenseVATSpecification."Line No.");
        until CardReceiptVATSpec.Next() = 0;
    end;

    // Mirrors Create Expense Report.CopyVATSpecsToReportLine.
    local procedure AddReportLineVATSpecs(CardReceiptData: Record "EA Card Receipt Data"; ExpenseReportLine: Record "Expense Report Line"; ExpenseVATLineNos: Dictionary of [Integer, Integer])
    var
        CardReceiptVATSpec: Record "EA Card Receipt VAT Spec.";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        LineNo: Integer;
        SourceLineNo: Integer;
    begin
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportLine."Document No.");
        ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineVATSpec.IsEmpty() then
            exit;
        CardReceiptVATSpec.SetRange("Receipt Data Id", CardReceiptData.Id);
        if not CardReceiptVATSpec.FindSet() then
            exit;
        repeat
            LineNo += 1;
            SourceLineNo := 0;
            if ExpenseVATLineNos.Get(CardReceiptVATSpec."Line No.", SourceLineNo) then;
            ExpenseReportLineVATSpec.Init();
            ExpenseReportLineVATSpec."Document No." := ExpenseReportLine."Document No.";
            ExpenseReportLineVATSpec."Document Line No." := ExpenseReportLine."Line No.";
            ExpenseReportLineVATSpec."Line No." := LineNo;
            ExpenseReportLineVATSpec."Expense Category" := ExpenseReportLine."Expense Category";
            ExpenseReportLineVATSpec."Expense Subcategory" := ExpenseReportLine."Expense Subcategory Code";
            ExpenseReportLineVATSpec."VAT %" := CardReceiptVATSpec."VAT %";
            ExpenseReportLineVATSpec."VAT Base Amount" := CardReceiptVATSpec."VAT Base Amount";
            ExpenseReportLineVATSpec."VAT Amount" := CardReceiptVATSpec."VAT Amount";
            ExpenseReportLineVATSpec.Amount := CardReceiptVATSpec.Amount;
            ExpenseReportLineVATSpec."Currency Code" := ExpenseReportLine."Expense Currency Code";
            ExpenseReportLineVATSpec."Currency Factor" := ExpenseReportLine."Expense Currency Factor";
            ExpenseReportLineVATSpec."VAT Amount (LCY)" := GetAmountLCY(CardReceiptVATSpec."VAT Amount", ExpenseReportLine."Expense Currency Code", ExpenseReportLine."Expense Currency Factor");
            ExpenseReportLineVATSpec."VAT Base Amount (LCY)" := GetAmountLCY(CardReceiptVATSpec."VAT Base Amount", ExpenseReportLine."Expense Currency Code", ExpenseReportLine."Expense Currency Factor");
            ExpenseReportLineVATSpec."Amount (LCY)" := GetAmountLCY(CardReceiptVATSpec.Amount, ExpenseReportLine."Expense Currency Code", ExpenseReportLine."Expense Currency Factor");
            ExpenseReportLineVATSpec.Source := ExpenseReportLineVATSpec.Source::Agent;
            ExpenseReportLineVATSpec."Source Spec Line No." := SourceLineNo;
            if ExpenseSubcategory.Get(ExpenseReportLine."Expense Category", ExpenseReportLine."Expense Subcategory Code") then
                ExpenseReportLineVATSpec.Validate("Reclaim %", ExpenseSubcategory."Default VAT Reclaim %")
            else
                if ExpenseCategory.Get(ExpenseReportLine."Expense Category") then
                    ExpenseReportLineVATSpec.Validate("Reclaim %", ExpenseCategory."Default VAT Reclaim %");
            ExpenseReportLineVATSpec.UpdateReimbursementAmounts();
            ExpenseReportLineVATSpec.Insert();
        until CardReceiptVATSpec.Next() = 0;

        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLine."VAT Liable" then begin
            ExpenseReportLine."VAT Liable" := true;
            ExpenseReportLine.Modify();
        end;
    end;

    local procedure GetAmountLCY(Amount: Decimal; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    begin
        if CurrencyCode = '' then
            exit(Amount);
        if CurrencyFactor = 0 then
            exit(0);
        exit(Round(Amount / CurrencyFactor));
    end;
}
