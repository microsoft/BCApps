// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;

codeunit 20599 "Qlty. Misc Helpers"
{
    var
        DateKeywordTxt: Label 'Date';
        YesNoKeyword1Txt: Label 'Does the';
        YesNoKeyword2Txt: Label 'Do the';
        YesNoKeyword3Txt: Label 'Is the';
        YesNoKeyword4Txt: Label 'Did you';
        YesNoKeyword5Txt: Label 'Have you';
        TrackingKeyword1Txt: Label 'lot #';
        TrackingKeyword2Txt: Label 'serial #';
        TrackingKeyword3Txt: Label 'package #';
        TrackingKeyword4Txt: Label 'lot number';
        TrackingKeyword5Txt: Label 'serial number';
        TrackingKeyword6Txt: Label 'package number';
        UnableToSetTableValueTableNotFoundErr: Label 'Unable to set a value because the table [%1] was not found.', Comment = '%1=the table name';
        UnableToSetTableValueFieldNotFoundErr: Label 'Unable to set a value because the field [%1] in table [%2] was not found.', Comment = '%1=the field name, %2=the table name';
        BadTableTok: Label '?table?', Locked = true;
        BadFieldTok: Label '?t:%1?f:%2?', Locked = true, Comment = '%1=the table, %2=the requested field';


    /// <summary>
    /// Retrieves available record values for a table lookup field configured on an inspection line, returned as CSV.
    /// Evaluates expressions and applies filters configured in the field definition to generate the list.
    /// 
    /// Common usage: Populating dropdown lists or validating user input against configured lookup values.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line containing the table field configuration</param>
    /// <returns>Comma-separated string of available lookup values</returns>
    internal procedure GetRecordsForTableFieldAsCSV(var QltyInspectionLine: Record "Qlty. Inspection Line") CSVText: Text
    var
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        NeedComma: Boolean;
    begin
        QltyMiscHelpers.GetRecordsForTableField(QltyInspectionLine, TempBufferQltyTestLookupValue);
        if TempBufferQltyTestLookupValue.FindSet() then
            repeat
                if NeedComma then
                    CSVText += ',';

                NeedComma := true;
                CSVText += Format(TempBufferQltyTestLookupValue."Value");
            until TempBufferQltyTestLookupValue.Next() = 0
    end;

    /// <summary>
    /// Retrieves available records for a table lookup field configured on an inspection line.
    /// Evaluates expressions and applies configured table filters to populate the lookup buffer.
    /// 
    /// This overload automatically loads the inspection header and field definition from the inspection line,
    /// then calls the main GetRecordsForTableField procedure.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line containing the field code to look up</param>
    /// <param name="TempBufferQltyTestLookupValue">Output: Temporary buffer filled with available lookup values and descriptions</param>
    internal procedure GetRecordsForTableField(var QltyInspectionLine: Record "Qlty. Inspection Line"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyTest: Record "Qlty. Test";
    begin
        QltyInspectionHeader.Get(QltyInspectionLine."Inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyTest.Get(QltyInspectionLine."Test Code");
        GetRecordsForTableField(QltyTest, QltyInspectionHeader, QltyInspectionLine, TempBufferQltyTestLookupValue);
    end;

    /// <summary>
    /// Gets the available records for any given table field.
    /// This will evaluate expressions!
    /// </summary>
    /// <param name="QltyTest"></param>
    /// <param name="OptionalContextQltyInspectionHeader">Optional. Leave empty if you do not want search/replace fields.  Supply an inspection context if you want the lookup table filter to have square bracket [FIELDNAME] replacements </param>
    /// <param name="TempBufferQltyTestLookupValue"></param>
    internal procedure GetRecordsForTableField(var QltyTest: Record "Qlty. Test"; var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary)
    var
        TempDummyQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        GetRecordsForTableField(QltyTest, OptionalContextQltyInspectionHeader, TempDummyQltyInspectionLine, TempBufferQltyTestLookupValue);
    end;

    /// <summary>
    /// Retrieves lookup values for a quality field with context-sensitive filtering.
    /// Evaluates dynamic table filters using Inspection context and populates temporary buffer with available choices.
    /// 
    /// Behavior:
    /// - Evaluates QltyTest."Lookup Table Filter" using inspection header/line context for dynamic filtering
    /// - For Qlty. Test Lookup Value table: includes both Code and Description fields
    /// - For other tables: uses only the specified lookup field
    /// - Applies maximum row limit from setup to prevent excessive data retrieval
    /// 
    /// Common usage: Populating dropdown lists in inspection lines with context-aware options.
    /// </summary>
    /// <param name="QltyTest">The quality field configuration defining lookup table and filters</param>
    /// <param name="OptionalContextQltyInspectionHeader">Inspection header providing context for filter expression evaluation</param>
    /// <param name="OptionalContextQltyInspectionLine">Inspection line providing context for filter expression evaluation</param>
    /// <param name="TempBufferQltyTestLookupValue">Output: Temporary buffer populated with lookup values</param>
    procedure GetRecordsForTableField(var QltyTest: Record "Qlty. Test"; var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalContextQltyInspectionLine: Record "Qlty. Inspection Line"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary)
    var
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        ReasonableMaximum: Integer;
        DummyText: Text;
        TableFilter: Text;
    begin
        if TempBufferQltyTestLookupValue.IsTemporary() then
            TempBufferQltyTestLookupValue.DeleteAll();

        ReasonableMaximum := QltyConfigurationHelpers.GetDefaultMaximumRowsFieldLookup();

        TableFilter := QltyExpressionMgmt.EvaluateTextExpression(QltyTest."Lookup Table Filter", OptionalContextQltyInspectionHeader, OptionalContextQltyInspectionLine);

        if QltyTest."Lookup Table No." = Database::"Qlty. Test Lookup Value" then
            GetRecordsForTableField(QltyTest."Lookup Table No.", QltyTest."Lookup Field No.", TempBufferQltyTestLookupValue.FieldNo(Description), TableFilter, ReasonableMaximum, TempBufferQltyTestLookupValue, DummyText)
        else
            GetRecordsForTableField(QltyTest."Lookup Table No.", QltyTest."Lookup Field No.", 0, TableFilter, ReasonableMaximum, TempBufferQltyTestLookupValue, DummyText);
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
    internal procedure GetCSVOfValuesFromRecord(CurrentTable: Integer; ChoiceField: Integer; TableFilter: Text; MaxCountRecords: Integer) ResultText: Text
    var
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
    begin
        GetRecordsForTableField(CurrentTable, ChoiceField, 0, TableFilter, MaxCountRecords, TempBufferQltyTestLookupValue, ResultText);
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
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
    begin
        GetRecordsForTableField(CurrentTable, ChoiceField, 0, TableFilter, QltyConfigurationHelpers.GetArbitraryMaximumRecursion(), TempBufferQltyTestLookupValue, ResultText);
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
    /// <param name="TempBufferQltyTestLookupValue"></param>
    /// <param name="CSVSimpleText"></param>
    local procedure GetRecordsForTableField(CurrentTable: Integer; ChoiceField: Integer; DescriptionField: Integer; TableFilter: Text; MaxCountRecords: Integer; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary; var CSVSimpleText: Text)
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
            if MaxCountRecords > MaxRecordsFetchLimit() then
                MaxCountRecords := MaxRecordsFetchLimit();
        end;

        RemainingCountRecordsToAdd := MaxCountRecords;
        if DescriptionField = 0 then
            DescriptionField := ChoiceField;
        RecordRefToFetch.Open(CurrentTable);
        if TableFilter <> '' then
            RecordRefToFetch.SetView(TableFilter);

        LoopSafety := MaxRecordsFetchLimit();
        if RecordRefToFetch.FindSet() then
            repeat
                LoopSafety -= 1;
                FieldRefToChoiceField := RecordRefToFetch.Field(ChoiceField);
                FieldRefToDescriptionField := RecordRefToFetch.Field(DescriptionField);
                TempBufferQltyTestLookupValue."Lookup Group Code" := CopyStr(PadStr(Format(RemainingCountRecordsToAdd), MaxStrLen(TempBufferQltyTestLookupValue."Lookup Group Code"), '0'), 1, MaxStrLen(TempBufferQltyTestLookupValue."Lookup Group Code"));
                ValueToAddToList := CopyStr(Format(FieldRefToChoiceField.Value()), 1, MaxStrLen(TempBufferQltyTestLookupValue."Custom 1")).Trim();
                if not DuplicateChecker.Contains(ValueToAddToList) then begin
                    RemainingCountRecordsToAdd -= 1;
                    DuplicateChecker.Add(ValueToAddToList);
                    TempBufferQltyTestLookupValue."Custom 1" := CopyStr(ValueToAddToList, 1, MaxStrLen(TempBufferQltyTestLookupValue."Custom 1"));
                    TempBufferQltyTestLookupValue."Custom 2" := TempBufferQltyTestLookupValue."Custom 1".ToLower();
                    TempBufferQltyTestLookupValue."Custom 3" := TempBufferQltyTestLookupValue."Custom 1".ToUpper();
                    TempBufferQltyTestLookupValue."Value" := CopyStr(TempBufferQltyTestLookupValue."Custom 1", 1, MaxStrLen(TempBufferQltyTestLookupValue."Value"));
                    TempBufferQltyTestLookupValue.Description := CopyStr(Format(FieldRefToDescriptionField.Value()), 1, MaxStrLen(TempBufferQltyTestLookupValue.Description));
                    if (TempBufferQltyTestLookupValue.Description = '') and (TempBufferQltyTestLookupValue."Custom 1" <> '') then
                        TempBufferQltyTestLookupValue.Description := TempBufferQltyTestLookupValue."Custom 1";

                    TempBufferQltyTestLookupValue.Insert();
                    if HasAtLeastOne then
                        CSVSimpleText += ',';
                    CSVSimpleText += TempBufferQltyTestLookupValue."Custom 1";
                end;
                HasAtLeastOne := true;

            until (RecordRefToFetch.Next() = 0) or (RemainingCountRecordsToAdd <= 0) or (LoopSafety <= 0);

        RecordRefToFetch.Close();
    end;

    local procedure MaxRecordsFetchLimit(): Integer
    begin
        exit(1000);
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
    ///    - Contains tracking keywords ("lot", "serial", "package") → Field Type Text
    ///    - Starts with yes/no keywords → Field Type Boolean
    /// 3. Default fallback → Field Type Text
    /// 
    /// Common usage: Auto-configuration of fields during template import or field creation setup guides.
    /// </summary>
    /// <param name="Description">The field description text to analyze for type hints</param>
    /// <param name="OptionalValue">Optional sample value to analyze for type detection</param>
    /// <returns>The guessed field type enum value</returns>
    internal procedure GuessDataTypeFromDescriptionAndValue(Description: Text; OptionalValue: Text) QltyTestValueType: Enum "Qlty. Test Value Type"
    var
        QltyBooleanParsing: Codeunit "Qlty. Boolean Parsing";
        TestDateTime: Date;
        TestDate: Date;
    begin
        Description := UpperCase(Description);
        QltyTestValueType := QltyTestValueType::"Value Type Text";
        if OptionalValue <> '' then
#pragma warning disable AA0206
            case true of
                QltyBooleanParsing.CanTextBeInterpretedAsBooleanIsh(Text.DelChr(OptionalValue, '=', ' ').ToUpper()):
                    QltyTestValueType := QltyTestValueType::"Value Type Boolean";
                IsNumericText(OptionalValue):
                    QltyTestValueType := QltyTestValueType::"Value Type Decimal";
                Evaluate(TestDate, OptionalValue):
                    QltyTestValueType := QltyTestValueType::"Value Type Date";
                Evaluate(TestDateTime, OptionalValue):
                    QltyTestValueType := QltyTestValueType::"Value Type DateTime";
                Evaluate(TestDateTime, OptionalValue, 9):
                    QltyTestValueType := QltyTestValueType::"Value Type DateTime";
            end;
#pragma warning restore AA0206

        if Description <> '' then
            case true of
                Description.Contains(UpperCase(DateKeywordTxt)):
                    QltyTestValueType := QltyTestValueType::"Value Type Date";

                Description.Contains(UpperCase(TrackingKeyword1Txt)),
                Description.Contains(UpperCase(TrackingKeyword2Txt)),
                Description.Contains(UpperCase(TrackingKeyword3Txt)),
                Description.Contains(UpperCase(TrackingKeyword4Txt)),
                Description.Contains(UpperCase(TrackingKeyword5Txt)),
                Description.Contains(UpperCase(TrackingKeyword6Txt)):
                    QltyTestValueType := QltyTestValueType::"Value Type Text";

                Description.StartsWith(UpperCase(YesNoKeyword1Txt)),
                Description.StartsWith(UpperCase(YesNoKeyword2Txt)),
                Description.StartsWith(UpperCase(YesNoKeyword3Txt)),
                Description.StartsWith(UpperCase(YesNoKeyword4Txt)),
                Description.StartsWith(UpperCase(YesNoKeyword5Txt)):
                    QltyTestValueType := QltyTestValueType::"Value Type Boolean";
            end;
    end;

    /// <summary>
    /// Sets a field value in any table record identified by name/ID with optional validation.
    /// Provides flexible table and field identification using names, captions, or numeric IDs.
    /// 
    /// Resolution order:
    /// - TableName: Checked as object name → object caption → integer ID
    /// - NumberOrNameOfFieldToSet: Checked as field name → field number
    /// 
    /// Behavior:
    /// - Opens table and applies filter to find target record
    /// - Uses first matching record (FindFirst)
    /// - Applies value with optional validation
    /// - Throws error if table or field not found
    /// 
    /// Common usage: Generic field updates during automated test execution or configuration import.
    /// </summary>
    /// <param name="TableName">Table identifier (name, caption, or numeric ID as text)</param>
    /// <param name="TableFilter">AL filter syntax to identify the record(s) to update</param>
    /// <param name="NumberOrNameOfFieldToSet">Field identifier (name or numeric ID as text)</param>
    /// <param name="ValueToSet">The text value to set (will be evaluated based on field type)</param>
    /// <param name="Validate">True to trigger field validation; False to skip validation</param>
    internal procedure SetTableValue(TableName: Text; TableFilter: Text; NumberOrNameOfFieldToSet: Text; ValueToSet: Text; Validate: Boolean)
    var
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        RecordRefToSet: RecordRef;
        FieldRefToSet: FieldRef;
        TableToOpen: Integer;
        FieldNumber: Integer;
    begin
        TableToOpen := QltyFilterHelpers.IdentifyTableIDFromText(TableName);
        if TableToOpen = 0 then
            Error(UnableToSetTableValueTableNotFoundErr, TableName);

        RecordRefToSet.Open(TableToOpen);
        RecordRefToSet.SetView(TableFilter);
        FieldNumber := QltyFilterHelpers.IdentifyFieldIDFromText(TableToOpen, NumberOrNameOfFieldToSet);
        if FieldNumber = 0 then
            Error(UnableToSetTableValueFieldNotFoundErr, NumberOrNameOfFieldToSet, TableName);

        FieldRefToSet := RecordRefToSet.Field(FieldNumber);
        RecordRefToSet.FindFirst();
        ConfigValidateManagement.EvaluateTextToFieldRef(ValueToSet, FieldRefToSet, Validate);
        RecordRefToSet.Modify();
    end;

    /// <summary>
    /// Reads a field value from any record variant and returns it as formatted text.
    /// Provides flexible field identification and configurable formatting options.
    /// 
    /// Field identification:
    /// - NumberOrNameOfFieldName: Field name or numeric ID as text
    /// 
    /// Formatting behavior:
    /// - FormatNumber parameter controls output format per Business Central Format() method
    /// - Standard formats: 0 (default), 9 (XML format), etc.
    /// - FlowFields are automatically calculated before reading
    /// 
    /// Error handling:
    /// - Returns "?table?" if variant cannot be converted to RecordRef
    /// - Returns "?t:[TableNo]?f:[FieldName]?" if field not found
    /// 
    /// Common usage: Generic field reading in expression evaluation, report generation, or dynamic UI display.
    /// </summary>
    /// <param name="CurrentRecordVariant">Variant containing a record reference</param>
    /// <param name="NumberOrNameOfFieldName">Field identifier (name or numeric ID as text)</param>
    /// <param name="FormatNumber">Format code per Business Central Format() method (0=default, 9=XML, etc.)</param>
    /// <returns>The field value as formatted text, or error marker if field/table invalid</returns>
    internal procedure ReadFieldAsText(CurrentRecordVariant: Variant; NumberOrNameOfFieldName: Text; FormatNumber: Integer) ResultText: Text
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        RecordRefToRead: RecordRef;
        FieldRefToRead: FieldRef;
        FieldNo: Integer;
    begin
        ResultText := BadTableTok;

        if not GetRecordRefFromVariant(CurrentRecordVariant, RecordRefToRead) then
            exit;

        ResultText := StrSubstNo(BadFieldTok, RecordRefToRead.Number(), NumberOrNameOfFieldName);
        FieldNo := QltyFilterHelpers.IdentifyFieldIDFromText(RecordRefToRead.Number(), NumberOrNameOfFieldName);
        if FieldNo <= 0 then
            exit;

        FieldRefToRead := RecordRefToRead.Field(FieldNo);
        if FieldRefToRead.Class() = FieldClass::FlowField then
            FieldRefToRead.CalcField();
        ResultText := Format(FieldRefToRead.Value(), 0, FormatNumber);
    end;

    internal procedure GetUserNameByUserSecurityID(UserSecurityID: Guid): Code[50]
    var
        User: Record "User";
        EmptyGuid: Guid;
    begin
        case true of
            UserSecurityID = EmptyGuid,
            not User.ReadPermission(),
            not User.Get(UserSecurityID):
                exit('');
        end;

        exit(User."User Name");
    end;

    internal procedure GetRecordRefFromVariant(CurrentVariant: Variant; var RecordRef: RecordRef): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        if not DataTypeManagement.GetRecordRef(CurrentVariant, RecordRef) then
            exit(false);

        exit(RecordRef.Number() <> 0);
    end;
}
