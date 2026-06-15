// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001553 "Subc. Pstd. Transfer Rcpts." extends "Posted Transfer Receipts"
{
    views
    {
        addlast
        {
            view(SubcontractingReceipts)
            {
                Caption = 'Subcontracting Receipts';
                Filters = where("Subc. Source Type" = const(Subcontracting));
            }
        }
    }
}
