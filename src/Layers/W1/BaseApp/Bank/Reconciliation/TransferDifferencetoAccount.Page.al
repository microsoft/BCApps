// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;

page 1297 "Transfer Difference to Account"
{
    Caption = 'Transfer Difference to Account';
    DataCaptionExpression = '';
    PageType = StandardDialog;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount (including VAT) that the journal line consists of.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the journal line will be posted to.';
                    ValuesAllowed = "G/L Account", Customer, Vendor, "Bank Account";
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the entry on the journal line will be posted to.';
                }
                field(DescriptionTxt; DescriptionTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies text that describes this direct payment posting. By default, the text in the Transaction Text field is inserted.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        DescriptionTxt := Rec.Description;
        CurrPage.Editable := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            Rec.Validate(Description, DescriptionTxt)
    end;

    var
        DescriptionTxt: Text[100];
}

