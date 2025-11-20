// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 103 "Customer Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerRegister.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Register';
    UsageCategory = ReportsAndAnalysis;

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
            column(PrintAmountsInLCY; PrintAmountsInLCY)
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
            column(CustDebitAmountLCY; CustDebitAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(CustCreditAmountLCY; CustCreditAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(CustAmountLCY; CustAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(Customer_RegisterCaption; Customer_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Posting_Date_Caption; Cust__Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_Type_Caption; Cust__Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Cust__Ledger_Entry_DescriptionCaption; "Cust. Ledger Entry".FieldCaption(Description))
            {
            }
            column(Cust__Ledger_Entry__Customer_No__Caption; "Cust. Ledger Entry".FieldCaption("Customer No."))
            {
            }
            column(Cust_NameCaption; Cust_NameCaptionLbl)
            {
            }
            column(CustAmountCaption; CustAmountCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Applies_to_Doc__No__Caption; Cust__Ledger_Entry__Applies_to_Doc__No__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Due_Date_Caption; Cust__Ledger_Entry__Due_Date_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Entry_No__Caption; "Cust. Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(G_L_Register__No__Caption; G_L_Register__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(CustDebitAmountLCYCaption; CustDebitAmountLCYCaptionLbl)
            {
            }
            column(CustCreditAmountLCYCaption; CustCreditAmountLCYCaptionLbl)
            {
            }
            column(CustAmountLCYCaption; CustAmountLCYCaptionLbl)
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(Cust__Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Cust__Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Cust__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Cust__Ledger_Entry_Description; Description)
                {
                }
                column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                {
                }
                column(Cust_Name; Cust.Name)
                {
                }
                column(CustAmount; CustAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(Cust__Ledger_Entry__Currency_Code_; "Currency Code")
                {
                }
                column(Cust__Ledger_Entry__Applies_to_Doc__No__; "Applies-to Doc. No.")
                {
                }
                column(Cust__Ledger_Entry__Due_Date_; Format("Due Date"))
                {
                }
                column(Cust__Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(CustDebitAmountLCY_Control65; CustDebitAmountLCY)
                {
                    AutoFormatType = 1;
                }
                column(CustCreditAmountLCY_Control68; CustCreditAmountLCY)
                {
                    AutoFormatType = 1;
                }
                column(CustAmountLCY_Control71; CustAmountLCY)
                {
                    AutoFormatType = 1;
                }
                column(CustDebitAmountLCY_Control65Caption; CustDebitAmountLCY_Control65CaptionLbl)
                {
                }
                column(CustCreditAmountLCY_Control68Caption; CustCreditAmountLCY_Control68CaptionLbl)
                {
                }
                column(CustAmountLCY_Control71Caption; CustAmountLCY_Control71CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not Cust.Get("Customer No.") then
                        Cust.Init();

                    DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", "Entry No.");
                    DtldCustLedgEntry.CalcSums(Amount, "Amount (LCY)", "Debit Amount (LCY)", "Credit Amount (LCY)");

                    if PrintAmountsInLCY then begin
                        CustAmount := DtldCustLedgEntry."Amount (LCY)";
                        "Currency Code" := '';
                    end else
                        CustAmount := DtldCustLedgEntry.Amount;

                    CustAmountLCY := DtldCustLedgEntry."Amount (LCY)";
                    CustDebitAmountLCY := DtldCustLedgEntry."Debit Amount (LCY)";
                    CustCreditAmountLCY := DtldCustLedgEntry."Credit Amount (LCY)";

                    if ("Document Type" = "Document Type"::Payment) or ("Document Type" = "Document Type"::Refund) then
                        "Due Date" := 0D;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");
                    ClearAmounts();
                end;
            }

            trigger OnPreDataItem()
            begin
                ClearAmounts();
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
                    field(ShowAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
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
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::"Initial Entry");
    end;

    var
        Cust: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLRegFilter: Text;
        CustAmount: Decimal;
        CustAmountLCY: Decimal;
        CustDebitAmountLCY: Decimal;
        CustCreditAmountLCY: Decimal;
        PrintAmountsInLCY: Boolean;
        Customer_RegisterCaptionLbl: Label 'Customer Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY';
        Cust__Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Cust__Ledger_Entry__Document_Type_CaptionLbl: Label 'Document Type';
        Cust_NameCaptionLbl: Label 'Name';
        CustAmountCaptionLbl: Label 'Original Amount';
        Cust__Ledger_Entry__Applies_to_Doc__No__CaptionLbl: Label 'Applies-to Doc. No.';
        Cust__Ledger_Entry__Due_Date_CaptionLbl: Label 'Due Date';
        G_L_Register__No__CaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
        CustDebitAmountLCYCaptionLbl: Label 'Debit (LCY)';
        CustCreditAmountLCYCaptionLbl: Label 'Credit (LCY)';
        CustAmountLCYCaptionLbl: Label 'Total (LCY)';
        CustDebitAmountLCY_Control65CaptionLbl: Label 'Debit (LCY)';
        CustCreditAmountLCY_Control68CaptionLbl: Label 'Credit (LCY)';
        CustAmountLCY_Control71CaptionLbl: Label 'Total (LCY)';

    procedure InitializeRequest(ShowAmountInLCY: Boolean)
    begin
        PrintAmountsInLCY := ShowAmountInLCY;
    end;

    local procedure ClearAmounts()
    begin
        Clear(CustAmountLCY);
        Clear(CustDebitAmountLCY);
        Clear(CustCreditAmountLCY);
    end;
}

