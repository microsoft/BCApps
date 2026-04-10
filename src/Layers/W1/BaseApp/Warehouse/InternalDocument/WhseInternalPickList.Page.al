// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;

page 7359 "Whse. Internal Pick List"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Internal Picks';
    CardPageID = "Whse. Internal Pick";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Internal Pick Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                }
                field("To Zone Code"; Rec."To Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Pick")
            {
                Caption = '&Pick';
                Image = CreateInventoryPickup;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = const("Internal Pick"),
                                  Type = const(" "),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Whse. Document Type" = const("Internal Pick"),
                                  "Whse. Document No." = field("No.");
                    RunPageView = sorting("Whse. Document No.", "Whse. Document Type", "Activity Type")
                                  where("Activity Type" = const(Pick));
                    ToolTip = 'View the related picks.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re&lease")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ReleaseWhseInternalPick: Codeunit "Whse. Internal Pick Release";
                    begin
                        CurrPage.Update(true);
                        if Rec.Status = Rec.Status::Open then
                            ReleaseWhseInternalPick.Release(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseWhseInternalPick: Codeunit "Whse. Internal Pick Release";
                    begin
                        ReleaseWhseInternalPick.Reopen(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Re&lease_Promoted"; "Re&lease")
                {
                }
                actionref("Re&open_Promoted"; "Re&open")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Pick Lines_Promoted"; "Pick Lines")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(CopyStr(UserId, 1, 50)));
        Rec.FilterGroup(0);
    end;
}

