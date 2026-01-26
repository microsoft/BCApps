// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

table 11002 "Data Export"
{
    Caption = 'Data Export';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Data Exports";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
    begin
        DataExportRecordDefinition.Reset();
        DataExportRecordDefinition.SetRange("Data Export Code", Code);
        DataExportRecordDefinition.DeleteAll(true);
    end;
}

