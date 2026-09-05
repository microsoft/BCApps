// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

tableextension 11307 PurchaseLineNL extends "Purchase Line"
{
    fields
    {
        field(11303; "Suggested Line"; Boolean)
        {
            Caption = 'Suggested Line';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
}
