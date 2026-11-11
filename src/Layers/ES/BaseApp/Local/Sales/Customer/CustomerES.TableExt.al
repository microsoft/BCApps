// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

#pragma warning disable AS0088
tableextension 7000134 "Customer ES" extends Customer
{
    fields
    {
        field(10700; "Payment Days Code"; Code[20])
        {
            Caption = 'Payment Days Code';
            DataClassification = CustomerContent;
            TableRelation = Customer;
            ValidateTableRelation = false;
        }
        field(10701; "Non-Paymt. Periods Code"; Code[20])
        {
            Caption = 'Non-Paymt. Periods Code';
            DataClassification = CustomerContent;
            TableRelation = Customer;
            ValidateTableRelation = false;
        }
    }
}
