// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

report 5172 "Delete Expired Sales Quotes"
{
    Caption = 'Delete Expired Sales Quotes';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = where("Document Type" = const(Quote));
            RequestFilterFields = "No.", "Sell-to Customer No.";

            trigger OnPostDataItem()
            begin
                if CounterTotal > 0 then
                    Message(QuotesDeletedMsg, CounterTotal)
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Quote Valid Until Date", '<%1&<>%2', ValidToDate, 0D);
                CounterTotal := Count;
                if CounterTotal = 0 then begin
                    Message(NothingToDeleteMsg);
                    CurrReport.Break();
                end;

                if GuiAllowed then
                    if not Confirm(StrSubstNo(ConfirmQst, ValidToDate), false) then
                        Error('');

                DeleteAll(true);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(ValidToDate; ValidToDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Valid to date';
                    ToolTip = 'Specifies how long the quote is valid.';
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            ValidToDate := WorkDate();
        end;
    }

    labels
    {
    }

    var
        CounterTotal: Integer;
        NothingToDeleteMsg: Label 'There is nothing to delete.';
        QuotesDeletedMsg: Label 'Quotes deleted: %1.', Comment = '%1 - number of quotes.';
        ConfirmQst: Label 'All quotes with Quote Valid To Date less than %1 will be deleted. Do you want to continue?', Comment = '%1 - date';
        ValidToDate: Date;
}

