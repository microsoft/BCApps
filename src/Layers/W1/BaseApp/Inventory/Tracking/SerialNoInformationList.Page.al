// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Navigate;
using System.Text;

page 6509 "Serial No. Information List"
{
    Caption = 'Serial No. Information List';
    CardPageID = "Serial No. Information Card";
    ApplicationArea = ItemTracking;
    Editable = false;
    PageType = List;
    AboutTitle = 'About Serial No. Information List';
    AboutText = 'View and manage detailed information for item serial numbers, including descriptions, comments, blocked status, and inventory quantities to support tracking, quality assurance, and compliance needs.';
    SourceTable = "Serial No. Information";
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
                    ToolTip = 'Specifies the number that is copied from the Tracking Specification table, when a serial number information record is created.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a serial number information record is created.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    Editable = true;
                    ToolTip = 'Specifies a description of the serial no. information record.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(Control16; Rec.Comment)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that a comment has been recorded for the serial number.';
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory quantity of the specified serial number.';
                    Visible = false;
                }
                field("Expired Inventory"; Rec."Expired Inventory")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory of the serial number with an expiration date before the posting date on the associated document.';
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
            group("&Serial No.")
            {
                Caption = '&Serial No.';
                Image = SerialNo;
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
                        ItemTrackingSetup."Serial No." := Rec."Serial No.";
                        ItemTrackingDocMgt.ShowItemTrackingForEntity(0, '', Rec."Item No.", Rec."Variant Code", '', ItemTrackingSetup);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "Item Tracking Comments";
                    RunPageLink = Type = const("Serial No."),
                                  "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Serial/Lot No." = field("Serial No.");
                    ToolTip = 'View or add comments for the record.';
                }
                separator(Action1102601004)
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
                        ItemTracingBuffer.SetRange("Serial No.", Rec."Serial No.");
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
                        SNInfo: Record "Serial No. Information";
                        SNLabel: Report "SN Label";
                    begin
                        SNInfo := Rec;
                        CurrPage.SetSelectionFilter(SNInfo);
                        SNLabel.SetTableView(SNInfo);
                        SNLabel.RunModal();
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
                    ItemTrackingSetup."Serial No." := Rec."Serial No.";
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
        SerialNoInfo: Record "Serial No. Information";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(SerialNoInfo);
        exit(SelectionFilterManagement.GetSelectionFilterForSerialNoInformation(SerialNoInfo));
    end;
}

