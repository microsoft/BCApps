// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

/// <summary>
/// Displays dimension values in list format with support for hierarchical indentation and selection filtering.
/// Supports both global dimensions and shortcut dimensions with dynamic caption management.
/// </summary>
/// <remarks>
/// Supports dimension value type formatting with visual emphasis for non-standard values.
/// Integrates with selection filter management for dimension value lookups and filtering operations.
/// </remarks>
page 560 "Dimension Value List"
{
    Caption = 'Dimension Value List';
    DataCaptionExpression = GetFormCaption();
    Editable = false;
    PageType = List;
    SourceTable = "Dimension Value";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field("Dimension Value Type"; Rec."Dimension Value Type")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Consolidation Code"; Rec."Consolidation Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLines();
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Shortcut Dimension %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Emphasize: Boolean;
        NameIndent: Integer;

    /// <summary>
    /// Returns selection filter text for currently selected dimension values using selection filter management.
    /// Provides formatted filter expression for use in reports and queries.
    /// </summary>
    /// <returns>Selection filter text for selected dimension values</returns>
    procedure GetSelectionFilter(): Text
    var
        DimVal: Record "Dimension Value";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(DimVal);
        exit(SelectionFilterManagement.GetSelectionFilterForDimensionValue(DimVal));
    end;

    /// <summary>
    /// Sets selection filter on the current page based on provided dimension value records.
    /// Enables bulk selection and filtering operations for dimension value processing.
    /// </summary>
    /// <param name="DimVal">Dimension value records to use for selection filtering</param>
    procedure SetSelection(var DimVal: Record "Dimension Value")
    begin
        CurrPage.SetSelectionFilter(DimVal);
    end;

    local procedure GetFormCaption(): Text[250]
    begin
        if Rec.GetFilter("Dimension Code") <> '' then
            exit(Rec.GetFilter("Dimension Code"));

        if Rec.GetFilter("Global Dimension No.") = '1' then
            exit(GLSetup."Global Dimension 1 Code");

        if Rec.GetFilter("Global Dimension No.") = '2' then
            exit(GLSetup."Global Dimension 2 Code");

        if Rec.GetFilter("Global Dimension No.") = '3' then
            exit(GLSetup."Shortcut Dimension 3 Code");

        if Rec.GetFilter("Global Dimension No.") = '4' then
            exit(GLSetup."Shortcut Dimension 4 Code");

        if Rec.GetFilter("Global Dimension No.") = '5' then
            exit(GLSetup."Shortcut Dimension 5 Code");

        if Rec.GetFilter("Global Dimension No.") = '6' then
            exit(GLSetup."Shortcut Dimension 6 Code");

        if Rec.GetFilter("Global Dimension No.") = '7' then
            exit(GLSetup."Shortcut Dimension 7 Code");

        if Rec.GetFilter("Global Dimension No.") = '8' then
            exit(GLSetup."Shortcut Dimension 8 Code");

        exit(StrSubstNo(Text000, Rec."Global Dimension No."));
    end;

    local procedure FormatLines()
    begin
        Emphasize := Rec."Dimension Value Type" <> Rec."Dimension Value Type"::Standard;
        NameIndent := Rec.Indentation;
    end;
}

