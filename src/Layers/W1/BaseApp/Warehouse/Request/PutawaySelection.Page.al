// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

page 7334 "Put-away Selection"
{
    Caption = 'Put-away Selection';
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Put-away Request";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that created the warehouse put-away request.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse document that should be put away.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location in which the request is occurring.';
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code where the bin on the request is located.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Completely Put Away"; Rec."Completely Put Away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that all the items on the warehouse source document have been put away.';
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

    procedure GetResult(var WhsePutAwayRequest: Record "Whse. Put-away Request")
    begin
        CurrPage.SetSelectionFilter(WhsePutAwayRequest);
    end;
}

