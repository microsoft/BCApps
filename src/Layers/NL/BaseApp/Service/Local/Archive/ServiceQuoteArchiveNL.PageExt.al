// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

pageextension 11460 "Service Quote Archive NL" extends "Service Quote Archive"
{
    layout
    {
        addafter("VAT Bus. Posting Group")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Service;
            }
            field("Bank Account Code"; Rec."Bank Account Code")
            {
                ApplicationArea = Service;
            }
        }
    }
}