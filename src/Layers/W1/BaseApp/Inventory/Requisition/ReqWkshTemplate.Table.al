// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using System.Reflection;

table 244 "Req. Wksh. Template"
{
    Caption = 'Req. Wksh. Template';
    LookupPageID = "Req. Worksheet Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Recurring);
            end;
        }
        field(12; Recurring; Boolean)
        {
            Caption = 'Recurring';

            trigger OnValidate()
            begin
                if Recurring then
                    "Page ID" := Page::"Recurring Req. Worksheet"
                else
                    case Type of
                        Type::"Req.":
                            "Page ID" := Page::"Req. Worksheet";
                        Type::Planning:
                            "Page ID" := Page::"Planning Worksheet";
                    end;
            end;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
        }
        field(99000750; Type; Enum "Req. Worksheet Template Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of the requisition worksheet template.';
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
        fieldgroup(DropDown; Name, Description, Recurring, Type)
        {
        }
    }

    trigger OnDelete()
    begin
        ReqLine.SetRange("Worksheet Template Name", Name);
        ReqLine.DeleteAll(true);
        ReqWkshName.SetRange("Worksheet Template Name", Name);
        ReqWkshName.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
}

