// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

tableextension 11792 "Value Entry CZL" extends "Value Entry"
{
    fields
    {
        field(11764; "G/L Correction CZL"; Boolean)
        {
            Caption = 'G/L Correction';
            DataClassification = CustomerContent;
        }
    }
}
