// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
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
            column(ShowBody1; (ColumnNo = 0) and (LabelFormat = LabelFormat::"36 x 70 mm (3 columns)"))
            {
            }
            column(GroupNo1; GroupNo)
            {
            }
            column(ShowBody2; (ColumnNo = 0) and (LabelFormat = LabelFormat::"37 x 70 mm (3 columns)"))
            {
            }
            column(VendAddr_2__8__Control1500000; VendAddr[2] [8])
            {
            }
            column(VendAddr_2__7__Control1500001; VendAddr[2] [7])
            {
            }
            column(VendAddr_2__6__Control1500002; VendAddr[2] [6])
            {
            }
            column(VendAddr_2__5__Control1500003; VendAddr[2] [5])
            {
            }
            column(VendAddr_1__5__Control1500004; VendAddr[1] [5])
            {
            }
            column(VendAddr_1__6__Control1500005; VendAddr[1] [6])
            {
            }
            column(VendAddr_1__7__Control1500006; VendAddr[1] [7])
            {
            }
            column(VendAddr_1__8__Control1500007; VendAddr[1] [8])
            {
            }
            column(VendAddr_1__4__Control1500008; VendAddr[1] [4])
            {
            }
            column(VendAddr_2__4__Control1500009; VendAddr[2] [4])
            {
            }
            column(VendAddr_1__3__Control1500010; VendAddr[1] [3])
            {
            }
            column(VendAddr_2__3__Control1500011; VendAddr[2] [3])
            {
            }
            column(VendAddr_1__2__Control1500012; VendAddr[1] [2])
            {
            }
            column(VendAddr_2__2__Control1500013; VendAddr[2] [2])
            {
            }
            column(VendAddr_1__1__Control1500014; VendAddr[1] [1])
            {
            }
            column(VendAddr_2__1__Control1500015; VendAddr[2] [1])
            {
            }
            column(VendBarCode_2_; VendBarCode[2])
            {
            }
            column(VendBarCode_1_; VendBarCode[1])
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
                FormatAddr.Vendor(VendAddr[ColumnNo], Vendor);
                VendBarCode[ColumnNo] := FormatAddr.PrintBarCode(0);
                if RecordNo = NoOfRecords then begin
                    for i := ColumnNo + 1 to NoOfColumns do begin
                        Clear(VendAddr[i]);
                        VendBarCode[i] := '';
                    end;
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
                    LabelFormat::"36 x 105 mm (2 columns)", LabelFormat::"37 x 105 mm (2 columns)", LabelFormat::"48 x 105 mm (2 columns - Bar Code)":
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
                    field(Format; LabelFormat)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Format';
                        OptionCaption = '36 x 70 mm (3 columns),37 x 70 mm (3 columns),36 x 105 mm (2 columns),37 x 105 mm (2 columns),48 x 105 mm (2 columns - Bar Code)';
                        ToolTip = 'Specifies the format of the label.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            GLSetup: Record "General Ledger Setup";
        begin
            GLSetup.Get();
            /*REQUESTOPTIONSPAGE."Bar Code".ENABLED(
              (GLSetup."Address Validation" <> GLSetup."Address Validation"::"Post Code & City") AND
              (GLSetup."AMAS Software" <> 0));*/

        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GroupNo := 1;
        RecPerPageNum := 5;
    end;

    var
        FormatAddr: Codeunit "Format Address";
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)","48 x 105 mm (2 columns - Bar Code)";
        NoOfRecords: Integer;
        RecordNo: Integer;
        NoOfColumns: Integer;
        ColumnNo: Integer;
        i: Integer;
        GroupNo: Integer;
        Counter: Integer;
        RecPerPageNum: Integer;
        VendBarCode: array[3] of Text[100];

    protected var
        VendAddr: array[3, 8] of Text[100];

    procedure InitializeRequest(SetLabelFormat: Option)
    begin
        LabelFormat := SetLabelFormat;
    end;
}

