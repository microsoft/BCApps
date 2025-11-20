// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

page 7354 "Whse. Internal Put-away"
{
    Caption = 'Whse. Internal Put-away';
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Whse. Internal Put-away Header";

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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location where the internal put-away is being performed.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        Rec.LookupLocation(Rec);
                        CurrPage.Update(true);
                    end;
                }
                field("From Zone Code"; Rec."From Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone from which the items to be put away should be taken.';
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin from which the items to be put away should be taken.';
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the internal put-away.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the internal put-away.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                }
                field("Assignment Time"; Rec."Assignment Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the time when the user was assigned the activity.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the warehouse internal put-always are sorted.';

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate();
                    end;
                }
            }
            part(WhseInternalPutAwayLines; "Internal Put-away Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = field("No.");
                SubPageView = sorting("No.", "Sorting Sequence No.");
            }
        }
        area(factboxes)
        {
            part(Control5; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                Provider = WhseInternalPutAwayLines;
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
            group("&Put-away")
            {
                Caption = '&Put-away';
                Image = CreatePutAway;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = const("Internal Put-away"),
                                  Type = const(" "),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Put-away Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away Lines';
                    Image = PutawayLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Whse. Document Type" = const("Internal Put-away"),
                                  "Whse. Document No." = field("No.");
                    RunPageView = sorting("Whse. Document No.", "Whse. Document Type", "Activity Type")
                                  where("Activity Type" = const("Put-away"));
                    ToolTip = ' View the related put-aways.';
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
                        ReleaseWhseInternalPutAway: Codeunit "Whse. Int. Put-away Release";
                    begin
                        if Rec.Status = Rec.Status::Open then
                            ReleaseWhseInternalPutAway.Release(Rec);
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
                        ReleaseWhseInternalPutaway: Codeunit "Whse. Int. Put-away Release";
                    begin
                        ReleaseWhseInternalPutaway.Reopen(Rec);
                    end;
                }
                action("Get Bin Content")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Get Bin Content';
                    Ellipsis = true;
                    Image = GetBinContent;
                    ToolTip = 'Use a function to create transfer lines with items to put away or pick based on the actual content in the specified bin.';

                    trigger OnAction()
                    var
                        DummyRec: Record "Whse. Worksheet Line";
                        BinContent: Record "Bin Content";
                        GetBinContent: Report "Whse. Get Bin Content";
                    begin
                        BinContent.SetRange("Location Code", Rec."Location Code");
                        GetBinContent.SetTableView(BinContent);
                        GetBinContent.SetParameters(DummyRec, Rec, Enum::"Warehouse Destination Type 2"::"WhseInternalPutawayHeader");
                        GetBinContent.Run();
                    end;
                }
                action(CreatePutAway)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Put-away';
                    Ellipsis = true;
                    Image = CreatePutAway;
                    ToolTip = 'Create a warehouse put-away document.';

                    trigger OnAction()
                    begin
                        CurrPage.Update(true);
                        CurrPage.WhseInternalPutAwayLines.PAGE.PutAwayCreate();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreatePutAway_Promoted; CreatePutAway)
                {
                }
                actionref("Get Bin Content_Promoted"; "Get Bin Content")
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
            group("Category_Put-away")
            {
                Caption = 'Put-away';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Put-away Lines_Promoted"; "Put-away Lines")
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

