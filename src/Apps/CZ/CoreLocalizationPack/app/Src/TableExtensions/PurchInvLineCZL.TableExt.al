// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Intrastat;

tableextension 11760 "Purch. Inv. Line CZL" extends "Purch. Inv. Line"
{
    fields
    {
        field(31065; "Tariff No. CZL"; Code[20])
        {
            Caption = 'Tariff No.';
            TableRelation = "Tariff Number";
            DataClassification = CustomerContent;
        }
    }
}
