// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 10607 "Service Credit Memo NO" extends "Service Credit Memo"
{
    layout
    {
        addbefore("Shortcut Dimension 1 Code")
        {
            field(GLN; Rec.GLN)
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the global location number of the customer.';
            }
            field("Account Code"; Rec."Account Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the account code of the customer.';

                trigger OnValidate()
                begin
                    AccountCodeOnAfterValidate();
                end;
            }
            field("E-Invoice"; Rec."E-Invoice")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies whether the customer is part of the EHF system and requires an electronic service order.';
            }
        }
    }

    local procedure AccountCodeOnAfterValidate()
    begin
        CurrPage.ServLines.PAGE.UpdateForm(true);
    end;
}