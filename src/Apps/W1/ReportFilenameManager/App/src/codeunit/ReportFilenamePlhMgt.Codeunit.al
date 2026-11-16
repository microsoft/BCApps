// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Reflection;

codeunit 8129 "Report Filename Plh. Mgt."
{
    // Which placeholders and tables are offered is derived from compiled metadata (Report
    // Metadata, Report Data Items, Table Metadata, Field), not from the company's records.

    Access = Internal;

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
    /// The tables non-processing reports are about (each report's subject table, as the manager
    /// defines it), each with how many reports are about it.
    /// </summary>
    internal procedure BuildTables(var TableBuffer: Record "Report Filename Table Buffer")
    var
        ReportMetadata: Record "Report Metadata";
        TableMetadata: Record "Table Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        TableBuffer.Reset();
        TableBuffer.DeleteAll();

        ReportMetadata.SetRange(ProcessingOnly, false);

        // Two passes, split on the first data item's table.
        // First: reports whose first data item is a real table. Still asked through the manager,
        // because report 25's subject is Financial Report, not its first data item.
        ReportMetadata.SetFilter(FirstDataItemTableID, '>%1&<%2', 0, SystemTableFrom());
        if ReportMetadata.FindSet() then
            repeat
                CountTable(TableBuffer, TableMetadata, ReportFilenameMgt.SubjectTableNo(ReportMetadata));
            until ReportMetadata.Next() = 0;

        // Then: reports whose first data item is a system or virtual table; some have a real
        // subject further in (e.g. report 910 Posted Assembly Order).
        ReportMetadata.SetFilter(FirstDataItemTableID, '%1|>=%2', 0, SystemTableFrom());
        if ReportMetadata.FindSet() then
            repeat
                CountTable(TableBuffer, TableMetadata, ReportFilenameMgt.SubjectTableNo(ReportMetadata.ID));
            until ReportMetadata.Next() = 0;
    end;

    /// <summary>
    /// Counts one more report for a table. Tables without a caption are skipped.
    /// </summary>
    /// <param name="TableNo">Zero when the report is about no table.</param>
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
    /// What a field placeholder produces when the run covers several records: a first-to-last
    /// range, as the resolver renders one.
    /// </summary>
    /// <returns>Blank when the field has no shape.</returns>
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

        // A text field's shape is its own name, the same at both ends.
        if LastShape = FirstShape then
            exit(FirstShape);

        exit(FirstShape + ReportFilenameMgt.RangeJoinOf(Pattern) + LastShape);
    end;

    local procedure OverManyForComputed(var Pattern: Record "Report Filename Pattern"; PlaceholderImplementation: Interface "Report Filename Placeholder"): Text
    begin
        if PlaceholderImplementation.SpeaksForARunOfManyRecords() then
            exit(ComputedExample(Pattern, PlaceholderImplementation));
        exit(CannotNameARunMsg);
    end;

    local procedure SystemTableFrom(): Integer
    begin
        exit(2000000000);
    end;

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
    /// Turns the pattern text into its binding: each placeholder replaced by its field number or
    /// computed canonical name. Raises an error for any placeholder that resolves to nothing.
    /// </summary>
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
    /// A field on the source table wins over a computed value of the same name.
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

        // Tried last: the only interpretation that has to guess where a name splits.
        if StrPos(PlaceholderName, HopSeparatorTok) > 0 then
            exit(BindHopPlaceholder(Pattern, PlaceholderName, TableMetadata.Caption));

        Error(UnknownFieldPlaceholderErr, PlaceholderName, TableMetadata.Caption);
    end;

    /// <summary>
    /// Binds a placeholder one relation away, such as [Finance Charge Terms.Interest Rate]. Every
    /// full stop is tried as the split, since captions such as "No." contain one; exactly one
    /// interpretation must work.
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

        // A full stop does not mean a relation was intended; only mention relations when part of
        // the name matched one.
        if RelationsMatched = 0 then
            Error(UnknownFieldPlaceholderErr, PlaceholderName, SourceTableCaption);

        Error(UnknownHopErr, PlaceholderName, SourceTableCaption);
    end;

    /// <summary>
    /// Counts one candidate split. The left side may name the related table or the relation field,
    /// which is how two relations to the same table (sell-to and bill-to customer) are told apart.
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
    /// Matches the caption in the session language first, then the language-invariant AL field name.
    /// </summary>
    /// <param name="MatchCount">How many fields carry that caption, so the caller can tell "no such field" from "more than one".</param>
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

        // Every field with the caption is counted, so an ambiguous caption can be reported.
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
    /// Excludes types with no file name form: Blob and Media, and Time, which Report Filename Mgt.
    /// resolves to nothing. Applied both when offering and when binding.
    /// </summary>
    local procedure ExcludeUnnameableTypes(var FieldRec: Record Field)
    begin
        FieldRec.SetFilter(Type, '<>%1&<>%2&<>%3&<>%4', FieldRec.Type::BLOB, FieldRec.Type::Media, FieldRec.Type::MediaSet, FieldRec.Type::Time);
    end;

    /// <summary>
    /// Fields that can be offered as a placeholder. FlowFilters hold no value on a record.
    /// </summary>
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
    /// Relation fields a placeholder may hop through. Shared by every pass so they agree on what counts as a relation.
    /// </summary>
    local procedure FilterRelationFields(var RelationFieldRec: Record Field; SourceTableNo: Integer)
    begin
        RelationFieldRec.SetRange(TableNo, SourceTableNo);
        RelationFieldRec.SetFilter(RelationTableNo, '<>%1', 0);
        RelationFieldRec.SetRange(Class, RelationFieldRec.Class::Normal);
        RelationFieldRec.SetRange(Enabled, true);
        RelationFieldRec.SetRange(ObsoleteState, RelationFieldRec.ObsoleteState::No);
    end;

    /// <summary>
    /// Accepts both the display name and the canonical name.
    /// </summary>
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
    /// Doubles literal braces so they are not read back as binding delimiters.
    /// </summary>
    local procedure EscapeLiteral(LiteralText: Text): Text
    begin
        exit(LiteralText.Replace(BindStartTok, BindStartTok + BindStartTok).Replace(BindEndTok, BindEndTok + BindEndTok));
    end;

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
            // Skipped when the table is not supported, or when any field has the same name (a single
            // such field wins in BindPlaceholder, so the computed value could not be chosen).
            if PlaceholderImplementation.IsTableSupported(Pattern."Table No.") then
                if not (FindFieldByPlaceholder(Pattern."Table No.", PlaceholderImplementation.DisplayName(), FieldNo, MatchCount) or (MatchCount > 1)) then
                    AddPlaceholder(PlaceholderBuffer, PlaceholderBuffer.Source::Computed, PlaceholderImplementation.DisplayName(), PlaceholderImplementation.Description(),
                        ComputedExample(Pattern, PlaceholderImplementation), OverManyForComputed(Pattern, PlaceholderImplementation), 0);
        end;
    end;

    /// <summary>
    /// The fields one relation away. Each relation adds a table row (indentation 0, no field
    /// number, never bound) and its fields under it (indentation 1); the table row is only
    /// added when it has fields.
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
    /// The related table's caption, or the relation field's caption when the document relates
    /// to that table more than once (e.g. sell-to and bill-to customer).
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
    /// The field's caption, or its unique AL name when another field shares the caption.
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
    /// Counted over every field the binding searches (and more), so the picker never offers a
    /// caption the binding would refuse as ambiguous.
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
    /// The request page's FlowFilter fields, resolved from the run's filter rather than the
    /// record. Shown as a range over one record or many.
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
    /// Resolves the computed value against no document, falling back to its declared shape.
    /// Values needing no document (company, date, user) are not document data, so safe to show.
    /// </summary>
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
    /// The shape of a field's value, generated from its type and never read from a record, so
    /// no real data is shown.
    /// </summary>
    local procedure ShapeOfValue(var Pattern: Record "Report Filename Pattern"; var FieldRec: Record Field): Text
    begin
        exit(ShapeOfValue(Pattern, FieldRec, false));
    end;

    /// <summary>
    /// Types where ranges occur (codes, numbers, amounts, dates) give a distinct last sample so a
    /// range reads as a range; a text field's shape is its own name at both ends.
    /// </summary>
    /// <param name="Last">True for the shape of the last value in a run.</param>
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
                // Text can hold anything, so show which field lands there.
                exit(NameOfField(Pattern, FieldRec));
        end;
        // Other types (DateFormula, Duration, RecordId, TableFilter) have no sample of their own.
        exit(NameOfField(Pattern, FieldRec));
    end;

    /// <summary>
    /// The field's caption, prefixed by its table's caption when it is on a related table,
    /// because field names repeat across tables.
    /// </summary>
    local procedure NameOfField(var Pattern: Record "Report Filename Pattern"; var FieldRec: Record Field): Text
    var
        TableMetadata: Record "Table Metadata";
        FieldName: Text;
    begin
        if FieldRec."Field Caption" <> '' then
            FieldName := FieldRec."Field Caption"
        else
            FieldName := FieldRec.FieldName;

        if FieldRec.TableNo = Pattern."Table No." then
            exit(FieldName);

        if not TableMetadata.Get(FieldRec.TableNo) then
            exit(FieldName);

        exit(TableMetadata.Caption + ' ' + FieldName);
    end;

    /// <summary>
    /// The first non-blank entry in the field's OptionString; an option field can start with a blank option.
    /// </summary>
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
    /// The shape of a field's value for a caller without a document, such as the card's preview.
    /// </summary>
    /// <returns>Blank when there is no such field.</returns>
    internal procedure ShapeForField(var Pattern: Record "Report Filename Pattern"; TableNo: Integer; FieldNo: Integer): Text
    begin
        exit(ShapeForField(Pattern, TableNo, FieldNo, false));
    end;

    /// <param name="Last">True for the shape of the last value in a run.</param>
    internal procedure ShapeForField(var Pattern: Record "Report Filename Pattern"; TableNo: Integer; FieldNo: Integer; Last: Boolean): Text
    var
        FieldRec: Record Field;
    begin
        if not FieldRec.Get(TableNo, FieldNo) then
            exit('');
        exit(ShapeOfValue(Pattern, FieldRec, Last));
    end;

    internal procedure RelatedTableOf(TableNo: Integer; FieldNo: Integer): Integer
    var
        FieldRec: Record Field;
    begin
        if not FieldRec.Get(TableNo, FieldNo) then
            exit(0);
        exit(FieldRec.RelationTableNo);
    end;

    /// <summary>
    /// Same rule as the picker's Example column, so the preview and the picker agree.
    /// </summary>
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
    /// Picker order by source, independent of the enum's ordinals.
    /// </summary>
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

    local procedure AddRelatedFieldPlaceholder(var PlaceholderBuffer: Record "Report Filename Plh. Buffer"; GroupName: Text; PlaceholderName: Text; DescriptionText: Text; ExampleText: Text; OverManyText: Text; FieldNo: Integer)
    begin
        if PlaceholderName = '' then
            exit;

        AddRow(PlaceholderBuffer, PlaceholderBuffer.Source::"Related Field", '[' + PlaceholderName + ']', DescriptionText, ExampleText, OverManyText, FieldNo, 1, GroupName, SortOrderFor(PlaceholderBuffer.Source::"Related Field"));
    end;

    /// <summary>
    /// A tree branch for a related table, written without brackets because it is not a placeholder;
    /// the picker refuses it.
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
