// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Foundation.Period;

report 15000004 "Delete rem. payment order"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Delete rem. payment order';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Remittance Payment Order"; "Remittance Payment Order")
        {
            DataItemTableView = sorting(Date);

            trigger OnAfterGetRecord()
            begin
                WindowCOunter := WindowCOunter + 1;
                Window.Update(1, Round(10000 * WindowCOunter / NumberOfWindows, 1));

                // make sure no Waiting journal lines in the payment order of type:export have status approved or sent.
                // payment orders of type:return can be deleted.
                if Type = Type::Export then begin
                    WaitingJournalLine.SetRange("Payment Order ID - Sent", ID);
                    WaitingJournalLine.SetFilter(
                      "Remittance Status", '%1|%2', WaitingJournalLine."Remittance Status"::Sent,
                      WaitingJournalLine."Remittance Status"::Approved);
                    if WaitingJournalLine.FindFirst() then
                        WaitingJournalLine.FieldError("Remittance Status");
                end;

                Delete(true);
            end;

            trigger OnPreDataItem()
            begin
                if StartDate < FirstDate then
                    Error(Text000, StartDate);
                if EndDate > LastDate then
                    Error(Text002, EndDate);

                SetRange(Date, StartDate, EndDate);
                if FindFirst() then begin
                    if not Confirm(Text003, false, Count) then
                        Error('');
                end else
                    Error(Text004);

                Window.Open(Text005);
                NumberOfWindows := Count;
                WindowCOunter := 0;
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start date';
                        ToolTip = 'Specifies the start date of the payment orders to be included in the report.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End date';
                        ToolTip = 'Specifies the end date of the payment order to be included in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            AccountingPeriod.SetRange(Closed, true);
            if not AccountingPeriod.FindFirst() then
                Error(Text007);
            FirstDate := AccountingPeriod."Starting Date";
            // Find the first open period, following the last closed period
            AccountingPeriod.FindLast();
            AccountingPeriod.SetRange(Closed);
            LastDate := AccountingPeriod."Starting Date";
            if AccountingPeriod.Next() > 0 then
                LastDate := ClosingDate(CalcDate('<-1D>', AccountingPeriod."Starting Date"));

            StartDate := FirstDate;
            EndDate := LastDate;
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'Only payment orders in closed accounting periods can be deleted.\Starting date %1 is prior to the first closed accounting period.';
        Text002: Label 'Only payment orders in closed accounting periods can be deleted.\Ending date %1 is after the last closed accounting period.';
        Text003: Label 'There are %1 payment orders in the period.\Delete?';
        Text004: Label 'There are no remittance payment orders in the period.';
        Text005: Label 'Deleting remittance payment order...\Deleting  @1@@@@@@@@@@@@@@@@@@@';
        Text007: Label 'Only the payment order in closed accounting periods can be closed.\Not all periods are closed.';
        AccountingPeriod: Record "Accounting Period";
        WaitingJournalLine: Record "Waiting Journal";
        Window: Dialog;
        StartDate: Date;
        EndDate: Date;
        FirstDate: Date;
        LastDate: Date;
        WindowCOunter: Integer;
        NumberOfWindows: Integer;
}

