// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing.ActionMessage;

using Microsoft.Inventory.Setup;

tableextension 5840 "Cost Adjmt. Inventory Setup" extends "Inventory Setup"
{
    fields
    {
        field(5840; "Disable Cost Adjmt. Signals"; Boolean)
        {
            Caption = 'Disable cost adjustment signals logging';
            ToolTip = 'Specifies whether cost adjustment signals logging should be disabled.';
            DataClassification = CustomerContent;
        }
    }
}