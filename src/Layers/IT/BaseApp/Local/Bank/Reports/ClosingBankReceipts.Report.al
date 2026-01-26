// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

report 12171 "Closing Bank Receipts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Closing Bank Receipts';
    Permissions = TableData "Cust. Ledger Entry" = imd;
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(CustEntry1; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Due Date", "Customer No.", "Bank Receipt", "Bank Receipt Temp. No.", "Customer Bill No.") order(ascending) where("Document Type" = const(Payment), Open = const(true), "Bank Receipt" = const(true));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Customer No.", "Due Date";
            dataitem(CustEntry2; "Cust. Ledger Entry")
            {
                DataItemLink = "Document Type" = field("Document Type to Close"), "Document No." = field("Document No. to Close"), "Document Occurrence" = field("Document Occurrence to Close"), "Customer No." = field("Customer No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Document Occurrence", "Customer No.") order(ascending) where(Open = const(true), "Bank Receipt Issued" = const(true), "Customer Bill No." = filter(<> ''));

                trigger OnAfterGetRecord()
                var
                    ApplyUnapplyParameters: Record "Apply Unapply Parameters";
                    DocumentNo: Code[20];
                begin
                    CustLedgEntry.SetFilter("Entry No.", '%1|%2', CustEntry1."Entry No.", "Entry No.");
                    CustLedgEntry.ModifyAll("Applies-to ID", '');
                    CustEntrySetApplId.SetApplId(CustLedgEntry, CustEntry1, Format("Entry No."));

                    Commit();

                    Clear(CustEntryApplyPostedEntries);
                    CustEntryApplyPostedEntries.SetCheckDim(CheckDim);
                    CustLedgEntry.Get(CustEntry1."Entry No.");
                    DocumentNo := CustLedgEntry."Document No.";
                    if Confirmation then begin
                        if not Confirm(Text1130000, false, "Document Type", "Document No.") then
                            exit;
                        AskForDocNoAndApplnDate(DocumentNo, ClosePerDay);
                    end;
                    ApplyUnapplyParameters."Document No." := DocumentNo;
                    ApplyUnapplyParameters."Posting Date" := ClosePerDay;
                    CustEntryApplyPostedEntries.Apply(CustLedgEntry, ApplyUnapplyParameters);
                    if Confirmation then
                        Message(Text012);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Due Date" > ClosePerDay then
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(RiskPeriod; RiskPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Receipts Risk Period';
                        ToolTip = 'Specifies the bank receipts risk period.';

                        trigger OnValidate()
                        begin
                            DoCalcDate();
                        end;
                    }
                    field(ConfirmPerApplication; Confirmation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Confirm per Application';
                        ToolTip = 'Specifies the confirm per application.';
                    }
                    field(WorkDate; WorkDate())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Today';
                        Editable = false;
                        ToolTip = 'Specifies if the report is for today.';
                    }
                    field(ClosingDateForBankReceipts; ClosePerDay)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closingdate for Bank Receipts';
                        Editable = false;
                        ToolTip = 'Specifies the closing date.';
                    }
                    field(CheckDim; CheckDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Do Not Check Dimensions';
                        ToolTip = 'Specifies if you do not want to check the dimensions.';
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

    trigger OnInitReport()
    begin
        SalesSetup.Get();
        Clear(NULL);
        RiskPeriod := SalesSetup."Bank Receipts Risk Period";
        if RiskPeriod = NULL then
            Error(Text1033,
              SalesSetup.FieldCaption("Bank Receipts Risk Period"), SalesSetup.TableCaption());
        DoCalcDate();
    end;

    trigger OnPostReport()
    begin
        if not Confirmation then
            Window.Close();
    end;

    trigger OnPreReport()
    begin
        if not Confirmation then
            Window.Open(Text1034);
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustEntrySetApplId: Codeunit "Cust. Entry-SetAppl.ID";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        Window: Dialog;
        RiskPeriod: DateFormula;
        ClosePerDay: Date;
        Confirmation: Boolean;
        NULL: DateFormula;
        CheckDim: Boolean;
        Text1130000: Label 'Do you want to post the application of %1 %2?';
        Text012: Label 'The application was successfully posted.';
        Text1033: Label 'Please specify %1 in %2 before running this report.';
        Text1034: Label 'Posting application...';
#pragma warning disable AA0470
        ApplicationDateErr: Label 'The %1 entered must not be before the %1 on the %2.';
#pragma warning restore AA0470

    [Scope('OnPrem')]
    procedure DoCalcDate()
    var
        RiskPeriod2: DateFormula;
    begin
        Evaluate(RiskPeriod2, '-' + Format(RiskPeriod));
        ClosePerDay := CalcDate(RiskPeriod2, WorkDate());
    end;

    local procedure AskForDocNoAndApplnDate(DocumentNo: Code[20]; var ApplicationDate: Date)
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        NewApplyUnapplyParameters: Record "Apply Unapply Parameters";
        PostApplication: Page "Post Application";
    begin
        ApplyUnapplyParameters."Document No." := DocumentNo;
        ApplyUnapplyParameters."Posting Date" := ApplicationDate;
        PostApplication.SetParameters(ApplyUnapplyParameters);
        if ACTION::OK = PostApplication.RunModal() then begin
            PostApplication.GetParameters(NewApplyUnapplyParameters);
            if NewApplyUnapplyParameters."Posting Date" < ApplicationDate then
                Error(ApplicationDateErr, CustLedgEntry.FieldCaption("Posting Date"), ApplicationDate);
        end else
            exit;
        ApplicationDate := NewApplyUnapplyParameters."Posting Date";
    end;
}

