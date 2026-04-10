// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Simple dimension selection list for single dimension choice scenarios.
/// Provides read-only view of available dimensions for selection-based operations.
/// </summary>
/// <remarks>
/// Used in scenarios requiring single dimension selection from a predefined list.
/// Supports dimension lookup operations and selection workflows in various business processes.
/// Provides integration events for custom validation and processing during dimension selection.
/// </remarks>
page 568 "Dimension Selection"
{
    Caption = 'Dimension Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Dimension Selection Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
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
    /// Retrieves the dimension code of the currently selected dimension.
    /// Returns the code for the dimension record positioned in the selection list.
    /// </summary>
    /// <returns>Code of the selected dimension</returns>
    procedure GetDimSelCode(): Text[30]
    begin
        exit(Rec.Code);
    end;

    /// <summary>
    /// Adds a dimension entry to the selection buffer for display in the dimension list.
    /// Automatically resolves dimension descriptions and configures lookup table mappings.
    /// </summary>
    /// <param name="NewSelected">Initial selection state for the dimension</param>
    /// <param name="NewCode">Dimension code to add to the selection list</param>
    /// <param name="NewDescription">Description for the dimension, auto-resolved if empty</param>
    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30])
    var
        Dim: Record Dimension;
        GLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        if NewDescription = '' then
            if Dim.Get(NewCode) then
                NewDescription := Dim.GetMLName(GlobalLanguage);

        Rec.Init();
        Rec.Selected := NewSelected;
        Rec.Code := NewCode;
        Rec.Description := NewDescription;
        case Rec.Code of
            GLAcc.TableCaption:
                Rec."Filter Lookup Table No." := Database::"G/L Account";
            BusinessUnit.TableCaption:
                Rec."Filter Lookup Table No." := Database::"Business Unit";
        end;
        OnInsertDimSelBufOnBeforeInsert(Rec);
        Rec.Insert();
    end;

    /// <summary>
    /// Integration event raised before inserting a dimension selection buffer record.
    /// Enables custom validation and field modification during dimension selection setup.
    /// </summary>
    /// <param name="DimensionSelectionBuffer">Dimension selection buffer record being inserted</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertDimSelBufOnBeforeInsert(var DimensionSelectionBuffer: Record "Dimension Selection Buffer")
    begin
    end;
}

