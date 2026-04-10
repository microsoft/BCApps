// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using System.Reflection;

table 7336 "Bin Creation Wksh. Template"
{
    Caption = 'Bin Creation Wksh. Template';
    LookupPageID = "Bin Creation Wksh. Templ. List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the bin creation worksheet template you are creating.';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the warehouse worksheet template you are creating.';
        }
        field(6; "Page ID"; Integer)
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
        field(9; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies which type of bin creation will be used with this warehouse worksheet template.';
            OptionCaption = 'Bin,Bin Content';
            OptionMembers = Bin,"Bin Content";

            trigger OnValidate()
            begin
                case Type of
                    Type::Bin:
                        "Page ID" := PAGE::"Bin Creation Worksheet";
                    Type::"Bin Content":
                        "Page ID" := PAGE::"Bin Content Creation Worksheet";
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
        BinCreateWkshLine.SetRange("Worksheet Template Name", Name);
        BinCreateWkshLine.DeleteAll(true);
        BinCreateWkshName.SetRange("Worksheet Template Name", Name);
        BinCreateWkshName.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        BinCreateWkshName: Record "Bin Creation Wksh. Name";
        BinCreateWkshLine: Record "Bin Creation Worksheet Line";
}

