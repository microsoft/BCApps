// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

table 11007 "Data Export Record Type"
{
    Caption = 'Data Export Record Type';
    LookupPageID = "Data Export Record Types";
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
        DataExportRecordDefinition.SetRange("Data Exp. Rec. Type Code", Code);
        if DataExportRecordDefinition.FindFirst() then
            Error(MustNotDeleteErr, Code);
    end;

    var
        MustNotDeleteErr: Label 'You must not delete the Data Export Record Type %1 if there exists a Data Export Record Definition for it.';
}

