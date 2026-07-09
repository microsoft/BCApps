// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Environment;
using System.Environment.Configuration;

page 1159 "Purchase Documents"
{
    Caption = 'Purchase Documents';
    DataCaptionFields = "Vendor No.";
    PageType = ListPart;
    SourceTable = "Vendor Ledger Entry";
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
                    ToolTip = 'Specifies when the purchase document is due.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the purchase document number.';
                }
                field("Vendor Name"; VendorName)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies name of the Vendor.';
                }
                field("Remaining Amount LCY"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Remaining Amount. (LCY)';
                    ToolTip = 'Specifies the net amount of in the local currency. The amount is calculated using the Remaining Quantity, Line Discount %, and Unit Price (LCY) fields. ';

                    trigger OnDrillDown()
                    var
                        Company: Record Company;
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                        HyperLinkUrl: Text[500];
                    begin
                        Company.Get(CompanyName);
                        if Company."Evaluation Company" then
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 574) +
                              '&' + ConfPersonalizationMgt.GetProfileUrlParameterForEvaluationCompany()
                              + StrSubstNo(FilterForRemAmtDrillDwnTxt, Rec."Entry No.")
                        else
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 574) + StrSubstNo(FilterForRemAmtDrillDwnTxt, Rec."Entry No.");
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
        Vendor: Record Vendor;
    begin
        StyleTxt := Rec.SetStyle();
        Vendor.Get(Rec."Vendor No.");
        VendorName := Vendor.Name;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Due Date", '<%1', WorkDate());
        Rec.SetRange("Document Type", Rec."Document Type"::Invoice);
        Rec.SetFilter("Remaining Amt. (LCY)", '<>0');
        Rec.Ascending := true;
    end;

    var
        StyleTxt: Text;
        VendorName: Text[250];
        FilterForRemAmtDrillDwnTxt: Label '&filter=''Detailed Vendor Ledg. Entry''.''Vendor Ledger Entry No.'' IS ''%1''', Comment = '%1 - Entry No. for Vendor ledger entry. ';

    procedure SetFilterForOverduePurInvoiceAmount()
    begin
        Rec.Reset();
        Rec.SetFilter("Due Date", '<%1', WorkDate());
        Rec.SetRange("Document Type", Rec."Document Type"::Invoice);
        Rec.SetFilter("Remaining Amt. (LCY)", '<>0');
        Rec.Ascending := true;
        CurrPage.Update();
    end;

    procedure SetFilterForPurchDocsDueToday()
    begin
        Rec.Reset();
        Rec.SetRange(Open, true);
        Rec.SetFilter("Document Type", 'Invoice|Credit Memo');
        Rec.SetFilter("Due Date", '<=%1', WorkDate());
        Rec.Ascending := true;
        CurrPage.Update();
    end;

    procedure SetFilterForPurchInvoicesDueNextWeek()
    begin
        Rec.Reset();
        Rec.SetRange(Open, true);
        Rec.SetFilter("Document Type", 'Invoice|Credit Memo');
        Rec.SetFilter("Due Date", '%1..%2', CalcDate('<1D>', WorkDate()), CalcDate('<1W>', WorkDate()));
        Rec.Ascending := true;
        CurrPage.Update();
    end;
}

