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
            NotBlank = true;
            TableRelation = "Service Price Group";
        }
        field(2; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";
        }
        field(3; "Cust. Price Group Code"; Code[10])
        {
            Caption = 'Cust. Price Group Code';
            TableRelation = "Customer Price Group";
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(6; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            TableRelation = "Service Price Adjustment Group";
        }
        field(7; "Include Discounts"; Boolean)
        {
            Caption = 'Include Discounts';
        }
        field(8; "Adjustment Type"; Option)
        {
            Caption = 'Adjustment Type';
            OptionCaption = 'Fixed,Maximum,Minimum';
            OptionMembers = "Fixed",Maximum,Minimum;
        }
        field(9; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(10; "Include VAT"; Boolean)
        {
            Caption = 'Include VAT';
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

