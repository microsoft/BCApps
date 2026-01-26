// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.EServices.EDocument;

page 10765 "Posted Sales Invoice - Update"
{
    Caption = 'Posted Sales Invoice - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Invoice Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posted invoice number.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you shipped the items on the invoice to.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the invoice was posted.';
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field(OperationDescription; OperationDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Operation Description';
                    Editable = true;
                    MultiLine = true;
                    ToolTip = 'Specifies the Operation Description.';

                    trigger OnValidate()
                    var
                        SIIManagement: Codeunit "SII Management";
                    begin
                        SIIManagement.SplitOperationDescription(OperationDescription, Rec."Operation Description", Rec."Operation Description 2");
                        Rec.Validate("Operation Description");
                        Rec.Validate("Operation Description 2");
                    end;
                }
                field("Special Scheme Code"; Rec."Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Special Scheme Code.';
                }
                field("Invoice Type"; Rec."Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Invoice Type.';

                    trigger OnValidate()
                    begin
                        SIIFirstSummaryDocNo := '';
                        SIILastSummaryDocNo := '';
                    end;
                }
                field("ID Type"; Rec."ID Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the ID Type.';
                }
                field("Succeeded Company Name"; Rec."Succeeded Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the name of the company successor in connection with corporate restructuring.';
                }
                field("Succeeded VAT Registration No."; Rec."Succeeded VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the VAT registration number of the company successor in connection with corporate restructuring.';
                }
                field("Issued By Third Party"; Rec."Issued By Third Party")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the invoice was issued by a third party.';
                }
                field("SII First Summary Doc. No."; SIIFirstSummaryDocNo)
                {
                    Caption = 'First Summary Doc. No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first number in the series of the summary entry. This field applies to F4-type invoices only.';
                    trigger OnValidate()
                    begin
                        Rec.SetSIIFirstSummaryDocNo(SIIFirstSummaryDocNo);
                    end;
                }
                field("SII Last Summary Doc. No."; SIILastSummaryDocNo)
                {
                    Caption = 'Last Summary Doc. No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number in the series of the summary entry. This field applies to F4-type invoices only.';
                    trigger OnValidate()
                    begin
                        Rec.SetSIILastSummaryDocNo(SIILastSummaryDocNo);
                    end;
                }
                field("Dispute Status"; Rec."Dispute Status")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Importance = Promoted;
                    Tooltip = 'Specifies if there is an ongoing dispute for this Invoice';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        xSalesInvoiceHeader := Rec;
        SIIManagement.CombineOperationDescription(Rec."Operation Description", Rec."Operation Description 2", OperationDescription);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Sales Invoice Header - Edit", Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        SIIFirstSummaryDocNo := Copystr(Rec.GetSIIFirstSummaryDocNo(), 1, 35);
        SIILastSummaryDocNo := Copystr(Rec.GetSIILastSummaryDocNo(), 1, 35);
    end;

    var
        xSalesInvoiceHeader: Record "Sales Invoice Header";
        OperationDescription: Text[500];
        SIIFirstSummaryDocNo: Text[35];
        SIILastSummaryDocNo: Text[35];

    local procedure RecordChanged() RecordIsChanged: Boolean
    begin
        RecordIsChanged :=
          (Rec."Operation Description" <> xSalesInvoiceHeader."Operation Description") or
          (Rec."Operation Description 2" <> xSalesInvoiceHeader."Operation Description 2") or
          (Rec."Special Scheme Code" <> xSalesInvoiceHeader."Special Scheme Code") or
          (Rec."Invoice Type" <> xSalesInvoiceHeader."Invoice Type") or
          (Rec."ID Type" <> xSalesInvoiceHeader."ID Type") or
          (Rec."Succeeded Company Name" <> xSalesInvoiceHeader."Succeeded Company Name") or
          (Rec."Succeeded VAT Registration No." <> xSalesInvoiceHeader."Succeeded VAT Registration No.") or
          (Rec."Issued By Third Party" <> xSalesInvoiceHeader."Issued By Third Party") or
          (Rec.GetSIIFirstSummaryDocNo() <> xSalesInvoiceHeader.GetSIIFirstSummaryDocNo()) or
          (Rec.GetSIILastSummaryDocNo() <> xSalesInvoiceHeader.GetSIILastSummaryDocNo()) or
          (Rec."Dispute Status" <> xSalesInvoiceHeader."Dispute Status");

        OnAfterRecordIsChanged(Rec, xSalesInvoiceHeader, RecordIsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        Rec := SalesInvoiceHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordIsChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var RecordIsChanged: Boolean)
    begin
    end;
}

