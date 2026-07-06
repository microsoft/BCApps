// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;

report 310 "Vendor - Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorLabels.rdlc';
    ApplicationArea = Suite;
    Caption = 'Vendor - Labels';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.", Name;
            column(VendAddr_1__1_; VendAddr[1] [1])
            {
            }
            column(VendAddr_1__2_; VendAddr[1] [2])
            {
            }
            column(VendAddr_1__3_; VendAddr[1] [3])
            {
            }
            column(VendAddr_1__4_; VendAddr[1] [4])
            {
            }
            column(VendAddr_1__5_; VendAddr[1] [5])
            {
            }
            column(VendAddr_1__6_; VendAddr[1] [6])
            {
            }
            column(VendAddr_2__1_; VendAddr[2] [1])
            {
            }
            column(VendAddr_2__2_; VendAddr[2] [2])
            {
            }
            column(VendAddr_2__3_; VendAddr[2] [3])
            {
            }
            column(VendAddr_2__4_; VendAddr[2] [4])
            {
            }
            column(VendAddr_2__5_; VendAddr[2] [5])
            {
            }
            column(VendAddr_2__6_; VendAddr[2] [6])
            {
            }
            column(VendAddr_3__1_; VendAddr[3] [1])
            {
            }
            column(VendAddr_3__2_; VendAddr[3] [2])
            {
            }
            column(VendAddr_3__3_; VendAddr[3] [3])
            {
            }
            column(VendAddr_3__4_; VendAddr[3] [4])
            {
            }
            column(VendAddr_3__5_; VendAddr[3] [5])
            {
            }
            column(VendAddr_3__6_; VendAddr[3] [6])
            {
            }
            column(VendAddr_1__7_; VendAddr[1] [7])
            {
            }
            column(VendAddr_1__8_; VendAddr[1] [8])
            {
            }
            column(VendAddr_2__7_; VendAddr[2] [7])
            {
            }
            column(VendAddr_2__8_; VendAddr[2] [8])
            {
            }
            column(VendAddr_3__7_; VendAddr[3] [7])
            {
            }
            column(VendAddr_3__8_; VendAddr[3] [8])
            {
            }
            column(ColumnNo; ColumnNo)
            {
            }
            column(LabelFormatInt; LabelFormatInt)
            {
            }
            column(GroupNo; GroupNo)
            {
            }

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                ColumnNo := ColumnNo + 1;
                FormatAddr.Vendor(VendAddr[ColumnNo], Vendor);
                if RecordNo = NoOfRecords then begin
                    for i := ColumnNo + 1 to NoOfColumns do
                        Clear(VendAddr[i]);
                    ColumnNo := 0;
                end else
                    if ColumnNo = NoOfColumns then
                        ColumnNo := 0;

                if Counter = BlocksPerPage * NoOfColumns then begin
                    GroupNo := GroupNo + 1;
                    Counter := 0;
                end;
                Counter := Counter + 1;
            end;

            trigger OnPreDataItem()
            begin
                LabelFormatInt := LabelFormat;

                case LabelFormat of
                    LabelFormat::"36 x 70 mm (3 columns)", LabelFormat::"37 x 70 mm (3 columns)":
                        NoOfColumns := 3;
                    LabelFormat::"36 x 105 mm (2 columns)", LabelFormat::"37 x 105 mm (2 columns)":
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
                    field(Format; LabelFormat)
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

    trigger OnInitReport()
    begin
        GroupNo := 0;
        Counter := 0;
        BlocksPerPage := 6;
    end;

    var
        FormatAddr: Codeunit "Format Address";
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
        NoOfRecords: Integer;
        RecordNo: Integer;
        NoOfColumns: Integer;
        ColumnNo: Integer;
        i: Integer;
        LabelFormatInt: Integer;
        GroupNo: Integer;
        Counter: Integer;
        BlocksPerPage: Integer;

    protected var
        VendAddr: array[3, 8] of Text[100];

    procedure InitializeRequest(NewLabelFormat: Option)
    begin
        LabelFormat := NewLabelFormat;
    end;
}

