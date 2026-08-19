// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

report 6951 "Expense Report Cover Page"
{
    DefaultRenderingLayout = "ExpenseReportCoverPage.rdlc";
    Caption = 'Expense Report Cover Page';
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem("Expense Report Header"; "Expense Report Header")
        {
            RequestFilterFields = "No.";
            CalcFields = "Amount (LCY)", "Reimbursable Amount (LCY)", "Refundable Amount (LCY)";

            column(ReportTitleLbl; ReportTitleLbl)
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(CompanyAddress2; CompanyAddress[2])
            {
            }
            column(CompanyAddress3; CompanyAddress[3])
            {
            }
            column(CompanyAddress4; CompanyAddress[4])
            {
            }
            column(CompanyAddress5; CompanyAddress[5])
            {
            }
            column(CompanyAddress6; CompanyAddress[6])
            {
            }
            column(CompanyAddress7; CompanyAddress[7])
            {
            }
            column(CompanyAddress8; CompanyAddress[8])
            {
            }
            column(ExpenseReportNo; "No.")
            {
            }
            column(ExpenseUserName; "Expense User Name")
            {
            }
            column(ExpenseReportDate; "Expense Report Date")
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            column(Description; Description)
            {
            }
            column(AntiCorruptionAttestation; "Anti-Corruption Attestation")
            {
            }
            column(AntiCorruptionDescription; "Anti-Corruption Description")
            {
            }
            column(TotalAmountLCY; "Amount (LCY)")
            {
            }
            column(TotalReimbursableAmountLCY; "Reimbursable Amount (LCY)")
            {
            }
            column(TotalPaidByCompanyLCY; TotalPaidByCompanyLCY)
            {
            }
            column(TotalNonRefundableAmountLCY; TotalNonRefundableAmountLCY)
            {
            }
            column(TotalRefundableAmountLCY; TotalRefundableAmountLCY)
            {
            }
            column(CurrencyCode; "Reimbursement Currency Code")
            {
            }
            column(SubmittedBy; "Expense User Name")
            {
            }
            column(ApprovedBy; "Approver Expense User ID")
            {
            }
            column(ExpenseReportNoLbl; ExpenseReportNoLbl)
            {
            }
            column(ExpenseUserNameLbl; "Expense Report Header".FieldCaption("Expense User Name"))
            {
            }
            column(ExpenseReportDateLbl; "Expense Report Header".FieldCaption("Expense Report Date"))
            {
            }
            column(PostingDateLbl; "Expense Report Header".FieldCaption("Posting Date"))
            {
            }
            column(DescriptionLbl; "Expense Report Header".FieldCaption(Description))
            {
            }
            column(AntiCorruptionAttestationLbl; AntiCorruptionAttestationLbl)
            {
            }
            column(AntiCorruptionDescriptionLbl; AntiCorruptionDescriptionLbl)
            {
            }
            column(TotalAmountLCYLbl; TotalAmountLCYLbl)
            {
            }
            column(TotalReimbursableAmountLCYLbl; TotalReimbursableAmountLCYLbl)
            {
            }
            column(TotalPaidByCompanyLCYLbl; TotalPaidByCompanyLCYLbl)
            {
            }
            column(TotalNonRefundableAmountLCYLbl; TotalNonRefundableAmountLCYLbl)
            {
            }
            column(TotalRefundableAmountLCYLbl; TotalRefundableAmountLCYLbl)
            {
            }
            column(CurrencyCodeLbl; ExpenseReportLine.FieldCaption("Expense Currency Code"))
            {
            }
            column(SubmittedByLbl; SubmittedByLbl)
            {
            }
            column(ApprovedByLbl; ApprovedByLbl)
            {
            }
            column(Page_Lbl; PageLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                TotalNonRefundableAmountLCY := GetTotalNonRefundableAmountLCY("Expense Report Header"."No.");
                TotalPaidByCompanyLCY := GetTotalPaidByCompanyLCY("Expense Report Header"."No.");
                TotalRefundableAmountLCY := "Refundable Amount (LCY)";
            end;
        }
    }
    rendering
    {
        layout("ExpenseReportCoverPage.rdlc")
        {
            Type = RDLC;
            Caption = 'Expense Report Cover Page';
            LayoutFile = 'src/ExpenseReport/Reports/ExpenseReportCoverPage.rdlc';
            Summary = 'Cover page for Expense Report with header and totals.';
        }
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        FormatAddress.Company(CompanyAddress, CompanyInformation);
    end;

    var
        CompanyInformation: Record "Company Information";
        ExpenseReportLine: Record "Expense Report Line";
        FormatAddress: Codeunit "Format Address";
        CompanyAddress: array[8] of Text[100];
        TotalPaidByCompanyLCY: Decimal;
        TotalNonRefundableAmountLCY: Decimal;
        TotalRefundableAmountLCY: Decimal;
        ReportTitleLbl: Label 'Expense Report';
        ExpenseReportNoLbl: Label 'Expense Report No.';
        AntiCorruptionAttestationLbl: Label 'Anti-Corruption Attestation';
        AntiCorruptionDescriptionLbl: Label 'Anti-Corruption Description';
        TotalAmountLCYLbl: Label 'Total Amount (LCY)';
        TotalReimbursableAmountLCYLbl: Label 'Total Reimbursable Amount (LCY)';
        TotalPaidByCompanyLCYLbl: Label 'Total Amount Paid by Company (LCY)';
        TotalNonRefundableAmountLCYLbl: Label 'Total Non-refundable Amount (LCY)';
        TotalRefundableAmountLCYLbl: Label 'Total Refundable Amount (LCY)';
        SubmittedByLbl: Label 'Submitted By';
        ApprovedByLbl: Label 'Approver';
        PageLbl: Label 'Page';

    local procedure GetTotalNonRefundableAmountLCY(DocumentNo: Code[20]): Decimal
    begin
        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetRange(Refundable, false);
        ExpenseReportLine.CalcSums("Amount (LCY)");
        exit(ExpenseReportLine."Amount (LCY)");
    end;

    local procedure GetTotalPaidByCompanyLCY(DocumentNo: Code[20]): Decimal
    begin
        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetFilter("Reimbursement Type", '<>%1', ExpenseReportLine."Reimbursement Type"::"Employee Paid");
        ExpenseReportLine.CalcSums("Amount (LCY)");
        exit(ExpenseReportLine."Amount (LCY)");
    end;
}