// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;

codeunit 6916 "Exp. Report Change Log Mgt."
{
    Access = Internal;
    Permissions = tabledata "Exp. Report Change Log Entry" = rimd,
                  tabledata "Dimension Set Entry" = r;

    var
        DimensionsLbl: Label 'Dimensions';
        DimensionValueTok: Label '%1: %2', Locked = true;
        DimensionSeparatorTok: Label '; ', Locked = true;

    local procedure HasLineChanges(OldExpenseReportLine: Record "Expense Report Line"; NewExpenseReportLine: Record "Expense Report Line"): Boolean
    begin
        exit(
            (OldExpenseReportLine."Dimension Set ID" <> NewExpenseReportLine."Dimension Set ID") or
            (OldExpenseReportLine."Account Type" <> NewExpenseReportLine."Account Type") or
            (OldExpenseReportLine."Account No." <> NewExpenseReportLine."Account No.") or
            (OldExpenseReportLine.Billable <> NewExpenseReportLine.Billable) or
            (OldExpenseReportLine."Billable to Customer" <> NewExpenseReportLine."Billable to Customer") or
            (OldExpenseReportLine."Purchase Invoice" <> NewExpenseReportLine."Purchase Invoice") or
            (OldExpenseReportLine."Vendor No." <> NewExpenseReportLine."Vendor No.") or
            (OldExpenseReportLine."Posted Purch. Invoice No." <> NewExpenseReportLine."Posted Purch. Invoice No.") or
            (OldExpenseReportLine."Merchant Name" <> NewExpenseReportLine."Merchant Name") or
            (OldExpenseReportLine."Merchant VAT Registration No." <> NewExpenseReportLine."Merchant VAT Registration No.") or
            (OldExpenseReportLine."Job No." <> NewExpenseReportLine."Job No.") or
            (OldExpenseReportLine."Job Task No." <> NewExpenseReportLine."Job Task No.") or
            (OldExpenseReportLine."VAT Liable" <> NewExpenseReportLine."VAT Liable"));
    end;

    /// <summary>
    /// Records the accounting fields that changed on an expense report line after the report left the Open status.
    /// </summary>
    internal procedure LogLineChanges(OldExpenseReportLine: Record "Expense Report Line"; NewExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        if NewExpenseReportLine.IsTemporary() then
            exit;

        if not HasLineChanges(OldExpenseReportLine, NewExpenseReportLine) then
            exit;

        ExpenseReportHeader.SetLoadFields(Status);
        ExpenseReportHeader.Get(NewExpenseReportLine."Document No.");
        if not IsChangeTrackingRequired(ExpenseReportHeader) then
            exit;

        if OldExpenseReportLine."Dimension Set ID" <> NewExpenseReportLine."Dimension Set ID" then
            InsertEntry(
                ExpenseReportHeader, NewExpenseReportLine."Line No.", NewExpenseReportLine."Expense No.", Database::"Expense Report Line",
                NewExpenseReportLine.FieldNo("Dimension Set ID"), DimensionsLbl,
                GetDimensionSetText(OldExpenseReportLine."Dimension Set ID"), GetDimensionSetText(NewExpenseReportLine."Dimension Set ID"));

        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Account Type"), Format(OldExpenseReportLine."Account Type"), Format(NewExpenseReportLine."Account Type"));
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Account No."), OldExpenseReportLine."Account No.", NewExpenseReportLine."Account No.");
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo(Billable), Format(OldExpenseReportLine.Billable), Format(NewExpenseReportLine.Billable));
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Billable to Customer"), OldExpenseReportLine."Billable to Customer", NewExpenseReportLine."Billable to Customer");
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Purchase Invoice"), Format(OldExpenseReportLine."Purchase Invoice"), Format(NewExpenseReportLine."Purchase Invoice"));
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Vendor No."), OldExpenseReportLine."Vendor No.", NewExpenseReportLine."Vendor No.");
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Posted Purch. Invoice No."), OldExpenseReportLine."Posted Purch. Invoice No.", NewExpenseReportLine."Posted Purch. Invoice No.");
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Merchant Name"), OldExpenseReportLine."Merchant Name", NewExpenseReportLine."Merchant Name");
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Merchant VAT Registration No."), OldExpenseReportLine."Merchant VAT Registration No.", NewExpenseReportLine."Merchant VAT Registration No.");
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Job No."), OldExpenseReportLine."Job No.", NewExpenseReportLine."Job No.");
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("Job Task No."), OldExpenseReportLine."Job Task No.", NewExpenseReportLine."Job Task No.");
        LogLineFieldChange(ExpenseReportHeader, NewExpenseReportLine, NewExpenseReportLine.FieldNo("VAT Liable"), Format(OldExpenseReportLine."VAT Liable"), Format(NewExpenseReportLine."VAT Liable"));
    end;

    /// <summary>
    /// Records a change of the header dimensions after the report left the Open status.
    /// </summary>
    internal procedure LogHeaderDimensionChange(ExpenseReportHeader: Record "Expense Report Header"; OldDimensionSetID: Integer)
    begin
        if OldDimensionSetID = ExpenseReportHeader."Dimension Set ID" then
            exit;
        if not IsChangeTrackingRequired(ExpenseReportHeader) then
            exit;

        InsertEntry(
            ExpenseReportHeader, 0, '', Database::"Expense Report Header", ExpenseReportHeader.FieldNo("Dimension Set ID"), DimensionsLbl,
            GetDimensionSetText(OldDimensionSetID), GetDimensionSetText(ExpenseReportHeader."Dimension Set ID"));
    end;

    /// <summary>
    /// Moves the change history of an expense report to the posted expense report created from it.
    /// </summary>
    internal procedure ReassignEntriesToPosted(ExpenseReportHeader: Record "Expense Report Header"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        // Both updates run in the posting transaction, so no entry is left with only one of the two source fields changed.
        SetSourceFilter(ExpReportChangeLogEntry, Database::"Expense Report Header", ExpenseReportHeader.SystemId);
        if ExpReportChangeLogEntry.IsEmpty() then
            exit;
        ExpReportChangeLogEntry.ModifyAll("Source Record System ID", PostedExpenseReportHeader.SystemId, false);

        ExpReportChangeLogEntry.SetRange("Source Record System ID", PostedExpenseReportHeader.SystemId);
        ExpReportChangeLogEntry.ModifyAll("Source Table ID", Database::"Posted Expense Report Header", false);
    end;

    /// <summary>
    /// Deletes the change history of the specified expense report or posted expense report.
    /// </summary>
    internal procedure DeleteEntriesForSource(SourceTableID: Integer; SourceRecordSystemID: Guid)
    var
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        SetSourceFilter(ExpReportChangeLogEntry, SourceTableID, SourceRecordSystemID);
        if not ExpReportChangeLogEntry.IsEmpty() then
            ExpReportChangeLogEntry.DeleteAll();
    end;

    /// <summary>
    /// Deletes the change history of the specified expense report line.
    /// </summary>
    internal procedure DeleteEntriesForLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        if ExpenseReportLine.IsTemporary() then
            exit;

        ExpenseReportHeader.SetLoadFields("No.");
        if not ExpenseReportHeader.Get(ExpenseReportLine."Document No.") then
            exit;

        SetSourceFilter(ExpReportChangeLogEntry, Database::"Expense Report Header", ExpenseReportHeader.SystemId);
        ExpReportChangeLogEntry.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        if not ExpReportChangeLogEntry.IsEmpty() then
            ExpReportChangeLogEntry.DeleteAll();
    end;

    internal procedure ShowChangeLog(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        SetSourceFilter(ExpReportChangeLogEntry, Database::"Expense Report Header", ExpenseReportHeader.SystemId);
        Page.Run(Page::"Exp. Report Change Log Entries", ExpReportChangeLogEntry);
    end;

    internal procedure ShowChangeLog(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        ExpenseReportHeader.SetLoadFields("No.");
        ExpenseReportHeader.Get(ExpenseReportLine."Document No.");
        SetSourceFilter(ExpReportChangeLogEntry, Database::"Expense Report Header", ExpenseReportHeader.SystemId);
        ExpReportChangeLogEntry.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        Page.Run(Page::"Exp. Report Change Log Entries", ExpReportChangeLogEntry);
    end;

    internal procedure ShowChangeLog(PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        SetSourceFilter(ExpReportChangeLogEntry, Database::"Posted Expense Report Header", PostedExpenseReportHeader.SystemId);
        Page.Run(Page::"Exp. Report Change Log Entries", ExpReportChangeLogEntry);
    end;

    internal procedure ShowChangeLog(PostedExpenseReportLine: Record "Posted Expense Report Line")
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        PostedExpenseReportHeader.SetLoadFields("No.");
        PostedExpenseReportHeader.Get(PostedExpenseReportLine."Document No.");
        SetSourceFilter(ExpReportChangeLogEntry, Database::"Posted Expense Report Header", PostedExpenseReportHeader.SystemId);
        ExpReportChangeLogEntry.SetRange("Document Line No.", PostedExpenseReportLine."Line No.");
        Page.Run(Page::"Exp. Report Change Log Entries", ExpReportChangeLogEntry);
    end;

    local procedure IsChangeTrackingRequired(ExpenseReportHeader: Record "Expense Report Header"): Boolean
    begin
        if ExpenseReportHeader.IsTemporary() or IsNullGuid(ExpenseReportHeader.SystemId) then
            exit(false);

        // Changes made while the report is open are part of the normal preparation and are not audited.
        exit(ExpenseReportHeader.Status <> ExpenseReportHeader.Status::Open);
    end;

    local procedure LogLineFieldChange(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; FieldNo: Integer; OldValue: Text; NewValue: Text)
    var
        RecordRef: RecordRef;
    begin
        if OldValue = NewValue then
            exit;

        RecordRef.GetTable(ExpenseReportLine);
        InsertEntry(
            ExpenseReportHeader, ExpenseReportLine."Line No.", ExpenseReportLine."Expense No.", Database::"Expense Report Line",
            FieldNo, RecordRef.Field(FieldNo).Caption(), OldValue, NewValue);
    end;

    local procedure InsertEntry(ExpenseReportHeader: Record "Expense Report Header"; DocumentLineNo: Integer; ExpenseNo: Code[20]; TableID: Integer; FieldNo: Integer; FieldCaption: Text; OldValue: Text; NewValue: Text)
    var
        ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry";
    begin
        ExpReportChangeLogEntry."Source Table ID" := Database::"Expense Report Header";
        ExpReportChangeLogEntry."Source Record System ID" := ExpenseReportHeader.SystemId;
        ExpReportChangeLogEntry."Document No." := ExpenseReportHeader."No.";
        ExpReportChangeLogEntry."Document Line No." := DocumentLineNo;
        ExpReportChangeLogEntry."Expense No." := ExpenseNo;
        ExpReportChangeLogEntry."Table ID" := TableID;
        ExpReportChangeLogEntry."Field No." := FieldNo;
        ExpReportChangeLogEntry."Field Caption" := CopyStr(FieldCaption, 1, MaxStrLen(ExpReportChangeLogEntry."Field Caption"));
        ExpReportChangeLogEntry."Old Value" := CopyStr(OldValue, 1, MaxStrLen(ExpReportChangeLogEntry."Old Value"));
        ExpReportChangeLogEntry."New Value" := CopyStr(NewValue, 1, MaxStrLen(ExpReportChangeLogEntry."New Value"));
        ExpReportChangeLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ExpReportChangeLogEntry."User ID"));
        ExpReportChangeLogEntry."Changed At" := CurrentDateTime();
        ExpReportChangeLogEntry.Insert();
    end;

    local procedure SetSourceFilter(var ExpReportChangeLogEntry: Record "Exp. Report Change Log Entry"; SourceTableID: Integer; SourceRecordSystemID: Guid)
    begin
        ExpReportChangeLogEntry.SetRange("Source Table ID", SourceTableID);
        ExpReportChangeLogEntry.SetRange("Source Record System ID", SourceRecordSystemID);
    end;

    local procedure GetDimensionSetText(DimensionSetID: Integer) DimensionSetText: Text
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if DimensionSetID = 0 then
            exit('');

        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetLoadFields("Dimension Code", "Dimension Value Code");
        if DimensionSetEntry.FindSet() then
            repeat
                if DimensionSetText <> '' then
                    DimensionSetText += DimensionSeparatorTok;
                DimensionSetText += StrSubstNo(DimensionValueTok, DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code");
            until DimensionSetEntry.Next() = 0;
    end;
}