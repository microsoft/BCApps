// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Setup;
using System.Text;

page 6516 "Package No. Information List"
{
    Caption = 'Package No. Information List';
    CardPageID = "Package No. Information Card";
    ApplicationArea = ItemTracking;
    Editable = false;
    PageType = List;
    SourceTable = "Package No. Information";
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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs declaration number.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(Control16; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment associated with this line.';
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity on inventory with this line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Package")
            {
                Caption = '&Package';
                action("Item &Tracking Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View or edit package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    var
                        ItemTrackingSetup: Record "Item Tracking Setup";
                        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                    begin
                        ItemTrackingSetup."Package No." := Rec."Package No.";
                        ItemTrackingDocMgt.ShowItemTrackingForEntity(0, '', Rec."Item No.", Rec."Variant Code", '', ItemTrackingSetup);
                    end;
                }
                action(Comment)
                {
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "Item Tracking Comments";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Serial/Lot No." = field("Package No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("&Item Tracing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Item Tracing';
                    Image = ItemTracing;
                    ToolTip = 'Trace where a package number assigned to the item was used, for example, to find which package a defective component came from or to find all the customers that have received items containing the defective component.';

                    trigger OnAction()
                    var
                        ItemTracingBuffer: Record "Item Tracing Buffer";
                        ItemTracing: Page "Item Tracing";
                    begin
                        Clear(ItemTracing);
                        ItemTracingBuffer.SetRange("Item No.", Rec."Item No.");
                        ItemTracingBuffer.SetRange("Variant Code", Rec."Variant Code");
                        ItemTracingBuffer.SetRange("Package No.", Rec."Package No.");
                        ItemTracing.InitFilters(ItemTracingBuffer);
                        ItemTracing.FindRecords();
                        ItemTracing.RunModal();
                    end;
                }
            }
        }
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find entries and documents that exist for the package number on the selected record. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    ItemTrackingSetup: Record "Item Tracking Setup";
                    Navigate: Page Navigate;
                begin
                    ItemTrackingSetup."Package No." := Rec."Package No.";
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
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
        SetCaption();
    end;

    var
        PageCaptionTxt: Label '%1 No. Information List', Comment = '%1 - package caption';

    procedure SetSelection(var PackageNoInfo: Record "Package No. Information")
    begin
        CurrPage.SetSelectionFilter(PackageNoInfo);
    end;

    procedure GetSelectionFilter(): Text
    var
        PackageNoInfo: Record "Package No. Information";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(PackageNoInfo);
        exit(SelectionFilterManagement.GetSelectionFilterForPackageNoInformation(PackageNoInfo));
    end;

    local procedure SetCaption()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Package Caption" <> '' then
            CurrPage.Caption := StrSubstNo(PageCaptionTxt, InventorySetup."Package Caption");
    end;
}

