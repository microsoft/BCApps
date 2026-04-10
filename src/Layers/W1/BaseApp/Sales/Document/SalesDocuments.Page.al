// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Sales.Customer;
using System.Environment;
using System.Environment.Configuration;

page 1160 "Sales Documents"
{
    Caption = 'Sales Documents';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Cust. Ledger Entry";
    SourceTableView = sorting("Entry No.")
                      order(descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies when the sales documents are due.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of sales document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the sales document number.';
                }
                field("Customer Name"; CustomerName)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies customer name.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount that remains to be paid on the sales documents.';

                    trigger OnDrillDown()
                    var
                        Company: Record Company;
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                        HyperLinkUrl: Text[500];
                    begin
                        Company.Get(CompanyName);
                        if Company."Evaluation Company" then
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 573) +
                              '&' + ConfPersonalizationMgt.GetProfileUrlParameterForEvaluationCompany()
                               + StrSubstNo(FilterForRemAmtDrillDwnTxt, Rec."Entry No.")
                        else
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 573) + StrSubstNo(FilterForRemAmtDrillDwnTxt, Rec."Entry No.");
                        HyperLink(HyperLinkUrl);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetRecord()
    var
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("Name");
        Customer.Get(Rec."Customer No.");
        CustomerName := Customer.Name;
        StyleTxt := Rec.SetStyle();

        OnAfterOnAfterGetRecord(Rec, StyleTxt);
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("Document Type", Rec."Document Type"::Invoice);
        Rec.SetRange(Open, true);
        Rec.SetFilter("Due Date", '<%1', WorkDate());
        Rec.SetFilter("Remaining Amt. (LCY)", '<>0');
        Rec.SetCurrentKey("Remaining Amt. (LCY)");
        Rec.Ascending := false;
    end;

    var
        StyleTxt: Text;
        CustomerName: Text[100];
        FilterForRemAmtDrillDwnTxt: Label '&filter=''Detailed Cust. Ledg. Entry''.''Cust. Ledger Entry No.'' IS ''%1''', Comment = '%1 - Entry No. for Vendor ledger entry. ';

    procedure SetFilterForOverdueSalesInvoiceAmount()
    begin
        Rec.Reset();
        Rec.SetRange("Document Type", Rec."Document Type"::Invoice);
        Rec.SetRange(Open, true);
        Rec.SetFilter("Due Date", '<%1', WorkDate());
        Rec.SetFilter("Remaining Amt. (LCY)", '<>0');
        Rec.SetCurrentKey("Remaining Amt. (LCY)");
        Rec.Ascending := false;
        CurrPage.Update();
    end;

    procedure SetFilterForSalesDocsDueToday()
    begin
        Rec.Reset();
        Rec.SetFilter("Document Type", 'Invoice|Credit Memo');
        Rec.SetFilter("Due Date", '<=%1', WorkDate());
        Rec.SetRange(Open, true);
        Rec.Ascending := false;
        CurrPage.Update();
    end;

    procedure SetFilterForSalesDocsDueNextWeek()
    begin
        Rec.Reset();
        Rec.SetFilter("Document Type", 'Invoice|Credit Memo');
        Rec.SetFilter("Due Date", '%1..%2', CalcDate('<1D>', WorkDate()), CalcDate('<1W>', WorkDate()));
        Rec.SetRange(Open, true);
        Rec.Ascending := false;
        CurrPage.Update();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnAfterGetRecord(CustLedgerEntry: Record "Cust. Ledger Entry"; var StyleTxt: Text)
    begin
    end;
}

