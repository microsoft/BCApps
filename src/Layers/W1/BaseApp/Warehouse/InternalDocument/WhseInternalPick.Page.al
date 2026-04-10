// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Structure;

page 7357 "Whse. Internal Pick"
{
    Caption = 'Whse. Internal Pick';
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Whse. Internal Pick Header";

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

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        Rec.LookupLocation(Rec);
                        CurrPage.Update(true);
                    end;
                }
                field("To Zone Code"; Rec."To Zone Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = Warehouse;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                }
                field("Assignment Time"; Rec."Assignment Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate();
                    end;
                }
            }
            part(WhseInternalPickLines; "Whse. Internal Pick Line")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = field("No.");
                SubPageView = sorting("No.", "Sorting Sequence No.");
            }
        }
        area(factboxes)
        {
            part(Control6; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                Provider = WhseInternalPickLines;
                SubPageLink = "Item No." = field("Item No."),
                              "Variant Code" = field("Variant Code"),
                              "Location Code" = field("Location Code");
                Visible = false;
            }
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
                    Enabled = Rec.Status <> Rec.Status::Released;
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
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseWhseInternalPick: Codeunit "Whse. Internal Pick Release";
                    begin
                        ReleaseWhseInternalPick.Reopen(Rec);
                    end;
                }
                action(CreatePick)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Pick';
                    Ellipsis = true;
                    Image = CreateInventoryPickup;
                    ToolTip = 'Create a warehouse pick document.';

                    trigger OnAction()
                    begin
                        CurrPage.Update(true);
                        CurrPage.WhseInternalPickLines.PAGE.PickCreate();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreatePick_Promoted; CreatePick)
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref("Re&lease_Promoted"; "Re&lease")
                    {
                    }
                    actionref("Re&open_Promoted"; "Re&open")
                    {
                    }
                }
            }
            group(Category_Pick)
            {
                Caption = 'Pick';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Pick Lines_Promoted"; "Pick Lines")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetWhseLocationFilter();
    end;

    local procedure SortingMethodOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

