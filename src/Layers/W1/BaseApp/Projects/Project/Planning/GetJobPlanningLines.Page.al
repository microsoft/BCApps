// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Sales.Document;

page 1043 "Get Job Planning Lines"
{
    Editable = false;
    PageType = List;
    Caption = 'Get Project Planning Lines';
    SourceTable = "Job Planning Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Jobs;
                }
                field("Planning Date"; Rec."Planning Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Planned Delivery Date"; Rec."Planned Delivery Date")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of project planning line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of item units, resource hours, general ledger account payments, or cost that have been shipped to the customer.';
                }
                field("Qty. to Assemble"; Rec."Qty. to Assemble")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Visible = false;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Visible = false;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the quantity expressed in the base units of measure.';
                    Visible = false;
                }
                field("Remaining Qty."; Rec."Remaining Qty.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Direct Unit Cost (LCY)"; Rec."Direct Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in the local currency, of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Remaining Total Cost"; Rec."Remaining Total Cost")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Total Cost (LCY)"; Rec."Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost for the planning line. The amount is in the local currency.';
                    Visible = false;
                }
                field("Remaining Total Cost (LCY)"; Rec."Remaining Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the remaining total cost (LCY) for the planning line. The amount is in the local currency.';
                    Visible = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Remaining Line Amount"; Rec."Remaining Line Amount")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Line Amount (LCY)"; Rec."Line Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount in the local currency that will be posted to the project ledger.';
                    Visible = false;
                }
                field("Remaining Line Amount (LCY)"; Rec."Remaining Line Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount in the local currency that will be posted to the project ledger.';
                    Visible = false;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Total Price"; Rec."Total Price")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Total Price (LCY)"; Rec."Total Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total price on the planning line. The total price is in the local currency.';
                    Visible = false;
                }
                field("Qty. Posted"; Rec."Qty. Posted")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Posted Total Cost"; Rec."Posted Total Cost")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Posted Total Cost (LCY)"; Rec."Posted Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost (LCY) that has been posted to the project ledger, if the Usage Link check box has been selected.';
                    Visible = false;
                }
                field("Posted Line Amount"; Rec."Posted Line Amount")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Posted Line Amount (LCY)"; Rec."Posted Line Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount in the local currency that has been posted to the project ledger. This field is only filled in if the Apply Usage Link check box selected on the project card.';
                    Visible = false;
                }
                field("Qty. Transferred to Invoice"; Rec."Qty. Transferred to Invoice")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Qty. to Transfer to Invoice"; Rec."Qty. to Transfer to Invoice")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Qty. Invoiced"; Rec."Qty. Invoiced")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Qty. to Invoice"; Rec."Qty. to Invoice")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Invoiced Amount (LCY)"; Rec."Invoiced Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in local currency, the sales amount that was invoiced for this planning line.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownJobInvoices();
                    end;
                }
                field("Invoiced Cost Amount (LCY)"; Rec."Invoiced Cost Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies, in the local currency, the cost amount that was invoiced for this planning line.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Job Contract Entry No."; Rec."Job Contract Entry No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(ControlLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(ControlNotes; Notes)
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
            group("Job Planning &Line")
            {
                Caption = 'Project Planning &Line';
                Image = Line;

                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the project planning line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ItemTrackingLines_Promoted; ItemTrackingLines)
                {
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupCancel then
            if not Confirm(ExitQst, false) then
                Error('');
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            CreateLines();
    end;

    var
        SalesHeader: Record "Sales Header";
        JobGetPlanningLines: Codeunit "Job-Process Plan. Lines";
        ExitQst: Label 'Are you sure that you want to exit?';

    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
    end;

    procedure SetRecords(var TempJobPlanningLine: Record "Job Planning Line" temporary)
    begin
        Rec.Copy(TempJobPlanningLine, true);
    end;

    procedure CreateLines()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Copy(Rec);
        CurrPage.SetSelectionFilter(JobPlanningLine);
        JobGetPlanningLines.SetSalesHeader(SalesHeader);
        JobGetPlanningLines.CreateInvLines(JobPlanningLine);
    end;
}