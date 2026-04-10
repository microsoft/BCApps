// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using System.Reflection;

table 7328 "Whse. Worksheet Template"
{
    Caption = 'Whse. Worksheet Template';
    LookupPageID = "Whse. Worksheet Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name you enter for the warehouse worksheet template you are creating.';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the warehouse worksheet template you are creating.';
        }
        field(3; Type; Enum "Warehouse Worksheet Template Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies information about the activity you can plan in the warehouse worksheets that will be defined by this template.';

            trigger OnValidate()
            begin
                case Type of
                    Type::"Put-away":
                        "Page ID" := PAGE::"Put-away Worksheet";
                    Type::Pick:
                        "Page ID" := PAGE::"Pick Worksheet";
                    Type::Movement:
                        "Page ID" := PAGE::"Movement Worksheet";
                end;
            end;
        }
        field(4; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
            end;
        }
        field(5; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
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
    }

    trigger OnDelete()
    begin
        WhseWkshLine.SetRange("Worksheet Template Name", Name);
        WhseWkshLine.DeleteAll(true);

        WhseWkshName.SetRange("Worksheet Template Name", Name);
        WhseWkshName.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        WhseWkshName: Record "Whse. Worksheet Name";
        WhseWkshLine: Record "Whse. Worksheet Line";
}

