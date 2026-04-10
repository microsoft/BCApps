// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

/// <summary>
/// Provides date range selection interface for bank statement import and filtering operations.
/// Allows users to specify from and to dates for bank statement data processing.
/// </summary>
/// <remarks>
/// Dialog page for collecting date range parameters from users.
/// Validates date range consistency and provides user-friendly date selection interface.
/// Used in bank statement import workflows to limit the scope of imported transactions.
/// </remarks>
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

    /// <summary>
    /// Gets the currently selected date range from the filter page.
    /// </summary>
    /// <param name="ResultFromDate">Returns the start date of the selected range.</param>
    /// <param name="ResultToDate">Returns the end date of the selected range.</param>
    procedure GetDates(var ResultFromDate: Date; var ResultToDate: Date)
    begin
        ResultFromDate := FromDate;
        ResultToDate := ToDate;
    end;

    /// <summary>
    /// Sets the date range for the filter page with validation.
    /// </summary>
    /// <param name="NewFromDate">The start date of the range to set.</param>
    /// <param name="NewToDate">The end date of the range to set.</param>
    procedure SetDates(NewFromDate: Date; NewToDate: Date)
    begin
        if NewFromDate > NewToDate then
            Error(DateInputTxt);

        FromDate := NewFromDate;
        ToDate := NewToDate;
    end;
}

