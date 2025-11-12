// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Journal;

using Microsoft.CostAccounting.Reports;
using Microsoft.Foundation.AuditCodes;
using System.Reflection;

table 1100 "Cost Journal Template"
{
    Caption = 'Cost Journal Template';
    DataClassification = CustomerContent;
    LookupPageID = "Cost Journal Templates";
    ReplicateData = true;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(6; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(7; "Posting Report ID"; Integer)
        {
            Caption = 'Posting Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(8; "Posting Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Posting Report ID")));
            Caption = 'Posting Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name, Description)
        {
        }
    }

    trigger OnDelete()
    var
        CostJnlBatch: Record "Cost Journal Batch";
    begin
        CostJnlBatch.SetRange("Journal Template Name", Name);
        CostJnlBatch.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TestField(Name);
        "Posting Report ID" := REPORT::"Cost Register";
    end;
}

