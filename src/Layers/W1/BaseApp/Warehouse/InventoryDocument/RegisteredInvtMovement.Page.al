// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InventoryDocument;

using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;

page 7384 "Registered Invt. Movement"
{
    Caption = 'Registered Invt. Movement';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Registered Invt. Movement Hdr.";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Destination No."; Rec."Destination No.")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass(Rec."Destination Type", Rec."Source Document", 0));
                    Editable = false;
                }
#pragma warning disable AA0100
                field("WMSMgt.GetDestinationName(""Destination Type"",""Destination No."")"; WMSMgt.GetDestinationEntityName(Rec."Destination Type", Rec."Destination No."))
#pragma warning restore AA0100
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass(Rec."Destination Type", Rec."Source Document", 1));
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the destination for the registered inventory movement.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass(Rec."Destination Type", Rec."Source Document", 2));
                }
                field("External Document No.2"; Rec."External Document No.2")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass(Rec."Destination Type", Rec."Source Document", 3));
                }
            }
            part(WhseActivityLines; "Reg. Invt. Movement Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = field("No.");
                SubPageView = sorting("No.", "Sorting Sequence No.");
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Movement")
            {
                Caption = '&Movement';
                Image = CreateMovement;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = const("Registered Invt. Movement"),
                                  Type = const(" "),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update();
    end;

    var
        WMSMgt: Codeunit "WMS Management";
}

