// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Globalization;
using System.Reflection;

table 8125 "Report Filename Pattern"
{
    // Empty on install; with no rows every report keeps Business Central's own file name.

    Caption = 'Report Filename Pattern';
    DataClassification = CustomerContent;
    // Public, so other extensions can add rows. App ID records the inserting extension only when
    // that extension sets it before Insert (see OnInsert).
    Access = Public;
    // Indirect read for the table's own procedures, which naming calls for users with no
    // permission on this table (see Report Filename Mgt.TryResolve).
    Permissions = tabledata "Report Filename Pattern" = r;
    LookupPageId = "Report Filename Patterns";
    DrillDownPageId = "Report Filename Patterns";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            BlankZero = true;
            ToolTip = 'Specifies the ID of the report this pattern applies to. Leave it blank to apply the pattern to every report on the same table.';
            TableRelation = "Report Metadata".ID where(ProcessingOnly = const(false));

            trigger OnValidate()
            begin
                if "Report ID" <> 0 then
                    SuggestFromReport();
            end;
        }
        field(3; "Table No."; Integer)
        {
            Caption = 'Table No.';
            BlankZero = true;
            ToolTip = 'Specifies the number of the table this pattern applies to. Table Caption shows it by name.';
            TableRelation = "Table Metadata".ID;

            trigger OnValidate()
            begin
                // A table that disagrees with the report would never match. Checked here, not
                // only in the lookup, so a value set through Validate from code is checked too.
                CheckReportDecidesWhatItIsAbout();

                if "Table No." <> xRec."Table No." then begin
                    "Language Code Field" := 0;
                    SuggestLanguageField();
                    // The binding holds field numbers of the old table. Rebuilt rather than
                    // cleared, so a pattern that no longer fits errors now.
                    BuildPlaceholderBinding();
                end;
            end;
        }
        field(4; "Table Filter"; Blob)
        {
            Caption = 'Table Filter';
            ToolTip = 'Specifies a filter the records must match for this pattern to apply, such as a reminder level. Leave it blank to apply the pattern to every record in the table.';
        }
        field(23; "Output Route Filter"; Text[250])
        {
            // Enum ordinals joined by |, in the enum's Ordinals() order, so the value is language independent. Blank
            // means every route. Use this table's procedures to set and read it.
            Caption = 'Output Route Filter';
            ToolTip = 'Specifies which ways out of Business Central this pattern applies to, such as Print|Preview. All routes when it is blank. Choose the field to select routes; each one says what produces a file on it.';
        }
        field(6; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language this pattern applies to. Leave it blank to apply the pattern to every language.';
            TableRelation = Language;

            trigger OnValidate()
            begin
                // Without a language field the pattern could only match the fallback language.
                if "Language Code" = '' then
                    exit;
                if "Language Code Field" = 0 then
                    SuggestLanguageField();
                if "Language Code Field" = 0 then
                    Error(NoLanguageFieldErr, "Language Code");
            end;
        }
        field(7; "File Name Pattern"; Text[250])
        {
            Caption = 'File Name Pattern';
            ToolTip = 'Specifies the file name without the extension. Use placeholders in square brackets, such as Invoice-[No.]. The output format adds the extension automatically.';

            trigger OnValidate()
            begin
                BuildPlaceholderBinding();

                // Clearing an enabled pattern turns it off (with a message) rather than being
                // refused, so an administrator can rewrite a pattern from scratch.
                if ("File Name Pattern" = '') and Enabled then begin
                    Enabled := false;
                    if GuiAllowed() then
                        Message(SwitchedOffByClearingMsg);
                end;
            end;
        }
        field(8; "Date Format"; Enum "Report Filename Date Format")
        {
            Caption = 'Date Format';
            ToolTip = 'Specifies how dates are written in the file name.';
        }
        field(10; "Max. Values Named"; Integer)
        {
            // Counts distinct values per placeholder: 100 invoices for two customers list both.
            Caption = 'Max. Values Named';
            InitValue = 3;
            ToolTip = 'Specifies how many different values each placeholder lists when one file covers several records. Repeated values are listed once. Beyond this number, only the first and the last value are named, joined by the range word.';

            trigger OnValidate()
            begin
                if "Max. Values Named" < 1 then
                    Error(MaxValuesErr);
            end;
        }
        field(11; "Separator"; Text[5])
        {
            Caption = 'Separator';
            InitValue = '-';
            ToolTip = 'Specifies the text placed between the records named in one file, when the file covers several records - for example, a report run for a range of invoices or for several customers. A file for a single record never uses it. To put text between two placeholders, type it into the file name pattern.';

            trigger OnValidate()
            var
                ReportFilenameMgt: Codeunit "Report Filename Mgt.";
            begin
                if "Separator" = '' then
                    exit;
                // Not checked as a whole file name: leading and trailing spaces are legal mid-name.
                if not ReportFilenameMgt.IsUsableSeparator("Separator") then
                    Error(SeparatorErr, ReportFilenameMgt.DisallowedCharacters());
            end;
        }
        field(22; "Range Word"; Text[10])
        {
            // A field rather than a label, so each company can set it in its own language.
            Caption = 'Range Word';
            InitValue = 'to';
            ToolTip = 'Specifies the word placed between the first and the last record when a run covers more records than are named one by one, so the name reads 10000-to-99999. It sits between two separators. Leave it blank to join the two with the separator only.';

            trigger OnValidate()
            var
                ReportFilenameMgt: Codeunit "Report Filename Mgt.";
            begin
                if "Range Word" = '' then
                    exit;
                // Checked like the separator: it sits mid-name.
                if not ReportFilenameMgt.IsUsableSeparator("Range Word") then
                    Error(RangeWordErr, ReportFilenameMgt.DisallowedCharacters());
            end;
        }
        field(12; Enabled; Boolean)
        {
            Caption = 'Enabled';
            // A new pattern starts as an inert draft; completeness is checked when it is enabled.
            InitValue = false;
            ToolTip = 'Specifies whether this pattern is used.';

            trigger OnValidate()
            begin
                // Only when enabling, so a half-edited pattern can always be turned off.
                if Enabled then
                    Verify();
            end;
        }
        field(13; "Language Code Field"; Integer)
        {
            Caption = 'Language Code Field';
            BlankZero = true;
            // The pattern card repeats this caption and tooltip. Change them together.
            ToolTip = 'Specifies which field on the table holds the language of the record: a field that relates to the Language table. Where a run covers several records, they must all have the same language, or the run has none. Suggested when the table has one such field.';
            TableRelation = Field."No." where(TableNo = field("Table No."), Class = const(Normal));

            trigger OnValidate()
            begin
                // Only a field related to the Language table holds a language code.
                if "Language Code Field" = 0 then
                    exit;
                if not IsLanguageField("Table No.", "Language Code Field") then
                    Error(NotALanguageFieldErr, FieldCaptionOn("Table No.", "Language Code Field"));
            end;
        }
        field(14; "App ID"; Guid)
        {
            Caption = 'App ID';
            Editable = false;
        }
        field(15; "Placeholder Binding"; Blob)
        {
            // The pattern with each placeholder replaced by its field number or computed key, so nothing is looked
            // up by name at run time. A Blob, because the bound form can exceed 250 characters.
            // Derived data, kept off every page.
            Caption = 'Placeholder Binding';
        }
        field(20; "Table Caption"; Text[250])
        {
            // Caption and tooltip are set here, not on the pages, so the card and list agree.
            Caption = 'Table Caption';
            ToolTip = 'Specifies the table this pattern applies to - the records that one file is named after. It decides which patterns can apply and which fields are offered as placeholders. Choosing a report fills this in. Leave the report blank and choose a table to cover every report on that table.';
            FieldClass = FlowField;
            CalcFormula = lookup("Table Metadata".Caption where(ID = field("Table No.")));
            Editable = false;
        }
        field(21; "Report Name"; Text[250])
        {
            Caption = 'Report Name';
            ToolTip = 'Specifies the report this pattern applies to. Leave it blank to apply the pattern to every report on the same table.';
            FieldClass = FlowField;
            CalcFormula = lookup("Report Metadata".Caption where(ID = field("Report ID")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Selection; Enabled, "Report ID", "Table No.")
        {
        }
        // The list's sort order.
        key(Grouping; "Table No.", "Report ID", "Language Code")
        {
        }
    }

    var
        SeparatorErr: Label 'A separator cannot contain any of the characters %1, because a file name cannot contain them either. Spaces and punctuation are fine.', Comment = '%1 the characters that are not allowed';
        RangeWordErr: Label 'The range word cannot contain any of the characters %1, because a file name cannot contain them either.', Comment = '%1 the characters a file name may not contain';
        FilterPageCaptionLbl: Label 'Which records does this pattern apply to?';
        MaxValuesErr: Label 'Max. Values Named must be at least 1.';
        NothingCompetesMsg: Label 'No other pattern can apply to the same files as %1.', Comment = '%1 the pattern, as its card is titled';
        NoDocumentTypeForFilterErr: Label 'Choose the table this pattern applies to before you set a table filter.';
        NoDocumentTypeForLanguageErr: Label 'Choose the table this pattern applies to first, so its fields can be offered.';
        ReportDecidesErr: Label 'The table is decided by the report this pattern applies to, %1, and cannot be changed - a pattern that disagrees with its own report would never be used. Choose Clear report first if you want the pattern to cover every report on a table.', Comment = '%1 the report';
        NoLanguageFieldErr: Label 'Choose the language code field before you limit this pattern to %1.', Comment = '%1 language code';
        NotALanguageFieldErr: Label '%1 does not hold a language, because it does not relate to the Language table. Choose a field that does, such as Language Code.', Comment = '%1 the caption of the field that was chosen';
        NoLanguageFieldOnTableErr: Label '%1 has no field that holds a language, so this pattern cannot be limited to one.', Comment = '%1 the caption of the table';
        NoPatternToEnableErr: Label 'Enter a file name pattern before you turn this pattern on. A pattern with no file name pattern would name nothing.';
        SwitchedOffByClearingMsg: Label 'The file name pattern is now empty, so this pattern has been turned off. Turn it on again when you have entered a new file name pattern.';
        NoReportOrDocumentTypeErr: Label 'Choose a report or a table before you turn this pattern on. Otherwise it is not clear which files it should name.';
        CaptionSeparatorTok: Label ' · ', Locked = true;
        AllRecordsLbl: Label 'All records';
        AllRoutesLbl: Label 'All routes';
        RouteFilterDamagedErr: Label 'The output route filter of this pattern, %1, cannot be read. Set it again with the lookup beside Output Route Filter.', Comment = '%1 the stored filter';
        RouteSeparatorTok: Label '|', Locked = true;

    trigger OnInsert()
    var
        ModuleInfo: ModuleInfo;
    begin
        // Kept when the inserting code has set it. Otherwise this app's ID: GetCurrentModuleInfo
        // reports the app that contains the running object, which is this table.
        if IsNullGuid("App ID") then begin
            NavApp.GetCurrentModuleInfo(ModuleInfo);
            "App ID" := ModuleInfo.Id();
        end;
    end;

    internal procedure LookupTableFilter()
    var
        TableMetadata: Record "Table Metadata";
        FilterPageBuilder: FilterPageBuilder;
        TableName: Text;
        ExistingView: Text;
    begin
        // Not TestField, whose message quotes the entry number.
        if "Table No." = 0 then
            Error(NoDocumentTypeForFilterErr);
        TableMetadata.Get("Table No.");

        TableName := FilterPageBuilder.AddTable(TableMetadata.Caption, "Table No.");

        ExistingView := GetTableFilterView();
        if ExistingView <> '' then
            FilterPageBuilder.SetView(TableName, ExistingView);

        FilterPageBuilder.PageCaption := FilterPageCaptionLbl;

        if not FilterPageBuilder.RunModal() then
            exit;

        SetTableFilterView(FilterPageBuilder.GetView(TableName, false));
    end;

    local procedure SetTableFilterView(ViewText: Text)
    begin
        WriteTableFilter(ViewText);
        Modify(true);
    end;

    /// <summary>
    /// Sets the filter on the record in memory without saving, for code that builds a row before inserting it.
    /// </summary>
    /// <param name="ViewText">An empty view clears the filter.</param>
    internal procedure WriteTableFilter(ViewText: Text)
    var
        FilterOutStream: OutStream;
    begin
        Clear("Table Filter");
        if ViewText = '' then
            exit;

        "Table Filter".CreateOutStream(FilterOutStream, TextEncoding::UTF8);
        FilterOutStream.WriteText(ViewText);
    end;

    internal procedure GetTableFilterView() ViewText: Text
    var
        FilterInStream: InStream;
    begin
        CalcFields("Table Filter");
        if not "Table Filter".HasValue() then
            exit('');

        "Table Filter".CreateInStream(FilterInStream, TextEncoding::UTF8);
        FilterInStream.ReadText(ViewText);
    end;

    internal procedure HasTableFilter(): Boolean
    begin
        exit(GetTableFilterView() <> '');
    end;

    /// <summary>
    /// The filter as captions and values (GetFilters), not view syntax.
    /// </summary>
    internal procedure GetTableFilterDisplayText(): Text
    var
        FilterRecRef: RecordRef;
        ViewText: Text;
    begin
        ViewText := GetTableFilterView();
        if ViewText = '' then
            exit('');

        if not TryDescribeView("Table No.", ViewText, FilterRecRef) then
            exit('');

        exit(FilterRecRef.GetFilters());
    end;

    /// <summary>
    /// Shared by the card and the list so both show the same text.
    /// </summary>
    internal procedure NoTableFilterText(): Text
    begin
        exit(AllRecordsLbl);
    end;

    /// <summary>
    /// Closing the page with Close returns OK, so the ticks are kept as any page edit is.
    /// </summary>
    internal procedure LookupOutputRouteFilter()
    var
        RoutesPage: Page "Report Filename Routes";
        Routes: List of [Integer];
    begin
        GetOutputRoutes(Routes);
        RoutesPage.SetRoutes(Routes);
        if RoutesPage.RunModal() <> Action::OK then
            exit;

        RoutesPage.GetRoutes(Routes);
        SetOutputRoutes(Routes);
        Modify(true);
    end;

    /// <summary>
    /// Sets the record in memory. No routes, or every route, is stored as blank so routes added
    /// later by other extensions are covered too. Any is never stored.
    /// </summary>
    /// <param name="Routes">Enum ordinals.</param>
    internal procedure SetOutputRoutes(Routes: List of [Integer])
    var
        Ordinal: Integer;
        FilterText: Text;
        EveryRoute: Boolean;
    begin
        EveryRoute := true;
        // In the enum's own order, so the same routes always store the same text.
        foreach Ordinal in Enum::"Report Filename Output Route".Ordinals() do
            if Ordinal <> AnyRouteOrdinal() then
                if Routes.Contains(Ordinal) then begin
                    if FilterText <> '' then
                        FilterText += RouteSeparatorTok;
                    FilterText += Format(Ordinal);
                end else
                    EveryRoute := false;
        if EveryRoute then
            FilterText := '';
        "Output Route Filter" := CopyStr(FilterText, 1, MaxStrLen("Output Route Filter"));
    end;

    /// <param name="Routes">Receives enum ordinals; empty when the pattern applies to every route.</param>
    internal procedure GetOutputRoutes(var Routes: List of [Integer])
    var
        Part: Text;
        Ordinal: Integer;
    begin
        Clear(Routes);
        if "Output Route Filter" = '' then
            exit;
        foreach Part in "Output Route Filter".Split(RouteSeparatorTok) do begin
            // In this app only SetOutputRoutes writes the field, so a part that is not a number is a defect.
            if not Evaluate(Ordinal, Part) then
                Error(RouteFilterDamagedErr, "Output Route Filter");
            Routes.Add(Ordinal);
        end;
    end;

    internal procedure HasOutputRouteFilter(): Boolean
    begin
        exit("Output Route Filter" <> '');
    end;

    /// <summary>
    /// A pattern with no route filter applies to every route, including Any.
    /// </summary>
    internal procedure AppliesToRoute(Route: Enum "Report Filename Output Route"): Boolean
    var
        Routes: List of [Integer];
    begin
        if not HasOutputRouteFilter() then
            exit(true);
        GetOutputRoutes(Routes);
        exit(Routes.Contains(Route.AsInteger()));
    end;

    /// <summary>
    /// Route captions joined by |, or "All routes".
    /// </summary>
    internal procedure OutputRouteFilterText() RouteText: Text
    var
        Routes: List of [Integer];
        Ordinal: Integer;
    begin
        if not HasOutputRouteFilter() then
            exit(AllRoutesLbl);
        GetOutputRoutes(Routes);
        foreach Ordinal in Routes do
            // Skips routes whose extension has been uninstalled.
            if Enum::"Report Filename Output Route".Ordinals().Contains(Ordinal) then begin
                if RouteText <> '' then
                    RouteText += RouteSeparatorTok;
                RouteText += Format(Enum::"Report Filename Output Route".FromInteger(Ordinal));
            end;
    end;

    /// <summary>
    /// The pattern's first route, or Any when it applies to every route.
    /// </summary>
    internal procedure DefaultTestRoute(): Enum "Report Filename Output Route"
    var
        Routes: List of [Integer];
    begin
        GetOutputRoutes(Routes);
        if Routes.Count() = 0 then
            exit(Enum::"Report Filename Output Route"::Any);
        exit(Enum::"Report Filename Output Route".FromInteger(Routes.Get(1)));
    end;

    local procedure SharesARouteWith(var Other: Record "Report Filename Pattern"): Boolean
    var
        Mine: List of [Integer];
        Theirs: List of [Integer];
        Ordinal: Integer;
    begin
        if (not HasOutputRouteFilter()) or (not Other.HasOutputRouteFilter()) then
            exit(true);
        GetOutputRoutes(Mine);
        Other.GetOutputRoutes(Theirs);
        foreach Ordinal in Mine do
            if Theirs.Contains(Ordinal) then
                exit(true);
        exit(false);
    end;

    local procedure AnyRouteOrdinal(): Integer
    begin
        exit(Enum::"Report Filename Output Route"::Any.AsInteger());
    end;

    [TryFunction]
    local procedure TryDescribeView(TableNo: Integer; ViewText: Text; var FilterRecRef: RecordRef)
    begin
        FilterRecRef.Open(TableNo);
        FilterRecRef.SetView(ViewText);
    end;

    /// <summary>
    /// Checks completeness when the pattern is enabled. Explicit errors rather than TestField,
    /// whose message quotes the entry number.
    /// </summary>
    local procedure Verify()
    begin
        if "File Name Pattern" = '' then
            Error(NoPatternToEnableErr);

        if ("Report ID" = 0) and ("Table No." = 0) then
            Error(NoReportOrDocumentTypeErr);
    end;

    /// <summary>
    /// The higher score wins when several patterns apply. Used both by naming and by Priority, so
    /// they cannot disagree. Each criterion has its own power of two; on a tie the pattern
    /// created first wins.
    /// </summary>
    /// <param name="HasTableFilterValue">Passed in to avoid reading the Blob again.</param>
    /// <returns>0 to 31.</returns>
    internal procedure Specificity(HasTableFilterValue: Boolean) Score: Integer
    begin
        if HasTableFilterValue then
            Score += 16;
        if "Report ID" <> 0 then
            Score += 8;
        if "Table No." <> 0 then
            Score += 4;
        if HasOutputRouteFilter() then
            Score += 2;
        if "Language Code" <> '' then
            Score += 1;
    end;

    /// <returns>1 (highest) to 32.</returns>
    internal procedure Priority(): Integer
    begin
        exit(32 - Specificity(HasTableFilter()));
    end;

    /// <summary>
    /// Each criterion is blank on one side or equal on both. Table filters are not compared;
    /// Test Pattern checks real records.
    /// </summary>
    internal procedure CanCompeteWith(var Other: Record "Report Filename Pattern"): Boolean
    begin
        // A draft with neither report nor table would otherwise match everything.
        if not (CouldEverApply() and Other.CouldEverApply()) then
            exit(false);
        if not SameOrBlank("Report ID", Other."Report ID") then
            exit(false);
        if not SameOrBlank("Table No.", Other."Table No.") then
            exit(false);
        if not SharesARouteWith(Other) then
            exit(false);
        if ("Language Code" <> '') and (Other."Language Code" <> '') then
            if "Language Code" <> Other."Language Code" then
                exit(false);
        exit(true);
    end;

    internal procedure HasCompetitor(): Boolean
    var
        Other: Record "Report Filename Pattern";
    begin
        Other.SetFilter("Entry No.", '<>%1', "Entry No.");
        if Other.FindSet() then
            repeat
                if CanCompeteWith(Other) then
                    exit(true);
            until Other.Next() = 0;
        exit(false);
    end;

    internal procedure NothingCompetesMessage(): Text
    begin
        exit(StrSubstNo(NothingCompetesMsg, DisplayCaption()));
    end;

    /// <summary>
    /// Verify requires a report or a table before a pattern can be enabled.
    /// </summary>
    internal procedure CouldEverApply(): Boolean
    begin
        exit(("Report ID" <> 0) or ("Table No." <> 0));
    end;

    local procedure SameOrBlank(Value: Integer; OtherValue: Integer): Boolean
    begin
        exit((Value = 0) or (OtherValue = 0) or (Value = OtherValue));
    end;

    /// <returns>The report, or else the table, followed by the output routes and language when set.</returns>
    internal procedure DisplayCaption() CaptionText: Text
    var
        Pattern: Record "Report Filename Pattern";
    begin
        // On a copy, so CalcFields does not change the caller's record.
        Pattern := Rec;
        Pattern.CalcFields("Report Name", "Table Caption");
        CaptionText := Pattern."Report Name";
        if CaptionText = '' then
            CaptionText := Pattern."Table Caption";
        if CaptionText = '' then
            exit('');
        if HasOutputRouteFilter() then
            CaptionText += CaptionSeparatorTok + OutputRouteFilterText();
        if "Language Code" <> '' then
            CaptionText += CaptionSeparatorTok + "Language Code";
    end;

    /// <summary>
    /// The copy is disabled, as an enabled copy would compete with the original.
    /// </summary>
    internal procedure CopyToNewPattern(var NewPattern: Record "Report Filename Pattern")
    begin
        // CalcFields loads the Blobs' content into the record before TransferFields copies it.
        CalcFields("Table Filter", "Placeholder Binding");
        NewPattern.Init();
        NewPattern.TransferFields(Rec, false);
        NewPattern.Enabled := false;
        // OnInsert sets the App ID again for the copy.
        Clear(NewPattern."App ID");
        NewPattern.Insert(true);
    end;

    /// <summary>
    /// When a report is set, the table must be the report's subject table, or the pattern never matches.
    /// </summary>
    local procedure CheckReportDecidesWhatItIsAbout()
    var
        ReportMetadata: Record "Report Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SubjectTableNo: Integer;
    begin
        if "Report ID" = 0 then
            exit;
        if "Table No." = 0 then
            exit;
        if not ReportMetadata.Get("Report ID") then
            exit;

        // Not always the first data item: see Report Filename Mgt.SubjectTableNo.
        SubjectTableNo := ReportFilenameMgt.SubjectTableNo("Report ID");

        // A report with no record subject constrains nothing.
        if not IsRealTable(SubjectTableNo) then
            exit;
        if SubjectTableNo = "Table No." then
            exit;

        Error(ReportDecidesErr, ReportMetadata.Caption);
    end;

    /// <summary>
    /// False for zero and for system tables (from 2000000000), such as the virtual Integer table.
    /// </summary>
    local procedure IsRealTable(TableNo: Integer): Boolean
    begin
        exit((TableNo > 0) and (TableNo < SystemTableFromTok()));
    end;

    local procedure SystemTableFromTok(): Integer
    begin
        exit(2000000000);
    end;

    internal procedure LookupReport()
    var
        ReportMetadata: Record "Report Metadata";
        ReportLookup: Page "Report Filename Report Lookup";
    begin
        if "Report ID" <> 0 then
            if ReportMetadata.Get("Report ID") then
                ReportLookup.SetRecord(ReportMetadata);
        // With a table and no report, only reports about that table would pass
        // CheckReportDecidesWhatItIsAbout.
        if ("Report ID" = 0) and ("Table No." <> 0) then
            ReportLookup.SetReportsAbout("Table No.");

        ReportLookup.LookupMode(true);
        if ReportLookup.RunModal() <> Action::LookupOK then
            exit;

        ReportLookup.GetRecord(ReportMetadata);
        Validate("Report ID", ReportMetadata.ID);
    end;

    /// <summary>
    /// Keeps the table, so the pattern covers every report on it.
    /// </summary>
    internal procedure ClearReport()
    begin
        if "Report ID" = 0 then
            exit;
        Validate("Report ID", 0);
        BuildPlaceholderBinding();
    end;

    internal procedure LookupTable()
    var
        TableLookup: Page "Report Filename Table Lookup";
    begin
        // Refused before opening the list: with a report set, the table is fixed.
        if "Report ID" <> 0 then
            Error(ReportDecidesErr, "Report Name");

        TableLookup.LookupMode(true);
        if TableLookup.RunModal() <> Action::LookupOK then
            exit;

        Validate("Table No.", TableLookup.ChosenTableNo());
    end;

    internal procedure LookupLanguageCodeField()
    var
        FieldRec: Record Field;
        FieldLookup: Page "Report Filename Field Lookup";
    begin
        if "Table No." = 0 then
            Error(NoDocumentTypeForLanguageErr);

        FieldRec.SetRange(TableNo, "Table No.");
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        // The rule the field's validation enforces.
        FieldRec.SetRange(RelationTableNo, Database::Language);
        if FieldRec.IsEmpty() then
            Error(NoLanguageFieldOnTableErr, TableCaptionOf("Table No."));
        FieldLookup.SetTableView(FieldRec);

        if "Language Code Field" <> 0 then
            if FieldRec.Get("Table No.", "Language Code Field") then
                FieldLookup.SetRecord(FieldRec);

        FieldLookup.LookupMode(true);
        if FieldLookup.RunModal() <> Action::LookupOK then
            exit;

        FieldLookup.GetRecord(FieldRec);
        Validate("Language Code Field", FieldRec."No.");
    end;

    local procedure IsLanguageField(TableNo: Integer; FieldNo: Integer): Boolean
    var
        FieldRec: Record Field;
    begin
        if not FieldRec.Get(TableNo, FieldNo) then
            exit(false);
        exit(FieldRec.RelationTableNo = Database::Language);
    end;

    local procedure FieldCaptionOn(TableNo: Integer; FieldNo: Integer): Text
    var
        FieldRec: Record Field;
    begin
        if not FieldRec.Get(TableNo, FieldNo) then
            exit(Format(FieldNo));
        exit(FieldRec."Field Caption");
    end;

    local procedure TableCaptionOf(TableNo: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if not TableMetadata.Get(TableNo) then
            exit(Format(TableNo));
        exit(TableMetadata.Caption);
    end;

    internal procedure LanguageCodeFieldCaption(): Text
    var
        FieldRec: Record Field;
    begin
        if ("Table No." = 0) or ("Language Code Field" = 0) then
            exit('');
        if not FieldRec.Get("Table No.", "Language Code Field") then
            exit('');
        exit(FieldRec."Field Caption");
    end;

    /// <summary>
    /// Errors on a placeholder that cannot be resolved, while the user who typed it is still there.
    /// </summary>
    local procedure BuildPlaceholderBinding()
    var
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        SetPlaceholderBinding(FilenamePlaceholderMgt.BuildBinding(Rec));
    end;

    internal procedure GetPlaceholderBinding() BindingText: Text
    var
        BindingInStream: InStream;
        Chunk: Text;
    begin
        CalcFields("Placeholder Binding");
        if not "Placeholder Binding".HasValue() then
            exit('');

        "Placeholder Binding".CreateInStream(BindingInStream, TextEncoding::UTF8);
        // ReadText stops at a line break, so read until EOS.
        while not BindingInStream.EOS() do begin
            BindingInStream.ReadText(Chunk);
            BindingText += Chunk;
        end;
    end;

    /// <summary>
    /// Does not modify: it runs during validation, and the caller's insert or modify saves it.
    /// </summary>
    /// <param name="BindingText">Empty clears it.</param>
    local procedure SetPlaceholderBinding(BindingText: Text)
    var
        BindingOutStream: OutStream;
    begin
        Clear("Placeholder Binding");
        if BindingText = '' then
            exit;

        "Placeholder Binding".CreateOutStream(BindingOutStream, TextEncoding::UTF8);
        BindingOutStream.WriteText(BindingText);
    end;

    /// <summary>
    /// Sets the table from the report's subject and suggests a language field.
    /// </summary>
    local procedure SuggestFromReport()
    var
        ReportMetadata: Record "Report Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SubjectTableNo: Integer;
    begin
        if not ReportMetadata.Get("Report ID") then
            exit;

        // The subject, not the first data item: report 910 Posted Assembly Order starts with Integer.
        SubjectTableNo := ReportFilenameMgt.SubjectTableNo("Report ID");

        if not IsRealTable(SubjectTableNo) then begin
            // No record subject: leave the table blank so only computed placeholders are offered.
            "Table No." := 0;
            "Language Code Field" := 0;
            BuildPlaceholderBinding();
            exit;
        end;

        if "Table No." = SubjectTableNo then
            exit;

        "Table No." := SubjectTableNo;
        "Language Code Field" := 0;
        SuggestLanguageField();
        // Assigned, not validated, so the binding is rebuilt here.
        BuildPlaceholderBinding();
    end;

    /// <summary>
    /// Suggests only when the table has exactly one field related to the Language table.
    /// </summary>
    local procedure SuggestLanguageField()
    var
        FieldRec: Record Field;
    begin
        if "Table No." = 0 then
            exit;

        FieldRec.SetRange(TableNo, "Table No.");
        FieldRec.SetRange(RelationTableNo, Database::Language);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Enabled, true);
        if FieldRec.Count() = 1 then begin
            FieldRec.FindFirst();
            "Language Code Field" := FieldRec."No.";
        end;
    end;
}
