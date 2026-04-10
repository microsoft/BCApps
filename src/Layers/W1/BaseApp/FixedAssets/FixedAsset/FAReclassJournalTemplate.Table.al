// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using System.Reflection;

table 5622 "FA Reclass. Journal Template"
{
    Caption = 'FA Reclass. Journal Template';
    LookupPageID = "FA Reclass. Jnl. Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the journal template you are creating.';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the journal template that you are creating.';
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    "Page ID" := PAGE::"FA Reclass. Journal";
            end;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
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
    }

    trigger OnDelete()
    begin
        FAReclassJnlLine.SetRange("Journal Template Name", Name);
        FAReclassJnlLine.DeleteAll();
        FAReclassJnlBatch.SetRange("Journal Template Name", Name);
        FAReclassJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        FAReclassJnlBatch: Record "FA Reclass. Journal Batch";
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
}

