// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Globalization;

/// <summary>
/// Page that shows the list of allows languages which is enabled for this environment. If nothing is specified, then the user will be able to use all available languages.
/// </summary>
page 3563 "Allowed Languages"
{
    Caption = 'Allowed Languages';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Allowed Language";
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2149387';
    AdditionalSearchTerms = 'company,role center,role,language';
    AboutTitle = 'About allowed languages.';
    AboutText = 'Define a list of allowed languages which are enabled in this environment. If nothing is specified, the user will be able to select from all languages.';

    layout
    {
        area(Content)
        {
            repeater(AllowedLanguages)
            {
                field("Language Id"; Rec."Language Id")
                {
                }
                field(Language; Rec.Language)
                {
                }
            }
        }
    }
}