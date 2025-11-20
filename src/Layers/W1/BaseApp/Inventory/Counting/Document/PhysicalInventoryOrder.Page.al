// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Counting.Recording;

page 5875 "Physical Inventory Order"
{
    Caption = 'Physical Inventory Order';
    PageType = Document;
    SourceTable = "Phys. Invt. Order Header";
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number for the physical inventory order.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a short description of the physical inventory order.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location where items on this line should be counted.';
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person who is responsible for performing this physical inventory order.';
                }
                field("No. Finished Recordings"; Rec."No. Finished Recordings")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of entered physical inventory recording documents that have the status set to Finished.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the order date for the physical inventory order.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the posting date of the physical inventory order.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the physical inventory order is open or finished.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(OrderLines; "Physical Inventory Order Subf.")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Document No." = field("No.");
                SubPageView = sorting("Document No.", "Line No.");
            }
        }
        area(factboxes)
        {
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
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(Statistics)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Phys. Invt. Order Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information for the physical inventory order.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Phys. Inventory Comment Sheet";
                    RunPageLink = "Document Type" = const(Order),
                                  "Order No." = field("No."),
                                  "Recording No." = const(0);
                    ToolTip = 'View or edit comments for the physical inventory order.';
                }
                action("&Recordings")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Recordings';
                    Image = Document;
                    RunObject = Page "Phys. Inventory Recording List";
                    RunPageLink = "Order No." = field("No.");
                    RunPageView = sorting("Order No.", "Recording No.");
                    ToolTip = 'Open any related physical inventory recordings, the documents that are used to record the actual counting.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as a project or department, that are assigned to the physical inventory order for financial analysis.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                action("Show &Duplicate Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show &Duplicate Lines';
                    Image = CheckDuplicates;
                    RunObject = Codeunit "Phys. Invt.-Show Duplicates";
                    ToolTip = 'Show lines that have the same value in the Item No., Variant Code, Location Code, and Bin Code fields.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CalculateLines)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Calculate Lines';
                    Ellipsis = true;
                    Image = CalculateLines;
                    ToolTip = 'Add physical inventory lines for items that are currently recorded in inventory.';

                    trigger OnAction()
                    var
                        CalcPhysInvtOrderLines: Report "Calc. Phys. Invt. Order Lines";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeCalculateLines(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        CalcPhysInvtOrderLines.SetPhysInvtOrderHeader(Rec);
                        CalcPhysInvtOrderLines.RunModal();
                        Clear(CalcPhysInvtOrderLines);
                    end;
                }
                action(CalculateCountingPeriod)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Counting &Period';
                    Ellipsis = true;
                    Image = CalculateCalendar;
                    ToolTip = 'Add physical inventory order lines for items and SKUs that are set up with counting periods. See the Phys Invt Counting Period Code field on the item card or SKU card.';

                    trigger OnAction()
                    var
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        PhysInvtCountMgt.InitFromPhysInvtOrder(Rec);
                        PhysInvtCountMgt.Run();
                        Clear(PhysInvtCountMgt);
                    end;
                }
                action(CalculateLinesBins)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Lines (&Bins)';
                    Ellipsis = true;
                    Image = CalculateBinReplenishment;
                    ToolTip = 'Add physical inventory lines for items that are currently recorded in bins in the warehouse.';

                    trigger OnAction()
                    var
                        CalcPhysInvtOrderBins: Report "Calc. Phys. Invt. Order (Bins)";
                    begin
                        CalcPhysInvtOrderBins.SetPhysInvtOrderHeader(Rec);
                        CalcPhysInvtOrderBins.RunModal();
                        Clear(CalcPhysInvtOrderBins);
                    end;
                }
                action(CopyDocument)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Copy &Document';
                    Ellipsis = true;
                    Image = CopyDocument;
                    ToolTip = 'Copy Document.';

                    trigger OnAction()
                    var
                        CopyPhysInvtOrder: Report "Copy Phys. Invt. Order";
                    begin
                        CopyPhysInvtOrder.SetPhysInvtOrderHeader(Rec);
                        CopyPhysInvtOrder.RunModal();
                        Clear(CopyPhysInvtOrder);
                    end;
                }
                action("Calc. &Qty. Expected")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calc. &Qty. Expected';
                    Ellipsis = true;
                    Image = AllLines;
                    RunObject = Codeunit "Phys. Invt.-Calc. Qty. All";
                    ToolTip = 'Update the value in the Qty. Expected (Base) field on the lines with any inventory changes made since you created the order. When you have used this function, the Qty. Exp. Calculated check box is selected.';
                }
                action(MakeNewRecording)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Make New &Recording';
                    Ellipsis = true;
                    Image = NewDocument;
                    ToolTip = 'Create a physical inventory recording document for the lines on the order. On the request page that appears, you can select to only create recording lines for items that are not already on other recordings for the order.';

                    trigger OnAction()
                    begin
                        PhysInvtOrderHeader := Rec;
                        PhysInvtOrderHeader.SetRecFilter();
                        REPORT.RunModal(REPORT::"Make Phys. Invt. Recording", true, false, PhysInvtOrderHeader);
                    end;
                }
                action("Fi&nish")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Fi&nish';
                    Ellipsis = true;
                    Image = Approve;
                    RunObject = Codeunit "Phys. Invt. Order-Finish (Y/N)";
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Indicate that the counting is completed. This is only possible if all related recordings are set to Finished.';
                }
                action("Reo&pen")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reo&pen';
                    Ellipsis = true;
                    Image = ReOpen;
                    RunObject = Codeunit "Phys. Invt. Order-Reopen (Y/N)";
                    ToolTip = 'Change the status of the physical inventory order from Finished to Open.';
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Preview the inventory counting that will be recorded when you choose the Post action.';

                    trigger OnAction()
                    begin
                        DocPrint.PrintInvtOrderTest(Rec, true);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Update the involved item ledger entries with the counted inventory quantities.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post (Y/N)", Rec);
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview();
                        CurrPage.Update(false);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Update the involved item ledger entries with the counted inventory and print the Phys. Inventory Order Difference List report, which shows counted quantities compared to expected as negative or positive differences.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post + Print", Rec);
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the Phys. Inventory Order Difference List report, which shows counted quantities compared to expected as negative or positive differences.';

                trigger OnAction()
                begin
                    DocPrint.PrintInvtOrder(Rec, true);
                end;
            }
        }
#if not CLEAN25
#pragma warning disable AL0545
        area(creation)
        {
            action("New Phys. Inventory Recording")
            {
                ApplicationArea = Warehouse;
                Caption = 'New Phys. Inventory Recording';
                Image = PhysicalInventory;
                RunObject = Page "Phys. Inventory Recording";
                ToolTip = 'Create new physical inventory recording.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Action removed as creation area is not supported and not rendered in document page.';
                ObsoleteTag = '25.0';
            }
        }
#pragma warning restore AL0545
#endif
        area(reporting)
        {
            action("Physical Inventory Recording")
            {
                ApplicationArea = Warehouse;
                Caption = 'Physical Inventory Recording';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                ToolTip = 'Print the first physical inventory recording that exists for the order. The printed document has an empty column in which to write the counted quantities.';

                trigger OnAction()
                var
                    PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
                begin
                    PhysInvtRecordHeader.SetRange("Order No.", Rec."No.");
                    PhysInvtRecordHeader.FindFirst();
                    DocPrint.PrintInvtRecording(PhysInvtRecordHeader, true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category6)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                }
                actionref(MakeNewRecording_Promoted; MakeNewRecording)
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
                actionref("Fi&nish_Promoted"; "Fi&nish")
                {
                }
                actionref("Reo&pen_Promoted"; "Reo&pen")
                {
                }
            }
            group(Category_Prepare)
            {
                Caption = 'Prepare';

                actionref(CopyDocument_Promoted; CopyDocument)
                {
                }
                group(Category_Calculate)
                {
                    Caption = 'Calculate';

                    actionref(CalculateLines_Promoted; CalculateLines)
                    {
                    }
                    actionref(CalculateCountingPeriod_Promoted; CalculateCountingPeriod)
                    {
                    }
                    actionref(CalculateLinesBins_Promoted; CalculateLinesBins)
                    {
                    }
                }
            }
            group(Category_Order)
            {
                Caption = 'Order';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
        }
    }

    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        DocPrint: Codeunit "Document-Print";

    local procedure ShowPreview()
    var
        PhysInvtOrderPostYN: Codeunit "Phys. Invt. Order-Post (Y/N)";
    begin
        PhysInvtOrderPostYN.Preview(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateLines(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean)
    begin
    end;
}

