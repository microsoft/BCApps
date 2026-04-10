// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Page for editing dimension set entries in a temporary context.
/// Provides interface for modifying dimension combinations and generating updated dimension set IDs.
/// </summary>
/// <remarks>
/// Uses temporary table source to allow dimension editing without immediate database persistence.
/// Supports dynamic form captions and integrates with dimension management for dimension set creation.
/// Returns updated dimension set ID upon page closure for use in calling processes.
/// </remarks>
page 480 "Edit Dimension Set Entries"
{
    Caption = 'Edit Dimension Set Entries';
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Dimension Set Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = Rec."Dimension Value Code" = '';
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field(DimensionValueCode; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension Value Name"; Rec."Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnClosePage()
    begin
        DimSetID := DimMgt.GetDimensionSetID(Rec);
    end;

    trigger OnOpenPage()
    begin
        DimSetID := Rec.GetRangeMin("Dimension Set ID");
        DimMgt.GetDimensionSet(Rec, DimSetID);
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        DimSetID: Integer;
        FormCaption: Text[250];

    /// <summary>
    /// Retrieves the current dimension set ID after dimension editing operations.
    /// Returns the dimension set ID generated from the edited dimension entries.
    /// </summary>
    /// <returns>Dimension set ID representing the current dimension combination</returns>
    /// <remarks>
    /// Used by calling processes to obtain the updated dimension set ID after dimension editing.
    /// The ID is generated when the page closes through dimension management integration.
    /// </remarks>
    procedure GetDimensionID(): Integer
    begin
        exit(DimSetID);
    end;

    /// <summary>
    /// Sets a custom caption for the dimension editing form.
    /// Allows contextual form titles to indicate the source or purpose of dimension editing.
    /// </summary>
    /// <param name="NewFormCaption">Custom caption text to be combined with the default page caption</param>
    /// <remarks>
    /// Combines the provided caption with the default page caption using a separator.
    /// Applied when the page opens to provide context-specific titles for dimension editing scenarios.
    /// </remarks>
    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;
}

