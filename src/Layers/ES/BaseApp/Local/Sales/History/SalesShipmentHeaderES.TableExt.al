// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Customer;

tableextension 7000066 "Sales Shipment Header ES" extends "Sales Shipment Header"
{
    fields
    {
        field(7000001; "Cust. Bank Acc. Code"; Code[20])
        {
            Caption = 'Cust. Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Address is taken from the fields Bill-to Address, Bill-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }
}
