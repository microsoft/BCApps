// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;
using Microsoft.Finance.GeneralLedger.Setup;

page 1355 "Posted Sales Inv. - Update"
{
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Invoice Header";
    SourceTableTemporary = true;
    Caption = 'Posted Sales Inv. - Update';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer at the sell-to address.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date for the document.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent Service';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Suite;
                    Editable = true;
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the date on which the invoice is due for payment.';
                }
                field("Promised Pay Date"; Rec."Promised Pay Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the date on which the customer have promised to pay this invoice.';
                }
                field("Dispute Status"; Rec."Dispute Status")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Importance = Promoted;
                    Tooltip = 'Specifies if there is an ongoing dispute for this Invoice';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s reference. The contents will be printed on sales documents.';
                }
            }
            group(Payment)
            {
                Caption = 'Payment';
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Method Code';
                    ToolTip = 'Specifies how the customer must pay for products on the sales document, such as with bank transfer, cash, or check.';
                    Visible = IsPaymentMethodCodeVisible;
                }
                field("Payment Reference"; Rec."Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Reference';
                    ToolTip = 'Specifies the payment of the sales invoice.';
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Bank Account Code';
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                    Visible = IsCompanyBankAccountVisible;
                }
            }
            group("Electronic Document")
            {
                Caption = 'Electronic Document';
                field("CFDI Cancellation Reason Code"; Rec."CFDI Cancellation Reason Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the reason for the cancellation as a code.';
                }
                field("Substitution Document No."; Rec."Substitution Document No.")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the document number that replaces the canceled one. It is required when the cancellation reason is 01.';
                }
                field("Fiscal Invoice Number PAC"; Rec."Fiscal Invoice Number PAC")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the official invoice number for the related electronic document. When you generate an electronic document, Business Central sends it to a an authorized service provider, PAC, for processing. When the PAC returns the electronic document with the digital stamp, the electronic document includes a fiscal invoice number that uniquely identifies the document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xSalesInvoiceHeader := Rec;
        GLSetup.Get();
        IsPaymentMethodCodeVisible := not GLSetup."Hide Payment Method Code";
        IsCompanyBankAccountVisible := not GLSetup."Hide Company Bank Account";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Sales Inv. Header - Edit", Rec);
    end;

    var
        xSalesInvoiceHeader: Record "Sales Invoice Header";
        GLSetup: Record "General Ledger Setup";
        IsPaymentMethodCodeVisible: Boolean;
        IsCompanyBankAccountVisible: Boolean;

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged := (Rec."Payment Method Code" <> xSalesInvoiceHeader."Payment Method Code") or
          (Rec."Payment Reference" <> xSalesInvoiceHeader."Payment Reference") or
          (Rec."Company Bank Account Code" <> xSalesInvoiceHeader."Company Bank Account Code") or
          (Rec."CFDI Cancellation Reason Code" <> xSalesInvoiceHeader."CFDI Cancellation Reason Code") or
          (Rec."Substitution Document No." <> xSalesInvoiceHeader."Substitution Document No.") or
          (Rec."Posting Description" <> xSalesInvoiceHeader."Posting Description") or
          (Rec."Fiscal Invoice Number PAC" <> xSalesInvoiceHeader."Fiscal Invoice Number PAC") or
          (Rec."Posting Description" <> xSalesInvoiceHeader."Posting Description") or
          (Rec."Promised Pay Date" <> xSalesInvoiceHeader."Promised Pay Date") or
          (Rec."Dispute Status" <> xSalesInvoiceHeader."Dispute Status") or
          (Rec."Shipping Agent Code" <> xSalesInvoiceHeader."Shipping Agent Code") or
          (Rec."Shipping Agent Service Code" <> xSalesInvoiceHeader."Shipping Agent Service Code") or
          (Rec."Package Tracking No." <> xSalesInvoiceHeader."Package Tracking No.") or
          (Rec."Due Date" <> xSalesInvoiceHeader."Due Date") or
          (Rec."Your Reference" <> xSalesInvoiceHeader."Your Reference");

        OnAfterRecordChanged(Rec, xSalesInvoiceHeader, IsChanged);
    end;

    procedure SetRec(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        Rec := SalesInvoiceHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var IsChanged: Boolean)
    begin
    end;
}

