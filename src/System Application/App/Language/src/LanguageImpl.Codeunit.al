// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Globalization;

using System;
using System.Environment;
using System.Environment.Configuration;

codeunit 54 "Language Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Allowed Language" = rimd,
                  tabledata Language = rimd,
                  tabledata "Language Selection" = r,
                  tabledata "User Personalization" = rm,
                  tabledata "Windows Language" = r;

    var
        ResetLanguageIdOverrideAfterUse, ResetFormatRegionOverrideAfterUse : Boolean;
        LanguageIdOverride: Integer;
        FormatRegionOverride: Text[80];
        LanguageNotFoundErr: Label 'The language %1 could not be found.', Comment = '%1 = Language ID';
        LanguageIdOverrideMsg: Label 'LanguageIdOverride has been applied in GetLanguageIdOrDefault. The new Language Id is %1.', Comment = '%1 - Language ID';
        FormatRegionOverrideMsg: Label 'FormatRegionOverride has been applied in GetFormatRegionOrDefault. The new FormatRegion is %1.', Comment = '%1 - Format Region';
        LanguageCategoryTxt: Label 'Language';
        NotificationAllowedLanguagesLbl: Label '2c2bd28b-926c-47a7-bbc4-cf76f8173549', Locked = true;
        NotificationAllowedLanguagesMessageLbl: Label 'This list of languages has been filtered by your administrator.';
        ReadMoreLbl: Label 'Read more';

    procedure GetUserLanguageCode() UserLanguageCode: Code[10]
    var
        Language: Codeunit Language;
        Handled: Boolean;
    begin
        Language.OnGetUserLanguageCode(UserLanguageCode, Handled);

        if not Handled then
            UserLanguageCode := GetLanguageCode(GlobalLanguage());
    end;

    procedure GetUserLanguageTag() UserLanguageTag: Text[80]
    begin
        UserLanguageTag := GetLanguageTag(GlobalLanguage());
    end;

    procedure GetLanguageIdOrDefault(LanguageCode: Code[10]): Integer;
    var
        LanguageId: Integer;
    begin
        if LanguageIdOverride <> 0 then begin
            LanguageId := LanguageIdOverride;
            Session.LogMessage('0000MJQ', StrSubstNo(LanguageIdOverrideMsg, LanguageId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', LanguageCategoryTxt);
            if ResetLanguageIdOverrideAfterUse then
                LanguageIdOverride := 0;
            exit(LanguageId);
        end;

        LanguageId := GetLanguageId(LanguageCode);
        if LanguageId = 0 then
            LanguageId := GlobalLanguage();

        exit(LanguageId);
    end;

    procedure GetFormatRegionOrDefault(FormatRegion: Text[80]): Text[80]
    var
        LanguageSelection: Record "Language Selection";
        UserSessionSettings: SessionSettings;
        LocalId: Integer;
    begin
        if FormatRegionOverride <> '' then begin
            FormatRegion := FormatRegionOverride;
            Session.LogMessage('0000MJR', StrSubstNo(FormatRegionOverrideMsg, FormatRegion), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', LanguageCategoryTxt);
            if ResetFormatRegionOverrideAfterUse then
                FormatRegionOverride := '';
            exit(FormatRegion);
        end;

        if FormatRegion <> '' then
            exit(FormatRegion);

        // Lookup based on locale in user session
        UserSessionSettings.Init();
        LocalId := UserSessionSettings.LocaleId();
        LanguageSelection.SetRange("Language ID", LocalId);
        if LanguageSelection.FindFirst() then
            exit(LanguageSelection."Language Tag");

        exit('en-US');
    end;

    procedure SetOverrideLanguageId(LanguageId: Integer; ResetOverride: Boolean)
    begin
        LanguageIdOverride := LanguageId;
        ResetLanguageIdOverrideAfterUse := ResetOverride;
    end;

    procedure SetOverrideFormatRegion(FormatRegion: Text[80]; ResetOverride: Boolean)
    begin
        FormatRegionOverride := FormatRegion;
        ResetFormatRegionOverrideAfterUse := ResetOverride;
    end;

    procedure GetLanguageId(LanguageCode: Code[10]): Integer
    var
        Language: Record Language;
    begin
        if LanguageCode <> '' then
            if Language.Get(LanguageCode) then
                exit(Language."Windows Language ID");

        exit(0);
    end;

    procedure GetLanguageCode(LanguageId: Integer): Code[10]
    var
        Language: Record Language;
    begin
        if LanguageId = 0 then
            exit('');

        Language.SetRange("Windows Language ID", LanguageId);
        if Language.FindFirst() then;

        exit(Language.Code);
    end;

    procedure GetLanguageTag(LanguageId: Integer): Text[80]
    var
        WindowsLanguage: Record "Windows Language";
    begin
        if LanguageId = 0 then
            exit('');

        WindowsLanguage.SetRange("Language ID", LanguageId);
        if WindowsLanguage.FindFirst() then;

        exit(WindowsLanguage."Language Tag");
    end;

    procedure GetWindowsLanguageName(LanguageCode: Code[10]): Text
    var
        Language: Record Language;
    begin
        if LanguageCode = '' then
            exit('');

        Language.SetAutoCalcFields("Windows Language Name");
        if Language.Get(LanguageCode) then
            exit(Language."Windows Language Name");

        exit('');
    end;

    procedure GetWindowsLanguageName(LanguageId: Integer): Text
    var
        WindowsLanguage: Record "Windows Language";
    begin
        if LanguageId = 0 then
            exit('');

        if WindowsLanguage.Get(LanguageId) then
            exit(WindowsLanguage.Name);

        exit('');
    end;

    procedure GetApplicationLanguages(var TempWindowsLanguage: Record "Windows Language" temporary)
    var
        AllowedLanguage: Record "Allowed Language";
        WindowsLanguage: Record "Windows Language";
        LanguageFilter: Text;
    begin
        AllowedLanguage.ReadIsolation := IsolationLevel::ReadCommitted;
        AllowedLanguage.LoadFields("Language Id");
        if AllowedLanguage.FindSet() then
            repeat
                AddToFilter(Format(AllowedLanguage."Language Id"), LanguageFilter);
            until AllowedLanguage.Next() = 0;

        WindowsLanguage.ReadIsolation := IsolationLevel::ReadCommitted;
        if LanguageFilter <> '' then
            WindowsLanguage.SetFilter("Language ID", LanguageFilter);

        if WindowsLanguage.FindSet() then
            repeat
                TempWindowsLanguage := WindowsLanguage;
                TempWindowsLanguage.Insert();
            until WindowsLanguage.Next() = 0;
    end;

    local procedure AddToFilter(Value: Text; var ValueFilter: Text)
    begin
        if ValueFilter = '' then
            ValueFilter := Value
        else
            ValueFilter += '|' + Value;
    end;

    procedure GetDefaultApplicationLanguageId(): Integer
    begin
        exit(1033); // en-US
    end;

    procedure ToDefaultLanguage(ValueVariant: Variant): Text
    var
        Result: Text;
        CurrentLanguage: Integer;
        DummyBoolean: Boolean;
    begin
        case true of
            // Handle specific data types in case the function is being called within a report that uses local language.
            // In that case the current local language takes priority and the default case logic won't work.
            ValueVariant.IsBoolean:
                begin
                    DummyBoolean := ValueVariant;
                    if DummyBoolean then
                        Result := 'Yes'
                    else
                        Result := 'No';
                end;
            else begin
                CurrentLanguage := GlobalLanguage();
                GlobalLanguage(GetDefaultApplicationLanguageId());

                Result := Format(ValueVariant);

                GlobalLanguage(CurrentLanguage);
            end;
        end;

        exit(Result);
    end;

    procedure ValidateApplicationLanguageId(LanguageId: Integer)
    var
        TempWindowsLanguage: Record "Windows Language" temporary;
    begin
        GetApplicationLanguages(TempWindowsLanguage);

        TempWindowsLanguage.SetRange("Language ID", LanguageId);

        if TempWindowsLanguage.IsEmpty() then
            Error(LanguageNotFoundErr, LanguageId);
    end;

    procedure ValidateWindowsLanguageId(LanguageId: Integer)
    var
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.SetRange("Language ID", LanguageId);

        if WindowsLanguage.IsEmpty() then
            Error(LanguageNotFoundErr, LanguageId);
    end;

    procedure LookupApplicationLanguageId(var LanguageId: Integer)
    var
        TempWindowsLanguage: Record "Windows Language" temporary;
    begin
        GetApplicationLanguages(TempWindowsLanguage);

        TempWindowsLanguage.SetCurrentKey(Name);

        if TempWindowsLanguage.Get(LanguageId) then;

        if Page.RunModal(Page::"Windows Languages", TempWindowsLanguage) = Action::LookupOK then
            LanguageId := TempWindowsLanguage."Language ID";
    end;

    procedure LookupLanguageCode(var LanguageCode: Code[10])
    var
        Language: Record Language;
    begin
        Language.SetCurrentKey(Name);

        if Language.Get(LanguageCode) then;

        if Page.RunModal(Page::Languages, Language) = Action::LookupOK then
            LanguageCode := Language.Code;
    end;

    procedure LookupWindowsLanguageId(var LanguageId: Integer)
    var
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.SetCurrentKey(Name);

        if WindowsLanguage.Get(LanguageId) then;

        if Page.RunModal(Page::"Windows Languages", WindowsLanguage) = Action::LookupOK then
            LanguageId := WindowsLanguage."Language ID";
    end;

    procedure GetParentLanguageId(LanguageId: Integer) ParentLanguageId: Integer
    begin
        if TryGetParentLanguageId(LanguageId, ParentLanguageId) then
            exit(ParentLanguageId);

        exit(LanguageId);
    end;

    [TryFunction]
    local procedure TryGetParentLanguageId(LanguageId: Integer; var ParentLanguageId: Integer)
    var
        CultureInfo: DotNet CultureInfo;
    begin
        ParentLanguageId := CultureInfo.CultureInfo(LanguageId).Parent().LCID();
    end;

    procedure SetPreferredLanguageID(UserSecID: Guid; NewLanguageID: Integer)
    var
        UserPersonalization: Record "User Personalization";
    begin
        if not UserPersonalization.ReadPermission() then
            exit;

        if not UserPersonalization.Get(UserSecID) then
            exit;

        // Only lock the table if there is a change
        if UserPersonalization."Language ID" = NewLanguageID then
            exit; // No changes required

        UserPersonalization.LockTable();
        UserPersonalization.Get(UserSecID);
        UserPersonalization.Validate("Language ID", NewLanguageID);
        UserPersonalization.Validate("Locale ID", NewLanguageID);
        UserPersonalization.Modify(true);
    end;

    procedure GetTwoLetterISOLanguageName(LanguageID: Integer): Text[2]
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.CultureInfo(LanguageID);
        exit(CultureInfo.TwoLetterISOLanguageName);
    end;

    procedure GetLanguageIdFromCultureName(CultureName: Text): Integer
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.CultureInfo(CultureName);
        exit(CultureInfo.LCID());
    end;

    procedure GetCultureName(LanguageID: Integer): Text
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.CultureInfo(LanguageID);
        exit(CultureInfo.Name);
    end;

    procedure GetCurrentCultureName(): Text
    var
        CultureInfo: DotNet CultureInfo;
    begin
        exit(CultureInfo.CurrentCulture.Name);
    end;

    procedure ShowAllowedLanguagesNotification()
    var
        AllowedLanguage: Record "Allowed Language";
        Notification: Notification;
        NotificationGuid: Guid;
    begin
        if AllowedLanguage.IsEmpty() then
            exit;

        NotificationGuid := NotificationAllowedLanguagesLbl;
        Notification.Id(NotificationGuid);
        Notification.Message(NotificationAllowedLanguagesMessageLbl);
        Notification.AddAction(ReadMoreLbl, Codeunit::"Language Impl.", 'OpenReadMore');
        Notification.Send();
    end;

    procedure OpenReadMore(Notification: Notification)
    begin
        Hyperlink('https://go.microsoft.com/fwlink/?linkid=2299275');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", GetApplicationLanguage, '', false, false)]
    local procedure SetApplicationLanguageId(var language: Integer)
    begin
        language := GetDefaultApplicationLanguageId();
    end;
}

