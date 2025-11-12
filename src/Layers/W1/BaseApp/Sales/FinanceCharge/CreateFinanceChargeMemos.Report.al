// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 191 "Create Finance Charge Memos"
{
    Caption = 'Create Finance Charge Memos';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                Clear(MakeFinChrgMemo);
                MakeFinChrgMemo.Set(Customer, CustLedgEntry, FinChrgMemoHeaderReq);
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
                    Mark := not MakeFinChrgMemo.Code();
                end;
                Commit();
            end;

            trigger OnPostDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                Window.Close();
                MarkedOnly := true;
                if FindFirst() then
                    if ConfirmManagement.GetResponse(Text003, true) then
                        PAGE.RunModal(0, Customer);
            end;

            trigger OnPreDataItem()
            begin
                if FinChrgMemoHeaderReq."Document Date" = 0D then
                    Error(Text000, FinChrgMemoHeaderReq.FieldCaption("Document Date"));
                FilterGroup := 2;
                SetFilter("Fin. Charge Terms Code", '<>%1', '');
                FilterGroup := 0;
                NoOfRecords := Count;
                if NoOfRecords = 1 then
                    Window.Open(Text001)
                else begin
                    Window.Open(Text002);
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
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
#pragma warning disable AA0100
                    field("FinChrgMemoHeaderReq.""Posting Date"""; FinChrgMemoHeaderReq."Posting Date")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that will appear as the posting date on the header of the finance charge memo created by the batch job.';
                    }
                    field(DocumentDate; FinChrgMemoHeaderReq."Document Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies a document date for the finance charge memo. This date is also used to determine the due date for the finance charge memo. ';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if FinChrgMemoHeaderReq."Document Date" = 0D then begin
                FinChrgMemoHeaderReq."Document Date" := WorkDate();
                FinChrgMemoHeaderReq."Posting Date" := WorkDate();
            end;
        end;
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
#pragma warning disable AA0470
        Text000: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text001: Label 'Making finance charge memos...';
        Text002: Label 'Making finance charge memos @1@@@@@@@@@@@@@';
        Text003: Label 'It was not possible to create finance charge memos for some of the selected customers.\Do you want to see these customers?';
#pragma warning restore AA0074

    protected var
        FinChrgMemoHeaderReq: Record "Finance Charge Memo Header";

    procedure InitializeRequest(PostingDate: Date; DocumentDate: Date)
    begin
        FinChrgMemoHeaderReq."Posting Date" := PostingDate;
        FinChrgMemoHeaderReq."Document Date" := DocumentDate;
    end;
}

