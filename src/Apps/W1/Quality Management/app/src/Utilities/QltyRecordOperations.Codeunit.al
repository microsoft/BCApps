// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using System.IO;
using System.Reflection;
using System.Security.AccessControl;

/// <summary>
/// This codeunit provides generic record manipulation utilities for reading and writing field values
/// across arbitrary tables using reflection and RecordRef operations.
/// </summary>
codeunit 20594 "Qlty. Record Operations"
{
    var
        UnableToSetTableValueTableNotFoundErr: Label 'Unable to set a value because the table [%1] was not found.', Comment = '%1=the table name';
        UnableToSetTableValueFieldNotFoundErr: Label 'Unable to set a value because the field [%1] in table [%2] was not found.', Comment = '%1=the field name, %2=the table name';
        BadTableTok: Label '?table?', Locked = true;
        BadFieldTok: Label '?t:%1?f:%2?', Locked = true, Comment = '%1=the table, %2=the requested field';

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

    /// <summary>
    /// Retrieves the username associated with a given user security ID.
    /// Safely handles missing permissions, invalid GUIDs, and non-existent users.
    /// 
    /// Returns empty string if:
    /// - UserSecurityID is empty GUID
    /// - User table read permission is not granted
    /// - User record does not exist for the given ID
    /// 
    /// Common usage: Converting system-tracked User Security IDs to human-readable usernames
    /// in audit logs, test headers, or user assignments.
    /// </summary>
    /// <param name="UserSecurityID">The unique identifier of the user</param>
    /// <returns>The username (Code[50]) or empty string if user cannot be found</returns>
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

    /// <summary>
    /// Converts a variant to a RecordRef, validating that it represents a valid table record.
    /// Provides safe extraction of RecordRef from variant types with validation.
    /// 
    /// Returns false if:
    /// - Variant cannot be converted to RecordRef
    /// - RecordRef table number is 0 (invalid)
    /// 
    /// Common usage: Generic procedures that accept variants and need to perform record operations.
    /// </summary>
    /// <param name="CurrentVariant">Variant that may contain a record reference</param>
    /// <param name="RecordRef">Output: The extracted RecordRef if successful</param>
    /// <returns>True if variant was successfully converted to a valid RecordRef; False otherwise</returns>
    internal procedure GetRecordRefFromVariant(CurrentVariant: Variant; var RecordRef: RecordRef): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        if not DataTypeManagement.GetRecordRef(CurrentVariant, RecordRef) then
            exit(false);

        exit(RecordRef.Number() <> 0);
    end;
}
