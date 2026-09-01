// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;

page 8396 "Totaling Accounts Factbox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Totaling Accounts';
    PageType = ListPart;
    SourceTable = "G/L Account";
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.") { }
                field(Name; Rec.Name) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewAll)
            {
                Caption = 'View All';
                Image = Accounts;
                ToolTip = 'View G/L accounts that are included in the totaling on the current line.';

                trigger OnAction()
                var
                    GLAccount: Record "G/L Account";
                begin
                    GLAccount.SetFilter("No.", Rec.GetFilter("No."));
                    Page.Run(0, GLAccount);
                end;
            }
        }
    }

    procedure SetTotalingFilter(TotalingFilter: Text)
    begin
        Rec.SetFilter("No.", TotalingFilter);
        CurrPage.Update(false);
    end;
}