// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;

report 951 "Suggest Res. Jnl. Lines"
{
    Caption = 'Suggest Res. Jnl. Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Resource; Resource)
        {
            DataItemTableView = where("Use Time Sheet" = const(true));
            RequestFilterFields = "No.", Type;

            trigger OnAfterGetRecord()
            begin
                FillTempBuffer("No.");
            end;

            trigger OnPostDataItem()
            var
                NoSeries: Codeunit "No. Series";
                NextDocNo: Code[20];
                LineNo: Integer;
                QtyToPost: Decimal;
            begin
                if TempTimeSheetLine.FindSet() then begin
                    ResJnlLine.LockTable();
                    ResJnlTemplate.Get(ResJnlLine."Journal Template Name");
                    ResJnlBatch.Get(ResJnlLine."Journal Template Name", ResJnlLine."Journal Batch Name");
                    if ResJnlBatch."No. Series" = '' then
                        NextDocNo := ''
                    else
                        NextDocNo := NoSeries.PeekNextNo(ResJnlBatch."No. Series", TempTimeSheetLine."Time Sheet Starting Date");

                    ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
                    ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
                    if ResJnlLine.FindLast() then;
                    LineNo := ResJnlLine."Line No.";

                    repeat
                        TimeSheetHeader.Get(TempTimeSheetLine."Time Sheet No.");
                        TimeSheetDetail.SetRange("Time Sheet No.", TempTimeSheetLine."Time Sheet No.");
                        TimeSheetDetail.SetRange("Time Sheet Line No.", TempTimeSheetLine."Line No.");
                        if DateFilter <> '' then
                            TimeSheetDetail.SetFilter(Date, DateFilter);
                        TimeSheetDetail.SetFilter(Quantity, '<>0');
                        if TimeSheetDetail.FindSet() then
                            repeat
                                QtyToPost := TimeSheetDetail.GetMaxQtyToPost();
                                if QtyToPost <> 0 then begin
                                    ResJnlLine.Init();
                                    LineNo := LineNo + 10000;
                                    ResJnlLine."Line No." := LineNo;
                                    ResJnlLine."Time Sheet No." := TimeSheetDetail."Time Sheet No.";
                                    ResJnlLine."Time Sheet Line No." := TimeSheetDetail."Time Sheet Line No.";
                                    ResJnlLine."Time Sheet Date" := TimeSheetDetail.Date;
                                    ResJnlLine.Validate("Resource No.", TimeSheetHeader."Resource No.");
                                    ResJnlLine.Validate("Posting Date", TimeSheetDetail.Date);
                                    ResJnlLine."Document No." := NextDocNo;
                                    NextDocNo := IncStr(NextDocNo);
                                    ResJnlLine."Posting No. Series" := ResJnlBatch."Posting No. Series";
                                    ResJnlLine.Description := TempTimeSheetLine.Description;
                                    ResJnlLine.Validate("Work Type Code", TempTimeSheetLine."Work Type Code");
                                    ResJnlLine.Validate(Quantity, QtyToPost);
                                    ResJnlLine."Source Code" := ResJnlTemplate."Source Code";
                                    ResJnlLine."Reason Code" := ResJnlBatch."Reason Code";
                                    OnBeforeResJnlLineInsert(ResJnlLine, TimeSheetHeader, TempTimeSheetLine, TimeSheetDetail, ResJnlTemplate, ResJnlBatch);
                                    ResJnlLine.Insert();
                                end;
                            until TimeSheetDetail.Next() = 0;
                    until TempTimeSheetLine.Next() = 0;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if ResourceNoFilter <> '' then
                    SetFilter("No.", ResourceNoFilter);

                if DateFilter <> '' then
                    TimeSheetHeader.SetFilter("Starting Date", DateFilter);
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
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date of the first day for the period for which you want to create journal lines.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date of the last day for the period for which you want to create journal lines.';
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
    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        DateFilter := TimeSheetMgt.GetDateFilter(StartingDate, EndingDate);
    end;

    var
        ResJnlLine: Record "Res. Journal Line";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlTemplate: Record "Res. Journal Template";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
        TimeSheetDetail: Record "Time Sheet Detail";
        ResourceNoFilter: Code[250];
        StartingDate: Date;
        EndingDate: Date;
        DateFilter: Text[30];

    procedure SetResJnlLine(NewResJnlLine: Record "Res. Journal Line")
    begin
        ResJnlLine := NewResJnlLine;
    end;

    procedure InitParameters(NewResJnlLine: Record "Res. Journal Line"; NewResourceNoFilter: Code[250]; NewStartingDate: Date; NewEndingDate: Date)
    begin
        ResJnlLine := NewResJnlLine;
        ResourceNoFilter := NewResourceNoFilter;
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
    end;

    local procedure FillTempBuffer(ResourceNo: Code[20])
    begin
        TimeSheetHeader.SetRange("Resource No.", ResourceNo);
        if TimeSheetHeader.FindSet() then
            repeat
                TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Resource);
                TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Approved);
                TimeSheetLine.SetRange(Posted, false);
                if TimeSheetLine.FindSet() then
                    repeat
                        TempTimeSheetLine := TimeSheetLine;
                        TempTimeSheetLine.Insert();
                    until TimeSheetLine.Next() = 0;
            until TimeSheetHeader.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResJnlLineInsert(var ResJournalLine: Record "Res. Journal Line"; TimeSheetHeader: Record "Time Sheet Header"; TimeSheetLine: Record "Time Sheet Line"; TimeSheetDetail: Record "Time Sheet Detail"; ResJournalTemplate: Record "Res. Journal Template"; ResJournalBatch: Record "Res. Journal Batch")
    begin
    end;
}

