// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50120 "Report Filename Total Plh." implements "Report Filename Placeholder"
{
    Access = Internal;

    // Section 10 of the design lists this as one of the four capabilities reminders need from
    // the generic model, and it is the one that is not a field: Base Application computes a
    // reminder's total in code rather than storing it. That is why computed values are an
    // interface - a value that has to be worked out per document type has somewhere to live.

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
        // The only computed value that depends on the kind of document, and the reason this
        // method is on the interface at all. A pattern naming a customer or an item has no
        // document total, so TryResolve would decline and take the whole pattern down with it.
        // Asked here instead, the picker simply does not offer it.
        if TableNo = 0 then
            exit(false);

        exit(HasTotalSource(TableNo));
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // Three invoices have three totals and no one of them is the run's. Summing them
        // would invent a figure that appears on no document, so the placeholder declines instead
        // and the picker says so rather than letting the administrator find out later.
        exit(false);
    end;

    procedure ExampleWithoutDocument(): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // The one computed value that needs a document, so the picker cannot resolve it for
        // real and would otherwise leave the row blank. A total is a decimal, and the shape of
        // a decimal is the same one a Decimal field shows.
        exit(ReportFilenameMgt.SampleDecimalText());
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        DocumentRecRefCopy: RecordRef;
        Total: Decimal;
    begin
        // A run covering several documents has no single total, and inventing one would name a
        // batch after an amount that appears on none of its documents. The placeholder declines, and
        // the pattern with it, which is the same rule every other placeholder follows.
        if not TryFindExactlyOne(DocumentRecRef, DocumentRecRefCopy) then
            exit(false);

        if not TryGetTotal(DocumentRecRefCopy, Total) then
            exit(false);

        PlaceholderValue := ReportFilenameMgt.FormatPatternDecimal(Total, DocumentRecRefCopy);
        exit(PlaceholderValue <> '');
    end;

    /// <summary>
    /// Positions on the one document being named, and refuses when the run covers more than
    /// one.
    /// </summary>
    local procedure TryFindExactlyOne(var DocumentRecRef: RecordRef; var SingleRecRef: RecordRef): Boolean
    begin
        // Duplicating is itself guarded. There is no document at all when the picker asks what
        // this value would look like, and Duplicate on a record that was never opened raises
        // "The record is not open" rather than returning anything - so without this the placeholder
        // brought down whatever asked it, instead of declining like every other placeholder.
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

    /// <summary>
    /// The document's total including VAT. Reminders are computed, because that is how Base
    /// Application defines a reminder's total; every other document is read from the field
    /// that holds it. A document type that has neither declines rather than guessing.
    /// </summary>
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

        // The amount is a FlowField on the posted sales and purchase documents, so it holds
        // nothing until it is calculated.
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

    /// <summary>
    /// Whether a total can be worked out for a kind of document at all. Asked by the picker
    /// before the placeholder is offered and by the resolver before it is used, so the two can never
    /// disagree about which documents have a total.
    /// </summary>
    /// <param name="SourceTableNo">The table the pattern names documents from.</param>
    /// <returns>True when this kind of document has a total including VAT.</returns>
    local procedure HasTotalSource(SourceTableNo: Integer): Boolean
    var
        FieldRec: Record Field;
    begin
        // Reminders are the computed case: Base Application works a reminder's total out in
        // code rather than storing it, which is why this placeholder exists as an interface at all.
        if SourceTableNo = Database::"Issued Reminder Header" then
            exit(true);

        exit(FindTotalField(SourceTableNo, FieldRec));
    end;

    /// <summary>
    /// Finds the field holding the document total including VAT, by its language-invariant AL
    /// name - the caption is translated, and a pattern must resolve the same way in every
    /// language.
    /// </summary>
    /// <param name="SourceTableNo">The table to look on.</param>
    /// <param name="FieldRec">Receives the field when there is one.</param>
    /// <returns>True when the table has that field.</returns>
    /// <remarks>
    /// The same filter decides both whether the placeholder is offered and what it reads, so the picker
    /// cannot offer it where it would then decline. The guards are the ones the picker applies
    /// everywhere else: an obsolete, non-public or FlowFilter field is not a value a file name may
    /// be built from, and matching one would produce a wrong total rather than no total.
    /// </remarks>
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
