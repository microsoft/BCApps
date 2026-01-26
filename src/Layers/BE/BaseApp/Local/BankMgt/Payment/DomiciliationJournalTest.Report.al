// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 2000020 "Domiciliation Journal - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Payment/DomiciliationJournalTest.rdlc';
    Caption = 'Domiciliation Journal - Test';

    dataset
    {
        dataitem("Domiciliation Journal Batch"; "Domiciliation Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(Name_DomiciliationJnlBatch; Name)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(DomiciliationJnlBatchJnlTempName; "Domiciliation Journal Batch"."Journal Template Name")
                {
                }
                column(DomiciliationJnlBatchName; "Domiciliation Journal Batch".Name)
                {
                }
                column(OutputNo; OutputNo)
                {
                }
                column(BatchName; BatchName)
                {
                }
                column(DomiciliationJnlLineDomJnlLineFilter; "Domiciliation Journal Line".TableCaption + ': ' + DomJnlLineFilter)
                {
                }
                column(DomJnlLineFilter1; DomJnlLineFilter1)
                {
                }
                column(DomiciliationJnllTestReportCaption; DomiciliationJnllTestReportCaptionLbl)
                {
                }
                column(PageCaption1; PageCaptionLbl)
                {
                }
                column(DomiciliationJnlJnlTempNameCaption; "Domiciliation Journal Batch".FieldCaption("Journal Template Name"))
                {
                }
                column(JnlBatchCaption; JnlBatchCaptionLbl)
                {
                }
                column(PageCaption; PageCaptionLbl)
                {
                }
                column(NoCaption; NoCaptionLbl)
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(Message1Caption; Message1CaptionLbl)
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(PmtDiscPossibleCaption; PmtDiscPossibleCaptionLbl)
                {
                }
                column(ReferenceCaption; ReferenceCaptionLbl)
                {
                }
                column(DueDateCaption; DueDateCaptionLbl)
                {
                }
                column(PmtDiscDateCaption; PmtDiscDateCaptionLbl)
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                dataitem("Domiciliation Journal Line"; "Domiciliation Journal Line")
                {
                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                    DataItemLinkReference = "Domiciliation Journal Batch";
                    DataItemTableView = sorting("Customer No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
                    RequestFilterFields = "Posting Date";
                    column(PostingDateFormatted_DomiciliationJnlLine; Format("Posting Date"))
                    {
                    }
                    column(AccName; AccName)
                    {
                    }
                    column(Message1_DomiciliationJnlLine; "Message 1")
                    {
                    }
                    column(Amount_DomiciliationJnlLine; Amount)
                    {
                    }
                    column(PmtDiscPossible_DomiciliationJnlLine; "Pmt. Disc. Possible")
                    {
                    }
                    column(Reference_DomiciliationJnlLine; Reference)
                    {
                    }
                    column(DueDate1; Format(DueDate[1]))
                    {
                    }
                    column(DueDate2; Format(DueDate[2]))
                    {
                    }
                    column(PostingDate_DomiciliationJnlLine; "Posting Date")
                    {
                    }
                    column(CustomerNo1; CustomerNo1)
                    {
                    }
                    column(Jlpostingdate; Jlpostingdate)
                    {
                    }
                    column(TotalAmount; TotalAmount)
                    {
                    }
                    column(TotalPmtDiscPossible; Pmt_Disc_Possible)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    column(TotalLCYCaption; TotalLCYCaptionLbl)
                    {
                    }
                    column(JournalBatchName_DomiciliationJnlLine; "Journal Batch Name")
                    {
                    }
                    column(CustomerNo_DomiciliationJnlLine; "Customer No.")
                    {
                    }
                    dataitem(DimensionLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) order(ascending) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(NumberInt; Number)
                        {
                        }
                        column(DimensionsCaption; DimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimensionSetEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText, DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimensionSetEntry.Next() = 0;
                        end;

                        trigger OnPostDataItem()
                        begin
                            TotalAmount := TotalAmount + "Domiciliation Journal Line".Amount;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();
                            DimensionSetEntry.SetRange("Dimension Set ID", "Domiciliation Journal Line"."Dimension Set ID");
                        end;
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorMsgNumber; ErrorMsg[Number])
                        {
                        }
                        column(CustCurrencyCode; Cust."Currency Code")
                        {
                        }
                        column(ErrorMsgNumberCaption; WarningCaptionLbl)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCount := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCount);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        DimMgt: Codeunit DimensionManagement;
                        TableID: array[10] of Integer;
                        No: array[10] of Code[20];
                    begin
                        CustomerNo1 := TempCustomerNo;
                        TempCustomerNo := "Customer No.";
                        OutputNo := OutputNo + 1;
                        Pmt_Disc_Possible := Pmt_Disc_Possible + "Pmt. Disc. Possible";

                        Clear(DueDate);
                        CustLedgEntry.SetCurrentKey("Document No.");
                        CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                        CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                        CustLedgEntry.SetRange("Customer No.", "Customer No.");
                        if CustLedgEntry.FindFirst() then begin
                            DueDate[1] := CustLedgEntry."Due Date";
                            if CustLedgEntry."Remaining Pmt. Disc. Possible" <> 0 then
                                DueDate[2] := CustLedgEntry."Pmt. Discount Date";
                            if CustLedgEntry.Open = false then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    Format("Applies-to Doc. Type", 0), "Applies-to Doc. No."));
                        end;
                        if CustNo <> "Customer No." then begin
                            AccName := '';
                            if not ("Customer No." = '') then begin
                                if "Pmt. Disc. Possible" * Amount < 0 then
                                    AddError(
                                      StrSubstNo(
                                        Text001, FieldCaption("Pmt. Disc. Possible"), FieldCaption(Amount)));

                                if "Customer No." <> '' then
                                    CheckCustomer("Domiciliation Journal Line");
                            end;
                        end;
                        if "Bank Account No." <> '' then
                            CheckBankAccount("Domiciliation Journal Line");

                        // mod 97 test
                        if Reference <> '' then
                            if not PaymJnlManagement.Mod97Test(Reference) then
                                AddError(StrSubstNo(Text002, Reference));

                        DimensionSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                        if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                            AddError(DimMgt.GetDimCombErr());

                        TableID[1] := DATABASE::Customer;
                        No[1] := "Customer No.";
                        TableID[2] := DATABASE::"Bank Account";
                        No[2] := "Bank Account No.";
                        if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                            AddError(DimMgt.GetDimValuePostingErr());

                        Jlpostingdate := FieldNo("Posting Date");
                        CustNo := "Customer No.";
                    end;

                    trigger OnPreDataItem()
                    begin
                        DomJnlTemplate.Get("Domiciliation Journal Batch"."Journal Template Name");
                        DomJnlLine.Reset();
                        DomJnlLine.CopyFilters("Domiciliation Journal Line");
                        CustNo := "Domiciliation Journal Line"."Customer No.";
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                BatchName := "Domiciliation Journal Batch".Name;
                Pmt_Disc_Possible := 0;
                TotalAmount := 0;
            end;

            trigger OnPreDataItem()
            begin
                OutputNo := 0;
                TempCustomerNo := ' ';
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
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
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
        DomJnlLineFilter := "Domiciliation Journal Line".GetFilters();
    end;

    var
        Text000: Label 'Customer ledger entry %1 %2 is not open.', Comment = 'Parameter 1 - document type ( ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund), 2 - document number.';
        Text001: Label '%1 must have the same sign as %2.';
        Text002: Label 'Reference %1 fails the MOD97 test.';
        Text003: Label 'Customer %1 does not exist.';
        Text004: Label 'The Blocked field must be blank or Ship for customer %1.';
        PrivacyBlockedErr: Label 'Privacy Blocked field must be No for customer %1.', Comment = '%1 = customer number';
        Text005: Label 'Currency Code must always be local currency.';
        Text006: Label 'Domiciliation number is empty for customer %1.';
        Text007: Label 'Domiciliation number %1 fails the MOD97 test.';
        DomJnlLine: Record "Domiciliation Journal Line";
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAcc: Record "Bank Account";
        DomJnlTemplate: Record "Domiciliation Journal Template";
        DimensionSetEntry: Record "Dimension Set Entry";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        DomJnlManagement: Codeunit DomiciliationJnlManagement;
        DomJnlLineFilter: Text[250];
        AccName: Text[100];
        ErrorCount: Integer;
        ErrorMsg: array[50] of Text[250];
        CustNo: Code[20];
        DueDate: array[2] of Date;
        DimText: Text[120];
        OldDimText: Text[120];
        ShowDim: Boolean;
        Continue: Boolean;
        OutputNo: Integer;
        BatchName: Text[30];
        CustomerNo1: Text[30];
        Jlpostingdate: Integer;
        DomJnlLineFilter1: Text[30];
        TotalAmount: Decimal;
        TempCustomerNo: Text[30];
        Pmt_Disc_Possible: Decimal;
        Text008: Label 'The Blocked field must be No for bank account %1.';
        Text009: Label 'Bank account %1 does not exist.';
        DomiciliationJnllTestReportCaptionLbl: Label 'Domiciliation Journal - Test Report';
        JnlBatchCaptionLbl: Label 'Journal Batch';
        PageCaptionLbl: Label 'Page';
        NoCaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        Message1CaptionLbl: Label 'Message 1';
        AmountCaptionLbl: Label 'Amount';
        PmtDiscPossibleCaptionLbl: Label 'Pmt. Disc. Possible';
        ReferenceCaptionLbl: Label 'Reference';
        DueDateCaptionLbl: Label 'Due Date';
        PmtDiscDateCaptionLbl: Label 'Pmt. Disc. Date';
        PostingDateCaptionLbl: Label 'Posting Date';
        TotalCaptionLbl: Label 'TOTAL', Comment = 'Total';
        TotalLCYCaptionLbl: Label 'TOTAL (LCY)', Comment = 'Total (LCY)';
        DimensionsCaptionLbl: Label 'Dimensions';
        WarningCaptionLbl: Label 'Warning !';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCount := ErrorCount + 1;
        ErrorMsg[ErrorCount] := Text;
    end;

    local procedure CheckCustomer(var DomicJnlLine: Record "Domiciliation Journal Line")
    begin
        if not Cust.Get(DomicJnlLine."Customer No.") then
            AddError(StrSubstNo(Text003, DomicJnlLine."Customer No."))
        else begin
            AccName := Cust.Name;

            if Cust."Privacy Blocked" then
                AddError(StrSubstNo(PrivacyBlockedErr, DomicJnlLine."Customer No."));

            if Cust.Blocked in [Cust.Blocked::All, Cust.Blocked::Invoice] then
                AddError(StrSubstNo(Text004, DomicJnlLine."Customer No."));
            if Cust."Currency Code" <> '' then
                AddError(Text005);

            if Cust."Domiciliation No." = '' then
                AddError(
                  StrSubstNo(Text006, DomicJnlLine."Customer No."))
            else
                if not DomJnlManagement.CheckDomiciliationNo(Cust."Domiciliation No.") then
                    AddError(StrSubstNo(Text007, Cust."Domiciliation No."))
        end;
    end;

    local procedure CheckBankAccount(var DomicJnlLine: Record "Domiciliation Journal Line")
    begin
        if not BankAcc.Get(DomicJnlLine."Bank Account No.") then
            AddError(StrSubstNo(Text009, DomicJnlLine."Bank Account No."))
        else
            if BankAcc.Blocked then
                AddError(StrSubstNo(Text008, DomicJnlLine."Bank Account No."));
    end;
}

