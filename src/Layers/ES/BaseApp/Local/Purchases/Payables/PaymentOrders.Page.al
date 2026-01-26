// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.Payment;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Navigate;
using System.Telemetry;

page 7000050 "Payment Orders"
{
    Caption = 'Payment Orders';
    DataCaptionExpression = Rec.Caption();
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Payment Order";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number for this payment order.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number or code of the bank where the payment order is delivered.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where the payment order is delivered.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the general posting date for the payment order.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code associated with this payment order.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum total of the documents included in this payment order.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of all of the documents included in this payment order.';
                }
                field("Export Electronic Payment"; Rec."Export Electronic Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this payment order will be used for electronic payments.';
                }
            }
            part(Docs; "Docs. in PO Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Type = const(Payable),
                              "Collection Agent" = const(Bank),
                              "Bill Gr./Pmt. Order No." = field("No.");
                SubPageView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Accepted, "Due Date", Place);
            }
            group(Auditing)
            {
                Caption = 'Auditing';
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies why the entry is created. When reason codes are assigned to journal line or sales and purchase documents, all entries with a reason code will be marked during posting.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of printed copies of this payment order.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901420307; "Pmt Orders Analysis Fact Box")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part("Payment File Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment File Errors';
                Provider = Docs;
                SubPageLink = "Document No." = field("Bill Gr./Pmt. Order No."),
                              "Journal Line No." = field("Entry No.");
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
            group("Pmt. O&rd.")
            {
                Caption = 'Pmt. O&rd.';
                action(Comments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "BG/PO Comment Sheet";
                    RunPageLink = "BG/PO No." = field("No."),
                                  Type = const(Payable);
                    ToolTip = 'View or create a comment.';
                }
                separator(Action18)
                {
                }
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Enabled = true;
                    Image = "Report";
                    RunObject = Page "Payment Orders Analysis";
                    RunPageLink = "No." = field("No."),
                                  "Due Date Filter" = field("Due Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Category Filter" = field("Category Filter");
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';
                }
                separator(Action33)
                {
                }
                action(Listing)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Listing';
                    Ellipsis = true;
                    Enabled = true;
                    Image = List;
                    ToolTip = 'View detailed information about the posted bill group or payment order.';

                    trigger OnAction()
                    begin
                        if Rec.Find() then begin
                            PmtOrd.Copy(Rec);
                            PmtOrd.SetRecFilter();
                        end;
                        PmtOrd.PrintRecords(true);
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to File';
                    Image = ExportFile;
                    ToolTip = 'Export a file with the payment information on the lines.';

                    trigger OnAction()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        ESElecPaymentsTok: Label 'ES Electronic Payments', Locked = true;
                    begin
                        FeatureTelemetry.LogUptake('1000HY0', ESElecPaymentsTok, Enum::"Feature Uptake Status"::"Used");
                        Rec.ExportToFile();
                        FeatureTelemetry.LogUsage('1000HY1', ESElecPaymentsTok, 'ES Electronic Payments Exported');
                    end;
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Enabled = true;
                    Image = TestReport;
                    ToolTip = 'Preview the resulting entries to see the consequences before you perform the actual posting.';

                    trigger OnAction()
                    begin
                        if not Rec.Find() then
                            exit;
                        PmtOrd.Reset();
                        PmtOrd := Rec;
                        PmtOrd.SetRecFilter();
                        REPORT.Run(REPORT::"Payment Order - Test", true, false, PmtOrd);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the documents to indicate that they are ready to submit to the bank for payment or collection. ';

                    trigger OnAction()
                    begin
                        if Rec.Find() then
                            PostBGPO.PayablePostOnly(Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Enabled = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post and then print the documents to indicate that they are ready to submit to the bank for payment or collection.';

                    trigger OnAction()
                    begin
                        if Rec.Find() then
                            PostBGPO.PayablePostAndPrint(Rec);
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Enabled = true;
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."No.");
                    Navigate.Run();
                end;
            }
            action("Page Payment Orders Maturity Process")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Orders Maturity';
                Image = DocumentsMaturity;
                RunObject = Page "Payment Orders Maturity";
                RunPageLink = "No." = field("No."),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                              "Category Filter" = field("Category Filter");
                ToolTip = 'View the document lines that have matured. Maturity information can be viewed by period start date.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Post_Promoted; Post)
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
                actionref(Export_Promoted; Export)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Page Payment Orders Maturity Process_Promoted"; "Page Payment Orders Maturity Process")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(Listing_Promoted; Listing)
                {
                }
            }
        }
    }

    var
        PmtOrd: Record "Payment Order";
        PostBGPO: Codeunit "BG/PO-Post and Print";
        Navigate: Page Navigate;
}

