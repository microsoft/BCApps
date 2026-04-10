// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Manufacturing.WorkCenter;

tableextension 99000768 "Mfg. Std. Item Journal Line" extends "Standard Item Journal Line"
{
    fields
    {
        field(5839; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center";
        }
    }
}
