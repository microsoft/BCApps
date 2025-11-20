// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Navigate;
using Microsoft.Warehouse.Tracking;

page 6504 "Serial No. Information Card"
{
    Caption = 'Serial No. Information Card';
    PageType = Card;
    PopulateAllFields = true;
    SourceTable = "Serial No. Information";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number that is copied from the Tracking Specification table, when a serial number information record is created.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a serial number information record is created.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the serial no. information record.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                field(Control19; Rec.Inventory)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory quantity of the specified serial number.';
                }
                field("Expired Inventory"; Rec."Expired Inventory")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory of the serial number with an expiration date before the posting date on the associated document.';
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
                    ShortCutKey = 'Ctrl+F7';
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
                separator(Action24)
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
            group(ButtonFunctions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = ButtonFunctionsVisible;
                action(CopyInfo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Copy &Info';
                    Ellipsis = true;
                    Image = CopySerialNo;
                    ToolTip = 'Copy the information record from the old serial number.';

                    trigger OnAction()
                    var
                        SelectedRecord: Record "Serial No. Information";
                        ShowRecords: Record "Serial No. Information";
                        FocusOnRecord: Record "Serial No. Information";
                        ItemTrackingMgt: Codeunit "Item Tracking Management";
                        SerialNoInfoList: Page "Serial No. Information List";
                    begin
                        ShowRecords.SetRange("Item No.", Rec."Item No.");
                        ShowRecords.SetRange("Variant Code", Rec."Variant Code");

                        FocusOnRecord.Copy(ShowRecords);
                        FocusOnRecord.SetRange("Serial No.", TrackingSpecification."Serial No.");

                        SerialNoInfoList.SetTableView(ShowRecords);

                        if FocusOnRecord.FindFirst() then
                            SerialNoInfoList.SetRecord(FocusOnRecord);
                        if SerialNoInfoList.RunModal() = ACTION::LookupOK then begin
                            SerialNoInfoList.GetRecord(SelectedRecord);
                            ItemTrackingMgt.CopySerialNoInformation(SelectedRecord, Rec."Serial No.");
                        end;
                    end;
                }
            }
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

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Date Filter", '>%1&<=%2', 0D, WorkDate());
        if ShowButtonFunctions then
            ButtonFunctionsVisible := true;
    end;

    var
        ShowButtonFunctions: Boolean;
        ButtonFunctionsVisible: Boolean;

    protected var
        TrackingSpecification: Record "Tracking Specification";

    procedure Init(CurrentTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification := CurrentTrackingSpecification;
        ShowButtonFunctions := true;
    end;

    procedure InitWhse(CurrentTrackingSpecification: Record "Whse. Item Tracking Line")
    begin
        TrackingSpecification."Serial No." := CurrentTrackingSpecification."Serial No.";
        ShowButtonFunctions := true;
    end;
}

