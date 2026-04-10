// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

/// <summary>
/// Enables mapping of intercompany dimension values to local company dimension values for incoming transactions.
/// Provides editing interface for establishing dimension value mappings with hierarchical display formatting.
/// </summary>
page 635 "IC Mapping Dim Values Incoming"
{
    PageType = ListPart;
    SourceTable = "IC Dimension Value";
    Editable = true;
    DeleteAllowed = true;
    InsertAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(ICDimCode; Rec."Code")
                {
                    Caption = 'IC Dim. Code';
                    ToolTip = 'Specifies the intercompany''s dimension value code.';
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field(ICDimName; Rec.Name)
                {
                    Caption = 'IC Dim. Name';
                    ToolTip = 'Specifies the intercompany''s dimension value name.';
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
                field(CompanyDimCode; Rec."Map-to Dimension Code")
                {
                    Caption = 'Dim. Code';
                    ToolTip = 'Specifies the dimension code associated with the corresponding intercompany dimension.';
                    ApplicationArea = All;
                    TableRelation = Dimension.Code;
                    Editable = false;
                    Enabled = false;
                }
                field(CompanyDimValueCode; Rec."Map-to Dimension Value Code")
                {
                    Caption = 'Dim. Value Code';
                    ToolTip = 'Specifies the dimension''s value code associated with the corresponding intercompany''s dimension value.';
                    ApplicationArea = All;
                    TableRelation = "Dimension Value".Code;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Dimension Code", '= %1 & <> ''''', ICDimensionFilter.Code);
        Rec.SetFilter("Map-to Dimension Code", '<> ''''');
        CurrPage.Update();
    end;

    trigger OnAfterGetRecord()
    begin
        FormatLine();
    end;

    var
        ICDimensionFilter: Record "IC Dimension";
        Emphasize: Boolean;

    local procedure FormatLine()
    begin
        Emphasize := Rec."Dimension Value Type" <> Rec."Dimension Value Type"::Standard;
    end;

    /// <summary>
    /// Sets the intercompany dimension filter for dimension values displayed in the page.
    /// </summary>
    /// <param name="ICDimension">IC dimension record to filter by</param>
    procedure SetDimensionFilter(ICDimension: Record "IC Dimension")
    begin
        ICDimensionFilter := ICDimension;
    end;

    /// <summary>
    /// Retrieves the currently selected intercompany dimension value lines for processing.
    /// </summary>
    /// <param name="ICDimensionValues">Record variable to store selected IC dimension value records</param>
    procedure GetSelectedLines(var ICDimensionValues: Record "IC Dimension Value")
    begin
        CurrPage.SetSelectionFilter(ICDimensionValues);
    end;
}
