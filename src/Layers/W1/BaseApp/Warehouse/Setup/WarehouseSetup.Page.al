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
                    ToolTip = 'Specifies whether you require users to use the receive activity.';
                    Visible = false;
                }
                field("Require Put-away"; Rec."Require Put-away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether you require users to use the put-away activity.';
                    Visible = false;
                }
                field("Require Shipment"; Rec."Require Shipment")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if warehouse shipments are required in warehouse work flows.';
                    Visible = false;
                }
                field("Require Pick"; Rec."Require Pick")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether you require users to use the pick activity.';
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
                    ToolTip = 'Specifies what should happen if errors occur when warehouse receipts are posted.';
                }
                field("Shipment Posting Policy"; Rec."Shipment Posting Policy")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies what should happen if errors occur when warehouse shipments are posted per source document.';
                }
                field("Copy Item Descr. to Entries"; Rec."Copy Item Descr. to Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the description on item cards to be copied to warehouse entries during registering.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Whse. Receipt Nos."; Rec."Whse. Receipt Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code to use when you assign numbers to warehouse receipt journals.';
                }
                field("Whse. Ship Nos."; Rec."Whse. Ship Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse shipment journals.';
                }
                field("Whse. Internal Put-away Nos."; Rec."Whse. Internal Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to internal put-always.';
                }
                field("Whse. Internal Pick Nos."; Rec."Whse. Internal Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to internal picks.';
                }
                field("Whse. Put-away Nos."; Rec."Whse. Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse put-away documents.';
                }
                field("Whse. Pick Nos."; Rec."Whse. Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code you want used when you assign numbers to warehouse pick documents.';
                }
                field("Posted Whse. Receipt Nos."; Rec."Posted Whse. Receipt Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to posted warehouse receipts.';
                }
                field("Posted Whse. Shipment Nos."; Rec."Posted Whse. Shipment Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to posted warehouse shipments.';
                }
                field("Registered Whse. Put-away Nos."; Rec."Registered Whse. Put-away Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used when numbers are assigned to registered put-away documents.';
                }
                field("Registered Whse. Pick Nos."; Rec."Registered Whse. Pick Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code you want to be used to assign numbers to registered pick documents.';
                }
                field("Whse. Movement Nos."; Rec."Whse. Movement Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to warehouse movements.';
                }
                field("Registered Whse. Movement Nos."; Rec."Registered Whse. Movement Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign numbers to registered warehouse movements.';
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

