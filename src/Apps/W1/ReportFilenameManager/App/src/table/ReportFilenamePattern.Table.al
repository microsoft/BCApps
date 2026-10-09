// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 50110 "Report Filename Pattern"
{
    // The table of patterns. Empty on install and until an administrator adds a row, which is what
    // makes the compatibility guarantee real: with no rows, every delivery path falls through to
    // the name Business Central produces today.

    Caption = 'Report Filename Pattern';
    DataClassification = CustomerContent;
    // Public: an extension may add rows of its own, which the App ID field records.
    Access = Public;
    // Naming reads a pattern's placeholder binding and condition through this table's own procedures,
    // for users who hold no permission on it. Report Filename Mgt.TryResolve grants them indirect
    // read for the length of the call, and indirect read is honoured only by an object that
    // declares it - the codeunit declares it for its own reads, and this for the table's.
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
            // Table No. and Table Caption, the pair Business Central itself uses wherever a setup
            // row points at a table - Change Log Setup (Table), Retention Policy Setup and the
            // configuration packages. It was captioned "Applies to", which collides with the
            // Applies-to fields every finance user knows from applying payments to invoices.
            Caption = 'Table No.';
            BlankZero = true;
            ToolTip = 'Specifies the number of the table this pattern applies to. Table Caption shows it by name.';
            TableRelation = "Table Metadata".ID;

            trigger OnValidate()
            begin
                // A report decides what it is about, so the two cannot be set independently.
                // Naming requires BOTH to agree with what is running: a pattern naming report
                // 1306 but claiming to be about customers is rejected on every run, because the
                // document in hand is a sales invoice. It would save without complaint and
                // silently never fire - which is the one failure this design exists to remove.
                // Checked here rather than only in the lookup, so a configuration package or a
                // line of code cannot create what the card refuses.
                CheckReportDecidesWhatItIsAbout();

                if "Table No." <> xRec."Table No." then begin
                    "Language Code Field" := 0;
                    SuggestLanguageField();
                    // A binding holds field numbers of the table it was built against, so one
                    // built for the old table must never survive the table changing. Rebuilt
                    // rather than cleared, so a pattern that no longer fits says so here
                    // instead of declining silently the next time the report runs.
                    BuildPlaceholderBinding();
                end;
            end;
        }
        field(4; "Table Filter"; Blob)
        {
            Caption = 'Table Filter';
            ToolTip = 'Specifies a filter the records must match for this pattern to apply, such as a reminder level. Leave it blank to apply the pattern to every record in the table.';
        }
        // Field 5 was Output Route, one route per pattern. A pattern for Print did not name the
        // same document previewed and then downloaded - that is the Preview route - so naming
        // both took two identical patterns. It is a filter now, field 23.
        field(23; "Output Route Filter"; Text[250])
        {
            // The routes as their enum ordinals joined by |, in ascending order - identities
            // rather than captions, so the filter reads the same whatever language set it, the way
            // the placeholder binding does. Blank means every route. Set and read only through
            // this table's procedures, and shown in words by OutputRouteFilterText.
            Caption = 'Output Route Filter';
            // What produces a file on each route is said beside its tick box on the page the
            // lookup opens (Report Filename Route Buffer.RouteDescription), where the route is
            // chosen; several captions read as synonyms on their own.
            ToolTip = 'Specifies which ways out of Business Central this pattern applies to, such as Print|Preview. All routes when it is blank. Choose the field to select routes; each one says what produces a file on it.';
        }
        field(6; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language this pattern applies to. Leave it blank to apply the pattern to every language.';
            TableRelation = Language;

            trigger OnValidate()
            begin
                // Naming a language with no field to read it from would leave a row that can
                // only ever match the fallback language, which is not what the administrator
                // meant to say.
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
            // Not "Pattern": that is what the whole row is called, so messages had to say "the
            // file name pattern of this pattern" or leave the reader to guess which one was meant.
            Caption = 'File Name Pattern';
            ToolTip = 'Specifies the file name to produce, as text with placeholders in square brackets, such as Invoice-[No.].';

            trigger OnValidate()
            begin
                BuildPlaceholderBinding();

                // A live pattern cannot be nameless. Completeness was checked on the way on and
                // never again, so clearing the text of an enabled pattern left it switched on
                // with nothing to name a file - inert, because selection skips a blank pattern,
                // but reading as live in the list. It is switched off instead, and said out loud:
                // silently changing a setting somebody else can see is its own defect.
                //
                // Switched off rather than refused, because refusing would trap an administrator
                // rewriting a pattern from scratch - clearing the field is the first thing they
                // would do. Base Application guards the same way where a live record has
                // something at stake: Shopify's Shop Card refuses a change to the shop URL while
                // the shop is enabled, and Workflow refuses every change while it is running.
                // A file name has nothing in flight, so the softer guard is the right one.
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
        // Field 9 was Max. Length. One maximum now applies to every pattern, from
        // Report Filename Setup, so two patterns can no longer disagree about how long a name may be.
        field(10; "Max. Records Named"; Integer)
        {
            // Says what is counted. It was "Max. Values" and then "Max. Number Named", and both
            // left the reader to supply the noun - which is records.
            Caption = 'Max. Records Named';
            InitValue = 3;
            ToolTip = 'Specifies how many records are named one by one when one file covers several records. Beyond this number, only the first and the last record are named, joined by the range word, so the file name cannot grow without limit.';

            trigger OnValidate()
            begin
                if "Max. Records Named" < 1 then
                    Error(MaxValuesErr);
            end;
        }
        field(11; "Separator"; Text[5])
        {
            // Bare, because the group it sits in supplies the rest. It was "Value Separator",
            // which read as though it separated one placeholder from the next - which it never
            // has; text typed between two placeholders does that. Under the Multiple Records
            // group, what it separates needs no adjective.
            Caption = 'Separator';
            InitValue = '-';
            ToolTip = 'Specifies the text placed between the records named in one file, when the file covers several records - for example, a report run for a range of invoices or for several customers. A file for a single record never uses it. To put text between two placeholders, type it into the file name pattern.';

            trigger OnValidate()
            var
                ReportFilenameMgt: Codeunit "Report Filename Mgt.";
            begin
                if "Separator" = '' then
                    exit;
                // Judged as a separator, not as a whole file name. Sanitise also trims leading
                // and trailing spaces and periods, because a file name may not begin or end
                // with one - but a separator sits in the middle, where a space is perfectly
                // legal and common: "Invoice - 103001" is what somebody types first. Checking
                // it with the whole-name rule refused " - " and blamed the hyphen.
                if not ReportFilenameMgt.IsUsableSeparator("Separator") then
                    Error(SeparatorErr, ReportFilenameMgt.DisallowedCharacters());
            end;
        }
        field(22; "Range Word"; Text[10])
        {
            // The one word this feature used to put into a file name on its own authority. It
            // was a Label marked Locked, which means never translated, so a Danish company got
            // 10000-to-99999 and had no way to change it. Everything else in a name is either
            // typed by the administrator, read off the records, or a caption Business Central
            // itself translates - this was the only exception, and it is one no longer.
            Caption = 'Range Word';
            InitValue = 'to';
            ToolTip = 'Specifies the word placed between the first and the last record when a run covers more records than are named one by one, so the name reads 10000-to-99999. It sits between two separators. Leave it blank to join the two with the separator only.';

            trigger OnValidate()
            var
                ReportFilenameMgt: Codeunit "Report Filename Mgt.";
            begin
                if "Range Word" = '' then
                    exit;
                // Judged the way the separator is, for the same reason: it sits in the middle of
                // a name, where a space is legal, rather than at either end.
                if not ReportFilenameMgt.IsUsableSeparator("Range Word") then
                    Error(RangeWordErr, ReportFilenameMgt.DisallowedCharacters());
            end;
        }
        field(12; Enabled; Boolean)
        {
            Caption = 'Enabled';
            // Off, so a pattern begins as a draft. The primary key is an auto-incremented
            // entry number, so New always succeeds with nothing filled in - a table keyed on
            // a code field would have forced the administrator to type something. Price List
            // Line is the one setup table in Base Application behind a surrogate key, and it
            // does the same: it tolerates an incomplete row, keeps it inert, and enforces
            // completeness at the moment of activation rather than refusing to create it.
            InitValue = false;
            ToolTip = 'Specifies whether this pattern is used.';

            trigger OnValidate()
            begin
                // Only on the way on. A pattern being switched off needs no completeness -
                // and demanding it would trap an administrator who had half-edited a row.
                if Enabled then
                    Verify();
            end;
        }
        field(13; "Language Code Field"; Integer)
        {
            Caption = 'Language Code Field';
            BlankZero = true;
            // The pattern card shows this field by name through a page variable, which carries
            // this same caption and tooltip word for word. Change them together.
            ToolTip = 'Specifies which field on the table holds the language of the record: a field that relates to the Language table. Where a run covers several records, they must all have the same language, or the run has none. Suggested when the table has one such field.';
            TableRelation = Field."No." where(TableNo = field("Table No."), Class = const(Normal));

            trigger OnValidate()
            begin
                // Only a field that relates to the Language table holds a language. Any other field
                // read as one gives a "language" that is no language at all, and every placeholder
                // that follows the document's language then declines: a test once chose Shopify
                // Order No. here, and [Kind of Document] gave no value for an invoice plainly in
                // English (8 October). Base Application's own rule for a document's language reads
                // such a field on every document it knows (Report Distribution Management.
                // GetDocumentLanguageCode), and of the 90 code and text fields named after a
                // language in Base Application, System Application and the platform, every one on a
                // table a report prints relates to the Language table.
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
            // The canonical form of the pattern: every placeholder replaced by the field number it
            // resolved to when it was saved, so nothing is looked up by name when a report
            // runs. That is what makes a pattern survive a field rename, resolve identically
            // whatever language it was authored in, and fail in front of the person who
            // mistyped a placeholder rather than silently at render time.
            //
            // A Blob rather than a Text[250]: the pattern is capped at 250 characters, but its
            // bound form can be longer once a short caption becomes a longer placeholder.
            // Editable is not a property a Blob accepts. The field is kept off every page
            // instead, which is the stronger guarantee: it is derived data, and there is
            // nothing in it an administrator could usefully change by hand.
            Caption = 'Placeholder Binding';
        }
        field(20; "Table Caption"; Text[250])
        {
            // Captioned here, not on each page, so the card and the list cannot diverge - which
            // they did while each page captioned it itself.
            //
            // Named four times before getting here. "Source Table" was the internal name.
            // "Document type" collided with the Document Type field, whose values are Quote,
            // Order, Invoice, Credit Memo. "Report is about" described a report that did not
            // exist in the one case where a human edits this field. "Applies to" collided with
            // Applies-to Doc. No. and the other Applies-to fields, which to a finance user mean
            // applying a payment to an invoice. Table Caption is what Business Central calls the
            // same thing on its own setup pages, beside Table No.
            Caption = 'Table Caption';
            // The tooltip lives here too, for the same reason the caption does. It is worth
            // stating fully, because this one field decides whether a pattern is used at all and
            // which fields are offered as placeholders.
            ToolTip = 'Specifies the table this pattern applies to - the records that one file is named after. It decides which patterns can apply and which fields are offered as placeholders. Choosing a report fills this in. Leave the report blank and choose a table to cover every report on that table.';
            FieldClass = FlowField;
            CalcFormula = lookup("Table Metadata".Caption where(ID = field("Table No.")));
            Editable = false;
        }
        field(21; "Report Name"; Text[250])
        {
            // Report Name, as the Report Inbox, Report Selections and Custom Report Layouts
            // caption the same lookup. Here, not on each page: the card said one thing and the
            // list another about the same field.
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
        // The order the list opens in: grouped by table, so the patterns that can compete for
        // the same files sit next to each other.
        key(Grouping; "Table No.", "Report ID", "Language Code")
        {
        }
    }

    var
        SeparatorErr: Label 'A separator cannot contain any of the characters %1, because a file name cannot contain them either. Spaces and punctuation are fine.', Comment = '%1 the characters that are not allowed';
        RangeWordErr: Label 'The range word cannot contain any of the characters %1, because a file name cannot contain them either.', Comment = '%1 the characters a file name may not contain';
        FilterPageCaptionLbl: Label 'Which records does this pattern apply to?';
        MaxValuesErr: Label 'Max. Records Named must be at least 1.';
        NothingCompetesMsg: Label 'No other pattern can apply to the same files as %1.', Comment = '%1 the pattern, as its card is titled';
        NoDocumentTypeForFilterErr: Label 'Choose the table this pattern applies to before you set a table filter.';
        NoDocumentTypeForLanguageErr: Label 'Choose the table this pattern applies to first, so its fields can be offered.';
        ReportDecidesErr: Label 'The table is decided by the report this pattern applies to, %1, and cannot be changed - a pattern that disagrees with its own report would never be used. Clear the report first if you want the pattern to cover every report on a table.', Comment = '%1 the report';
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
        // Nothing in the platform stamps the inserting extension, so the code that inserts
        // records it. Rows added by an extension are recognisable by this.
        if IsNullGuid("App ID") then begin
            NavApp.GetCurrentModuleInfo(ModuleInfo);
            "App ID" := ModuleInfo.Id();
        end;
    end;

    /// <summary>
    /// Opens a filter page on the source table so the administrator states the condition by
    /// picking fields and values, rather than writing a filter expression. This is what lets
    /// "a level 3 reminder is named differently" be a row instead of a branch in code.
    /// </summary>
    internal procedure LookupTableFilter()
    var
        TableMetadata: Record "Table Metadata";
        FilterPageBuilder: FilterPageBuilder;
        TableName: Text;
        ExistingView: Text;
    begin
        // Not TestField: its message names the field as the table declares it and quotes the
        // record's entry number, so an administrator is told "Source Table must have a value in
        // Report Filename Pattern: Entry No.=627" about a field the card calls Document type.
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

    /// <summary>
    /// Stores the condition and saves the row. This is the page's path: the filter page has
    /// just been closed, so the row has to end up on disk without the administrator having to
    /// do anything else.
    /// </summary>
    /// <param name="ViewText">The view to store.</param>
    local procedure SetTableFilterView(ViewText: Text)
    begin
        WriteTableFilter(ViewText);
        Modify(true);
    end;

    /// <summary>
    /// Stores the condition on the record in memory, leaving it to the caller's own insert or
    /// modify to persist it. Code that builds a pattern row - a test, or an extension seeding
    /// one - needs this rather than the page's path, which would have to modify a row that
    /// does not exist yet.
    /// </summary>
    /// <param name="ViewText">The view to store. An empty view clears the condition, so a pattern can be widened again.</param>
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

    /// <summary>
    /// The stored condition as a view.
    /// </summary>
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

    /// <summary>
    /// Whether this pattern is narrowed to particular documents.
    /// </summary>
    internal procedure HasTableFilter(): Boolean
    begin
        exit(GetTableFilterView() <> '');
    end;

    /// <summary>
    /// The condition in the words an administrator used, rather than view syntax.
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
    /// The refusal raised when a table filter is set before the table, for the test app to
    /// compare against. A test holding its own copy of the wording breaks whenever the wording
    /// changes and in every language but English; asking for the label does neither.
    /// </summary>
    /// <returns>The message text.</returns>
    internal procedure NoTableForFilterMessage(): Text
    begin
        exit(NoDocumentTypeForFilterErr);
    end;

    /// <summary>
    /// The refusal raised when a pattern with no file name pattern is turned on, for the test
    /// app to compare against.
    /// </summary>
    /// <returns>The message text.</returns>
    internal procedure NoFileNamePatternMessage(): Text
    begin
        exit(NoPatternToEnableErr);
    end;

    /// <summary>
    /// The refusal raised for a separator holding a character a file name cannot contain, for
    /// the test app to compare against.
    /// </summary>
    /// <returns>The message text, with the characters filled in.</returns>
    internal procedure InvalidSeparatorMessage(): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        exit(StrSubstNo(SeparatorErr, ReportFilenameMgt.DisallowedCharacters()));
    end;

    /// <summary>
    /// What the card and the list show for a pattern with no table filter. One place, because the
    /// card said "Every record of this kind" while the list showed nothing for the same row.
    /// </summary>
    /// <returns>The text for an empty table filter.</returns>
    internal procedure NoTableFilterText(): Text
    begin
        exit(AllRecordsLbl);
    end;

    /// <summary>
    /// Opens the routes with a tick box each, ticked where the pattern already applies, and stores
    /// what was ticked when the page closes. The page offers only Close, and Close and Esc both
    /// return OK (measured in the client, 7 October), so what is ticked is kept as any edit on a
    /// page is. Nothing ticked, or every route ticked, is stored as blank: every route.
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
    /// Limits this pattern to these routes, on the record in memory; an empty list applies it to
    /// every route, and so does a list holding every route - stored as blank, so a route another
    /// extension adds later is covered too, as the administrator meant. Any is not a route of its
    /// own - it is what a delivery is when the platform does not say - so it is never stored.
    /// </summary>
    /// <param name="Routes">The routes, as enum ordinals.</param>
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

    /// <summary>
    /// The routes this pattern is limited to, as enum ordinals; empty when it applies to every route.
    /// </summary>
    /// <param name="Routes">Receives the routes.</param>
    internal procedure GetOutputRoutes(var Routes: List of [Integer])
    var
        Part: Text;
        Ordinal: Integer;
    begin
        Clear(Routes);
        if "Output Route Filter" = '' then
            exit;
        foreach Part in "Output Route Filter".Split(RouteSeparatorTok) do begin
            // Only this table writes the field, so a part that is not a number is a defect.
            if not Evaluate(Ordinal, Part) then
                Error(RouteFilterDamagedErr, "Output Route Filter");
            Routes.Add(Ordinal);
        end;
    end;

    /// <summary>
    /// Whether this pattern is limited to some routes.
    /// </summary>
    internal procedure HasOutputRouteFilter(): Boolean
    begin
        exit("Output Route Filter" <> '');
    end;

    /// <summary>
    /// Whether this pattern applies to a delivery by this route. A pattern with no route filter
    /// applies to every route, including one the platform does not name.
    /// </summary>
    /// <param name="Route">The delivery's route.</param>
    /// <returns>True when the pattern applies.</returns>
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
    /// The routes in words, as the card and the list show them: their captions joined by |, the
    /// way a filter reads; for a pattern with none, that it applies to every route.
    /// </summary>
    /// <returns>The text.</returns>
    internal procedure OutputRouteFilterText() RouteText: Text
    var
        Routes: List of [Integer];
        Ordinal: Integer;
    begin
        if not HasOutputRouteFilter() then
            exit(AllRoutesLbl);
        GetOutputRoutes(Routes);
        foreach Ordinal in Routes do
            // A route an extension added and then took away has no caption left to show.
            if Enum::"Report Filename Output Route".Ordinals().Contains(Ordinal) then begin
                if RouteText <> '' then
                    RouteText += RouteSeparatorTok;
                RouteText += Format(Enum::"Report Filename Output Route".FromInteger(Ordinal));
            end;
    end;

    /// <summary>
    /// What the card and the list show for a pattern with no route filter, for tests to compare with.
    /// </summary>
    /// <returns>The text.</returns>
    internal procedure NoOutputRouteFilterText(): Text
    begin
        exit(AllRoutesLbl);
    end;

    /// <summary>
    /// The route Test Pattern starts from: the first this pattern is limited to, or Any for a
    /// pattern that applies to every route.
    /// </summary>
    /// <returns>The route.</returns>
    internal procedure DefaultTestRoute(): Enum "Report Filename Output Route"
    var
        Routes: List of [Integer];
    begin
        GetOutputRoutes(Routes);
        if Routes.Count() = 0 then
            exit(Enum::"Report Filename Output Route"::Any);
        exit(Enum::"Report Filename Output Route".FromInteger(Routes.Get(1)));
    end;

    /// <summary>
    /// Whether this pattern and another can be used for at least one route in common.
    /// </summary>
    /// <param name="Other">The pattern to compare with.</param>
    /// <returns>True when a route is open to both.</returns>
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
    /// Insists a pattern is complete enough to be used, at the moment it is switched on. This
    /// is Price List Line's rule: an incomplete row is allowed to exist as a draft, is inert
    /// while it is one, and is checked when somebody activates it.
    ///
    /// Explicit errors rather than TestField. TestField names the field as the table declares
    /// it and quotes the record's key, so it would tell an administrator that "Source Table
    /// must have a value in Report Filename Pattern: Entry No.=726" about a field the card
    /// calls Document type - and the entry number is a surrogate they have never been shown.
    /// </summary>
    local procedure Verify()
    begin
        if "File Name Pattern" = '' then
            Error(NoPatternToEnableErr);

        // Either is enough. A pattern tied to one report names that report's document; a
        // pattern tied only to a table names every report on that table.
        if ("Report ID" = 0) and ("Table No." = 0) then
            Error(NoReportOrDocumentTypeErr);
    end;

    /// <summary>
    /// How specific this pattern is, which is what decides between two patterns that both
    /// apply to the same file: the higher number wins.
    ///
    /// The one definition of the rule. Report Filename Mgt. scores every candidate with this when
    /// a report runs, and the list shows it as Priority, so what the administrator reads and
    /// what naming does cannot drift apart.
    ///
    /// Each criterion has its own power of two, so the score says exactly which criteria are
    /// set. Two patterns can therefore only tie when they set the same criteria - and when both
    /// match the same file, those criteria hold the same values, so they differ only in the table
    /// filter. The selection then keeps the first it reads, which is the one created first.
    /// </summary>
    /// <param name="HasTableFilterValue">Whether this pattern has a table filter. Passed in because the caller has usually just read it, and reading it means reading a Blob.</param>
    /// <returns>The specificity, 0 to 31.</returns>
    internal procedure Specificity(HasTableFilterValue: Boolean) Score: Integer
    begin
        // The condition on the records is the most specific thing a pattern can say, so a row for
        // level 3 reminders beats the row for all of them.
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

    /// <summary>
    /// The specificity turned into a priority, where 1 is the highest - the way Business Central's
    /// Payment Application Rules number theirs.
    /// </summary>
    /// <returns>The priority, 1 to 32.</returns>
    internal procedure Priority(): Integer
    begin
        exit(32 - Specificity(HasTableFilter()));
    end;

    /// <summary>
    /// Whether this pattern and another could both apply to the same file, judged from their
    /// criteria alone. Each criterion either is blank on one of them, or holds the same value on
    /// both. Table filters are not compared: two filters may or may not select the same records,
    /// and only running the report against real records can say which - which is Test Pattern's
    /// job, not this one's.
    /// </summary>
    /// <param name="Other">The pattern to compare with.</param>
    /// <returns>True when both could apply to one file.</returns>
    internal procedure CanCompeteWith(var Other: Record "Report Filename Pattern"): Boolean
    begin
        // A pattern with neither a report nor a table can never be turned on (Verify), so it can
        // never apply to any file. Judged by its blank criteria alone it would match everything:
        // found in the container client on 8 October, a draft left by New was listed as
        // overlapping every pattern, and a pattern nothing competes with no longer said so.
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

    /// <summary>
    /// Whether any other pattern could apply to the same files as this one (CanCompeteWith).
    /// </summary>
    /// <returns>True when at least one other pattern could.</returns>
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

    /// <summary>
    /// What Show Overlapping Patterns says when no other pattern could apply to the same files.
    /// </summary>
    internal procedure NothingCompetesMessage(): Text
    begin
        exit(StrSubstNo(NothingCompetesMsg, DisplayCaption()));
    end;

    /// <summary>
    /// Whether this pattern names a report or a table - what Verify requires before it can be turned
    /// on, so the only patterns that could ever apply to a file.
    /// </summary>
    internal procedure CouldEverApply(): Boolean
    begin
        exit(("Report ID" <> 0) or ("Table No." <> 0));
    end;

    local procedure SameOrBlank(Value: Integer; OtherValue: Integer): Boolean
    begin
        exit((Value = 0) or (OtherValue = 0) or (Value = OtherValue));
    end;

    /// <summary>
    /// A title for the card: what the pattern applies to, in the words the card itself uses.
    /// The entry number would be a counter that means nothing to an administrator.
    /// </summary>
    /// <returns>The report, or else the table, followed by the output routes and language when set.</returns>
    internal procedure DisplayCaption() CaptionText: Text
    var
        Pattern: Record "Report Filename Pattern";
    begin
        // Worked out on a copy, so that a page asking for its title does not change the record it
        // shows: calculating FlowFields on the page's own record is a change the client notices.
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
    /// Inserts a copy of this pattern, turned off, and hands it back. Turned off so that the copy
    /// changes nothing until the administrator has made it say something different - an enabled
    /// copy would be an exact rival of the pattern it came from.
    /// </summary>
    /// <param name="NewPattern">Receives the inserted copy.</param>
    internal procedure CopyToNewPattern(var NewPattern: Record "Report Filename Pattern")
    begin
        // Blobs travel with TransferFields only once they have been read.
        CalcFields("Table Filter", "Placeholder Binding");
        NewPattern.Init();
        NewPattern.TransferFields(Rec, false);
        NewPattern.Enabled := false;
        // The inserting extension is recorded again, by OnInsert, for the copy.
        Clear(NewPattern."App ID");
        NewPattern.Insert(true);
    end;

    /// <summary>
    /// Insists that what a pattern says it is about agrees with the report it names.
    ///
    /// A report's first data item IS what it is about, so when a report is named the answer is
    /// already settled and any other answer produces a pattern that can never match. Nothing
    /// stops the two being set independently otherwise: naming a report and then claiming a
    /// different kind of record saved happily and then declined on every single run.
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

        // What the run is about, which is not always the report's first data item - for 35 of
        // the 901 reports installed that first item is a virtual table and the real subject is
        // its child. See the manager, which owns the rule.
        SubjectTableNo := ReportFilenameMgt.SubjectTableNo("Report ID");

        // Nothing is decided when the run is about no record at all, so nothing is refused.
        if not IsRealTable(SubjectTableNo) then
            exit;
        if SubjectTableNo = "Table No." then
            exit;

        Error(ReportDecidesErr, ReportMetadata.Caption);
    end;

    /// <summary>
    /// Whether a table number names a kind of record a file can be named after.
    ///
    /// Business Central's system and virtual tables start at 2,000,000,000, and a report whose
    /// first data item is one of those - the virtual Integer table, most often, which is how a
    /// report driven entirely by its request page is written - is a report with no document
    /// behind it. Thirty-nine of the reports installed in the test container are like that.
    /// </summary>
    /// <param name="TableNo">The table number to judge.</param>
    /// <returns>True when it is a real kind of record.</returns>
    local procedure IsRealTable(TableNo: Integer): Boolean
    begin
        exit((TableNo > 0) and (TableNo < SystemTableFromTok()));
    end;

    /// <summary>
    /// The first table number Business Central reserves for system and virtual tables.
    /// </summary>
    /// <returns>The lowest system table number.</returns>
    local procedure SystemTableFromTok(): Integer
    begin
        exit(2000000000);
    end;

    /// <summary>
    /// Picks the report this pattern applies to, by name. Clearing the choice widens the
    /// pattern to every report, which is what a blank criterion means everywhere in this
    /// design.
    /// </summary>
    internal procedure LookupReport()
    var
        ReportMetadata: Record "Report Metadata";
        ReportLookup: Page "Report Filename Report Lookup";
    begin
        if "Report ID" <> 0 then
            if ReportMetadata.Get("Report ID") then
                ReportLookup.SetRecord(ReportMetadata);
        // A pattern that already names a table and no report accepts only a report about that
        // table (CheckReportDecidesWhatItIsAbout refuses any other), so only those are offered. Once a report is
        // set, the table follows from it and the whole list is offered again.
        if ("Report ID" = 0) and ("Table No." <> 0) then
            ReportLookup.SetReportsAbout("Table No.");

        ReportLookup.LookupMode(true);
        if ReportLookup.RunModal() <> Action::LookupOK then
            exit;

        ReportLookup.GetRecord(ReportMetadata);
        Validate("Report ID", ReportMetadata.ID);
    end;

    /// <summary>
    /// Picks the document type, by name, for a pattern that covers every report naming that
    /// kind of document.
    /// </summary>
    internal procedure LookupTable()
    var
        TableLookup: Page "Report Filename Table Lookup";
    begin
        // Refused outright rather than offered and then rejected on save. Choosing from a list
        // of several hundred kinds, only to be told the one thing you are allowed is the one
        // already filled in, is worse than not opening the list.
        if "Report ID" <> 0 then
            Error(ReportDecidesErr, "Report Name");

        // The list builds itself from report metadata, so there is no record to position it on
        // beforehand - and nothing is lost by that: the list is short enough to find a name in.
        TableLookup.LookupMode(true);
        if TableLookup.RunModal() <> Action::LookupOK then
            exit;

        Validate("Table No.", TableLookup.ChosenTableNo());
    end;

    /// <summary>
    /// Picks which field holds the document's language, by caption, from the fields of this
    /// pattern's own source table.
    /// </summary>
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
        // Only the fields that hold a language - those that relate to the Language table. Offering
        // every code and text field let a field such as Shopify Order No. be chosen, which the
        // field's own validation now refuses.
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

    /// <summary>
    /// Whether a field of a table holds a language: whether it relates to the Language table.
    /// </summary>
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

    /// <summary>
    /// The refusal raised when a field that does not hold a language is chosen as the language
    /// code field, for the test that checks it.
    /// </summary>
    /// <param name="FieldCaptionText">The caption of the field that was chosen.</param>
    internal procedure NotALanguageFieldMessage(FieldCaptionText: Text): Text
    begin
        exit(StrSubstNo(NotALanguageFieldErr, FieldCaptionText));
    end;

    /// <summary>
    /// The refusal raised when the language code field is looked up on a table with no field that
    /// holds a language, for the test that checks it.
    /// </summary>
    /// <param name="TableCaptionText">The caption of the table.</param>
    internal procedure NoLanguageFieldOnTableMessage(TableCaptionText: Text): Text
    begin
        exit(StrSubstNo(NoLanguageFieldOnTableErr, TableCaptionText));
    end;

    /// <summary>
    /// The caption of the field currently chosen as holding the document's language, so the
    /// card can show a name where it stores a number.
    /// </summary>
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
    /// Rebuilds the canonical binding from the pattern text. Raises an error naming the placeholder
    /// when one cannot be resolved, which is the point of the field: the person who mistyped
    /// it is still on the screen.
    /// </summary>
    local procedure BuildPlaceholderBinding()
    var
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        SetPlaceholderBinding(FilenamePlaceholderMgt.BuildBinding(Rec));
    end;

    /// <summary>
    /// The canonical binding, as the manager reads it when a report runs.
    /// </summary>
    internal procedure GetPlaceholderBinding() BindingText: Text
    var
        BindingInStream: InStream;
        Chunk: Text;
    begin
        CalcFields("Placeholder Binding");
        if not "Placeholder Binding".HasValue() then
            exit('');

        "Placeholder Binding".CreateInStream(BindingInStream, TextEncoding::UTF8);
        // Read in chunks rather than once: ReadText stops at a line break, and a pattern
        // pasted with one in it would otherwise bind only as far as the break.
        while not BindingInStream.EOS() do begin
            BindingInStream.ReadText(Chunk);
            BindingText += Chunk;
        end;
    end;

    /// <summary>
    /// Stores the binding on the record in memory. Deliberately does not modify: the binding
    /// is built during validation, so the insert or modify the caller is already performing
    /// is what persists it.
    /// </summary>
    /// <param name="BindingText">The binding to store. Empty clears it.</param>
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
    /// Fills in the source table from the report, using the deterministic report-to-table
    /// link in report metadata, and suggests a language field for that table.
    /// </summary>
    local procedure SuggestFromReport()
    var
        ReportMetadata: Record "Report Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SubjectTableNo: Integer;
    begin
        if not ReportMetadata.Get("Report ID") then
            exit;

        // The subject rather than the first data item. Report 910 Posted Assembly Order is the
        // clearest case: its first data item is the virtual Integer table, so this used to leave
        // the pattern claiming no kind of record and offering no field placeholders, for a report that
        // is plainly about a posted assembly order.
        SubjectTableNo := ReportFilenameMgt.SubjectTableNo("Report ID");

        if not IsRealTable(SubjectTableNo) then begin
            // The report has no document behind it - its first data item is a system table, as
            // it is for a report driven entirely by its request page. There is no kind of record
            // to fill in, and saying Integer would be worse than saying nothing: the pattern
            // would then only match a document that is an Integer, which no delivery produces.
            // Left empty, the pattern is one that uses only the computed values, which is
            // exactly what such a report can supply.
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
        // The table is assigned here rather than validated, so the binding has to be rebuilt
        // for the new table the same way field 3's own validation does it.
        BuildPlaceholderBinding();
    end;

    /// <summary>
    /// Offers the field that points at the Language table, when the source table has exactly
    /// one. A suggestion rather than a rule - a table with two such fields, or none, is left
    /// for the administrator to settle.
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
