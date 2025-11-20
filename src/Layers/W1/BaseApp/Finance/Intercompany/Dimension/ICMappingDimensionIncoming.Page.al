// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

page 657 "IC Mapping Dimension Incoming"
{
    PageType = ListPart;
    SourceTable = "IC Dimension";
    Editable = true;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(ICDimCode; Rec."Code")
                {
                    Caption = 'IC Dim. Code';
                    ToolTip = 'Specifies the intercompany dimension code.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field(ICDimName; Rec.Name)
                {
                    Caption = 'IC Dim. Name';
                    ToolTip = 'Specifies the intercompany dimension name.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field(CompanyDimCode; Rec."Map-to Dimension Code")
                {
                    Caption = 'Dim. Code';
                    ToolTip = 'Specifies the dimension code associated with the corresponding intercompany dimension.';
                    ApplicationArea = All;
                    TableRelation = Dimension.Code;
                    Editable = true;
                    Enabled = true;
                }
            }
        }
    }

    procedure GetSelectedLines(var ICDimensions: Record "IC Dimension")
    begin
        CurrPage.SetSelectionFilter(ICDimensions);
    end;
}
