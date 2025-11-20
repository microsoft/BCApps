// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 2501 "Day Book Cust. Ledger Entry"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/DayBookCustLedgerEntry.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Day Book Customer Ledger Entry';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ReqCustLedgEntry; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code");
            RequestFilterFields = "Document Type", "Customer No.", "Posting Date", "Currency Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Date));
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(All_amounts_are_in___GLSetup__LCY_Code_; StrSubstNo(AllAmountsAreInLbl, GLSetup."LCY Code"))
            {
            }
            column(GetAmountLCY; AmountLCY1)
            {
            }
            column(GetPmtDiscGiven; PmtDiscGiven1)
            {
            }
            column(GetVatBase; VatBase1)
            {
            }
            column(GetVatAmount; VatAmount1)
            {
            }
            column(G_L_Entry___Entry_No__; "G/L Entry"."Entry No.")
            {
            }
            column(CustLedgerEntry___Entry_No__; "Cust. Ledger Entry"."Entry No.")
            {
            }
            column(PrintCLDetails; PrintCLDetails)
            {
            }
            column(GetActualAmount; ActualAmount1)
            {
            }
            column(Cust__Ledger_Entry__TABLENAME__________CustLedgFilter; "Cust. Ledger Entry".TableCaption + ': ' + CustLedgFilter)
            {
            }
            column(CustLedgFilter; CustLedgFilter)
            {
            }
            column(Total_for______Cust__Ledger_Entry__TABLENAME__________CustLedgFilter; StrSubstNo(TotalForCustLedgerEntryLbl, "Cust. Ledger Entry".TableCaption(), CustLedgFilter))
            {
            }
            column(VATAmount; VATAmount)
            {
                AutoFormatType = 1;
            }
            column(VATBase; VATBase)
            {
                AutoFormatType = 1;
            }
            column(ActualAmount; ActualAmount)
            {
                AutoFormatType = 1;
            }
            column(PmtDiscGiven; PmtDiscGiven)
            {
            }
            column(Cust__Ledger_Entry___Amount__LCY__; "Cust. Ledger Entry"."Amount (LCY)")
            {
                AutoFormatType = 1;
            }
            column(Date_Period_Type; "Period Type")
            {
            }
            column(Date_Period_Start; "Period Start")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Day_Book_Cust__Ledger_EntryCaption; Day_Book_Cust__Ledger_EntryCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Amount__LCY__Caption; Cust__Ledger_Entry__Amount__LCY__CaptionLbl)
            {
            }
            column(PmtDiscGiven_Control32Caption; PmtDiscGiven_Control32CaptionLbl)
            {
            }
            column(VATAmount_Control26Caption; VATAmount_Control26CaptionLbl)
            {
            }
            column(ActualAmount_Control39Caption; ActualAmount_Control39CaptionLbl)
            {
            }
            column(VATBase_Control29Caption; VATBase_Control29CaptionLbl)
            {
            }
            column(PmtDiscGiven_Control32Caption_Control33; PmtDiscGiven_Control32Caption_Control33Lbl)
            {
            }
            column(Customer_NameCaption; Customer_NameCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Customer_No__Caption; Cust__Ledger_Entry__Customer_No__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__External_Document_No__Caption; "Cust. Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Cust__Ledger_Entry__Amount__LCY__Caption_Control24; Cust__Ledger_Entry__Amount__LCY__Caption_Control24Lbl)
            {
            }
            column(VATAmount_Control26Caption_Control27; VATAmount_Control26Caption_Control27Lbl)
            {
            }
            column(VATBase_Control29Caption_Control30; VATBase_Control29Caption_Control30Lbl)
            {
            }
            column(ActualAmount_Control39Caption_Control35; ActualAmount_Control39Caption_Control35Lbl)
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date");
                column(Cust__Ledger_Entry__FIELDNAME__Posting_Date__________FORMAT_Date__Period_Start__0_4_; FieldCaption("Posting Date") + ' ' + Format(Date."Period Start", 0, 4))
                {
                }
                column(FIELDNAME__Document_Type___________FORMAT__Document_Type__; FieldCaption("Document Type") + ' ' + Format("Document Type"))
                {
                }
                column(Cust__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Cust__Ledger_Entry__External_Document_No__; "External Document No.")
                {
                }
                column(Cust__Ledger_Entry__Amount__LCY__; "Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(VATBase_Control29; VATBase)
                {
                    AutoFormatType = 1;
                }
                column(PmtDiscGiven_Control32; PmtDiscGiven)
                {
                }
                column(Customer_Name; Customer.Name)
                {
                }
                column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                {
                }
                column(ActualAmount_Control39; ActualAmount)
                {
                    AutoFormatType = 1;
                }
                column(VATAmount_Control26; VATAmount)
                {
                    AutoFormatType = 1;
                }
                column(Total_for___FIELDNAME__Document_Type_________FORMAT__Document_Type__; StrSubstNo(TotalForCustLedgerEntryLbl, FieldCaption("Document Type"), Format("Document Type")))
                {
                }
                column(VATAmount_Control19; VATAmount)
                {
                    AutoFormatType = 1;
                }
                column(VATBase_Control22; VATBase)
                {
                    AutoFormatType = 1;
                }
                column(ActualAmount_Control25; ActualAmount)
                {
                    AutoFormatType = 1;
                }
                column(PmtDiscGiven_Control38; PmtDiscGiven)
                {
                }
                column(Cust__Ledger_Entry__Amount__LCY___Control41; "Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(Total_for_____FORMAT_Date__Period_Start__0_4_; StrSubstNo(TotalForDatePeriodStartLbl, Format(Date."Period Start", 0, 4)))
                {
                }
                column(Cust__Ledger_Entry__Amount__LCY___Control57; "Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(PmtDiscGiven_Control50; PmtDiscGiven)
                {
                }
                column(ActualAmount_Control49; ActualAmount)
                {
                    AutoFormatType = 1;
                }
                column(VATBase_Control48; VATBase)
                {
                    AutoFormatType = 1;
                }
                column(VATAmount_Control47; VATAmount)
                {
                    AutoFormatType = 1;
                }
                column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Cust__Ledger_Entry_Document_Type; "Document Type")
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemTableView = sorting("Transaction No.");
                    column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                    {
                    }
                    column(GLAcc_Name; GLAcc.Name)
                    {
                    }
                    column(G_L_Entry_Amount; Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(G_L_Entry_Entry_No_; "Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "G/L Account No." <> GLAcc."No." then
                            if not GLAcc.Get("G/L Account No.") then
                                GLAcc.Init();

                        if SecondStep then begin
                            if PrintGLDetails then begin
                                AmountLCY1 := "Cust. Ledger Entry"."Amount (LCY)";
                                PmtDiscGiven1 := PmtDiscGiven;
                                ActualAmount1 := ActualAmount;
                                VatBase1 := VATBase;
                                VatAmount1 := VATAmount;
                            end;
                            SecondStep := false;
                        end else begin
                            AmountLCY1 := 0;
                            PmtDiscGiven1 := 0;
                            ActualAmount1 := 0;
                            VatBase1 := 0;
                            VatAmount1 := 0;
                        end;
                    end;

                    trigger OnPreDataItem()
                    var
                        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                        TransactionNoFilter: Text[250];
                    begin
                        if not PrintGLDetails then
                            CurrReport.Break();

                        DtldCustLedgEntry.Reset();
                        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", "Cust. Ledger Entry"."Entry No.");
                        DtldCustLedgEntry.SetFilter("Entry Type", '<>%1', DtldCustLedgEntry."Entry Type"::Application);
                        if DtldCustLedgEntry.FindSet() then begin
                            TransactionNoFilter := Format(DtldCustLedgEntry."Transaction No.");
                            while DtldCustLedgEntry.Next() <> 0 do
                                TransactionNoFilter := TransactionNoFilter + '|' + Format(DtldCustLedgEntry."Transaction No.");
                        end;
                        SetFilter("Transaction No.", TransactionNoFilter);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    TempVATEntry: Record "VAT Entry" temporary;
                begin
                    SecondStep := true;

                    if "Customer No." <> Customer."No." then
                        if not Customer.Get("Customer No.") then
                            Customer.Init();

                    VATAmount := 0;
                    VATBase := 0;
                    VATEntry.SetCurrentKey("Transaction No.");
                    VATEntry.SetRange("Transaction No.", "Transaction No.");
                    if VATEntry.FindSet() then
                        if VATEntry."Tax Liable" then begin
                            repeat
                                TempVATEntry.SetRange("Tax Area Code", VATEntry."Tax Area Code");
                                TempVATEntry.SetRange("Tax Group Code", VATEntry."Tax Group Code");
                                if TempVATEntry.FindFirst() then begin
                                    TempVATEntry.Amount += VATEntry.Amount;
                                    TempVATEntry.Modify();
                                end else begin
                                    TempVATEntry := VATEntry;
                                    TempVATEntry.Insert();
                                end;
                            until VATEntry.Next() = 0;
                            TempVATEntry.Reset();
                            TempVATEntry.CalcSums(Amount, Base);
                            VATAmount := -TempVATEntry.Amount;
                            VATBase := -TempVATEntry.Base;
                            TempVATEntry.DeleteAll();
                        end else begin
                            VATEntry.CalcSums(Amount, Base);
                            VATAmount := -VATEntry.Amount;
                            VATBase := -VATEntry.Base;
                        end;

                    PmtDiscGiven := 0;
                    CustLedgEntry.SetCurrentKey("Closed by Entry No.");
                    CustLedgEntry.SetRange("Closed by Entry No.", "Entry No.");
                    if CustLedgEntry.Find('-') then
                        repeat
                            PmtDiscGiven := PmtDiscGiven - CustLedgEntry."Pmt. Disc. Given (LCY)";
                        until CustLedgEntry.Next() = 0;

                    ActualAmount := "Amount (LCY)" - PmtDiscGiven;

                    if not PrintGLDetails then begin
                        AmountLCY1 := "Amount (LCY)";
                        PmtDiscGiven1 := PmtDiscGiven;
                        ActualAmount1 := ActualAmount;
                        VatBase1 := VATBase;
                        VatAmount1 := VATAmount;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(VATAmount);
                    Clear(PmtDiscGiven);
                    Clear(VATBase);
                    Clear(ActualAmount);
                    CopyFilters(ReqCustLedgEntry);
                    SetRange("Posting Date", Date."Period Start");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                AmountLCY1 := 0;
                PmtDiscGiven1 := 0;
                ActualAmount1 := 0;
                VatBase1 := 0;
                VatAmount1 := 0;
            end;

            trigger OnPreDataItem()
            var
                PostingDateStart: Date;
                PostingDateEnd: Date;
            begin
                Clear(VATAmount);
                Clear(PmtDiscGiven);
                Clear(VATBase);
                Clear(ActualAmount);
                ReqCustLedgEntry.CopyFilter("Posting Date", "Period Start");

                if ReqCustLedgEntry.GetFilter("Posting Date") = '' then
                    Error(MissingDateRangeFilterErr);

                PostingDateStart := ReqCustLedgEntry.GetRangeMin("Posting Date");
                PostingDateEnd := CalcDate('<+1Y>', PostingDateStart);

                if ReqCustLedgEntry.GetRangeMax("Posting Date") > PostingDateEnd then
                    Error(MaxPostingDateErr);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintCustLedgerDetails; PrintCLDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Cust. Ledger Details';
                        ToolTip = 'Specifies if Cust. Ledger Details is printed';

                        trigger OnValidate()
                        begin
                            PrintCLDetailsOnAfterValidate();
                        end;
                    }
                    field(PrintGLEntryDetails; PrintGLDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print G/L Entry Details';
                        ToolTip = 'Specifies if G/L Entry Details are printed';

                        trigger OnValidate()
                        begin
                            PrintGLDetailsOnAfterValidate();
                        end;
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
        CustLedgFilter := ReqCustLedgEntry.GetFilters();
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        CustLedgFilter: Text;
        PmtDiscGiven: Decimal;
        VATAmount: Decimal;
        ActualAmount: Decimal;
        VATBase: Decimal;
        AmountLCY1: Decimal;
        PmtDiscGiven1: Decimal;
        VatBase1: Decimal;
        VatAmount1: Decimal;
        PrintGLDetails: Boolean;
        PrintCLDetails: Boolean;
        SecondStep: Boolean;
        ActualAmount1: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Day_Book_Cust__Ledger_EntryCaptionLbl: Label 'Day Book Cust. Ledger Entry';
        Cust__Ledger_Entry__Amount__LCY__CaptionLbl: Label 'Ledger Entry Amount';
        PmtDiscGiven_Control32CaptionLbl: Label 'Payment Discount Given';
        VATAmount_Control26CaptionLbl: Label 'VAT Amount';
        ActualAmount_Control39CaptionLbl: Label 'Actual Amount';
        VATBase_Control29CaptionLbl: Label 'VAT Base';
        PmtDiscGiven_Control32Caption_Control33Lbl: Label 'Payment Discount Given';
        Customer_NameCaptionLbl: Label 'Name';
        Cust__Ledger_Entry__Customer_No__CaptionLbl: Label 'Account No.';
        Cust__Ledger_Entry__Amount__LCY__Caption_Control24Lbl: Label 'Ledger Entry Amount';
        VATAmount_Control26Caption_Control27Lbl: Label 'VAT Amount';
        VATBase_Control29Caption_Control30Lbl: Label 'VAT Base';
        ActualAmount_Control39Caption_Control35Lbl: Label 'Actual Amount';
#pragma warning disable AA0470
        AllAmountsAreInLbl: Label 'All amounts are in %1.', Comment = 'All amounts are in GBP';
        TotalForCustLedgerEntryLbl: Label 'Total for  %1 : %2.', Comment = 'Total for Cust. Ledger Entry 3403  ';
        TotalForDatePeriodStartLbl: Label 'Total for %1.', Comment = 'Total for posting date 12122012';
#pragma warning restore AA0470
        MissingDateRangeFilterErr: Label 'Posting Date filter must be set.';
        MaxPostingDateErr: Label 'Posting Date period must not be longer than 1 year.';

    local procedure PrintGLDetailsOnAfterValidate()
    begin
        if PrintGLDetails then
            PrintCLDetails := true;
    end;

    local procedure PrintCLDetailsOnAfterValidate()
    begin
        if not PrintCLDetails then
            PrintGLDetails := false;
    end;
}

