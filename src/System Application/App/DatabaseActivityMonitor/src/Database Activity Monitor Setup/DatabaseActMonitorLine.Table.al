// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Reflection;

/// <summary>
/// This table stores the retention policy setup records.
/// </summary>
table 6282 "Database Act. Monitor Line"
{
    fields
    {
        field(1; "Table Id"; Integer)
        {
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            BlankZero = true;
            NotBlank = true;
            MinValue = 0;
        }
        field(2; "Table Name"; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table Id")));
            Editable = false;
        }
        field(3; "Table Caption"; Text[249])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Table Id")));
            Editable = false;
        }
        field(20; "Log Delete"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log Delete';
            InitValue = true;
        }
        field(21; "Log Insert"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log Insert';
            InitValue = true;
        }
        field(22; "Log Modify"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log Modify';
            InitValue = true;
        }
        field(23; "Log Rename"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log Ranme';
            InitValue = true;
        }
    }

    keys
    {
        key(PrimaryKey; "Table Id")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        // TODO: Telemetry log
    end;
}