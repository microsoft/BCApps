// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using System.Utilities;

page 36850 "Bank Cat.Post.Pay.Bills Matrix"
{
    Caption = 'Bank Cat.Post.Pay.Bills Matrix';
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the posted payables bill. ';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the name of the bill.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[1];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[2];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[3];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[4];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[5];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[6];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[7];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[8];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[9];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[10];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[11];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[12];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[13];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[14];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[15];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[16];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[17];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[18];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[19];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[20];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[21];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[22];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[23];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[24];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[25];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[26];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[27];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[28];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[29];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[30];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[31];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[32];

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
        MATRIX_NoOfColumns: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 1;
        MATRIX_NoOfColumns := ArrayLen(MATRIX_CellData);

        while MATRIX_CurrentColumnOrdinal <= MATRIX_NoOfColumns do begin
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
        end;
    end;

    var
        CalcAmt: Decimal;
        CategoryFilter: Code[250];
        StatusFilterOption: Option Open,Honored,Rejected,All;
        MatrixRecords: array[32] of Record Date;
        MATRIX_ColumnCaption: array[32] of Text[1024];
        MATRIX_CellData: array[32] of Decimal;

    local procedure SetDateFilter(ColumnID: Integer)
    begin
        if CategoryFilter = '' then
            Rec.SetRange("Category Filter")
        else
            Rec.SetFilter("Category Filter", CategoryFilter);
        if StatusFilterOption = StatusFilterOption::All then
            Rec.SetFilter("Status Filter", '%1|%2|%3',
              StatusFilterOption::Open,
              StatusFilterOption::Honored,
              StatusFilterOption::Rejected)
        else
            Rec.SetRange("Status Filter", StatusFilterOption);

        if MatrixRecords[ColumnID]."Period Start" = MatrixRecords[ColumnID]."Period End" then
            Rec.SetRange("Due Date Filter", MatrixRecords[ColumnID]."Period Start")
        else
            Rec.SetRange("Due Date Filter", MatrixRecords[ColumnID]."Period Start", MatrixRecords[ColumnID]."Period End")
    end;

    [Scope('OnPrem')]
    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record Date; CategoryFilter1: Code[20]; StatusFilter: Text[30])
    begin
        CopyArray(MATRIX_ColumnCaption, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);
        CategoryFilter := CategoryFilter1;
        if Evaluate(StatusFilterOption, StatusFilter) then;
    end;

    local procedure MATRIX_OnDrillDown(ColumnID: Integer)
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        PostedBills: Page "Posted Bills";
    begin
        SetDateFilter(ColumnID);
        PostedCarteraDoc.SetRange("Document Type", PostedCarteraDoc."Document Type"::Bill);
        PostedCarteraDoc.SetRange(Type, PostedCarteraDoc.Type::Payable);

        if MatrixRecords[ColumnID]."Period Start" = MatrixRecords[ColumnID]."Period End" then
            PostedCarteraDoc.SetRange("Due Date", MatrixRecords[ColumnID]."Period Start")
        else
            PostedCarteraDoc.SetRange("Due Date", MatrixRecords[ColumnID]."Period Start", MatrixRecords[ColumnID]."Period End");

        PostedCarteraDoc.SetFilter("Category Code", CategoryFilter);
        PostedCarteraDoc.SetRange(Status, StatusFilterOption);
        PostedCarteraDoc.SetRange("Bank Account No.", Rec."No.");
        PostedBills.SetTableView(PostedCarteraDoc);
        PostedBills.RunModal();
    end;

    local procedure MATRIX_OnAfterGetRecord(ColumnID: Integer)
    begin
        SetDateFilter(ColumnID);
        Rec.SetFilter("Category Filter", CategoryFilter);
        if StatusFilterOption = StatusFilterOption::All then
            Rec.SetFilter("Status Filter", '%1|%2|%3',
              StatusFilterOption::Open,
              StatusFilterOption::Honored,
              StatusFilterOption::Rejected)
        else
            Rec.SetRange("Status Filter", StatusFilterOption);
        Rec.CalcFields("Posted Pay. Bills Amt. (LCY)");
        CalcAmt := Rec."Posted Pay. Bills Amt. (LCY)";
        MATRIX_CellData[ColumnID] := Rec."Posted Pay. Bills Amt. (LCY)";
    end;
}

