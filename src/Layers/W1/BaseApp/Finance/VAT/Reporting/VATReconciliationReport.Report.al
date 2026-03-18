// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Enums;

/// <summary>
/// Generates reconciliation analysis between G/L entries and VAT entries for audit and compliance purposes.
/// Compares posted amounts across G/L and VAT ledgers to identify discrepancies and ensure data integrity.
/// </summary>
report 743 "VAT Reconciliation Report"
{
    ApplicationArea = VAT;
    Caption = 'VAT Reconciliation Report';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(GLEntry; "G/L Entry")
        {
            DataItemTableView = sorting("G/L Account No.", "Posting Date");
            RequestFilterFields = "G/L Account No.", "Posting Date";

            column(CompanyName; CompanyProperty.DisplayName())
            {
            }
            column(GLEntryFilters; TableCaption() + ': ' + GetFilters())
            {
            }
            column(ShowDetails; ShowIndividualTransaction)
            {
            }
            column(VATAmount_GLEntry; "VAT Amount")
            {
            }
            column(GLAccountNo_GLEntry; "G/L Account No.")
            {
            }
            column(GLAccountNoCaption_GLEntry; FieldCaption("G/L Account No."))
            {
            }
            column(PostingDate_GLEntry; Format("Posting Date"))
            {
            }
            column(DocumentNo_GLEntry; "Document No.")
            {
            }
            column(DocumentNoCaption_GLEntry; FieldCaption("Document No."))
            {
            }
            column(BaseAmountSalesVAT; BaseAmountSalesVAT)
            {
            }
            column(SalesVAT; SalesVAT)
            {
            }
            column(BaseAmountRevCharges; BaseAmountRevCharges)
            {
            }
            column(SalesVATRevCharges; SalesVATRevCharges)
            {
            }
            column(BaseAmountPurchVAT; BaseAmountPurchVAT)
            {
            }
            column(PurchVAT; PurchVAT)
            {
            }
            column(GLAccountName; GLAccount.Name)
            {
            }
            column(ShowTransWithoutVAT; ShowTransactionWithoutVAT)
            {
            }

            trigger OnAfterGetRecord()
            var
                GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
            begin
                ResetGlobalVariables();

                if (not ShowIndividualTransaction) and ((GLEntry."VAT Amount" = 0) and (not ShowTransactionWithoutVAT)) then
                    CurrReport.Skip();

                GLEntryVATEntryLink.SetRange("G/L Entry No.", GLEntry."Entry No.");
                if GLEntryVATEntryLink.IsEmpty() then
                    CurrReport.Skip();

                repeat
                    SetVATValueFromVATEntry(GLEntryVATEntryLink."VAT Entry No.");
                until GLEntryVATEntryLink.Next() = 0;

                GLAccount.Get("G/L Account No.");
            end;

            trigger OnPreDataItem()
            begin
                GLEntry.SetLoadFields("VAT Amount", "G/L Account No.", "Posting Date", "Document No.", "Transaction No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Gen. Posting Type");

                GLAccount.SetLoadFields("No.", Name);

                if not ShowTransactionWithoutVAT then
                    GLEntry.SetFilter("VAT Amount", '<>0');
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About VAT Reconciliation Report';
        AboutText = 'The **VAT Reconciliation Report** compares VAT calculated on documents with the amounts posted to the VAT G/L accounts. Use it for verifying that VAT entries align with general ledger balances before tax filing, ensuring accurate and compliant reporting.';

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(ShowDetails; ShowIndividualTransaction)
                    {
                        ApplicationArea = VAT;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies if you want to include individual transactions. If the check box is not selected, then only one accumulated total will be printed for each account.';
                    }
                    field(ShowTransWithoutVAT; ShowTransactionWithoutVAT)
                    {
                        ApplicationArea = VAT;
                        Caption = 'Show Transactions without VAT';
                        ToolTip = 'Specifies if you want to have transactions without VAT amounts printed in the report.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Finance/VAT/Reporting/VATReconciliationReport.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
    }

    labels
    {
        VATReconciliationCaption = 'VAT Reconciliation';
        PageCaption = 'Page';
        PostingDateCaption = 'Posting Date';
        BaseAmountSalesVATCaption = 'Base Amount Sales VAT';
        SalesVATCaption = 'Sales VAT';
        BaseAmountRevChargesCaption = 'Base Amount Reverse Charges';
        SalesVATRevChargesCaption = 'Sales VAT Reverse Charges';
        BaseAmountPurchVATCaption = 'Base Amount Purchase VAT';
        PurchVATCaption = 'Purchase VAT';
        TotalCaption = 'Total';
    }

    local procedure ResetGlobalVariables()
    begin
        BaseAmountRevCharges := 0;
        SalesVATRevCharges := 0;
        BaseAmountSalesVAT := 0;
        SalesVAT := 0;
        BaseAmountPurchVAT := 0;
        PurchVAT := 0;
    end;

    var
        GLAccount: Record "G/L Account";
        ShowIndividualTransaction: Boolean;
        ShowTransactionWithoutVAT: Boolean;
        BaseAmountRevCharges: Decimal;
        SalesVATRevCharges: Decimal;
        BaseAmountSalesVAT: Decimal;
        SalesVAT: Decimal;
        BaseAmountPurchVAT: Decimal;
        PurchVAT: Decimal;

    local procedure SetVATValueFromVATEntry(VATEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetLoadFields(Amount, "VAT Calculation Type", Base, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        if not VATEntry.Get(VATEntryNo) then
            exit;

        if VATEntry."VAT Calculation Type" = Enum::"Tax Calculation Type"::"Reverse Charge VAT" then begin
            BaseAmountRevCharges += VATEntry.Base + VATEntry."Non-Deductible VAT Base";
            SalesVATRevCharges += VATEntry.Amount + VATEntry."Non-Deductible VAT Amount";
            exit;
        end;

        case GLEntry."Gen. Posting Type" of
            Enum::"General Posting Type"::Sale:
                begin
                    BaseAmountSalesVAT += -VATEntry.Base;
                    SalesVAT += -VATEntry.Amount;
                end;
            Enum::"General Posting Type"::Purchase:
                begin
                    BaseAmountPurchVAT += VATEntry.Base + VATEntry."Non-Deductible VAT Base";
                    PurchVAT += VATEntry.Amount + VATEntry."Non-Deductible VAT Amount";
                end;
        end;
    end;
}