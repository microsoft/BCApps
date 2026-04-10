// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Page for editing dimension reclassification mappings in a temporary buffer context.
/// Provides interface for defining old and new dimension value pairs for reclassification operations.
/// </summary>
/// <remarks>
/// Uses Reclas. Dimension Set Buffer as temporary source to manage dimension value mappings.
/// Supports dimension reclassification scenarios where dimension values need to be changed across entries.
/// Returns both original and new dimension set IDs for reclassification processing.
/// </remarks>
page 484 "Edit Reclas. Dimensions"
{
    Caption = 'Edit Reclas. Dimensions';
    PageType = List;
    SourceTable = "Reclas. Dimension Set Buffer";
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
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("New Dimension Value Code"; Rec."New Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension Value Name"; Rec."Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                }
                field("New Dimension Value Name"; Rec."New Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        FormCaption: Text[250];

    /// <summary>
    /// Retrieves both original and new dimension set IDs from the reclassification buffer.
    /// Returns dimension set IDs representing the before and after states of dimension reclassification.
    /// </summary>
    /// <param name="DimSetID">Returns the original dimension set ID before reclassification</param>
    /// <param name="NewDimSetId">Returns the new dimension set ID after reclassification</param>
    /// <remarks>
    /// Used by calling processes to obtain both dimension set IDs for reclassification operations.
    /// Delegates to buffer methods for dimension set ID generation from current mappings.
    /// </remarks>
    procedure GetDimensionIDs(var DimSetID: Integer; var NewDimSetId: Integer)
    begin
        DimSetID := Rec.GetDimSetID(Rec);
        NewDimSetId := Rec.GetNewDimSetID(Rec);
    end;

    /// <summary>
    /// Sets up dimension reclassification buffer with original and new dimension set entries.
    /// Populates the buffer with dimension mappings based on provided dimension set IDs.
    /// </summary>
    /// <param name="DimSetID">Original dimension set ID to load into buffer</param>
    /// <param name="NewDimSetId">New dimension set ID to map against original dimensions</param>
    /// <remarks>
    /// Clears existing buffer and populates with dimension entries from both dimension sets.
    /// Creates mapping structure showing old and new dimension values for reclassification editing.
    /// </remarks>
    procedure SetDimensionIDs(DimSetID: Integer; NewDimSetId: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        Rec.DeleteAll();
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet() then
            repeat
                Rec."Dimension Code" := DimSetEntry."Dimension Code";
                Rec."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                Rec."Dimension Value ID" := DimSetEntry."Dimension Value ID";
                Rec.Insert();
            until DimSetEntry.Next() = 0;
        DimSetEntry.SetRange("Dimension Set ID", NewDimSetId);
        if DimSetEntry.FindSet() then
            repeat
                if not Rec.Get(DimSetEntry."Dimension Code") then begin
                    Rec."Dimension Code" := DimSetEntry."Dimension Code";
                    Rec."Dimension Value Code" := '';
                    Rec."Dimension Value ID" := 0;
                    Rec.Insert();
                end;
                Rec."New Dimension Value Code" := DimSetEntry."Dimension Value Code";
                Rec."New Dimension Value ID" := DimSetEntry."Dimension Value ID";
                Rec.Modify();
            until DimSetEntry.Next() = 0;
    end;

    /// <summary>
    /// Sets a custom caption for the dimension reclassification form.
    /// Allows contextual form titles to indicate the source or purpose of dimension reclassification.
    /// </summary>
    /// <param name="NewFormCaption">Custom caption text to be combined with the default page caption</param>
    /// <remarks>
    /// Combines the provided caption with the default page caption using a separator.
    /// Applied when the page opens to provide context-specific titles for reclassification scenarios.
    /// </remarks>
    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;
}

