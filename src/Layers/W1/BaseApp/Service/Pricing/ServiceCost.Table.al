// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.UOM;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Service.Setup;
using Microsoft.Utilities;

table 5905 "Service Cost"
{
    Caption = 'Service Cost';
    LookupPageID = "Service Costs";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the service cost.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the service cost.';
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            ToolTip = 'Specifies the general ledger account number to which the service cost will be posted.';
            TableRelation = "G/L Account";
        }
        field(4; "Default Unit Price"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Default Unit Price';
            ToolTip = 'Specifies the default unit price of the cost that is copied to the service lines containing this service cost.';
        }
        field(5; "Default Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default Quantity';
            ToolTip = 'Specifies the default quantity that is copied to the service lines containing this service cost.';
            DecimalPlaces = 0 : 5;
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Unit of Measure";
        }
        field(7; "Cost Type"; Option)
        {
            Caption = 'Cost Type';
            ToolTip = 'Specifies the cost type.';
            OptionCaption = 'Travel,Support,Other';
            OptionMembers = Travel,Support,Other;

            trigger OnValidate()
            begin
                Validate("Service Zone Code");
            end;
        }
        field(8; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            ToolTip = 'Specifies the code of the service zone, to which travel applies if the Cost Type is Travel.';
            TableRelation = "Service Zone";

            trigger OnValidate()
            begin
                if "Service Zone Code" <> '' then
                    TestField("Cost Type", "Cost Type"::Travel);
            end;
        }
        field(9; "Default Unit Cost"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Default Unit Cost';
            ToolTip = 'Specifies the default unit cost that is copied to the service lines containing this service cost.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Service Zone Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Cost Type", "Default Unit Price")
        {
        }
    }

    trigger OnDelete()
    begin
        ServMoveEntries.MoveServiceCostLedgerEntries(Rec);
    end;

    var
        ServMoveEntries: Codeunit "Serv. Move Entries";

    local procedure AsPriceAsset(var PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type")
    begin
        PriceAsset.Init();
        PriceAsset."Price Type" := PriceType;
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::"Service Cost";
        PriceAsset."Asset No." := "Code";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        AsPriceAsset(PriceAsset, PriceType);
        PriceUXManagement.ShowPriceListLines(PriceAsset, PriceType, AmountType);
    end;
}

