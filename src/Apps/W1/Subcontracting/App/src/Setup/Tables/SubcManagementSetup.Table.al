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
        field(10; "Create Prod. Order Info Line"; Boolean)
        {
            Caption = 'Create Prod. Order Info Line';
        }
        field(40; "Subcontracting Template Name"; Code[10])
        {
            Caption = 'Subcontracting Journal Template Name';
            TableRelation = "Req. Wksh. Template" where(Type = const("For. Labor"));
        }
        field(50; "Subcontracting Batch Name"; Code[10])
        {
            Caption = 'Subcontracting Journal Batch Name';
            TableRelation = "Requisition Wksh. Name".Name where("Template Type" = const("For. Labor"),
                                                                "Worksheet Template Name" = field("Subcontracting Template Name"));
        }
        field(60; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer for Subcontracting';
        }
        field(70; "Component Direct Unit Cost"; Option)
        {
            Caption = 'Component Direct Unit Cost';
            OptionCaption = 'Standard,Prod. Order Component';
            OptionMembers = Standard,"Prod. Order Component";
        }
        field(80; "Subc. Inb. Whse. Handling Time"; DateFormula)
        {
            Caption = 'Subcontracting Inbound Whse. Handling Time';
        }
        field(90; "Rtng. Link Code Purch. Prov."; Code[10])
        {
            Caption = 'Routing Link Code Purchase Provision';
            TableRelation = "Routing Link";
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
        field(120; "Component at Location"; Enum "Components at Location")
        {
            Caption = 'Component at Location';
            trigger OnValidate()
            var
                CompanyInformation: Record "Company Information";
                ManufacturingSetup: Record "Manufacturing Setup";
            begin
                case "Component at Location" of
                    "Components at Location"::Company:
                        begin
                            CompanyInformation.Get();
                            CompanyInformation.TestField("Location Code");
                        end;
                    "Components at Location"::Manufacturing:
                        begin
                            ManufacturingSetup.Get();
                            ManufacturingSetup.TestField("Components at Location");
                        end;
                end;
            end;
        }
        field(130; RefItemChargeToRcptSubLines; Boolean)
        {
            Caption = 'Item Charge to Subcontracting Purch. Receipt Lines';
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
        SubcManagementSetup: Record "Subc. Management Setup";
    begin
        SubcManagementSetup.SetLoadFields(RefItemChargeToRcptSubLines);
        if not SubcManagementSetup.Get() then
            exit(false);

        exit(SubcManagementSetup.RefItemChargeToRcptSubLines);
    end;
}