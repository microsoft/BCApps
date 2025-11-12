// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Ledger;

report 1141 "Delete Old Cost Entries"
{
    Caption = 'Delete Old Cost Entries';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(YearEndingDate; YearEndDate)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Year Ending Date';
                    ToolTip = 'Specifies that you want to delete all cost entries up to and including the date that you enter in the report.';

                    trigger OnValidate()
                    begin
                        if YearEndDate <> CalcDate('<CY>', YearEndDate) then
                            Error(Text001, YearEndDate);

                        if WorkDate() - YearEndDate < 365 then
                            Error(Text002, YearEndDate);

                        if not Confirm(Text003, false, YearEndDate) then
                            exit;

                        CostEntry.SetCurrentKey("Cost Type No.", "Posting Date");
                        CostEntry.SetRange("Posting Date", 0D, YearEndDate);
                        if not CostEntry.IsEmpty() then begin
                            CostEntry.DeleteAll();
                            Message(Text004, YearEndDate);
                        end else
                            Error(Text005, YearEndDate);
                    end;
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

    var
        CostEntry: Record "Cost Entry";
        YearEndDate: Date;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 is not at year''s end.';
        Text002: Label 'The selected year ending date %1 must be older than last year.';
        Text003: Label 'Are you sure you want to delete all cost entries up to and including %1?';
        Text004: Label 'All cost entries up to and including %1 deleted.';
        Text005: Label 'No cost entries were found before %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

