// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Finance.Currency;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Reminder;
using System.Globalization;
using System.IO;
using System.Reflection;

codeunit 8125 "Report Filename Mgt."
{
    Access = Public;

    // Needed alongside the InherentPermissions attributes on TryResolve: an indirect read ('r')
    // succeeds only in an object whose Permissions property grants it.
    Permissions = tabledata "Report Filename Pattern" = r,
        tabledata "Report Filename Setup" = r;

    var
        BindStartTok: Label '{', Locked = true;
        BindEndTok: Label '}', Locked = true;
        PlaceholderStartTok: Label '[', Locked = true;
        PlaceholderEndTok: Label ']', Locked = true;
        FieldPrefixTok: Label 'f:', Locked = true;
        ComputedPrefixTok: Label 'c:', Locked = true;
        HopPrefixTok: Label 'r:', Locked = true;
        HopBindSeparatorTok: Label ':', Locked = true;
        HopSeparatorTok: Label ':', Locked = true;
        InvariantAmountTok: Label '<Precision,%1><Standard Format,9>', Comment = '%1 the decimal places, as Business Central writes them, such as 2:2', Locked = true;
        DefaultDecimalPlacesTok: Label '2:2', Locked = true;
        SortingLbl: Label 'SORTING(Field%1)', Comment = '%1 the field number the run is read in the order of', Locked = true;
        WhereTok: Label ' WHERE(', Locked = true;
        GreaterThanTok: Label '>%1', Comment = '%1 the last value already seen', Locked = true;
        // Invalid on Windows, plus # and %, which OneDrive for work or school lists as reserved.
        InvalidCharsTok: Label '"#%*:<>?\/|', Locked = true;
        SampleDecimalTok: Label '1234.50', Locked = true;
        SampleDecimalLastTok: Label '9876.50', Locked = true;
        SampleRangeSpanTok: Label '<+1M>', Locked = true;
        // Windows reads superscript digits as digits of a device name.
        ReservedNamesTok: Label 'CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9,COM¹,COM²,COM³,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9,LPT¹,LPT²,LPT³', Locked = true;
        ReminderAnswerKeyTok: Label '%1|%2|%3', Comment = '%1 reminder terms, %2 reminder level, %3 language code', Locked = true;
        // Copy of Electronic Document Format.GetAttachmentFileName's format; see BusinessCentralsDocumentFileName.
        DocumentFileNameTok: Label '%1 - %2 %3.%4', Comment = '%1 company name, %2 document type, %3 document number, %4 extension', Locked = true;
        SwitchedOffMsg: Label 'File name patterns are turned off, so every report gets Business Central''s own file name. Turn them on in the setup.';
        OpenSetupLbl: Label 'Open Setup';

    /// <summary>
    /// Resolves a file name for a report delivery. Returns false when no pattern applies or
    /// any placeholder cannot be resolved, in which case the caller keeps the name it already had.
    /// </summary>
    /// <param name="SourceRecRef">The document, when the caller has one. May be unopened.</param>
    // Every user who prints runs this, but Report Filename Mgr. is meant for pattern administrators,
    // so reading the patterns and setup is granted to the code. The records the name is built from
    // are still read under the user's own permissions.
    [InherentPermissions(PermissionObjectType::TableData, Database::"Report Filename Pattern", 'r')]
    [InherentPermissions(PermissionObjectType::Table, Database::"Report Filename Pattern", 'X')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Report Filename Setup", 'r')]
    [InherentPermissions(PermissionObjectType::Table, Database::"Report Filename Setup", 'X')]
    procedure TryResolve(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var SourceRecRef: RecordRef; FilterViews: Text; var Filename: Text): Boolean
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        Resolved: Boolean;
    begin
        Resolved := TryResolveOnce(PatternReportFor(ReportId), Channel, SourceRecRef, FilterViews, Filename);

        // The financial report period applies to this one name only, so it cannot leak into the next.
        ReportFilenameContext.ClearNamingPeriod();
        exit(Resolved);
    end;

    /// <summary>
    /// Whether the feature is switched on and at least one pattern exists. Subscribers ask this first,
    /// so that with the feature off the app adds no reads a user might lack permission for.
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Report Filename Pattern", 'r')]
    [InherentPermissions(PermissionObjectType::Table, Database::"Report Filename Pattern", 'X')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Report Filename Setup", 'r')]
    [InherentPermissions(PermissionObjectType::Table, Database::"Report Filename Setup", 'X')]
    procedure IsActive(): Boolean
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        if not ReportFilenameSetup.Get() then
            exit(false);
        if not ReportFilenameSetup.Enabled then
            exit(false);
        exit(not Pattern.IsEmpty());
    end;

    /// <summary>
    /// The report whose patterns apply. The Excel export of a financial report (a processing-only
    /// report) is named by the financial report's own pattern.
    /// </summary>
    local procedure PatternReportFor(ReportId: Integer): Integer
    begin
        if ReportId = Report::"Export Acc. Sched. to Excel" then
            exit(Report::"Account Schedule");
        exit(ReportId);
    end;

    // Covered by TryResolve's inherent permissions, which hold for everything it calls.
    local procedure TryResolveOnce(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var SourceRecRef: RecordRef; FilterViews: Text; var Filename: Text): Boolean
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        // Read here rather than through the table's GetSettings: a read inside the table's own code
        // is not covered by this codeunit's Permissions.
        if not ReportFilenameSetup.Get() then
            ReportFilenameSetup.Init();
        if not ReportFilenameSetup.Enabled then
            exit(false);

        // Checked before any record or JSON work, so with no patterns nothing else is read.
        if Pattern.IsEmpty() then
            exit(false);

        // Wrapped so that an error while naming does not stop the print; the caller keeps its own name.
        if not TryResolveInner(ReportId, Channel, SourceRecRef, FilterViews, Filename) then begin
            Clear(Filename);
            exit(false);
        end;

        exit(Filename <> '');
    end;

    /// <summary>
    /// The name a document would be given, together with the pattern that won, so Test Pattern can
    /// tell an administrator when a more specific pattern beats theirs.
    /// </summary>
    internal procedure TryResolveNaming(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var Winner: Record "Report Filename Pattern"; var Filename: Text): Boolean
    var
        LanguageCode: Code[10];
        LanguageKnown: Boolean;
    begin
        Clear(Filename);

        if not SelectPattern(ReportId, Channel, DocumentRecRef, Winner, LanguageCode, LanguageKnown) then
            exit(false);

        exit(TryResolveInLanguage(Winner, ReportId, DocumentRecRef, DocumentLanguage(Winner, DocumentRecRef), Filename));
    end;

    /// <summary>
    /// The report's caption, which Test Pattern shows as the name when no route rule gives one.
    /// </summary>
    internal procedure FallbackName(ReportId: Integer): Text
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportId = 0 then
            exit('');
        if not ReportMetadata.Get(ReportId) then
            exit('');
        exit(ReportMetadata.Caption);
    end;

    /// <summary>
    /// Whether Reminder Communication names any reminder in this run, in which case the whole run is
    /// left to it on every route. It subscribes to the same naming events, in unspecified order, so
    /// yielding keeps the result independent of subscriber order.
    /// Temporary: copies Reminder Communication's rule (FindFileName, GetReminderAttachmentText) until
    /// Base Application offers a public way to ask for its reminder name.
    /// </summary>
    internal procedure IsNamedByReminderCommunication(var DocumentRecRef: RecordRef): Boolean
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        RunRecRef: RecordRef;
        Answers: Dictionary of [Text, Boolean];
    begin
        if DocumentRecRef.Number() <> Database::"Issued Reminder Header" then
            exit(false);

        RunRecRef := DocumentRecRef.Duplicate();
        RunRecRef.SetLoadFields(IssuedReminderHeader.FieldNo("Customer No."), IssuedReminderHeader.FieldNo("Reminder Terms Code"),
            IssuedReminderHeader.FieldNo("Reminder Level"));
        if not RunRecRef.FindSet() then
            exit(false);

        repeat
            RunRecRef.SetTable(IssuedReminderHeader);
            if ReminderCommunicationNames(IssuedReminderHeader, Answers) then
                exit(true);
        until RunRecRef.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Each terms/level/language combination is looked up once per run.
    /// </summary>
    /// <returns>True when Reminder Communication names it, or would raise an error of its own.</returns>
    local procedure ReminderCommunicationNames(var IssuedReminderHeader: Record "Issued Reminder Header"; var Answers: Dictionary of [Text, Boolean]) Names: Boolean
    var
        LanguageCode: Code[10];
        AnswerKey: Text;
    begin
        if (IssuedReminderHeader."Reminder Level" = 0) or (IssuedReminderHeader."Reminder Terms Code" = '') then
            exit(false);

        LanguageCode := ReminderCommunicationLanguage(IssuedReminderHeader."Customer No.");
        AnswerKey := StrSubstNo(ReminderAnswerKeyTok, IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level", LanguageCode);
        if Answers.Get(AnswerKey, Names) then
            exit(Names);

        Names := ReminderFileNameIsSet(IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level", LanguageCode);
        Answers.Add(AnswerKey, Names);
    end;

    /// <summary>
    /// The level's attachment text, then the terms'. The first one found decides even when its File
    /// Name is blank, as in Reminder Communication.
    /// </summary>
    /// <returns>True when a File Name is set, or when the level or terms are missing.</returns>
    local procedure ReminderFileNameIsSet(TermsCode: Code[10]; Level: Integer; LanguageCode: Code[10]): Boolean
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        ReminderLevel.SetLoadFields("Reminder Attachment Text");
        if not ReminderLevel.Get(TermsCode, Level) then
            exit(true);

        ReminderAttachmentText.SetLoadFields("File Name");
        if ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", LanguageCode) then
            exit(ReminderAttachmentText."File Name" <> '');

        ReminderTerms.SetLoadFields("Reminder Attachment Text");
        if not ReminderTerms.Get(TermsCode) then
            exit(true);

        if ReminderAttachmentText.Get(ReminderTerms."Reminder Attachment Text", LanguageCode) then
            exit(ReminderAttachmentText."File Name" <> '');

        exit(false);
    end;

    /// <summary>
    /// Reminder Communication's language order (customer, user, application default), deliberately
    /// not the company default this feature names documents in.
    /// </summary>
    local procedure ReminderCommunicationLanguage(CustomerNo: Code[20]) LanguageCode: Code[10]
    var
        Customer: Record Customer;
        LanguageMgt: Codeunit Language;
    begin
        Customer.SetLoadFields("Language Code");
        if Customer.Get(CustomerNo) then
            LanguageCode := Customer."Language Code";

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetUserLanguageCode();

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetLanguageCode(LanguageMgt.GetDefaultApplicationLanguageId());
    end;

    [TryFunction]
    local procedure TryResolveInner(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var SourceRecRef: RecordRef; FilterViews: Text; var Filename: Text)
    var
        Pattern: Record "Report Filename Pattern";
        DocumentRecRef: RecordRef;
        LanguageCode: Code[10];
        LanguageKnown: Boolean;
    begin
        Clear(Filename);

        if not FindDocument(ReportId, SourceRecRef, FilterViews, DocumentRecRef) then
            exit;

        if IsNamedByReminderCommunication(DocumentRecRef) then
            exit;

        if not SelectPattern(ReportId, Channel, DocumentRecRef, Pattern, LanguageCode, LanguageKnown) then
            exit;

        // Re-read from the winner: selection read each candidate's language through that candidate's
        // own language field, which may differ from the winner's.
        LanguageCode := DocumentLanguage(Pattern, DocumentRecRef);

        if not TryResolveInLanguage(Pattern, ReportId, DocumentRecRef, LanguageCode, Filename) then
            Clear(Filename);
    end;

    /// <summary>
    /// The name one particular pattern produces, without choosing between patterns.
    /// </summary>
    internal procedure TryResolveWithPattern(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; var Filename: Text): Boolean
    begin
        exit(TryResolveInLanguage(Pattern, ReportId, DocumentRecRef, DocumentLanguage(Pattern, DocumentRecRef), Filename));
    end;

    /// <summary>
    /// Uses the document's language rather than the session's, so the same document gets the same
    /// name whoever produces it.
    /// </summary>
    local procedure TryResolveInLanguage(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var Filename: Text): Boolean
    var
        Resolved: Text;
    begin
        if not TryEvaluate(Pattern, ReportId, DocumentRecRef, LanguageCode, false, Resolved) then
            exit(false);

        exit(TryFinishName(Resolved, Filename));
    end;

    /// <summary>
    /// Finds the run's selection. Tried in order: the subject recorded by the starting action, the
    /// filter in the platform payload (OnGetFilename only), the caller's reference, and finally the
    /// whole table, which is a real answer for an unfiltered run.
    /// </summary>
    local procedure FindDocument(ReportId: Integer; var SourceRecRef: RecordRef; FilterViews: Text; var DocumentRecRef: RecordRef): Boolean
    var
        TableNo: Integer;
        ViewText: Text;
    begin
        TableNo := SubjectTableNo(ReportId);

        // Used by Financial Reporting: every financial report renders through one report object,
        // so the run itself does not say which financial report it is.
        if TryTakeRunSubject(ReportId, DocumentRecRef) then
            exit(true);

        if (TableNo <> 0) and (FilterViews <> '') then
            if GetViewForTable(FilterViews, TableNo, ViewText) then
                if TryOpenAndApply(TableNo, ViewText, DocumentRecRef) then
                    exit(true);

        // No SetRecFilter: the reference sits on an arbitrary row of the run, and the whole run is named.
        if TryOpenFromRecRef(SourceRecRef, DocumentRecRef) then
            if not DocumentRecRef.IsEmpty() then
                exit(true);

        if TableNo = 0 then
            exit(false);

        // No filter means the run selected the whole table - but only when the report reads that
        // table as a data item. Report 25 is about one financial report, so it is not named here.
        if not IteratesTable(ReportId, TableNo) then
            exit(false);

        exit(TryOpenWholeTable(TableNo, DocumentRecRef));
    end;

    /// <summary>
    /// The table a run is about: the first data item when it is a real table, otherwise the
    /// shallowest real table among the data items (some reports, such as 910 Posted Assembly Order,
    /// start with the virtual Integer table), otherwise zero.
    /// </summary>
    internal procedure SubjectTableNo(ReportId: Integer): Integer
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportId = 0 then
            exit(0);

        if ReportMetadata.Get(ReportId) then
            exit(SubjectTableNo(ReportMetadata));

        exit(SubjectFromDataItems(ReportId));
    end;

    /// <summary>
    /// Overload for callers that already hold the metadata, to avoid re-reading it per report.
    /// </summary>
    internal procedure SubjectTableNo(var ReportMetadata: Record "Report Metadata"): Integer
    begin
        // Every financial report renders through report 25, whose data items do not include the
        // Financial Report the administrator chose.
        if ReportMetadata.ID = Report::"Account Schedule" then
            exit(Database::"Financial Report");

        if IsNamableTable(ReportMetadata.FirstDataItemTableID) then
            exit(ReportMetadata.FirstDataItemTableID);

        exit(SubjectFromDataItems(ReportMetadata.ID));
    end;

    /// <summary>
    /// The reports whose subject is this table, as a filter on Report Metadata's ID. Report 25 is
    /// checked on its own because its subject is not among its data items.
    /// </summary>
    /// <returns>The IDs joined by |, or blank when no report is about the table.</returns>
    internal procedure ReportsAboutTable(TableNo: Integer) IdFilter: Text
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if not IsNamableTable(TableNo) then
            exit('');

        ReportMetadata.SetRange(ProcessingOnly, false);
        ReportMetadata.SetRange(FirstDataItemTableID, TableNo);
        if ReportMetadata.FindSet() then
            repeat
                if SubjectTableNo(ReportMetadata) = TableNo then
                    AddToIdFilter(IdFilter, ReportMetadata.ID);
            until ReportMetadata.Next() = 0;

        ReportMetadata.SetFilter(FirstDataItemTableID, '<>%1', TableNo);
        if ReportMetadata.FindSet() then
            repeat
                if not IsNamableTable(ReportMetadata.FirstDataItemTableID) then
                    if SubjectTableNo(ReportMetadata) = TableNo then
                        AddToIdFilter(IdFilter, ReportMetadata.ID);
            until ReportMetadata.Next() = 0;

        if SubjectTableNo(Report::"Account Schedule") = TableNo then
            AddToIdFilter(IdFilter, Report::"Account Schedule");
    end;

    local procedure AddToIdFilter(var IdFilter: Text; ReportId: Integer)
    begin
        if IdFilter <> '' then
            IdFilter += '|';
        IdFilter += Format(ReportId, 0, 9);
    end;

    local procedure SubjectFromDataItems(ReportId: Integer): Integer
    var
        ReportDataItems: Record "Report Data Items";
        Shallowest: Integer;
        Found: Integer;
    begin
        ReportDataItems.SetRange("Report ID", ReportId);
        if not ReportDataItems.FindSet() then
            exit(0);

        Shallowest := -1;
        repeat
            if IsNamableTable(ReportDataItems."Related Table ID") then
                if (Shallowest = -1) or (ReportDataItems."Indentation Level" < Shallowest) then begin
                    Shallowest := ReportDataItems."Indentation Level";
                    Found := ReportDataItems."Related Table ID";
                end;
        until ReportDataItems.Next() = 0;

        exit(Found);
    end;

    /// <summary>
    /// The table view a report declares on its subject (for example Standard Sales - Quote reads only quotes),
    /// so records offered for testing are ones the report can see. Taken from the shallowest data
    /// item over the table, as SubjectFromDataItems picks it.
    /// </summary>
    internal procedure SubjectViewOf(ReportId: Integer; TableNo: Integer): Text
    var
        ReportDataItems: Record "Report Data Items";
        Shallowest: Integer;
        View: Text;
    begin
        // A pattern with no report covers every report about the table, so no view applies.
        if (ReportId = 0) or (TableNo = 0) then
            exit('');

        ReportDataItems.SetRange("Report ID", ReportId);
        ReportDataItems.SetRange("Related Table ID", TableNo);
        if not ReportDataItems.FindSet() then
            exit('');

        Shallowest := -1;
        repeat
            if (Shallowest = -1) or (ReportDataItems."Indentation Level" < Shallowest) then begin
                Shallowest := ReportDataItems."Indentation Level";
                View := ReportDataItems."Data Item Table View";
            end;
        until ReportDataItems.Next() = 0;

        exit(View);
    end;

    /// <summary>
    /// Excludes system tables and obsolete tables whose fields the placeholder picker does not offer.
    /// </summary>
    internal procedure IsNamableTable(TableNo: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if (TableNo <= 0) or (TableNo >= 2000000000) then
            exit(false);
        if not TableMetadata.Get(TableNo) then
            exit(false);
        exit(TableMetadata.ObsoleteState = TableMetadata.ObsoleteState::No);
    end;

    local procedure IteratesTable(ReportId: Integer; TableNo: Integer): Boolean
    var
        ReportDataItems: Record "Report Data Items";
    begin
        if TableNo = 0 then
            exit(false);

        ReportDataItems.SetRange("Report ID", ReportId);
        // No readable data items: assume the report reads the table.
        if ReportDataItems.IsEmpty() then
            exit(true);

        ReportDataItems.SetRange("Related Table ID", TableNo);
        exit(not ReportDataItems.IsEmpty());
    end;

    local procedure TryTakeRunSubject(ReportId: Integer; var DocumentRecRef: RecordRef): Boolean
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        exit(ReportFilenameContext.TryTakeRunSubject(ReportId, DocumentRecRef));
    end;

    [TryFunction]
    local procedure TryOpenFromRecRef(var SourceRecRef: RecordRef; var DocumentRecRef: RecordRef)
    begin
        DocumentRecRef := SourceRecRef.Duplicate();
    end;

    [TryFunction]
    local procedure TryOpenWholeTable(TableNo: Integer; var DocumentRecRef: RecordRef)
    begin
        Clear(DocumentRecRef);
        DocumentRecRef.Open(TableNo);
    end;

    [TryFunction]
    local procedure TryOpenAndApply(TableNo: Integer; ViewText: Text; var DocumentRecRef: RecordRef)
    begin
        Clear(DocumentRecRef);
        DocumentRecRef.Open(TableNo);
        DocumentRecRef.SetView(ViewText);
    end;

    local procedure GetViewForTable(FilterViews: Text; TableNo: Integer; var ViewText: Text): Boolean
    var
        Views: JsonArray;
        i: Integer;
    begin
        if TableNo = 0 then
            exit(false);
        if not Views.ReadFrom(FilterViews) then
            exit(false);

        for i := 0 to Views.Count() - 1 do
            if TryReadViewForTable(Views, i, TableNo, ViewText) then
                exit(true);

        exit(false);
    end;

    /// <summary>
    /// Checks the shape at every step: an unexpected platform payload leaves the document
    /// unidentified rather than raising an error during a print.
    /// </summary>
    local procedure TryReadViewForTable(var Views: JsonArray; Index: Integer; TableNo: Integer; var ViewText: Text): Boolean
    var
        Entry: JsonToken;
        Value: JsonToken;
    begin
        if not Views.Get(Index, Entry) then
            exit(false);
        if not Entry.IsObject() then
            exit(false);
        if not Entry.AsObject().Get('tableid', Value) then
            exit(false);
        if not Value.IsValue() then
            exit(false);
        if Value.AsValue().AsInteger() <> TableNo then
            exit(false);
        if not Entry.AsObject().Get('view', Value) then
            exit(false);
        if not Value.IsValue() then
            exit(false);

        ViewText := Value.AsValue().AsText();
        exit(ViewText <> '');
    end;

    /// <summary>
    /// Most specific pattern wins; a blank criterion applies to anything.
    /// </summary>
    local procedure SelectPattern(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var Best: Record "Report Filename Pattern"; var BestLanguageCode: Code[10]; var BestLanguageKnown: Boolean): Boolean
    var
        Candidate: Record "Report Filename Pattern";
        CandidateLanguageCode: Code[10];
        CandidateLanguageKnown: Boolean;
        BestScore: Integer;
        Score: Integer;
        Found: Boolean;
    begin
        BestScore := 0;
        BestLanguageCode := '';
        BestLanguageKnown := false;
        Candidate.SetCurrentKey(Enabled, "Report ID", "Table No.");
        Candidate.SetRange(Enabled, true);
        Candidate.SetLoadFields("Report ID", "Table No.", "Output Route Filter", "Language Code", "Language Code Field", "File Name Pattern", "Date Format", "Max. Values Named", "Separator");
        if not Candidate.FindSet() then
            exit(false);

        repeat
            if Matches(Candidate, ReportId, Channel, DocumentRecRef, Score, CandidateLanguageCode, CandidateLanguageKnown) then
                if (not Found) or (Score > BestScore) then begin
                    Best := Candidate;
                    BestScore := Score;
                    BestLanguageCode := CandidateLanguageCode;
                    BestLanguageKnown := CandidateLanguageKnown;
                    Found := true;
                end;
        until Candidate.Next() = 0;

        exit(Found);
    end;

    local procedure Matches(var Candidate: Record "Report Filename Pattern"; ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var Score: Integer; var LanguageCode: Code[10]; var LanguageKnown: Boolean): Boolean
    begin
        exit(UnmetCriterion(Candidate, ReportId, Channel, DocumentRecRef, Score, LanguageCode, LanguageKnown) = "Report Filename Criterion"::None);
    end;

    /// <summary>
    /// For Test Pattern: the first criterion not met, by the same rules used at delivery.
    /// </summary>
    /// <param name="DocumentLanguageCode">Receives the document's language when the pattern has
    /// a language to compare it with; blank otherwise.</param>
    internal procedure FirstUnmetCriterion(var Candidate: Record "Report Filename Pattern"; ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var DocumentLanguageCode: Code[10]): Enum "Report Filename Criterion"
    var
        Score: Integer;
        LanguageKnown: Boolean;
    begin
        exit(UnmetCriterion(Candidate, ReportId, Channel, DocumentRecRef, Score, DocumentLanguageCode, LanguageKnown));
    end;

    local procedure UnmetCriterion(var Candidate: Record "Report Filename Pattern"; ReportId: Integer; Channel: Enum "Report Filename Output Route"; var DocumentRecRef: RecordRef; var Score: Integer; var LanguageCode: Code[10]; var LanguageKnown: Boolean): Enum "Report Filename Criterion"
    var
        Criterion: Enum "Report Filename Criterion";
        HasTableFilter: Boolean;
    begin
        Score := 0;
        LanguageCode := '';
        LanguageKnown := false;

        if Candidate."File Name Pattern" = '' then
            exit(Criterion::"File Name Pattern");

        if Candidate."Report ID" <> 0 then
            if Candidate."Report ID" <> ReportId then
                exit(Criterion::Report);

        if Candidate."Table No." <> 0 then
            if Candidate."Table No." <> DocumentRecRef.Number() then
                exit(Criterion::"Table");

        if not Candidate.AppliesToRoute(Channel) then
            exit(Criterion::"Output Route");

        // Checked per candidate, because each row names its own language field.
        if Candidate."Language Code" <> '' then begin
            LanguageCode := DocumentLanguage(Candidate, DocumentRecRef);
            LanguageKnown := true;
            if Candidate."Language Code" <> LanguageCode then
                exit(Criterion::Language);
        end;

        // Evaluated last because it reads a BLOB and counts the run twice.
        HasTableFilter := Candidate.HasTableFilter();
        if HasTableFilter then
            if not DocumentSatisfies(Candidate, DocumentRecRef) then
                exit(Criterion::"Table Filter");

        // Same rule as the Priority shown in the list.
        Score := Candidate.Specificity(HasTableFilter);
        exit(Criterion::None);
    end;

    /// <summary>
    /// True only when EVERY record in the run satisfies the pattern's condition, because the name
    /// applies to the whole file. The condition goes in its own filter group so it combines with
    /// the run's filter rather than replacing it.
    /// </summary>
    local procedure DocumentSatisfies(var Candidate: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef): Boolean
    var
        TestRecRef: RecordRef;
        InTheRun: Integer;
        Satisfying: Integer;
    begin
        if not TrySelectionCount(DocumentRecRef, InTheRun) then
            exit(false);

        // An empty run must not satisfy every condition vacuously.
        if InTheRun = 0 then
            exit(false);

        TestRecRef := DocumentRecRef.Duplicate();
        if not TryApplyCondition(TestRecRef, Candidate.GetTableFilterView()) then
            exit(false);

        if not TrySelectionCount(TestRecRef, Satisfying) then
            exit(false);

        exit(Satisfying = InTheRun);
    end;

    // A try function, so a reference that cannot be counted declines the condition instead of raising.
    [TryFunction]
    local procedure TrySelectionCount(var SelectionRecRef: RecordRef; var Records: Integer)
    var
        CountRecRef: RecordRef;
    begin
        CountRecRef := SelectionRecRef.Duplicate();
        Records := CountRecRef.Count();
    end;

    [TryFunction]
    local procedure TryApplyCondition(var TestRecRef: RecordRef; ViewText: Text)
    begin
        TestRecRef.FilterGroup(10);
        TestRecRef.SetView(ViewText);
        TestRecRef.FilterGroup(0);
    end;

    /// <summary>
    /// The language every record in the run agrees on, read up to MaxRecordsToAgree records.
    /// A run that disagrees falls back to the company default.
    /// </summary>
    local procedure TryReadLanguageForRun(var DocumentRecRef: RecordRef; FieldNo: Integer; var LanguageCode: Code[10]): Boolean
    var
        WorkRecRef: RecordRef;
        LanguageFieldRef: FieldRef;
        AgreedCode: Code[10];
        ThisCode: Code[10];
        Seen: Integer;
        AnyRecords: Boolean;
    begin
        Clear(LanguageCode);

        if not TryOpenAgreementRead(DocumentRecRef, FieldNo, WorkRecRef, AnyRecords) then
            exit(false);
        if not AnyRecords then
            exit(false);

        repeat
            Seen += 1;

            if not TryReadField(WorkRecRef, FieldNo, LanguageFieldRef) then
                exit(false);
            ThisCode := CopyStr(Format(LanguageFieldRef.Value()), 1, MaxStrLen(ThisCode));

            if Seen = 1 then
                AgreedCode := ThisCode
            else
                if ThisCode <> AgreedCode then
                    exit(false);

            // Decline rather than name a large run after its first few records.
            if Seen > MaxRecordsToAgree() then
                exit(false);
        until WorkRecRef.Next() = 0;

        LanguageCode := AgreedCode;
        exit(LanguageCode <> '');
    end;

    [TryFunction]
    local procedure TryOpenAgreementRead(var DocumentRecRef: RecordRef; FieldNo: Integer; var WorkRecRef: RecordRef; var AnyRecords: Boolean)
    begin
        WorkRecRef := DocumentRecRef.Duplicate();
        WorkRecRef.SetLoadFields(FieldNo);
        AnyRecords := WorkRecRef.FindSet();
    end;

    internal procedure NameLanguage(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef): Code[10]
    begin
        exit(DocumentLanguage(Pattern, DocumentRecRef));
    end;

    /// <summary>
    /// The language the name is built in: the document's, then the company's Default
    /// Language Code (as Report Distribution Management.GetDocumentLanguageCode), then the
    /// application default. Never the user's, so the name does not depend on who produces it.
    /// </summary>
    local procedure DocumentLanguage(var Candidate: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef) LanguageCode: Code[10]
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        LanguageMgt: Codeunit Language;
    begin
        if Candidate."Language Code Field" <> 0 then
            if not TryReadLanguageForRun(DocumentRecRef, Candidate."Language Code Field", LanguageCode) then
                Clear(LanguageCode);

        CompanyInformationMgt.GetLanguageDefault(LanguageCode);

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetLanguageCode(LanguageMgt.GetDefaultApplicationLanguageId());

        exit(LanguageCode);
    end;

    /// <summary>
    /// Replaces every placeholder from the binding saved with the pattern (field numbers, not names),
    /// so renamed or translated fields cannot change what resolves. Declines the whole pattern if
    /// any placeholder has no value, rather than producing a partly filled name.
    /// </summary>
    local procedure TryEvaluate(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; ShapesOnly: Boolean; var Result: Text): Boolean
    begin
        exit(TryEvaluate(Pattern, ReportId, DocumentRecRef, LanguageCode, ShapesOnly, '', Result));
    end;

    /// <param name="DocumentRecRef">The run's selection, or an unopened reference when shaping.</param>
    /// <param name="ShapesOnly">True to shape from metadata rather than read any record.</param>
    /// <param name="ValueJoiner">Shaping only: empty for a single record; otherwise the separator
    /// (listed values) or separator, range word, separator (first-to-last range).</param>
    local procedure TryEvaluate(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; ShapesOnly: Boolean; ValueJoiner: Text; var Result: Text): Boolean
    var
        Remaining: Text;
        Placeholder: Text;
        PlaceholderValue: Text;
        LastValue: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        Remaining := Pattern.GetPlaceholderBinding();
        // The binding is built when the text is validated; there is no fallback to resolving by name.
        if Remaining = '' then
            exit(false);

        while Remaining <> '' do begin
            StartPos := StrPos(Remaining, BindStartTok);
            if StartPos = 0 then begin
                Result += UnescapeLiteral(Remaining);
                Remaining := '';
            end else begin
                Result += UnescapeLiteral(CopyStr(Remaining, 1, StartPos - 1));

                if CopyStr(Remaining, StartPos + 1, 1) = BindStartTok then begin
                    Result += BindStartTok;
                    Remaining := CopyStr(Remaining, StartPos + 2);
                end else begin
                    EndPos := StrPos(CopyStr(Remaining, StartPos), BindEndTok);
                    if EndPos = 0 then
                        exit(false);
                    EndPos += StartPos - 1;

                    Placeholder := CopyStr(Remaining, StartPos + 1, EndPos - StartPos - 1);
                    // The walk is shared with the preview so the two cannot drift apart; only this step differs.
                    if ShapesOnly then begin
                        if not ShapeForBoundPlaceholder(Pattern, Placeholder, false, PlaceholderValue) then
                            exit(false);
                        if ValueJoiner <> '' then
                            if CollapsesOverARun(Placeholder) then begin
                                if not ShapeForBoundPlaceholder(Pattern, Placeholder, true, LastValue) then
                                    exit(false);
                                if LastValue <> PlaceholderValue then
                                    PlaceholderValue += ValueJoiner + LastValue;
                            end else
                                // As at run time, a computed value that cannot speak for many records declines the pattern.
                                if not SpeaksForARunOfMany(Placeholder) then
                                    exit(false);
                    end else
                        if not TryResolveBoundPlaceholder(Pattern, ReportId, DocumentRecRef, LanguageCode, Placeholder, PlaceholderValue) then
                            exit(false);
                    if PlaceholderValue = '' then
                        exit(false);

                    Result += PlaceholderValue;
                    Remaining := CopyStr(Remaining, EndPos + 1);
                end;
            end;
        end;

        exit(Result <> '');
    end;

    /// <summary>
    /// The first placeholder without a value, as the administrator wrote it. The binding keeps the
    /// pattern text's placeholder order, so the position maps back to the text.
    /// </summary>
    /// <param name="ShapesOnly">True to test each placeholder's shape rather than its value.</param>
    /// <param name="PlaceholderText">Receives the placeholder, brackets included.</param>
    internal procedure TryFindPlaceholderWithoutValue(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; ShapesOnly: Boolean; var PlaceholderText: Text): Boolean
    var
        LanguageCode: Code[10];
        Remaining: Text;
        Placeholder: Text;
        PlaceholderValue: Text;
        StartPos: Integer;
        EndPos: Integer;
        Position: Integer;
        HasValue: Boolean;
    begin
        PlaceholderText := '';
        Remaining := Pattern.GetPlaceholderBinding();
        if Remaining = '' then
            exit(false);
        if not ShapesOnly then
            LanguageCode := DocumentLanguage(Pattern, DocumentRecRef);

        while Remaining <> '' do begin
            StartPos := StrPos(Remaining, BindStartTok);
            if StartPos = 0 then
                exit(false);
            if CopyStr(Remaining, StartPos + 1, 1) = BindStartTok then
                Remaining := CopyStr(Remaining, StartPos + 2)
            else begin
                EndPos := StrPos(CopyStr(Remaining, StartPos), BindEndTok);
                if EndPos = 0 then
                    exit(false);
                EndPos += StartPos - 1;
                Placeholder := CopyStr(Remaining, StartPos + 1, EndPos - StartPos - 1);
                Position += 1;

                PlaceholderValue := '';
                if ShapesOnly then
                    HasValue := ShapeForBoundPlaceholder(Pattern, Placeholder, false, PlaceholderValue)
                else
                    HasValue := TryResolveBoundPlaceholder(Pattern, ReportId, DocumentRecRef, LanguageCode, Placeholder, PlaceholderValue);
                if not HasValue or (PlaceholderValue = '') then begin
                    PlaceholderText := PlaceholderInText(Pattern."File Name Pattern", Position);
                    exit(PlaceholderText <> '');
                end;

                Remaining := CopyStr(Remaining, EndPos + 1);
            end;
        end;
        exit(false);
    end;

    // Finds placeholders the way BuildBinding does: from each opening bracket to the next closing one.
    local procedure PlaceholderInText(PatternText: Text; Position: Integer): Text
    var
        Remaining: Text;
        StartPos: Integer;
        EndPos: Integer;
        Seen: Integer;
    begin
        Remaining := PatternText;
        while StrPos(Remaining, PlaceholderStartTok) > 0 do begin
            StartPos := StrPos(Remaining, PlaceholderStartTok);
            EndPos := StrPos(CopyStr(Remaining, StartPos), PlaceholderEndTok);
            if EndPos = 0 then
                exit('');
            EndPos += StartPos - 1;
            Seen += 1;
            if Seen = Position then
                exit(CopyStr(Remaining, StartPos, EndPos - StartPos + 1));
            Remaining := CopyStr(Remaining, EndPos + 1);
        end;
        exit('');
    end;

    // Braces in literal text are doubled when the binding is built.
    local procedure UnescapeLiteral(LiteralText: Text): Text
    begin
        exit(LiteralText.Replace(BindEndTok + BindEndTok, BindEndTok));
    end;

    /// <summary>
    /// The name in the Example File Name part, built from value shapes rather than a real document:
    /// there may be no data, no permission to read it, or it may be sensitive. Finished with the
    /// same sanitiser and length limit as a real name.
    /// </summary>
    internal procedure TryShapeName(var Pattern: Record "Report Filename Pattern"; var Filename: Text): Boolean
    begin
        exit(TryShapeName(Pattern, false, Filename));
    end;

    /// <param name="OverManyRecords">True for the first-to-last range shape of a run over many records.</param>
    internal procedure TryShapeName(var Pattern: Record "Report Filename Pattern"; OverManyRecords: Boolean; var Filename: Text): Boolean
    var
        NoDocument: RecordRef;
        Resolved: Text;
        Joiner: Text;
    begin
        if OverManyRecords then
            Joiner := RangeJoinOf(Pattern);

        if not TryEvaluate(Pattern, Pattern."Report ID", NoDocument, Pattern."Language Code", true, Joiner, Resolved) then
            exit(false);

        exit(TryFinishName(Resolved, Filename));
    end;

    /// <summary>
    /// The shape of a run over a few records (up to Max. Values Named): values listed rather than
    /// collapsed to first-to-last.
    /// </summary>
    internal procedure TryShapeNameListed(var Pattern: Record "Report Filename Pattern"; var Filename: Text): Boolean
    var
        NoDocument: RecordRef;
        Resolved: Text;
    begin
        if not TryEvaluate(Pattern, Pattern."Report ID", NoDocument, Pattern."Language Code", true, SeparatorOf(Pattern), Resolved) then
            exit(false);

        exit(TryFinishName(Resolved, Filename));
    end;

    /// <summary>
    /// Mirrors TryResolveBoundPlaceholder case for case. A relation placeholder is shaped from the
    /// related table's metadata, never by following the relation.
    /// </summary>
    local procedure ShapeForBoundPlaceholder(var Pattern: Record "Report Filename Pattern"; Placeholder: Text; Last: Boolean; var PlaceholderValue: Text): Boolean
    var
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        FieldNo: Integer;
        LocalFieldNo: Integer;
        RelatedFieldNo: Integer;
        RelatedTableNo: Integer;
        HopText: Text;
        SeparatorPos: Integer;
    begin
        PlaceholderValue := '';

        if CopyStr(Placeholder, 1, StrLen(FieldPrefixTok)) = FieldPrefixTok then begin
            if not Evaluate(FieldNo, CopyStr(Placeholder, StrLen(FieldPrefixTok) + 1)) then
                exit(false);
            PlaceholderValue := FilenamePlaceholderMgt.ShapeForField(Pattern, Pattern."Table No.", FieldNo, Last);
            exit(PlaceholderValue <> '');
        end;

        if CopyStr(Placeholder, 1, StrLen(HopPrefixTok)) = HopPrefixTok then begin
            HopText := CopyStr(Placeholder, StrLen(HopPrefixTok) + 1);
            SeparatorPos := StrPos(HopText, HopBindSeparatorTok);
            if SeparatorPos = 0 then
                exit(false);
            if not Evaluate(LocalFieldNo, CopyStr(HopText, 1, SeparatorPos - 1)) then
                exit(false);
            if not Evaluate(RelatedFieldNo, CopyStr(HopText, SeparatorPos + 1)) then
                exit(false);
            RelatedTableNo := FilenamePlaceholderMgt.RelatedTableOf(Pattern."Table No.", LocalFieldNo);
            if RelatedTableNo = 0 then
                exit(false);
            PlaceholderValue := FilenamePlaceholderMgt.ShapeForField(Pattern, RelatedTableNo, RelatedFieldNo, Last);
            exit(PlaceholderValue <> '');
        end;

        if CopyStr(Placeholder, 1, StrLen(ComputedPrefixTok)) = ComputedPrefixTok then begin
            if not FilenamePlaceholderMgt.ShapeForComputed(Pattern, CopyStr(Placeholder, StrLen(ComputedPrefixTok) + 1), PlaceholderValue) then
                exit(false);
            exit(PlaceholderValue <> '');
        end;

        exit(false);
    end;

    // Field values have two ends over a run; a computed value (company, date made) is one value.
    local procedure CollapsesOverARun(Placeholder: Text): Boolean
    begin
        exit(CopyStr(Placeholder, 1, StrLen(ComputedPrefixTok)) <> ComputedPrefixTok);
    end;

    // An unrecognised placeholder is treated as unable to speak for a run: declining is safer.
    local procedure SpeaksForARunOfMany(Placeholder: Text): Boolean
    var
        PlaceholderImplementation: Interface "Report Filename Placeholder";
    begin
        if not TryFindComputedPlaceholder(CopyStr(Placeholder, StrLen(ComputedPrefixTok) + 1), PlaceholderImplementation) then
            exit(false);
        exit(PlaceholderImplementation.SpeaksForARunOfManyRecords());
    end;

    local procedure SeparatorOf(var Pattern: Record "Report Filename Pattern") Separator: Text
    begin
        Separator := Pattern."Separator";
        if Separator = '' then
            Separator := '-';
    end;

    /// <summary>
    /// What goes between the first and last value of a range. A blank Range Word is a valid choice
    /// and leaves just the separator.
    /// </summary>
    internal procedure RangeJoinOf(var Pattern: Record "Report Filename Pattern") Joiner: Text
    begin
        Joiner := SeparatorOf(Pattern);
        if Pattern."Range Word" = '' then
            exit(Joiner);
        exit(Joiner + Pattern."Range Word" + Joiner);
    end;

    local procedure TryResolveBoundPlaceholder(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; Placeholder: Text; var PlaceholderValue: Text): Boolean
    var
        FieldRec: Record Field;
        FieldNo: Integer;
    begin
        // The caller reuses this variable for every placeholder; no value may carry over.
        PlaceholderValue := '';

        if CopyStr(Placeholder, 1, StrLen(FieldPrefixTok)) = FieldPrefixTok then begin
            if not Evaluate(FieldNo, CopyStr(Placeholder, StrLen(FieldPrefixTok) + 1)) then
                exit(false);
            // The field may have been removed in a later version.
            if not FieldRec.Get(DocumentRecRef.Number(), FieldNo) then
                exit(false);
            exit(ResolveField(Pattern, DocumentRecRef, FieldRec, PlaceholderValue));
        end;

        if CopyStr(Placeholder, 1, StrLen(HopPrefixTok)) = HopPrefixTok then
            exit(ResolveHop(Pattern, DocumentRecRef, CopyStr(Placeholder, StrLen(HopPrefixTok) + 1), PlaceholderValue));

        if CopyStr(Placeholder, 1, StrLen(ComputedPrefixTok)) = ComputedPrefixTok then
            exit(ResolveComputed(Pattern, ReportId, DocumentRecRef, LanguageCode, CopyStr(Placeholder, StrLen(ComputedPrefixTok) + 1), PlaceholderValue));

        exit(false);
    end;

    // The binding stores the canonical name, not the enum ordinal, so reordering an extension's values is safe.
    local procedure ResolveComputed(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; CanonicalName: Text; var PlaceholderValue: Text): Boolean
    var
        PlaceholderImplementation: Interface "Report Filename Placeholder";
    begin
        if not TryFindComputedPlaceholder(CanonicalName, PlaceholderImplementation) then
            exit(false);

        exit(PlaceholderImplementation.TryResolve(Pattern, ReportId, DocumentRecRef, LanguageCode, PlaceholderValue));
    end;

    internal procedure TryFindComputedPlaceholder(CanonicalName: Text; var PlaceholderImplementation: Interface "Report Filename Placeholder"): Boolean
    begin
        exit(TryFindComputedPlaceholder(CanonicalName, false, PlaceholderImplementation));
    end;

    /// <summary>
    /// Walks the placeholder enum, including values added by extensions.
    /// </summary>
    /// <param name="AcceptDisplayName">True to also match the translated display name, as a typed pattern may carry either; a binding is matched on the canonical name only.</param>
    internal procedure TryFindComputedPlaceholder(PlaceholderName: Text; AcceptDisplayName: Boolean; var PlaceholderImplementation: Interface "Report Filename Placeholder"): Boolean
    var
        PlaceholderValue: Enum "Report Filename Placeholder";
        Candidate: Interface "Report Filename Placeholder";
        Ordinal: Integer;
    begin
        foreach Ordinal in PlaceholderValue.Ordinals() do begin
            PlaceholderValue := Enum::"Report Filename Placeholder".FromInteger(Ordinal);
            Candidate := PlaceholderValue;
            if Candidate.CanonicalName() = PlaceholderName then begin
                PlaceholderImplementation := Candidate;
                exit(true);
            end;
            if AcceptDisplayName and (Candidate.DisplayName() = PlaceholderName) then begin
                PlaceholderImplementation := Candidate;
                exit(true);
            end;
        end;
        exit(false);
    end;

    /// <summary>
    /// A placeholder one table relation away, such as a reminder's interest rate on Finance Charge Terms.
    /// </summary>
    local procedure ResolveHop(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; HopText: Text; var PlaceholderValue: Text): Boolean
    var
        LocalFieldRec: Record Field;
        RelatedFieldRec: Record Field;
        RelatedRecRef: RecordRef;
        LocalFieldRef: FieldRef;
        LocalFieldNo: Integer;
        RelatedFieldNo: Integer;
        RelationValue: Text;
    begin
        if not TrySplitHop(HopText, LocalFieldNo, RelatedFieldNo) then
            exit(false);

        if not LocalFieldRec.Get(DocumentRecRef.Number(), LocalFieldNo) then
            exit(false);
        if LocalFieldRec.RelationTableNo = 0 then
            exit(false);
        if not RelatedFieldRec.Get(LocalFieldRec.RelationTableNo, RelatedFieldNo) then
            exit(false);

        // Named after every related record the run points at, as for a field on the run's own table.
        if LocalFieldRec.Class = LocalFieldRec.Class::Normal then
            if TryHopOverRun(Pattern, DocumentRecRef, LocalFieldRec, RelatedFieldRec, PlaceholderValue) then
                exit(PlaceholderValue <> '');

        // Fallback for a FlowField, or a run TryHopOverRun cannot read in order: the related
        // record must be the same across the whole run.
        if not ResolveSingleValue(Pattern, DocumentRecRef, LocalFieldRec, RelationValue) then
            exit(false);
        if RelationValue = '' then
            exit(false);

        if not TryOpenRelated(LocalFieldRec, RelationValue, RelatedRecRef, LocalFieldRef) then
            exit(false);

        exit(ResolveSingleValue(Pattern, RelatedRecRef, RelatedFieldRec, PlaceholderValue));
    end;

    /// <summary>
    /// Reads the run in the order of the pointing field. A range's ends are the related values of
    /// the first and last pointing values, not the alphabetical extremes of the related values,
    /// which would cost a read per distinct value. A try function so an unorderable field falls back.
    /// </summary>
    [TryFunction]
    local procedure TryHopOverRun(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var LocalFieldRec: Record Field; var RelatedFieldRec: Record Field; var PlaceholderValue: Text)
    var
        PointingValues: List of [Text];
        RelatedValues: List of [Text];
        FirstPointing: Text;
        LastPointing: Text;
        FirstRelated: Text;
        LastRelated: Text;
        RelatedValue: Text;
        PointingValue: Text;
    begin
        PlaceholderValue := '';

        if not ReadEnds(Pattern, DocumentRecRef, LocalFieldRec, FirstPointing, LastPointing) then
            exit;

        if FirstPointing = LastPointing then begin
            if HopTo(Pattern, LocalFieldRec, RelatedFieldRec, FirstPointing, RelatedValue) then
                PlaceholderValue := RelatedValue;
            exit;
        end;

        if CollectValues(Pattern, DocumentRecRef, LocalFieldRec, PointingValues) then begin
            foreach PointingValue in PointingValues do begin
                // One relation that cannot be followed declines the placeholder rather than leave a gap.
                if not HopTo(Pattern, LocalFieldRec, RelatedFieldRec, PointingValue, RelatedValue) then
                    exit;

                // Two related records can share a description; avoid names like Net-Net.
                if not RelatedValues.Contains(RelatedValue) then
                    RelatedValues.Add(RelatedValue);
            end;

            PlaceholderValue := Joined(RelatedValues, SeparatorOf(Pattern));
            exit;
        end;

        if not HopTo(Pattern, LocalFieldRec, RelatedFieldRec, FirstPointing, FirstRelated) then
            exit;
        if not HopTo(Pattern, LocalFieldRec, RelatedFieldRec, LastPointing, LastRelated) then
            exit;

        if FirstRelated = LastRelated then begin
            PlaceholderValue := FirstRelated;
            exit;
        end;

        PlaceholderValue := FirstRelated + RangeJoinOf(Pattern) + LastRelated;
    end;

    local procedure HopTo(var Pattern: Record "Report Filename Pattern"; var LocalFieldRec: Record Field; var RelatedFieldRec: Record Field; RelationValue: Text; var RelatedValue: Text): Boolean
    var
        RelatedRecRef: RecordRef;
        TargetFieldRef: FieldRef;
    begin
        RelatedValue := '';

        if RelationValue = '' then
            exit(false);

        if not TryOpenRelated(LocalFieldRec, RelationValue, RelatedRecRef, TargetFieldRef) then
            exit(false);

        exit(ResolveSingleValue(Pattern, RelatedRecRef, RelatedFieldRec, RelatedValue));
    end;

    // With no target field (RelationFieldNo 0), the first primary key field is used, as Config.
    // Validate Management does for a single-field key.
    [TryFunction]
    local procedure TryOpenRelated(var LocalFieldRec: Record Field; RelationValue: Text; var RelatedRecRef: RecordRef; var TargetFieldRef: FieldRef)
    var
        RelatedKeyRef: KeyRef;
    begin
        RelatedRecRef.Open(LocalFieldRec.RelationTableNo);

        if LocalFieldRec.RelationFieldNo <> 0 then
            TargetFieldRef := RelatedRecRef.Field(LocalFieldRec.RelationFieldNo)
        else begin
            RelatedKeyRef := RelatedRecRef.KeyIndex(1);
            TargetFieldRef := RelatedKeyRef.FieldIndex(1);
        end;

        TargetFieldRef.SetRange(RelationValue);
    end;

    local procedure TrySplitHop(HopText: Text; var LocalFieldNo: Integer; var RelatedFieldNo: Integer): Boolean
    var
        SplitPos: Integer;
    begin
        SplitPos := StrPos(HopText, HopSeparatorTok);
        if SplitPos = 0 then
            exit(false);
        if not Evaluate(LocalFieldNo, CopyStr(HopText, 1, SplitPos - 1)) then
            exit(false);
        exit(Evaluate(RelatedFieldNo, CopyStr(HopText, SplitPos + 1)));
    end;

    /// <summary>
    /// Names the run from the records it covers, not from its filter, so one selection gets one
    /// name however it was described. Read in the field's own order, the cost does not grow with
    /// the run: first, last, and one read per further listed value.
    /// </summary>
    local procedure ResolveField(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var PlaceholderValue: Text): Boolean
    var
        SourceFieldRef: FieldRef;
    begin
        if not TryReadField(DocumentRecRef, FieldRec."No.", SourceFieldRef) then
            exit(false);

        // A FlowFilter has no value on any record, only the filter the run is given.
        if FieldRec.Class = FieldRec.Class::FlowFilter then
            exit(ResolveFlowFilter(Pattern, SourceFieldRef, FieldRec, PlaceholderValue));

        // A FlowField has no value until calculated, so it is resolved record by record with
        // CalcField, bounded by MaxRecordsToAgree.
        if FieldRec.Class <> FieldRec.Class::Normal then
            exit(ResolveSingleValue(Pattern, DocumentRecRef, FieldRec, PlaceholderValue));

        // A stored field the platform will not order on falls back the same way.
        if not TryNameFromRecords(Pattern, DocumentRecRef, FieldRec, PlaceholderValue) then
            exit(ResolveSingleValue(Pattern, DocumentRecRef, FieldRec, PlaceholderValue));

        exit(PlaceholderValue <> '');
    end;

    /// <summary>
    /// Names a single value or a range. No filter, a filter GetRangeMin/Max rejects (such as a
    /// list), or a blank end declines the placeholder.
    /// </summary>
    local procedure ResolveFlowFilter(var Pattern: Record "Report Filename Pattern"; var FilterFieldRef: FieldRef; var FieldRec: Record Field; var PlaceholderValue: Text): Boolean
    var
        FirstText: Text;
        LastText: Text;
    begin
        PlaceholderValue := '';
        if FilterFieldRef.GetFilter() = '' then
            exit(false);
        if not TryReadFilterEnds(Pattern, FilterFieldRef, FieldRec, FirstText, LastText) then
            exit(false);
        if (FirstText = '') or (LastText = '') then
            exit(false);

        if FirstText = LastText then
            PlaceholderValue := FirstText
        else
            PlaceholderValue := FirstText + RangeJoinOf(Pattern) + LastText;
        exit(true);
    end;

    // GetRangeMin/Max raise an error for a filter that is not a single value or a range.
    [TryFunction]
    local procedure TryReadFilterEnds(var Pattern: Record "Report Filename Pattern"; var FilterFieldRef: FieldRef; var FieldRec: Record Field; var FirstText: Text; var LastText: Text)
    begin
        FirstText := FormatFilterValue(Pattern, FieldRec, FilterFieldRef.GetRangeMin());
        LastText := FormatFilterValue(Pattern, FieldRec, FilterFieldRef.GetRangeMax());
    end;

    local procedure FormatFilterValue(var Pattern: Record "Report Filename Pattern"; var FieldRec: Record Field; Value: Variant): Text
    var
        AsDate: Date;
    begin
        case FieldRec.Type of
            FieldRec.Type::Date:
                begin
                    AsDate := Value;
                    exit(FormatDate(AsDate, Pattern."Date Format"));
                end;
            FieldRec.Type::Code,
            FieldRec.Type::Text,
            FieldRec.Type::Integer,
            FieldRec.Type::Option:
                exit(Format(Value));
        end;
        exit('');
    end;

    // A try function so a field the platform will not order on falls back rather than fails the name.
    [TryFunction]
    local procedure TryNameFromRecords(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var PlaceholderValue: Text)
    var
        Values: List of [Text];
        FirstText: Text;
        LastText: Text;
    begin
        PlaceholderValue := '';

        if not ReadEnds(Pattern, DocumentRecRef, FieldRec, FirstText, LastText) then
            exit;

        // Read in this field's order, so equal ends mean every record holds the same value.
        if FirstText = LastText then begin
            PlaceholderValue := FirstText;
            exit;
        end;

        if CollectValues(Pattern, DocumentRecRef, FieldRec, Values) then begin
            PlaceholderValue := Joined(Values, SeparatorOf(Pattern));
            exit;
        end;

        PlaceholderValue := FirstText + RangeJoinOf(Pattern) + LastText;
    end;

    /// <summary>
    /// The distinct values of a field in the run, in order. Each next value is found as the first
    /// one greater than the last, so the cost is one read per value, not per record.
    /// </summary>
    /// <returns>False when there are more values than the name lists.</returns>
    local procedure CollectValues(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var Values: List of [Text]): Boolean
    var
        WorkRecRef: RecordRef;
        WorkFieldRef: FieldRef;
        LastSeen: Variant;
        ValueText: Text;
        Seen: Integer;
        MaxNamed: Integer;
    begin
        Clear(Values);
        MaxNamed := NamedIndividually(Pattern);

        WorkRecRef := DocumentRecRef.Duplicate();
        WorkRecRef.SetView(OrderedBy(WorkRecRef, FieldRec."No."));

        if not WorkRecRef.FindFirst() then
            exit(false);

        WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
        Values.Add(FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef));
        LastSeen := WorkFieldRef.Value();
        Seen := 1;

        while true do begin
            // Own filter group, so it cannot replace the run's filter on the same field.
            WorkRecRef.FilterGroup(NextValueFilterGroup());
            WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
            WorkFieldRef.SetFilter(GreaterThanTok, LastSeen);
            WorkRecRef.FilterGroup(0);

            if not WorkRecRef.FindFirst() then
                exit(true);

            Seen += 1;
            if Seen > MaxNamed then
                exit(false);

            WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
            ValueText := FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef);
            LastSeen := WorkFieldRef.Value();

            // Different stored values can format the same (amounts of differing precision).
            if not Values.Contains(ValueText) then
                Values.Add(ValueText);
        end;
    end;

    /// <summary>
    /// Deliberately not a try function: an unorderable field must fail the caller's try function
    /// so it falls back, rather than turn into an empty name here.
    /// </summary>
    local procedure ReadEnds(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var FirstText: Text; var LastText: Text): Boolean
    var
        WorkRecRef: RecordRef;
        WorkFieldRef: FieldRef;
    begin
        FirstText := '';
        LastText := '';

        WorkRecRef := DocumentRecRef.Duplicate();
        WorkRecRef.SetView(OrderedBy(WorkRecRef, FieldRec."No."));

        if not WorkRecRef.FindFirst() then
            exit(false);
        WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
        FirstText := FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef);

        if not WorkRecRef.FindLast() then
            exit(false);
        WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
        LastText := FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef);

        exit(true);
    end;

    /// <summary>
    /// A RecordRef has no SetCurrentKey (CurrentKeyIndex picks only a defined key), so the order is
    /// set through the view (as Data Search does), keeping the WHERE part so the run is not
    /// widened to the whole table.
    /// </summary>
    local procedure OrderedBy(var SourceRecRef: RecordRef; FieldNo: Integer) NewView: Text
    var
        CurrentView: Text;
        WherePos: Integer;
    begin
        CurrentView := SourceRecRef.GetView(false);
        NewView := StrSubstNo(SortingLbl, FieldNo);

        WherePos := StrPos(CurrentView, WhereTok);
        if WherePos > 0 then
            NewView += CopyStr(CurrentView, WherePos);
    end;

    local procedure Joined(var Values: List of [Text]; Separator: Text) Rendered: Text
    var
        Value: Text;
    begin
        foreach Value in Values do begin
            if Rendered <> '' then
                Rendered += Separator;
            Rendered += Value;
        end;
    end;

    /// <summary>
    /// How many values the name lists before collapsing to first-to-last. Guards against zero from
    /// a row written without validation, such as a configuration package import.
    /// </summary>
    local procedure NamedIndividually(var Pattern: Record "Report Filename Pattern") MaxNamed: Integer
    begin
        MaxNamed := Pattern."Max. Values Named";
        if MaxNamed < 1 then
            MaxNamed := 3;
    end;

    local procedure NextValueFilterGroup(): Integer
    begin
        exit(12);
    end;

    local procedure ResolveSingleValue(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; var FieldRec: Record Field; var PlaceholderValue: Text): Boolean
    var
        WorkRecRef: RecordRef;
        WorkFieldRef: FieldRef;
        FirstValue: Text;
        Seen: Integer;
    begin
        WorkRecRef := DocumentRecRef.Duplicate();
        // Every field is loaded when the value is a decimal: formatting it reads the document's
        // currency from another field on the same row (DocumentCurrencyCode).
        if (FieldRec.Class <> FieldRec.Class::FlowField) and (FieldRec.Type <> FieldRec.Type::Decimal) then
            WorkRecRef.SetLoadFields(FieldRec."No.");
        if not WorkRecRef.FindSet() then
            exit(false);

        repeat
            Seen += 1;
            WorkFieldRef := WorkRecRef.Field(FieldRec."No.");
            if FieldRec.Class = FieldRec.Class::FlowField then
                WorkFieldRef.CalcField();

            if Seen = 1 then
                FirstValue := FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef)
            else
                if FormatFieldRef(WorkFieldRef, FieldRec, Pattern, WorkRecRef) <> FirstValue then
                    exit(false);

            // Decline rather than name a large run after its first few records.
            if Seen > MaxRecordsToAgree() then
                exit(false);
        until WorkRecRef.Next() = 0;

        PlaceholderValue := FirstValue;
        exit(PlaceholderValue <> '');
    end;

    local procedure MaxRecordsToAgree(): Integer
    begin
        exit(100);
    end;

    local procedure FormatFieldRef(var SourceFieldRef: FieldRef; var FieldRec: Record Field; var Pattern: Record "Report Filename Pattern"; var OwnerRecRef: RecordRef): Text
    var
        AsDateTime: DateTime;
        AsDecimal: Decimal;
    begin
        case FieldRec.Type of
            FieldRec.Type::Date:
                exit(FormatDate(SourceFieldRef.Value(), Pattern."Date Format"));
            FieldRec.Type::DateTime:
                begin
                    // Only the date part: the sanitiser would strip the time's colons and run the digits together.
                    AsDateTime := SourceFieldRef.Value();
                    exit(FormatDate(DT2Date(AsDateTime), Pattern."Date Format"));
                end;
            FieldRec.Type::Decimal:
                begin
                    AsDecimal := SourceFieldRef.Value();
                    exit(FormatPatternDecimal(AsDecimal, OwnerRecRef));
                end;
            FieldRec.Type::Time:
                // A time has no file-safe form that stays readable, so the placeholder declines.
                exit('');
            FieldRec.Type::BLOB,
            FieldRec.Type::Media,
            FieldRec.Type::MediaSet:
                exit('');
        end;
        exit(Format(SourceFieldRef.Value()));
    end;

    /// <summary>
    /// To the document currency's decimal places, with an invariant separator and no grouping: the
    /// session's format region would otherwise make the same amount read differently per user.
    /// </summary>
    /// <param name="OwnerRecRef">The record the amount is on, which is where its currency is read from.</param>
    internal procedure FormatPatternDecimal(Value: Decimal; var OwnerRecRef: RecordRef): Text
    begin
        exit(Format(Value, 0, StrSubstNo(InvariantAmountTok, AmountDecimalPlaces(OwnerRecRef))));
    end;

    // The currency's decimal places, or General Ledger Setup's for local currency.
    local procedure AmountDecimalPlaces(var OwnerRecRef: RecordRef) DecimalPlaces: Text
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        DecimalPlaces := DefaultDecimalPlacesTok;

        if Currency.Get(DocumentCurrencyCode(OwnerRecRef)) then begin
            if Currency."Amount Decimal Places" <> '' then
                DecimalPlaces := Currency."Amount Decimal Places";
            exit(DecimalPlaces);
        end;

        if GeneralLedgerSetup.Get() then
            if GeneralLedgerSetup."Amount Decimal Places" <> '' then
                DecimalPlaces := GeneralLedgerSetup."Amount Decimal Places";
    end;

    internal procedure FormatPatternDate(Value: Date; DateFormat: Enum "Report Filename Date Format"): Text
    begin
        exit(FormatDate(Value, DateFormat));
    end;

    // The one field relating to Currency; none or several means local currency, as for a blank code.
    local procedure DocumentCurrencyCode(var OwnerRecRef: RecordRef) CurrencyCode: Code[10]
    var
        FieldRec: Record Field;
        CurrencyFieldRef: FieldRef;
    begin
        FieldRec.SetRange(TableNo, OwnerRecRef.Number());
        FieldRec.SetRange(RelationTableNo, Database::Currency);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Enabled, true);
        if FieldRec.Count() <> 1 then
            exit('');

        FieldRec.FindFirst();
        if not TryReadField(OwnerRecRef, FieldRec."No.", CurrencyFieldRef) then
            exit('');

        exit(CopyStr(Format(CurrencyFieldRef.Value()), 1, MaxStrLen(CurrencyCode)));
    end;

    internal procedure FormatSampleDate(DateFormat: Enum "Report Filename Date Format"): Text
    begin
        exit(FormatSampleDate(DateFormat, false));
    end;

    /// <summary>
    /// The later sample is a month on, so the two ends differ in every offered format except
    /// Year, where they differ only in December.
    /// </summary>
    internal procedure FormatSampleDate(DateFormat: Enum "Report Filename Date Format"; Last: Boolean): Text
    begin
        if Last then
            exit(FormatDate(CalcDate(SampleRangeSpanTok, Today()), DateFormat));
        exit(FormatDate(Today(), DateFormat));
    end;

    local procedure FormatDate(Value: Date; DateFormat: Enum "Report Filename Date Format"): Text
    begin
        if Value = 0D then
            exit('');

        case DateFormat of
            DateFormat::YearMonthDay:
                exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
            DateFormat::YearMonthDayCompact:
                exit(Format(Value, 0, '<Year4><Month,2><Day,2>'));
            DateFormat::DayMonthYear:
                exit(Format(Value, 0, '<Day,2>-<Month,2>-<Year4>'));
            DateFormat::YearMonth:
                exit(Format(Value, 0, '<Year4>-<Month,2>'));
            DateFormat::Year:
                exit(Format(Value, 0, '<Year4>'));
        end;
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    [TryFunction]
    local procedure TryReadField(var DocumentRecRef: RecordRef; FieldNo: Integer; var ResultFieldRef: FieldRef)
    begin
        ResultFieldRef := DocumentRecRef.Field(FieldNo);
    end;

    internal procedure SampleDecimalText(): Text
    begin
        exit(SampleDecimalText(false));
    end;

    internal procedure SampleDecimalText(Last: Boolean): Text
    begin
        if Last then
            exit(SampleDecimalLastTok);
        exit(SampleDecimalTok);
    end;

    /// <summary>
    /// Narrower than Sanitise: a separator sits mid-name, so leading or trailing spaces and periods
    /// (as in " - ") are allowed.
    /// </summary>
    internal procedure IsUsableSeparator(Value: Text): Boolean
    begin
        if Value = '' then
            exit(true);
        if DelChr(Value, '=', InvalidCharsTok) <> Value then
            exit(false);
        exit(DelChr(Value, '=', GetControlChars()) = Value);
    end;

    internal procedure DisallowedCharacters(): Text
    begin
        exit(InvalidCharsTok);
    end;

    /// <summary>
    /// GetSafeFileName removes only what the server's OS rejects (on Unix just null and /), so every
    /// device's invalid characters are removed as well. Unusual but legal characters such as &amp;
    /// or ~ are kept, which is why StripNotsupportChrInFileName is not used.
    /// </summary>
    /// <returns>A name that is safe to use, or an empty string when nothing usable remains - the pattern then declines.</returns>
    internal procedure Sanitise(Value: Text) Result: Text
    begin
        Result := CleanName(Value);

        if Result = '' then
            exit('');

        if IsReservedName(Result) then
            exit('');
    end;

    local procedure CleanName(Value: Text) Result: Text
    var
        FileManagement: Codeunit "File Management";
    begin
        Result := FileManagement.GetSafeFileName(Value);
        Result := RemoveCharsEveryDeviceRejects(Result);

        while StrPos(Result, '  ') > 0 do
            Result := Result.Replace('  ', ' ');

        Result := DelChr(Result, '<>', ' .');
    end;

    /// <summary>
    /// For Test Pattern: why FinishName refuses a name, judged in the same order.
    /// </summary>
    /// <param name="CutName">Receives the name after the cut, for the two refusals made after it.</param>
    internal procedure WhyNameIsRefused(Value: Text; var CutName: Text): Enum "Report Filename Refusal"
    var
        Cleaned: Text;
    begin
        CutName := '';
        Cleaned := CleanName(Value);
        if Cleaned = '' then
            exit(Enum::"Report Filename Refusal"::"Nothing Usable");
        if IsReservedName(Cleaned) then
            exit(Enum::"Report Filename Refusal"::Reserved);

        CutName := Truncate(Cleaned, MaxFileNameLength());
        if CutName = '' then
            exit(Enum::"Report Filename Refusal"::"Nothing After Cut");
        if IsReservedName(CutName) then
            exit(Enum::"Report Filename Refusal"::"Reserved After Cut");
        exit(Enum::"Report Filename Refusal"::None);
    end;

    /// <summary>
    /// As TryResolveWithPattern, but before FinishName sanitises and cuts the name.
    /// </summary>
    internal procedure TryBuildUnfinishedName(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; var Resolved: Text): Boolean
    begin
        exit(TryEvaluate(Pattern, ReportId, DocumentRecRef, DocumentLanguage(Pattern, DocumentRecRef), false, Resolved));
    end;

    internal procedure MaxFileNameLengthInUse(): Integer
    begin
        exit(MaxFileNameLength());
    end;

    /// <summary>
    /// Windows' invalid characters and control characters 1-31 (also invalid on FAT and exFAT), DEL
    /// (rejected by Android's FileUtils.isValidFatFilenameChar), and # and % (reserved in OneDrive
    /// for work or school).
    /// </summary>
    internal procedure RemoveCharsEveryDeviceRejects(Value: Text): Text
    begin
        exit(DelChr(DelChr(Value, '=', InvalidCharsTok), '=', GetControlChars()));
    end;

    // Windows reserves a device name with any extension too (NUL.txt), so only the part before the first period counts.
    local procedure IsReservedName(Value: Text): Boolean
    var
        Reserved: List of [Text];
    begin
        Reserved := ReservedNamesTok.Split(',');
        if StrPos(Value, '.') > 0 then
            Value := CopyStr(Value, 1, StrPos(Value, '.') - 1);
        exit(Reserved.Contains(UpperCase(Value)));
    end;

    local procedure GetControlChars() Chars: Text
    var
        ControlChar: Char;
        i: Integer;
    begin
        // Through a Char so the character is appended, not its digits (which DelChr would then strip).
        for i := 1 to 31 do begin
            ControlChar := i;
            Chars += ControlChar;
        end;
        // DEL, which Android's FileUtils.isValidFatFilenameChar rejects.
        ControlChar := 127;
        Chars += ControlChar;
    end;

    local procedure MaxFileNameLength(): Integer
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        if not ReportFilenameSetup.Get() then
            ReportFilenameSetup.Init();
        exit(ReportFilenameSetup."Max. File Name Length");
    end;

    internal procedure NotifyIfSwitchedOff(): Boolean
    var
        ReportFilenameSetup: Record "Report Filename Setup";
        SwitchedOffNotification: Notification;
    begin
        ReportFilenameSetup.GetSettings();
        if ReportFilenameSetup.Enabled then
            exit(false);

        SwitchedOffNotification.Message(SwitchedOffMsg);
        SwitchedOffNotification.Scope(NotificationScope::LocalScope);
        SwitchedOffNotification.AddAction(OpenSetupLbl, Codeunit::"Report Filename Mgt.", 'OpenSetupFromNotification');
        SwitchedOffNotification.Send();
        exit(true);
    end;

    /// <summary>
    /// Re-sends the notification if patterns are still off, since choosing the action dismissed it.
    /// </summary>
    internal procedure OpenSetupFromNotification(SetupNotification: Notification)
    begin
        Page.RunModal(Page::"Report Filename Setup");
        NotifyIfSwitchedOff();
    end;

    /// <summary>
    /// Checked again after the cut, which can leave a reserved name ("CON - x" becomes CON) or nothing.
    /// </summary>
    /// <returns>The name, or an empty string when nothing usable remains - the pattern then declines.</returns>
    internal procedure FinishName(Value: Text; MaxLength: Integer) Result: Text
    begin
        Result := Sanitise(Value);
        if Result = '' then
            exit('');

        Result := Truncate(Result, MaxLength);
        if Result = '' then
            exit('');
        if IsReservedName(Result) then
            exit('');
    end;

    local procedure TryFinishName(Resolved: Text; var Filename: Text): Boolean
    var
        Finished: Text;
    begin
        Finished := FinishName(Resolved, MaxFileNameLength());
        if Finished = '' then
            exit(false);

        Filename := Finished;
        exit(true);
    end;

    // To Max. File Name Length, then to what every device stores, leaving room for an extension and a number.
    local procedure Truncate(Value: Text; MaxLength: Integer): Text
    begin
        if (MaxLength > 0) and (StrLen(Value) > MaxLength) then
            Value := DelChr(CopyStr(Value, 1, MaxLength), '>', ' .-');
        exit(DelChr(FitToDevices(Value, DeviceNameLimit() - ExtensionReserve()), '>', ' .-'));
    end;

    /// <summary>
    /// Shortens the name, never the ending (extension, or number and extension).
    /// </summary>
    /// <param name="MaxLength">The length of the field the name goes into, or 0 for none.</param>
    internal procedure FitWithEnding(Name: Text; Ending: Text; MaxLength: Integer): Text
    begin
        if (MaxLength > 0) and (StrLen(Name) + StrLen(Ending) > MaxLength) then
            Name := CopyStr(Name, 1, MaxLength - StrLen(Ending));
        exit(FitToDevices(Name, DeviceNameLimit() - DeviceLength(Ending)) + Ending);
    end;

    /// <summary>
    /// Business Central's default document file name, rebuilt from a copy of
    /// Electronic Document Format.GetAttachmentFileName's format: calling it would raise
    /// OnBeforeGetAttachmentFileName and could return another extension's name. Extension lower
    /// case as version 30 writes it (29 wrote upper case). Temporary until ask 8 provides a public
    /// way to read that name without raising the event.
    /// </summary>
    internal procedure BusinessCentralsDocumentFileName(DocumentType: Text; DocumentNo: Code[20]; Extension: Code[3]): Text[250]
    begin
        exit(CopyStr(UncutDocumentFileName(DocumentType, DocumentNo, Extension), 1, 250));
    end;

    local procedure UncutDocumentFileName(DocumentType: Text; DocumentNo: Code[20]; Extension: Code[3]): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        exit(StrSubstNo(DocumentFileNameTok, FileManagement.StripNotsupportChrInFileName(CompanyName()), DocumentType, DocumentNo, LowerCase(Extension)));
    end;

    /// <summary>
    /// Whether a name is still Business Central's default. The extension is compared in either case,
    /// because version 29 writes it upper case and version 30 lower case.
    /// </summary>
    internal procedure IsBusinessCentralsDefaultName(CurrentName: Text; DocumentType: Text; DocumentNo: Code[20]; Extension: Code[3]): Boolean
    var
        WrittenExtension: Text;
    begin
        exit(IsBusinessCentralsDefaultName(CurrentName, DocumentType, DocumentNo, Extension, WrittenExtension));
    end;

    /// <param name="WrittenExtension">Receives the extension as written in the current name, without its dot; blank when the name is not Business Central's or the 250-character cut removed it.</param>
    /// <returns>True when nothing has changed the name since Business Central built it.</returns>
    internal procedure IsBusinessCentralsDefaultName(CurrentName: Text; DocumentType: Text; DocumentNo: Code[20]; Extension: Code[3]; var WrittenExtension: Text): Boolean
    var
        DefaultName: Text;
        StemLength: Integer;
    begin
        WrittenExtension := '';
        if CurrentName = '' then
            exit(false);
        DefaultName := BusinessCentralsDocumentFileName(DocumentType, DocumentNo, Extension);
        if StrLen(CurrentName) <> StrLen(DefaultName) then
            exit(false);

        // Measured on the uncut name, so an extension partly removed by the 250-character cut is
        // still compared in either case.
        StemLength := StrLen(UncutDocumentFileName(DocumentType, DocumentNo, Extension)) - StrLen(Format(Extension));
        if CopyStr(CurrentName, 1, StemLength) <> CopyStr(DefaultName, 1, StemLength) then
            exit(false);
        if StemLength >= StrLen(CurrentName) then
            exit(true);
        if LowerCase(CopyStr(CurrentName, StemLength + 1)) <> CopyStr(DefaultName, StemLength + 1) then
            exit(false);
        WrittenExtension := CopyStr(CurrentName, StemLength + 1);
        exit(true);
    end;

    /// <summary>
    /// File systems allow 255 bytes (ext4) or 255 UTF-16 characters (NTFS, FAT32, exFAT, HFS+
    /// after decomposition), so a character above 127 counts as 4, the most UTF-8 bytes a
    /// character takes. Surrogate pairs are never split.
    /// </summary>
    /// <param name="Limit">How much of the 255 the name may use.</param>
    internal procedure FitToDevices(Value: Text; Limit: Integer): Text
    var
        Used: Integer;
        i: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            Used += DeviceLength(Value[i]);
            if Used > Limit then begin
                Value := CopyStr(Value, 1, i - 1);
                if (StrLen(Value) > 0) and IsFirstOfPair(Value[StrLen(Value)]) then
                    Value := CopyStr(Value, 1, StrLen(Value) - 1);
                exit(Value);
            end;
        end;
        exit(Value);
    end;

    local procedure DeviceLength(Value: Text) Length: Integer
    var
        i: Integer;
    begin
        for i := 1 to StrLen(Value) do
            if Value[i] > 127 then
                Length += 4
            else
                Length += 1;
    end;

    local procedure IsFirstOfPair(Character: Char): Boolean
    begin
        exit((Character >= 55296) and (Character <= 56319));
    end;

    local procedure DeviceNameLimit(): Integer
    begin
        exit(255);
    end;

    // Room for an extension and a number added later, such as " (1).xlsx"; matches Max. File Name Length's ceiling of 245.
    local procedure ExtensionReserve(): Integer
    begin
        exit(10);
    end;
}
