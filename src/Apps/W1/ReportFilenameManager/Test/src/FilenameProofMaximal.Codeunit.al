// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using System.EMail;
using System.Globalization;
using System.Reflection;
using System.Threading;
using System.Utilities;

codeunit 149508 "Filename Proof Maximal"
{
    // One pattern with field, related-field and computed placeholders resolves identically on four
    // routes (preview, download, email, scheduled), with a competing pattern present. Authored in a
    // Danish session; preview, download and email render in a German one. Also proves that a mixed
    // batch declines and that Max. Values Named and Max. File Name Length apply.

    SingleInstance = true;

    trigger OnRun()
    begin
        ProveMaximalCase();
        Commit();
        ProveMixedBatchDeclines();
        Commit();
        ProveValueCollapseAndTruncation();
        Commit();
    end;

    procedure ProveMaximalCase()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        RestoreLanguage: Integer;
        ExpectedName: Text;
        PreviewName: Text;
        DownloadName: Text;
        EmailName: Text;
        ScheduledName: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        // Payment terms description has no character the sanitiser would touch - see ExpectedMaximalName.
        PostInvoiceOnTerms(TestData.CreateCustomer(), BaseUnitPrice(), SalesInvoiceHeader);

        // Also matches, so the specific pattern has to win on selection.
        ConfigureCompetingPattern();
        // Limit set to the name's own length, so the default limit (100) cannot cut it.
        ExpectedName := ExpectedMaximalName(SalesInvoiceHeader);
        ConfigureMaximalPattern(StrLen(ExpectedName));
        ProofSupport.LogLine('12 Document', SalesInvoiceHeader."No.");

        ProofSupport.LogLine('12 Competing pattern that must lose', CompetingPatternTok);
        ProofSupport.LogLine('12 Binding stored', StoredBinding());
        ProofSupport.LogLine('12 Expected', ExpectedName);

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.GermanLanguageId());
        PreviewName := NameAsPreview(SalesInvoiceHeader);
        DownloadName := NameAsDownload(SalesInvoiceHeader);
        EmailName := NameAsEmail(SalesInvoiceHeader);
        GlobalLanguage(RestoreLanguage);

        Commit();
        ScheduledName := NameAsScheduled(SalesInvoiceHeader);

        ProofSupport.LogLine('12 Preview   rendered in German', PreviewName);
        ProofSupport.LogLine('12 Download  rendered in German', DownloadName);
        ProofSupport.LogLine('12 Email     rendered in German', EmailName);
        ProofSupport.LogLine('12 Scheduled through the job queue', ScheduledName);

        if (PreviewName = ExpectedName) and (DownloadName = ExpectedName) and (EmailName = ExpectedName) and (ScheduledName = ExpectedName) then
            ProofSupport.LogLine('RESULT maximal pattern is identical on all four routes', StrSubstNo(IdenticalMsg, ExpectedName))
        else
            ProofSupport.LogLine('RESULT maximal pattern is identical on all four routes',
                StrSubstNo(DifferMsg,
                    RouteDifference(PreviewLbl, ExpectedName, PreviewName) +
                    RouteDifference(DownloadLbl, ExpectedName, DownloadName) +
                    RouteDifference(EmailLbl, ExpectedName, EmailName) +
                    RouteDifference(ScheduledLbl, ExpectedName, ScheduledName)));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// A run over invoices with different amounts declines, so the caller keeps its own name.
    /// </summary>
    procedure ProveMixedBatchDeclines()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Numbers: List of [Text];
        ThreeInvoices: Text;
        Name: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        PostThreeInvoices(Numbers);
        ThreeInvoices := ThreeInvoiceFilter(Numbers);

        ClearPatterns();
        ConfigureMaximalPattern(0);

        Name := NameFromFilterViews(ThreeInvoices);
        ProofSupport.LogLine('13 Filter covering three invoices', ThreeInvoices);
        ProofSupport.LogLine('13 Maximal pattern over three documents', Name);

        if Name = DidNotResolveMsg then
            ProofSupport.LogLine('RESULT a batch whose documents disagree is left unnamed', PassMsg)
        else
            ProofSupport.LogLine('RESULT a batch whose documents disagree is left unnamed', StrSubstNo(ShouldNotHaveResolvedMsg, Name));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Filtered values are joined until they exceed Max. Values Named, then collapse to first-to-last.
    /// The length limit applies last and trims a trailing separator.
    /// </summary>
    procedure ProveValueCollapseAndTruncation()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Numbers: List of [Text];
        ThreeInvoices: Text;
        FirstNo: Code[20];
        LastNo: Code[20];
        JoinedName: Text;
        CollapsedName: Text;
        TruncatedName: Text;
        Limit: Integer;
        ExpectedJoined: Text;
        ExpectedCollapsed: Text;
        ExpectedTruncated: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        PostThreeInvoices(Numbers);
        ThreeInvoices := ThreeInvoiceFilter(Numbers);
        ThreeInvoiceBounds(Numbers, FirstNo, LastNo);

        ClearPatterns();
        CreateSimplePattern(3, 0);
        ExpectedJoined := InvoicePrefixTok + ThreeInvoicesJoined(Numbers);
        JoinedName := NameFromFilterViews(ThreeInvoices);
        ProofSupport.LogLine('14 Three values, three allowed', JoinedName);
        if JoinedName = ExpectedJoined then
            ProofSupport.LogLine('RESULT a selection is listed in full while it fits', PassMsg)
        else
            ProofSupport.LogLine('RESULT a selection is listed in full while it fits', StrSubstNo(ExpectedButGotMsg, ExpectedJoined, JoinedName));

        ClearPatterns();
        CreateSimplePattern(2, 0);
        ExpectedCollapsed := InvoicePrefixTok + FirstNo + CollapseJoinTok + LastNo;
        CollapsedName := NameFromFilterViews(ThreeInvoices);
        ProofSupport.LogLine('14 Three values, two allowed', CollapsedName);
        if CollapsedName = ExpectedCollapsed then
            ProofSupport.LogLine('RESULT too many values collapse to first-to-last', PassMsg)
        else
            ProofSupport.LogLine('RESULT too many values collapse to first-to-last', StrSubstNo(ExpectedButGotMsg, ExpectedCollapsed, CollapsedName));

        // The limit is put on a separator where there is one, so the trim is exercised; the
        // length check guards against a limit that cuts nothing.
        Limit := LimitThatCutsAfterASeparator(ExpectedJoined);
        ClearPatterns();
        CreateSimplePattern(3, Limit);
        ExpectedTruncated := TrimmedToLength(ExpectedJoined, Limit);
        TruncatedName := NameFromFilterViews(ThreeInvoices);
        ProofSupport.LogLine('14 Untruncated name', ExpectedJoined);
        ProofSupport.LogLine('14 Same name limited to ' + Format(Limit) + ' characters', TruncatedName);
        ProofSupport.LogLine('14 The cut lands on a separator, so the trim is exercised', Format(CopyStr(ExpectedJoined, Limit, 1) = SeparatorTok));
        if StrLen(ExpectedTruncated) >= StrLen(ExpectedJoined) then
            ProofSupport.LogLine('RESULT the length limit is applied last', LimitDidNothingMsg)
        else
            if TruncatedName = ExpectedTruncated then
                ProofSupport.LogLine('RESULT the length limit is applied last', StrSubstNo(TruncatedMsg, StrLen(ExpectedJoined), StrLen(TruncatedName), TruncatedName))
            else
                ProofSupport.LogLine('RESULT the length limit is applied last', StrSubstNo(ExpectedButGotMsg, ExpectedTruncated, TruncatedName));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Describes the difference from the first differing character, so the verdict fits in an error message.
    /// </summary>
    /// <returns>Blank when they match.</returns>
    local procedure RouteDifference(RouteName: Text; Expected: Text; Actual: Text): Text
    var
        i: Integer;
        Position: Integer;
    begin
        if Expected = Actual then
            exit('');

        Position := 0;
        for i := 1 to StrLen(Expected) do begin
            if i > StrLen(Actual) then begin
                Position := i;
                break;
            end;
            if Expected[i] <> Actual[i] then begin
                Position := i;
                break;
            end;
        end;
        if Position = 0 then
            Position := StrLen(Expected) + 1;

        exit(StrSubstNo(DifferenceLbl, RouteName, Position, TailFrom(Expected, Position), TailFrom(Actual, Position)));
    end;

    local procedure TailFrom(Value: Text; Position: Integer): Text
    begin
        if Position > StrLen(Value) then
            exit(NothingLbl);
        exit(CopyStr(Value, Position, 30));
    end;

    /// <summary>
    /// Built from the document independently of the manager.
    /// </summary>
    local procedure ExpectedMaximalName(var SalesInvoiceHeader: Record "Sales Invoice Header") Expected: Text
    var
        CompanyInformation: Record "Company Information";
        PaymentTerms: Record "Payment Terms";
    begin
        CompanyInformation.Get();
        PaymentTerms.Get(SalesInvoiceHeader."Payment Terms Code");
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        Expected :=
            CompanyInformation.Name + '-Invoice-' +
            SalesInvoiceHeader."No." + '-' +
            SalesInvoiceHeader."Sell-to Customer No." + '-' +
            PaymentTerms.Description + '-' +
            ProofSupport.AmountForFileName(SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Currency Code") + '-' +
            ProofSupport.AmountForFileName(SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Currency Code") + '-' +
            Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>') + '-' +
            ReportCaptionInDocumentLanguage(SalesInvoiceHeader);

        // Deliberately not put through the manager's sanitiser: an expectation that calls the code
        // under test moves with it. Assumes no value contains a character the sanitiser changes.
    end;

    local procedure ReportCaptionInDocumentLanguage(var SalesInvoiceHeader: Record "Sales Invoice Header") Caption: Text
    var
        ReportMetadata: Record "Report Metadata";
        LanguageMgt: Codeunit Language;
        RestoreLanguage: Integer;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(LanguageMgt.GetLanguageIdOrDefault(DocumentLanguageOf(SalesInvoiceHeader)));
        if ReportMetadata.Get(Report::"Standard Sales - Invoice") then
            Caption := ReportMetadata.Caption;
        GlobalLanguage(RestoreLanguage);
    end;

    /// <summary>
    /// Document language, then the session language (where the invoice report falls back too), then the application default.
    /// </summary>
    local procedure DocumentLanguageOf(var SalesInvoiceHeader: Record "Sales Invoice Header") LanguageCode: Code[10]
    var
        LanguageMgt: Codeunit Language;
    begin
        LanguageCode := SalesInvoiceHeader."Language Code";
        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetUserLanguageCode();
        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetLanguageCode(LanguageMgt.GetDefaultApplicationLanguageId());
    end;


    local procedure ConfigureMaximalPattern(MaxLength: Integer)
    var
        Pattern: Record "Report Filename Pattern";
        RestoreLanguage: Integer;
        PatternText: Text;
    begin
        // Typed with Danish captions in a Danish session, as a Danish administrator would.
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.DanishLanguageId());
        PatternText := MaximalPatternText();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("Date Format", Pattern."Date Format"::YearMonthDay);
        if MaxLength <> 0 then
            SetMaxFileNameLength(MaxLength);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        // Patterns are created disabled, so a live one must be enabled explicitly.
        Pattern.Enabled := true;
        Pattern.Insert(true);

        GlobalLanguage(RestoreLanguage);
        ProofSupport.LogLine('12 Pattern as authored', PatternText);
    end;

    /// <summary>
    /// Field and relation placeholders use the session language's captions; computed values use
    /// their canonical names, which are accepted in any language.
    /// </summary>
    local procedure MaximalPatternText(): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        LanguageId: Integer;
    begin
        LanguageId := GlobalLanguage();
        exit(
            '[' + CompanyPlaceholderTok + ']-Invoice-' +
            FilenameProofSupport.FieldPlaceholderIn(LanguageId, Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("No.")) + '-' +
            FilenameProofSupport.FieldPlaceholderIn(LanguageId, Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No.")) + '-' +
            FilenameProofSupport.HopPlaceholderIn(LanguageId, Database::"Payment Terms", PaymentTerms.FieldNo(Description)) + '-' +
            FilenameProofSupport.FieldPlaceholderIn(LanguageId, Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Amount Including VAT")) + '-' +
            '[' + TotalPlaceholderTok + ']-' +
            FilenameProofSupport.FieldPlaceholderIn(LanguageId, Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Posting Date")) + '-' +
            '[' + ReportCaptionPlaceholderTok + ']');
    end;

    /// <summary>
    /// Matches the same documents on a weaker criterion (table only), so it must lose selection.
    /// </summary>
    local procedure ConfigureCompetingPattern()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        RestoreLanguage: Integer;
    begin
        ClearPatterns();

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());

        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", CompetingPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        GlobalLanguage(RestoreLanguage);
    end;

    local procedure CreateSimplePattern(MaxValues: Integer; MaxLength: Integer)
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        RestoreLanguage: Integer;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("Max. Values Named", MaxValues);
        if MaxLength <> 0 then
            SetMaxFileNameLength(MaxLength);
        Pattern.Validate("File Name Pattern", SimplePatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        GlobalLanguage(RestoreLanguage);
    end;

    local procedure StoredBinding(): Text
    var
        Pattern: Record "Report Filename Pattern";
    begin
        // The maximal row is the one with a report ID; the competing row has none.
        Pattern.SetFilter("Report ID", '%1', Report::"Standard Sales - Invoice");
        if not Pattern.FindLast() then
            exit('');
        exit(Pattern.GetPlaceholderBinding());
    end;

    local procedure ClearPatterns()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.ClearPatterns();
    end;

    local procedure SetMaxFileNameLength(MaxLength: Integer)
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.SetMaxFileNameLength(MaxLength);
    end;

    local procedure NameAsPreview(var SalesInvoiceHeader: Record "Sales Invoice Header") Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Preview,
             EmptyRecRef, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader), Name)
        then
            exit(DidNotResolveMsg);
    end;

    local procedure NameAsDownload(var SalesInvoiceHeader: Record "Sales Invoice Header") Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        SalesInvoiceHeader.SetRecFilter();
        SourceRecRef.GetTable(SalesInvoiceHeader);

        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Download,
             SourceRecRef, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader), Name)
        then
            exit(DidNotResolveMsg);
    end;

    local procedure NameAsEmail(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        DocumentMailing: Codeunit "Document-Mailing";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
        AttachmentName: Text[250];
    begin
        SalesInvoiceHeader.SetRecFilter();
        RecRef.GetTable(SalesInvoiceHeader);

        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"Standard Sales - Invoice", '', ReportFormat::Pdf, OutStr, RecRef);

        DocumentMailing.GetAttachmentFileName(AttachmentName, SalesInvoiceHeader."No.",
            InvoiceDocTypeTok, "Report Selection Usage"::"S.Invoice".AsInteger());

        if AttachmentName = '' then
            exit(DidNotResolveMsg);

        exit(AttachmentName.Replace(PdfExtensionTok, ''));
    end;

    /// <summary>
    /// Runs codeunit Job Queue Start Report on a one-off entry and reads the name from the Report Inbox entry it produces.
    /// </summary>
    local procedure NameAsScheduled(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportInbox: Record "Report Inbox";
        Ran: Boolean;
    begin
        SalesInvoiceHeader.SetRecFilter();

        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"Standard Sales - Invoice";
        JobQueueEntry."Record ID to Process" := SalesInvoiceHeader.RecordId();
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::PDF;
        JobQueueEntry.Description := CopyStr(MaximalDescriptionTok, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry.Insert(true);
        Commit();

        Ran := Codeunit.Run(Codeunit::"Job Queue Start Report", JobQueueEntry);
        // The entry's ID stays in the variable and finds the Report Inbox row below.
        ProofSupport.RemoveJobQueueEntry(JobQueueEntry.ID);
        if not Ran then
            exit(DidNotResolveMsg);

        ReportInbox.SetRange("Job Queue Log Entry ID", JobQueueEntry.ID);
        if not ReportInbox.FindLast() then
            exit(DidNotResolveMsg);
        if ReportInbox."File Name" = '' then
            exit(DidNotResolveMsg);

        exit(ReportInbox."File Name");
    end;

    local procedure NameFromFilterViews(FilterViews: Text) Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Preview,
             EmptyRecRef, FilterViews, Name)
        then
            exit(DidNotResolveMsg);
    end;


    /// <summary>
    /// Three invoices with different customers and amounts. Amount Including VAT must agree across a run
    /// and Total Incl. VAT names one record only, so the maximal pattern declines. Each has payment
    /// terms, so a decline cannot come from a missing related record. Returned in posting order.
    /// </summary>
    local procedure PostThreeInvoices(var Numbers: List of [Text])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Counter: Integer;
    begin
        Clear(Numbers);
        for Counter := 1 to 3 do begin
            PostInvoiceOnTerms(TestData.CreateCustomer(), BaseUnitPrice() * Counter, SalesInvoiceHeader);
            Numbers.Add(SalesInvoiceHeader."No.");
        end;
    end;

    local procedure PostInvoiceOnTerms(CustomerNo: Code[20]; UnitPrice: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        TestData.PostNewInvoice(CustomerNo, '', TestData.CreatePaymentTerms(PaymentTermsDescriptionTok), UnitPrice, SalesInvoiceHeader);
    end;

    local procedure BaseUnitPrice(): Decimal
    begin
        exit(100);
    end;

    local procedure ThreeInvoiceFilter(var Numbers: List of [Text]): Text
    begin
        exit(ProofSupport.InvoiceFilterViewsFor(ThreeInvoicesJoinedWith(Numbers, AlternationTok)));
    end;

    local procedure ThreeInvoiceBounds(var Numbers: List of [Text]; var FirstNo: Code[20]; var LastNo: Code[20])
    begin
        FirstNo := CopyStr(Numbers.Get(1), 1, MaxStrLen(FirstNo));
        LastNo := CopyStr(Numbers.Get(Numbers.Count()), 1, MaxStrLen(LastNo));
    end;

    local procedure ThreeInvoicesJoined(var Numbers: List of [Text]): Text
    begin
        exit(ThreeInvoicesJoinedWith(Numbers, SeparatorTok));
    end;

    local procedure ThreeInvoicesJoinedWith(var Numbers: List of [Text]; Separator: Text) Joined: Text
    var
        Number: Text;
    begin
        foreach Number in Numbers do begin
            if Joined <> '' then
                Joined += Separator;
            Joined += Number;
        end;
    end;

    /// <summary>
    /// Cut to the limit, then trim a trailing separator.
    /// </summary>
    local procedure TrimmedToLength(Value: Text; MaxLength: Integer): Text
    begin
        if StrLen(Value) <= MaxLength then
            exit(Value);
        exit(DelChr(CopyStr(Value, 1, MaxLength), '>', ' .-'));
    end;

    /// <summary>
    /// Derived from the name because document numbers depend on the number series. The field
    /// accepts no limit below 20, so that is the fallback.
    /// </summary>
    local procedure LimitThatCutsAfterASeparator(Value: Text): Integer
    var
        Position: Integer;
    begin
        for Position := 20 to StrLen(Value) - 1 do
            if CopyStr(Value, Position, 1) = SeparatorTok then
                exit(Position);

        exit(20);
    end;



    var
        ProofSupport: Codeunit "Filename Proof Support";
        TestData: Codeunit "Filename Test Data";
        // The canonical names, which the app accepts in any session language.
        CompanyPlaceholderTok: Label 'Your Company Name', Locked = true;
        TotalPlaceholderTok: Label 'Total Incl. VAT', Locked = true;
        ReportCaptionPlaceholderTok: Label 'Report Name', Locked = true;
        CompetingPatternTok: Label 'Any-Invoice-[No.]', Locked = true;
        SimplePatternTok: Label 'Invoice-[No.]', Locked = true;
        InvoicePrefixTok: Label 'Invoice-', Locked = true;
        CollapseJoinTok: Label '-to-', Locked = true;
        SeparatorTok: Label '-', Locked = true;
        AlternationTok: Label '|', Locked = true;
        InvoiceDocTypeTok: Label 'Invoice', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        MaximalDescriptionTok: Label 'Filename proof maximal scheduled run', Locked = true;
        DidNotResolveMsg: Label '(did not resolve)';
        PassMsg: Label 'PASS';
        IdenticalMsg: Label 'IDENTICAL on all four routes: %1', Comment = '%1 the file name';
        DifferMsg: Label 'THE NAMES DIFFER - the claim does not hold. %1', Comment = '%1 which routes differ and how';
        DifferenceLbl: Label '%1 differs from character %2: expected "%3", got "%4". ', Comment = '%1 route, %2 position, %3 expected tail, %4 actual tail';
        NothingLbl: Label '(nothing - the name stops here)';
        PreviewLbl: Label 'Preview';
        DownloadLbl: Label 'Download';
        EmailLbl: Label 'Email';
        ScheduledLbl: Label 'Scheduled';
        ExpectedButGotMsg: Label 'FAIL - expected %1, got %2', Comment = '%1 expected value, %2 actual value';
        TruncatedMsg: Label 'PASS - cut from %1 characters to %2, with no separator left dangling: %3', Comment = '%1 length before, %2 length after, %3 the name';
        LimitDidNothingMsg: Label 'INCONCLUSIVE - the name is shorter than the shortest limit the field accepts, so truncation cannot be shown on this data.';
        ShouldNotHaveResolvedMsg: Label 'FAIL - it named the batch %1, which belongs to only one of the documents in it.', Comment = '%1 the name it produced';
        PaymentTermsDescriptionTok: Label 'Proof terms 14 days', Locked = true;
}
