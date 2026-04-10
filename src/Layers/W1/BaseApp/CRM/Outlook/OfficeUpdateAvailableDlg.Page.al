// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Utilities;
using System.Security.AccessControl;

page 1607 "Office Update Available Dlg"
{
    Caption = 'Office Add-in Update Available';
    DataCaptionExpression = 'Office Add-in Update Available';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Office Add-in";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            label(Empty)
            {
                ApplicationArea = Basic, Suite;
                Caption = '';
                Editable = false;
                Enabled = false;
                HideValue = true;
                ShowCaption = false;
                ToolTip = 'Specifies options for updating the add-in.';
            }
            label(AdminNonBreaking)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'An update is available for this Outlook add-in. To update the add-in, please contact your system administrator.';
                HideValue = true;
                ToolTip = 'Specifies an option for updating the add-in.';
                Visible = not UserCanUpdate and UserCanContinue;
            }
            label(AdminBreaking)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'An update is available for this Outlook add-in. To continue using the add-in, please contact your system administrator.';
                ToolTip = 'Specifies an option for updating the add-in.';
                Visible = not UserCanUpdate and not UserCanContinue;
            }
            label(UserNonBreaking)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'An update is available for this Outlook add-in. Do you want to apply the update now?';
                ToolTip = 'Specifies an option for updating the add-in.';
                Visible = UserCanContinue and UserCanUpdate;
            }
            label(UserBreaking)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'An update is available for this Outlook add-in. To continue using the add-in, you must apply the update.';
                ToolTip = 'Specifies an option for updating the add-in.';
                Visible = not UserCanContinue and UserCanUpdate;
            }
            field(UpgradeNow; UpgradeNowLbl)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Specifies that the add-in must be updated now.';
                Visible = UserCanUpdate;

                trigger OnDrillDown()
                begin
                    Hyperlink('https://learn.microsoft.com/en-us/dynamics365/business-central/admin-outlook');
                    CurrPage.Close();
                end;
            }
            field(UpgradeLater; GetLaterLabel())
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Specifies that you want to continue using the add-in and update it later.';
                Visible = UserCanContinue;

                trigger OnDrillDown()
                begin
                    CurrPage.Close();
                end;
            }
            field(DontShowAgain; DontShowAgain)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Do not show this message again';
                ToolTip = 'Specifies if you want to not see this message again.';
                Visible = UserCanContinue;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        User: Record User;
        Email: Text[250];
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst() then
            Email := User."Authentication Email";
        UserCanUpdate := true;
        UserCanContinue := not Rec.Breaking;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if DontShowAgain then begin
            if UserCanUpdate then
                Message(DontDisplayAgainMsg);
            InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.OfficeUpdateNotificationCode());
        end;

        if Rec.Breaking then
            exit(false);
    end;

    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        DontDisplayAgainMsg: Label 'To update the add-in later, you must use the Outlook Add-In assisted setup guide.';
        ContinueLbl: Label 'Continue';
        UpgradeNowLbl: Label 'See instructions to Upgrade';
        UpgradeLaterLbl: Label 'Upgrade Later';
        DontShowAgain: Boolean;
        UserCanContinue: Boolean;
        UserCanUpdate: Boolean;

    local procedure GetLaterLabel(): Text
    begin
        case true of
            UserCanContinue and not UserCanUpdate:
                exit(ContinueLbl);
            else
                exit(UpgradeLaterLbl);
        end;
    end;
}
