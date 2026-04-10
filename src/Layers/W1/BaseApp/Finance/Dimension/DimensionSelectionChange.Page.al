// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Interactive dimension selection interface for dimension value change operations.
/// Enables users to select dimensions and specify new dimension values for bulk change scenarios.
/// </summary>
/// <remarks>
/// Used in dimension change and reclassification processes where dimension values need to be updated.
/// Supports filtering existing dimension values and specifying new target dimension values for replacement.
/// Commonly used in dimension correction, reclassification, and global dimension change workflows.
/// </remarks>
page 567 "Dimension Selection-Change"
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
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Dimensions;
                }
                field("New Dimension Value Code"; Rec."New Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                }
            }
        }
    }

    actions
    {
    }

    /// <summary>
    /// Retrieves all dimension selections with change criteria from the temporary buffer.
    /// Transfers complete dimension configuration including filters and new values to calling process.
    /// </summary>
    /// <param name="TheDimSelectionBuf">Target buffer to receive dimension selection and change configuration</param>
    procedure GetDimSelBuf(var TheDimSelectionBuf: Record "Dimension Selection Buffer")
    begin
        TheDimSelectionBuf.DeleteAll();
        if Rec.Find('-') then
            repeat
                TheDimSelectionBuf := Rec;
                TheDimSelectionBuf.Insert();
            until Rec.Next() = 0;
    end;

    /// <summary>
    /// Adds a dimension to the selection buffer with change criteria including new dimension value codes.
    /// Automatically resolves dimension descriptions and configures lookup tables for various entity types.
    /// </summary>
    /// <param name="NewSelected">Whether the dimension is initially selected for change</param>
    /// <param name="NewCode">Dimension code to add</param>
    /// <param name="NewDescription">Description for the dimension, auto-resolved if empty</param>
    /// <param name="NewNewDimValueCode">New dimension value code to change to</param>
    /// <param name="NewDimValueFilter">Filter criteria for existing dimension values to change</param>
    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30]; NewNewDimValueCode: Code[20]; NewDimValueFilter: Text[250])
    var
        Dim: Record Dimension;
        GLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        if NewDescription = '' then
            if Dim.Get(NewCode) then
                NewDescription := Dim.Name;

        Rec.Init();
        Rec.Selected := NewSelected;
        Rec.Code := NewCode;
        Rec.Description := NewDescription;
        if NewSelected then begin
            Rec."New Dimension Value Code" := NewNewDimValueCode;
            Rec."Dimension Value Filter" := NewDimValueFilter;
        end;
        case Rec.Code of
            GLAcc.TableCaption:
                Rec."Filter Lookup Table No." := Database::"G/L Account";
            BusinessUnit.TableCaption:
                Rec."Filter Lookup Table No." := Database::"Business Unit";
        end;
        Rec.Insert();
    end;
}

