// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Selection interface for linking local bank accounts to online banking services.
/// Displays available online bank accounts for automated statement import setup.
/// </summary>
/// <remarks>
/// Source Table: Online Bank Acc. Link (777). Used in bank account linking wizard.
/// Facilitates connection between local bank accounts and external banking services.
/// </remarks>
page 270 "Online Bank Accounts"
{
    Caption = 'Select which bank account to set up';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Online Bank Acc. Link";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                InstructionalText = 'Select which bank account to set up.';
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the online bank account.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account name.';
                }
            }
        }
    }

    actions
    {
    }

    procedure SetRecs(var OnlineBankAccLink: Record "Online Bank Acc. Link")
    begin
        OnlineBankAccLink.Reset();
        OnlineBankAccLink.FindSet();
        repeat
            Rec := OnlineBankAccLink;
            Rec.Insert();
        until OnlineBankAccLink.Next() = 0
    end;
}

