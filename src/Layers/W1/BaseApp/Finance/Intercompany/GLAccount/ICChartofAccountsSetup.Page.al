// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

page 629 "IC Chart of Accounts Setup"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Synchronization Setup';
    PageType = StandardDialog;
    SourceTable = "IC Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                ShowCaption = false;
                field(PartnerCode; Rec."Partner Code for Acc. Syn.")
                {
                    Caption = 'Partner Code';
                    ToolTip = 'Specifies the partner code with which you want to synchronize the intercompany chart of accounts.';
                    ApplicationArea = All;
                    Editable = true;
                    Enabled = true;
                }
            }
        }
    }

    trigger OnClosePage()
    var
        ICAccounts: Record "IC G/L Account";
        ICPartner: Record "IC Partner";
        TempICPartnerAccount: Record "IC G/L Account" temporary;
        ICMapping: Codeunit "IC Mapping";
        ICDataExchange: Interface "IC Data Exchange";
        MessageText: Text;
    begin
        if Rec."Partner Code for Acc. Syn." = '' then
            exit;

        if not ICPartner.Get(Rec."Partner Code for Acc. Syn.") then
            exit;

        ICDataExchange := ICPartner."Data Exchange Type";
        ICDataExchange.GetICPartnerICGLAccount(ICPartner, TempICPartnerAccount);

        if TempICPartnerAccount.IsEmpty() then
            exit;

        if System.GuiAllowed() then begin
            MessageText := StrSubstNo(SyncronizeChartOfAccountsQst, Rec."Partner Code for Acc. Syn.");
            if not ICAccounts.IsEmpty() then
                MessageText := StrSubstNo(SplitMessageTxt, MessageText, CleanExistingICAccountsMsg);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, ContinueQst);
            if not Confirm(MessageText, false) then
                exit;
        end;

        ICMapping.SynchronizeAccounts(true, Rec."Partner Code for Acc. Syn.");
    end;

    var
        SplitMessageTxt: Label '%1\%2', Comment = '%1 = First part of the message, %2 = Second part of the message.', Locked = true;
        SyncronizeChartOfAccountsQst: Label 'Partner %1 has an intercompany chart of accounts that can be synchronized now.', Comment = '%1 = IC Partner code';
        CleanExistingICAccountsMsg: Label 'Before synchronizing with a new partner it is necessary to delete existing intercompany accounts.';
        ContinueQst: Label 'Do you want to continue?';
}
