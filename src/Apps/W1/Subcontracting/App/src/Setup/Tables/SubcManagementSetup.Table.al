// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

table 99001501 "Subc. Management Setup"
{
    AllowInCustomizations = AsReadOnly;
    Caption = 'Subcontracting Setup';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(100; "Common Work Center No."; Code[20])
        {
            Caption = 'Common Work Center No.';
            TableRelation = "Work Center";
        }
        field(110; "Def. provision flushing method"; Enum "Flushing Method Routing")
        {
            Caption = 'Default flushing method purchase provision';
        }
        field(200; ShowRtngBOMSelect_Both; Enum "Subc. Show/Edit Type")
        {
            Caption = 'Routing/BOM Selection - Both';
        }
        field(210; ShowProdRtngCompSelect_Both; Enum "Subc. Show/Edit Type")
        {
            Caption = 'Show Prod. Routing/Component Selection - Both';
        }
        field(220; ShowRtngBOMSelect_Partial; Enum "Subc. Show/Edit Type")
        {
            Caption = 'Routing/BOM Selection - Partial';
        }
        field(230; ShowProdRtngCompSelect_Partial; Enum "Subc. Show/Edit Type")
        {
            Caption = 'Show Prod. Routing/Component Selection - Partial';
        }
        field(240; ShowRtngBOMSelect_Nothing; Enum "Subc. Show/Edit Type")
        {
            Caption = 'Routing/BOM Selection - Nothing';
        }
        field(250; ShowProdRtngCompSelect_Nothing; Enum "Subc. Show/Edit Type")
        {
            Caption = 'Show Prod. Routing/Component Selection - Nothing';
        }
        field(260; "Always Save Modified Versions"; Boolean)
        {
            Caption = 'Always Save Modified Versions';
        }
        field(270; "Put-Away Work Center No."; Code[20])
        {
            Caption = 'Put-Away Work Center No.';
            TableRelation = "Work Center";
        }
        field(280; AllowEditUISelection; Boolean)
        {
            Caption = 'Allow Edit UI Selection';
        }
        field(290; "Preset Component Item No."; Code[20])
        {
            Caption = 'Preset Component Item No.';
            TableRelation = Item;
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "Primary Key")
        {
        }
        fieldgroup(Brick; "Primary Key")
        {
        }
    }
    procedure ItemChargeToRcptSubReferenceEnabled(): Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.SetLoadFields(RefItemChargeToRcptSubLines);
        if not ManufacturingSetup.Get() then
            exit(false);

        exit(ManufacturingSetup.RefItemChargeToRcptSubLines);
    end;
}