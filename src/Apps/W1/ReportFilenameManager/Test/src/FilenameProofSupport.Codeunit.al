// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50162 "Filename Proof Support"
{
    // Shared by the proofs, so that the amount-format reference, the caption lookups and the
    // language switching exist once rather than in two copies that can drift apart.
    //
    // The language handling here is the important part. A proof that authors a pattern with an
    // English caption while the session happens to be Danish does not fail with a wrong name -
    // it fails to save at all, and takes the rest of the run with it. Which language a pattern
    // is authored in has to be a decision, never an accident of who is logged in.

    Access = Internal;

    /// <summary>
    /// Writes one line to Filename Proof Log. Every proof records its findings this way, and it lived
    /// as an identical private copy in six of them before it was moved here.
    /// </summary>
    /// <param name="ItemName">What is being reported. A name beginning RESULT is a verdict.</param>
    /// <param name="ItemValue">What was found.</param>
    internal procedure LogLine(ItemName: Text; ItemValue: Text)
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.LogProofLine(ItemName, ItemValue);
    end;

    internal procedure EnglishLanguageId(): Integer
    begin
        exit(1033);
    end;

    /// <summary>
    /// Limits a pattern to one route, on the record in memory, as the proofs written for a single
    /// Output Route need. Any leaves the pattern for every route.
    /// </summary>
    /// <param name="Pattern">The pattern.</param>
    /// <param name="Route">The route.</param>
    internal procedure LimitToRoute(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route")
    var
        Routes: List of [Integer];
    begin
        if Route <> Route::Any then
            Routes.Add(Route.AsInteger());
        Pattern.SetOutputRoutes(Routes);
    end;

    internal procedure DanishLanguageId(): Integer
    begin
        exit(1030);
    end;

    internal procedure GermanLanguageId(): Integer
    begin
        exit(1031);
    end;

    internal procedure EnglishLanguageCode(): Code[10]
    begin
        exit('ENU');
    end;

    internal procedure DanishLanguageCode(): Code[10]
    begin
        exit('DAN');
    end;

    internal procedure GermanLanguageCode(): Code[10]
    begin
        exit('DEU');
    end;

    /// <summary>
    /// A field's caption as one language has it, without leaving the session in that language.
    /// </summary>
    /// <param name="LanguageId">The language to read in.</param>
    /// <param name="TableNo">The table.</param>
    /// <param name="FieldNo">The field.</param>
    /// <returns>The caption, or an empty string when the field does not exist.</returns>
    internal procedure FieldCaptionIn(LanguageId: Integer; TableNo: Integer; FieldNo: Integer) Caption: Text
    var
        FieldRec: Record Field;
        RestoreLanguage: Integer;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        if FieldRec.Get(TableNo, FieldNo) then
            Caption := FieldRec."Field Caption";
        GlobalLanguage(RestoreLanguage);
    end;

    /// <summary>
    /// A table's caption as one language has it.
    /// </summary>
    internal procedure TableCaptionIn(LanguageId: Integer; TableNo: Integer) Caption: Text
    var
        TableMetadata: Record "Table Metadata";
        RestoreLanguage: Integer;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        if TableMetadata.Get(TableNo) then
            Caption := TableMetadata.Caption;
        GlobalLanguage(RestoreLanguage);
    end;

    /// <summary>
    /// A report's caption as one language has it.
    /// </summary>
    internal procedure ReportCaptionIn(LanguageId: Integer; ReportId: Integer) Caption: Text
    var
        ReportMetadata: Record "Report Metadata";
        RestoreLanguage: Integer;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        if ReportMetadata.Get(ReportId) then
            Caption := ReportMetadata.Caption;
        GlobalLanguage(RestoreLanguage);
    end;

    /// <summary>
    /// A field placeholder as an administrator working in one language would write it - the caption
    /// in that language, in brackets. Composed rather than written down, so a proof that claims
    /// to author in Danish really does, whatever translations happen to be installed.
    /// </summary>
    internal procedure FieldPlaceholderIn(LanguageId: Integer; TableNo: Integer; FieldNo: Integer): Text
    begin
        exit('[' + FieldCaptionIn(LanguageId, TableNo, FieldNo) + ']');
    end;

    /// <summary>
    /// A placeholder reaching one relation away, as that language writes it: the related table's
    /// caption, a full stop, and the field's caption.
    /// </summary>
    internal procedure HopPlaceholderIn(LanguageId: Integer; RelatedTableNo: Integer; RelatedFieldNo: Integer): Text
    begin
        exit('[' + TableCaptionIn(LanguageId, RelatedTableNo) + '.' + FieldCaptionIn(LanguageId, RelatedTableNo, RelatedFieldNo) + ']');
    end;

    /// <summary>
    /// Whether two languages actually say something different here. A cross-language proof
    /// against captions that read the same in both languages passes while proving nothing, so
    /// every such proof asks this first and reports the answer.
    /// </summary>
    internal procedure CaptionsDifferBetweenLanguages(TableNo: Integer; FieldNo: Integer): Boolean
    var
        English: Text;
        Danish: Text;
        German: Text;
    begin
        English := FieldCaptionIn(EnglishLanguageId(), TableNo, FieldNo);
        Danish := FieldCaptionIn(DanishLanguageId(), TableNo, FieldNo);
        German := FieldCaptionIn(GermanLanguageId(), TableNo, FieldNo);
        exit((Danish <> English) and (German <> Danish));
    end;

    /// <summary>
    /// Sets the language on a posted invoice, reading the row again first and handing the
    /// caller a fresh copy back.
    ///
    /// Both halves matter. Rendering an invoice increments No. Printed on the header, so a copy
    /// held from before a render cannot be saved; and the caller goes on to name the document
    /// from its own variable, so a variable still carrying the old language would have the
    /// proof measuring the wrong thing and reporting a failure against correct code.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The invoice. Re-read in place.</param>
    /// <param name="LanguageCode">The language to record on it.</param>
    internal procedure SetInvoiceLanguage(var SalesInvoiceHeader: Record "Sales Invoice Header"; LanguageCode: Code[10])
    var
        Writable: Record "Sales Invoice Header";
        InvoiceNo: Code[20];
    begin
        InvoiceNo := SalesInvoiceHeader."No.";
        if not Writable.Get(InvoiceNo) then
            exit;

        Writable."Language Code" := LanguageCode;
        Writable.Modify(false);

        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.Get(InvoiceNo);
    end;

    /// <summary>
    /// The filterviews payload a single posted sales invoice arrives as on the platform hook.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The invoice the payload should select.</param>
    /// <returns>The payload, as Business Central itself writes it.</returns>
    internal procedure InvoiceFilterViews(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    begin
        exit(InvoiceFilterViewsFor(SalesInvoiceHeader."No."));
    end;

    /// <summary>
    /// The same payload for a filter value the caller has built - three document numbers
    /// alternated, say, which is how a multi-document selection arrives.
    /// </summary>
    /// <param name="FilterValue">The filter expression the view should carry.</param>
    /// <returns>The payload, as Business Central itself writes it.</returns>
    internal procedure InvoiceFilterViewsFor(FilterValue: Text): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        exit(StrSubstNo(FilterViewsTok, InvoiceDataItemTok, Database::"Sales Invoice Header",
            SalesInvoiceHeader.FieldNo("No."), SalesInvoiceHeader.FieldNo("No."), FilterValue));
    end;

    /// <summary>
    /// The filterviews payload a single issued reminder arrives as on the platform hook.
    /// </summary>
    /// <param name="IssuedReminderHeader">The reminder the payload should select.</param>
    /// <returns>The payload, as Business Central itself writes it.</returns>
    internal procedure IssuedReminderFilterViews(var IssuedReminderHeader: Record "Issued Reminder Header"): Text
    begin
        exit(StrSubstNo(FilterViewsTok, IssuedReminderDataItemTok, Database::"Issued Reminder Header",
            IssuedReminderHeader.FieldNo("No."), IssuedReminderHeader.FieldNo("No."), IssuedReminderHeader."No."));
    end;

    /// <summary>
    /// The filterviews payload the proof's own document arrives as on the platform hook.
    /// </summary>
    /// <param name="ProofDocument">The document the payload should select.</param>
    /// <returns>The payload, as Business Central itself writes it.</returns>
    internal procedure ProofDocumentFilterViews(var ProofDocument: Record "Filename Proof Document"): Text
    begin
        exit(StrSubstNo(FilterViewsTok, ProofDocumentDataItemTok, Database::"Filename Proof Document",
            ProofDocument.FieldNo("No."), ProofDocument.FieldNo("No."), ProofDocument."No."));
    end;

    /// <summary>
    /// The amount as a file name has to carry it: the decimal places the document's own
    /// currency uses, with an invariant separator. Derived from the currency and the company's
    /// setup directly, so it is a reference the manager has to match rather than a copy of what
    /// the manager does.
    /// </summary>
    internal procedure AmountForFileName(Value: Decimal; CurrencyCode: Code[10]): Text
    begin
        exit(Format(Value, 0, StrSubstNo(InvariantAmountTok, DecimalPlacesFor(CurrencyCode))));
    end;

    /// <summary>
    /// Removes a job queue entry a proof created and ran itself through Job Queue Start Report,
    /// as the job queue removes a one-off entry once it has run. They were left behind before: by
    /// 8 October the container held about 110 of them, many still Ready.
    /// </summary>
    /// <param name="JobQueueEntryId">The entry's ID.</param>
    internal procedure RemoveJobQueueEntry(JobQueueEntryId: Guid)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get(JobQueueEntryId) then
            JobQueueEntry.Delete(true);
        Commit();
    end;

    local procedure DecimalPlacesFor(CurrencyCode: Code[10]) DecimalPlaces: Text
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        DecimalPlaces := DefaultDecimalPlacesTok;

        if Currency.Get(CurrencyCode) then begin
            if Currency."Amount Decimal Places" <> '' then
                DecimalPlaces := Currency."Amount Decimal Places";
            exit(DecimalPlaces);
        end;

        if GeneralLedgerSetup.Get() then
            if GeneralLedgerSetup."Amount Decimal Places" <> '' then
                DecimalPlaces := GeneralLedgerSetup."Amount Decimal Places";
    end;

    var
        InvariantAmountTok: Label '<Precision,%1><Standard Format,9>', Comment = '%1 the decimal places', Locked = true;
        DefaultDecimalPlacesTok: Label '2:2', Locked = true;
        // The one place this payload's shape is written down. It stood in three proofs before,
        // twice character for character, and the field numbers are asked of the record rather
        // than typed so that the payload cannot quietly stop selecting anything.
        FilterViewsTok: Label '[{"name":"%1","tableid":%2,"view":"VERSION(1) SORTING(Field%3) WHERE(Field%4=1(%5))"}]', Comment = '%1 data item name, %2 table number, %3 sorting field, %4 filtered field, %5 document number', Locked = true;
        InvoiceDataItemTok: Label 'Header', Locked = true;
        IssuedReminderDataItemTok: Label 'IssuedReminderHeader', Locked = true;
        ProofDocumentDataItemTok: Label 'Document', Locked = true;
}
