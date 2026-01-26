// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Sales.Receivables;

report 10746 "Not Fully Applied Cash Pmts."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/NotFullyAppliedCashPmts.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Not Fully Applied Cash Payments';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            CalcFields = "Amount (LCY)";
            DataItemTableView = sorting("Customer No.", "Document Type", "Document Situation", "Document Status") where("Document Type" = const(Payment), Open = const(true));
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
            {
            }
            column(Cust__Ledger_Entry__Document_Date_; "Document Date")
            {
            }
            column(Cust__Ledger_Entry__Document_No__; "Document No.")
            {
            }
            column(Cust__Ledger_Entry_Description; Description)
            {
            }
            column(Cust__Ledger_Entry__Amount__LCY__; "Amount (LCY)")
            {
            }
            column(Cust__Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
            {
            }
            column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Open_Cash_PaymentsCaption; Open_Cash_PaymentsCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Customer_No__Caption; FieldCaption("Customer No."))
            {
            }
            column(Cust__Ledger_Entry__Document_Date_Caption; FieldCaption("Document Date"))
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(Cust__Ledger_Entry_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Cust__Ledger_Entry__Amount__LCY__Caption; FieldCaption("Amount (LCY)"))
            {
            }
            column(Cust__Ledger_Entry__Remaining_Amt___LCY__Caption; FieldCaption("Remaining Amt. (LCY)"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Bal. Account No." <> '' then begin
                    if not IsCashAccount(RetrieveBalAccount("Cust. Ledger Entry")) then
                        CurrReport.Skip();
                end else
                    if not HasCashAccount("Cust. Ledger Entry") then
                        CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                "Cust. Ledger Entry".SetRange("Document Date", FromDate, ToDate);
                "Cust. Ledger Entry".SetFilter(
                  "Bal. Account Type",
                  '%1|%2',
                  "Cust. Ledger Entry"."Bal. Account Type"::"G/L Account",
                  "Cust. Ledger Entry"."Bal. Account Type"::"Bank Account");
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
                    field(FiscalYear; FiscalYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Year';
                        Numeric = true;
                        ToolTip = 'Specifies the year of the reporting period. It must be 4 digits without spaces or special characters.';

                        trigger OnValidate()
                        begin
                            if StrLen(FiscalYear) <> MaxStrLen(FiscalYear) then
                                Error(Text000, MaxStrLen(FiscalYear));
                        end;
                    }
                    field(ColumnGLAcc; ColumnGLAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'GL Acc. for Payments in Cash';
                        Editable = false;
                        ToolTip = 'Specifies one or more on general ledger accounts for cash payments. When you export the data to a declaration file, the Amount Received in Cash field in the file contains the accumulated value for the selected general ledger accounts. If you do not select any general ledger accounts, then type 2 lines for payments in cash will not be created.';

                        trigger OnAssistEdit()
                        var
                            GLAccSelectionBuf: Record "G/L Account Buffer";
                        begin
                            GLAccSelectionBuf.SetGLAccSelectionMultiple(ColumnGLAcc, FilterString);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if FiscalYear = '' then
                FiscalYear := '0000';
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if FilterString = '' then
            GetFilterStringFromColumnGLAcc();
        if DelChr(FilterString, '<>') = '' then
            exit;

        if FiscalYear = '' then
            Error(Text002);

        NoOfAccounts := RetrieveGLAccount(FilterString);
        Evaluate(NumFiscalYear, FiscalYear);
        if NumFiscalYear = 0 then
            Error(Text001);
        FromDate := DMY2Date(1, 1, NumFiscalYear);
        ToDate := DMY2Date(31, 12, NumFiscalYear);
    end;

    var
        Text000: Label 'Fiscal Year must be %1 digits without spaces or digital characters.';
        ColumnGLAcc: Text[250];
        FilterString: Text[250];
        FiscalYear: Code[4];
        Text001: Label 'Incorrect Fiscal Year.';
        NumFiscalYear: Integer;
        FromDate: Date;
        ToDate: Date;
        Text002: Label 'Fiscal Year must be entered.';
        NoOfAccounts: Integer;
        FilterArray: array[50] of Text[30];
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Open_Cash_PaymentsCaptionLbl: Label 'Not Fully Applied Cash Payments';

    local procedure GetFilterStringFromColumnGLAcc()
    var
        GLAccCode: Text[250];
        Position: Integer;
    begin
        GLAccCode := ColumnGLAcc;
        repeat
            Position := StrPos(GLAccCode, ';');
            if GLAccCode <> '' then begin
                if Position <> 0 then begin
                    FilterString := FilterString + CopyStr(GLAccCode, 1, Position - 1);
                    GLAccCode := CopyStr(GLAccCode, Position + 1);
                end else begin
                    FilterString := FilterString + CopyStr(GLAccCode, 1);
                    GLAccCode := '';
                end;
                if GLAccCode <> '' then
                    FilterString := FilterString + '|';
            end;
        until GLAccCode = '';
    end;

    local procedure RetrieveGLAccount(StringFilter: Text[250]) NoOfAcc: Integer
    var
        CommaPos: Integer;
        j: Integer;
    begin
        CommaPos := 1;
        j := 1;
        while CommaPos <> 0 do begin
            CommaPos := StrPos(StringFilter, '|');
            if CommaPos = 0 then
                FilterArray[j] := StringFilter
            else begin
                FilterArray[j] := CopyStr(StringFilter, 1, CommaPos - 1);
                StringFilter := DelStr(StringFilter, 1, CommaPos);
            end;
            j += 1;
        end;
        NoOfAcc := j - 1;
    end;

    local procedure IsCashAccount(GLAccountNo: Text[20]): Boolean
    var
        i: Integer;
    begin
        for i := 1 to NoOfAccounts do
            if GLAccountNo = FilterArray[i] then
                exit(true);
        exit(false);
    end;

    local procedure RetrieveBalAccount(CustLedgerEntry: Record "Cust. Ledger Entry"): Text[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        case CustLedgerEntry."Bal. Account Type" of
            CustLedgerEntry."Bal. Account Type"::"G/L Account":
                exit(CustLedgerEntry."Bal. Account No.");
            CustLedgerEntry."Bal. Account Type"::"Bank Account":
                begin
                    BankAccount.Get(CustLedgerEntry."Bal. Account No.");
                    BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
                    exit(BankAccountPostingGroup."G/L Account No.");
                end;
        end;
    end;

    local procedure HasCashAccount(CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Reset();
        GLEntry.SetRange("Transaction No.", CustLedgerEntry."Transaction No.");
        GLEntry.SetFilter("G/L Account No.", FilterString);
        if GLEntry.FindFirst() then
            exit(true);
        exit(false);
    end;
}

