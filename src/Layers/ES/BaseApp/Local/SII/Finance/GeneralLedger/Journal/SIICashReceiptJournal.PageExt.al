// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;

#pragma warning disable AS0088
pageextension 7000054 "SII Cash Receipt Journal" extends "Cash Receipt Journal"
{
    layout
    {
        addbefore("Correction Type")
        {
            field("Sales Invoice Type"; Rec."Sales Invoice Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sales invoice type.';
                Visible = false;
            }
            field("Sales Cr. Memo Type"; Rec."Sales Cr. Memo Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sales credit memo type.';
                Visible = false;
            }
            field("Sales Special Scheme Code"; Rec."Sales Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sales special scheme code.';
                Visible = false;
            }
            field("Purch. Invoice Type"; Rec."Purch. Invoice Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the purchase invoice type.';
                Visible = false;
            }
            field("Purch. Cr. Memo Type"; Rec."Purch. Cr. Memo Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the purchase credit memo type.';
                Visible = false;
            }
            field("Purch. Special Scheme Code"; Rec."Purch. Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the purchase special scheme code.';
                Visible = false;
            }
        }
        addafter("Corrected Invoice No.")
        {
            field("ID Type"; Rec."ID Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the ID Type.';
            }
            field("Succeeded Company Name"; Rec."Succeeded Company Name")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the name of the company successor in connection with corporate restructuring.';
            }
            field("Succeeded VAT Registration No."; Rec."Succeeded VAT Registration No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the VAT registration number of the company successor in connection with corporate restructuring.';
            }
        }
    }
}
