// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

page 667 "IC Mapping Dimension Outgoing"
{
    PageType = ListPart;
    SourceTable = Dimension;
    Editable = true;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(CompanyDimCode; Rec.Code)
                {
                    Caption = 'Dim. Code.';
                    ToolTip = 'Specifies the dimension code.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field(CompanyDimName; Rec.Name)
                {
                    Caption = 'Dim. Name';
                    ToolTip = 'Specifies the dimension name.';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = false;
                }
                field(ICDimCode; Rec."Map-to IC Dimension Code")
                {
                    Caption = 'IC Dim. Code';
                    ToolTip = 'Specifies the intercompany''s dimension code associated with the dimension of the current company.';
                    ApplicationArea = All;
                    TableRelation = "IC Dimension".Code;
                    Editable = true;
                    Enabled = true;
                }
            }
        }
    }
    procedure GetSelectedLines(var Dimensions: Record Dimension)
    begin
        CurrPage.SetSelectionFilter(Dimensions);
    end;
}
