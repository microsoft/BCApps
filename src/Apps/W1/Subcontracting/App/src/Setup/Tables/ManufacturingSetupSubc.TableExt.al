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

tableextension 99001501 "Manufacturing Setup Subc." extends "Manufacturing Setup"
{
    fields
    {
        field(99001500; "Create Prod. Order Info Line"; Boolean)
        {
            Caption = 'Create Prod. Order Info Line';
            DataClassification = CustomerContent;
        }
        field(99001501; "Subcontracting Template Name"; Code[10])
        {
            Caption = 'Subcontracting Journal Template Name';
            DataClassification = CustomerContent;
            TableRelation = "Req. Wksh. Template" where(Type = const("For. Labor"));
        }
        field(99001502; "Subcontracting Batch Name"; Code[10])
        {
            Caption = 'Subcontracting Journal Batch Name';
            DataClassification = CustomerContent;
            TableRelation = "Requisition Wksh. Name".Name where("Template Type" = const("For. Labor"),
                                                                "Worksheet Template Name" = field("Subcontracting Template Name"));
        }
        field(99001503; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer for Subcontracting';
            DataClassification = CustomerContent;
        }
        field(99001504; "Component Direct Unit Cost"; Option)
        {
            Caption = 'Component Direct Unit Cost';
            DataClassification = CustomerContent;
            OptionCaption = 'Standard,Prod. Order Component';
            OptionMembers = Standard,"Prod. Order Component";
        }
        field(99001505; "Subc. Inb. Whse. Handling Time"; DateFormula)
        {
            Caption = 'Subcontracting Inbound Whse. Handling Time';
            DataClassification = CustomerContent;
        }
        field(99001506; "Rtng. Link Code Purch. Prov."; Code[10])
        {
            Caption = 'Routing Link Code Purchase Provision';
            DataClassification = CustomerContent;
            TableRelation = "Routing Link";
        }
        field(99001509; "Subc. Comp. at Location"; Enum "Components at Location")
        {
            Caption = 'Component at Location';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                CompanyInformation: Record "Company Information";
                ManufacturingSetup: Record "Manufacturing Setup";
            begin
                case "Subc. Comp. at Location" of
                    "Subc. Comp. at Location"::Company:
                        begin
                            CompanyInformation.Get();
                            CompanyInformation.TestField("Location Code");
                        end;
                    "Subc. Comp. at Location"::Manufacturing:
                        begin
                            ManufacturingSetup.Get();
                            ManufacturingSetup.TestField("Components at Location");
                        end;
                end;
            end;
        }
        field(99001510; RefItemChargeToRcptSubLines; Boolean)
        {
            Caption = 'Item Charge to Subcontracting Purch. Receipt Lines';
            DataClassification = CustomerContent;
        }
    }
}