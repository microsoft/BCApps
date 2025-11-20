// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Setup;
using Microsoft.Warehouse.Tracking;

page 6526 "Package No. Information Card"
{
    Caption = 'Package No. Information Card';
    PageType = Card;
    PopulateAllFields = true;
    SourceTable = "Package No. Information";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs declaration number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "Item Tracking Comments";
                    RunPageLink = Type = const("Package No."),
                                  "Item No." = field("Item No."),
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
            group(ButtonFunctions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = ButtonFunctionsVisible;
                action("Copy &Info")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy &Info';
                    Ellipsis = true;
                    Image = CopySerialNo;
                    ToolTip = 'Copy the information record from the old package number.';

                    trigger OnAction()
                    var
                        SelectedPackageNoInfo: Record "Package No. Information";
                        ShowPackageNoInfo: Record "Package No. Information";
                        FocusOnPackageNoInfo: Record "Package No. Information";
                        PackageInfoMgt: Codeunit "Package Info. Management";
                        PackageNoInfoList: Page "Package No. Information List";
                    begin
                        ShowPackageNoInfo.SetRange("Item No.", Rec."Item No.");
                        ShowPackageNoInfo.SetRange("Variant Code", Rec."Variant Code");

                        FocusOnPackageNoInfo.Copy(ShowPackageNoInfo);
                        FocusOnPackageNoInfo.SetRange("Package No.", TrackingSpecification."Package No.");

                        PackageNoInfoList.SetTableView(ShowPackageNoInfo);

                        if FocusOnPackageNoInfo.FindFirst() then
                            PackageNoInfoList.SetRecord(FocusOnPackageNoInfo);
                        if PackageNoInfoList.RunModal() = ACTION::LookupOK then begin
                            PackageNoInfoList.GetRecord(SelectedPackageNoInfo);
                            PackageInfoMgt.CopyPackageNoInformation(SelectedPackageNoInfo, Rec."Package No.");
                        end;
                    end;
                }
            }
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

    trigger OnOpenPage()
    begin
        SetCaption();
        Rec.SetFilter("Date Filter", '>%1&<=%2', 0D, WorkDate());
        if ShowButtonFunctions then
            ButtonFunctionsVisible := true;
    end;

    var
        ShowButtonFunctions: Boolean;
        ButtonFunctionsVisible: Boolean;
        PageCaptionTxt: Label '%1 No. Information Card', Comment = '%1 - package caption';

    protected var
        TrackingSpecification: Record "Tracking Specification";

    procedure Init(CurrentTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification := CurrentTrackingSpecification;
        ShowButtonFunctions := true;
    end;

    procedure InitWhse(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        TrackingSpecification."Package No." := WhseItemTrackingLine."Package No.";
        ShowButtonFunctions := true;
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

