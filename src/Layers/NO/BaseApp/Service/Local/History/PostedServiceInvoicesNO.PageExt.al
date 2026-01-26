// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;

pageextension 10619 "Posted Service Invoices NO" extends "Posted Service Invoices"
{
    actions
    {
        addafter(Dimensions)
        {
            separator(Action1080000)
            {
            }
            action("Create Electronic Invoice")
            {
                ApplicationArea = Service;
                Caption = 'Create Electronic Invoice';
                Image = CreateDocument;
                ToolTip = 'Create one or more XML documents that you can send to the customer. You can run the batch job for multiple invoices or you can run it for an individual invoice. The document number is used as the file name. The files are stored at the location that has been specified in the Sales & Receivables Setup window.';
                Visible = false;

                trigger OnAction()
                var
                    ServiceInvoiceHeader: Record "Service Invoice Header";
                begin
                    ServiceInvoiceHeader := Rec;
                    ServiceInvoiceHeader.SetRecFilter();
                    REPORT.RunModal(REPORT::"Create Elec. Service Invoices", true, false, ServiceInvoiceHeader);
                end;
            }
        }
    }
}