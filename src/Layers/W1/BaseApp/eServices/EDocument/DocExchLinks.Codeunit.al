// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.History;

codeunit 1411 "Doc. Exch. Links"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;

    trigger OnRun()
    begin
    end;

    var
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";

        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';

    procedure UpdateDocumentRecord(DocRecRef: RecordRef; DocIdentifier: Text; DocOrigIdentifier: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDocumentRecord(DocRecRef, DocIdentifier, DocOrigIdentifier, IsHandled);
        if IsHandled then
            exit;

        DocRecRef.Find();
        case DocRecRef.Number of
            DATABASE::"Sales Invoice Header":
                SetInvoiceDocSent(DocRecRef, DocIdentifier, DocOrigIdentifier);
            DATABASE::"Sales Cr.Memo Header":
                SetCrMemoDocSent(DocRecRef, DocIdentifier, DocOrigIdentifier);
            else
                Error(UnSupportedTableTypeErr, DocRecRef.Number);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchCrMemoStatus(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        NewStatus: Enum "Sales Document Exchange Status";
    begin
        NewStatus := MapDocExchStatusToSalesCMStatus(
            DocExchServiceMgt.GetDocumentStatus(SalesCrMemoHeader.RecordId, SalesCrMemoHeader."Document Exchange Identifier", SalesCrMemoHeader."Doc. Exch. Original Identifier"));
        if NewStatus <> SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service" then begin
            SalesCrMemoHeader.Validate(SalesCrMemoHeader."Document Exchange Status", NewStatus);
            SalesCrMemoHeader.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchInvoiceStatus(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        NewStatus: Enum "Sales Document Exchange Status";
    begin
        NewStatus := MapDocExchStatusToSalesInvStatus(
            DocExchServiceMgt.GetDocumentStatus(SalesInvoiceHeader.RecordId, SalesInvoiceHeader."Document Exchange Identifier", SalesInvoiceHeader."Doc. Exch. Original Identifier"));
        if NewStatus <> SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service" then begin
            SalesInvoiceHeader.Validate(SalesInvoiceHeader."Document Exchange Status", NewStatus);
            SalesInvoiceHeader.Modify(true);
        end;
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServDocExchangeMgt', '25.0')]
    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchServiceInvoiceStatus(var ServiceInvoiceHeader: Record Microsoft.Service.History."Service Invoice Header")
    var
        ServDocExchangeMgt: Codeunit "Serv. Doc. Exchange Mgt.";
    begin
        ServDocExchangeMgt.CheckAndUpdateDocExchServiceInvoiceStatus(ServiceInvoiceHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServDocExchangeMgt', '25.0')]
    [Scope('OnPrem')]
    procedure CheckAndUpdateDocExchServiceCrMemoStatus(var ServiceCrMemoHeader: Record Microsoft.Service.History."Service Cr.Memo Header")
    var
        ServDocExchangeMgt: Codeunit "Serv. Doc. Exchange Mgt.";
    begin
        ServDocExchangeMgt.CheckAndUpdateDocExchServiceCrMemoStatus(ServiceCrMemoHeader);
    end;
#endif

    local procedure SetInvoiceDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        DocRecRef.SetTable(SalesInvoiceHeader);
        SalesInvoiceHeader.Validate("Document Exchange Identifier",
          CopyStr(DocIdentifier, 1, MaxStrLen(SalesInvoiceHeader."Document Exchange Identifier")));
        SalesInvoiceHeader.Validate("Doc. Exch. Original Identifier",
          CopyStr(DocOriginalIdentifier, 1, MaxStrLen(SalesInvoiceHeader."Doc. Exch. Original Identifier")));
        SalesInvoiceHeader.Validate("Document Exchange Status", SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        SalesInvoiceHeader.Modify(true);
    end;

    local procedure SetCrMemoDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        DocRecRef.SetTable(SalesCrMemoHeader);
        SalesCrMemoHeader.Validate("Document Exchange Identifier",
          CopyStr(DocIdentifier, 1, MaxStrLen(SalesCrMemoHeader."Document Exchange Identifier")));
        SalesCrMemoHeader.Validate("Doc. Exch. Original Identifier",
          CopyStr(DocOriginalIdentifier, 1, MaxStrLen(SalesCrMemoHeader."Doc. Exch. Original Identifier")));
        SalesCrMemoHeader.Validate("Document Exchange Status", SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        SalesCrMemoHeader.Modify(true);
    end;

    local procedure MapDocExchStatusToSalesInvStatus(DocExchStatus: Text): Enum "Sales Document Exchange Status"
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit("Sales Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit("Sales Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit("Sales Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit("Sales Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    local procedure MapDocExchStatusToSalesCMStatus(DocExchStatus: Text): Enum "Sales Document Exchange Status"
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit("Sales Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit("Sales Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit("Sales Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit("Sales Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocumentRecord(DocRecRef: RecordRef; DocIdentifier: Text; DocOrigIdentifier: Text; var IsHandled: Boolean)
    begin
    end;
}

