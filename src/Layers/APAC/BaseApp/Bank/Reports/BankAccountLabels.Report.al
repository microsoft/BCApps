// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Address;

/// <summary>
/// Generates mailing labels for bank accounts with formatted address information.
/// Supports multiple label formats and column layouts for printing address labels.
/// </summary>
/// <remarks>
/// Data Sources: Bank Account. 
/// Features: Multiple label format options, address formatting, multi-column printing layouts.
/// Usage: Mailing label printing, address label generation, bank correspondence addressing.
/// </remarks>
report 1405 "Bank Account - Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Bank/Reports/BankAccountLabels.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account - Labels';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            RequestFilterFields = "No.", Name;
            column(BankAccAddr_1__1_; BankAccAddr[1] [1])
            {
            }
            column(BankAccAddr_1__2_; BankAccAddr[1] [2])
            {
            }
            column(BankAccAddr_1__3_; BankAccAddr[1] [3])
            {
            }
            column(BankAccAddr_1__4_; BankAccAddr[1] [4])
            {
            }
            column(BankAccAddr_1__5_; BankAccAddr[1] [5])
            {
            }
            column(BankAccAddr_1__6_; BankAccAddr[1] [6])
            {
            }
            column(BankAccAddr_2__1_; BankAccAddr[2] [1])
            {
            }
            column(BankAccAddr_2__2_; BankAccAddr[2] [2])
            {
            }
            column(BankAccAddr_2__3_; BankAccAddr[2] [3])
            {
            }
            column(BankAccAddr_2__4_; BankAccAddr[2] [4])
            {
            }
            column(BankAccAddr_2__5_; BankAccAddr[2] [5])
            {
            }
            column(BankAccAddr_2__6_; BankAccAddr[2] [6])
            {
            }
            column(BankAccAddr_3__1_; BankAccAddr[3] [1])
            {
            }
            column(BankAccAddr_3__2_; BankAccAddr[3] [2])
            {
            }
            column(BankAccAddr_3__3_; BankAccAddr[3] [3])
            {
            }
            column(BankAccAddr_3__4_; BankAccAddr[3] [4])
            {
            }
            column(BankAccAddr_3__5_; BankAccAddr[3] [5])
            {
            }
            column(BankAccAddr_3__6_; BankAccAddr[3] [6])
            {
            }
            column(BankAccAddr_1__7_; BankAccAddr[1] [7])
            {
            }
            column(BankAccAddr_1__8_; BankAccAddr[1] [8])
            {
            }
            column(BankAccAddr_2__7_; BankAccAddr[2] [7])
            {
            }
            column(BankAccAddr_2__8_; BankAccAddr[2] [8])
            {
            }
            column(BankAccAddr_3__7_; BankAccAddr[3] [7])
            {
            }
            column(BankAccAddr_3__8_; BankAccAddr[3] [8])
            {
            }
            column(ShowBody1; (ColumnNo = 0) and (LabelFormat = LabelFormat::"36 x 70 mm (3 columns)"))
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(ShowBody2; (ColumnNo = 0) and (LabelFormat = LabelFormat::"37 x 70 mm (3 columns)"))
            {
            }
            column(BankAccAddr_2__8__Control1500000; BankAccAddr[2] [8])
            {
            }
            column(BankAccAddr_2__7__Control1500001; BankAccAddr[2] [7])
            {
            }
            column(BankAccAddr_1__7__Control1500002; BankAccAddr[1] [7])
            {
            }
            column(BankAccAddr_1__8__Control1500003; BankAccAddr[1] [8])
            {
            }
            column(BankAccAddr_1__6__Control1500004; BankAccAddr[1] [6])
            {
            }
            column(BankAccAddr_2__6__Control1500005; BankAccAddr[2] [6])
            {
            }
            column(BankAccAddr_1__5__Control1500006; BankAccAddr[1] [5])
            {
            }
            column(BankAccAddr_2__5__Control1500007; BankAccAddr[2] [5])
            {
            }
            column(BankAccAddr_1__4__Control1500008; BankAccAddr[1] [4])
            {
            }
            column(BankAccAddr_2__4__Control1500009; BankAccAddr[2] [4])
            {
            }
            column(BankAccAddr_1__3__Control1500010; BankAccAddr[1] [3])
            {
            }
            column(BankAccAddr_2__3__Control1500011; BankAccAddr[2] [3])
            {
            }
            column(BankAccAddr_1__2__Control1500012; BankAccAddr[1] [2])
            {
            }
            column(BankAccAddr_2__2__Control1500013; BankAccAddr[2] [2])
            {
            }
            column(BankAccAddr_1__1__Control1500014; BankAccAddr[1] [1])
            {
            }
            column(BankAccAddr_2__1__Control1500015; BankAccAddr[2] [1])
            {
            }
            column(BankAccBarCode_2_; BankAccBarCode[2])
            {
            }
            column(BankAccBarCode_1_; BankAccBarCode[1])
            {
            }
            column(ColumnNo___0__AND__LabelFormat___LabelFormat___48_x_105_mm__2_columns___Bar_Code___; (ColumnNo = 0) and (LabelFormat = LabelFormat::"48 x 105 mm (2 columns - Bar Code)"))
            {
            }
            column(ShowBody3; (ColumnNo = 0) and (LabelFormat = LabelFormat::"36 x 105 mm (2 columns)"))
            {
            }
            column(ShowBody4; (ColumnNo = 0) and (LabelFormat = LabelFormat::"37 x 105 mm (2 columns)"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                ColumnNo := ColumnNo + 1;
                FormatAddr.BankAcc(BankAccAddr[ColumnNo], "Bank Account");
                BankAccBarCode[ColumnNo] := FormatAddr.PrintBarCode(0);
                if RecordNo = NoOfRecords then begin
                    for i := ColumnNo + 1 to NoOfColumns do begin
                        Clear(BankAccAddr[i]);
                        BankAccBarCode[i] := '';
                    end;
                    ColumnNo := 0;
                end else
                    if ColumnNo = NoOfColumns then
                        ColumnNo := 0;

                if Counter = RecPerPageNum * NoOfColumns then begin
                    GroupNo := GroupNo + 1;
                    Counter := 0;
                end;

                Counter := Counter + 1;
            end;

            trigger OnPreDataItem()
            begin
                case LabelFormat of
                    LabelFormat::"36 x 70 mm (3 columns)", LabelFormat::"37 x 70 mm (3 columns)":
                        NoOfColumns := 3;
                    LabelFormat::"36 x 105 mm (2 columns)", LabelFormat::"37 x 105 mm (2 columns)", LabelFormat::"48 x 105 mm (2 columns - Bar Code)":
                        NoOfColumns := 2;
                end;
                NoOfRecords := Count;
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
                    field(LabelFormat; LabelFormat)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Format';
                        OptionCaption = '36 x 70 mm (3 columns),37 x 70 mm (3 columns),36 x 105 mm (2 columns),37 x 105 mm (2 columns),48 x 105 mm (2 columns - Bar Code)';
                        ToolTip = 'Specifies the size of the labels and whether they are printed in two or three columns.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GroupNo := 1;
        RecPerPageNum := 7;
    end;

    var
        FormatAddr: Codeunit "Format Address";
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)","48 x 105 mm (2 columns - Bar Code)";
        BankAccAddr: array[3, 8] of Text[100];
        NoOfRecords: Integer;
        RecordNo: Integer;
        NoOfColumns: Integer;
        ColumnNo: Integer;
        i: Integer;
        GroupNo: Integer;
        Counter: Integer;
        RecPerPageNum: Integer;
        BankAccBarCode: array[3] of Text[100];
}

