// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 12112 "IT - Report Management"
{

    trigger OnRun()
    begin
    end;

    var
        UnpostedSalesDocumentsErr: Label 'An unposted sales document with posting number %1 exists, which you must post before you can continue.\\%2.', Comment = '%1=Posting No.,%2=Sales Header RecordID';
        UnpostedPurchDocumentsErr: Label 'An unposted purchase document with posting number %1 exists, which you must post before you can continue.\\%2.', Comment = '%1=Posting No.,%2=Purchase Header RecordID';
        UnpostedSalesDocumentsMsg: Label 'An unposted sales document with posting number %1 exists.\\%2.', Comment = '%1=Posting No.,%2=Sales Header RecordID';
        UnpostedPurchDocumentsMsg: Label 'An unposted puchase document with posting number %1 exists.\\%2.', Comment = '%1=Posting No.,%2=Purchase Header RecordID';

    procedure CheckSalesDocNoGaps(MaxDate: Date; ThrowError: Boolean)
    begin
        CheckSalesDocNoGaps(MaxDate, ThrowError, true);
    end;

    procedure CheckSalesDocNoGaps(MaxDate: Date; ThrowError: Boolean; ShowMessage: Boolean)
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDocNoGaps(MaxDate, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.SetFilter("Posting No.", '<>%1', '');
        if MaxDate <> 0D then
            SalesHeader.SetFilter("Posting Date", '<=%1', MaxDate);
        if not SalesHeader.FindFirst() then
            exit;
        if ThrowError then
            Error(UnpostedSalesDocumentsErr, SalesHeader."Posting No.", SalesHeader.RecordId);
        if ShowMessage then
            Message(UnpostedSalesDocumentsMsg, SalesHeader."Posting No.", SalesHeader.RecordId);
    end;

    procedure CheckPurchDocNoGaps(MaxDate: Date; ThrowError: Boolean)
    begin
        CheckPurchDocNoGaps(MaxDate, ThrowError, true);
    end;

    procedure CheckPurchDocNoGaps(MaxDate: Date; ThrowError: Boolean; ShowMessage: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchDocNoGaps(MaxDate, IsHandled);
        if IsHandled then
            exit;

        PurchaseHeader.SetFilter("Posting No.", '<>%1', '');
        if MaxDate <> 0D then
            PurchaseHeader.SetFilter("Posting Date", '<=%1', MaxDate);
        if not PurchaseHeader.FindFirst() then
            exit;

        if ThrowError then
            Error(UnpostedPurchDocumentsErr, PurchaseHeader."Posting No.", PurchaseHeader.RecordId);

        if ShowMessage then
            Message(UnpostedPurchDocumentsMsg, PurchaseHeader."Posting No.", PurchaseHeader.RecordId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchDocNoGaps(MaxDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDocNoGaps(MaxDate: Date; var IsHandled: Boolean)
    begin
    end;

}
