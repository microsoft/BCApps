#pragma warning disable AA0247
report 12409 "Order Proforma-Invoice (A)"
{
    Caption = 'Order Proforma-Invoice (A)';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Header; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.");
            RequestFilterFields = "No.";
        }
    }

    requestpage
    {
        PopulateAllFields = true;
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CopiesNumber; CopiesNumber)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';

                        trigger OnValidate()
                        begin
                            if CopiesNumber < 1 then
                                CopiesNumber := 1;
                        end;
                    }
                    field(AmountInvoiceDone; AmountInvoiceDone)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Currency';
                        OptionCaption = 'Invoice Currency,LCY';
                        ToolTip = 'Specifies if the currency code is shown in the report.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        ToolTip = 'Specifies that interactions with the related contact are logged.';
                    }
                    field(Preview; PreviewReport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview';
                        ToolTip = 'Specifies that the report can be previewed.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if CopiesNumber < 1 then
                CopiesNumber := 1;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        OrderFacturaInvoice: Report "Order Factura-Invoice (A)";
    begin
        OrderFacturaInvoice.InitializeRequest(
          CopiesNumber, AmountInvoiceDone, LogInteraction, PreviewReport, true);
        OrderFacturaInvoice.SetTableView(Header);
        OrderFacturaInvoice.UseRequestPage(false);
        OrderFacturaInvoice.Run();
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            CopiesNumber := 1;
    end;

    var
        CopiesNumber: Integer;
        AmountInvoiceDone: Option "Invoice Currency",LCY;
        LogInteraction: Boolean;
        PreviewReport: Boolean;
}

