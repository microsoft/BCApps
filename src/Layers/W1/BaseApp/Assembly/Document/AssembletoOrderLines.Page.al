// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.Comment;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Globalization;

page 914 "Assemble-to-Order Lines"
{
    AutoSplitKey = true;
    Caption = 'Assemble-to-Order Lines';
    DataCaptionExpression = GetCaption();
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Assembly Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Avail. Warning"; Rec."Avail. Warning")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowAvailabilityWarningPage();
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Assembly;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                }
                field("Consumed Quantity"; Rec."Consumed Quantity")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Qty. Picked"; Rec."Qty. Picked")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Pick Qty."; Rec."Pick Qty.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
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
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Inventory Posting Group"; Rec."Inventory Posting Group")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Assembly;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Resource Usage Type"; Rec."Resource Usage Type")
                {
                    ApplicationArea = Assembly;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Appl.-from Item Entry"; Rec."Appl.-from Item Entry")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Reserve")
            {
                ApplicationArea = Reservation;
                Caption = '&Reserve';
                Ellipsis = true;
                Image = LineReserve;
                ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                trigger OnAction()
                begin
                    Rec.ShowReservation();
                end;
            }
            action("Select Item Substitution")
            {
                ApplicationArea = Suite;
                Caption = 'Select Item Substitution';
                Image = SelectItemSubstitution;
                ToolTip = 'Select another item that has been set up to be traded instead of the original item if it is unavailable.';

                trigger OnAction()
                begin
                    Rec.ShowItemSub();
                    CurrPage.Update();
                end;
            }
            action("Explode BOM")
            {
                ApplicationArea = Assembly;
                Caption = 'Explode BOM';
                Image = ExplodeBOM;
                ToolTip = 'Insert new lines for the components on the bill of materials, for example to sell the parent item as a kit. CAUTION: The line for the parent item will be deleted and represented by a description only. To undo, you must delete the component lines and add a line the parent item again.';

                trigger OnAction()
                begin
                    Rec.ExplodeAssemblyList();
                    CurrPage.Update();
                end;
            }
            action("Assembly BOM")
            {
                ApplicationArea = Assembly;
                Caption = 'Assembly BOM';
                Image = BulletList;
                ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';

                trigger OnAction()
                begin
                    Rec.ShowAssemblyList();
                end;
            }
            action("Create Inventor&y Movement")
            {
                ApplicationArea = Warehouse;
                Caption = 'Create Inventor&y Movement';
                Ellipsis = true;
                Image = CreatePutAway;
                ToolTip = 'Create an inventory movement to handle items on the document according to a basic warehouse configuration.';

                trigger OnAction()
                var
                    AssemblyHeader: Record "Assembly Header";
                    ATOMovementsCreated: Integer;
                    TotalATOMovementsToBeCreated: Integer;
                begin
                    AssemblyHeader.Get(Rec."Document Type", Rec."Document No.");
                    AssemblyHeader.CreateInvtMovement(false, false, false, ATOMovementsCreated, TotalATOMovementsToBeCreated);
                end;
            }
        }
        area(navigation)
        {
            action("Show Document")
            {
                ApplicationArea = Assembly;
                Caption = 'Show Document';
                Image = View;
                ToolTip = 'Open the document that the selected line exists on.';

                trigger OnAction()
                var
                    ATOLink: Record "Assemble-to-Order Link";
                    IsHandled: Boolean;
                begin
                    IsHandled := false;
                    OnBeforeShowDocument(Rec, IsHandled);
                    if IsHandled then
                        exit;

                    ATOLink.Get(Rec."Document Type", Rec."Document No.");
                    ATOLink.ShowAsmDocument();
                end;
            }
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
            group("Item Availability by")
            {
                Caption = 'Item Availability by';
                Image = ItemAvailability;
                action("Event")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Event';
                    Image = "Event";
                    ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    trigger OnAction()
                    begin
                        AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmLine(Rec, "Item Availability Type"::"Event");
                    end;
                }
                action(Period)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Period';
                    Image = Period;
                    ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                    trigger OnAction()
                    begin
                        AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmLine(Rec, "Item Availability Type"::Period);
                    end;
                }
                action(Variant)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant';
                    Image = ItemVariant;
                    ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                    trigger OnAction()
                    begin
                        AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmLine(Rec, "Item Availability Type"::Variant);
                    end;
                }
                action(Location)
                {
                    AccessByPermission = TableData Location = R;
                    ApplicationArea = Location;
                    Caption = 'Location';
                    Image = Warehouse;
                    ToolTip = 'View the actual and projected quantity of the item per location.';

                    trigger OnAction()
                    begin
                        AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmLine(Rec, "Item Availability Type"::Location);
                    end;
                }
                action(Lot)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot';
                    Image = LotInfo;
                    RunObject = Page "Item Availability by Lot No.";
                    RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                    ToolTip = 'View the current and projected quantity of the item in each lot.';
                }
                action("BOM Level")
                {
                    ApplicationArea = Assembly;
                    Caption = 'BOM Level';
                    Image = BOMLevel;
                    ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                    trigger OnAction()
                    begin
                        AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmLine(Rec, "Item Availability Type"::BOM);
                    end;
                }
            }
            action(Comments)
            {
                ApplicationArea = Comments;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Assembly Comment Sheet";
                RunPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Document Line No." = field("Line No.");
                ToolTip = 'View or add comments for the record.';
            }
            action(ShowWarning)
            {
                ApplicationArea = Assembly;
                Caption = 'Show Warning';
                Image = ShowWarning;
                ToolTip = 'View details about availability issues.';

                trigger OnAction()
                begin
                    Rec.ShowAvailabilityWarning();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref("&Reserve_Promoted"; "&Reserve")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref("Assembly BOM_Promoted"; "Assembly BOM")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record "Item";
    begin
        Rec.UpdateAvailWarning();
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            Commit();
            if not AssemblyLineReserve.DeleteLineConfirm(Rec) then
                exit(false);
            AssemblyLineReserve.DeleteLine(Rec);
        end;
    end;

    var
        AssemblyAvailabilityMgt: Codeunit "Assembly Availability Mgt.";
        VariantCodeMandatory: Boolean;

    local procedure GetCaption(): Text[250]
    var
        ObjTransln: Record "Object Translation";
        AsmHeader: Record "Assembly Header";
        SourceTableName: Text[250];
        SourceFilter: Text[200];
        Description: Text[100];
    begin
        Description := '';

        if AsmHeader.Get(Rec."Document Type", Rec."Document No.") then begin
            SourceTableName := ObjTransln.TranslateObject(ObjTransln."Object Type"::Table, 27);
            SourceFilter := AsmHeader."Item No.";
            Description := AsmHeader.Description;
        end;
        exit(StrSubstNo('%1 %2 %3', SourceTableName, SourceFilter, Description));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocument(var AssemblyLine: Record "Assembly Line"; var IsHandled: boolean)
    begin
    end;
}

