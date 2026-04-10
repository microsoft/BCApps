// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Maintenance;

table 6081 "Serv. Price Group Setup"
{
    Caption = 'Serv. Price Group Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            ToolTip = 'Specifies the code of the Service Price Adjustment Group that was assigned to the service item linked to this service line.';
            NotBlank = true;
            TableRelation = "Service Price Group";
        }
        field(2; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            ToolTip = 'Specifies a code for the fault area assigned to the given service price group.';
            TableRelation = "Fault Area";
        }
        field(3; "Cust. Price Group Code"; Code[10])
        {
            Caption = 'Cust. Price Group Code';
            ToolTip = 'Specifies the code of the customer price group associated with the given service price group.';
            TableRelation = "Customer Price Group";
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code assigned to the service price group.';
            TableRelation = Currency;
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date when the service hours become applicable to the service price group.';
        }
        field(6; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            ToolTip = 'Specifies the code of the service price adjustment group that applies to the posted service line.';
            TableRelation = "Service Price Adjustment Group";
        }
        field(7; "Include Discounts"; Boolean)
        {
            Caption = 'Include Discounts';
            ToolTip = 'Specifies that any sales line or invoice discount set up for the customer will be deducted from the price of the item assigned to the service price group.';
        }
        field(8; "Adjustment Type"; Option)
        {
            Caption = 'Adjustment Type';
            ToolTip = 'Specifies the adjustment type for the service item line.';
            OptionCaption = 'Fixed,Maximum,Minimum';
            OptionMembers = "Fixed",Maximum,Minimum;
        }
        field(9; Amount; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount to which the price on the service price group is going to be adjusted.';
        }
        field(10; "Include VAT"; Boolean)
        {
            Caption = 'Include VAT';
            ToolTip = 'Specifies that the amount to be adjusted for the given service price group should include VAT.';
        }
    }

    keys
    {
        key(Key1; "Service Price Group Code", "Fault Area Code", "Cust. Price Group Code", "Currency Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

