// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 303 "Vendor Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorRegister.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Register';
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
            column(PrintAmountsInLCY; PrintAmountsInLCYReq)
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
            column(VendDebitAmountLCY; VendDebitAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(VendCreditAmountLCY; VendCreditAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(VendAmountLCY; VendAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(Vendor_RegisterCaption; Vendor_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; Vendor_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; Vendor_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_No__Caption; "Vendor Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Vendor_Ledger_Entry_DescriptionCaption; "Vendor Ledger Entry".FieldCaption(Description))
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__Caption; "Vendor Ledger Entry".FieldCaption("Vendor No."))
            {
            }
            column(Vend_NameCaption; Vend_NameCaptionLbl)
            {
            }
            column(VendAmountCaption; VendAmountCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Applies_to_Doc__No__Caption; Vendor_Ledger_Entry__Applies_to_Doc__No__CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date_Caption; Vendor_Ledger_Entry__Due_Date_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Entry_No__Caption; "Vendor Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(G_L_Register__No__Caption; G_L_Register__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(VendDebitAmountLCYCaption; VendDebitAmountLCYCaptionLbl)
            {
            }
            column(VendCreditAmountLCYCaption; VendCreditAmountLCYCaptionLbl)
            {
            }
            column(VendAmountLCYCaption; VendAmountLCYCaptionLbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(Vendor_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Vendor_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Vendor_Ledger_Entry_Description; Description)
                {
                }
                column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
                {
                }
                column(Vend_Name; Vendor.Name)
                {
                }
                column(VendAmount; VendAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(Vendor_Ledger_Entry__Currency_Code_; "Currency Code")
                {
                }
                column(Vendor_Ledger_Entry__Applies_to_Doc__No__; "Applies-to Doc. No.")
                {
                }
                column(Vendor_Ledger_Entry__Due_Date_; Format("Due Date"))
                {
                }
                column(Vendor_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(VendDebitAmountLCY_Control61; VendDebitAmountLCY)
                {
                    AutoFormatType = 1;
                }
                column(VendCreditAmountLCY_Control64; VendCreditAmountLCY)
                {
                    AutoFormatType = 1;
                }
                column(VendAmountLCY_Control67; VendAmountLCY)
                {
                    AutoFormatType = 1;
                }
                column(VendDebitAmountLCY_Control61Caption; VendDebitAmountLCY_Control61CaptionLbl)
                {
                }
                column(VendCreditAmountLCY_Control64Caption; VendCreditAmountLCY_Control64CaptionLbl)
                {
                }
                column(VendAmountLCY_Control67Caption; VendAmountLCY_Control67CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not Vendor.Get("Vendor No.") then
                        Vendor.Init();

                    DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", "Entry No.");
                    DetailedVendorLedgEntry.CalcSums(Amount, "Amount (LCY)", "Debit Amount (LCY)", "Credit Amount (LCY)");

                    if PrintAmountsInLCYReq then begin
                        VendAmount := DetailedVendorLedgEntry."Amount (LCY)";
                        "Currency Code" := '';
                    end else
                        VendAmount := DetailedVendorLedgEntry.Amount;

                    VendAmountLCY := DetailedVendorLedgEntry."Amount (LCY)";
                    VendDebitAmountLCY := DetailedVendorLedgEntry."Debit Amount (LCY)";
                    VendCreditAmountLCY := DetailedVendorLedgEntry."Credit Amount (LCY)";

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
                    field(PrintAmountsInLCY; PrintAmountsInLCYReq)
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
        DetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
    end;

    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GLRegFilter: Text;
        VendAmount: Decimal;
        VendAmountLCY: Decimal;
        VendDebitAmountLCY: Decimal;
        VendCreditAmountLCY: Decimal;
        PrintAmountsInLCYReq: Boolean;
        Vendor_RegisterCaptionLbl: Label 'Vendor Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY.';
        Vendor_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Vendor_Ledger_Entry__Document_Type_CaptionLbl: Label 'Document Type';
        Vend_NameCaptionLbl: Label 'Name';
        VendAmountCaptionLbl: Label 'Original Amount';
        Vendor_Ledger_Entry__Applies_to_Doc__No__CaptionLbl: Label 'Applies-to Doc. No.';
        Vendor_Ledger_Entry__Due_Date_CaptionLbl: Label 'Due Date';
        G_L_Register__No__CaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
        VendDebitAmountLCYCaptionLbl: Label 'Debit (LCY)';
        VendCreditAmountLCYCaptionLbl: Label 'Credit (LCY)';
        VendAmountLCYCaptionLbl: Label 'Total (LCY)';
        VendDebitAmountLCY_Control61CaptionLbl: Label 'Debit (LCY)';
        VendCreditAmountLCY_Control64CaptionLbl: Label 'Credit (LCY)';
        VendAmountLCY_Control67CaptionLbl: Label 'Total (LCY)';

    procedure InitializeRequest(NewPrintAmountsInLCY: Boolean)
    begin
        PrintAmountsInLCYReq := NewPrintAmountsInLCY;
    end;

    local procedure ClearAmounts()
    begin
        Clear(VendAmountLCY);
        Clear(VendDebitAmountLCY);
        Clear(VendCreditAmountLCY);
    end;
}

