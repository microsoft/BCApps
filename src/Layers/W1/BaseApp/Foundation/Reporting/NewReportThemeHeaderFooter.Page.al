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
                Visible = not EditMode;
                ToolTip = 'Specifies the name of the new theme or header/footer.';
            }
            field(DescriptionField; PartDescription)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Description';
                ToolTip = 'Specifies a description for the new theme or header/footer.';
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

    internal procedure GetPartDescription(): Text[250]
    begin
        exit(PartDescription);
    end;

    /// <summary>
    /// Switches the dialog to description-only edit mode: the Name is hidden (renaming a part would orphan its
    /// Tenant Report Layout Cfg assignments) and the description is pre-filled with the current value.
    /// </summary>
    internal procedure SetEditDescriptionMode(CurrentDescription: Text[250])
    begin
        EditMode := true;
        PartDescription := CurrentDescription;
        DialogCaption := EditDescriptionCaptionLbl;
    end;

    var
        PartName: Text[250];
        PartDescription: Text[250];
        DialogCaption: Text;
        EditMode: Boolean;
        NewThemeCaptionLbl: Label 'New Theme';
        NewHeaderFooterCaptionLbl: Label 'New Header/Footer';
        EditDescriptionCaptionLbl: Label 'Edit Description';
}
