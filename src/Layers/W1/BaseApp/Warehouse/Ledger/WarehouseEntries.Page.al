// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Ledger;

using Microsoft.Inventory.Tracking;
using System.Security.User;

page 7318 "Warehouse Entries"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Entries';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    AboutTitle = 'About Warehouse Entries';
    AboutText = 'Track and review detailed records of item movements within the warehouse, including adjustments, transfers, and transactions linked to specific documents, locations, bins, and serial or lot numbers.';
    SourceTable = "Warehouse Entry";
    SourceTableView = sorting("Entry No.")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Warehouse;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the entry, in the base unit of measure.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;

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

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Package No.", Rec."Package No.");
                    end;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source Subtype"; Rec."Source Subtype")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source Subline No."; Rec."Source Subline No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Cubage; Rec.Cubage)
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Whse. Document Type"; Rec."Whse. Document Type")
                {
                    ApplicationArea = Warehouse;
                }
                field("Whse. Document No."; Rec."Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Registering Date"; Rec."Registering Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Warehouse;
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
        area(Navigation)
        {
            group("&Item Tracking")
            {
                Caption = '&Item Tracking';
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
                        GetTrackingSpecification(TrackingSpecification);
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
                        GetTrackingSpecification(TrackingSpecification);
                        LotNoInformation.ShowCard(Rec."Lot No.", TrackingSpecification);
                    end;
                }
                action("Package No. Information Card")
                {
                    Caption = 'Package No. Information Card';
                    Image = SNInfo;
                    ToolTip = 'View or edit detailed information about the package number.';

                    trigger OnAction()
                    var
                        PackageNoInformation: Record "Package No. Information";
                        TrackingSpecification: Record "Tracking Specification";
                    begin
                        Rec.TestField("Package No.");
                        GetTrackingSpecification(TrackingSpecification);
                        PackageNoInformation.ShowCard(Rec."Package No.", TrackingSpecification);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
    end;

    local procedure GetTrackingSpecification(var TrackingSpecification: Record "Tracking Specification")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.CopyTrackingFromWhseEntry(Rec);
        TrackingSpecification.SetItemData(Rec."Item No.", '', Rec."Location Code", Rec."Variant Code", '', 0);
        TrackingSpecification.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);
    end;
}

