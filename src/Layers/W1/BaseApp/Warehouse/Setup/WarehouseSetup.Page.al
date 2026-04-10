// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

page 5775 "Warehouse Setup"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Warehouse Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Require Receive"; Rec."Require Receive")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Require Put-away"; Rec."Require Put-away")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Require Shipment"; Rec."Require Shipment")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Require Pick"; Rec."Require Pick")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Last Whse. Posting Ref. No."; Rec.GetCurrentReference())
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Last Whse. Posting Ref. No.';
                    ToolTip = 'Specifies that the document reference of the last warehouse posting will be shown.';
                }
                field("Receipt Posting Policy"; Rec."Receipt Posting Policy")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shipment Posting Policy"; Rec."Shipment Posting Policy")
                {
                    ApplicationArea = Warehouse;
                }
                field("Copy Item Descr. to Entries"; Rec."Copy Item Descr. to Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Whse. Receipt Nos."; Rec."Whse. Receipt Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Whse. Ship Nos."; Rec."Whse. Ship Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Whse. Internal Put-away Nos."; Rec."Whse. Internal Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Whse. Internal Pick Nos."; Rec."Whse. Internal Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Whse. Put-away Nos."; Rec."Whse. Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Whse. Pick Nos."; Rec."Whse. Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Posted Whse. Receipt Nos."; Rec."Posted Whse. Receipt Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Posted Whse. Shipment Nos."; Rec."Posted Whse. Shipment Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Registered Whse. Put-away Nos."; Rec."Registered Whse. Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Registered Whse. Pick Nos."; Rec."Registered Whse. Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Whse. Movement Nos."; Rec."Whse. Movement Nos.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Registered Whse. Movement Nos."; Rec."Registered Whse. Movement Nos.")
                {
                    ApplicationArea = Warehouse;
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

