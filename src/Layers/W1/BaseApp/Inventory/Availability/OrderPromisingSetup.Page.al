// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

page 99000958 "Order Promising Setup"
{
    AdditionalSearchTerms = 'calculate delivery,capable to promise,ctp,available to promise,atp';
    ApplicationArea = OrderPromising;
    Caption = 'Order Promising Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Order Promising Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Offset (Time)"; Rec."Offset (Time)")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the period of time to wait before issuing a new purchase order, production order, or transfer order.';
                }
                field("Order Promising Nos."; Rec."Order Promising Nos.")
                {
                    ApplicationArea = OrderPromising;
                }
                field("Order Promising Template"; Rec."Order Promising Template")
                {
                    ApplicationArea = OrderPromising;
                }
                field("Order Promising Worksheet"; Rec."Order Promising Worksheet")
                {
                    ApplicationArea = OrderPromising;
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

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

