// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

pageextension 8556 "IC Gen. Journal Line Entity" extends "Gen. Journal Line Entity"
{
    layout
    {
        addafter(balVatDifference)
        {
            field(icPartnerCode; Rec."IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'IC Partner Code', Locked = true;
                ToolTip = 'Specifies the code of the intercompany partner.';
            }
            field(icDirection; Rec."IC Direction")
            {
                ApplicationArea = All;
                Caption = 'IC Direction', Locked = true;
                ToolTip = 'Specifies the direction of the intercompany transaction.';
            }
            field(icPartnerTransactionNumber; Rec."IC Partner Transaction No.")
            {
                ApplicationArea = All;
                Caption = 'IC Partner Transaction No.', Locked = true;
                ToolTip = 'Specifies the transaction number assigned by the intercompany partner.';
            }
            field(icAccountType; Rec."IC Account Type")
            {
                ApplicationArea = All;
                Caption = 'IC Account Type', Locked = true;
                ToolTip = 'Specifies the type of the account that you want to use for the transaction with your IC partner.';
            }
            field(icAccountNo; Rec."IC Account No.")
            {
                ApplicationArea = All;
                Caption = 'IC Account No.', Locked = true;
                ToolTip = 'Specifies the number of the general ledger or bank account that the IC transaction is posted to.';
            }
        }
    }
}
