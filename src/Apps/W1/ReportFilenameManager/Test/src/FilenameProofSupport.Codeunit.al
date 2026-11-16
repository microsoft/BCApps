// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.Reflection;
using System.TestLibraries.Utilities;
using System.Threading;

codeunit 149512 "Filename Proof Support"
{
    // Helpers shared by the proofs. Captions are read in an explicit language: a pattern's
    // placeholders are matched against captions in the session language (or AL field names), so a
    // pattern written with another language's captions is refused when it is validated.

    Access = Internal;

    /// <param name="ItemName">A name beginning RESULT is a verdict.</param>
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

    // On the record in memory; Any leaves the pattern for every route.
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

    internal procedure AssertNameLanguage(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; ExpectedLanguageCode: Code[10])
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Assert: Codeunit "Library Assert";
    begin
        Assert.AreEqual(ExpectedLanguageCode, ReportFilenameMgt.NameLanguage(Pattern, DocumentRecRef), UnexpectedNameLanguageErr);
    end;

    internal procedure AssertSessionLanguage(ExpectedLanguageId: Integer)
    var
        Assert: Codeunit "Library Assert";
    begin
        Assert.AreEqual(ExpectedLanguageId, GlobalLanguage(), UnexpectedSessionLanguageErr);
    end;

    internal procedure AssertContains(Actual: Text; ExpectedParameter: Text)
    var
        Assert: Codeunit "Library Assert";
    begin
        Assert.AreNotEqual('', ExpectedParameter, EmptyExpectedParameterErr);
        Assert.IsTrue(StrPos(Actual, ExpectedParameter) > 0, StrSubstNo(MissingParameterErr, ExpectedParameter, Actual));
    end;

    // Without leaving the session in that language; empty when the field does not exist.
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

    // The caption in that language, in brackets.
    internal procedure FieldPlaceholderIn(LanguageId: Integer; TableNo: Integer; FieldNo: Integer): Text
    begin
        exit('[' + FieldCaptionIn(LanguageId, TableNo, FieldNo) + ']');
    end;

    // The related table's caption, a full stop, and the field's caption.
    internal procedure HopPlaceholderIn(LanguageId: Integer; RelatedTableNo: Integer; RelatedFieldNo: Integer): Text
    begin
        exit('[' + TableCaptionIn(LanguageId, RelatedTableNo) + '.' + FieldCaptionIn(LanguageId, RelatedTableNo, RelatedFieldNo) + ']');
    end;

    // A cross-language proof against identical captions proves nothing, so each asks this first.
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
    /// Re-reads the invoice first (a render increments No. Printed, so an older copy cannot be
    /// saved) and hands the caller the updated copy to name from.
    /// </summary>
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

    // A filterviews payload (name, tableid, view, as in OnGetFilename's payload) for one invoice.
    internal procedure InvoiceFilterViews(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    begin
        exit(InvoiceFilterViewsFor(SalesInvoiceHeader."No."));
    end;

    // For a caller-built filter, e.g. several document numbers joined with |.
    internal procedure InvoiceFilterViewsFor(FilterValue: Text): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        exit(StrSubstNo(FilterViewsTok, InvoiceDataItemTok, Database::"Sales Invoice Header",
            SalesInvoiceHeader.FieldNo("No."), SalesInvoiceHeader.FieldNo("No."), FilterValue));
    end;

    internal procedure IssuedReminderFilterViews(var IssuedReminderHeader: Record "Issued Reminder Header"): Text
    begin
        exit(StrSubstNo(FilterViewsTok, IssuedReminderDataItemTok, Database::"Issued Reminder Header",
            IssuedReminderHeader.FieldNo("No."), IssuedReminderHeader.FieldNo("No."), IssuedReminderHeader."No."));
    end;

    internal procedure ProofDocumentFilterViews(var ProofDocument: Record "Filename Proof Document"): Text
    begin
        exit(StrSubstNo(FilterViewsTok, ProofDocumentDataItemTok, Database::"Filename Proof Document",
            ProofDocument.FieldNo("No."), ProofDocument.FieldNo("No."), ProofDocument."No."));
    end;

    // The currency's decimal places with an invariant separator, derived independently of the manager.
    internal procedure AmountForFileName(Value: Decimal; CurrencyCode: Code[10]): Text
    begin
        exit(Format(Value, 0, StrSubstNo(InvariantAmountTok, DecimalPlacesFor(CurrencyCode))));
    end;

    // As the job queue removes a one-off entry once it has run.
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
        UnexpectedNameLanguageErr: Label 'The filename language must follow the document or its configured fallback, not the session.';
        UnexpectedSessionLanguageErr: Label 'Filename resolution must preserve the session language.';
        EmptyExpectedParameterErr: Label 'The expected message parameter must not be empty.';
        MissingParameterErr: Label 'Expected the value "%1" in "%2".', Comment = '%1 expected parameter, %2 actual text';
        InvariantAmountTok: Label '<Precision,%1><Standard Format,9>', Comment = '%1 the decimal places', Locked = true;
        DefaultDecimalPlacesTok: Label '2:2', Locked = true;
        FilterViewsTok: Label '[{"name":"%1","tableid":%2,"view":"VERSION(1) SORTING(Field%3) WHERE(Field%4=1(%5))"}]', Comment = '%1 data item name, %2 table number, %3 sorting field, %4 filtered field, %5 document number', Locked = true;
        InvoiceDataItemTok: Label 'Header', Locked = true;
        IssuedReminderDataItemTok: Label 'IssuedReminderHeader', Locked = true;
        ProofDocumentDataItemTok: Label 'Document', Locked = true;
}
