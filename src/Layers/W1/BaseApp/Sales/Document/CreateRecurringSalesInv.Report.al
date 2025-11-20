// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

report 172 "Create Recurring Sales Inv."
{
    AdditionalSearchTerms = 'repeat sales';
    ApplicationArea = Basic, Suite;
    Caption = 'Create Recurring Sales Invoices';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Standard Customer Sales Code"; "Standard Customer Sales Code")
        {
            RequestFilterFields = "Customer No.", "Code";

            trigger OnAfterGetRecord()
            begin
                Counter += 1;
                Window.Update(1, 10000 * Counter div TotalCount);
                CreateSalesInvoice(OrderDate, PostingDate);
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Valid From Date", '%1|<=%2', 0D, OrderDate);
                SetFilter("Valid To date", '%1|>=%2', 0D, OrderDate);
                SetRange(Blocked, false);

                TotalCount := Count;
                Window.Open(ProgressMsg);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(OrderDate; OrderDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order Date';
                    ToolTip = 'Specifies the date that will be entered in the Document Date field on the sales invoices that are created by using the batch job.';
                }
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the date that will be entered in the Posting Date field on the sales invoices that are created by using the batch job.';
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

    trigger OnPostReport()
    begin
        Window.Close();
        Message(NoOfInvoicesMsg, TotalCount);
    end;

    trigger OnPreReport()
    begin
        if (OrderDate = 0D) or (PostingDate = 0D) then
            Error(MissingDatesErr);
    end;

    var
        Window: Dialog;
        PostingDate: Date;
        OrderDate: Date;
        MissingDatesErr: Label 'You must enter both a posting date and an order date.';
        TotalCount: Integer;
        Counter: Integer;
#pragma warning disable AA0470
        ProgressMsg: Label 'Creating Invoices #1##################';
        NoOfInvoicesMsg: Label '%1 invoices were created.';
#pragma warning restore AA0470
}

