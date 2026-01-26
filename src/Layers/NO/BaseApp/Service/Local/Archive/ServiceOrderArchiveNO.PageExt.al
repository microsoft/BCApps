// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;
using Microsoft.Service.Archive;

pageextension 10602 "Service Order Archive NO" extends "Service Order Archive"
{
    layout
    {
        modify("External Document No.")
        {
            Visible = false;
        }
        addafter("Max. Labor Unit Price")
        {
            field(GLN; Rec.GLN)
            {
                ApplicationArea = Service;
            }
            field("Account Code"; Rec."Account Code")
            {
                ApplicationArea = Service;
            }
            field("E-Invoice"; Rec."E-Invoice")
            {
                ApplicationArea = Service;
            }
        }
        addlast(General)
        {
            field("External Document No. NO"; Rec."External Document No. NO")
            {
                ApplicationArea = Service;
            }
        }
        addafter(Shipping)
        {
            field("Delivery Date"; Rec."Delivery Date")
            {
                ApplicationArea = Service;
            }
        }
    }
}