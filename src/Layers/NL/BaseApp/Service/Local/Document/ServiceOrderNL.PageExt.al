// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 11454 "Service Order NL" extends "Service Order"
{
    layout
    {
        addafter("VAT Bus. Posting Group")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the transaction mode code for the service header.';
            }
            field("Bank Account Code"; Rec."Bank Account Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the bank account code for the service header.';
            }
        }
    }
}
