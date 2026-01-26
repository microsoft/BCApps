// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using System.Utilities;

page 7000071 "Bank Cat. Posted Payable Bills"
{
    Caption = 'Bank Cat. Posted Payable Bills';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CategoryFilter; CategoryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Category Filter';
                    TableRelation = "Category Code";
                    ToolTip = 'Specifies the categories that the data is included for.';
                }
                field(StatusFilterOption; StatusFilterOption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status Filter';
                    OptionCaption = 'Open,Honored,Rejected,All';
                    ToolTip = 'Specifies a filter for the status of bills that will be included.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View By';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        SetColumns(SetWanted::Initial);
                    end;
                }
                field(ColumnSet; ColumnSet)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the column setting based on how you have selected to view the matrix.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Show Matrix")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Bank Cat.Post.Pay.Bills Matrix";
                begin
                    StatusFilter := Format(StatusFilterOption, 0, '<Text>');
                    MatrixForm.Load(MatrixColumnCaptions, MatrixRecords, CategoryFilter, StatusFilter);
                    MatrixForm.RunModal();
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    SetColumns(SetWanted::Next);
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous data set.';

                trigger OnAction()
                begin
                    SetColumns(SetWanted::Previous);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Show Matrix_Promoted"; "&Show Matrix")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetColumns(SetWanted::Initial);
        if Rec.HasFilter then begin
            CategoryFilter := Rec.GetFilter("Category Filter");
            StatusFilter := Rec.GetFilter("Status Filter");
            if Evaluate(StatusFilterOption, StatusFilter) then;
        end;
    end;

    var
        MatrixRecords: array[32] of Record Date;
        CategoryFilter: Code[20];
        StatusFilterOption: Option Open,Honored,Rejected,All;
        PeriodType: Enum "Analysis Period Type";
        SetWanted: Option Initial,Previous,Same,Next;
        MatrixColumnCaptions: array[32] of Text[1024];
        ColumnSet: Text[1024];
        PKFirstRecInCurrSet: Text[100];
        StatusFilter: Text[30];
        CurrSetLength: Integer;

    [Scope('OnPrem')]
    procedure SetColumns(SetWanted: Option Initial,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(SetWanted, 32, false, PeriodType, '',
          PKFirstRecInCurrSet, MatrixColumnCaptions, ColumnSet, CurrSetLength, MatrixRecords);
    end;
}

