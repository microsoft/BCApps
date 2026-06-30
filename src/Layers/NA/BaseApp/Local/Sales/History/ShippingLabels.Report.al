// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Foundation.Address;
using System.Utilities;

report 10078 "Shipping Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/History/ShippingLabels.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Shipping Labels';
    UsageCategory = Documents;

    dataset
    {
        dataitem("Sales Shipment Header"; "Sales Shipment Header")
        {
            RequestFilterFields = "No.";
            column(Addr_1__2_; Addr[1] [2])
            {
            }
            column(Addr_1__3_; Addr[1] [3])
            {
            }
            column(Addr_1__1_; Addr[1] [1])
            {
            }
            column(LabelsPerRow; LabelsPerRow)
            {
            }
            column(NumOfBlanksInput; NumOfBlanksInput)
            {
            }
            column(ColumnNo; ColumnNo)
            {
            }
            column(Addr_1__4_; Addr[1] [4])
            {
            }
            column(Addr_1__5_; Addr[1] [5])
            {
            }
            column(Addr_1__6_; Addr[1] [6])
            {
            }
            column(Addr_1__7_; Addr[1] [7])
            {
            }
            column(Addr_1__3__Control8; Addr[1] [3])
            {
            }
            column(Addr_1__2__Control10; Addr[1] [2])
            {
            }
            column(Addr_1__1__Control11; Addr[1] [1])
            {
            }
            column(Addr_2__2_; Addr[2] [2])
            {
            }
            column(Addr_2__1_; Addr[2] [1])
            {
            }
            column(Addr_2__3_; Addr[2] [3])
            {
            }
            column(Addr_1__4__Control20; Addr[1] [4])
            {
            }
            column(Addr_2__4_; Addr[2] [4])
            {
            }
            column(Addr_1__5__Control21; Addr[1] [5])
            {
            }
            column(Addr_2__5_; Addr[2] [5])
            {
            }
            column(Addr_1__6__Control23; Addr[1] [6])
            {
            }
            column(Addr_2__6_; Addr[2] [6])
            {
            }
            column(Addr_1__7__Control24; Addr[1] [7])
            {
            }
            column(Addr_2__7_; Addr[2] [7])
            {
            }
            column(Addr_1__3__Control12; Addr[1] [3])
            {
            }
            column(Addr_1__2__Control15; Addr[1] [2])
            {
            }
            column(Addr_1__1__Control17; Addr[1] [1])
            {
            }
            column(Addr_2__2__Control29; Addr[2] [2])
            {
            }
            column(Addr_2__1__Control30; Addr[2] [1])
            {
            }
            column(Addr_2__3__Control31; Addr[2] [3])
            {
            }
            column(Addr_3__2_; Addr[3] [2])
            {
            }
            column(Addr_3__3_; Addr[3] [3])
            {
            }
            column(Addr_3__1_; Addr[3] [1])
            {
            }
            column(Addr_1__4__Control26; Addr[1] [4])
            {
            }
            column(Addr_2__4__Control35; Addr[2] [4])
            {
            }
            column(Addr_3__4_; Addr[3] [4])
            {
            }
            column(Addr_1__5__Control27; Addr[1] [5])
            {
            }
            column(Addr_2__5__Control37; Addr[2] [5])
            {
            }
            column(Addr_3__5_; Addr[3] [5])
            {
            }
            column(Addr_1__6__Control28; Addr[1] [6])
            {
            }
            column(Addr_2__6__Control39; Addr[2] [6])
            {
            }
            column(Addr_3__6_; Addr[3] [6])
            {
            }
            column(Addr_1__7__Control25; Addr[1] [7])
            {
            }
            column(Addr_2__7__Control41; Addr[2] [7])
            {
            }
            column(Addr_3__7_; Addr[3] [7])
            {
            }
            column(Sales_Shipment_Header_No_; "No.")
            {
            }
            dataitem(BlankLine; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(NumOfBlanks; NumOfBlanks)
                {
                }
                column(BlankLine_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if NumOfBlanks <= 0 then
                        CurrReport.Break();
                    NumOfBlanks := NumOfBlanks - 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                ColumnNo := ColumnNo + 1;
                if ColumnNo = 1 then
                    Clear(Addr);
                FormatAddress.SalesShptShipTo(Addr[ColumnNo], "Sales Shipment Header");
                if RecordNo = NoOfRecords then begin
                    for i := ColumnNo + 1 to NoOfColumns do
                        Clear(Addr[i]);
                    ColumnNo := 0;
                end else
                    if ColumnNo = NoOfColumns then
                        ColumnNo := 0;

                NumOfBlanks := NumOfBlanksInput - 7;
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
                NoOfColumns := LabelsPerRow;
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
                    field(NumOfBlanksInput; NumOfBlanksInput)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of print lines on label';
                        ToolTip = 'Specifies the height of each label on print lines. Since each print line is .16 inches, you can measure the height of the label (top of one label to the top of the next label) in inches and then multiply the result by 6.';
                    }
                    field(LabelsPerRow; LabelsPerRow)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of labels per row';
                        MaxValue = 3;
                        MinValue = 1;
                        ToolTip = 'Specifies the number of labels that can run across one row of labels.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            if NumOfBlanksInput = 0 then
                NumOfBlanksInput := 6;
            if LabelsPerRow = 0 then
                LabelsPerRow := 1;
        end;
    }

    labels
    {
    }

    var
        FormatAddress: Codeunit "Format Address";
        Addr: array[3, 8] of Text[100];
        NumOfBlanksInput: Integer;
        LabelsPerRow: Integer;
        NumOfBlanks: Integer;
        RecordNo: Integer;
        ColumnNo: Integer;
        NoOfColumns: Integer;
        NoOfRecords: Integer;
        i: Integer;
}

