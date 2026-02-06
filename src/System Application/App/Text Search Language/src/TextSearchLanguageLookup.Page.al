// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Database;
using System.Globalization;

page 9235 "Text Search Language Lookup"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = "Windows Language";
    Caption = 'Select Text Search Language';
    SourceTableTemporary = true;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the language.';
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        WindowsLanguage: Record "Windows Language";
        IndexManagement: Codeunit "Index Management";
        SupportedLanguages: Dictionary of [Integer, Text];
        LanguageId: Integer;
    begin
        Rec.DeleteAll();
        SupportedLanguages := IndexManagement.GetSupportedOptimizedTextSearchLanguages();
        foreach LanguageId in SupportedLanguages.Keys() do
            if WindowsLanguage.Get(LanguageId) then begin
                Rec.Init();
                Rec."Language ID" := LanguageId;
                if WindowsLanguage.Get(LanguageId) then
                    Rec.Name := WindowsLanguage.Name
                else
                    Rec.Name := CopyStr(SupportedLanguages.Get(LanguageId), 1, MaxStrLen(Rec.Name));
                Rec.Insert();
            end;
    end;
}