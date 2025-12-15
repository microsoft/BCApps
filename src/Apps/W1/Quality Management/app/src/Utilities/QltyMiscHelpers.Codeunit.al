// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.Utilities;

codeunit 20599 "Qlty. Misc Helpers"
{
    var
        QltyBooleanParser: Codeunit "Qlty. Boolean Parser";
        DateKeywordTxt: Label 'Date';
        YesNoKeyword1Txt: Label 'Does the';
        YesNoKeyword2Txt: Label 'Do the';
        YesNoKeyword3Txt: Label 'Is the';
        YesNoKeyword4Txt: Label 'Did you';
        YesNoKeyword5Txt: Label 'Have you';
        TrackingKeyword1Txt: Label 'serial #';
        TrackingKeyword2Txt: Label 'lot #';
        TrackingKeyword3Txt: Label 'serial number';
        TrackingKeyword4Txt: Label 'lot number';

    /// <summary>
    /// Retrieves available record values for a table lookup field configured on a test line, returned as CSV.
    /// Evaluates expressions and applies filters configured in the field definition to generate the list.
    /// 
    /// Common usage: Populating dropdown lists or validating user input against configured lookup values.
    /// </summary>
    /// <param name="QltyInspectionTestLine">The test line containing the table field configuration</param>
    /// <returns>Comma-separated string of available lookup codes</returns>
    procedure GetRecordsForTableFieldAsCSV(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line") CSVText: Text
    var
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
        NeedComma: Boolean;
    begin
        GetRecordsForTableField(QltyInspectionTestLine, TempBufferQltyLookupCode);
        if TempBufferQltyLookupCode.FindSet() then
            repeat
                if NeedComma then
                    CSVText += ',';

                NeedComma := true;
                CSVText += Format(TempBufferQltyLookupCode.Code);
            until TempBufferQltyLookupCode.Next() = 0
    end;

    /// <summary>
    /// Retrieves available records for a table lookup field configured on a test line.
    /// Evaluates expressions and applies configured table filters to populate the lookup buffer.
    /// 
    /// This overload automatically loads the test header and field definition from the test line,
    /// then calls the main GetRecordsForTableField procedure.
    /// </summary>
    /// <param name="QltyInspectionTestLine">The test line containing the field code to look up</param>
    /// <param name="TempBufferQltyLookupCode">Output: Temporary buffer filled with available lookup codes and descriptions</param>
    procedure GetRecordsForTableField(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary)
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyField: Record "Qlty. Field";
    begin
        QltyInspectionTestHeader.Get(QltyInspectionTestLine."Test No.", QltyInspectionTestHeader."Retest No.");
        QltyField.Get(QltyInspectionTestLine."Field Code");
        GetRecordsForTableField(QltyField, QltyInspectionTestHeader, QltyInspectionTestLine, TempBufferQltyLookupCode);
    end;

    /// <summary>
    /// Gets the available records for any given table field.
    /// This will evaluate expressions!
    /// </summary>
    /// <param name="QltyField"></param>
    /// <param name="OptionalContextQltyInspectionTestHeader">Optional. Leave empty if you do not want search/replace fields.  Supply a test context if you want the lookup table filter to have square bracket [FIELDNAME] replacements </param>
    /// <param name="TempBufferQltyLookupCode"></param>
    internal procedure GetRecordsForTableField(var QltyField: Record "Qlty. Field"; var OptionalContextQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary)
    var
        TempDummyQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
    begin
        GetRecordsForTableField(QltyField, OptionalContextQltyInspectionTestHeader, TempDummyQltyInspectionTestLine, TempBufferQltyLookupCode);
    end;

    /// <summary>
    /// Retrieves lookup values for a quality field with context-sensitive filtering.
    /// Evaluates dynamic table filters using inspection test context and populates temporary buffer with available choices.
    /// 
    /// Behavior:
    /// - Evaluates QltyField."Lookup Table Filter" using test header/line context for dynamic filtering
    /// - For Qlty. Lookup Code table: includes both Code and Description fields
    /// - For other tables: uses only the specified lookup field
    /// - Applies maximum row limit from setup to prevent excessive data retrieval
    /// 
    /// Common usage: Populating dropdown lists in inspection test lines with context-aware options.
    /// </summary>
    /// <param name="QltyField">The quality field configuration defining lookup table and filters</param>
    /// <param name="OptionalContextQltyInspectionTestHeader">Test header providing context for filter expression evaluation</param>
    /// <param name="OptionalContextQltyInspectionTestLine">Test line providing context for filter expression evaluation</param>
    /// <param name="TempBufferQltyLookupCode">Output: Temporary buffer populated with lookup values</param>
    internal procedure GetRecordsForTableField(var QltyField: Record "Qlty. Field"; var OptionalContextQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var OptionalContextQltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary)
    var
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        ReasonableMaximum: Integer;
        DummyText: Text;
        TableFilter: Text;
    begin
        ReasonableMaximum := QltyConfigurationHelpers.GetDefaultMaximumRowsFieldLookup();

        TableFilter := QltyExpressionMgmt.EvaluateTextExpression(QltyField."Lookup Table Filter", OptionalContextQltyInspectionTestHeader, OptionalContextQltyInspectionTestLine);

        if QltyField."Lookup Table No." = Database::"Qlty. Lookup Code" then
            GetRecordsForTableField(QltyField."Lookup Table No.", QltyField."Lookup Field No.", TempBufferQltyLookupCode.FieldNo(Description), TableFilter, ReasonableMaximum, TempBufferQltyLookupCode, DummyText)
        else
            GetRecordsForTableField(QltyField."Lookup Table No.", QltyField."Lookup Field No.", 0, TableFilter, ReasonableMaximum, TempBufferQltyLookupCode, DummyText);
    end;

    /// <summary>
    /// Generates a CSV string of values for a specific field from a table with optional filtering.
    /// Retrieves up to MaxCountRecords records and formats field values as comma-separated text.
    /// 
    /// Example: For Item table, Location Code field → "BLUE,RED,GREEN,YELLOW"
    /// 
    /// Common usage: Building dropdown lists, generating reports, or creating filter strings.
    /// </summary>
    /// <param name="CurrentTable">The table number to retrieve records from</param>
    /// <param name="ChoiceField">The field number whose values should be extracted</param>
    /// <param name="TableFilter">Optional filter to apply to the table (AL filter syntax)</param>
    /// <param name="MaxCountRecords">Maximum number of records to include in the CSV output</param>
    /// <returns>Comma-separated string of field values</returns>
    procedure GetCSVOfValuesFromRecord(CurrentTable: Integer; ChoiceField: Integer; TableFilter: Text; MaxCountRecords: Integer) ResultText: Text
    var
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
    begin
        GetRecordsForTableField(CurrentTable, ChoiceField, 0, TableFilter, MaxCountRecords, TempBufferQltyLookupCode, ResultText);
    end;

    /// <summary>
    /// Generates a CSV string of values for a specific field from a table with optional filtering.
    /// Uses system-defined maximum recursion limit for record count.
    /// 
    /// This internal overload is optimized for configuration traversal scenarios where a reasonable
    /// default limit is appropriate.
    /// </summary>
    /// <param name="CurrentTable">The table number to retrieve records from</param>
    /// <param name="ChoiceField">The field number whose values should be extracted</param>
    /// <param name="TableFilter">Optional filter to apply to the table (AL filter syntax)</param>
    /// <returns>Comma-separated string of field values (up to system maximum records)</returns>
    internal procedure GetCSVOfValuesFromRecord(CurrentTable: Integer; ChoiceField: Integer; TableFilter: Text) ResultText: Text
    var
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
    begin
        GetRecordsForTableField(CurrentTable, ChoiceField, 0, TableFilter, QltyConfigurationHelpers.GetArbitraryMaximumRecursion(), TempBufferQltyLookupCode, ResultText);
    end;

    /// <summary>
    /// Populates Custom 1 with the 'actual' key.
    /// Populates Code with the code version of that key
    /// Populates Description with the visible portion of that key.
    /// </summary>
    /// <param name="CurrentTable"></param>
    /// <param name="ChoiceField"></param>
    /// <param name="DescriptionField"></param>
    /// <param name="TableFilter"></param>
    /// <param name="MaxCountRecords"></param>
    /// <param name="TempBufferQltyLookupCode"></param>
    /// <param name="CSVSimpleText"></param>
    local procedure GetRecordsForTableField(CurrentTable: Integer; ChoiceField: Integer; DescriptionField: Integer; TableFilter: Text; MaxCountRecords: Integer; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary; var CSVSimpleText: Text)
    var
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
        RecordRefToFetch: RecordRef;
        FieldRefToChoiceField: FieldRef;
        FieldRefToDescriptionField: FieldRef;
        RemainingCountRecordsToAdd: Integer;
        LoopSafety: Integer;
        HasAtLeastOne: Boolean;
        DuplicateChecker: List of [Text];
        ValueToAddToList: Text;
    begin
        if (CurrentTable = 0) or (ChoiceField = 0) then
            exit;

        if MaxCountRecords <= 0 then begin
            MaxCountRecords := QltyConfigurationHelpers.GetDefaultMaximumRowsFieldLookup();
            if MaxCountRecords <= 0 then
                MaxCountRecords := 1;
            if MaxCountRecords > 1000 then
                MaxCountRecords := 1000;
        end;

        RemainingCountRecordsToAdd := MaxCountRecords;
        if DescriptionField = 0 then
            DescriptionField := ChoiceField;
        RecordRefToFetch.Open(CurrentTable);
        if TableFilter <> '' then
            RecordRefToFetch.SetView(TableFilter);

        LoopSafety := 1000;
        if RecordRefToFetch.FindSet() then
            repeat
                LoopSafety -= 1;
                FieldRefToChoiceField := RecordRefToFetch.Field(ChoiceField);
                FieldRefToDescriptionField := RecordRefToFetch.Field(DescriptionField);
                TempBufferQltyLookupCode."Group Code" := CopyStr(PadStr(Format(RemainingCountRecordsToAdd), MaxStrLen(TempBufferQltyLookupCode."Group Code"), '0'), 1, MaxStrLen(TempBufferQltyLookupCode."Group Code"));
                ValueToAddToList := CopyStr(Format(FieldRefToChoiceField.Value()), 1, MaxStrLen(TempBufferQltyLookupCode."Custom 1")).Trim();
                if not DuplicateChecker.Contains(ValueToAddToList) then begin
                    RemainingCountRecordsToAdd -= 1;
                    DuplicateChecker.Add(ValueToAddToList);
                    TempBufferQltyLookupCode."Custom 1" := CopyStr(ValueToAddToList, 1, MaxStrLen(TempBufferQltyLookupCode."Custom 1"));
                    TempBufferQltyLookupCode."Custom 2" := TempBufferQltyLookupCode."Custom 1".ToLower();
                    TempBufferQltyLookupCode."Custom 3" := TempBufferQltyLookupCode."Custom 1".ToUpper();
                    TempBufferQltyLookupCode.Code := CopyStr(TempBufferQltyLookupCode."Custom 1", 1, MaxStrLen(TempBufferQltyLookupCode.Code));
                    TempBufferQltyLookupCode.Description := CopyStr(Format(FieldRefToDescriptionField.Value()), 1, MaxStrLen(TempBufferQltyLookupCode.Description));
                    if (TempBufferQltyLookupCode.Description = '') and (TempBufferQltyLookupCode."Custom 1" <> '') then
                        TempBufferQltyLookupCode.Description := TempBufferQltyLookupCode."Custom 1";

                    if TempBufferQltyLookupCode.Insert() then;
                    if HasAtLeastOne then
                        CSVSimpleText += ',';
                    CSVSimpleText += TempBufferQltyLookupCode."Custom 1";
                end;
                HasAtLeastOne := true;

            until (RecordRefToFetch.Next() = 0) or (RemainingCountRecordsToAdd <= 0) or (LoopSafety <= 0);

        RecordRefToFetch.Close();
    end;


    internal procedure IsNumericText(Input: Text): Boolean
    var
        TestNumber: Decimal;
    begin
#pragma warning disable AA0206
        exit(Evaluate(TestNumber, Input));
#pragma warning restore AA0206
    end;

    /// <summary>
    /// Attempts to infer the appropriate data type for a quality field based on its description text and sample value.
    /// Uses heuristic analysis of keywords and value patterns to suggest the most suitable field type.
    /// 
    /// Detection priority:
    /// 1. Value-based detection (if OptionalValue provided):
    ///    - Boolean-like text → Field Type Boolean
    ///    - Numeric text → Field Type Decimal
    ///    - Date format → Field Type Date
    ///    - DateTime format → Field Type DateTime
    /// 2. Description-based detection (keywords):
    ///    - Contains "date" → Field Type Date
    ///    - Contains tracking keywords ("lot", "serial") → Field Type Text
    ///    - Starts with yes/no keywords → Field Type Boolean
    /// 3. Default fallback → Field Type Text
    /// 
    /// Common usage: Auto-configuration of fields during template import or field creation wizards.
    /// </summary>
    /// <param name="Description">The field description text to analyze for type hints</param>
    /// <param name="OptionalValue">Optional sample value to analyze for type detection</param>
    /// <returns>The guessed field type enum value</returns>
    procedure GuessDataTypeFromDescriptionAndValue(Description: Text; OptionalValue: Text) QltyFieldType: Enum "Qlty. Field Type"
    var
        TestDateTime: Date;
        TestDate: Date;
    begin
        Description := UpperCase(Description);
        QltyFieldType := QltyFieldType::"Field Type Text";
        if OptionalValue <> '' then
#pragma warning disable AA0206
            case true of
                QltyBooleanParser.CanTextBeInterpretedAsBooleanIsh(Text.DelChr(OptionalValue, '=', ' ').ToUpper()):
                    QltyFieldType := QltyFieldType::"Field Type Boolean";
                IsNumericText(OptionalValue):
                    QltyFieldType := QltyFieldType::"Field Type Decimal";
                Evaluate(TestDate, OptionalValue):
                    QltyFieldType := QltyFieldType::"Field Type Date";
                Evaluate(TestDateTime, OptionalValue):
                    QltyFieldType := QltyFieldType::"Field Type DateTime";
                Evaluate(TestDateTime, OptionalValue, 9):
                    QltyFieldType := QltyFieldType::"Field Type DateTime";
            end;
#pragma warning restore AA0206

        if Description <> '' then
            case true of
                Description.Contains(UpperCase(DateKeywordTxt)):
                    QltyFieldType := QltyFieldType::"Field Type Date";

                Description.Contains(UpperCase(TrackingKeyword1Txt)),
                Description.Contains(UpperCase(TrackingKeyword2Txt)),
                Description.Contains(UpperCase(TrackingKeyword3Txt)),
                Description.Contains(UpperCase(TrackingKeyword4Txt)):
                    QltyFieldType := QltyFieldType::"Field Type Text";

                Description.StartsWith(UpperCase(YesNoKeyword1Txt)),
                Description.StartsWith(UpperCase(YesNoKeyword2Txt)),
                Description.StartsWith(UpperCase(YesNoKeyword3Txt)),
                Description.StartsWith(UpperCase(YesNoKeyword4Txt)),
                Description.StartsWith(UpperCase(YesNoKeyword5Txt)):
                    QltyFieldType := QltyFieldType::"Field Type Boolean";
            end;
    end;

    /// <summary>
    /// Opens the source document associated with a quality inspection test in its appropriate page.
    /// Automatically determines the correct page to display based on the source record type.
    /// 
    /// Behavior:
    /// - Fires OnBeforeNavigateToSourceDocument event for extensibility
    /// - Exits if no source document is linked (Source RecordId is empty)
    /// - Uses Page Management to find the appropriate page for the record type
    /// - Opens the page in modal mode displaying the source document
    /// 
    /// Common usage: "View Source" button on inspection test pages to jump to originating document
    /// (e.g., Purchase Order, Sales Order, Production Order).
    /// </summary>
    /// <param name="QltyInspectionTestHeader">The inspection test whose source document should be displayed</param>
    procedure NavigateToSourceDocument(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        PageManagement: Codeunit "Page Management";
        RecordRefToNavigateTo: RecordRef;
        VariantContainer: Variant;
        CurrentPage: Integer;
        Handled: Boolean;
    begin
        OnBeforeNavigateToSourceDocument(QltyInspectionTestHeader, Handled);
        if Handled then
            exit;

        if QltyInspectionTestHeader."Source RecordId".TableNo() = 0 then
            exit;

        RecordRefToNavigateTo := QltyInspectionTestHeader."Source RecordId".GetRecord();
        CurrentPage := PageManagement.GetPageID(RecordRefToNavigateTo);
        VariantContainer := RecordRefToNavigateTo;
        Page.RunModal(CurrentPage, VariantContainer);
    end;

    /// <summary>
    /// Opens the Navigate page to find all related entries for an inspection test's source document.
    /// Pre-fills search criteria with test source information including item, document number, and tracking.
    /// 
    /// Populated Navigate criteria:
    /// - Source Item No.
    /// - Source Document No.
    /// - Source Lot No. (if tracked)
    /// - Source Serial No. (if tracked)
    /// - Source Package No. (if tracked)
    /// - Source Table: Quality Inspection Test Header
    /// 
    /// Common usage: Finding all ledger entries, posted documents, and transactions related to
    /// the item and document that triggered the inspection test.
    /// </summary>
    /// <param name="QltyInspectionTestHeader">The inspection test whose related entries should be found</param>
    internal procedure NavigateToFindEntries(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        Navigate: Page Navigate;
    begin
        TempItemTrackingSetup."Lot No." := QltyInspectionTestHeader."Source Lot No.";
        TempItemTrackingSetup."Serial No." := QltyInspectionTestHeader."Source Serial No.";
        TempItemTrackingSetup."Package No." := QltyInspectionTestHeader."Source Package No.";

        Navigate.SetSource(0D, CopyStr(QltyInspectionTestHeader.TableCaption(), 1, 100), QltyInspectionTestHeader."No.", Database::"Qlty. Inspection Test Header", QltyInspectionTestHeader."Source Item No.");
        Navigate.SetTracking(TempItemTrackingSetup);
        Navigate.SetDoc(0D, QltyInspectionTestHeader."Source Document No.");
        Navigate.Run();
    end;

    /// <summary>
    /// Provides an ability to override the handling of navigating to a source document.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNavigateToSourceDocument(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var Handled: Boolean)
    begin
    end;
}
