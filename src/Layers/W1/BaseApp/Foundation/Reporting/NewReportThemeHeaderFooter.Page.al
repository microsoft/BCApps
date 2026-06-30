// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;

/// <summary>
/// Minimal dialog to capture the name of a new theme or header/footer artifact. The caller creates the layout under
/// Tenant Report Defaults so the artifact is assignable to any report; only the name is needed here, unlike the full
/// Report Layout New Dialog. The dialog title reflects whether a theme or a header/footer is being added.
/// </summary>
page 9668 "New Report Theme Header/Footer"
{
    PageType = StandardDialog;
    Caption = 'New Theme or Header/Footer';
    Extensible = true;

    layout
    {
        area(content)
        {
            field(NameField; PartName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                ShowMandatory = true;
                ToolTip = 'Specifies the name of the new theme or header/footer.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        if DialogCaption <> '' then
            CurrPage.Caption := DialogCaption;
    end;

    internal procedure SetSubtype(NewSubtype: Enum "Report Layout Subtype")
    begin
        if NewSubtype = Enum::"Report Layout Subtype"::Theme then
            DialogCaption := NewThemeCaptionLbl
        else
            DialogCaption := NewHeaderFooterCaptionLbl;
    end;

    internal procedure GetPartName(): Text[250]
    begin
        exit(PartName);
    end;

    var
        PartName: Text[250];
        DialogCaption: Text;
        NewThemeCaptionLbl: Label 'New Theme';
        NewHeaderFooterCaptionLbl: Label 'New Header/Footer';
}
