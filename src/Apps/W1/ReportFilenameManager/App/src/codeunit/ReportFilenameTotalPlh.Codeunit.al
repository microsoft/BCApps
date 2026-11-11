// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Sales.Reminder;
using System.Reflection;

codeunit 8135 "Report Filename Total Plh." implements "Report Filename Placeholder"
{
    Access = Internal;

    // Computed rather than a field because Base Application computes an issued reminder's total
    // in code instead of storing it.

    procedure CanonicalName(): Text
    begin
        exit(CanonicalTok);
    end;

    procedure DisplayName(): Text
    begin
        exit(DisplayLbl);
    end;

    procedure Description(): Text
    begin
        exit(DescriptionLbl);
    end;

    procedure IsTableSupported(TableNo: Integer): Boolean
    begin
        if TableNo = 0 then
            exit(false);

        exit(HasTotalSource(TableNo));
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // Several documents have several totals; summing them would invent a figure on no document.
        exit(false);
    end;

    procedure ExampleWithoutDocument(): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        exit(ReportFilenameMgt.SampleDecimalText());
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        DocumentRecRefCopy: RecordRef;
        Total: Decimal;
    begin
        if not TryFindExactlyOne(DocumentRecRef, DocumentRecRefCopy) then
            exit(false);

        if not TryGetTotal(DocumentRecRefCopy, Total) then
            exit(false);

        PlaceholderValue := ReportFilenameMgt.FormatPatternDecimal(Total, DocumentRecRefCopy);
        exit(PlaceholderValue <> '');
    end;

    local procedure TryFindExactlyOne(var DocumentRecRef: RecordRef; var SingleRecRef: RecordRef): Boolean
    begin
        // Guarded: the picker passes an unopened RecordRef.
        if not TryDuplicate(DocumentRecRef, SingleRecRef) then
            exit(false);
        if not TryFindFirst(SingleRecRef) then
            exit(false);
        exit(SingleRecRef.Next() = 0);
    end;

    [TryFunction]
    local procedure TryDuplicate(var DocumentRecRef: RecordRef; var SingleRecRef: RecordRef)
    begin
        SingleRecRef := DocumentRecRef.Duplicate();
    end;

    [TryFunction]
    local procedure TryFindFirst(var RecRef: RecordRef)
    begin
        RecRef.FindFirst();
    end;

    local procedure TryGetTotal(var SingleRecRef: RecordRef; var Total: Decimal): Boolean
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        FieldRec: Record Field;
        TotalFieldRef: FieldRef;
    begin
        if SingleRecRef.Number() = Database::"Issued Reminder Header" then begin
            SingleRecRef.SetTable(IssuedReminderHeader);
            Total := IssuedReminderHeader.CalculateTotalIncludingVAT();
            exit(true);
        end;

        if not FindTotalField(SingleRecRef.Number(), FieldRec) then
            exit(false);

        if not TryReadField(SingleRecRef, FieldRec."No.", TotalFieldRef) then
            exit(false);

        // A FlowField on sales and purchase headers, posted and unposted.
        if FieldRec.Class = FieldRec.Class::FlowField then
            TotalFieldRef.CalcField();

        Total := TotalFieldRef.Value();
        exit(true);
    end;

    [TryFunction]
    local procedure TryReadField(var RecRef: RecordRef; FieldNo: Integer; var ResultFieldRef: FieldRef)
    begin
        ResultFieldRef := RecRef.Field(FieldNo);
    end;

    local procedure HasTotalSource(SourceTableNo: Integer): Boolean
    var
        FieldRec: Record Field;
    begin
        if SourceTableNo = Database::"Issued Reminder Header" then
            exit(true);

        exit(FindTotalField(SourceTableNo, FieldRec));
    end;

    /// <summary>
    /// Finds the total field by its AL name, not its translated caption. Used both to offer the
    /// placeholder and to read it, so the two agree on which tables have a total.
    /// </summary>
    local procedure FindTotalField(SourceTableNo: Integer; var FieldRec: Record Field): Boolean
    begin
        FieldRec.Reset();
        FieldRec.SetRange(TableNo, SourceTableNo);
        FieldRec.SetRange(FieldName, AmountIncludingVatTok);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        FieldRec.SetRange(Access, FieldRec.Access::Public);
        FieldRec.SetFilter(Class, '<>%1', FieldRec.Class::FlowFilter);
        exit(FieldRec.FindFirst());
    end;

    var
        CanonicalTok: Label 'Total Incl. VAT', Locked = true;
        AmountIncludingVatTok: Label 'Amount Including VAT', Locked = true;
        DisplayLbl: Label 'Total Incl. VAT';
        DescriptionLbl: Label 'The total including VAT of the record being named, to the number of decimals its currency uses';
}
