// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

/// <summary>
/// FactBox that shows the theme and header/footer applied to the selected report layout. The host page pushes the
/// current report and layout via <see cref="SetContext"/>. Values are read-only: 'None' = no part applies,
/// 'Default' = a broader configured default applies, otherwise the assigned part name.
/// </summary>
page 9669 "Theme and Header/Footer Box"
{
    PageType = CardPart;
    Caption = 'Theme and Header/Footer';
    Editable = false;
    Extensible = true;

    layout
    {
        area(content)
        {
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
                Visible = ThemeSourceVisible;
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
                Visible = HeaderSourceVisible;
                ToolTip = 'Specifies where the header/footer resolves from: This layout, Report default, Company (Company Information), or Global default.';
            }
        }
    }

    internal procedure SetContext(ReportID: Integer; LayoutName: Text)
    begin
        Clear(ThemeDisplay);
        Clear(ThemeSource);
        Clear(HeaderDisplay);
        Clear(HeaderSource);
        // Only resolve when a report is selected; with no report there is nothing to show.
        if ReportID <> 0 then
            LookupHelper.GetResolvedPartDisplays(ReportID, LayoutName, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);
        // Show the source columns only when a source actually resolved (i.e. the value is not blank).
        ThemeSourceVisible := ThemeSource <> '';
        HeaderSourceVisible := HeaderSource <> '';
        CurrPage.Update(false);
    end;

    var
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        ThemeDisplay: Text;
        ThemeSource: Text;
        ThemeSourceVisible: Boolean;
        HeaderDisplay: Text;
        HeaderSource: Text;
        HeaderSourceVisible: Boolean;
}
