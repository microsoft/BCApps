// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Reflection;

codeunit 149509 "Filename Proof Picker"
{
    // Proofs for the placeholder picker, including how long building it takes on a posted sales
    // invoice, whose related tables add their fields to the list.

    trigger OnRun()
    begin
        ProvePickerIsUsable();
    end;

    procedure ProvePickerIsUsable()
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        StartedAt: DateTime;
        ElapsedMs: Integer;
        TotalPlaceholders: Integer;
        OwnFields: Integer;
        RelatedRows: Integer;
        RelatedTables: Integer;
        RelatedFields: Integer;
        Computed: Integer;
        TreeDefectText: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");

        StartedAt := CurrentDateTime();
        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);
        ElapsedMs := CurrentDateTime() - StartedAt;

        // Counted before the per-source counts, which leave a filter on the buffer behind them.
        TempPlaceholderBuffer.Reset();
        TotalPlaceholders := TempPlaceholderBuffer.Count();

        Computed := CountSource(TempPlaceholderBuffer, TempPlaceholderBuffer.Source::Computed);
        OwnFields := CountSource(TempPlaceholderBuffer, TempPlaceholderBuffer.Source::"Record Field");
        RelatedRows := CountSource(TempPlaceholderBuffer, TempPlaceholderBuffer.Source::"Related Field");
        // Table branches and their fields counted apart, so losing either one shows.
        RelatedTables := CountRelatedAtIndentation(TempPlaceholderBuffer, 0);
        RelatedFields := CountRelatedAtIndentation(TempPlaceholderBuffer, 1);

        ProofSupport.LogLine('15 Placeholders offered for a posted sales invoice', Format(TotalPlaceholders));
        ProofSupport.LogLine('15 Of which computed', Format(Computed));
        ProofSupport.LogLine('15 Of which fields on the document', Format(OwnFields));
        ProofSupport.LogLine('15 Of which related tables to expand', Format(RelatedTables));
        ProofSupport.LogLine('15 Of which related fields', Format(RelatedFields));
        ProofSupport.LogLine('15 Time to build the list', Format(ElapsedMs) + MillisecondsTok);

        if (Computed = 0) or (OwnFields = 0) or (RelatedFields = 0) then
            ProofSupport.LogLine('RESULT the picker offers computed, field and related-field placeholders', MissingSourceMsg)
        else
            ProofSupport.LogLine('RESULT the picker offers computed, field and related-field placeholders', PassMsg);

        if RelatedTables + RelatedFields <> RelatedRows then
            ProofSupport.LogLine('RESULT every related row is either a table or a field', StrSubstNo(StrayIndentMsg, RelatedRows - RelatedTables - RelatedFields))
        else
            ProofSupport.LogLine('RESULT every related row is either a table or a field', PassMsg);

        ProveComputedPlaceholdersFollowTheDocument();

        TreeDefectText := TreeDefect(TempPlaceholderBuffer);
        if TreeDefectText <> '' then
            ProofSupport.LogLine('RESULT the placeholder tree holds together in the order it is shown', TreeDefectText)
        else
            ProofSupport.LogLine('RESULT the placeholder tree holds together in the order it is shown',
                StrSubstNo(WellFormedMsg, RelatedTables, RelatedFields));

        if ElapsedMs > BudgetMs() then
            ProofSupport.LogLine('RESULT the picker builds fast enough to open', StrSubstNo(TooSlowMsg, ElapsedMs, BudgetMs()))
        else
            ProofSupport.LogLine('RESULT the picker builds fast enough to open', StrSubstNo(FastEnoughMsg, ElapsedMs, BudgetMs()));

        ProveTheColumnSaysWhatARunOfManyProduces();
        ProveTheTablesOfferedAreWhatReportsAreAbout();
        ProveAReportWithNoDocumentClaimsNoTable();

        FilenameProofLogMgt.Flush();
    end;


    /// <summary>
    /// The picker says what becomes of each placeholder in a run of several records: a field shows
    /// a range, a computed value that cannot speak for many says so, one that can is unchanged.
    /// </summary>
    local procedure ProveTheColumnSaysWhatARunOfManyProduces()
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        FieldRangeSeen: Boolean;
        DeclinerSaysSo: Boolean;
        SpeakerUnchanged: Boolean;
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        FilenamePlaceholderMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);

        TempPlaceholderBuffer.Reset();
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::"Record Field");
        if TempPlaceholderBuffer.FindSet() then
            repeat
                if StrPos(TempPlaceholderBuffer."Over Several Records", RangeMarkerTok) > 0 then
                    FieldRangeSeen := true;
            until TempPlaceholderBuffer.Next() = 0;

        TempPlaceholderBuffer.Reset();
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::Computed);
        if TempPlaceholderBuffer.FindSet() then
            repeat
                if TempPlaceholderBuffer."Over Several Records" = '' then
                    SpeakerUnchanged := SpeakerUnchanged
                else
                    if TempPlaceholderBuffer."Over Several Records" <> TempPlaceholderBuffer.Example then
                        DeclinerSaysSo := true
                    else
                        SpeakerUnchanged := true;
            until TempPlaceholderBuffer.Next() = 0;

        ProofSupport.LogLine('23 A field placeholder over several records',
            StrSubstNo(SeenLbl, FieldRangeSeen));
        ProofSupport.LogLine('23 A computed value that cannot speak for a run says so',
            StrSubstNo(SeenLbl, DeclinerSaysSo));
        ProofSupport.LogLine('23 A computed value that can speak for a run is unchanged',
            StrSubstNo(SeenLbl, SpeakerUnchanged));

        case true of
            not FieldRangeSeen:
                ProofSupport.LogLine('RESULT the picker says what a run of several records produces', NoFieldRangeMsg);
            not DeclinerSaysSo:
                ProofSupport.LogLine('RESULT the picker says what a run of several records produces', NoDeclinerMsg);
            not SpeakerUnchanged:
                ProofSupport.LogLine('RESULT the picker says what a run of several records produces', NoSpeakerMsg);
            else
                ProofSupport.LogLine('RESULT the picker says what a run of several records produces', PassMsg);
        end;
    end;

    /// <summary>
    /// The table list offers only tables some report is about, never a system or virtual table.
    /// </summary>
    local procedure ProveTheTablesOfferedAreWhatReportsAreAbout()
    var
        TempTableBuffer: Record "Report Filename Table Buffer" temporary;
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        SystemTables: Integer;
        WithoutReports: Integer;
        Offered: Integer;
    begin
        FilenamePlaceholderMgt.BuildTables(TempTableBuffer);

        TempTableBuffer.Reset();
        Offered := TempTableBuffer.Count();

        TempTableBuffer.SetFilter("Table No.", '>=%1', SystemTableFromTok());
        SystemTables := TempTableBuffer.Count();

        TempTableBuffer.Reset();
        TempTableBuffer.SetRange("Report Count", 0);
        WithoutReports := TempTableBuffer.Count();

        ProofSupport.LogLine('16 Tables offered', Format(Offered));

        if Offered = 0 then
            ProofSupport.LogLine('RESULT the Tables lookup offers what reports are about', NoTablesMsg)
        else
            if SystemTables > 0 then
                ProofSupport.LogLine('RESULT the Tables lookup offers what reports are about',
                    StrSubstNo(SystemTablesOfferedMsg, SystemTables))
            else
                if WithoutReports > 0 then
                    ProofSupport.LogLine('RESULT the Tables lookup offers what reports are about',
                        StrSubstNo(TablesWithoutReportsMsg, WithoutReports))
                else
                    ProofSupport.LogLine('RESULT the Tables lookup offers what reports are about',
                        StrSubstNo(TablesWellFormedMsg, Offered));
    end;

    /// <summary>
    /// A pattern for a report driven only by its request page claims no table, not the virtual
    /// table it loops over. The report is found through metadata, as installed reports differ.
    /// </summary>
    local procedure ProveAReportWithNoDocumentClaimsNoTable()
    var
        Pattern: Record "Report Filename Pattern";
        ReportMetadata: Record "Report Metadata";
    begin
        ReportMetadata.SetRange(ProcessingOnly, false);
        ReportMetadata.SetFilter(FirstDataItemTableID, '>=%1', SystemTableFromTok());
        if not ReportMetadata.FindFirst() then begin
            ProofSupport.LogLine('RESULT a report with no document behind it claims no table', NoSuchReportMsg);
            exit;
        end;

        ProofSupport.LogLine('16 Report with a system table as its first data item',
            StrSubstNo(ReportAndTableMsg, ReportMetadata.Caption, ReportMetadata.FirstDataItemTableID));

        Pattern.Init();
        Pattern.Validate("Report ID", ReportMetadata.ID);

        if Pattern."Table No." = 0 then
            ProofSupport.LogLine('RESULT a report with no document behind it claims no table',
                StrSubstNo(NoTableClaimedMsg, ReportMetadata.Caption))
        else
            ProofSupport.LogLine('RESULT a report with no document behind it claims no table',
                StrSubstNo(TableClaimedAnywayMsg, ReportMetadata.Caption, Pattern."Table No."));
    end;

    // Stated here, not read from the app, so the proof does not agree with the code by construction.
    local procedure SystemTableFromTok(): Integer
    begin
        exit(2000000000);
    end;

    // What a person will wait for the list to appear; chosen, not measured.
    local procedure BudgetMs(): Integer
    begin
        exit(3000);
    end;

    /// <summary>
    /// Walks the related rows in page order: each table's fields must follow it and nothing else may.
    /// </summary>
    /// <returns>Empty when the tree is well formed, otherwise what is wrong with it.</returns>
    local procedure TreeDefect(var TempPlaceholderBuffer: Record "Report Filename Plh. Buffer"): Text
    var
        SeenGroups: List of [Text];
        CurrentGroup: Text;
        ChildrenInGroup: Integer;
        InsideBranch: Boolean;
    begin
        CurrentGroup := '';
        ChildrenInGroup := 0;
        // Not inferred from the group name: a field sorted ahead of every table has no group either.
        InsideBranch := false;

        TempPlaceholderBuffer.Reset();
        TempPlaceholderBuffer.SetCurrentKey(Source, "Group Name", Indentation, Placeholder);
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::"Related Field");
        if not TempPlaceholderBuffer.FindSet() then
            exit(NoRelatedRowsMsg);

        repeat
            if TempPlaceholderBuffer.IsRelatedTableRow() then begin
                if InsideBranch and (ChildrenInGroup = 0) then
                    exit(StrSubstNo(EmptyBranchMsg, CurrentGroup));
                if SeenGroups.Contains(TempPlaceholderBuffer."Group Name") then
                    exit(StrSubstNo(SplitBranchMsg, TempPlaceholderBuffer."Group Name"));
                SeenGroups.Add(TempPlaceholderBuffer."Group Name");
                CurrentGroup := TempPlaceholderBuffer."Group Name";
                ChildrenInGroup := 0;
                InsideBranch := true;
            end else begin
                if not InsideBranch then
                    exit(StrSubstNo(BeforeAnyBranchMsg, TempPlaceholderBuffer.Placeholder));
                if TempPlaceholderBuffer."Group Name" <> CurrentGroup then
                    exit(StrSubstNo(OrphanFieldMsg, TempPlaceholderBuffer.Placeholder, TempPlaceholderBuffer."Group Name", CurrentGroup));
                ChildrenInGroup += 1;
            end;
        until TempPlaceholderBuffer.Next() = 0;

        if not InsideBranch then
            exit(NoBranchAtAllMsg);
        if ChildrenInGroup = 0 then
            exit(StrSubstNo(EmptyBranchMsg, CurrentGroup));

        exit('');
    end;

    /// <summary>
    /// A computed placeholder is offered only where it can resolve: [Total Incl. VAT] on a posted
    /// sales invoice but not on a customer. Both sides are asserted.
    /// </summary>
    local procedure ProveComputedPlaceholdersFollowTheDocument()
    var
        DocumentPattern: Record "Report Filename Pattern";
        NoTotalPattern: Record "Report Filename Pattern";
        TempDocumentPlaceholders: Record "Report Filename Plh. Buffer" temporary;
        TempNoTotalPlaceholders: Record "Report Filename Plh. Buffer" temporary;
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        TotalPlaceholder: Interface "Report Filename Placeholder";
        KindPlaceholder: Interface "Report Filename Placeholder";
        TotalPlaceholderValue: Enum "Report Filename Placeholder";
        KindPlaceholderValue: Enum "Report Filename Placeholder";
        TotalName: Text;
        KindName: Text;
        OnDocument: Boolean;
        OnCustomer: Boolean;
        KindOnDocument: Boolean;
        KindOnCustomer: Boolean;
    begin
        TotalPlaceholderValue := TotalPlaceholderValue::TotalInclVat;
        TotalPlaceholder := TotalPlaceholderValue;
        TotalName := TotalPlaceholder.DisplayName();

        // The kind of document is offered only on tables GetFullDocumentTypeText has a word for.
        KindPlaceholderValue := KindPlaceholderValue::KindOfDocument;
        KindPlaceholder := KindPlaceholderValue;
        KindName := KindPlaceholder.DisplayName();

        DocumentPattern.Init();
        DocumentPattern.Validate("Table No.", Database::"Sales Invoice Header");
        FilenamePlaceholderMgt.BuildPlaceholders(DocumentPattern, TempDocumentPlaceholders);

        NoTotalPattern.Init();
        NoTotalPattern.Validate("Table No.", Database::Customer);
        FilenamePlaceholderMgt.BuildPlaceholders(NoTotalPattern, TempNoTotalPlaceholders);

        OnDocument := HasComputedPlaceholder(TempDocumentPlaceholders, TotalName);
        OnCustomer := HasComputedPlaceholder(TempNoTotalPlaceholders, TotalName);
        KindOnDocument := HasComputedPlaceholder(TempDocumentPlaceholders, KindName);
        KindOnCustomer := HasComputedPlaceholder(TempNoTotalPlaceholders, KindName);

        ProofSupport.LogLine('15 Computed placeholders offered on a posted sales invoice', Format(CountSource(TempDocumentPlaceholders, TempDocumentPlaceholders.Source::Computed)));
        ProofSupport.LogLine('15 Computed placeholders offered on a customer', Format(CountSource(TempNoTotalPlaceholders, TempNoTotalPlaceholders.Source::Computed)));
        ProofSupport.LogLine('15 ' + TotalName + ' offered on a posted sales invoice', Format(OnDocument));
        ProofSupport.LogLine('15 ' + TotalName + ' offered on a customer', Format(OnCustomer));
        ProofSupport.LogLine('15 ' + KindName + ' offered on a posted sales invoice', Format(KindOnDocument));
        ProofSupport.LogLine('15 ' + KindName + ' offered on a customer', Format(KindOnCustomer));

        case true of
            not (OnDocument and not OnCustomer):
                ProofSupport.LogLine('RESULT a computed placeholder is offered only where it can resolve', StrSubstNo(ApplicabilityMsg, TotalName, OnDocument, OnCustomer));
            not (KindOnDocument and not KindOnCustomer):
                ProofSupport.LogLine('RESULT a computed placeholder is offered only where it can resolve', StrSubstNo(ApplicabilityMsg, KindName, KindOnDocument, KindOnCustomer));
            else
                ProofSupport.LogLine('RESULT a computed placeholder is offered only where it can resolve', PassMsg);
        end;
    end;

    // Matched in brackets, as the picker writes it.
    local procedure HasComputedPlaceholder(var TempPlaceholderBuffer: Record "Report Filename Plh. Buffer"; PlaceholderDisplayName: Text): Boolean
    begin
        TempPlaceholderBuffer.Reset();
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::Computed);
        TempPlaceholderBuffer.SetRange(Placeholder, '[' + PlaceholderDisplayName + ']');
        exit(not TempPlaceholderBuffer.IsEmpty());
    end;

    local procedure CountSource(var TempPlaceholderBuffer: Record "Report Filename Plh. Buffer"; PlaceholderSource: Enum "Report Filename Plh. Source"): Integer
    begin
        TempPlaceholderBuffer.Reset();
        TempPlaceholderBuffer.SetRange(Source, PlaceholderSource);
        exit(TempPlaceholderBuffer.Count());
    end;

    local procedure CountRelatedAtIndentation(var TempPlaceholderBuffer: Record "Report Filename Plh. Buffer"; Indentation: Integer): Integer
    begin
        TempPlaceholderBuffer.Reset();
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::"Related Field");
        TempPlaceholderBuffer.SetRange(Indentation, Indentation);
        exit(TempPlaceholderBuffer.Count());
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        RangeMarkerTok: Label '-to-', Locked = true;
        SeenLbl: Label '%1', Comment = '%1 yes or no', Locked = true;
        NoFieldRangeMsg: Label 'FAIL - no field placeholder says it becomes a first-to-last range when the run covers several records, so the picker still leaves that unsaid.';
        NoDeclinerMsg: Label 'FAIL - the computed value that cannot name a run of several records does not say so; it is offered as though it could.';
        NoSpeakerMsg: Label 'FAIL - no computed value is shown unchanged over a run of several records, so the column is telling every row the same thing.';
        MillisecondsTok: Label ' ms', Locked = true;
        PassMsg: Label 'PASS';
        MissingSourceMsg: Label 'FAIL - computed, field or related-field placeholders are not offered at all.';
        ApplicabilityMsg: Label 'FAIL - %1 should be offered on a posted sales invoice and not on a customer, but it was offered on the invoice = %2 and on the customer = %3.', Comment = '%1 the placeholder name, %2 and %3 whether it was offered';
        FastEnoughMsg: Label 'PASS - %1 ms, within the %2 ms a person will wait', Comment = '%1 measured, %2 budget';
        TooSlowMsg: Label 'FAIL - %1 ms, over the %2 ms a person will wait', Comment = '%1 measured, %2 budget';
        WellFormedMsg: Label 'PASS - %1 tables, each followed by its own fields and nothing else, %2 fields in all', Comment = '%1 related tables, %2 related fields';
        NoRelatedRowsMsg: Label 'FAIL - the list offers nothing one relation away, so there is no tree to check.';
        EmptyBranchMsg: Label 'FAIL - %1 is offered as a table to expand but has no fields under it, so expanding it shows nothing.', Comment = '%1 the related table';
        SplitBranchMsg: Label 'FAIL - %1 appears as a table to expand more than once, so its fields are split across two branches.', Comment = '%1 the related table';
        OrphanFieldMsg: Label 'FAIL - %1 belongs to %2 but is shown under %3, so it sits inside the wrong table.', Comment = '%1 the placeholder, %2 the table it belongs to, %3 the table it was shown under';
        BeforeAnyBranchMsg: Label 'FAIL - %1 is shown before any table has been offered to expand, so it hangs under nothing.', Comment = '%1 the placeholder';
        NoBranchAtAllMsg: Label 'FAIL - not one related table is offered as a branch, so nothing in the list can be expanded.';
        StrayIndentMsg: Label 'FAIL - %1 related rows are neither a table nor a field one relation away.', Comment = '%1 how many rows';
        NoTablesMsg: Label 'FAIL - the Tables lookup is empty, so an administrator cannot say what a pattern applies to.';
        SystemTablesOfferedMsg: Label 'FAIL - %1 of the tables offered are system or virtual tables, which no document can ever be.', Comment = '%1 how many';
        TablesWithoutReportsMsg: Label 'FAIL - %1 of the tables offered have no report about them, so choosing one could never match anything.', Comment = '%1 how many';
        TablesWellFormedMsg: Label 'PASS - %1 tables offered, every one a real table with at least one report about it', Comment = '%1 how many tables';
        NoSuchReportMsg: Label 'FAIL - no installed report has a system table as its first data item, so this cannot be checked in this database.';
        ReportAndTableMsg: Label '%1, first data item table %2', Comment = '%1 the report caption, %2 the table number';
        NoTableClaimedMsg: Label 'PASS - a pattern for %1 is left claiming no table', Comment = '%1 the report caption';
        TableClaimedAnywayMsg: Label 'FAIL - a pattern for %1 claims table %2 as its table, which is a system table.', Comment = '%1 the report caption, %2 the table number';
}
