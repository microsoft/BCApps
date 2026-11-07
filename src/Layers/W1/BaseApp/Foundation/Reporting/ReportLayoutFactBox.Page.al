// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;

page 9669 "Report Layout FactBox"
{
    PageType = CardPart;
    Caption = 'Details';
    SourceTable = "Report Layout List";
    Editable = false;
    Extensible = true;

    layout
    {
        area(content)
        {
            group(DescriptionGroup)
            {
                ShowCaption = false;

                field(DescriptionField; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ShowCaption = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the description of the selected layout.';
                }
            }
            group(CompositeLayout)
            {
                Caption = 'Theme and Header/Footer';

                field(ThemeField; ThemeDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Theme';
                    ToolTip = 'Specifies the theme applied to the selected layout. None = no theme applies at any level.';
                }
                field(ThemeSourceField; ThemeSource)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Theme source';
                    ToolTip = 'Specifies where the theme resolves from: This layout, Report default, Company (Company Information), or Global default.';
                }
                field(HeaderFooterField; HeaderDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Header/Footer';
                    ToolTip = 'Specifies the header/footer applied to the selected layout. None = none applies at any level.';
                }
                field(HeaderSourceField; HeaderSource)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Header/Footer source';
                    ToolTip = 'Specifies where the header/footer resolves from: This layout, Report default, Company (Company Information), or Global default.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Clear(ThemeDisplay);
        Clear(ThemeSource);
        Clear(HeaderDisplay);
        Clear(HeaderSource);

        if Rec."Report ID" <> 0 then
            LookupHelper.GetResolvedPartDisplays(
                Rec."Report ID", LookupHelper.CompositeLayoutKey(Rec), HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);

    end;

    var
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        ThemeDisplay: Text;
        ThemeSource: Text;
        HeaderDisplay: Text;
        HeaderSource: Text;
}
