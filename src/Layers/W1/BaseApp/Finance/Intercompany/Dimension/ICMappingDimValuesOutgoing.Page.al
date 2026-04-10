// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

/// <summary>
/// Enables mapping of local company dimension values to intercompany dimension values for outgoing transactions.
/// Provides editing interface for establishing dimension value mappings with hierarchical display formatting.
/// </summary>
page 677 "IC Mapping Dim Values Outgoing"
{
    PageType = ListPart;
    SourceTable = "Dimension Value";
    Editable = true;
    DeleteAllowed = true;
    InsertAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(CompanyDimCode; Rec.Code)
                {
                    Caption = 'Dim. Code.';
                    ToolTip = 'Specifies the dimension''s value code.';
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field(CompanyDimName; Rec.Name)
                {
                    Caption = 'Dim. Name';
                    ToolTip = 'Specifies the dimension''s value name.';
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field(Blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                    ApplicationArea = All;
                }
                field(ICDimCode; Rec."Map-to IC Dimension Code")
                {
                    Caption = 'IC Dim. Code';
                    ToolTip = 'Specifies the intercompany''s dimension code associated with the dimension of the current company.';
                    ApplicationArea = All;
                    TableRelation = "IC Dimension".Code;
                    Editable = false;
                    Enabled = false;
                }
                field(ICDimValueCode; Rec."Map-to IC Dimension Value Code")
                {
                    Caption = 'IC Dim. Value Code';
                    ToolTip = 'Specifies the intercompany''s dimension value code associated with the dimension''s value of the current company.';
                    ApplicationArea = All;
                    TableRelation = "IC Dimension Value".Code;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Dimension Code", '= %1 & <> ''''', DimensionFilter.Code);
        Rec.SetFilter("Map-to IC Dimension Code", '<> ''''');
        CurrPage.Update();
    end;

    trigger OnAfterGetRecord()
    begin
        FormatLine();
    end;

    var
        DimensionFilter: Record Dimension;
        Emphasize: Boolean;

    local procedure FormatLine()
    begin
        Emphasize := Rec."Dimension Value Type" <> Rec."Dimension Value Type"::Standard;
    end;

    /// <summary>
    /// Sets the dimension filter for dimension values displayed in the page.
    /// </summary>
    /// <param name="Dimension">Dimension record to filter by</param>
    procedure SetDimensionFilter(Dimension: Record Dimension)
    begin
        DimensionFilter := Dimension;
    end;

    /// <summary>
    /// Retrieves the currently selected dimension value lines for processing.
    /// </summary>
    /// <param name="DimensionValues">Record variable to store selected dimension value records</param>
    procedure GetSelectedLines(var DimensionValues: Record "Dimension Value")
    begin
        CurrPage.SetSelectionFilter(DimensionValues);
    end;
}
