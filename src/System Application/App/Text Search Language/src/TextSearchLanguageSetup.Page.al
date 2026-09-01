// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Database;
using System.Globalization;

/// <summary>This page allows users to select the optimized text search language, triggering re-indexing to improve full-text search performance for the chosen language.</summary>
page 9234 "Text Search Language Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Text Search Language Optimizer';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field(Name; LanguageName)
            {
                Lookup = true;
                Caption = 'Language';
                ToolTip = 'Specifies the optimized text search language for the current environment. Changing this language requires re-indexing which can take a long time.';

                trigger OnLookup(var Value: Text): Boolean
                var
                    TempWindowsLanguage: Record "Windows Language" temporary;
                    IndexManagement: Codeunit "Index Management";
                    TextSearchLanguageLookup: Page "Text Search Language Lookup";
                begin
                    Clear(TextSearchLanguageLookup);
                    TextSearchLanguageLookup.LookupMode(true);
                    if TextSearchLanguageLookup.RunModal() = Action::LookupOK then
                        if Confirm(ConfirmLanguageChangeQst) then begin
                            TextSearchLanguageLookup.GetRecord(TempWindowsLanguage);
                            IndexManagement.SetCurrentOptimizedTextSearchLanguage(TempWindowsLanguage."Language ID");
                            UpdateCurrentOptimizedTextSearchLanguage();
                        end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateCurrentOptimizedTextSearchLanguage();
    end;

    local procedure UpdateCurrentOptimizedTextSearchLanguage()
    var
        WindowsLang: Record "Windows Language";
        IndexManagement: Codeunit "Index Management";
        LanguageId: Integer;
    begin
        LanguageId := IndexManagement.GetCurrentOptimizedTextSearchLanguage();

        if WindowsLang.Get(LanguageId) then
            LanguageName := WindowsLang.Name
        else
            LanguageName := IndexManagement.GetSupportedOptimizedTextSearchLanguages().Get(LanguageId);
    end;

    var
        LanguageName: Text;
        ConfirmLanguageChangeQst: Label 'Changing the optimized text search language requires re-indexing, which can take a significant amount of time. It is recommended to do this outside of work hours. Do you want to continue?';
}