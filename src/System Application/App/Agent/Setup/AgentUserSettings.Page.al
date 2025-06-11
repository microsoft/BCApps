// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Globalization;
using System.DateTime;
using System.Security.AccessControl;
using System.Environment.Configuration;

/// <summary>
/// Page that shows the settings of a given user.
/// </summary>
page 4317 "Agent User Settings"
{
    DataCaptionExpression = Rec."User ID";
    ApplicationArea = All;
    Caption = 'Agent User Settings';
    PageType = StandardDialog;
    SourceTable = "User Settings";
    InherentEntitlements = X;
    InherentPermissions = X;
    SourceTableTemporary = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    LinksAllowed = false;
    RefreshOnActivate = true;
    Extensible = true;
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2149387';
    Permissions = tabledata User = r;

    layout
    {
        area(Content)
        {
            group(Control1)
            {
                Caption = 'Agent Settings';
                group("Agent Settings")
                {
                    ShowCaption = false;
                    field(ProfileDisplayName; ProfileDisplayName)
                    {
                        ApplicationArea = All;
                        AssistEdit = true;
                        Caption = 'Role';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the role that defines your home page with links to the most common tasks.';

                        trigger OnAssistEdit()
                        begin
                            UserSettings.LookupProfile(Rec);
                            CurrPage.Update();
                        end;
                    }
                    field(Region; Language.GetWindowsLanguageName(Rec."Locale ID"))
                    {
                        ApplicationArea = All;
                        Caption = 'Region';
                        ToolTip = 'Specifies the regional settings, such as date and numeric format, on all devices. You must sign out and then sign in again for the change to take effect.';

                        trigger OnAssistEdit()
                        begin
                            Language.LookupWindowsLanguageId(Rec."Locale ID");
                        end;
                    }
                    field(LanguageName; Language.GetWindowsLanguageName(Rec."Language ID"))
                    {
                        ApplicationArea = All;
                        Caption = 'Language';
                        Importance = Promoted;
                        ToolTip = 'Specifies the display language, on all devices. You must sign out and then sign in again for the change to take effect.';

                        trigger OnAssistEdit()
                        begin
                            Language.LookupApplicationLanguageId(Rec."Language ID");
                        end;
                    }
                    field("Time Zone"; TimeZoneSelection.GetTimeZoneDisplayName(Rec."Time Zone"))
                    {
                        ApplicationArea = All;
                        Caption = 'Time Zone';
                        ToolTip = 'Specifies the time zone that you work in. You must sign out and then sign in again for the change to take effect.';

                        trigger OnAssistEdit()
                        begin
                            TimeZoneSelection.LookupTimeZone(Rec."Time Zone");
                        end;
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Initialized then
            UserSettings.GetUserSettings(Rec."User Security ID", Rec);
    end;

    trigger OnAfterGetCurrRecord()
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        ProfileDisplayName := AgentImpl.GetProfileName(Rec.Scope, Rec."App ID", Rec."Profile ID");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            UserSettings.UpdateUserSettings(Rec);
    end;

    var
        Language: Codeunit Language;
        TimeZoneSelection: Codeunit "Time Zone Selection";
        UserSettings: Codeunit "User Settings";
        ProfileDisplayName: Text;
}
