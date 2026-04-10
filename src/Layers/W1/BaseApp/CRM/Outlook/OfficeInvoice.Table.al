// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;

table 1606 "Office Invoice"
{
    Caption = 'Office Invoice', Comment = 'This table is used to keep track of invoices that have been created from the context of an Office add-in.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item ID"; Text[250])
        {
            Caption = 'Item ID';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the related document.';
        }
        field(3; Posted; Boolean)
        {
            Caption = 'Posted';
            ToolTip = 'Specifies whether the document has been posted.';
        }
    }

    keys
    {
        key(Key1; "Item ID", "Document No.", Posted)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ShowInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PageManagement: Codeunit "Page Management";
    begin
        if Posted then begin
            SalesInvoiceHeader.Get("Document No.");
            PageManagement.PageRun(SalesInvoiceHeader);
        end else begin
            SalesHeader.Get(SalesHeader."Document Type"::Invoice, "Document No.");
            PageManagement.PageRun(SalesHeader);
        end;
    end;

    procedure UnlinkDocument(DocumentNo: Code[20]; IsPosted: Boolean)
    var
        OfficeInvoice: Record "Office Invoice";
    begin
        OfficeInvoice.SetRange("Document No.", DocumentNo);
        OfficeInvoice.SetRange(Posted, IsPosted);
        OfficeInvoice.DeleteAll();
    end;
}

