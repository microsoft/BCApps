// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Navigate;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

codeunit 20599 "Qlty. Misc Helpers"
{
    var
        TranslatableYesLbl: Label 'Yes';
        TranslatableNoLbl: Label 'No';
        LockedYesLbl: Label 'Yes', Locked = true;
        LockedNoLbl: Label 'No', Locked = true;
        ImportFromLbl: Label 'Import From File';
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
        UnableToSetTableValueTableNotFoundErr: Label 'Unable to set a value because the table [%1] was not found.', Comment = '%1=the table name';
        UnableToSetTableValueFieldNotFoundErr: Label 'Unable to set a value because the field [%1] in table [%2] was not found.', Comment = '%1=the field name, %2=the table name';
        BadTableTok: Label '?table?', Locked = true;
        BadFieldTok: Label '?t:%1?f:%2?', Locked = true, Comment = '%1=the table, %2=the requested field';

    /// <summary>
    /// Returns the translatable "Yes" label with maximum length of 250 characters.
    /// Used for UI display and user-facing text where localization is required.
    /// </summary>
    /// <returns>The localized "Yes" text (up to 250 characters)</returns>
    procedure GetTranslatedYes250(): Text[250]
    begin
        exit(TranslatableYesLbl);
    end;

    /// <summary>
    /// Returns the translatable "No" label with maximum length of 250 characters.
    /// Used for UI display and user-facing text where localization is required.
    /// </summary>
    /// <returns>The localized "No" text (up to 250 characters)</returns>
    procedure GetTranslatedNo250(): Text[250]
    begin
        exit(TranslatableNoLbl);
    end;

    /// <summary>
    /// The maximum recursion to use when creating tests.
    /// Used for traversal on source table configuration when finding applicable generation rules, and also when populating source fields.
    /// 
    /// This limit prevents infinite loops in complex configuration hierarchies and ensures reasonable performance
    /// when traversing multi-level table relationships.
    /// </summary>
    /// <returns>The maximum recursion depth allowed (currently 20 levels)</returns>
    internal procedure GetArbitraryMaximumRecursion(): Integer
    begin
        exit(20);
    end;

    internal procedure GetDefaultMaximumRowsFieldLookup() ResultRowsCount: Integer
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Handled: Boolean;
    begin
        ResultRowsCount := 100;
        OnBeforeGetDefaultMaximumRowsToShowInLookup(ResultRowsCount, Handled);
        if Handled then
            exit;

        if not QltyManagementSetup.ReadPermission() then
            exit;
        if not QltyManagementSetup.Get() then
            exit;

        if QltyManagementSetup."Max Rows Field Lookups" > 0 then
            ResultRowsCount := QltyManagementSetup."Max Rows Field Lookups";
    end;

    /// <summary>
    /// Prompts the user to select a file and imports its contents into an InStream for processing.
    /// Displays a file upload dialog with optional file type filtering.
    /// 
    /// Common usage: Importing configuration files, test data, or external quality inspection results.
    /// </summary>
    /// <param name="FilterString">File type filter for the upload dialog (e.g., "*.xml|*.txt")</param>
    /// <param name="InStream">Output: InStream containing the uploaded file contents</param>
    /// <returns>True if file was successfully selected and uploaded; False if user cancelled or upload failed</returns>
    procedure PromptAndImportIntoInStream(FilterString: Text; var InStream: InStream) Worked: Boolean
    var
        ServerFile: Text;
    begin
        Worked := UploadIntoStream(ImportFromLbl, '', FilterString, ServerFile, InStream);
    end;

    /// <summary>
    /// Attempts to parse simple range notation (min..max) into separate minimum and maximum decimal values.
    /// Handles the common 90% use case of range specifications in quality inspection tests.
    /// 
    /// Examples:
    /// - "10..20" → OutMin=10, OutMax=20, returns true
    /// - "5.5..10.5" → OutMin=5.5, OutMax=10.5, returns true
    /// - "Invalid" → returns false
    /// - "10" → returns false (not a range)
    /// </summary>
    /// <param name="InputText">The text containing a range in format "minValue..maxValue"</param>
    /// <param name="MinValueInRange">Output: The minimum value from the range</param>
    /// <param name="MaxValueInRange">Output: The maximum value from the range</param>
    /// <returns>True if successfully parsed as a simple range; False if input doesn't match simple range pattern</returns>
    procedure AttemptSplitSimpleRangeIntoMinMax(InputText: Text; var MinValueInRange: Decimal; var MaxValueInRange: Decimal): Boolean
    var
        OfParts: List of [Text];
        Temp: Text;
    begin
        Clear(MaxValueInRange);
        Clear(MinValueInRange);

        if InputText.Contains('..') then
            if InputText.IndexOf('..') > 0 then begin
                OfParts := InputText.Split('..');
                if OfParts.Count() = 2 then begin
                    OfParts.Get(1, Temp);
                    if Evaluate(MinValueInRange, Temp) then begin
                        OfParts.Get(2, Temp);
                        if Evaluate(MaxValueInRange, Temp) then
                            exit(true);
                    end;
                end;
            end;
    end;

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
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        NeedComma: Boolean;
    begin
        QltyMiscHelpers.GetRecordsForTableField(QltyInspectionTestLine, TempBufferQltyLookupCode);
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
    procedure GetRecordsForTableField(var QltyField: Record "Qlty. Field"; var OptionalContextQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var OptionalContextQltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary)
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        ReasonableMaximum: Integer;
        DummyText: Text;
        TableFilter: Text;
    begin
        ReasonableMaximum := GetDefaultMaximumRowsFieldLookup();

        TableFilter := QltyExpressionMgmt.EvaluateTextExpression(QltyField."Lookup Table Filter", OptionalContextQltyInspectionTestHeader, OptionalContextQltyInspectionTestLine);

        if QltyField."Lookup Table No." = Database::"Qlty. Lookup Code" then
            GetRecordsForTableField(QltyField."Lookup Table No.", QltyField."Lookup Field No.", TempBufferQltyLookupCode.FieldNo(Description), TableFilter, ReasonableMaximum, TempBufferQltyLookupCode, DummyText)
        else
            GetRecordsForTableField(QltyField."Lookup Table No.", QltyField."Lookup Field No.", 0, TableFilter, ReasonableMaximum, TempBufferQltyLookupCode, DummyText);
    end;

    /// <summary>
    /// Generates a CSV string of values for a specific field from a table with optional filtering.
    /// Retrieves up to MaxRecords records and formats field values as comma-separated text.
    /// 
    /// Example: For Item table, Location Code field → "BLUE,RED,GREEN,YELLOW"
    /// 
    /// Common usage: Building dropdown lists, generating reports, or creating filter strings.
    /// </summary>
    /// <param name="CurrentTable">The table number to retrieve records from</param>
    /// <param name="ChoiceField">The field number whose values should be extracted</param>
    /// <param name="TableFilter">Optional filter to apply to the table (AL filter syntax)</param>
    /// <param name="MaxRecords">Maximum number of records to include in the CSV output</param>
    /// <returns>Comma-separated string of field values</returns>
    procedure GetCSVOfValuesFromRecord(CurrentTable: Integer; ChoiceField: Integer; TableFilter: Text; MaxRecords: Integer) ResultText: Text
    var
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
    begin
        GetRecordsForTableField(CurrentTable, ChoiceField, 0, TableFilter, MaxRecords, TempBufferQltyLookupCode, ResultText);
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
    begin
        GetRecordsForTableField(CurrentTable, ChoiceField, 0, TableFilter, GetArbitraryMaximumRecursion(), TempBufferQltyLookupCode, ResultText);
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
    /// <param name="MaxRecords"></param>
    /// <param name="TempBufferQltyLookupCode"></param>
    /// <param name="CSVSimpleText"></param>
    local procedure GetRecordsForTableField(CurrentTable: Integer; ChoiceField: Integer; DescriptionField: Integer; TableFilter: Text; MaxRecords: Integer; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary; var CSVSimpleText: Text)
    var
        RecordRefToFetch: RecordRef;
        FieldRefToChoiceField: FieldRef;
        FieldRefToDescriptionField: FieldRef;
        RemainingMaxRecordsToAdd: Integer;
        LoopSafety: Integer;
        HasAtLeastOne: Boolean;
        DuplicateChecker: List of [Text];
        ValueToAddToList: Text;
    begin
        if CurrentTable = 0 then
            exit;
        if ChoiceField = 0 then
            exit;

        if MaxRecords <= 0 then begin
            MaxRecords := GetDefaultMaximumRowsFieldLookup();
            if MaxRecords <= 0 then
                MaxRecords := 1;
            if MaxRecords > 1000 then
                MaxRecords := 1000;
        end;

        RemainingMaxRecordsToAdd := MaxRecords;
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
                TempBufferQltyLookupCode."Group Code" := CopyStr(PadStr(Format(RemainingMaxRecordsToAdd), MaxStrLen(TempBufferQltyLookupCode."Group Code"), '0'), 1, MaxStrLen(TempBufferQltyLookupCode."Group Code"));
                ValueToAddToList := CopyStr(Format(FieldRefToChoiceField.Value()), 1, MaxStrLen(TempBufferQltyLookupCode."Custom 1")).Trim();
                if not DuplicateChecker.Contains(ValueToAddToList) then begin
                    RemainingMaxRecordsToAdd -= 1;
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

            until (RecordRefToFetch.Next() = 0) or (RemainingMaxRecordsToAdd <= 0) or (LoopSafety <= 0);

        RecordRefToFetch.Close();
    end;

    /// <summary>
    /// Converts text input to a boolean value using flexible interpretation rules.
    /// Treats any positive boolean representation as true, everything else as false.
    /// 
    /// Recognized as TRUE (case-insensitive):
    /// - Standard: "Yes", "Y", "True", "T", "1", "On"
    /// - Quality-specific: "Positive", "Check", "Checked", "Good", "Pass", "Passed", "Acceptable", "OK"
    /// - Special: "V" (checkmark), ":SELECTED:"
    /// 
    /// All other values (including empty string) return FALSE.
    /// 
    /// Note: This does NOT validate if input looks like a boolean - it converts any input to boolean.
    /// </summary>
    /// <param name="Input">The text value to convert to boolean</param>
    /// <returns>True if input matches any positive boolean representation; False otherwise</returns>
    procedure GetBooleanFor(Input: Text) IsTrue: Boolean
    begin
        if Input <> '' then begin
            if not Evaluate(IsTrue, Input) then
                exit(IsTextValuePositiveBoolean(Input));

            case UpperCase(Input) of
                UpperCase(TranslatableYesLbl), UpperCase(LockedYesLbl),
                'Y', 'YES', 'T', 'TRUE', '1', 'POSITIVE', 'ENABLED', 'CHECK', 'CHECKED',
                'GOOD', 'PASS', 'ACCEPTABLE', 'PASSED', 'OK', 'ON',
                'V', ':SELECTED:':
                    IsTrue := true;
            end;
        end;
    end;

    /// <summary>
    /// Checks if a text value represents a "positive" or "true-ish" boolean value.
    /// 
    /// IMPORTANT: This does NOT validate whether the text is boolean-like.
    /// It ONLY returns true if the text matches a positive boolean representation.
    /// Non-boolean text and negative boolean values both return false.
    /// 
    /// Use case: Quality inspection where "Pass", "Good", "Acceptable" should be treated as true.
    /// 
    /// See GetBooleanFor() for the complete list of recognized positive values.
    /// </summary>
    /// <param name="ValueToCheckIfPositiveBoolean">The text value to check</param>
    /// <returns>True if the value represents a positive/affirmative boolean; False otherwise</returns>
    procedure IsTextValuePositiveBoolean(ValueToCheckIfPositiveBoolean: Text): Boolean
    var
        ConvertedBoolean: Boolean;
    begin
        ValueToCheckIfPositiveBoolean := ValueToCheckIfPositiveBoolean.Trim();

        if Evaluate(ConvertedBoolean, ValueToCheckIfPositiveBoolean) then
            if ConvertedBoolean then
                exit(true);

        case UpperCase(ValueToCheckIfPositiveBoolean) of
            UpperCase(TranslatableYesLbl),
            UpperCase(LockedYesLbl),
            'Y',
            'YES',
            'T',
            'TRUE',
            '1',
            'POSITIVE',
            'ENABLED',
            'CHECK',
            'CHECKED',
            'GOOD',
            'PASS',
            'ACCEPTABLE',
            'PASSED',
            'OK',
            'ON',
            'V',
            ':SELECTED:':
                exit(true);
        end;
    end;

    /// <summary>
    /// Checks if text represents a negative/false boolean value.
    /// Only returns true for negative boolean representations; does NOT validate if text is boolean-like.
    /// 
    /// Recognized negative values (case-insensitive):
    /// - Standard: "No", "N", "False", "F", "0"
    /// - Quality-specific: "Bad", "Fail", "Failed", "Unacceptable", "NotOK"
    /// - UI states: "Disabled", "Off", "Uncheck", "Unchecked", ":UNSELECTED:"
    /// - Other: "Negative"
    /// 
    /// Important: Returns false for positive values AND for non-boolean text.
    /// Use CanTextBeInterpretedAsBooleanIsh() first to validate if text is boolean-like.
    /// 
    /// Common usage: Evaluating inspection test results for failure conditions.
    /// </summary>
    /// <param name="ValueToCheckIfNegativeBoolean">The text value to check for negative boolean representation</param>
    /// <returns>True if text represents a negative boolean value; False otherwise (including positive values)</returns>
    procedure IsTextValueNegativeBoolean(ValueToCheckIfNegativeBoolean: Text): Boolean
    var
        ConvertedBoolean: Boolean;
    begin
        ValueToCheckIfNegativeBoolean := ValueToCheckIfNegativeBoolean.Trim();

        if Evaluate(ConvertedBoolean, ValueToCheckIfNegativeBoolean) then
            if not ConvertedBoolean then
                exit(true);

        case UpperCase(ValueToCheckIfNegativeBoolean) of
            UpperCase(TranslatableNoLbl),
            UpperCase(LockedNoLbl),
            'N',
            'NO',
            'F',
            'FALSE',
            '0',
            'NEGATIVE',
            'DISABLED',
            'UNCHECK',
            'UNCHECKED',
            'BAD',
            'FAIL',
            'UNACCEPTABLE',
            'FAILED',
            'NOTOK',
            'OFF',
            ':UNSELECTED:':
                exit(true);
        end;
    end;

    /// <summary>
    /// Checks if text can be interpreted as a boolean-like value (positive or negative).
    /// Detects whether input looks like a boolean representation, regardless of its value.
    /// 
    /// Returns true if input matches any boolean representation:
    /// - Positive: "Yes", "True", "Pass", "Good", etc.
    /// - Negative: "No", "False", "Fail", "Bad", etc.
    /// 
    /// Use case: Validating user input before conversion or determining field data type hints.
    /// 
    /// Note: This checks if text LOOKS like a boolean, not what boolean value it represents.
    /// For conversion, use GetBooleanFor() instead.
    /// </summary>
    /// <param name="InputText">The text to check for boolean-like characteristics</param>
    /// <returns>True if text appears to be a boolean representation; False otherwise</returns>
    procedure CanTextBeInterpretedAsBooleanIsh(InputText: Text): Boolean
    begin
        exit(IsTextValuePositiveBoolean(InputText) or IsTextValueNegativeBoolean(InputText));
    end;

    /// <summary>
    /// Extracts person contact details from an inspection test line if it references a person-related record.
    /// Validates that the test line is a table lookup type referencing a supported person table before retrieval.
    /// 
    /// Supported person tables (validated via Field configuration):
    /// - Contact, Employee, Resource, User, User Setup, Salesperson/Purchaser
    /// 
    /// Returns false early if:
    /// - Test Value is empty
    /// - Field Type is not "Field Type Table Lookup"
    /// - Field Code is invalid
    /// - Lookup Table is not a person-related table
    /// 
    /// Common usage: Displaying inspector/approver details in test forms and reports.
    /// </summary>
    /// <param name="QltyInspectionTestLine">The inspection test line containing the person reference</param>
    /// <param name="FullName">Output: The person's full name</param>
    /// <param name="JobTitle">Output: The person's job title</param>
    /// <param name="EmailAddress">Output: The person's email address</param>
    /// <param name="PhoneNo">Output: The person's phone number</param>
    /// <param name="SourceRecordId">Output: RecordId of the source person record</param>
    /// <returns>True if test line references a person and details were retrieved; False otherwise</returns>
    procedure GetBasicPersonDetailsFromTestLine(QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var FullName: Text; var JobTitle: Text; var EmailAddress: Text; var PhoneNo: Text; var SourceRecordId: RecordId): Boolean
    var
        QltyField: Record "Qlty. Field";
    begin
        Clear(FullName);
        Clear(JobTitle);
        Clear(EmailAddress);
        Clear(PhoneNo);
        Clear(SourceRecordId);

        if QltyInspectionTestLine."Test Value" = '' then
            exit(false);

        if not (QltyInspectionTestLine."Field Type" in [QltyInspectionTestLine."Field Type"::"Field Type Table Lookup"]) then
            exit(false);

        if not QltyField.Get(QltyInspectionTestLine."Field Code") then
            exit(false);

        if not (QltyField."Lookup Table No." in [
            Database::Contact,
            Database::Employee,
            Database::Resource,
            Database::User,
            Database::"User Setup",
            Database::"Salesperson/Purchaser"])
        then
            exit(false);

        exit(GetBasicPersonDetails(
            QltyInspectionTestLine."Test Value",
            FullName,
            JobTitle,
            EmailAddress,
            PhoneNo,
            SourceRecordId));
    end;

    /// <summary>
    /// Retrieves basic contact information for a person from any supported person-related record type.
    /// Searches across multiple tables to find contact details by primary key.
    /// 
    /// Supported record types:
    /// - Contact
    /// - Employee
    /// - Resource
    /// - User
    /// - User Setup
    /// - Salesperson/Purchaser
    /// 
    /// Common usage: Displaying inspector/approver details in quality inspection reports and forms.
    /// </summary>
    /// <param name="Input">The primary key value to search for (e.g., User ID, Contact No., Employee No.)</param>
    /// <param name="FullName">Output: The person's full name</param>
    /// <param name="JobTitle">Output: The person's job title or position</param>
    /// <param name="EmailAddress">Output: The person's email address</param>
    /// <param name="PhoneNo">Output: The person's phone number</param>
    /// <param name="SourceRecordId">Output: RecordId of the source record where details were found</param>
    /// <returns>True if person details were found in any supported table; False otherwise</returns>
    procedure GetBasicPersonDetails(Input: Text; var FullName: Text; var JobTitle: Text; var EmailAddress: Text; var PhoneNo: Text; var SourceRecordId: RecordId) HasDetails: Boolean
    var
        Contact: Record Contact;
        Employee: Record Employee;
        User: Record User;
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        Clear(FullName);
        Clear(JobTitle);
        Clear(EmailAddress);
        Clear(PhoneNo);
        Clear(SourceRecordId);
        if Input = '' then
            exit(false);

        if Contact.ReadPermission() then
            if Contact.Get(CopyStr(Input, 1, MaxStrLen(Contact."No."))) then begin
                FullName := Contact.Name;
                JobTitle := Contact."Job Title";
                EmailAddress := Contact."E-Mail";
                PhoneNo := Contact."Phone No.";
                SourceRecordId := Contact.RecordId();
                exit(true);
            end;

        if Employee.ReadPermission() then
            if Employee.Get(CopyStr(Input, 1, MaxStrLen(Employee."No."))) then begin
                FullName := Employee.FullName();
                JobTitle := Employee."Job Title";
                EmailAddress := Employee."E-Mail";
                PhoneNo := Employee."Phone No.";
                SourceRecordId := Employee.RecordId();
                exit(true);
            end;

        if Resource.ReadPermission() then
            if Resource.Get(CopyStr(Input, 1, MaxStrLen(Resource."No."))) then
                if Resource.Type = Resource.Type::Person then begin
                    FullName := Resource.Name;
                    JobTitle := Resource."Job Title";
                    EmailAddress := '';
                    PhoneNo := '';
                    SourceRecordId := Resource.RecordId();
                    exit(true);
                end;

        if User.ReadPermission() then begin
            User.SetRange("User Name", CopyStr(Input, 1, MaxStrLen(User."User Name")));
            if User.FindFirst() then begin
                HasDetails := true;
                FullName := User."Full Name";
                JobTitle := '';
                EmailAddress := User."Contact Email";
                PhoneNo := '';
                SourceRecordId := User.RecordId();
                if UserSetup.ReadPermission() then begin
                    if UserSetup.Get(User."User Name") then begin
                        SourceRecordId := UserSetup.RecordId();
                        if UserSetup."E-Mail" <> '' then
                            EmailAddress := UserSetup."E-Mail";
                        if UserSetup."Phone No." <> '' then
                            PhoneNo := UserSetup."Phone No.";

                        if UserSetup."Salespers./Purch. Code" <> '' then
                            Input := UserSetup."Salespers./Purch. Code";
                    end else
                        exit(true);
                end else
                    exit(true);
            end;

            if SalespersonPurchaser.ReadPermission() then
                if SalespersonPurchaser.Get(CopyStr(Input, 1, MaxStrLen(SalespersonPurchaser.Code))) then begin
                    if SalespersonPurchaser.Name <> '' then
                        FullName := SalespersonPurchaser.Name;
                    if SalespersonPurchaser."Job Title" <> '' then
                        JobTitle := SalespersonPurchaser."Job Title";
                    if SalespersonPurchaser."E-Mail" <> '' then
                        EmailAddress := SalespersonPurchaser."E-Mail";

                    if SalespersonPurchaser."Phone No." <> '' then
                        PhoneNo := SalespersonPurchaser."Phone No.";
                    SourceRecordId := SalespersonPurchaser.RecordId();
                    exit(true);
                end;
        end;
    end;

    internal procedure IsNumericText(Input: Text): Boolean
    var
#pragma warning disable AA0206
        TestNumber: Decimal;
    begin
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
#pragma warning disable AA0206
        TestDateTime: Date;
        TestDate: Date;
    begin
        Description := UpperCase(Description);
        QltyFieldType := QltyFieldType::"Field Type Text";
        if OptionalValue <> '' then
            case true of
                CanTextBeInterpretedAsBooleanIsh(Text.DelChr(OptionalValue, '=', ' ').ToUpper()):
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

#pragma warning restore AA0206
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
    procedure SetTableValue(TableName: Text; TableFilter: Text; NumberOrNameOfFieldToSet: Text; ValueToSet: Text; Validate: Boolean)
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
    procedure ReadFieldAsText(CurrentRecordVariant: Variant; NumberOrNameOfFieldName: Text; FormatNumber: Integer) ResultText: Text
    var
        DataTypeManagement: Codeunit "Data Type Management";
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        RecordRefToRead: RecordRef;
        FieldRefToRead: FieldRef;
        FieldNo: Integer;
    begin
        ResultText := BadTableTok;
        if not DataTypeManagement.GetRecordRef(CurrentRecordVariant, RecordRefToRead) then
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
        if UserSecurityID = EmptyGuid then
            exit('');

        if not User.ReadPermission() then
            exit('');


        if not User.Get(UserSecurityID) then
            exit('');

        exit(User."User Name");
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

    /// <summary>
    /// Provides an opportunity for customizations to alter the default maximum rows shown
    /// for a table lookup in a quality inspector field.
    /// Changing the default to a larger number can introduce performance issues.
    /// </summary>
    /// <param name="Rows"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultMaximumRowsToShowInLookup(var Rows: Integer; var Handled: Boolean)
    begin
    end;
}
