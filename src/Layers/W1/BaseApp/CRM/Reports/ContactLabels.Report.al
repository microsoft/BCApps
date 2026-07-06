// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;

report 5056 "Contact - Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/ContactLabels.rdlc';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Contact Labels';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Contact; Contact)
        {
            RequestFilterFields = "No.", Name, Type, "Salesperson Code", "Post Code", "Territory Code", "Country/Region Code";
            column(ContAddr_1__1_; ContAddr[1] [1])
            {
            }
            column(ContAddr_1__2_; ContAddr[1] [2])
            {
            }
            column(ContAddr_1__3_; ContAddr[1] [3])
            {
            }
            column(ContAddr_1__4_; ContAddr[1] [4])
            {
            }
            column(ContAddr_1__5_; ContAddr[1] [5])
            {
            }
            column(ContAddr_1__6_; ContAddr[1] [6])
            {
            }
            column(ContAddr_2__1_; ContAddr[2] [1])
            {
            }
            column(ContAddr_2__2_; ContAddr[2] [2])
            {
            }
            column(ContAddr_2__3_; ContAddr[2] [3])
            {
            }
            column(ContAddr_2__4_; ContAddr[2] [4])
            {
            }
            column(ContAddr_2__5_; ContAddr[2] [5])
            {
            }
            column(ContAddr_2__6_; ContAddr[2] [6])
            {
            }
            column(ContAddr_3__1_; ContAddr[3] [1])
            {
            }
            column(ContAddr_3__2_; ContAddr[3] [2])
            {
            }
            column(ContAddr_3__3_; ContAddr[3] [3])
            {
            }
            column(ContAddr_3__4_; ContAddr[3] [4])
            {
            }
            column(ContAddr_3__5_; ContAddr[3] [5])
            {
            }
            column(ContAddr_3__6_; ContAddr[3] [6])
            {
            }
            column(ContAddr_1__7_; ContAddr[1] [7])
            {
            }
            column(ContAddr_1__8_; ContAddr[1] [8])
            {
            }
            column(ContAddr_2__7_; ContAddr[2] [7])
            {
            }
            column(ContAddr_2__8_; ContAddr[2] [8])
            {
            }
            column(ContAddr_3__7_; ContAddr[3] [7])
            {
            }
            column(ContAddr_3__8_; ContAddr[3] [8])
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
                FormatAddr.ContactAddr(ContAddr[ColumnNo], Contact);
                if RecordNo = NoOfRecords then begin
                    for i := ColumnNo + 1 to NoOfColumns do
                        Clear(ContAddr[i]);
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
        AboutTitle = 'About Contact Labels';
        AboutText = 'Print mailing labels with the names and addresses of your contacts.';
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
                        ApplicationArea = RelationshipMgmt;
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
        ContAddr: array[3, 8] of Text[100];
        NoOfRecords: Integer;
        RecordNo: Integer;
        NoOfColumns: Integer;
        ColumnNo: Integer;
        i: Integer;
        GroupNo: Integer;
        Counter: Integer;
        RecPerPageNum: Integer;

    procedure InitializeRequest(LabelFormatFrom: Option)
    begin
        LabelFormat := LabelFormatFrom;
    end;
}

