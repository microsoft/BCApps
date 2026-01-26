// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;

report 110 "Customer - Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerLabels.rdlc';
    Caption = 'Customer - Labels';

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", Name;
            column(CustAddr_1__1_; CustAddr[1] [1])
            {
            }
            column(CustAddr_1__2_; CustAddr[1] [2])
            {
            }
            column(CustAddr_1__3_; CustAddr[1] [3])
            {
            }
            column(CustAddr_1__4_; CustAddr[1] [4])
            {
            }
            column(CustAddr_1__5_; CustAddr[1] [5])
            {
            }
            column(CustAddr_1__6_; CustAddr[1] [6])
            {
            }
            column(CustAddr_2__1_; CustAddr[2] [1])
            {
            }
            column(CustAddr_2__2_; CustAddr[2] [2])
            {
            }
            column(CustAddr_2__3_; CustAddr[2] [3])
            {
            }
            column(CustAddr_2__4_; CustAddr[2] [4])
            {
            }
            column(CustAddr_2__5_; CustAddr[2] [5])
            {
            }
            column(CustAddr_2__6_; CustAddr[2] [6])
            {
            }
            column(CustAddr_3__1_; CustAddr[3] [1])
            {
            }
            column(CustAddr_3__2_; CustAddr[3] [2])
            {
            }
            column(CustAddr_3__3_; CustAddr[3] [3])
            {
            }
            column(CustAddr_3__4_; CustAddr[3] [4])
            {
            }
            column(CustAddr_3__5_; CustAddr[3] [5])
            {
            }
            column(CustAddr_3__6_; CustAddr[3] [6])
            {
            }
            column(CustAddr_1__7_; CustAddr[1] [7])
            {
            }
            column(CustAddr_1__8_; CustAddr[1] [8])
            {
            }
            column(CustAddr_2__7_; CustAddr[2] [7])
            {
            }
            column(CustAddr_2__8_; CustAddr[2] [8])
            {
            }
            column(CustAddr_3__7_; CustAddr[3] [7])
            {
            }
            column(CustAddr_3__8_; CustAddr[3] [8])
            {
            }
            column(ShowBody1; (ColumnNo = 0) and (LabelFormat = LabelFormat::"36 x 70 mm (3 columns)"))
            {
            }
            column(GroupNo1; GroupNo)
            {
            }
            column(ShowBody2; (ColumnNo = 0) and (LabelFormat = LabelFormat::"37 x 70 mm (3 columns)"))
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
                FormatAddr.Customer(CustAddr[ColumnNo], Customer);
                if RecordNo = NoOfRecords then begin
                    for i := ColumnNo + 1 to NoOfColumns do
                        Clear(CustAddr[i]);
                    ColumnNo := 0;
                end else
                    if ColumnNo = NoOfColumns then
                        ColumnNo := 0;

                if ColumnNo = 0 then begin
                    if Counter = RecPerPageNum then begin
                        GroupNo := GroupNo + 1;
                        Counter := 0;
                    end;
                    Counter := Counter + 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                case LabelFormat of
                    LabelFormat::"36 x 70 mm (3 columns)", LabelFormat::"37 x 70 mm (3 columns)":
                        NoOfColumns := 3;
                    LabelFormat::"36 x 105 mm (2 columns)", LabelFormat::"37 x 105 mm (2 columns)":
                        NoOfColumns := 2;
                end;
                NoOfRecords := Count;
                RecordNo := 0;
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
                        ApplicationArea = Suite;
                        Caption = 'Format';
                        OptionCaption = '36 x 70 mm (3 columns),37 x 70 mm (3 columns),36 x 105 mm (2 columns),37 x 105 mm (2 columns)';
                        ToolTip = 'Specifies the format of the label.';
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
        GroupNo := 1;
        RecPerPageNum := 7;
    end;

    var
        FormatAddr: Codeunit "Format Address";
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
        CustAddr: array[3, 8] of Text[100];
        NoOfRecords: Integer;
        RecordNo: Integer;
        NoOfColumns: Integer;
        ColumnNo: Integer;
        i: Integer;
        GroupNo: Integer;
        Counter: Integer;
        RecPerPageNum: Integer;

    procedure InitializeRequest(SetLabelFormat: Option)
    begin
        LabelFormat := SetLabelFormat;
    end;
}

