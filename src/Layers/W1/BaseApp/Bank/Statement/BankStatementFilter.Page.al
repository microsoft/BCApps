// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

page 1298 "Bank Statement Filter"
{
    Caption = 'Import transaction data';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            field(Instructions; InstructionsTxt)
            {
                ApplicationArea = Basic, Suite;
                Caption = '';
                ShowCaption = false;
                ToolTip = 'Specifies the instructions for use.';
            }
            field(FromDate; FromDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'From Date';
                ToolTip = 'Specifies the first date that the bank statement must contain transactions for.';
            }
            field(ToDate; ToDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'To Date';
                ToolTip = 'Specifies the last date that the bank statement must contain transactions for.';
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (CloseAction in [ACTION::OK, ACTION::LookupOK]) then
            exit(true);

        if FromDate > ToDate then begin
            Message(DateInputTxt);
            exit(false);
        end;
    end;

    var
        FromDate: Date;
        ToDate: Date;
        DateInputTxt: Label 'The value in the From Date field must not be greater than the value in the To Date field.';
        InstructionsTxt: label 'Choose the date range for the data import';

    procedure GetDates(var ResultFromDate: Date; var ResultToDate: Date)
    begin
        ResultFromDate := FromDate;
        ResultToDate := ToDate;
    end;

    procedure SetDates(NewFromDate: Date; NewToDate: Date)
    begin
        if NewFromDate > NewToDate then
            Error(DateInputTxt);

        FromDate := NewFromDate;
        ToDate := NewToDate;
    end;
}

