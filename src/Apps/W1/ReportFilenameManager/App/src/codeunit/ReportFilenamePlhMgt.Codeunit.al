// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50114 "Report Filename Plh. Mgt."
{
    // Derives what an administrator may choose from, entirely from compiled metadata:
    //   report            -> the run's subject: Report Metadata.FirstDataItemTableID when that
    //                        is a real table, else the shallowest real Report Data Items entry
    //   record fields     -> Field, excluding FlowFilters, which hold no value on a record
    //   filter placeholders     -> Report Data Items."Request Filter Fields"
    // No list is written by hand, nothing is learned from previous runs, and the result is
    // identical in an empty database and in a ten-year-old company.

    Access = Internal;

    /// <summary>
    /// Fills the buffer with every placeholder the pattern's report and table can supply.
    /// </summary>
    /// <param name="Pattern">The pattern being edited.</param>
    /// <param name="PlaceholderBuffer">Receives the available placeholders.</param>
    internal procedure BuildPlaceholders(var Pattern: Record "Report Filename Pattern"; var PlaceholderBuffer: Record "Report Filename Plh. Buffer")
    begin
        NextEntryNo := 0;

        AddComputedPlaceholders(Pattern, PlaceholderBuffer);

        if Pattern."Table No." <> 0 then begin
            AddRecordFieldPlaceholders(Pattern, PlaceholderBuffer);
            AddRelatedFieldPlaceholders(Pattern, PlaceholderBuffer);
        end;

        if Pattern."Report ID" <> 0 then
            AddFilterPlaceholders(Pattern, PlaceholderBuffer);
    end;

    /// <summary>
    /// The kinds of record that reports are actually about, each with how many reports are about
    /// it. Derived from every non-processing report's first data item - the same thing the card
    /// fills in when a report is chosen - so the lookup can only offer a choice that could
    /// really match something.
    ///
    /// The run's subject and not every table the report touches: a name is decided where only
    /// the primary data item is in scope, which is why that is the one a pattern binds to. For
    /// most reports the subject IS the first data item; where that is a virtual table, the
    /// subject is the shallowest real one. The manager owns that rule.
    /// </summary>
    /// <param name="TableBuffer">Receives one row per kind of record.</param>
    internal procedure BuildTables(var TableBuffer: Record "Report Filename Table Buffer")
    var
        ReportMetadata: Record "Report Metadata";
        TableMetadata: Record "Table Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        TableBuffer.Reset();
        TableBuffer.DeleteAll();

        ReportMetadata.SetRange(ProcessingOnly, false);

        // Two passes, because the subject of a run is not always its first data item and only
        // one of the two cases can be filtered in the database.
        //
        // First the reports whose first data item is already a real table - 786 of the 901
        // installed - which the database can select outright.
        //
        // Asked through the manager rather than read straight off the row, because for one
        // report the two differ: report 25 renders every financial report there is, and its
        // first data item names the row definition rather than the financial report. Reading
        // the row directly here is what left Financial Report out of the list an administrator
        // chooses from, so report 25 could be named by nothing they could set up.
        ReportMetadata.SetFilter(FirstDataItemTableID, '>%1&<%2', 0, SystemTableFrom());
        if ReportMetadata.FindSet() then
            repeat
                CountTable(TableBuffer, TableMetadata, ReportFilenameMgt.SubjectTableNo(ReportMetadata));
            until ReportMetadata.Next() = 0;

        // Then the ones whose first data item is a system or virtual table. Most are reports
        // driven entirely by their request page, which are about no record and contribute
        // nothing - but 35 of them hide a real subject one or two data items in, and leaving
        // those out is what kept report 910 Posted Assembly Order from offering a kind of
        // record at all. Only this handful pays for the extra metadata read.
        ReportMetadata.SetFilter(FirstDataItemTableID, '%1|>=%2', 0, SystemTableFrom());
        if ReportMetadata.FindSet() then
            repeat
                CountTable(TableBuffer, TableMetadata, ReportFilenameMgt.SubjectTableNo(ReportMetadata.ID));
            until ReportMetadata.Next() = 0;
    end;

    /// <summary>
    /// Records one more report as being about a kind of record. A table with no caption of its
    /// own is skipped: it would be offered as a blank line, and a blank line is not a choice.
    /// </summary>
    /// <param name="TableBuffer">The list being built.</param>
    /// <param name="TableMetadata">A metadata record to read the caption through.</param>
    /// <param name="TableNo">The kind of record, or zero when the run is about none.</param>
    local procedure CountTable(var TableBuffer: Record "Report Filename Table Buffer"; var TableMetadata: Record "Table Metadata"; TableNo: Integer)
    begin
        if (TableNo <= 0) or (TableNo >= SystemTableFrom()) then
            exit;

        if TableBuffer.Get(TableNo) then begin
            TableBuffer."Report Count" += 1;
            TableBuffer.Modify();
            exit;
        end;

        if not TableMetadata.Get(TableNo) then
            exit;
        if TableMetadata.Caption = '' then
            exit;

        TableBuffer.Init();
        TableBuffer."Table No." := TableNo;
        TableBuffer."Table Caption" := CopyStr(TableMetadata.Caption, 1, MaxStrLen(TableBuffer."Table Caption"));
        TableBuffer."Report Count" := 1;
        TableBuffer.Insert();
    end;

    /// <summary>
    /// What a field placeholder produces when the run covers several records: a first-to-last range,
    /// exactly as the resolver renders one.
    ///
    /// Every field placeholder collapses this way, on every report. That is the point the picker used
    /// to leave unsaid: [No.] looks perfectly reasonable on a chart of accounts, it resolves,
    /// and what it resolves to is a range - which nothing on the screen admitted. Saying it here
    /// is better than withholding the placeholder, because the placeholder is not wrong; it was only
    /// undescribed.
    /// </summary>
    /// <param name="Pattern">The pattern being edited, which carries the separator.</param>
    /// <param name="FieldRec">The field the placeholder reads.</param>
    /// <returns>The collapsed form, or blank when the field has no shape.</returns>
    local procedure CollapsedShapeOf(var Pattern: Record "Report Filename Pattern"; var FieldRec: Record Field): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FirstShape: Text;
        LastShape: Text;
    begin
        FirstShape := ShapeOfValue(Pattern, FieldRec, false);
        if FirstShape = '' then
            exit('');

        LastShape := ShapeOfValue(Pattern, FieldRec, true);

        // A field whose shape is its own name - a text field - reads the same at both ends of
        // any range, so showing it twice would say nothing. The single shape is the honest
        // answer there.
        if LastShape = FirstShape then
            exit(FirstShape);

        // Joined exactly as a real name is, with the pattern's own separator and range word. It
        // used a fixed English 'to' here, so the list could show a different word from the
        // example on the card and from the file itself.
        exit(FirstShape + ReportFilenameMgt.RangeJoinOf(Pattern) + LastShape);
    end;

    /// <summary>
    /// What a computed placeholder produces when the run covers several records. Most are one value
    /// for the whole run and are unchanged; the one that is not says so in words rather than
    /// being quietly withheld, because withholding it would leave an administrator wondering
    /// where it had gone.
    /// </summary>
    /// <param name="Pattern">The pattern being edited.</param>
    /// <param name="PlaceholderImplementation">The computed value.</param>
    /// <returns>What it produces over a run of many records.</returns>
    local procedure OverManyForComputed(var Pattern: Record "Report Filename Pattern"; PlaceholderImplementation: Interface "Report Filename Placeholder"): Text
    begin
        if PlaceholderImplementation.SpeaksForARunOfManyRecords() then
            exit(ComputedExample(Pattern, PlaceholderImplementation));
        exit(CannotNameARunMsg);
    end;

    /// <summary>
    /// The first table number Business Central reserves for system and virtual tables. Anything
    /// at or above it is machinery rather than a record a file could be named after.
    /// </summary>
    /// <returns>The lowest system table number.</returns>
    local procedure SystemTableFrom(): Integer
    begin
        exit(2000000000);
    end;

    /// <summary>
    /// Says in plain words what the list is derived from, including the case where a report
    /// has no document behind it.
    /// </summary>
    /// <param name="Pattern">The pattern being edited.</param>
    /// <returns>A sentence for the administrator.</returns>
    internal procedure DescribeScope(var Pattern: Record "Report Filename Pattern"): Text
    var
        ReportMetadata: Record "Report Metadata";
        TableMetadata: Record "Table Metadata";
    begin
        if (Pattern."Report ID" = 0) and (Pattern."Table No." = 0) then
            exit(AnyReportAnyTableMsg);

        if Pattern."Table No." = 0 then begin
            if ReportMetadata.Get(Pattern."Report ID") then
                exit(StrSubstNo(NoDocumentMsg, ReportMetadata.Caption));
            exit(AnyReportAnyTableMsg);
        end;

        if not TableMetadata.Get(Pattern."Table No.") then
            exit(AnyReportAnyTableMsg);

        if ReportMetadata.Get(Pattern."Report ID") then
            exit(StrSubstNo(ReportAndTableMsg, ReportMetadata.Caption, TableMetadata.Caption));

        exit(StrSubstNo(TableOnlyMsg, TableMetadata.Caption));
    end;

    /// <summary>
    /// Turns the pattern text into its canonical binding: every placeholder replaced by the field
    /// number it resolves to, or by the canonical name of the value it computes. Raises an
    /// error naming any placeholder that resolves to nothing, so a mistyped placeholder is refused while
    /// the person who typed it is still looking at it.
    /// </summary>
    /// <param name="Pattern">The pattern whose text is being bound.</param>
    /// <returns>The binding, or an empty string when the pattern has no text.</returns>
    internal procedure BuildBinding(var Pattern: Record "Report Filename Pattern") Binding: Text
    var
        Remaining: Text;
        PlaceholderName: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        Remaining := Pattern."File Name Pattern";
        if Remaining = '' then
            exit('');

        while StrPos(Remaining, PlaceholderStartTok) > 0 do begin
            StartPos := StrPos(Remaining, PlaceholderStartTok);
            // Searched from the opening bracket, so a literal closing bracket earlier in the
            // text cannot make a well-formed placeholder look unterminated.
            EndPos := StrPos(CopyStr(Remaining, StartPos), PlaceholderEndTok);
            if EndPos = 0 then
                Error(UnterminatedPlaceholderErr, CopyStr(Remaining, StartPos));
            EndPos += StartPos - 1;

            Binding += EscapeLiteral(CopyStr(Remaining, 1, StartPos - 1));
            PlaceholderName := CopyStr(Remaining, StartPos + 1, EndPos - StartPos - 1);
            Binding += BindPlaceholder(Pattern, PlaceholderName);

            Remaining := CopyStr(Remaining, EndPos + 1);
        end;

        Binding += EscapeLiteral(Remaining);
    end;

    /// <summary>
    /// Binds one placeholder. A field on the source table is tried first, so a table that happens
    /// to have a field called Created is still nameable by it rather than being shadowed by
    /// the computed value of the same name.
    /// </summary>
    local procedure BindPlaceholder(var Pattern: Record "Report Filename Pattern"; PlaceholderName: Text): Text
    var
        TableMetadata: Record "Table Metadata";
        ComputedKey: Text;
        FieldNo: Integer;
        MatchCount: Integer;
    begin
        if PlaceholderName = '' then
            Error(EmptyPlaceholderErr);

        if FindFieldByPlaceholder(Pattern."Table No.", PlaceholderName, FieldNo, MatchCount) then
            exit(StrSubstNo(FieldBindingTok, FieldNo));

        if TryResolveComputedName(PlaceholderName, ComputedKey) then
            exit(StrSubstNo(ComputedBindingTok, ComputedKey));

        if MatchCount > 1 then
            Error(AmbiguousPlaceholderErr, PlaceholderName);

        if Pattern."Table No." = 0 then
            Error(NoSourceTablePlaceholderErr, PlaceholderName);

        if not TableMetadata.Get(Pattern."Table No.") then
            Error(UnknownPlaceholderErr, PlaceholderName);

        // Tried last, because it is the only interpretation that has to guess where a name
        // ends. A placeholder naming a field on the document itself never reaches this point.
        if StrPos(PlaceholderName, HopSeparatorTok) > 0 then
            exit(BindHopPlaceholder(Pattern, PlaceholderName, TableMetadata.Caption));

        Error(UnknownFieldPlaceholderErr, PlaceholderName, TableMetadata.Caption);
    end;

    /// <summary>
    /// Binds a placeholder that reaches one table relation away, such as
    /// [Finance Charge Terms.Interest Rate]. Every position the name could split at is tried,
    /// because a caption may itself contain a full stop - "No." is one - so the split cannot
    /// be decided by looking at the text. Exactly one interpretation has to work: none means
    /// the placeholder names nothing, and more than one would mean picking silently between two
    /// readings of what the administrator wrote.
    /// </summary>
    local procedure BindHopPlaceholder(var Pattern: Record "Report Filename Pattern"; PlaceholderName: Text; SourceTableCaption: Text): Text
    var
        LocalFieldNo: Integer;
        RelatedFieldNo: Integer;
        Interpretations: Integer;
        RelationsMatched: Integer;
        SplitPos: Integer;
        NextSeparator: Integer;
    begin
        SplitPos := 0;
        // Walks the separators from left to right. The offset always advances past the one just
        // found, and the loop ends when there is no separator left in the remainder.
        repeat
            NextSeparator := StrPos(CopyStr(PlaceholderName, SplitPos + 1), HopSeparatorTok);
            if NextSeparator > 0 then begin
                SplitPos += NextSeparator;
                CountHopInterpretation(Pattern."Table No.",
                    CopyStr(PlaceholderName, 1, SplitPos - 1), CopyStr(PlaceholderName, SplitPos + 1),
                    LocalFieldNo, RelatedFieldNo, Interpretations, RelationsMatched);
            end;
        until NextSeparator = 0;

        if Interpretations = 1 then
            exit(StrSubstNo(HopBindingTok, LocalFieldNo, RelatedFieldNo));

        if Interpretations > 1 then
            Error(AmbiguousHopErr, PlaceholderName);

        // A full stop in a placeholder is not evidence that a relation was meant - most field
        // captions end in one. The relation message is only the right thing to say when part
        // of the placeholder really did name a table the document points at; otherwise this is an
        // ordinary field name that does not exist, and saying so is more use than explaining
        // a feature the administrator was not trying to use.
        if RelationsMatched = 0 then
            Error(UnknownFieldPlaceholderErr, PlaceholderName, SourceTableCaption);

        Error(UnknownHopErr, PlaceholderName, SourceTableCaption);
    end;

    /// <summary>
    /// Counts one candidate reading of a hop placeholder, keeping the field numbers of the last one
    /// that worked. The left side may name the related table, or the field on the document
    /// that points at it - the second form is what makes a document with two relations to the
    /// same table, a bill-to and a sell-to customer, expressible at all.
    /// </summary>
    local procedure CountHopInterpretation(SourceTableNo: Integer; LeftName: Text; RightName: Text; var LocalFieldNo: Integer; var RelatedFieldNo: Integer; var Interpretations: Integer; var RelationsMatched: Integer)
    var
        RelationFieldRec: Record Field;
        TableMetadata: Record "Table Metadata";
        RelatedFieldNoCandidate: Integer;
        MatchCount: Integer;
    begin
        if (LeftName = '') or (RightName = '') then
            exit;

        FilterRelationFields(RelationFieldRec, SourceTableNo);
        if not RelationFieldRec.FindSet() then
            exit;

        repeat
            if not TableMetadata.Get(RelationFieldRec.RelationTableNo) then
                Clear(TableMetadata);

            if (TableMetadata.Caption = LeftName) or (RelationFieldRec."Field Caption" = LeftName) or (RelationFieldRec.FieldName = LeftName) then begin
                RelationsMatched += 1;
                if FindFieldByPlaceholder(RelationFieldRec.RelationTableNo, RightName, RelatedFieldNoCandidate, MatchCount) then begin
                    Interpretations += 1;
                    LocalFieldNo := RelationFieldRec."No.";
                    RelatedFieldNo := RelatedFieldNoCandidate;
                end;
            end;
        until RelationFieldRec.Next() = 0;
    end;

    /// <summary>
    /// Finds the field a placeholder names. The caption is tried first, in the language the
    /// administrator is working in, so a pattern can be authored as it reads on screen. The
    /// AL field name is tried second: it is language-invariant and unique within a table, so
    /// a pattern authored in another session's language, or before captions were accepted,
    /// still binds.
    /// </summary>
    /// <param name="SourceTableNo">The table to search.</param>
    /// <param name="PlaceholderName">The placeholder as the administrator wrote it.</param>
    /// <param name="FieldNo">Receives the field number when exactly one field matches.</param>
    /// <param name="MatchCount">Receives how many fields carry that caption, so the caller can tell "no such field" from "more than one".</param>
    /// <returns>True when exactly one field matches.</returns>
    local procedure FindFieldByPlaceholder(SourceTableNo: Integer; PlaceholderName: Text; var FieldNo: Integer; var MatchCount: Integer): Boolean
    var
        FieldRec: Record Field;
    begin
        FieldNo := 0;
        MatchCount := 0;
        if SourceTableNo = 0 then
            exit(false);

        FieldRec.SetRange(TableNo, SourceTableNo);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        ExcludeUnnameableTypes(FieldRec);

        // Captions are compared in AL rather than filtered on, because the caption is
        // resolved per session language rather than stored, and counting the matches is what
        // lets two fields sharing a caption be reported instead of silently picking one.
        if FieldRec.FindSet() then
            repeat
                if FieldRec."Field Caption" = PlaceholderName then begin
                    MatchCount += 1;
                    if MatchCount = 1 then
                        FieldNo := FieldRec."No.";
                end;
            until FieldRec.Next() = 0;

        if MatchCount = 1 then
            exit(true);
        if MatchCount > 1 then begin
            FieldNo := 0;
            exit(false);
        end;

        FieldRec.SetRange(FieldName, CopyStr(PlaceholderName, 1, MaxStrLen(FieldRec.FieldName)));
        if not FieldRec.FindFirst() then
            exit(false);

        FieldNo := FieldRec."No.";
        exit(true);
    end;

    /// <summary>
    /// Leaves out the field types that have no file name form at all. A Blob holds a document
    /// or an image - Issued Reminder Header's Email Text is one, on the very table this design
    /// centres on - and offering it would put either something meaningless or an error into a
    /// file name. A Time has no file-safe form that stays readable, so resolving one gives nothing
    /// (Report Filename Mgt.) - offered, it would make a pattern that never names a file. Applied
    /// wherever fields are offered and wherever a placeholder is bound, so that a pattern saved before
    /// this existed cannot reach one either.
    /// </summary>
    /// <param name="FieldRec">The field record to filter.</param>
    local procedure ExcludeUnnameableTypes(var FieldRec: Record Field)
    begin
        FieldRec.SetFilter(Type, '<>%1&<>%2&<>%3&<>%4', FieldRec.Type::BLOB, FieldRec.Type::Media, FieldRec.Type::MediaSet, FieldRec.Type::Time);
    end;

    /// <summary>
    /// The fields of a table that can be offered as a placeholder: public, live, and holding a value a
    /// name can be built from. FlowFilters are excluded because they exist only as filters, so a
    /// placeholder bound to one would look pickable and then resolve to nothing.
    ///
    /// Filtered in one place because the picker and the binding have to agree on what is
    /// offerable - a field the picker offers and the binding then refuses is the one failure an
    /// administrator cannot act on.
    /// </summary>
    /// <param name="FieldRec">The field record to filter.</param>
    /// <param name="SourceTableNo">The table whose fields are wanted.</param>
    local procedure FilterNameableFields(var FieldRec: Record Field; SourceTableNo: Integer)
    begin
        FieldRec.SetRange(TableNo, SourceTableNo);
        FieldRec.SetFilter(Class, '<>%1', FieldRec.Class::FlowFilter);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        FieldRec.SetRange(Access, FieldRec.Access::Public);
        ExcludeUnnameableTypes(FieldRec);
    end;

    /// <summary>
    /// The fields of a table that point at another table, which are the one hop a placeholder may
    /// take. Filtered in one place so the three passes over them - counting how many fields
    /// reach each related table, offering the related fields, and reading a hop placeholder back -
    /// cannot disagree about what counts as a relation.
    /// </summary>
    /// <param name="RelationFieldRec">The field record to filter.</param>
    /// <param name="SourceTableNo">The document table whose relations are wanted.</param>
    local procedure FilterRelationFields(var RelationFieldRec: Record Field; SourceTableNo: Integer)
    begin
        RelationFieldRec.SetRange(TableNo, SourceTableNo);
        RelationFieldRec.SetFilter(RelationTableNo, '<>%1', 0);
        RelationFieldRec.SetRange(Class, RelationFieldRec.Class::Normal);
        RelationFieldRec.SetRange(Enabled, true);
        RelationFieldRec.SetRange(ObsoleteState, RelationFieldRec.ObsoleteState::No);
    end;

    /// <summary>
    /// Matches a placeholder against the computed values, by the name shown to the administrator in
    /// their own language and by the canonical name the binding records. Both are accepted, so
    /// a pattern authored in Danish and one authored in English bind to the same thing.
    /// </summary>
    /// <param name="PlaceholderName">The placeholder as the administrator wrote it.</param>
    /// <param name="ComputedKey">Receives the canonical name.</param>
    /// <returns>True when the placeholder names a computed value.</returns>
    local procedure TryResolveComputedName(PlaceholderName: Text; var ComputedKey: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        PlaceholderImplementation: Interface "Report Filename Placeholder";
    begin
        if not ReportFilenameMgt.TryFindComputedPlaceholder(PlaceholderName, true, PlaceholderImplementation) then
            exit(false);

        ComputedKey := PlaceholderImplementation.CanonicalName();
        exit(true);
    end;

    /// <summary>
    /// Protects literal braces in the pattern text, which are legal in a file name, from
    /// being read back as the binding's own placeholder delimiters.
    /// </summary>
    local procedure EscapeLiteral(LiteralText: Text): Text
    begin
        exit(LiteralText.Replace(BindStartTok, BindStartTok + BindStartTok).Replace(BindEndTok, BindEndTok + BindEndTok));
    end;

    /// <summary>
    /// Every computed value declared on the enum, including ones an extension added. Nothing
    /// here knows what they are, which is what makes the extension point real rather than
    /// nominal.
    /// </summary>
    local procedure AddComputedPlaceholders(var Pattern: Record "Report Filename Pattern"; var PlaceholderBuffer: Record "Report Filename Plh. Buffer")
    var
        PlaceholderValue: Enum "Report Filename Placeholder";
        PlaceholderImplementation: Interface "Report Filename Placeholder";
        Ordinal: Integer;
        FieldNo: Integer;
        MatchCount: Integer;
    begin
        foreach Ordinal in PlaceholderValue.Ordinals() do begin
            PlaceholderValue := Enum::"Report Filename Placeholder".FromInteger(Ordinal);
            PlaceholderImplementation := PlaceholderValue;
            // Asked, not assumed. Every other kind of placeholder is listed only when compiled
            // metadata says where its value would come from, and until this was here the
            // computed ones were the exception that made the picker's own promise false: a
            // pattern on a customer was offered [Total Incl. VAT], which can never resolve
            // there, and the whole pattern would then decline at the moment it was used.
            //
            // Nor when a field of the table carries the same name. The binding lets the field
            // win (BindPlaceholder), so the computed value could never be chosen there: Issued
            // Reminder Header has a User ID field, and choosing the computed [User ID] - "the
            // user who produced the file", example ADMIN - bound the user who issued the
            // reminder (container client, 8 October). Asked of the same lookup the binding uses.
            if PlaceholderImplementation.IsTableSupported(Pattern."Table No.") then
                if not (FindFieldByPlaceholder(Pattern."Table No.", PlaceholderImplementation.DisplayName(), FieldNo, MatchCount) or (MatchCount > 1)) then
                    AddPlaceholder(PlaceholderBuffer, PlaceholderBuffer.Source::Computed, PlaceholderImplementation.DisplayName(), PlaceholderImplementation.Description(),
                        ComputedExample(Pattern, PlaceholderImplementation), OverManyForComputed(Pattern, PlaceholderImplementation), 0);
        end;
    end;

    /// <summary>
    /// The fields one table relation away, offered as ready-made placeholders so the administrator
    /// picks a path rather than writing one. The left side of the placeholder names the related
    /// table where that is unambiguous, and the field on the document where it is not - a
    /// posted invoice points at Customer twice, as sell-to and as bill-to, and
    /// [Customer.Name] could not say which.
    ///
    /// Each relation contributes a row naming the table itself, at indentation zero, and its
    /// fields under it at indentation one, so the picker can show the relation as a step the
    /// administrator takes rather than as a prefix repeated down forty rows. The table row is
    /// written only once its fields are known to exist, so the tree never offers a branch that
    /// opens onto nothing. It is presentation only and carries no field number: it is not a
    /// placeholder and never reaches the binding.
    /// </summary>
    local procedure AddRelatedFieldPlaceholders(var Pattern: Record "Report Filename Pattern"; var PlaceholderBuffer: Record "Report Filename Plh. Buffer")
    var
        RelationFieldRec: Record Field;
        RelatedFieldRec: Record Field;
        TableMetadata: Record "Table Metadata";
        RelationCounts: Dictionary of [Integer, Integer];
        CaptionCounts: Dictionary of [Text, Integer];
        LeftName: Text;
    begin
        CountRelations(Pattern."Table No.", RelationCounts);

        FilterRelationFields(RelationFieldRec, Pattern."Table No.");
        RelationFieldRec.SetRange(Access, RelationFieldRec.Access::Public);
        if not RelationFieldRec.FindSet() then
            exit;

        repeat
            LeftName := HopLeftName(RelationFieldRec, RelationCounts, TableMetadata);
            if LeftName <> '' then begin
                Clear(CaptionCounts);
                CountCaptions(RelationFieldRec.RelationTableNo, CaptionCounts);

                RelatedFieldRec.Reset();
                FilterNameableFields(RelatedFieldRec, RelationFieldRec.RelationTableNo);
                RelatedFieldRec.SetRange(IsPartOfPrimaryKey, false);
                if RelatedFieldRec.FindSet() then begin
                    AddRelatedTableRow(PlaceholderBuffer, LeftName,
                        StrSubstNo(ExpandForFieldsMsg, TableMetadata.Caption, RelationFieldRec."Field Caption"));
                    repeat
                        AddRelatedFieldPlaceholder(PlaceholderBuffer, LeftName,
                            LeftName + HopSeparatorTok + PlaceholderNameForField(RelatedFieldRec, CaptionCounts),
                            RelatedFieldRec.FieldName, ShapeOfValue(Pattern, RelatedFieldRec),
                            CollapsedShapeOf(Pattern, RelatedFieldRec), RelatedFieldRec."No.");
                    until RelatedFieldRec.Next() = 0;
                end;
            end;
        until RelationFieldRec.Next() = 0;
    end;

    /// <summary>
    /// The unambiguous left-hand name for a relation: the related table's caption when the
    /// document points at that table once, and the pointing field's own caption when it points
    /// at it more than once.
    /// </summary>
    local procedure HopLeftName(var RelationFieldRec: Record Field; var RelationCounts: Dictionary of [Integer, Integer]; var TableMetadata: Record "Table Metadata"): Text
    var
        Relations: Integer;
    begin
        if not TableMetadata.Get(RelationFieldRec.RelationTableNo) then
            exit('');
        if TableMetadata.Caption = '' then
            exit('');

        if RelationCounts.Get(RelationFieldRec.RelationTableNo, Relations) then
            if Relations > 1 then
                exit(RelationFieldRec."Field Caption");

        exit(TableMetadata.Caption);
    end;

    /// <summary>
    /// How many fields on the document point at each related table.
    /// </summary>
    local procedure CountRelations(SourceTableNo: Integer; var RelationCounts: Dictionary of [Integer, Integer])
    var
        RelationFieldRec: Record Field;
        Relations: Integer;
    begin
        FilterRelationFields(RelationFieldRec, SourceTableNo);
        if not RelationFieldRec.FindSet() then
            exit;

        repeat
            Relations := 0;
            if RelationCounts.ContainsKey(RelationFieldRec.RelationTableNo) then
                RelationCounts.Get(RelationFieldRec.RelationTableNo, Relations);
            RelationCounts.Set(RelationFieldRec.RelationTableNo, Relations + 1);
        until RelationFieldRec.Next() = 0;
    end;

    /// <summary>
    /// Every field on the document that can hold a value. FlowFilters are excluded: they
    /// exist only as filters, so a placeholder bound to one would look pickable and then resolve
    /// to nothing.
    /// </summary>
    local procedure AddRecordFieldPlaceholders(var Pattern: Record "Report Filename Pattern"; var PlaceholderBuffer: Record "Report Filename Plh. Buffer")
    var
        FieldRec: Record Field;
        CaptionCounts: Dictionary of [Text, Integer];
    begin
        CountCaptions(Pattern."Table No.", CaptionCounts);

        FilterNameableFields(FieldRec, Pattern."Table No.");
        if not FieldRec.FindSet() then
            exit;

        repeat
            AddPlaceholder(PlaceholderBuffer, PlaceholderBuffer.Source::"Record Field", PlaceholderNameForField(FieldRec, CaptionCounts),
                FieldRec.FieldName, ShapeOfValue(Pattern, FieldRec), CollapsedShapeOf(Pattern, FieldRec), FieldRec."No.");
        until FieldRec.Next() = 0;
    end;

    /// <summary>
    /// The placeholder to offer for a field: its caption, which is what the administrator reads on
    /// the document and can be authored in their own language, unless the table has two
    /// fields carrying that caption - in which case the caption would be ambiguous and the
    /// AL field name, which is unique, is offered instead.
    /// </summary>
    local procedure PlaceholderNameForField(var FieldRec: Record Field; var CaptionCounts: Dictionary of [Text, Integer]): Text
    var
        SameCaption: Integer;
    begin
        if FieldRec."Field Caption" <> '' then
            if CaptionCounts.Get(FieldRec."Field Caption", SameCaption) then
                if SameCaption = 1 then
                    exit(FieldRec."Field Caption");

        exit(FieldRec.FieldName);
    end;

    /// <summary>
    /// How many fields on a table carry each caption. Counted over exactly the fields the
    /// binding will search, so the picker never offers a placeholder that the binding would then
    /// refuse as ambiguous.
    /// </summary>
    local procedure CountCaptions(SourceTableNo: Integer; var CaptionCounts: Dictionary of [Text, Integer])
    var
        FieldRec: Record Field;
        SameCaption: Integer;
    begin
        FieldRec.SetRange(TableNo, SourceTableNo);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        if not FieldRec.FindSet() then
            exit;

        repeat
            SameCaption := 0;
            if CaptionCounts.ContainsKey(FieldRec."Field Caption") then
                CaptionCounts.Get(FieldRec."Field Caption", SameCaption);
            CaptionCounts.Set(FieldRec."Field Caption", SameCaption + 1);
        until FieldRec.Next() = 0;
    end;

    /// <summary>
    /// The fields the request page declares as filters. These may be FlowFilters, because
    /// they resolve from the filter the run was given rather than from the record - which is
    /// how an analytical report's period reaches the file name. Their example is a range,
    /// because that is what a period is, and it reads the same over one record or many.
    /// </summary>
    local procedure AddFilterPlaceholders(var Pattern: Record "Report Filename Pattern"; var PlaceholderBuffer: Record "Report Filename Plh. Buffer")
    var
        ReportDataItems: Record "Report Data Items";
        FieldRec: Record Field;
        CaptionCounts: Dictionary of [Text, Integer];
        FieldNumbers: List of [Text];
        FieldNoText: Text;
        FieldNo: Integer;
    begin
        ReportDataItems.SetRange("Report ID", Pattern."Report ID");
        ReportDataItems.SetRange("Related Table ID", Pattern."Table No.");
        if not ReportDataItems.FindFirst() then
            exit;
        if ReportDataItems."Request Filter Fields" = '' then
            exit;

        CountCaptions(Pattern."Table No.", CaptionCounts);
        FieldNumbers := ReportDataItems."Request Filter Fields".Split(',');

        foreach FieldNoText in FieldNumbers do
            if Evaluate(FieldNo, FieldNoText.Trim()) then
                if FieldRec.Get(Pattern."Table No.", FieldNo) then
                    if FieldRec.Class = FieldRec.Class::FlowFilter then
                        AddPlaceholder(PlaceholderBuffer, PlaceholderBuffer.Source::"Request Filter", PlaceholderNameForField(FieldRec, CaptionCounts),
                            FieldRec.FieldName, CollapsedShapeOf(Pattern, FieldRec), CollapsedShapeOf(Pattern, FieldRec), FieldRec."No.");
    end;

    /// <summary>
    /// What a computed value will actually produce. These are safe to show for real: the company
    /// name, today's date, the signed-in user and the chosen report's caption are properties of
    /// the company, the session and the pattern - not anybody's data. Resolved against no
    /// document, so a value that needs one - the document total - declines and shows nothing
    /// rather than reaching into a record.
    /// </summary>
    /// <param name="Pattern">The pattern being edited, which carries the date format and the report.</param>
    /// <param name="PlaceholderImplementation">The computed value to ask.</param>
    /// <returns>The value, or blank when it needs a document.</returns>
    local procedure ComputedExample(var Pattern: Record "Report Filename Pattern"; PlaceholderImplementation: Interface "Report Filename Placeholder"): Text
    var
        NoDocument: RecordRef;
        ExampleText: Text;
    begin
        if not PlaceholderImplementation.TryResolve(Pattern, Pattern."Report ID", NoDocument, Pattern."Language Code", ExampleText) then
            exit(PlaceholderImplementation.ExampleWithoutDocument());
        exit(ExampleText);
    end;

    /// <summary>
    /// The shape a field's value takes in a file name, worked out from the field's own type.
    ///
    /// Generated, never read from a record. The examples used to come from whichever document
    /// happened to be first in the table, which was wrong twice over: an administrator setting
    /// up names for a payroll report would be shown a real person's real figures, for no
    /// purpose - and the record was arbitrary, so the value told them nothing they could rely
    /// on anyway. The card already had the honest form of this - "Dates will look like" shows a
    /// made-up date, not a posting date taken off a real invoice.
    /// </summary>
    /// <param name="Pattern">The pattern being edited, whose date format decides how a date reads.</param>
    /// <param name="FieldRec">The field to describe.</param>
    /// <returns>An example of the form its value takes.</returns>
    local procedure ShapeOfValue(var Pattern: Record "Report Filename Pattern"; var FieldRec: Record Field): Text
    begin
        exit(ShapeOfValue(Pattern, FieldRec, false));
    end;

    /// <summary>
    /// The shape of a value, either the first in a run or the last.
    ///
    /// A run covering many records collapses a field placeholder into a first-to-last range, and an
    /// example that showed the same shape at both ends would read as a defect rather than as a
    /// range. So the types where ranges actually occur - document numbers, entry numbers,
    /// amounts and dates - each offer a distinct second sample. For a text field the shape is
    /// the field's own name, and the name of the field is the same at both ends of any range,
    /// so those are left alone rather than given a fictitious second value.
    /// </summary>
    /// <param name="Pattern">The pattern being described.</param>
    /// <param name="FieldRec">The field whose shape is wanted.</param>
    /// <param name="Last">True for the shape of the last value in a run.</param>
    /// <returns>The shape.</returns>
    local procedure ShapeOfValue(var Pattern: Record "Report Filename Pattern"; var FieldRec: Record Field; Last: Boolean): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        case FieldRec.Type of
            FieldRec.Type::Date, FieldRec.Type::DateTime:
                exit(ReportFilenameMgt.FormatSampleDate(Pattern."Date Format", Last));
            FieldRec.Type::Boolean:
                exit(SampleBooleanLbl);
            FieldRec.Type::Integer, FieldRec.Type::BigInteger:
                if Last then
                    exit(SampleIntegerLastTok)
                else
                    exit(SampleIntegerTok);
            FieldRec.Type::Decimal:
                exit(ReportFilenameMgt.SampleDecimalText(Last));
            FieldRec.Type::Guid:
                exit(SampleGuidTok);
            FieldRec.Type::Option:
                // The option list is only populated for an option field; a field typed as an
                // enum leaves it empty, and most of these are enums now. Falling back keeps the
                // column complete rather than blank on a third of the rows for a reason that
                // has nothing to do with the administrator.
                if FirstOptionCaption(FieldRec) <> '' then
                    exit(FirstOptionCaption(FieldRec))
                else
                    exit(NameOfField(Pattern, FieldRec));
            FieldRec.Type::Code:
                if Last then
                    exit(SampleCodeLastTok)
                else
                    exit(SampleCodeTok);
            FieldRec.Type::Text:
                // The field's own name, not a made-up string, and qualified by its table when
                // that is not the table the pattern names. A code has a shape worth showing and
                // a date has a format that matters, but a text field can hold anything - so what
                // is useful is which field lands there.
                //
                // "Some text" said nothing at all. The field name alone was not enough either:
                // field names repeat across tables, so [Payment Terms.Description] reading as
                // "Description" leaves an administrator guessing which Description it is. It
                // reads "Payment Terms Description" now, which is the one thing that could not
                // be mistaken for another table's field of the same name.
                exit(NameOfField(Pattern, FieldRec));
        end;
        // Every other type offered - a date formula such as a customer's Shipping Time, a
        // duration, a record ID, a table filter - has no sample of its own, so it reads as the
        // field's name, as a text field does. It used to read as nothing: an empty Example in
        // Available Placeholders and no example on the card (container client, 8 October).
        exit(NameOfField(Pattern, FieldRec));
    end;

    /// <summary>
    /// A field's name as the administrator reads it, for use where the field's identity is more
    /// useful than a sample of its contents - qualified by its table when the field belongs to
    /// another one, because field names are not unique across tables.
    /// </summary>
    /// <param name="Pattern">The pattern being described, whose own table needs no qualifying.</param>
    /// <param name="FieldRec">The field.</param>
    /// <returns>Its name, qualified by its table when the field is one relation away.</returns>
    local procedure NameOfField(var Pattern: Record "Report Filename Pattern"; var FieldRec: Record Field): Text
    var
        TableMetadata: Record "Table Metadata";
        FieldName: Text;
    begin
        if FieldRec."Field Caption" <> '' then
            FieldName := FieldRec."Field Caption"
        else
            FieldName := FieldRec.FieldName;

        // Unqualified while the field is on the table the pattern itself names - there is only
        // one of those, so there is nothing to confuse it with. Qualified as soon as the field
        // is one relation away, because that is exactly where two tables can both have a
        // Description and only the table says which is meant.
        if FieldRec.TableNo = Pattern."Table No." then
            exit(FieldName);

        if not TableMetadata.Get(FieldRec.TableNo) then
            exit(FieldName);

        exit(TableMetadata.Caption + ' ' + FieldName);
    end;

    /// <summary>
    /// The first caption an option field offers that is not blank. That is a real value of the
    /// field itself and gives away nothing about any record. Not blank, because many option
    /// fields start with a blank option - Applies-to Doc. Type does - and an example of nothing
    /// was shown for them (Available Placeholders in the container client, 8 October).
    /// </summary>
    /// <param name="FieldRec">The option field.</param>
    /// <returns>Its first caption that is not blank, or blank when it declares none.</returns>
    local procedure FirstOptionCaption(var FieldRec: Record Field): Text
    var
        Captions: List of [Text];
        Caption: Text;
    begin
        if FieldRec.OptionString = '' then
            exit('');
        Captions := FieldRec.OptionString.Split(',');
        foreach Caption in Captions do
            if DelChr(Caption, '<>', ' ') <> '' then
                exit(Caption);
        exit('');
    end;

    /// <summary>
    /// The shape a field's value takes, for a caller that has no document - the setup card's
    /// preview, which has to work in a company where the first invoice has not been entered
    /// yet, and for an administrator who has no permission to read one.
    /// </summary>
    /// <param name="Pattern">The pattern being previewed, whose date format shapes a date.</param>
    /// <param name="TableNo">The table the field belongs to.</param>
    /// <param name="FieldNo">The field.</param>
    /// <returns>The shape, or blank when there is no such field.</returns>
    internal procedure ShapeForField(var Pattern: Record "Report Filename Pattern"; TableNo: Integer; FieldNo: Integer): Text
    begin
        exit(ShapeForField(Pattern, TableNo, FieldNo, false));
    end;

    /// <summary>
    /// The shape of a field's value, at either end of a run.
    /// </summary>
    /// <param name="Pattern">The pattern being described.</param>
    /// <param name="TableNo">The table the field belongs to.</param>
    /// <param name="FieldNo">The field.</param>
    /// <param name="Last">True for the shape of the last value in a run.</param>
    /// <returns>The shape, or blank when the field has none.</returns>
    internal procedure ShapeForField(var Pattern: Record "Report Filename Pattern"; TableNo: Integer; FieldNo: Integer; Last: Boolean): Text
    var
        FieldRec: Record Field;
    begin
        if not FieldRec.Get(TableNo, FieldNo) then
            exit('');
        exit(ShapeOfValue(Pattern, FieldRec, Last));
    end;

    /// <summary>
    /// The table a field points at, so a placeholder that reaches one relation away can be shaped
    /// without following the relation into a record that may not exist.
    /// </summary>
    /// <param name="TableNo">The table the pointing field belongs to.</param>
    /// <param name="FieldNo">The pointing field.</param>
    /// <returns>The table it relates to, or zero.</returns>
    internal procedure RelatedTableOf(TableNo: Integer; FieldNo: Integer): Integer
    var
        FieldRec: Record Field;
    begin
        if not FieldRec.Get(TableNo, FieldNo) then
            exit(0);
        exit(FieldRec.RelationTableNo);
    end;

    /// <summary>
    /// What a computed value will show when there is no document: its real value where it needs
    /// none, and otherwise the shape it declares. The same rule the placeholder picker uses, so the
    /// preview and the Example column cannot disagree.
    /// </summary>
    /// <param name="Pattern">The pattern being previewed.</param>
    /// <param name="CanonicalName">The language-invariant name recorded in the binding.</param>
    /// <param name="Shape">Receives the value.</param>
    /// <returns>True when the name is one of the computed values.</returns>
    internal procedure ShapeForComputed(var Pattern: Record "Report Filename Pattern"; CanonicalName: Text; var Shape: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        PlaceholderImplementation: Interface "Report Filename Placeholder";
    begin
        if not ReportFilenameMgt.TryFindComputedPlaceholder(CanonicalName, false, PlaceholderImplementation) then
            exit(false);

        Shape := ComputedExample(Pattern, PlaceholderImplementation);
        exit(true);
    end;

    /// <summary>
    /// Where a kind of placeholder sits in the picker. The computed values come first: this app has seven
    /// of them, each offered wherever it supports the pattern's table, and they are what somebody
    /// naming a file reaches for before hunting through a hundred and fifty fields. The report's
    /// request-page filters follow them, by the user's decision of 7 October 2026, then the
    /// record's fields and the related tables' fields. Held here rather than in the enum's
    /// ordinals, which are identities and must not be reordered to move rows on a page.
    /// </summary>
    /// <param name="PlaceholderSource">The kind of placeholder.</param>
    /// <returns>Its position among the kinds.</returns>
    local procedure SortOrderFor(PlaceholderSource: Enum "Report Filename Plh. Source"): Integer
    begin
        case PlaceholderSource of
            PlaceholderSource::Computed:
                exit(1);
            PlaceholderSource::"Request Filter":
                exit(2);
            PlaceholderSource::"Record Field":
                exit(3);
            PlaceholderSource::"Related Field":
                exit(4);
        end;
        exit(9);
    end;

    local procedure AddPlaceholder(var PlaceholderBuffer: Record "Report Filename Plh. Buffer"; PlaceholderSource: Enum "Report Filename Plh. Source"; PlaceholderName: Text; DescriptionText: Text; ExampleText: Text; OverManyText: Text; FieldNo: Integer)
    begin
        if PlaceholderName = '' then
            exit;

        AddRow(PlaceholderBuffer, PlaceholderSource, '[' + PlaceholderName + ']', DescriptionText, ExampleText, OverManyText, FieldNo, 0, '', SortOrderFor(PlaceholderSource));
    end;

    /// <summary>
    /// A field one relation away, written under the table it belongs to. Its description is the
    /// field's own name rather than the relation, because the relation is now said once on the
    /// table row above it instead of once per field.
    /// </summary>
    local procedure AddRelatedFieldPlaceholder(var PlaceholderBuffer: Record "Report Filename Plh. Buffer"; GroupName: Text; PlaceholderName: Text; DescriptionText: Text; ExampleText: Text; OverManyText: Text; FieldNo: Integer)
    begin
        if PlaceholderName = '' then
            exit;

        AddRow(PlaceholderBuffer, PlaceholderBuffer.Source::"Related Field", '[' + PlaceholderName + ']', DescriptionText, ExampleText, OverManyText, FieldNo, 1, GroupName, SortOrderFor(PlaceholderBuffer.Source::"Related Field"));
    end;

    /// <summary>
    /// The row standing for a related table. It is written without brackets, precisely so that
    /// it does not read as something to type: it is a branch of the tree, not a placeholder, and the
    /// picker refuses it if the administrator tries to choose it.
    /// </summary>
    local procedure AddRelatedTableRow(var PlaceholderBuffer: Record "Report Filename Plh. Buffer"; GroupName: Text; DescriptionText: Text)
    begin
        if GroupName = '' then
            exit;

        AddRow(PlaceholderBuffer, PlaceholderBuffer.Source::"Related Field", GroupName, DescriptionText, '', '', 0, 0, GroupName, SortOrderFor(PlaceholderBuffer.Source::"Related Field"));
    end;

    local procedure AddRow(var PlaceholderBuffer: Record "Report Filename Plh. Buffer"; PlaceholderSource: Enum "Report Filename Plh. Source"; RowText: Text; DescriptionText: Text; ExampleText: Text; OverManyText: Text; FieldNo: Integer; Indentation: Integer; GroupName: Text; SortOrder: Integer)
    begin
        NextEntryNo += 1;
        PlaceholderBuffer.Init();
        PlaceholderBuffer."Entry No." := NextEntryNo;
        PlaceholderBuffer.Source := PlaceholderSource;
        PlaceholderBuffer.Placeholder := CopyStr(RowText, 1, MaxStrLen(PlaceholderBuffer.Placeholder));
        PlaceholderBuffer.Description := CopyStr(DescriptionText, 1, MaxStrLen(PlaceholderBuffer.Description));
        PlaceholderBuffer.Example := CopyStr(ExampleText, 1, MaxStrLen(PlaceholderBuffer.Example));
        PlaceholderBuffer."Over Several Records" := CopyStr(OverManyText, 1, MaxStrLen(PlaceholderBuffer."Over Several Records"));
        PlaceholderBuffer."Field No." := FieldNo;
        PlaceholderBuffer.Indentation := Indentation;
        PlaceholderBuffer."Group Name" := CopyStr(GroupName, 1, MaxStrLen(PlaceholderBuffer."Group Name"));
        PlaceholderBuffer."Sort Order" := SortOrder;
        PlaceholderBuffer.Insert();
    end;

    var
        NextEntryNo: Integer;
        PlaceholderStartTok: Label '[', Locked = true;
        PlaceholderEndTok: Label ']', Locked = true;
        BindStartTok: Label '{', Locked = true;
        BindEndTok: Label '}', Locked = true;
        FieldBindingTok: Label '{f:%1}', Comment = '%1 field number', Locked = true;
        ComputedBindingTok: Label '{c:%1}', Comment = '%1 canonical computed value name', Locked = true;
        HopBindingTok: Label '{r:%1:%2}', Comment = '%1 field number on the document, %2 field number on the related table', Locked = true;
        HopSeparatorTok: Label '.', Locked = true;
        CannotNameARunMsg: Label 'Cannot name a run over several records, so the pattern is not used';
        SampleCodeTok: Label 'ABC-01', Locked = true;
        SampleCodeLastTok: Label 'ABC-09', Locked = true;
        SampleIntegerTok: Label '1234', Locked = true;
        SampleIntegerLastTok: Label '1298', Locked = true;
        SampleGuidTok: Label '0f8b-c41d', Locked = true;
        SampleBooleanLbl: Label 'Yes';
        AmbiguousHopErr: Label '%1 can be read in more than one way, so it is not clear which field is meant. Choose it from Available Placeholders instead.', Comment = '%1 the placeholder as it was typed';
        UnknownHopErr: Label '%1 cannot be found. A placeholder can use a field on a related table, as in [Finance Charge Terms.Interest Rate]: the first part must be a table that %2 relates to, and the second a field on that table. A table related to a related table cannot be used.', Comment = '%1 the placeholder as it was typed, %2 the table name';
        // Written as something to do rather than as a name. The branch row carried the same
        // words as the field it is reached through, one row below it and without the
        // brackets - "Transaction Type" sitting under "[Transaction Type]" reads as the same
        // thing twice, and a search flattens the tree so the two end up adjacent.
        ExpandForFieldsMsg: Label 'Expand to use a field from %1, through %2', Comment = '%1 related table name, %2 the field on the record that relates to it';
        UnterminatedPlaceholderErr: Label 'The file name pattern has an opening bracket that is never closed, at %1. Close the placeholder or remove the bracket.', Comment = '%1 the rest of the file name pattern from the unclosed bracket';
        EmptyPlaceholderErr: Label 'The file name pattern contains an empty placeholder. Put a placeholder name between the brackets, or remove them.';
        AmbiguousPlaceholderErr: Label 'More than one field is called %1, so it is not clear which one is meant. Choose it from Available Placeholders instead.', Comment = '%1 the placeholder as it was typed';
        NoSourceTablePlaceholderErr: Label '%1 cannot be used until this pattern has a table, because there is no record to read it from. Choose a report or a table first, or use one of the computed placeholders from Available Placeholders.', Comment = '%1 the placeholder as it was typed';
        UnknownFieldPlaceholderErr: Label '%1 is not a field on %2 and is not a value Business Central can compute. Choose from Available Placeholders to see what this pattern can use.', Comment = '%1 the placeholder as it was typed, %2 the table name';
        UnknownPlaceholderErr: Label '%1 is not a value Business Central can compute. Choose from Available Placeholders to see what this pattern can use.', Comment = '%1 the placeholder as it was typed';
        AnyReportAnyTableMsg: Label 'This pattern has no report and no table, so only the computed placeholders can be used.';
        NoDocumentMsg: Label '%1 is not based on a table of records, so only the computed placeholders can be used.', Comment = '%1 report name';
        ReportAndTableMsg: Label '%1, on the %2 table.', Comment = '%1 report name, %2 table name';
        TableOnlyMsg: Label 'Any report on the %1 table.', Comment = '%1 table name';
}
