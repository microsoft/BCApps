// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using System.Security.User;
using System.Utilities;

/// <summary>
/// Manages user selection dialogs and confirmation prompts for document posting operations.
/// Provides standardized posting option selection for sales and purchase documents with print and email capabilities.
/// </summary>
/// <remarks>
/// Central posting selection engine handling user confirmation dialogs for various document posting scenarios.
/// Supports sales and purchase document posting with options for shipping, receiving, invoicing, printing, and emailing.
/// Integrates with user setup management for posting policy validation and restriction enforcement.
/// Provides extensible confirmation framework for custom posting scenarios and workflow integration.
/// </remarks>
codeunit 99 "Posting Selection Management"
{
    trigger OnRun()
    begin

    end;

    var
        ShipInvoiceOptionsQst: Label '&Ship,&Invoice,Ship &and Invoice';
        ReceiveInvoiceOptionsQst: Label '&Receive,&Invoice,Receive &and Invoice';
        ShipInvoiceFromWhseQst: Label '&Ship,Ship &and Invoice';
        ReceiveInvoiceFromWhseQst: Label '&Receive,Receive &and Invoice';
        PostDocConfirmQst: Label 'Do you want to post the %1?', Comment = '%1 = Document Type';
        PostWhseAndDocConfirmQst: Label 'Do you want to post the %1 and %2?', Comment = '%1 = Activity Type, %2 = Document Type';
        PostAndPrintConfirmQst: Label 'Do you want to post and print the %1?', Comment = '%1 = Document Type';
        PostAndEmailConfirmQst: Label 'Do you want to post and email the %1?', Comment = '%1 = Document Type';
        InvoiceConfirmQst: Label 'Do you want to post the invoice?';
        CreditMemoConfirmQst: Label 'Do you want to post the credit memo?';
        PrintInvoiceConfirmQst: Label 'Do you want to post and print the invoice?';
        PrintCreditMemoConfirmQst: Label 'Do you want to post and print the credit memo?';
        EmailInvoiceConfirmQst: Label 'Do you want to post and email the invoice?';
        EmailCreditMemoConfirmQst: Label 'Do you want to post and email the credit memo?';
        ShipConfirmQst: Label 'Do you want to post the shipment?';
        ShipInvoiceConfirmQst: Label 'Do you want to post the shipment and invoice?';
        ReceiveConfirmQst: Label 'Do you want to post the receipt?';
        ReceiveInvoiceConfirmQst: Label 'Do you want to post the receipt and invoice?';
        PostingInvoiceProhibitedErr: Label 'You cannot post the invoice because %1 is %2 in %3.', Comment = '%1 = Invoice Posting Policy, %2 = Prohibited, %3 = User Setup';

    /// <summary>
    /// Displays confirmation dialog for sales document posting with user selection options.
    /// </summary>
    /// <param name="SalesHeaderToPost">Sales header to post</param>
    /// <param name="DefaultOption">Default posting option (1=Ship, 2=Invoice, 3=Ship and Invoice)</param>
    /// <param name="WithPrint">Whether printing option is available</param>
    /// <param name="WithEmail">Whether email option is available</param>
    /// <returns>True if user confirmed posting, false if cancelled</returns>
    procedure ConfirmPostSalesDocument(var SalesHeaderToPost: Record "Sales Header"; DefaultOption: Integer; WithPrint: Boolean; WithEmail: Boolean) Result: Boolean
    var
        SalesHeader: Record "Sales Header";
        UserSetupManagement: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        Selection: Integer;
        IsHandled: Boolean;
    begin
        if DefaultOption > 3 then
            DefaultOption := 3;
        if DefaultOption <= 0 then
            DefaultOption := 1;

        SalesHeader.Copy(SalesHeaderToPost);

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                begin
                    IsHandled := false;
                    OnConfirmPostSalesDocumentOnBeforeSalesOrderGetSalesInvoicePostingPolicy(SalesHeader, IsHandled);
                    if not IsHandled then
                        UserSetupManagement.GetSalesInvoicePostingPolicy(SalesHeader.Ship, SalesHeader.Invoice);
                    case true of
                        not SalesHeader.Ship and not SalesHeader.Invoice:
                            begin
                                Selection := GetSalesOrderPostingSelection(SalesHeader, DefaultOption);
                                if Selection = 0 then
                                    exit(false);
                                SalesHeader.Ship := Selection in [1, 3];
                                SalesHeader.Invoice := Selection in [2, 3];
                            end;
                        SalesHeader.Ship and not SalesHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetShipConfirmationMessage(), true) then
                                exit(false);
                        SalesHeader.Ship and SalesHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetShipInvoiceConfirmationMessage(), true) then
                                exit(false);
                    end;
                end;
            SalesHeader."Document Type"::"Return Order":
                begin
                    IsHandled := false;
                    OnConfirmPostSalesDocumentOnBeforeSalesOrderReturnGetSalesInvoicePostingPolicy(SalesHeader, IsHandled);
                    if not IsHandled then
                        UserSetupManagement.GetSalesInvoicePostingPolicy(SalesHeader.Receive, SalesHeader.Invoice);
                    case true of
                        not SalesHeader.Receive and not SalesHeader.Invoice:
                            begin
                                Selection := StrMenu(ReceiveInvoiceOptionsQst, DefaultOption);
                                if Selection = 0 then
                                    exit(false);
                                SalesHeader.Receive := Selection in [1, 3];
                                SalesHeader.Invoice := Selection in [2, 3];
                            end;
                        SalesHeader.Receive and not SalesHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetReceiveConfirmationMessage(), true) then
                                exit(false);
                        SalesHeader.Receive and SalesHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetReceiveInvoiceConfirmationMessage(), true) then
                                exit(false);
                    end;
                end;
            SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo":
                begin
                    CheckUserCanInvoiceSales();
                    if not ConfirmManagement.GetResponseOrDefault(
                            GetPostConfirmationMessage(SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice, WithPrint, WithEmail), true)
                    then
                        exit(false);
                end;
            else
                if not ConfirmManagement.GetResponseOrDefault(
                        GetPostConfirmationMessage(Format(SalesHeader."Document Type"), WithPrint, WithEmail), true)
                then
                    exit(false);
        end;

        SalesHeaderToPost.Copy(SalesHeader);
        exit(true);
    end;

    /// <summary>
    /// Displays confirmation dialog for purchase document posting with user selection options.
    /// </summary>
    /// <param name="PurchaseHeaderToPost">Purchase header to post</param>
    /// <param name="DefaultOption">Default posting option (1=Receive, 2=Invoice, 3=Receive and Invoice)</param>
    /// <param name="WithPrint">Whether printing option is available</param>
    /// <param name="WithEmail">Whether email option is available</param>
    /// <returns>True if user confirmed posting, false if cancelled</returns>
    procedure ConfirmPostPurchaseDocument(var PurchaseHeaderToPost: Record "Purchase Header"; DefaultOption: Integer; WithPrint: Boolean; WithEmail: Boolean) Result: Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        UserSetupManagement: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        Selection: Integer;
        IsHandled: Boolean;
    begin
        if DefaultOption > 3 then
            DefaultOption := 3;
        if DefaultOption <= 0 then
            DefaultOption := 1;

        PurchaseHeader.Copy(PurchaseHeaderToPost);

        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                begin
                    IsHandled := false;
                    OnConfirmPostPurchaseDocumentOnBeforePurchaseOrderGetPurchaseInvoicePostingPolicy(PurchaseHeader, IsHandled);
                    if not IsHandled then
                        UserSetupManagement.GetPurchaseInvoicePostingPolicy(PurchaseHeader.Receive, PurchaseHeader.Invoice);
                    case true of
                        not PurchaseHeader.Receive and not PurchaseHeader.Invoice:
                            begin
                                Selection := GetPurchaseOrderPostingSelection(PurchaseHeader, DefaultOption);
                                if Selection = 0 then
                                    exit(false);
                                PurchaseHeader.Receive := Selection in [1, 3];
                                PurchaseHeader.Invoice := Selection in [2, 3];
                            end;
                        PurchaseHeader.Receive and not PurchaseHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetReceiveConfirmationMessage(), true) then
                                exit(false);
                        PurchaseHeader.Receive and PurchaseHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetReceiveInvoiceConfirmationMessage(), true) then
                                exit(false);
                    end;
                end;
            PurchaseHeader."Document Type"::"Return Order":
                begin
                    IsHandled := false;
                    OnConfirmPostPurchaseDocumentOnBeforePurchaseReturnOrderGetPurchaseInvoicePostingPolicy(PurchaseHeader, IsHandled);
                    if not IsHandled then
                        UserSetupManagement.GetPurchaseInvoicePostingPolicy(PurchaseHeader.Ship, PurchaseHeader.Invoice);
                    case true of
                        not PurchaseHeader.Ship and not PurchaseHeader.Invoice:
                            begin
                                Selection := StrMenu(ShipInvoiceOptionsQst, DefaultOption);
                                if Selection = 0 then
                                    exit(false);
                                PurchaseHeader.Ship := Selection in [1, 3];
                                PurchaseHeader.Invoice := Selection in [2, 3];
                            end;
                        PurchaseHeader.Ship and not PurchaseHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetShipConfirmationMessage(), true) then
                                exit(false);
                        PurchaseHeader.Ship and PurchaseHeader.Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(GetShipInvoiceConfirmationMessage(), true) then
                                exit(false);
                    end;
                end;
            PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::"Credit Memo":
                begin
                    CheckUserCanInvoicePurchase();
                    if not ConfirmManagement.GetResponseOrDefault(
                            GetPostConfirmationMessage(PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice, WithPrint, WithEmail), true)
                    then
                        exit(false);
                end;
            else
                if not ConfirmManagement.GetResponseOrDefault(
                        GetPostConfirmationMessage(Format(PurchaseHeader."Document Type"), WithPrint, WithEmail), true)
                then
                    exit(false);
        end;

        PurchaseHeaderToPost.Copy(PurchaseHeader);
        exit(true);
    end;


    /// <summary>
    /// Displays confirmation dialog for warehouse activity posting with user selection options.
    /// </summary>
    /// <param name="WarehouseActivityLine">Warehouse activity line to post</param>
    /// <param name="Selection">Selected posting option returned to caller</param>
    /// <param name="DefaultOption">Default posting option</param>
    /// <param name="WithPrint">Whether printing option is available</param>
    /// <returns>True if user confirmed posting, false if cancelled</returns>
    procedure ConfirmPostWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Selection: Integer; DefaultOption: Integer; WithPrint: Boolean) Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if DefaultOption < 1 then
            DefaultOption := 1;
        if DefaultOption > 2 then
            DefaultOption := 2;

        case WarehouseActivityLine."Activity Type" of
            WarehouseActivityLine."Activity Type"::"Invt. Put-away":
                begin
                    if WarehouseActivityLine."Source Document" in ["Warehouse Activity Source Document"::"Prod. Output",
                                                               "Warehouse Activity Source Document"::"Inbound Transfer",
                                                               "Warehouse Activity Source Document"::"Prod. Consumption"]
                    then
                        exit(
                            ConfirmManagement.GetResponseOrDefault(
                              StrSubstNo(PostWhseAndDocConfirmQst, WarehouseActivityLine."Activity Type", WarehouseActivityLine."Source Document"), false));

                    exit(GetReceiveInvoiceSelectionForWhseActivity(DefaultOption, Selection));
                end;
            else begin
                if WarehouseActivityLine."Source Document" in ["Warehouse Activity Source Document"::"Prod. Consumption",
                                                            "Warehouse Activity Source Document"::"Outbound Transfer",
                                                            "Warehouse Activity Source Document"::"Job Usage"]
                then
                    exit(
                    ConfirmManagement.GetResponseOrDefault(
                        StrSubstNo(PostWhseAndDocConfirmQst, WarehouseActivityLine."Activity Type", WarehouseActivityLine."Source Document"), false));

                exit(GetShipInvoiceSelectionForWhseActivity(WarehouseActivityLine."Source Document", DefaultOption, Selection));
            end;
        end;

        exit(true);
    end;

    /// <summary>
    /// Displays confirmation dialog for warehouse shipment posting with user selection options.
    /// </summary>
    /// <param name="WarehouseShipmentLine">Warehouse shipment line to post</param>
    /// <param name="Selection">Selected posting option returned to caller</param>
    /// <returns>True if user confirmed posting, false if cancelled</returns>
    procedure ConfirmPostWhseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Selection: Integer) Result: Boolean
    var
        DefaultOption: Integer;
    begin
        DefaultOption := 1;
        Result := GetShipInvoiceSelectionForWhseActivity(WarehouseShipmentLine."Source Document", DefaultOption, Selection);
        exit(Result);
    end;

    /// <summary>
    /// Verifies that the current user has permission to invoice sales documents.
    /// </summary>
    procedure CheckUserCanInvoiceSales()
    var
        UserSetup: Record "User Setup";
        UserSetupManagement: Codeunit "User Setup Management";
        Ship: Boolean;
        Invoice: Boolean;
    begin
        UserSetupManagement.GetSalesInvoicePostingPolicy(Ship, Invoice);
        if Ship and not Invoice then
            Error(
              PostingInvoiceProhibitedErr,
              UserSetup.FieldCaption("Sales Invoice Posting Policy"), Format("Invoice Posting Policy"::Prohibited),
              UserSetup.TableCaption);
    end;

    /// <summary>
    /// Verifies that the current user has permission to invoice purchase documents.
    /// </summary>
    procedure CheckUserCanInvoicePurchase()
    var
        UserSetup: Record "User Setup";
        UserSetupManagement: Codeunit "User Setup Management";
        Receive: Boolean;
        Invoice: Boolean;
    begin
        UserSetupManagement.GetPurchaseInvoicePostingPolicy(Receive, Invoice);
        if Receive and not Invoice then
            Error(
              PostingInvoiceProhibitedErr,
              UserSetup.FieldCaption("Purch. Invoice Posting Policy"), Format("Invoice Posting Policy"::Prohibited),
              UserSetup.TableCaption);
    end;

    internal procedure IsPostingInvoiceMandatoryPurchase(): Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        Receive: Boolean;
        Invoice: Boolean;
    begin
        UserSetupManagement.GetPurchaseInvoicePostingPolicy(Receive, Invoice);
        exit(Receive and Invoice);
    end;


    local procedure GetShipInvoiceSelectionForWhseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; DefaultOption: Integer; var Selection: Integer): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Ship, Invoice, IsHandled, Result : Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeGetShipInvoiceSelectionForWhseActivity(DefaultOption, Selection, IsHandled, Result);
        if IsHandled then
            exit(Result);

        GetInvoicePostingPolicy(SourceDocument, Ship, Invoice);

        case true of
            not Ship and not Invoice:
                begin
                    Selection := StrMenu(ShipInvoiceFromWhseQst, DefaultOption);
                    if Selection = 0 then
                        exit(false);
                end;
            Ship and not Invoice:
                begin
                    if not ConfirmManagement.GetResponseOrDefault(GetShipConfirmationMessage(), true) then
                        exit(false);
                    Selection := 1;
                end;
            Ship and Invoice:
                begin
                    if not ConfirmManagement.GetResponseOrDefault(GetShipInvoiceConfirmationMessage(), true) then
                        exit(false);
                    Selection := 2;
                end;
        end;
        exit(true);
    end;

    local procedure GetInvoicePostingPolicy(SourceDocument: Enum "Warehouse Activity Source Document"; var Ship: Boolean; var Invoice: Boolean)
    var
        UserSetupManagement: Codeunit "User Setup Management";
    begin
        UserSetupManagement.GetSalesInvoicePostingPolicy(Ship, Invoice);

        OnAfterGetInvoicePostingPolicy(SourceDocument, Ship, Invoice);
    end;

    local procedure GetReceiveInvoiceSelectionForWhseActivity(DefaultOption: Integer; var Selection: Integer): Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        Receive: Boolean;
        Invoice: Boolean;
    begin
        UserSetupManagement.GetPurchaseInvoicePostingPolicy(Receive, Invoice);
        case true of
            not Receive and not Invoice:
                begin
                    Selection := StrMenu(ReceiveInvoiceFromWhseQst, DefaultOption);
                    if Selection = 0 then
                        exit(false);
                end;
            Receive and not Invoice:
                begin
                    if not ConfirmManagement.GetResponseOrDefault(GetReceiveConfirmationMessage(), true) then
                        exit(false);
                    Selection := 1;
                end;
            Receive and Invoice:
                begin
                    if not ConfirmManagement.GetResponseOrDefault(GetReceiveInvoiceConfirmationMessage(), true) then
                        exit(false);
                    Selection := 2;
                end;
        end;
        exit(true);
    end;

    /// <summary>
    /// Returns confirmation message text for posting operations with print and email options.
    /// </summary>
    /// <param name="What">Document type or operation description</param>
    /// <param name="WithPrint">Whether printing option is included</param>
    /// <param name="WithEmail">Whether email option is included</param>
    /// <returns>Formatted confirmation message text</returns>
    procedure GetPostConfirmationMessage(What: Text; WithPrint: Boolean; WithEmail: Boolean): Text
    begin
        if WithPrint then
            exit(StrSubstNo(PostAndPrintConfirmQst, What));

        if WithEmail then
            exit(StrSubstNo(PostAndEmailConfirmQst, What));

        exit(StrSubstNo(PostDocConfirmQst, What));
    end;

    /// <summary>
    /// Returns confirmation message text for invoice posting operations with print and email options.
    /// </summary>
    /// <param name="IsInvoice">Whether operation is invoicing</param>
    /// <param name="WithPrint">Whether printing option is included</param>
    /// <param name="WithEmail">Whether email option is included</param>
    /// <returns>Formatted confirmation message text</returns>
    procedure GetPostConfirmationMessage(IsInvoice: Boolean; WithPrint: Boolean; WithEmail: Boolean): Text
    begin
        if IsInvoice then begin
            if WithPrint then
                exit(PrintInvoiceConfirmQst);

            if WithEmail then
                exit(EmailInvoiceConfirmQst);

            exit(InvoiceConfirmQst);
        end else begin
            if WithPrint then
                exit(PrintCreditMemoConfirmQst);

            if WithEmail then
                exit(EmailCreditMemoConfirmQst);

            exit(CreditMemoConfirmQst);
        end;
    end;

    /// <summary>
    /// Returns confirmation message text for shipping operations.
    /// </summary>
    /// <returns>Ship confirmation message text</returns>
    procedure GetShipConfirmationMessage(): Text
    begin
        exit(ShipConfirmQst);
    end;

    /// <summary>
    /// Returns confirmation message text for ship and invoice operations.
    /// </summary>
    /// <returns>Ship and invoice confirmation message text</returns>
    procedure GetShipInvoiceConfirmationMessage(): Text
    begin
        exit(ShipInvoiceConfirmQst);
    end;

    /// <summary>
    /// Returns confirmation message text for receiving operations.
    /// </summary>
    /// <returns>Receive confirmation message text</returns>
    procedure GetReceiveConfirmationMessage(): Text
    begin
        exit(ReceiveConfirmQst);
    end;

    local procedure GetReceiveInvoiceConfirmationMessage(): Text
    begin
        exit(ReceiveInvoiceConfirmQst);
    end;

    /// <summary>
    /// Returns error message text for prohibited invoice posting.
    /// </summary>
    /// <returns>Posting invoice prohibited error message text</returns>
    procedure GetPostingInvoiceProhibitedErr(): Text
    begin
        exit(PostingInvoiceProhibitedErr);
    end;

    local procedure GetSalesOrderPostingSelection(var SalesHeader: Record "Sales Header"; DefaultOption: Integer) Selection: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesOrderPostingSelection(SalesHeader, DefaultOption, IsHandled, Selection);
        if IsHandled then
            exit(Selection);

        Selection := StrMenu(ShipInvoiceOptionsQst, DefaultOption);
    end;

    local procedure GetPurchaseOrderPostingSelection(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer) Selection: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchaseOrderPostingSelection(PurchaseHeader, DefaultOption, IsHandled, Selection);
        if IsHandled then
            exit(Selection);

        Selection := StrMenu(ReceiveInvoiceOptionsQst, DefaultOption);
    end;

    /// <summary>
    /// Integration event raised before getting sales invoice posting policy for sales orders.
    /// </summary>
    /// <param name="SalesHeader">Sales header for policy determination</param>
    /// <param name="IsHandled">Set to true to skip standard policy processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnConfirmPostSalesDocumentOnBeforeSalesOrderGetSalesInvoicePostingPolicy(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before getting sales invoice posting policy for sales return orders.
    /// </summary>
    /// <param name="SalesHeader">Sales header for policy determination</param>
    /// <param name="IsHandled">Set to true to skip standard policy processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnConfirmPostSalesDocumentOnBeforeSalesOrderReturnGetSalesInvoicePostingPolicy(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before getting purchase invoice posting policy for purchase orders.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase header for policy determination</param>
    /// <param name="IsHandled">Set to true to skip standard policy processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnConfirmPostPurchaseDocumentOnBeforePurchaseOrderGetPurchaseInvoicePostingPolicy(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before getting purchase invoice posting policy for purchase return orders.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase header for policy determination</param>
    /// <param name="IsHandled">Set to true to skip standard policy processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnConfirmPostPurchaseDocumentOnBeforePurchaseReturnOrderGetPurchaseInvoicePostingPolicy(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before getting ship/invoice selection for warehouse activities.
    /// </summary>
    /// <param name="DefaultOption">Default posting option</param>
    /// <param name="Selection">Selected posting option to return</param>
    /// <param name="IsHandled">Set to true to skip standard selection processing</param>
    /// <param name="Result">Result to return if handled</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShipInvoiceSelectionForWhseActivity(var DefaultOption: Integer; var Selection: Integer; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after determining invoice posting policy for warehouse activities.
    /// Enables customization of posting policy decisions based on warehouse source documents.
    /// </summary>
    /// <param name="SourceDocument">Warehouse activity source document type</param>
    /// <param name="Ship">Whether shipping should be performed</param>
    /// <param name="Invoice">Whether invoicing should be performed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetInvoicePostingPolicy(SourceDocument: Enum "Warehouse Activity Source Document"; var Ship: Boolean; var Invoice: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before determining sales order posting selection.
    /// Enables custom logic for posting option selection and validation.
    /// </summary>
    /// <param name="SalesHeader">Sales order header being processed</param>
    /// <param name="DefaultOption">Default posting option to display</param>
    /// <param name="IsHandled">Set to true to skip standard posting selection logic</param>
    /// <param name="Selection">Selected posting option result</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesOrderPostingSelection(var SalesHeader: Record "Sales Header"; DefaultOption: Integer; var IsHandled: Boolean; var Selection: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before determining purchase order posting selection.
    /// Enables custom logic for posting option selection and validation.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase order header being processed</param>
    /// <param name="DefaultOption">Default posting option to display</param>
    /// <param name="IsHandled">Set to true to skip standard posting selection logic</param>
    /// <param name="Selection">Selected posting option result</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchaseOrderPostingSelection(var PurchaseHeader: Record "Purchase Header"; DefaultOption: Integer; var IsHandled: Boolean; var Selection: Integer)
    begin
    end;
}