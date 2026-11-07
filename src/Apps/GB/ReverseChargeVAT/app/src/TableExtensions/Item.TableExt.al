// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Inventory.Item;

tableextension 10553 "Item" extends "Item"
{
    fields
    {
#pragma warning disable AS0099 // Preserve the existing field ID for compatibility.
        field(10507; "Reverse Charge Applies GB"; Boolean)
        {
            Caption = 'Reverse Charge Applies';
            DataClassification = CustomerContent;
        }
#pragma warning restore AS0099
    }
}