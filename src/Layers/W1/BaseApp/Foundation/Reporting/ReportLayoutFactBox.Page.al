// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;

/// <summary>
/// FactBox with details for the selected report layout: its description, and the theme and header/footer that apply to
/// it. The layout's name is not repeated here; the host page's row already shows it. Bound to the layout through the
/// host page's SubPageLink, like the other detail FactBoxes. The resolved part values are read-only: 'None' = no part
/// applies, 'Default' = a broader configured default applies, otherwise the assigned part name.
/// </summary>
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

                // Neither the group nor the field shows a caption: the FactBox opens with the description as bare
                // text. Keeping the field inside a group is what leaves it the full width of the FactBox, so a long
                // description wraps instead of being clipped to the right-hand half of a single line.
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

        // Only resolve when a report is selected; with no report there is nothing to show.
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
