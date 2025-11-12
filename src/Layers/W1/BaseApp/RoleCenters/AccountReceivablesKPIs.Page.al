// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;
using Microsoft.RoleCenters;
using System.Visualization;
using Microsoft.Sales.Receivables;

page 1318 "Account Receivables KPIs"
{
    PageType = CardPart;
    Caption = 'Accounts Receivables Overview';
    SourceTable = "Finance Cue";

    layout
    {
        area(Content)
        {
            cuegroup(KPIs)
            {
                ShowCaption = false;
                CuegroupLayout = Wide;
                field("Sales - Total Overdue (LCY)"; Rec."Total Overdue (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total overdue amount.';
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        CustLedgerEntry.SetRange(Open, true);
                        CustLedgerEntry.SetFilter("Due Date", '<=%1', Today());
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
                field("Sales - Total Outstanding (LCY)"; Rec."Total Outstanding (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total outstanding amount.';
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        CustLedgerEntry.SetRange(Open, true);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
                field("A/R Accounts Balance"; ActivitiesMgt.CalcARAccountsBalances())
                {
                    ApplicationArea = All;
                    Caption = 'A/R Accounts Balance';
                    ToolTip = 'Specifies the sum of the accounts that have the account receivables account category. You can configure which account category is considered for Account Receivables in the General Ledger Setup page.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownCalcARAccountsBalances();
                    end;
                }
                field("Average Collection Days"; ActivitiesMgt.CalcAverageCollectionDays(false))
                {
                    ApplicationArea = All;
                    Caption = 'Average Collection Days';
                    ToolTip = 'Specifies how long customers took to pay invoices in the last three months. This is the average number of days from when invoices are issued to when customers pay the invoices.';
                }
                field("Sales Invoices Due Next Week"; ActivitiesCue."Sales Invoices Due Next Week")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Invoices Due Next Week';
                    ToolTip = 'Specifies the total amount of sales invoices due next week.';
                    StyleExpr = SalesInvoicesDueNextWeekStyleExpr;

                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        CustLedgerEntry.SetFilter("Document Type", '%1|%2', CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::"Credit Memo");
                        CustLedgerEntry.SetFilter("Due Date", '%1..%2', CalcDate('<1D>', Today), CalcDate('<1W>', Today));
                        CustLedgerEntry.SetRange("Open", true);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
            }
        }
    }

    var
        ActivitiesCue: Record "Activities Cue";
        ActivitiesMgt: Codeunit "Activities Mgt.";
        SalesInvoicesDueNextWeekStyleExpr: Text;

    trigger OnOpenPage()
    var
        CuesAndKPIs: Codeunit "Cues And KPIs";
        SalesInvoicesDueNextWeekStyle: Enum "Cues And KPIs Style";
    begin
        Rec.SetRange("Overdue Date Filter", 0D, Today());
        if not Rec.Get() then begin
            Clear(Rec);
            Rec.Insert();
        end;
        if not ActivitiesCue.Get() then begin
            ActivitiesCue.Init();
            ActivitiesCue.Insert();
            Commit();
        end;

        ActivitiesCue.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<1D>', Today), CalcDate('<1W>', Today));
        ActivitiesCue.CalcFields("Sales Invoices Due Next Week");
        CuesAndKPIs.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Sales Invoices Due Next Week"), ActivitiesCue."Sales Invoices Due Next Week", SalesInvoicesDueNextWeekStyle);
        SalesInvoicesDueNextWeekStyleExpr := Format(SalesInvoicesDueNextWeekStyle);
    end;
}
