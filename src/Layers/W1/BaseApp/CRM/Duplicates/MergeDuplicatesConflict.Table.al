// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

using System.Reflection;

table 66 "Merge Duplicates Conflict"
{
    Caption = 'Merge Duplicates Conflict';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Table ID");
                "Table Name" := AllObjWithCaption."Object Caption";
            end;
        }
        field(2; Duplicate; RecordID)
        {
            Caption = 'Duplicate';
        }
        field(3; Current; RecordID)
        {
            Caption = 'Current';
        }
        field(4; "Field ID"; Integer)
        {
            Caption = 'Field ID';
        }
        field(5; "Table Name"; Text[249])
        {
            Caption = 'Table Name';
        }
    }

    keys
    {
        key(Key1; "Table ID", Duplicate)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Merge(): Boolean
    var
        MergeDuplicate: Page "Merge Duplicate";
    begin
        MergeDuplicate.SetConflict(Rec);
        MergeDuplicate.RunModal();
        exit(MergeDuplicate.IsConflictResolved());
    end;
}

