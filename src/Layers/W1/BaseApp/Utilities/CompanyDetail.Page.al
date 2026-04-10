// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.RoleCenters;
using Microsoft.Foundation.Task;
using Microsoft.Purchases.Document;
using Microsoft.RoleCenters;
using Microsoft.Sales.Receivables;
using System.Integration.PowerBI;

page 1156 "Company Detail"
{
    Caption = 'Company Details';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            group(Cash)
            {
                Caption = 'Cash';
                part(Control12; "Cash Account Balances")
                {
                    ApplicationArea = All;
                }
                part(Control9; "Client Detail Cash Flow Chart")
                {
                    ApplicationArea = All;
                }
            }
            group("User Tasks")
            {
                Caption = 'User Tasks';
                group(Control42)
                {
                    ShowCaption = false;
                    cuegroup(Control41)
                    {
                        ShowCaption = false;
                        field("<PendingTasks>"; PendingTasks)
                        {
                            ApplicationArea = All;
                            Caption = 'Pending Tasks';
                            Image = Checklist;
                            ToolTip = 'Specifies the number of pending tasks that are assigned to you.';

                            trigger OnDrillDown()
                            begin
                                SelectedUserTaskFilterTile := PendingUserTasksFilterTxt;
                                TotalUserTasks := CalculatePendingUserTasks();
                                CurrPage.UserTasksCtrl.Page.SetFilterForPendingTasks();
                            end;
                        }
                        field("<Due Today>"; UserTasksDueToday)
                        {
                            ApplicationArea = All;
                            Caption = 'Due Today';
                            Image = Checklist;
                            ToolTip = 'Specifies the number of pending tasks that are assigned to you and are due today or are overdue.';

                            trigger OnDrillDown()
                            begin
                                SelectedUserTaskFilterTile := UserTasksDueTodayFilterTxt;
                                TotalUserTasks := CalculateUserTasksDueToday();
                                CurrPage.UserTasksCtrl.Page.SetFilterForTasksDueToday();
                            end;
                        }
                        field("<Due This Week>"; UserTasksDueThisWeek)
                        {
                            ApplicationArea = All;
                            Caption = 'Due This Week';
                            Image = Checklist;
                            ToolTip = 'Specifies the number of pending tasks that are assigned to you and are due this week.';

                            trigger OnDrillDown()
                            begin
                                SelectedUserTaskFilterTile := UserTasksDueThisWeekFilterTxt;
                                TotalUserTasks := CalculateUserTasksDueThisWeek();
                                CurrPage.UserTasksCtrl.Page.SetFilterForTasksDueThisWeek();
                            end;
                        }
                    }
                    field("<SelectedUserTaskFilterTile>"; SelectedUserTaskFilterTile)
                    {
                        ApplicationArea = All;
                        Caption = 'Showing';
                        Importance = Promoted;
                        ShowCaption = false;
                    }
                    part(UserTasksCtrl; "User Task List Part")
                    {
                        ApplicationArea = All;
                        Caption = 'My Tasks';
                    }
                    field("<TotalUserTasks>"; TotalUserTasks)
                    {
                        ApplicationArea = All;
                        Caption = 'Total';
                        Importance = Promoted;
                        ToolTip = 'Specifies the total number of user tasks.';
                    }
                }
            }
            group("Power BI")
            {
                Caption = 'Power BI';
                part(PowerBIEmbeddedReportPart1; "Power BI Embedded Report Part")
                {
                    ApplicationArea = All;
                }
                part(PowerBIEmbeddedReportPart2; "Power BI Embedded Report Part")
                {
                    ApplicationArea = All;
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                group(Control7)
                {
                    ShowCaption = false;
                    cuegroup(Control14)
                    {
                        ShowCaption = false;
                        field(OverDuePurchInvoiceAmt; OverDuePurchInvoiceAmt)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Overdue Purch. Invoice Amount';
                            DecimalPlaces = 0 : 0;
                            Image = Cash;
                            ToolTip = 'Specifies the sum of your overdue payments to vendors.';

                            trigger OnDrillDown()
                            begin
                                SelectedPurchFilterTile := OverduePurchInvoiceAmtFilterTxt;
                                TotalPurch := OverDuePurchInvoiceAmt;
                                CurrPage.PurchaseDocumentsCtrl.Page.SetFilterForOverduePurInvoiceAmount();
                            end;
                        }
                        field("<PurchDocsDueToday>"; PurchDocsDueToday)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 0;
                            Caption = 'Purchase Documents Due Today';
                            DecimalPlaces = 0 : 0;
                            Image = Document;
                            ToolTip = 'Specifies the number of purchase invoices that are due for payment today.';

                            trigger OnDrillDown()
                            begin
                                SelectedPurchFilterTile := PurchDocsDueTodayFilterTxt;
                                TotalPurch := PurchDocsDueToday;
                                CurrPage.PurchaseDocumentsCtrl.Page.SetFilterForPurchDocsDueToday();
                            end;
                        }
                        field(PurchInvoicesDueNextWeek; PurchInvoicesDueNextWeek)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 0;
                            Caption = 'Purch. Invoices Due Next Week';
                            DecimalPlaces = 0 : 0;
                            Image = Document;
                            ToolTip = 'Specifies the number of payments to vendors that are due next week.';

                            trigger OnDrillDown()
                            begin
                                SelectedPurchFilterTile := PurchInvoicesDueNextWeekFilterTxt;
                                TotalPurch := PurchInvoicesDueNextWeek;
                                CurrPage.PurchaseDocumentsCtrl.Page.SetFilterForPurchInvoicesDueNextWeek();
                            end;
                        }
                    }
                    field(SelectedPurchFilterTile; SelectedPurchFilterTile)
                    {
                        ApplicationArea = All;
                        Caption = 'Showing';
                        Importance = Promoted;
                        ShowCaption = false;
                        ToolTip = 'Specifies that the part is visible. ';
                    }
                    part(PurchaseDocumentsCtrl; "Purchase Documents")
                    {
                        ApplicationArea = All;
                        Caption = 'Purchase Documents';
                    }
                    field("<TotalPurch>"; TotalPurch)
                    {
                        ApplicationArea = All;
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Total';
                        DecimalPlaces = 0 : 2;
                        Importance = Promoted;
                        ToolTip = 'Specifies selected purchase KPI information.';
                    }
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                group(Control19)
                {
                    ShowCaption = false;
                    cuegroup(Control18)
                    {
                        ShowCaption = false;
                        field("<OverDueSalesInvoiceAmt>"; OverDueSalesInvoiceAmt)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Overdue Sales Invoice Amount';
                            DecimalPlaces = 0 : 0;
                            Image = Cash;
                            ShowCaption = false;
                            ToolTip = 'Specifies the sum of overdue payments from customers.';

                            trigger OnDrillDown()
                            begin
                                SelectedSalesFilterTile := OverdueSalesInvoiceAmtFilterTxt;
                                TotalSales := OverDueSalesInvoiceAmt;
                                CurrPage.SalesDocumentsCtrl.Page.SetFilterForOverdueSalesInvoiceAmount();
                            end;
                        }
                        field("<SalesDocsDueToday>"; SalesDocsDueToday)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 0;
                            Caption = 'Sales Documents Due Today';
                            DecimalPlaces = 0 : 0;
                            Image = Document;
                            ToolTip = 'Specifies sales documents due today.';

                            trigger OnDrillDown()
                            begin
                                SelectedSalesFilterTile := SalesDocsDueTodayFilterTxt;
                                TotalSales := SalesDocsDueToday;
                                CurrPage.SalesDocumentsCtrl.Page.SetFilterForSalesDocsDueToday();
                            end;
                        }
                        field("<SalesDocsDueNextWeek>"; SalesDocsDueNextWeek)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 0;
                            Caption = 'Sales Documents Due Next Week';
                            DecimalPlaces = 0 : 0;
                            Image = Document;
                            ToolTip = 'Specifies sales documents due next week.';

                            trigger OnDrillDown()
                            begin
                                SelectedSalesFilterTile := SalesDocsDueNextWeekFilterTxt;
                                TotalSales := SalesDocsDueNextWeek;
                                CurrPage.SalesDocumentsCtrl.Page.SetFilterForSalesDocsDueNextWeek();
                            end;
                        }
                    }
                    field("<SelectedSalesFilterTile>"; SelectedSalesFilterTile)
                    {
                        ApplicationArea = All;
                        Caption = 'Showing';
                        Importance = Promoted;
                        ShowCaption = false;
                        ToolTip = 'Specifies that the part is visible. ';
                    }
                    part(SalesDocumentsCtrl; "Sales Documents")
                    {
                        ApplicationArea = All;
                        Caption = 'Sales Documents';
                    }
                    field("<TotalSales>"; TotalSales)
                    {
                        ApplicationArea = All;
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Total';
                        DecimalPlaces = 0 : 2;
                        Importance = Promoted;
                        ShowCaption = true;
                        ToolTip = 'Specifies selected sales KPI information.';
                    }
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            group("Report")
            {
                Caption = 'Report';
                group("Excel Reports")
                {
                    Caption = 'Excel Reports';
                    Image = Excel;
                }
            }
            group(Link)
            {
                Caption = 'Link';
                action(GoToClientCompany)
                {
                    ApplicationArea = All;
                    Caption = 'Go To Client';
                    Image = Link;
                    ToolTip = 'Log into this client company.';

                    trigger OnAction()
                    begin
                        HyperLink(GetUrl(CLIENTTYPE::Web, CompanyName));
                        OnGoToCompany();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(GoToClientCompany_Promoted; GoToClientCompany)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CalculatePurchCues();
        CalculateSalesCues();
        CalculateUserTasksCues();

        CurrPage.PowerBIEmbeddedReportPart1.Page.SetPageContext(PowerBiPartOneIdTxt);
        CurrPage.PowerBIEmbeddedReportPart2.Page.SetPageContext(PowerBiPartTwoIdTxt);
    end;

    var
        ActivitiesMgt: Codeunit "Activities Mgt.";
        UserTaskManagement: Codeunit "User Task Management";
        OverDuePurchInvoiceAmt: Decimal;
        PurchDocsDueToday: Decimal;
        PurchInvoicesDueNextWeek: Decimal;
        SelectedPurchFilterTile: Text[250];
        OverduePurchInvoiceAmtFilterTxt: Label 'Overdue Purch. Invoice Amount';
        PurchDocsDueTodayFilterTxt: Label 'Purchase Documents Due Today';
        PurchInvoicesDueNextWeekFilterTxt: Label 'Purch. Invoices Due Next Week';
        TotalPurch: Decimal;
        OverDueSalesInvoiceAmt: Decimal;
        TotalSales: Decimal;
        SelectedSalesFilterTile: Text[250];
        OverdueSalesInvoiceAmtFilterTxt: Label 'Overdue Sales Invoice Amount';
        SalesDocsDueToday: Decimal;
        SalesDocsDueNextWeek: Decimal;
        SalesDocsDueTodayFilterTxt: Label 'Sales Documents Due Today';
        SalesDocsDueNextWeekFilterTxt: Label 'Sales Documents Due Next Week';
        PowerBiPartOneIdTxt: Label '1156PowerBiPartOne', Locked = true;
        PowerBiPartTwoIdTxt: Label '1156PowerBiPartTwo', Locked = true;
        PendingTasks: Integer;
        UserTasksDueToday: Integer;
        UserTasksDueThisWeek: Integer;
        SelectedUserTaskFilterTile: Text[250];
        PendingUserTasksFilterTxt: Label 'Pending Tasks';
        UserTasksDueTodayFilterTxt: Label 'Due Today';
        UserTasksDueThisWeekFilterTxt: Label 'Due This Week';
        TotalUserTasks: Integer;

    local procedure CalculatePurchCues()
    var
        FinanceCue: Record "Finance Cue";
    begin
        // Calculate overdue purchase invoice amount
        OverDuePurchInvoiceAmt := ActivitiesMgt.OverduePurchaseInvoiceAmount(false, true);

        // Set overdue purchase invoice amount as default selected KPI
        SelectedPurchFilterTile := OverduePurchInvoiceAmtFilterTxt;
        TotalPurch := OverDuePurchInvoiceAmt;

        // Calculate purchase documents due today
        FinanceCue.SetFilter("Due Date Filter", '<=%1', WorkDate());
        FinanceCue.CalcFields("Purchase Documents Due Today");
        PurchDocsDueToday := FinanceCue."Purchase Documents Due Today";
        Clear(FinanceCue);

        // Calculate purchase invoices due next week
        FinanceCue.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<1D>', WorkDate()), CalcDate('<1W>', WorkDate()));
        FinanceCue.CalcFields("Purch. Invoices Due Next Week");
        PurchInvoicesDueNextWeek := FinanceCue."Purch. Invoices Due Next Week";
        Clear(FinanceCue);
    end;

    local procedure CalculateSalesCues()
    var
        FinanceCue: Record "Finance Cue";
    begin
        // Calculate overdue sales invoice amount
        OverDueSalesInvoiceAmt := ActivitiesMgt.OverdueSalesInvoiceAmount(false, true);
        // Set total sales to overdue sales invoice amount as default selected KPI
        SelectedSalesFilterTile := OverdueSalesInvoiceAmtFilterTxt;
        TotalSales := OverDueSalesInvoiceAmt;

        // Calculate sales documents due today
        FinanceCue.SetFilter("Overdue Date Filter", '<=%1', WorkDate());
        FinanceCue.CalcFields("Overdue Sales Documents");
        SalesDocsDueToday := FinanceCue."Overdue Sales Documents";
        Clear(FinanceCue);

        // Calculate sales documents due next week
        FinanceCue.SetFilter("Overdue Date Filter", '%1..%2', CalcDate('<1D>', WorkDate()), CalcDate('<1W>', WorkDate()));
        FinanceCue.CalcFields("Overdue Sales Documents");
        SalesDocsDueNextWeek := FinanceCue."Overdue Sales Documents";
        Clear(FinanceCue);
    end;

    local procedure CalculateUserTasksCues()
    begin
        // Set user tasks cue to display pending tasks
        SelectedUserTaskFilterTile := PendingUserTasksFilterTxt;

        // Calculate pending tasks
        PendingTasks := CalculatePendingUserTasks();
        TotalUserTasks := PendingTasks;

        // Calculate tasks due today
        UserTasksDueToday := CalculateUserTasksDueToday();

        // Calculate tasks due this week
        UserTasksDueThisWeek := CalculateUserTasksDueThisWeek();
    end;

    local procedure CalculatePendingUserTasks(): Integer
    begin
        exit(UserTaskManagement.GetMyPendingUserTasksCount());
    end;

    local procedure CalculateUserTasksDueToday(): Integer
    begin
        exit(UserTaskManagement.GetMyPendingUserTasksCountDueToday());
    end;

    local procedure CalculateUserTasksDueThisWeek(): Integer
    begin
        exit(UserTaskManagement.GetMyPendingUserTasksCountDueThisWeek());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGoToCompany()
    begin
        // This event is called when an accountant goes to their client and enables us to capture telemetry for this action.
    end;
}
