// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Ledger;

page 6501 "Item Tracking Entries"
{
    Caption = 'Item Tracking Entries';
    Editable = false;
    PageType = List;
    SaveValues = true;
    SourceTable = "Item Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies whether the item in the item ledge entry is positive.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of the item in the entry.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the entry.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Serial No.", Rec."Serial No.");
                    end;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Lot No.", Rec."Lot No.");
                    end;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a package number if the posted item carries such a number.';

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Package No.", Rec."Package No.");
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of units of the item in the item entry.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the source type that applies to the source number, shown in the Source No. field.';
                    Visible = false;
                }
                field("Warranty Date"; Rec."Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the last day of warranty for the item on the line.';
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the last date that the item on the line can be used.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item Tracking Entry")
            {
                Caption = '&Item Tracking Entry';
                Image = Entry;
                action("Serial No. Information Card")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    ToolTip = 'View or edit detailed information about the serial number.';

                    trigger OnAction()
                    var
                        SerialNoInformation: Record "Serial No. Information";
                        TrackingSpecification: Record "Tracking Specification";
                    begin
                        Rec.TestField("Serial No.");
                        TrackingSpecification.SetItemData(Rec."Item No.", '', Rec."Location Code", Rec."Variant Code", '', 0);
                        TrackingSpecification.CopyTrackingFromItemLedgEntry(Rec);
                        SerialNoInformation.ShowCard(Rec."Serial No.", TrackingSpecification);
                    end;
                }
                action("Lot No. Information Card")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    ToolTip = 'View or edit detailed information about the lot number.';

                    trigger OnAction()
                    var
                        LotNoInformation: Record "Lot No. Information";
                        TrackingSpecification: Record "Tracking Specification";
                    begin
                        Rec.TestField("Lot No.");
                        TrackingSpecification.SetItemData(Rec."Item No.", '', Rec."Location Code", Rec."Variant Code", '', 0);
                        TrackingSpecification.CopyTrackingFromItemLedgEntry(Rec);
                        LotNoInformation.ShowCard(Rec."Lot No.", TrackingSpecification);
                    end;
                }
                action("Package No. Information Card")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Package No. Information Card';
                    Image = SNInfo;
                    ToolTip = 'View or edit detailed information about the package number.';

                    trigger OnAction()
                    var
                        PackageNoInformation: Record "Package No. Information";
                        TrackingSpecification: Record "Tracking Specification";
                    begin
                        Rec.TestField("Package No.");
                        TrackingSpecification.SetItemData(Rec."Item No.", '', Rec."Location Code", Rec."Variant Code", '', 0);
                        TrackingSpecification.CopyTrackingFromItemLedgEntry(Rec);
                        PackageNoInformation.ShowCard(Rec."Package No.", TrackingSpecification);
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = ItemTracking;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 3.';

                    actionref("Lot No. Information Card_Promoted"; "Lot No. Information Card")
                    {
                    }
                    actionref("Serial No. Information Card_Promoted"; "Serial No. Information Card")
                    {
                    }
                    actionref("Package No. Information Card_Promoted"; "Package No. Information Card")
                    {
                    }
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    var
        Navigate: Page Navigate;
}

