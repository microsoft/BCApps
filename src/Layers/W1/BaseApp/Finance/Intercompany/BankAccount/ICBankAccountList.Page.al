// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.BankAccount;

using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;

page 697 "IC Bank Account List"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Bank Accounts';
    CardPageID = "IC Bank Account Card";
    SourceTable = "IC Bank Account";
    PageType = List;
    UsageCategory = Administration;
    RefreshOnActivate = true;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the name of the bank where the IC partner has the bank account.';
                }
                field(BankAccountNo; Rec."Bank Account No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number used by the IC partner''s bank for the bank account.';
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies that the IC bank account is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action(CopyFromPartner)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Copy from IC Partner';
                    Image = BankAccount;
                    ShortcutKey = 'C';
                    ToolTip = 'Create IC bank accounts from partner''s bank accounts.';
                    Enabled = EnableCopy;

                    trigger OnAction()
                    var
                        ICPartner: Record "IC Partner";
                        ICBankAccounts: Record "IC Bank Account";
                        ICMapping: Codeunit "IC Mapping";
                    begin
                        if (ICPartner.Get(Rec."IC Partner Code")) and (ICPartner."Inbox Type" <> "IC Partner Inbox Type"::Database) then begin
                            Message(OnlyAvailableForICUsingDatabaseLbl);
                            exit;
                        end;

                        ICBankAccounts.SetRange("IC Partner Code", Rec."IC Partner Code");
                        if not ICBankAccounts.IsEmpty() then
                            if Confirm(StrSubstNo(CopyICBankAccountsQst, Rec."IC Partner Code"), true) then
                                ICBankAccounts.DeleteAll()
                            else
                                exit;

                        ICMapping.CopyBankAccountsFromPartner(Rec."IC Partner Code");
                        CurrPage.Update();
                        exit;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Promoted_Functions)
            {
                Caption = 'Functions';
                actionref(CopyFromPartner_Promoted; CopyFromPartner)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ICPartner: Record "IC Partner";
    begin
        EnableCopy := false;
        if Rec."IC Partner Code" <> '' then
            if (ICPartner.Get(Rec."IC Partner Code")) and (ICPartner."Inbox Type" = "IC Partner Inbox Type"::Database) then
                EnableCopy := true;
    end;

    var
        EnableCopy: Boolean;
        CopyICBankAccountsQst: Label 'Do you want to create IC Bank Accounts for partner %1 using its current Bank Accounts? This will delete the existing IC Bank Accounts for this partner.', Comment = '%1 = IC Partner code';
        OnlyAvailableForICUsingDatabaseLbl: Label 'Copy is only available for partners using Database as their Inbox Type. Select this option in the partner''s setup if you want to use this action.';

}
