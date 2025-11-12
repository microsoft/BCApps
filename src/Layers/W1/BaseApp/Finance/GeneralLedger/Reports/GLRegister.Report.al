// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

report 3 "G/L Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/GLRegister.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Register';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ShowLines; ShowDetails)
            {
            }
            column(G_L_Register__TABLECAPTION__________GLRegFilter; TableCaption + ': ' + GLRegFilter)
            {
            }
            column(GLRegFilter; GLRegFilter)
            {
            }
            column(G_L_Register__No__; "No.")
            {
            }
            column(G_L_RegisterCaption; G_L_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Entry__Posting_Date_Caption; G_L_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(G_L_Entry__Document_Type_Caption; G_L_Entry__Document_Type_CaptionLbl)
            {
            }
            column(G_L_Entry__Document_No__Caption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(G_L_Entry__G_L_Account_No__Caption; "G/L Entry".FieldCaption("G/L Account No."))
            {
            }
            column(GLAcc_NameCaption; GLAcc_NameCaptionLbl)
            {
            }
            column(G_L_Entry_DescriptionCaption; "G/L Entry".FieldCaption(Description))
            {
            }
            column(G_L_Entry__VAT_Amount_Caption; "G/L Entry".FieldCaption("VAT Amount"))
            {
            }
            column(G_L_Entry__Gen__Posting_Type_Caption; G_L_Entry__Gen__Posting_Type_CaptionLbl)
            {
            }
            column(G_L_Entry__Gen__Bus__Posting_Group_Caption; G_L_Entry__Gen__Bus__Posting_Group_CaptionLbl)
            {
            }
            column(G_L_Entry__Gen__Prod__Posting_Group_Caption; G_L_Entry__Gen__Prod__Posting_Group_CaptionLbl)
            {
            }
            column(G_L_Entry_AmountCaption; "G/L Entry".FieldCaption(Amount))
            {
            }
            column(G_L_Entry__Entry_No__Caption; "G/L Entry".FieldCaption("Entry No."))
            {
            }
            column(G_L_Register__No__Caption; G_L_Register__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(G_L_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(G_L_Entry__Document_Type_; "Document Type")
                {
                }
                column(G_L_Entry__Document_No__; "Document No.")
                {
                }
                column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                {
                }
                column(GLAcc_Name; GLAcc.Name)
                {
                }
                column(G_L_Entry_Description; Description)
                {
                }
                column(G_L_Entry__VAT_Amount_; DetailedVATAmount)
                {
                    AutoCalcField = true;
                }
                column(G_L_Entry__Gen__Posting_Type_; "Gen. Posting Type")
                {
                }
                column(G_L_Entry__Gen__Bus__Posting_Group_; "Gen. Bus. Posting Group")
                {
                }
                column(G_L_Entry__Gen__Prod__Posting_Group_; "Gen. Prod. Posting Group")
                {
                }
                column(G_L_Entry_Amount; Amount)
                {
                }
                column(G_L_Entry__Entry_No__; "Entry No.")
                {
                }
                column(G_L_Entry_Amount_Control41; Amount)
                {
                }
                column(G_L_Entry_Amount_Control41Caption; G_L_Entry_Amount_Control41CaptionLbl)
                {
                }
                dataitem("Purch. Inv. Line"; "Purch. Inv. Line")
                {
                    DataItemTableView = sorting("Document No.");
                    DataItemLink = "Document No." = field("Document No."), "No." = field("G/L Account No.");
                    UseTemporary = true;
                    column(Purch__Inv__Line_Description; Description)
                    {
                    }
                    column(Purch__Inv__Line_Amount; Amount)
                    {
                    }
                    column(Purch__Inv__Line_Document_No_; "Document No.")
                    {
                    }
                    column(Purch__Inv__Line_Line_No_; "Line No.")
                    {
                    }
                    column(Purch__Inv__Line_No_; "No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DetailedVATAmount := "Amount Including VAT" - "VAT Base Amount";
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    PurchInvLine: Record "Purch. Inv. Line";
                    SalesInvoiceLine: Record "Sales Invoice Line";
                    PurchCrMemoLine: Record "Purch. Cr. Memo Line";
                    SalesCrMemoLine: Record "Sales Cr.Memo Line";
                    PurchInvHeader: Record "Purch. Inv. Header";
                    PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                    SalesInvoiceHeader: Record "Sales Invoice Header";
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    CurrancyFactor: Decimal;
                begin
                    if not GLAcc.Get("G/L Account No.") then
                        GLAcc.Init();

                    DetailedVATAmount := "VAT Amount";

                    if not ShowDetails then
                        exit;

                    "Purch. Inv. Line".DeleteAll();

                    PurchInvLine.SetRange("Document No.", "Document No.");
                    PurchInvLine.SetRange("No.", "G/L Account No.");
                    PurchInvLine.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                    if PurchInvLine.FindSet() then begin
                        if not PurchInvHeader.Get("Document No.") then
                            exit;
                        CurrancyFactor := SetCurrancyFactor(PurchInvHeader."Currency Factor");
                        Amount := 0;
                        repeat
                            PopulateRecFromPurchInvLine(PurchInvLine, CurrancyFactor, PurchInvHeader."Prices Including VAT");
                        until PurchInvLine.Next() = 0;
                        exit;
                    end;

                    PurchCrMemoLine.SetRange("Document No.", "Document No.");
                    PurchCrMemoLine.SetRange("No.", "G/L Account No.");
                    PurchCrMemoLine.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                    if PurchCrMemoLine.FindSet() then begin
                        if not PurchCrMemoHdr.Get("Document No.") then
                            exit;
                        CurrancyFactor := SetCurrancyFactor(PurchCrMemoHdr."Currency Factor");
                        Amount := 0;
                        repeat
                            PopulateRecFromPurchCrMemoLine(PurchCrMemoLine, CurrancyFactor, PurchCrMemoHdr."Prices Including VAT");
                        until PurchCrMemoLine.Next() = 0;
                        exit;
                    end;

                    SalesInvoiceLine.SetRange("Document No.", "Document No.");
                    SalesInvoiceLine.SetRange("No.", "G/L Account No.");
                    SalesInvoiceLine.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                    if SalesInvoiceLine.FindSet() then begin
                        if not SalesInvoiceHeader.Get("Document No.") then
                            exit;
                        CurrancyFactor := SetCurrancyFactor(SalesInvoiceHeader."Currency Factor");
                        Amount := 0;
                        repeat
                            PopulateRecFromSalesInvoiceLine(SalesInvoiceLine, CurrancyFactor, SalesInvoiceHeader."Prices Including VAT");
                        until SalesInvoiceLine.Next() = 0;
                        exit;
                    end;

                    SalesCrMemoLine.SetRange("Document No.", "Document No.");
                    SalesCrMemoLine.SetRange("No.", "G/L Account No.");
                    SalesCrMemoLine.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                    if SalesCrMemoLine.FindSet() then begin
                        if not SalesCrMemoHeader.Get("Document No.") then
                            exit;
                        CurrancyFactor := SetCurrancyFactor(SalesCrMemoHeader."Currency Factor");
                        Amount := 0;
                        repeat
                            PopulateRecFromSalesCrMemoLine(SalesCrMemoLine, CurrancyFactor, SalesCrMemoHeader."Prices Including VAT");
                        until SalesCrMemoLine.Next() = 0;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About G/L Register';
        AboutText = 'The **G/L Register** report provides a batch-wise list of all posted general ledger entries, including entry numbers, posting dates, user IDs, and source descriptions. Use it for auditing, tracing who posted what and when, and verifying financial transaction integrity by filtering entries by source, user, or date';

        layout
        {
            area(content)
            {
                group(Control3)
                {
                    Caption = 'Options';
                    field(ShowDetails; ShowDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show details';
                        ToolTip = 'Specifies if the report displays all lines in detail.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLRegFilter := "G/L Register".GetFilters();
        TempPurchInvLinePrinted.DeleteAll();
    end;

    var
        GLAcc: Record "G/L Account";
        TempPurchInvLinePrinted: Record "Purch. Inv. Line" temporary;
        GLRegFilter: Text;
        G_L_RegisterCaptionLbl: Label 'G/L Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        G_L_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        G_L_Entry__Document_Type_CaptionLbl: Label 'Document Type';
        GLAcc_NameCaptionLbl: Label 'Name';
        G_L_Entry__Gen__Posting_Type_CaptionLbl: Label 'Gen. Posting Type';
        G_L_Entry__Gen__Bus__Posting_Group_CaptionLbl: Label 'Gen. Bus. Posting Group';
        G_L_Entry__Gen__Prod__Posting_Group_CaptionLbl: Label 'Gen. Prod. Posting Group';
        G_L_Register__No__CaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
        G_L_Entry_Amount_Control41CaptionLbl: Label 'Total';
        ShowDetails: Boolean;
        DetailedVATAmount: Decimal;

    local procedure DetailsPrinted(PurchInvLine: Record "Purch. Inv. Line"): Boolean
    begin
        if TempPurchInvLinePrinted.get(PurchInvLine."Document No.", PurchInvLine."Line No.") then
            exit(true);
        TempPurchInvLinePrinted."Document No." := PurchInvLine."Document No.";
        TempPurchInvLinePrinted."Line No." := PurchInvLine."Line No.";
        TempPurchInvLinePrinted.Insert();
    end;

    local procedure PopulateRecFromPurchInvLine(PurchInvLine: Record "Purch. Inv. Line"; CurrancyFactor: Decimal; PricesInclVAT: Boolean)
    begin
        if PricesInclVAT then
            PurchInvLine.Amount := Round(PurchInvLine."VAT Base Amount" / CurrancyFactor)
        else
            PurchInvLine.Amount := Round(PurchInvLine."Line Amount" / CurrancyFactor);
        "Purch. Inv. Line".Init();
        "Purch. Inv. Line".TransferFields(PurchInvLine);
        if not DetailsPrinted("Purch. Inv. Line") then
            "Purch. Inv. Line".Insert();
    end;

    local procedure PopulateRecFromPurchCrMemoLine(PurchCrMemoLine: Record "Purch. Cr. Memo Line"; CurrancyFactor: Decimal; PricesInclVAT: Boolean)
    begin
        "Purch. Inv. Line".Init();
        if PricesInclVAT then
            PurchCrMemoLine.Amount := Round(PurchCrMemoLine."VAT Base Amount" / CurrancyFactor)
        else
            PurchCrMemoLine.Amount := Round(PurchCrMemoLine."Line Amount" / CurrancyFactor);
        "Purch. Inv. Line".Description := PurchCrMemoLine.Description;
        "Purch. Inv. Line".Amount := -PurchCrMemoLine.Amount;
        "Purch. Inv. Line"."Document No." := PurchCrMemoLine."Document No.";
        "Purch. Inv. Line"."Line No." := PurchCrMemoLine."Line No.";
        "Purch. Inv. Line"."No." := PurchCrMemoLine."No.";
        "Purch. Inv. Line"."Amount Including VAT" := -PurchCrMemoLine."Amount Including VAT";
        "Purch. Inv. Line"."VAT Base Amount" := -PurchCrMemoLine."VAT Base Amount";
        if not DetailsPrinted("Purch. Inv. Line") then
            "Purch. Inv. Line".Insert();
    end;

    local procedure PopulateRecFromSalesInvoiceLine(SalesInvoiceLine: Record "Sales Invoice Line"; CurrancyFactor: Decimal; PricesInclVAT: Boolean)
    begin
        "Purch. Inv. Line".Init();
        if PricesInclVAT then
            SalesInvoiceLine.Amount := Round(SalesInvoiceLine."VAT Base Amount" / CurrancyFactor)
        else
            SalesInvoiceLine.Amount := Round(SalesInvoiceLine."Line Amount" / CurrancyFactor);
        "Purch. Inv. Line".Description := SalesInvoiceLine.Description;
        "Purch. Inv. Line".Amount := -SalesInvoiceLine.Amount;
        "Purch. Inv. Line"."Document No." := SalesInvoiceLine."Document No.";
        "Purch. Inv. Line"."Line No." := SalesInvoiceLine."Line No.";
        "Purch. Inv. Line"."No." := SalesInvoiceLine."No.";
        "Purch. Inv. Line"."Amount Including VAT" := -SalesInvoiceLine."Amount Including VAT";
        "Purch. Inv. Line"."VAT Base Amount" := -SalesInvoiceLine."VAT Base Amount";
        if not DetailsPrinted("Purch. Inv. Line") then
            "Purch. Inv. Line".Insert();
    end;

    local procedure PopulateRecFromSalesCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"; CurrancyFactor: Decimal; PricesInclVAT: Boolean)
    begin
        "Purch. Inv. Line".Init();
        if PricesInclVAT then
            SalesCrMemoLine.Amount := Round(SalesCrMemoLine."VAT Base Amount" / CurrancyFactor)
        else
            SalesCrMemoLine.Amount := Round(SalesCrMemoLine."Line Amount" / CurrancyFactor);
        "Purch. Inv. Line".Description := SalesCrMemoLine.Description;
        "Purch. Inv. Line".Amount := SalesCrMemoLine.Amount;
        "Purch. Inv. Line"."Document No." := SalesCrMemoLine."Document No.";
        "Purch. Inv. Line"."Line No." := SalesCrMemoLine."Line No.";
        "Purch. Inv. Line"."No." := SalesCrMemoLine."No.";
        "Purch. Inv. Line"."Amount Including VAT" := SalesCrMemoLine."Amount Including VAT";
        "Purch. Inv. Line"."VAT Base Amount" := SalesCrMemoLine."VAT Base Amount";
        if not DetailsPrinted("Purch. Inv. Line") then
            "Purch. Inv. Line".Insert();
    end;

    local procedure SetCurrancyFactor(HeaderCurrancyFactor: Decimal): Decimal
    begin
        if HeaderCurrancyFactor = 0 then
            exit(1);
        exit(HeaderCurrancyFactor);
    end;
}

