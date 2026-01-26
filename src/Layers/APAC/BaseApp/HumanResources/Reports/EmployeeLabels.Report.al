// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.Foundation.Address;
using Microsoft.HumanResources.Employee;

report 5200 "Employee - Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeLabels.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Labels';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.", "First Name", "Middle Name", "Last Name";
            column(EmployeeAddr_1__1_; EmployeeAddr[1] [1])
            {
            }
            column(EmployeeAddr_1__2_; EmployeeAddr[1] [2])
            {
            }
            column(EmployeeAddr_1__3_; EmployeeAddr[1] [3])
            {
            }
            column(EmployeeAddr_1__4_; EmployeeAddr[1] [4])
            {
            }
            column(EmployeeAddr_1__5_; EmployeeAddr[1] [5])
            {
            }
            column(EmployeeAddr_1__6_; EmployeeAddr[1] [6])
            {
            }
            column(EmployeeAddr_2__1_; EmployeeAddr[2] [1])
            {
            }
            column(EmployeeAddr_2__2_; EmployeeAddr[2] [2])
            {
            }
            column(EmployeeAddr_2__3_; EmployeeAddr[2] [3])
            {
            }
            column(EmployeeAddr_2__4_; EmployeeAddr[2] [4])
            {
            }
            column(EmployeeAddr_2__5_; EmployeeAddr[2] [5])
            {
            }
            column(EmployeeAddr_2__6_; EmployeeAddr[2] [6])
            {
            }
            column(EmployeeAddr_3__1_; EmployeeAddr[3] [1])
            {
            }
            column(EmployeeAddr_3__2_; EmployeeAddr[3] [2])
            {
            }
            column(EmployeeAddr_3__3_; EmployeeAddr[3] [3])
            {
            }
            column(EmployeeAddr_3__4_; EmployeeAddr[3] [4])
            {
            }
            column(EmployeeAddr_3__5_; EmployeeAddr[3] [5])
            {
            }
            column(EmployeeAddr_3__6_; EmployeeAddr[3] [6])
            {
            }
            column(EmployeeAddr_1__7_; EmployeeAddr[1] [7])
            {
            }
            column(EmployeeAddr_1__8_; EmployeeAddr[1] [8])
            {
            }
            column(EmployeeAddr_2__7_; EmployeeAddr[2] [7])
            {
            }
            column(EmployeeAddr_2__8_; EmployeeAddr[2] [8])
            {
            }
            column(EmployeeAddr_3__7_; EmployeeAddr[3] [7])
            {
            }
            column(EmployeeAddr_3__8_; EmployeeAddr[3] [8])
            {
            }
            column(ShowBody1; (ColumnNo = 0) and (LabelFormat = LabelFormat::"36 x 70 mm (3 columns)"))
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
            column(ShowBody5; (ColumnNo = 0) and (LabelFormat = LabelFormat::"48 x 105 mm (2 columns - Bar Code)"))
            {
            }
            column(EmployeeAddr_2__8__Control1500000; EmployeeAddr[2] [8])
            {
            }
            column(EmployeeAddr_2__7__Control1500001; EmployeeAddr[2] [7])
            {
            }
            column(EmployeeAddr_2__6__Control1500002; EmployeeAddr[2] [6])
            {
            }
            column(EmployeeAddr_1__6__Control1500003; EmployeeAddr[1] [6])
            {
            }
            column(EmployeeAddr_1__7__Control1500004; EmployeeAddr[1] [7])
            {
            }
            column(EmployeeAddr_1__8__Control1500005; EmployeeAddr[1] [8])
            {
            }
            column(EmployeeAddr_1__5__Control1500006; EmployeeAddr[1] [5])
            {
            }
            column(EmployeeAddr_2__5__Control1500007; EmployeeAddr[2] [5])
            {
            }
            column(EmployeeAddr_1__4__Control1500008; EmployeeAddr[1] [4])
            {
            }
            column(EmployeeAddr_2__4__Control1500009; EmployeeAddr[2] [4])
            {
            }
            column(EmployeeAddr_1__3__Control1500010; EmployeeAddr[1] [3])
            {
            }
            column(EmployeeAddr_2__3__Control1500011; EmployeeAddr[2] [3])
            {
            }
            column(EmployeeAddr_1__2__Control1500012; EmployeeAddr[1] [2])
            {
            }
            column(EmployeeAddr_2__2__Control1500013; EmployeeAddr[2] [2])
            {
            }
            column(EmployeeAddr_1__1__Control1500014; EmployeeAddr[1] [1])
            {
            }
            column(EmployeeAddr_2__1__Control1500015; EmployeeAddr[2] [1])
            {
            }
            column(EmployeeBarCode_2_; EmployeeBarCode[2])
            {
            }
            column(EmployeeBarCode_1_; EmployeeBarCode[1])
            {
            }

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                ColumnNo := ColumnNo + 1;
                if (Today < "Alt. Address End Date") and
                   (Today > "Alt. Address Start Date") and
                   ("Alt. Address Code" <> '') and
                   (AddrFormat = AddrFormat::"Current Alternative Address")
                then
                    FormatAddr.EmployeeAltAddr(EmployeeAddr[ColumnNo], Employee)
                else
                    FormatAddr.Employee(EmployeeAddr[ColumnNo], Employee);
                EmployeeBarCode[ColumnNo] := FormatAddr.PrintBarCode(0);
                if RecordNo = NoOfRecords then begin
                    for i := ColumnNo + 1 to NoOfColumns do begin
                        Clear(EmployeeAddr[i]);
                        EmployeeBarCode[i] := '';
                    end;
                    ColumnNo := 0;
                end else
                    if ColumnNo = NoOfColumns then
                        ColumnNo := 0;
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
                    field(AddrFormat; AddrFormat)
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Use';
                        OptionCaption = 'Home Address,Current Alternative Address';
                        ToolTip = 'Specifies either the current Alternative Address or the Home Address to be printed on the labels. Click the desired option field.';
                    }
                    field(LabelFormat; LabelFormat)
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Format';
                        OptionCaption = '36 x 70 mm (3 columns),37 x 70 mm (3 columns),36 x 105 mm (2 columns),37 x 105 mm (2 columns),48 x 105 mm (2 columns - Bar Code)';
                        ToolTip = 'Specifies which of the four different printing formats applies: 36*70 mm (3 columns), 37*70 mm (3 columns), 36*105 mm (2 columns), 37*105 mm (2 columns), and 48*105 mm (2 columns - Bar Code).';
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

    var
        FormatAddr: Codeunit "Format Address";
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)","48 x 105 mm (2 columns - Bar Code)";
        AddrFormat: Option "Home Address","Current Alternative Address";
        EmployeeAddr: array[3, 8] of Text[100];
        EmployeeBarCode: array[3] of Text[100];
        NoOfRecords: Integer;
        RecordNo: Integer;
        NoOfColumns: Integer;
        ColumnNo: Integer;
        i: Integer;

    procedure InitializeRequest(AddrFormatFrom: Option; LabelFormatFrom: Option)
    begin
        AddrFormat := AddrFormatFrom;
        LabelFormat := LabelFormatFrom;
    end;
}

