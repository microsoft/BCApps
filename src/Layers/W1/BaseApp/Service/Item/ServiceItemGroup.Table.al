// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Service.Pricing;
using Microsoft.Service.Resources;

table 5904 "Service Item Group"
{
    Caption = 'Service Item Group';
    LookupPageID = "Service Item Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the service item group.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the service item group.';
        }
        field(3; "Create Service Item"; Boolean)
        {
            Caption = 'Create Service Item';
            ToolTip = 'Specifies that when you ship an item associated with this group, the item is registered as a service item in the Service Item table.';
        }
        field(4; "Default Contract Discount %"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Default Contract Discount %';
            ToolTip = 'Specifies the discount percentage used as the default quote discount in a service contract quote.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; "Default Serv. Price Group Code"; Code[10])
        {
            Caption = 'Default Serv. Price Group Code';
            ToolTip = 'Specifies the service price group code used as the default service price group in the Service Price Group table.';
            TableRelation = "Service Price Group";
        }
        field(6; "Default Response Time (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StdServItemGrCode: Record "Standard Service Item Gr. Code";
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
        DimMgt: Codeunit DimensionManagement;
    begin
        StdServItemGrCode.Reset();
        StdServItemGrCode.SetRange("Service Item Group Code", Code);
        StdServItemGrCode.DeleteAll();

        ResSkillMgt.DeleteServItemGrResSkills(Code);
        DimMgt.DeleteDefaultDim(DATABASE::"Service Item Group", Code);
    end;

    trigger OnRename()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Service Item Group", xRec.Code, Code);
    end;
}

