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
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Create Service Item"; Boolean)
        {
            Caption = 'Create Service Item';
        }
        field(4; "Default Contract Discount %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Default Contract Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; "Default Serv. Price Group Code"; Code[10])
        {
            Caption = 'Default Serv. Price Group Code';
            TableRelation = "Service Price Group";
        }
        field(6; "Default Response Time (Hours)"; Decimal)
        {
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

