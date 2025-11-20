// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Navigate;
using System.Text;

page 6508 "Lot No. Information List"
{
    Caption = 'Lot No. Information List';
    CardPageID = "Lot No. Information Card";
    ApplicationArea = ItemTracking;
    Editable = false;
    PageType = List;
    AboutTitle = 'About Lot No. Information List';
    AboutText = 'View and update details for tracked item lot numbers, including descriptions, quality status, certificate numbers, comments, and blocking specific lots from transactions.';
    SourceTable = "Lot No. Information";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    Editable = true;
                    ToolTip = 'Specifies a description of the lot no. information record.';
                }
                field("Test Quality"; Rec."Test Quality")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quality of a given lot if you have inspected the items.';
                }
                field("Certificate Number"; Rec."Certificate Number")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number provided by the supplier to indicate that the batch or lot meets the specified requirements.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(CommentField; Rec.Comment)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that a comment has been recorded for the lot number.';
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory quantity of the specified lot number.';
                    Visible = false;
                }
                field("Expired Inventory"; Rec."Expired Inventory")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory of the lot number with an expiration date before the posting date on the associated document.';
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
            group("&Lot No.")
            {
                Caption = '&Lot No.';
                Image = Lot;
                action("Item &Tracking Entries")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'View serial, lot or package numbers that are assigned to items.';

                    trigger OnAction()
                    var
                        ItemTrackingSetup: Record "Item Tracking Setup";
                        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                    begin
                        ItemTrackingSetup."Lot No." := Rec."Lot No.";
                        ItemTrackingDocMgt.ShowItemTrackingForEntity(0, '', Rec."Item No.", Rec."Variant Code", '', ItemTrackingSetup);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "Item Tracking Comments";
                    RunPageLink = Type = const("Lot No."),
                                  "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Serial/Lot No." = field("Lot No.");
                    ToolTip = 'View or add comments for the record.';
                }
                separator(Action1102601003)
                {
                }
                action("&Item Tracing")
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Item Tracing';
                    Image = ItemTracing;
                    ToolTip = 'Trace where a serial, lot or package number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';

                    trigger OnAction()
                    var
                        ItemTracingBuffer: Record "Item Tracing Buffer";
                        ItemTracing: Page "Item Tracing";
                    begin
                        Clear(ItemTracing);
                        ItemTracingBuffer.SetRange("Item No.", Rec."Item No.");
                        ItemTracingBuffer.SetRange("Variant Code", Rec."Variant Code");
                        ItemTracingBuffer.SetRange("Lot No.", Rec."Lot No.");
                        ItemTracing.InitFilters(ItemTracingBuffer);
                        ItemTracing.FindRecords();
                        ItemTracing.RunModal();
                    end;
                }
                action(PrintLabel)
                {
                    AccessByPermission = TableData "Serial No. Information" = I;
                    ApplicationArea = ItemTracking;
                    Image = Print;
                    Caption = 'Print Label';
                    ToolTip = 'Print Label';

                    trigger OnAction()
                    var
                        LotNoInfo: Record "Lot No. Information";
                        LotNoLabel: Report "Lot No Label";
                    begin
                        LotNoInfo := Rec;
                        CurrPage.SetSelectionFilter(LotNoInfo);
                        LotNoLabel.SetTableView(LotNoInfo);
                        LotNoLabel.RunModal();
                    end;
                }
            }
        }
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = ItemTracking;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    ItemTrackingSetup: Record "Item Tracking Setup";
                    Navigate: Page Navigate;
                begin
                    ItemTrackingSetup."Lot No." := Rec."Lot No.";
                    Navigate.SetTracking(ItemTrackingSetup);
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref(PrintLabel_Promoted; PrintLabel)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Date Filter", '>%1&<=%2', 0D, WorkDate());
    end;

    procedure GetSelectionFilter(): Text
    var
        LotNoInfo: Record "Lot No. Information";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(LotNoInfo);
        exit(SelectionFilterManagement.GetSelectionFilterForLotNoInformation(LotNoInfo));
    end;
}

