// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Comment;
using Microsoft.CashFlow.Worksheet;

page 847 "Cash Flow Forecast Card"
{
    Caption = 'Cash Flow Forecast Card';
    PageType = Card;
    SourceTable = "Cash Flow Forecast";

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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a description of the cash flow forecast.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of a forecast.';
                }
                field("Consider Discount"; Rec."Consider Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to include the cash discounts that are assigned in entries and documents in cash flow forecast.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Consider Pmt. Disc. Tol. Date"; Rec."Consider Pmt. Disc. Tol. Date")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ConsiderPmtDiscTolDateEnable;
                    ToolTip = 'Specifies if the payment discount tolerance date is considered when the cash flow date is calculated. If the check box is cleared, the due date or payment discount date from the customer and vendor ledger entries and the sales order or purchase order are used.';
                }
                field("Consider Pmt. Tol. Amount"; Rec."Consider Pmt. Tol. Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment tolerance amounts from the posted customer and vendor ledger entries are used in the cash flow forecast. If the check box is cleared, the amount without any payment tolerance amount from the customer and vendor ledger entries are used.';
                }
                field("Consider CF Payment Terms"; Rec."Consider CF Payment Terms")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to use cash flow payment terms for cash flow forecast. Cash flow payment terms overrule the standard payment terms that you have defined for customers, vendors, and orders. They also overrule the payment terms that you have manually entered on entries or documents.';
                }
                field(ShowInChart; ShowInChart)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show in Chart on Role Center';
                    ToolTip = 'Specifies the cash flow forecast chart on the Role Center page.';

                    trigger OnValidate()
                    begin
                        if not Rec.ValidateShowInChart(ShowInChart) then;
                        CurrPage.Update();
                    end;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date that the forecast was created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the user who created the forecast.';
                }
                field("G/L Budget From"; Rec."G/L Budget From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date from which you want to use the budget values from the general ledger in the cash flow forecast.';

                    trigger OnValidate()
                    begin
                        ValidateFromDatePrecedesToDate(Rec."G/L Budget From", Rec."G/L Budget To", 'G/L Budget');
                    end;
                }
                field("G/L Budget To"; Rec."G/L Budget To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date to which you want to use the budget values from the general ledger in the cash flow forecast.';

                    trigger OnValidate()
                    begin
                        ValidateFromDatePrecedesToDate(Rec."G/L Budget From", Rec."G/L Budget To", 'G/L Budget');
                    end;
                }
                field("Manual Payments From"; Rec."Manual Payments From")
                {
                    Caption = 'Manual Revenue/Expenses From';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a starting date from which manual revenue/expenses should be included in cash flow forecast.';

                    trigger OnValidate()
                    begin
                        ValidateFromDatePrecedesToDate(Rec."Manual Payments From", Rec."Manual Payments To", 'Manual Revenue/Expenses');
                    end;
                }
                field("Manual Payments To"; Rec."Manual Payments To")
                {
                    Caption = 'Manual Revenue/Expenses To';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a starting date to which manual revenue/expenses should be included in cash flow forecast.';

                    trigger OnValidate()
                    begin
                        ValidateFromDatePrecedesToDate(Rec."Manual Payments From", Rec."Manual Payments To", 'Manual Revenue/Expenses');
                    end;
                }
                field("Overdue CF Dates to Work Date"; Rec."Overdue CF Dates to Work Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Overdue Cash Flow Dates to Work Date';
                    ToolTip = 'Specifies if you want to change overdue dates to the current work date for the cash flow forecast. Choose the field if this forecast is shown in the forecast chart.';
                }
                field("Default G/L Budget Name"; Rec."Default G/L Budget Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger budget to be used when recalculating the cash flow forecast.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1905906307; "CF Forecast Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
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
            group("&Cash Flow Forecast")
            {
                Caption = '&Cash Flow Forecast';
                Image = CashFlow;
                action("E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&ntries';
                    Image = Entries;
                    RunObject = Page "Cash Flow Forecast Entries";
                    RunPageLink = "Cash Flow Forecast No." = field("No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View entries for the cash flow account.';
                }
                action("&Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Statistics';
                    Image = Statistics;
                    RunObject = Page "Cash Flow Forecast Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information for the cash flow forecast.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Cash Flow Comment";
                    RunPageLink = "Table Name" = const("Cash Flow Forecast"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                separator(Action1037)
                {
                    Caption = '';
                }
                action("CF &Availability by Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CF &Availability by Periods';
                    Image = ShowMatrix;
                    RunObject = Page "CF Availability by Periods";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View a scrollable summary of the forecasted amounts per source type, by period. The rows represent individual periods, and the columns represent the source types in the cash flow forecast.';
                }
            }
        }
        area(processing)
        {
            action(CashFlowWorksheet)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Flow Worksheet';
                Image = Worksheet2;
                RunObject = Page "Cash Flow Worksheet";
                ToolTip = 'Get an overview of cash inflows and outflows and create a short-term forecast that predicts how and when you expect money to be received and paid out by your business.';
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action(CashFlowDateList)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow &Date List';
                    Ellipsis = true;
                    Image = "Report";
                    ToolTip = 'View forecast entries for a period of time that you specify. The registered cash flow forecast entries are organized by source types, such as receivables, sales orders, payables, and purchase orders. You specify the number of periods and their length.';

                    trigger OnAction()
                    var
                        CashFlowForecast: Record "Cash Flow Forecast";
                    begin
                        CurrPage.SetSelectionFilter(CashFlowForecast);
                        CashFlowForecast.PrintRecords();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CashFlowWorksheet_Promoted; CashFlowWorksheet)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Cash Flow Forecast', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("&Statistics_Promoted"; "&Statistics")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref(CashFlowDateList_Promoted; CashFlowDateList)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateEnabled();
    end;

    trigger OnInit()
    begin
        ConsiderPmtDiscTolDateEnable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateEnabled();
    end;

    var
        ConsiderPmtDiscTolDateEnable: Boolean;
        ShowInChart: Boolean;
        FromDatePrecedesToDateErr: Label 'The "%1 To" date precedes the "%1 From" date. Select an end date after the start date.', Comment = '%1 = Field area';

    local procedure UpdateEnabled()
    begin
        ConsiderPmtDiscTolDateEnable := Rec."Consider Discount";
        ShowInChart := Rec.GetShowInChart();
    end;

    local procedure ValidateFromDatePrecedesToDate(FromDate: Date; ToDate: Date; FieldArea: Text)
    begin
        if (FromDate <> 0D) and (ToDate <> 0D) and (FromDate > ToDate) then
            Error(FromDatePrecedesToDateErr, FieldArea);
    end;
}

