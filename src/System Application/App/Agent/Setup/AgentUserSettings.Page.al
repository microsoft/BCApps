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
                        Visible = not TemporaryRecord;
                        ApplicationArea = All;
                        AssistEdit = true;
                        Caption = 'Profile (Role)';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the role that defines the agent''s home page with links to the most common tasks.';

                        trigger OnAssistEdit()
                        begin
                            if not Confirm(ProfileChangedQst, false) then
                                exit;

                            UserSettings.LookupProfile(Rec);
                            CurrPage.Update()
                        end;
                    }
                    field(Region; Language.GetWindowsLanguageName(GlobalLocaleID))
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Caption = 'Region';
                        ToolTip = 'Specifies the regional settings, such as date and numeric format, on all devices.';

                        trigger OnAssistEdit()
                        begin
                            Language.LookupWindowsLanguageId(GlobalLocaleID);
                        end;
                    }
                    field(LanguageName; Language.GetWindowsLanguageName(GlobalLanguageID))
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Caption = 'Language';
                        Importance = Promoted;
                        ToolTip = 'Specifies the display language, on all devices.';

                        trigger OnAssistEdit()
                        begin
                            Language.LookupApplicationLanguageId(GlobalLanguageID);
                        end;
                    }
                    field("Time Zone"; TimeZoneSelection.GetTimeZoneDisplayName(GlobalTimeZoneText))
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Caption = 'Time Zone';
                        ToolTip = 'Specifies the time zone that the agent works in.';

                        trigger OnAssistEdit()
                        begin
                            TimeZoneSelection.LookupTimeZone(GlobalTimeZoneText);
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

        SetGlobalsFromRec(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ProfileDisplayName := UserSettings.GetProfileName(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (CloseAction in [Action::LookupOK, Action::OK]) then
            exit(true);

        CopyGlobalsToRec();

        if TemporaryRecord then
            exit(true);

        UserSettings.UpdateUserSettings(Rec);
        exit(true);
    end;

    procedure InitializeTemp(var UserSettingsRec: Record "User Settings")
    begin
        TemporaryRecord := true;
        SetGlobalsFromRec(UserSettingsRec);
    end;

    procedure GetValues(var UserSettingsRec: Record "User Settings")
    begin
        UserSettingsRec.Copy(Rec);
    end;

    local procedure CopyGlobalsToRec()
    begin
        Rec."Language ID" := GlobalLanguageID;
        Rec."Locale ID" := GlobalLocaleID;
        Rec."Time Zone" := GlobalTimeZoneText;
    end;

    local procedure SetGlobalsFromRec(var UserSettingsRec: Record "User Settings")
    begin
        Rec.Copy(UserSettingsRec);
        GlobalLanguageID := Rec."Language ID";
        GlobalLocaleID := Rec."Locale ID";
        GlobalTimeZoneText := Rec."Time Zone";
    end;

    var
        Language: Codeunit Language;
        TimeZoneSelection: Codeunit "Time Zone Selection";
        UserSettings: Codeunit "User Settings";
        ProfileDisplayName: Text;
        GlobalTimeZoneText: Text[180];
        GlobalLocaleID: Integer;
        GlobalLanguageID: Integer;
        TemporaryRecord: Boolean;
        ProfileChangedQst: Label 'Changing the agent''s profile may affect its accuracy and performance. It could also grant access to unexpected fields and actions. Do you want to continue?';
}
