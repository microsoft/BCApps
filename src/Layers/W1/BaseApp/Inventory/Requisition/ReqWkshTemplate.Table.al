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
            ToolTip = 'Specifies the name of the requisition worksheet template you are creating.';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the requisition worksheet template you are creating.';
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
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
            ToolTip = 'Specifies whether the requisition worksheet template will be a recurring requisition worksheet.';

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
            ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
            ToolTip = 'Specifies if batch names using this template are automatically incremented. Example: The posting following BATCH001 is automatically named BATCH002.';
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

