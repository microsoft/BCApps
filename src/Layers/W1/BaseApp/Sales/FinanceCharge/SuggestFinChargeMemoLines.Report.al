// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Sales.Receivables;
using System.Utilities;

report 192 "Suggest Fin. Charge Memo Lines"
{
    Caption = 'Suggest Fin. Charge Memo Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Finance Charge Memo Header"; "Finance Charge Memo Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Finance Charge Memo';

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                Clear(MakeFinChrgMemo);
                MakeFinChrgMemo.SuggestLines("Finance Charge Memo Header", CustLedgEntry);
                if NoOfRecords = 1 then begin
                    MakeFinChrgMemo.Code();
                    Mark := false;
                end else begin
                    NewDateTime := CurrentDateTime;
                    if (NewDateTime - OldDateTime > 100) or (NewDateTime < OldDateTime) then begin
                        NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
                        if NewProgress <> OldProgress then begin
                            Window.Update(1, NewProgress * 100);
                            OldProgress := NewProgress;
                        end;
                        OldDateTime := CurrentDateTime;
                    end;
                    Mark := not MakeFinChrgMemo.Run();
                end;
            end;

            trigger OnPostDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                Commit();
                Window.Close();
                MarkedOnly := true;
                if FindFirst() then
                    if ConfirmManagement.GetResponse(Text002, true) then
                        PAGE.RunModal(0, "Finance Charge Memo Header");
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
                if NoOfRecords = 1 then
                    Window.Open(Text000)
                else begin
                    Window.Open(Text001);
                    OldDateTime := CurrentDateTime;
                end;
            end;
        }
        dataitem(CustLedgEntry2; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Customer No.");
            RequestFilterFields = "Document Type";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        CustLedgEntry.Copy(CustLedgEntry2);
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        MakeFinChrgMemo: Codeunit "FinChrgMemo-Make";
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewDateTime: DateTime;
        OldDateTime: DateTime;

#pragma warning disable AA0074
        Text000: Label 'Suggesting lines...';
        Text001: Label 'Suggesting lines @1@@@@@@@@@@@@@';
        Text002: Label 'It was not possible to process some of the selected finance charge memos.\Do you want to see these finance charge memos?';
#pragma warning restore AA0074
}

