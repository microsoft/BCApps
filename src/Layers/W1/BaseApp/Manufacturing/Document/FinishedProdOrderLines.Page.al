// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;

page 99000868 "Finished Prod. Order Lines"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Prod. Order Line";
    SourceTableView = where(Status = const(Finished));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Routing Version Code"; Rec."Routing Version Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Production BOM Version Code"; Rec."Production BOM Version Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Starting Time"; StartingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Time';
                    ToolTip = 'Specifies the entry''s starting time, which is retrieved from the production order routing.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Starting Date"; StartingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the entry''s starting date, which is retrieved from the production order routing.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Ending Time"; EndingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Time';
                    ToolTip = 'Specifies the entry''s ending time, which is retrieved from the production order routing.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Ending Date"; EndingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the entry''s ending date, which is retrieved from the production order routing.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Finished Quantity"; Rec."Finished Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
#if not CLEAN27
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ObsoleteReason = 'Discontinued functionality';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Ro&uting")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ro&uting';
                    Image = Route;
                    ToolTip = 'View or edit the operations list of the parent item on the line.';
                    ShortCutKey = 'Ctrl+Alt+R';

                    trigger OnAction()
                    begin
                        Rec.ShowRouting();
                    end;
                }
                action(Components)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Components';
                    Image = Components;
                    ToolTip = 'View or edit the production order components of the parent item on the line.';
                    ShortCutKey = 'Ctrl+Alt+C';

                    trigger OnAction()
                    begin
                        ShowComponents();
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
        Rec.GetStartingEndingDateAndTime(StartingTime, StartingDate, EndingTime, EndingDate);
    end;

    trigger OnInit()
    begin
        DateAndTimeFieldVisible := false;
    end;

    trigger OnOpenPage()
    begin
        DateAndTimeFieldVisible := false;
    end;

    var
        DescriptionIndent: Integer;
        StartingTime: Time;
        EndingTime: Time;
        StartingDate: Date;
        EndingDate: Date;
        DateAndTimeFieldVisible: Boolean;

    local procedure ShowComponents()
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange(Status, Rec.Status);
        ProdOrderComp.SetRange("Prod. Order No.", Rec."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", Rec."Line No.");

        PAGE.Run(PAGE::"Prod. Order Components", ProdOrderComp);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec."Planning Level Code";
    end;
}

