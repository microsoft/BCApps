// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

pageextension 8528 "ICSalesReturnOrderSubform" extends "Sales Return Order Subform"
{
    layout
    {
        addafter("Item Reference No.")
        {
            field("IC Partner Ref. Type"; Rec."IC Partner Ref. Type")
            {
                ApplicationArea = Intercompany;
                Visible = false;
            }
            field("IC Partner Reference"; Rec."IC Partner Reference")
            {
                ApplicationArea = Intercompany;
                Visible = false;
            }
        }
    }
}
