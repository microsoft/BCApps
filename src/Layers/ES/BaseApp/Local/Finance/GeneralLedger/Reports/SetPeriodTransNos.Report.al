// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Period;
using System.Utilities;

report 10700 "Set Period Trans. Nos."
{
    Caption = 'Set Period Trans. Nos.';
    Permissions = TableData "G/L Entry" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 10));
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("Posting Date", "Transaction No.");
                RequestFilterFields = "Posting Date";

                trigger OnAfterGetRecord()
                begin
                    repeat
                        SetRange("Posting Date", "Posting Date");
                        repeat
                            SetRange("Transaction No.", "Transaction No.");
                            ModifyAll("Period Trans. No.", CurrPeriodTransNo, false);
                            SetFilter("Transaction No.", '>%1', "Transaction No.");
                            CurrPeriodTransNo += 1;
                        until Next() = 0;

                        SetRange("Transaction No.");
                        if "Posting Date" = NormalDate(CurrToDate) then
                            SetRange("Posting Date", CurrToDate, CurrToDate)
                        else
                            SetRange("Posting Date", CalcDate('<1D>', "Posting Date"), CurrToDate);
                    until Next() = 0;
                end;

                trigger OnPostDataItem()
                begin
                    if not EndReached then begin
                        FromDate := NormalDate(CalcDate('<1D>', CurPeriodLastDate));
                        CurrPeriodTransNo := 2;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Period.SetFilter("Starting Date", '> %1', FromDate);
                    Period.SetRange("New Fiscal Year", true);
                    if not Period.FindFirst() then
                        CurPeriodLastDate := ToDate
                    else
                        CurPeriodLastDate := ClosingDate(CalcDate('<-1D>', Period."Starting Date"));
                    if CurPeriodLastDate >= ToDate then begin
                        CurrToDate := ToDate;
                        EndReached := true
                    end else
                        CurrToDate := CurPeriodLastDate;
                    SetRange("Posting Date", FromDate, CurrToDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if EndReached then
                    CurrReport.Break();
            end;

            trigger OnPreDataItem()
            var
                GLEntry2: Record "G/L Entry";
            begin
                Period.Reset();
                Period.SetRange("New Fiscal Year", true);
                Period.FindFirst();
                if Period."Starting Date" > FromDate then
                    FromDate := Period."Starting Date";
                Period.FindLast();
                if Period."Starting Date" < FromDate then
                    FromDate := Period."Starting Date";

                "G/L Entry".SetCurrentKey("Posting Date", "Transaction No.");
                "G/L Entry".SetRange("Posting Date", FromDate, ToDate);
                if not "G/L Entry".FindFirst() then
                    CurrReport.Break();
                GLEntry2.SetCurrentKey("Posting Date", "Transaction No.");
                GLEntry2.FindFirst();
                if "G/L Entry"."Entry No." = GLEntry2."Entry No." then
                    CurrPeriodTransNo := 1
                else begin
                    Period.SetRange("Starting Date", FromDate);
                    if Period.FindFirst() then
                        CurrPeriodTransNo := 2
                    else begin
                        GLEntry2.SetFilter("Posting Date", '< %1', FromDate);
                        GLEntry2.FindLast();
                        CurrPeriodTransNo := GLEntry2."Period Trans. No." + 1;
                    end;
                end;

                EndReached := false;
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        FromDate := "G/L Entry".GetRangeMin("Posting Date");
        ToDate := ClosingDate("G/L Entry".GetRangeMax("Posting Date"));
    end;

    var
        Period: Record "Accounting Period";
        FromDate: Date;
        ToDate: Date;
        CurPeriodLastDate: Date;
        CurrToDate: Date;
        EndReached: Boolean;
        CurrPeriodTransNo: Integer;
}

