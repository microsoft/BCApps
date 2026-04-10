// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Interactive worksheet for selecting multiple dimensions for analysis and reporting purposes.
/// Provides checkbox-based selection interface for dimension filtering and analysis scenarios.
/// </summary>
/// <remarks>
/// Used in reporting and analysis contexts where users need to select multiple dimensions simultaneously.
/// Works with Dimension Selection Buffer to manage temporary selection state during user interaction.
/// Common scenarios: multi-dimensional analysis setup, report dimension filtering, consolidation dimension selection.
/// </remarks>
page 562 "Dimension Selection-Multiple"
{
    Caption = 'Dimension Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Dimension Selection Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Dimensions;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    /// <summary>
    /// Retrieves all selected dimensions from the temporary buffer into the target record.
    /// Used to transfer user selections from the page to calling processes.
    /// </summary>
    /// <param name="DimensionSelectionBuffer">Target buffer to receive selected dimension records</param>
    procedure GetDimSelBuf(var DimensionSelectionBuffer: Record "Dimension Selection Buffer")
    begin
        DimensionSelectionBuffer.DeleteAll();
        if Rec.Find('-') then
            repeat
                DimensionSelectionBuffer := Rec;
                DimensionSelectionBuffer.Insert();
            until Rec.Next() = 0;
    end;

    /// <summary>
    /// Adds a new dimension selection entry to the temporary buffer for display on the page.
    /// Automatically resolves dimension descriptions and sets up filter lookup tables.
    /// </summary>
    /// <param name="NewSelected">Initial selection state for the dimension</param>
    /// <param name="NewCode">Dimension code to add</param>
    /// <param name="NewDescription">Description text for the dimension, auto-resolved if empty</param>
    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30])
    var
        Dimension: Record Dimension;
        GLAccount: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        if NewDescription = '' then
            if Dimension.Get(NewCode) then
                NewDescription := Dimension.GetMLName(GlobalLanguage);

        Rec.Init();
        Rec.Selected := NewSelected;
        Rec.Code := NewCode;
        Rec.Description := NewDescription;
        case Rec.Code of
            GLAccount.TableCaption:
                Rec."Filter Lookup Table No." := Database::"G/L Account";
            BusinessUnit.TableCaption:
                Rec."Filter Lookup Table No." := Database::"Business Unit";
        end;
        Rec.Insert();
    end;
}

