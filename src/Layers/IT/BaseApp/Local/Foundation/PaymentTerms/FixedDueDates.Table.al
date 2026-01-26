// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 12172 "Fixed Due Dates"
{
    Caption = 'Fixed Due Dates';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Company,Customer,Vendor';
            OptionMembers = Company,Customer,Vendor;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = if (Type = const(Customer)) Customer
            else
            if (Type = const(Vendor)) Vendor;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Payment Days"; Integer)
        {
            Caption = 'Payment Days';
            MaxValue = 31;
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

