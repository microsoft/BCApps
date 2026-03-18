// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Document;

report 5901 "Service Item Line Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceItemLineLabels.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Item Line Labels';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Item Line"; "Service Item Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
            RequestFilterFields = "Document Type", "Document No.", "Line No.";
            column(Addr11; Addr[1] [1])
            {
            }
            column(Addr12; Addr[1] [2])
            {
            }
            column(Addr13; Addr[1] [3])
            {
            }
            column(Addr14; Addr[1] [4])
            {
            }
            column(Addr21; Addr[2] [1])
            {
            }
            column(Addr22; Addr[2] [2])
            {
            }
            column(Addr23; Addr[2] [3])
            {
            }
            column(Addr24; Addr[2] [4])
            {
            }
            column(Addr31; Addr[3] [1])
            {
            }
            column(Addr32; Addr[3] [2])
            {
            }
            column(Addr33; Addr[3] [3])
            {
            }
            column(Addr34; Addr[3] [4])
            {
            }
            column(ShowSection; ColumnNo = 0)
            {
            }

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                ColumnNo := ColumnNo + 1;

                Addr[ColumnNo] [1] := StrSubstNo('%1 %2', FieldCaption("Document No."), Format("Document No."));
                Addr[ColumnNo] [2] := StrSubstNo('%1 %2', FieldCaption("Service Item No."), Format("Service Item No."));
                Addr[ColumnNo] [3] := StrSubstNo('%1 %2', FieldCaption("Serial No."), Format("Serial No."));
                Addr[ColumnNo] [4] := Format(Description);

                CompressArray(Addr[ColumnNo]);

                if RecordNo = NoOfRecords then begin
                    for i := ColumnNo + 1 to NoOfColumns do
                        Clear(Addr[i]);
                    ColumnNo := 0;
                end else
                    if ColumnNo = NoOfColumns then
                        ColumnNo := 0;
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
                NoOfColumns := 3;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Item Line Labels';
        AboutText = 'Get an overview of service items that are included in service orders.';
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

    var
        Addr: array[3, 4] of Text[250];
        NoOfRecords: Integer;
        RecordNo: Integer;
        NoOfColumns: Integer;
        ColumnNo: Integer;
        i: Integer;
}

