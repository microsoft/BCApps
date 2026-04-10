// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Privacy;

using System.Privacy;
using System.Reflection;

codeunit 135157 "Library - Data Classification"
{
    Subtype = Normal;
    Permissions = tabledata "Fields Sync Status" = rid;

    /// <summary>
    /// Modifies the Last Sync Date Time field of the Field Sync Status table to LastFieldsSyncStatusDate.
    /// </summary>
    /// <param name="LastFieldsSyncStatusDate">The value that the Last Sync Date Time will take.</param>
    procedure ModifyLastFieldsSyncStatusDate(LastFieldsSyncStatusDate: DateTime)
    var
        FieldsSyncStatus: Record "Fields Sync Status";
    begin
        FieldsSyncStatus.DeleteAll();

        FieldsSyncStatus.Init();
        FieldsSyncStatus."Last Sync Date Time" := LastFieldsSyncStatusDate;
        FieldsSyncStatus.Insert();
    end;

    /// <summary>
    /// Get the number of enabled sensitive fields for all supported tables.
    /// </summary>
    procedure GetNumberOfEnabledSensitiveFieldsForAllSupportedTables() FieldCount: Integer
    var
        TableMetaData: Record "Table Metadata";
        Field: Record Field;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataClassificationMgtImpl: Codeunit "Data Classification Mgt. Impl.";
    begin
        FieldCount := 0;
        if TableMetaData.FindSet() then
            repeat
                if DataClassificationMgt.IsSupportedTable(TableMetaData.ID) then begin
                    Field.SetRange(TableNo, TableMetaData.ID);
                    DataClassificationMgtImpl.GetEnabledSensitiveFields(Field);
                    FieldCount := FieldCount + Field.Count();
                end;
            until TableMetaData.Next() = 0;
    end;
}