// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Setup;

tableextension 8125 "Subc. Manufacturing Setup" extends "Manufacturing Setup"
{
    fields
    {
        field(8124; "Create Prod. Order Info Line"; Boolean)
        {
            Caption = 'Create Prod. Order Info Line';
            DataClassification = CustomerContent;
        }
        field(8125; "Subcontracting Template Name"; Code[10])
        {
            Caption = 'Subcontracting Worksheet Template Name';
            DataClassification = CustomerContent;
#pragma warning disable AL0432
#pragma warning disable AL0520
            TableRelation = "Req. Wksh. Template" where(Type = const(Subcontracting));
#pragma warning restore AL0432
#pragma warning restore AL0520
        }
        field(8126; "Subcontracting Batch Name"; Code[10])
        {
            Caption = 'Subcontracting Worksheet Batch Name';
            DataClassification = CustomerContent;
#pragma warning disable AL0432
#pragma warning disable AL0520
            TableRelation = "Requisition Wksh. Name".Name where("Template Type" = const(Subcontracting),
                                                                "Worksheet Template Name" = field("Subcontracting Template Name"));
#pragma warning restore AL0432
#pragma warning restore AL0520
        }
        field(8128; "Component Direct Unit Cost"; Option)
        {
            Caption = 'Component Direct Unit Cost';
            DataClassification = CustomerContent;
            OptionCaption = 'Standard,Prod. Order Component';
            OptionMembers = Standard,"Prod. Order Component";
        }
        field(8129; "Subc. Comp. Transfer Lead Time"; DateFormula)
        {
            Caption = 'Subcontracting Component Transfer Lead Time';
            DataClassification = CustomerContent;
        }
        field(8133; "Subc. Default Comp. Location"; Enum "Components at Location")
        {
            Caption = 'Default Component Location Source';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                CompanyInformation: Record "Company Information";
                ManufacturingSetup: Record "Manufacturing Setup";
#if not CLEAN29
#pragma warning disable AL0432
                SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
            begin
#if not CLEAN29
#pragma warning disable AL0432
                if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
                    exit;
#endif
                case "Subc. Default Comp. Location" of
                    "Subc. Default Comp. Location"::Company:
                        begin
                            CompanyInformation.Get();
                            CompanyInformation.TestField("Location Code");
                        end;
                    "Subc. Default Comp. Location"::Manufacturing:
                        begin
                            ManufacturingSetup.Get();
                            ManufacturingSetup.TestField("Components at Location");
                        end;
                end;
            end;
        }
    }
}