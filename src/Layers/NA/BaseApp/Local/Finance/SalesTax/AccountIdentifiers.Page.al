// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;

page 10100 "Account Identifiers"
{
    Caption = 'Account Identifiers';
    PageType = Card;
    SourceTable = "Account Identifier";

    layout
    {
        area(content)
        {
            repeater(Control1030000)
            {
                ShowCaption = false;
                field("Business No."; Rec."Business No.")
                {
                    ToolTip = 'Specifies the business number for the account identifier.';
                    Visible = false;
                }
                field("Program Identifier"; Rec."Program Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the program identifier.';
                }
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number for the account identifier.';
                }
                field("Business Number"; Rec."Business Number")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the business number for the account identifier.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Company.Get();
        Rec."Business No." := Company."Federal ID No.";
    end;

    var
        Company: Record "Company Information";
}

