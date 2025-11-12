// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Telemetry;
using System.Utilities;

codeunit 427 ICInboxOutboxMgt
{
    Permissions = TableData "General Ledger Setup" = rm;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        DimMgt: Codeunit DimensionManagement;
        GLSetupFound: Boolean;
        CompanyInfoFound: Boolean;
#pragma warning disable AA0074
        Text000: Label 'Do you want to re-create the transaction?';
#pragma warning disable AA0470
        Text001: Label '%1 %2 does not exist as a %3 in %1 %4.';
        Text002: Label 'You cannot send IC document because %1 %2 has %3 %4.';
        Text004: Label 'Transaction %1 for %2 %3 already exists in the %4 table.';
        Text005: Label '%1 must be %2 or %3 in order to be re-created.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NoItemForCommonItemErr: Label 'There is no Item related to Common Item No. %1.', Comment = '%1 = Common Item No value';
        TransactionAlreadyExistsInOutboxHandledQst: Label '%1 %2 has already been sent to intercompany partner %3. Resending it will create a duplicate %1 for them. Do you want to send it again?', Comment = '%1 - Document Type, %2 - Document No, %3 - IC parthner code';
        TransactionCantBeFoundErr: Label 'The Intercompany transaction that originated this document cannot be found.';
        DuplicateICDocumentMsg: Label 'An %1 with no. %2 has been previously received through intercompany. You have an order and an invoice for the same document which can lead to duplicating information. You can remove one of these documents or use Reject IC Document.', Comment = '%1 - either "order", "invoice", or "posted invoice", %2 - a code';
        PermissionToAutoAcceptICDocsErr: Label 'Auto-accepting intercompany documents requires scheduling permissions which you do not have assigned, delegated administrators can not schedule tasks.';


    procedure CreateOutboxJnlTransaction(TempGenJnlLine: Record "Gen. Journal Line" temporary; Rejection: Boolean): Integer
    var
        ICPartner: Record "IC Partner";
        OutboxJnlTransaction: Record "IC Outbox Transaction";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICTransactionNo: Integer;
    begin
        ICPartner.Get(TempGenJnlLine."IC Partner Code");
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
            exit(0);

        FeatureTelemetry.LogUptake('0000IJ4', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IJV', ICMapping.GetFeatureTelemetryName(), 'Creating Outbox Journal Transaction');

        GLSetup.LockTable();
        GetGLSetup();
        if GLSetup."Last IC Transaction No." < 0 then
            GLSetup."Last IC Transaction No." := 0;
        ICTransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := ICTransactionNo;
        GLSetup.Modify();

        OutboxJnlTransaction.Init();
        OutboxJnlTransaction."Transaction No." := ICTransactionNo;
        OutboxJnlTransaction."IC Partner Code" := TempGenJnlLine."IC Partner Code";
        OutboxJnlTransaction."IC Source Type" := OutboxJnlTransaction."IC Source Type"::Journal;
        OutboxJnlTransaction."Document Type" := TempGenJnlLine."Document Type";
        OutboxJnlTransaction."Document No." := TempGenJnlLine."Document No.";
        OutboxJnlTransaction."Posting Date" := TempGenJnlLine."Posting Date";
        OutboxJnlTransaction."Document Date" := TempGenJnlLine."Document Date";
        OutboxJnlTransaction."IC Account Type" := TempGenJnlLine."IC Account Type";
        OutboxJnlTransaction."IC Account No." := TempGenJnlLine."IC Account No.";
        OutboxJnlTransaction."Source Line No." := TempGenJnlLine."Source Line No.";
        if Rejection then
            OutboxJnlTransaction."Transaction Source" := OutboxJnlTransaction."Transaction Source"::"Rejected by Current Company"
        else
            OutboxJnlTransaction."Transaction Source" := OutboxJnlTransaction."Transaction Source"::"Created by Current Company";
        OnCreateOutboxJnlTransactionOnBeforeOutboxJnlTransactionInsert(OutboxJnlTransaction, TempGenJnlLine);
        OutboxJnlTransaction.Insert();
        OnInsertICOutboxTransaction(OutboxJnlTransaction, TempGenJnlLine);
        exit(ICTransactionNo);
    end;

    procedure SendSalesDoc(var SalesHeader: Record "Sales Header"; Post: Boolean)
    var
        ICPartner: Record "IC Partner";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJ5', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IJW', ICMapping.GetFeatureTelemetryName(), 'Sending Sales Document');
        IsHandled := false;
        OnBeforeSendSalesDoc(SalesHeader, Post, IsHandled);
        if not IsHandled then begin

            IsHandled := false;
            OnSendSalesDocOnbeforeTestSendICDocument(SalesHeader, IsHandled);
            if not IsHandled then
                SalesHeader.TestField("Send IC Document");

            if SalesHeader."Sell-to IC Partner Code" <> '' then
                ICPartner.Get(SalesHeader."Sell-to IC Partner Code")
            else
                ICPartner.Get(SalesHeader."Bill-to IC Partner Code");
            if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
                if Post then
                    exit
                else
                    Error(Text002, ICPartner.TableCaption(), ICPartner.Code, ICPartner.FieldCaption("Inbox Type"), ICPartner."Inbox Type");
            ICPartner.TestField(Blocked, false);
            OnSendSalesDocOnBeforeReleaseSalesDocument(SalesHeader, Post);

            CheckICSalesDocumentAlreadySent(SalesHeader);

            if not Post then
                CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);
            if SalesHeader."Sell-to IC Partner Code" <> '' then
                CreateOutboxSalesDocTrans(SalesHeader, false, Post);
        end;

        OnAfterSendSalesDoc(SalesHeader, Post);
    end;

    procedure SendPurchDoc(var PurchHeader: Record "Purchase Header"; Post: Boolean)
    var
        ICPartner: Record "IC Partner";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJ6', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IJX', ICMapping.GetFeatureTelemetryName(), 'Sending Purchase Document');

        IsHandled := false;
        OnBeforeSendPurchDoc(PurchHeader, Post, IsHandled);
        if not IsHandled then begin
            PurchHeader.TestField("Send IC Document");
            ICPartner.Get(PurchHeader."Buy-from IC Partner Code");
            if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
                if Post then
                    exit
                else
                    Error(Text002, ICPartner.TableCaption(), ICPartner.Code, ICPartner.FieldCaption("Inbox Type"), ICPartner."Inbox Type");
            ICPartner.TestField(Blocked, false);

            OnSendPurchDocOnBeforeReleasePurchDocument(PurchHeader, Post);

            CheckICPurchaseDocumentAlreadySent(PurchHeader);

            if not Post then
                CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchHeader);
            CreateOutboxPurchDocTrans(PurchHeader, false, Post);
        end;

        OnAfterSendPurchDoc(PurchHeader, Post);
    end;

    procedure CreateOutboxSalesDocTrans(SalesHeader: Record "Sales Header"; Rejection: Boolean; Post: Boolean)
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ICOutBoxSalesHeader: Record "IC Outbox Sales Header";
        ICOutBoxSalesLine: Record "IC Outbox Sales Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        TransactionNo: Integer;
        LinesCreated: Boolean;
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJ7', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IJY', ICMapping.GetFeatureTelemetryName(), 'Creating Outbox Sales Document Transaction');

        IsHandled := false;
        OnBeforeCreateOutboxSalesDocTrans(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        GLSetup.LockTable();
        GetGLSetup();
        TransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := TransactionNo;
        GLSetup.Modify();
        Customer.Get(SalesHeader."Sell-to Customer No.");
        OutboxTransaction.Init();
        OutboxTransaction."Transaction No." := TransactionNo;
        OutboxTransaction."IC Partner Code" := Customer."IC Partner Code";
        OutboxTransaction."IC Source Type" := OutboxTransaction."IC Source Type"::"Sales Document";
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Order;
            SalesHeader."Document Type"::Invoice:
                OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Invoice;
            SalesHeader."Document Type"::"Credit Memo":
                OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Credit Memo";
            SalesHeader."Document Type"::"Return Order":
                OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Return Order";
        end;
        OutboxTransaction."Document No." := SalesHeader."No.";
        OutboxTransaction."Posting Date" := SalesHeader."Posting Date";
        OutboxTransaction."Document Date" := SalesHeader."Document Date";
        if Rejection then
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Rejected by Current Company"
        else
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
        OnBeforeOutBoxTransactionInsert(OutboxTransaction, SalesHeader);
        OutboxTransaction.Insert();
        ICOutBoxSalesHeader.TransferFields(SalesHeader);
        OnAfterICOutBoxSalesHeaderTransferFields(ICOutBoxSalesHeader, SalesHeader);
        if OutboxTransaction."Document Type" = OutboxTransaction."Document Type"::Order then
            ICOutBoxSalesHeader."Order No." := SalesHeader."No.";
        ICOutBoxSalesHeader."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICOutBoxSalesHeader."IC Transaction No." := OutboxTransaction."Transaction No.";
        ICOutBoxSalesHeader."Transaction Source" := OutboxTransaction."Transaction Source";
        AssignCurrencyCodeInOutBoxDoc(ICOutBoxSalesHeader."Currency Code", OutboxTransaction."IC Partner Code");
        AssignCountryCode(OutboxTransaction."IC Partner Code", ICOutBoxSalesHeader."Ship-to Country/Region Code");
        DimMgt.CopyDocDimtoICDocDim(DATABASE::"IC Outbox Sales Header", ICOutBoxSalesHeader."IC Transaction No.",
          ICOutBoxSalesHeader."IC Partner Code", ICOutBoxSalesHeader."Transaction Source", 0, SalesHeader."Dimension Set ID");

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        OnCreateOutboxSalesDocTransOnBeforeLoop(SalesLine);
        if SalesLine.Find('-') then
            repeat
                ICOutBoxSalesLine.Init();
                ICOutBoxSalesLine.TransferFields(SalesLine);
                case SalesLine."Document Type" of
                    SalesLine."Document Type"::Order:
                        ICOutBoxSalesLine."Document Type" := ICOutBoxSalesLine."Document Type"::Order;
                    SalesLine."Document Type"::Invoice:
                        ICOutBoxSalesLine."Document Type" := ICOutBoxSalesLine."Document Type"::Invoice;
                    SalesLine."Document Type"::"Credit Memo":
                        ICOutBoxSalesLine."Document Type" := ICOutBoxSalesLine."Document Type"::"Credit Memo";
                    SalesLine."Document Type"::"Return Order":
                        ICOutBoxSalesLine."Document Type" := ICOutBoxSalesLine."Document Type"::"Return Order";
                end;
                ICOutBoxSalesLine."IC Transaction No." := OutboxTransaction."Transaction No.";
                ICOutBoxSalesLine."IC Partner Code" := OutboxTransaction."IC Partner Code";
                if ICOutBoxSalesLine."IC Item Reference No." = '' then
                    ICOutBoxSalesLine."IC Item Reference No." := SalesLine."Item Reference No.";
                ICOutBoxSalesLine."Transaction Source" := OutboxTransaction."Transaction Source";
                ICOutBoxSalesLine."Currency Code" := ICOutBoxSalesHeader."Currency Code";
                if SalesLine.Type = SalesLine.Type::" " then begin
                    ICOutBoxSalesLine."IC Partner Reference" := '';
                    ICOutBoxSalesLine."IC Item Reference No." := '';
                end;
                DimMgt.CopyDocDimtoICDocDim(DATABASE::"IC Outbox Sales Line", ICOutBoxSalesLine."IC Transaction No.", ICOutBoxSalesLine."IC Partner Code", ICOutBoxSalesLine."Transaction Source",
                  ICOutBoxSalesLine."Line No.", SalesLine."Dimension Set ID");
                UpdateICOutboxSalesLineReceiptShipment(ICOutBoxSalesLine, ICOutBoxSalesHeader);
                if ICOutBoxSalesLine.Insert(true) then begin
                    OnCreateOutboxSalesDocTransOnAfterICOutBoxSalesLineInsert(ICOutBoxSalesLine, SalesLine);
                    LinesCreated := true;
                end;
                OnAfterICOutBoxSalesLineInsert(SalesLine, ICOutBoxSalesLine);
            until SalesLine.Next() = 0;

        if LinesCreated then begin
            ICOutBoxSalesHeader.Insert();
            if not Post then begin
                SalesHeader."IC Status" := SalesHeader."IC Status"::Pending;
                SalesHeader.Modify();
            end;
        end;
        OnBeforeICOutboxTransactionCreatedSalesDocTrans(SalesHeader, SalesLine, ICOutBoxSalesHeader, OutboxTransaction, LinesCreated, Post);
        OnInsertICOutboxSalesDocTransaction(OutboxTransaction);
    end;

    procedure CreateOutboxSalesInvTrans(SalesInvHdr: Record "Sales Invoice Header")
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
        SalesInvLine: Record "Sales Invoice Line";
        ICOutBoxSalesHeader: Record "IC Outbox Sales Header";
        ICOutBoxSalesLine: Record "IC Outbox Sales Line";
        ICDocDim: Record "IC Document Dimension";
        ItemReference: Record "Item Reference";
        Item: Record Item;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ToDate: Date;
        TransactionNo: Integer;
        RoundingLineNo: Integer;
        IsCommentType: Boolean;
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJ8', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IJZ', ICMapping.GetFeatureTelemetryName(), 'Creating Outbox Sales Invoice Transaction');

        IsHandled := false;
        OnBeforeCreateOutboxSalesInvTrans(SalesInvHdr, IsHandled);
        if IsHandled then
            exit;

        Customer.Get(SalesInvHdr."Bill-to Customer No.");
        ICPartner.Get(Customer."IC Partner Code");
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
            exit;

        GLSetup.LockTable();
        GetGLSetup();
        TransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := TransactionNo;
        GLSetup.Modify();
        OutboxTransaction.Init();
        OutboxTransaction."Transaction No." := TransactionNo;
        OutboxTransaction."IC Partner Code" := Customer."IC Partner Code";
        OutboxTransaction."IC Source Type" := OutboxTransaction."IC Source Type"::"Sales Document";
        OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Invoice;
        OutboxTransaction."Document No." := SalesInvHdr."No.";
        OutboxTransaction."Posting Date" := SalesInvHdr."Posting Date";
        OutboxTransaction."Document Date" := SalesInvHdr."Document Date";
        OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
        OnCreateOutboxSalesInvTransOnBeforeOutboxTransactionInsert(OutboxTransaction);
        OutboxTransaction.Insert();
        ICOutBoxSalesHeader.TransferFields(SalesInvHdr);
        ICOutBoxSalesHeader."Document Type" := ICOutBoxSalesHeader."Document Type"::Invoice;
        ICOutBoxSalesHeader."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICOutBoxSalesHeader."IC Transaction No." := OutboxTransaction."Transaction No.";
        ICOutBoxSalesHeader."Transaction Source" := OutboxTransaction."Transaction Source";
        AssignCurrencyCodeInOutBoxDoc(ICOutBoxSalesHeader."Currency Code", OutboxTransaction."IC Partner Code");
        AssignCountryCode(OutboxTransaction."IC Partner Code", ICOutBoxSalesHeader."Ship-to Country/Region Code");
        OnCreateOutboxSalesInvTransOnAfterTransferFieldsFromSalesInvHeader(ICOutBoxSalesHeader, SalesInvHdr, OutboxTransaction);
        ICOutBoxSalesHeader.Insert();
        OnCreateOutboxSalesInvTransOnAfterICOutBoxSalesHeaderInsert(ICOutBoxSalesHeader, SalesInvHdr);

        ICDocDim.Init();
        ICDocDim."Transaction No." := OutboxTransaction."Transaction No.";
        ICDocDim."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICDocDim."Transaction Source" := OutboxTransaction."Transaction Source";

        CreateICDocDimFromPostedDocDim(ICDocDim, SalesInvHdr."Dimension Set ID", DATABASE::"IC Outbox Sales Header");

        RoundingLineNo := FindRoundingSalesInvLine(SalesInvHdr."No.");
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", SalesInvHdr."No.");
        if RoundingLineNo <> 0 then
            SalesInvLine.SetRange("Line No.", 0, RoundingLineNo - 1);
        if SalesInvLine.FindSet() then
            repeat
                IsCommentType := (SalesInvLine.Type = SalesInvLine.Type::" ");
                if IsCommentType or ((SalesInvLine."No." <> '') and (SalesInvLine.Quantity <> 0)) then begin
                    ICOutBoxSalesLine.Init();
                    ICOutBoxSalesLine.TransferFields(SalesInvLine);
                    ICOutBoxSalesLine."Document Type" := ICOutBoxSalesLine."Document Type"::Invoice;
                    ICOutBoxSalesLine."IC Transaction No." := OutboxTransaction."Transaction No.";
                    ICOutBoxSalesLine."IC Partner Code" := OutboxTransaction."IC Partner Code";
                    ICOutBoxSalesLine."Transaction Source" := OutboxTransaction."Transaction Source";
                    ICOutBoxSalesLine."Currency Code" := ICOutBoxSalesHeader."Currency Code";
                    if SalesInvLine.Type = SalesInvLine.Type::" " then begin
                        ICOutBoxSalesLine."IC Partner Reference" := '';
                        ICOutBoxSalesLine."IC Item Reference No." := '';
                    end;
                    if (SalesInvLine."Bill-to Customer No." <> SalesInvLine."Sell-to Customer No.") and
                       (SalesInvLine.Type = SalesInvLine.Type::Item)
                    then
                        case ICPartner."Outbound Sales Item No. Type" of
                            ICPartner."Outbound Sales Item No. Type"::"Internal No.":
                                begin
                                    ICOutBoxSalesLine."IC Partner Ref. Type" := ICOutBoxSalesLine."IC Partner Ref. Type"::Item;
                                    ICOutBoxSalesLine."IC Partner Reference" := SalesInvLine."No.";
                                end;
                            ICPartner."Outbound Sales Item No. Type"::"Cross Reference":
                                begin
                                    ICOutBoxSalesLine.Validate("IC Partner Ref. Type", ICOutBoxSalesLine."IC Partner Ref. Type"::"Cross reference");
                                    ItemReference.SetRange("Reference Type", "Item Reference Type"::Customer);
                                    ItemReference.SetRange("Reference Type No.", SalesInvLine."Bill-to Customer No.");
                                    ItemReference.SetRange("Item No.", SalesInvLine."No.");
                                    ToDate := SalesInvLine.GetDateForCalculations();
                                    if ToDate <> 0D then begin
                                        ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
                                        ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
                                    end;
                                    if ItemReference.FindFirst() then
                                        ICOutBoxSalesLine."IC Item Reference No." := ItemReference."Reference No.";
                                end;
                            ICPartner."Outbound Sales Item No. Type"::"Common Item No.":
                                begin
                                    Item.Get(SalesInvLine."No.");
                                    ICOutBoxSalesLine."IC Partner Reference" := Item."Common Item No.";
                                end;
                        end;
                    UpdateICOutboxSalesLineReceiptShipment(ICOutBoxSalesLine, ICOutBoxSalesHeader);
                    OnCreateOutboxSalesInvTransOnBeforeICOutBoxSalesLineInsert(ICOutBoxSalesLine, SalesInvLine, ICOutBoxSalesHeader);
                    ICOutBoxSalesLine.Insert(true);

                    ICDocDim."Line No." := SalesInvLine."Line No.";
                    CreateICDocDimFromPostedDocDim(ICDocDim, SalesInvLine."Dimension Set ID", DATABASE::"IC Outbox Sales Line");
                end;
            until SalesInvLine.Next() = 0;

        OnBeforeICOutboxTransactionCreatedSalesInvTrans(SalesInvHdr, SalesInvLine, ICOutBoxSalesHeader, OutboxTransaction);
        OnInsertICOutboxSalesInvTransaction(OutboxTransaction);
    end;

    procedure CreateOutboxSalesCrMemoTrans(SalesCrMemoHdr: Record "Sales Cr.Memo Header")
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ICOutBoxSalesHeader: Record "IC Outbox Sales Header";
        ICOutBoxSalesLine: Record "IC Outbox Sales Line";
        ICDocDim: Record "IC Document Dimension";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        TransactionNo: Integer;
        RoundingLineNo: Integer;
        IsCommentType: Boolean;
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJ9', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK0', ICMapping.GetFeatureTelemetryName(), 'Creating Outbox Sales Credit Memo Transaction');

        IsHandled := false;
        OnBeforeCreateOutboxSalesCrMemoTrans(SalesCrMemoHdr, IsHandled);
        if IsHandled then
            exit;

        Customer.Get(SalesCrMemoHdr."Bill-to Customer No.");
        ICPartner.Get(Customer."IC Partner Code");
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
            exit;

        GLSetup.LockTable();
        GetGLSetup();
        TransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := TransactionNo;
        GLSetup.Modify();
        OutboxTransaction.Init();
        OutboxTransaction."Transaction No." := TransactionNo;
        OutboxTransaction."IC Partner Code" := Customer."IC Partner Code";
        OutboxTransaction."IC Source Type" := OutboxTransaction."IC Source Type"::"Sales Document";
        OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Credit Memo";
        OutboxTransaction."Document No." := SalesCrMemoHdr."No.";
        OutboxTransaction."Posting Date" := SalesCrMemoHdr."Posting Date";
        OutboxTransaction."Document Date" := SalesCrMemoHdr."Document Date";
        OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
        OnCreateOutboxSalesCrMemoTransOnBeforeOutboxTransactionInsert(OutboxTransaction);
        OutboxTransaction.Insert();
        ICOutBoxSalesHeader.TransferFields(SalesCrMemoHdr);
        ICOutBoxSalesHeader."Document Type" := ICOutBoxSalesHeader."Document Type"::"Credit Memo";
        ICOutBoxSalesHeader."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICOutBoxSalesHeader."IC Transaction No." := OutboxTransaction."Transaction No.";
        ICOutBoxSalesHeader."Transaction Source" := OutboxTransaction."Transaction Source";
        AssignCurrencyCodeInOutBoxDoc(ICOutBoxSalesHeader."Currency Code", OutboxTransaction."IC Partner Code");
        AssignCountryCode(OutboxTransaction."IC Partner Code", ICOutBoxSalesHeader."Ship-to Country/Region Code");
        OnCreateOutboxSalesCrMemoTransOnAfterTransferFieldsFromSalesCrMemoHeader(ICOutBoxSalesHeader, SalesCrMemoHdr, OutboxTransaction);
        ICOutBoxSalesHeader.Insert();
        OnCreateOutboxSalesCrMemoTransOnAfterICOutBoxSalesHeaderInsert(ICOutBoxSalesHeader, SalesCrMemoHdr);

        ICDocDim.Init();
        ICDocDim."Transaction No." := OutboxTransaction."Transaction No.";
        ICDocDim."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICDocDim."Transaction Source" := OutboxTransaction."Transaction Source";

        CreateICDocDimFromPostedDocDim(ICDocDim, SalesCrMemoHdr."Dimension Set ID", DATABASE::"IC Outbox Sales Header");

        RoundingLineNo := FindRoundingSalesCrMemoLine(SalesCrMemoHdr."No.");
        SalesCrMemoLine.Reset();
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHdr."No.");
        if RoundingLineNo <> 0 then
            SalesCrMemoLine.SetRange("Line No.", 0, RoundingLineNo - 1);
        if SalesCrMemoLine.FindSet() then
            repeat
                IsCommentType := (SalesCrMemoLine.Type = SalesCrMemoLine.Type::" ");
                if IsCommentType or ((SalesCrMemoLine."No." <> '') and (SalesCrMemoLine.Quantity <> 0)) then begin
                    ICOutBoxSalesLine.Init();
                    ICOutBoxSalesLine.TransferFields(SalesCrMemoLine);
                    ICOutBoxSalesLine."Document Type" := ICOutBoxSalesLine."Document Type"::"Credit Memo";
                    ICOutBoxSalesLine."IC Transaction No." := OutboxTransaction."Transaction No.";
                    ICOutBoxSalesLine."IC Partner Code" := OutboxTransaction."IC Partner Code";
                    ICOutBoxSalesLine."Transaction Source" := OutboxTransaction."Transaction Source";
                    ICOutBoxSalesLine."Currency Code" := ICOutBoxSalesHeader."Currency Code";
                    if SalesCrMemoLine.Type = SalesCrMemoLine.Type::" " then begin
                        ICOutBoxSalesLine."IC Partner Reference" := '';
                        ICOutBoxSalesLine."IC Item Reference No." := '';
                    end;
                    UpdateICOutboxSalesLineReceiptShipment(ICOutBoxSalesLine, ICOutBoxSalesHeader);
                    OnCreateOutboxSalesCrMemoTransOnBeforeICOutBoxSalesLineInsert(ICOutBoxSalesLine, SalesCrMemoLine);
                    ICOutBoxSalesLine.Insert(true);

                    ICDocDim."Line No." := SalesCrMemoLine."Line No.";
                    CreateICDocDimFromPostedDocDim(ICDocDim, SalesCrMemoLine."Dimension Set ID", DATABASE::"IC Outbox Sales Line");
                end;
            until SalesCrMemoLine.Next() = 0;
        OnBeforeICOutboxTransactionCreatedSalesCrMemoTrans(SalesCrMemoHdr, SalesCrMemoLine, ICOutBoxSalesHeader, OutboxTransaction);
        OnInsertICOutboxSalesCrMemoTransaction(OutboxTransaction);
    end;

    procedure CreateOutboxPurchDocTrans(PurchHeader: Record "Purchase Header"; Rejection: Boolean; Post: Boolean)
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        Vendor: Record Vendor;
        PurchLine: Record "Purchase Line";
        ICOutBoxPurchHeader: Record "IC Outbox Purchase Header";
        ICOutBoxPurchLine: Record "IC Outbox Purchase Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        TransactionNo: Integer;
        LinesCreated: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJA', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK1', ICMapping.GetFeatureTelemetryName(), 'Creating Outbox Purchase Document Transactions');

        OnBeforeCreateOutboxPurchDocTrans(PurchHeader, Rejection, Post);

        GLSetup.LockTable();
        GetGLSetup();
        TransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := TransactionNo;
        GLSetup.Modify();
        Vendor.Get(PurchHeader."Buy-from Vendor No.");
        Vendor.CheckBlockedVendOnDocs(Vendor, false);
        OutboxTransaction.Init();
        OutboxTransaction."Transaction No." := TransactionNo;
        OutboxTransaction."IC Partner Code" := Vendor."IC Partner Code";
        OutboxTransaction."IC Source Type" := OutboxTransaction."IC Source Type"::"Purchase Document";
        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Order:
                OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Order;
            PurchHeader."Document Type"::Invoice:
                OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Invoice;
            PurchHeader."Document Type"::"Credit Memo":
                OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Credit Memo";
            PurchHeader."Document Type"::"Return Order":
                OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Return Order";
        end;
        OutboxTransaction."Document No." := PurchHeader."No.";
        OutboxTransaction."Posting Date" := PurchHeader."Posting Date";
        OutboxTransaction."Document Date" := PurchHeader."Document Date";
        if Rejection then
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Rejected by Current Company"
        else
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
        OnCreateOutboxPurchDocTransOnBeforeOutboxTransactionInsert(OutboxTransaction, PurchHeader);
        OutboxTransaction.Insert();
        ICOutBoxPurchHeader.TransferFields(PurchHeader);
        ICOutBoxPurchHeader."IC Transaction No." := OutboxTransaction."Transaction No.";
        ICOutBoxPurchHeader."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICOutBoxPurchHeader."Transaction Source" := OutboxTransaction."Transaction Source";
        OnCreateOutboxPurchDocTransOnAfterTransferFieldsFromPurchHeader(ICOutboxPurchHeader, PurchHeader);

        GetCompanyInfo();
        AssignCurrencyCodeInOutBoxDoc(ICOutBoxPurchHeader."Currency Code", OutboxTransaction."IC Partner Code");
        AssignCountryCode(OutboxTransaction."IC Partner Code", ICOutBoxPurchHeader."Ship-to Country/Region Code");
        DimMgt.CopyDocDimtoICDocDim(DATABASE::"IC Outbox Purchase Header", ICOutBoxPurchHeader."IC Transaction No.",
          ICOutBoxPurchHeader."IC Partner Code", ICOutBoxPurchHeader."Transaction Source", 0, PurchHeader."Dimension Set ID");
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        OnCreateOutboxPurchDocTransOnAfterPurchLineSetFilters(PurchHeader, PurchLine);
        if PurchLine.Find('-') then
            repeat
                ICOutBoxPurchLine.Init();
                ICOutBoxPurchLine.TransferFields(PurchLine);
                case PurchLine."Document Type" of
                    PurchLine."Document Type"::Order:
                        ICOutBoxPurchLine."Document Type" := ICOutBoxPurchLine."Document Type"::Order;
                    PurchLine."Document Type"::Invoice:
                        ICOutBoxPurchLine."Document Type" := ICOutBoxPurchLine."Document Type"::Invoice;
                    PurchLine."Document Type"::"Credit Memo":
                        ICOutBoxPurchLine."Document Type" := ICOutBoxPurchLine."Document Type"::"Credit Memo";
                    PurchLine."Document Type"::"Return Order":
                        ICOutBoxPurchLine."Document Type" := ICOutBoxPurchLine."Document Type"::"Return Order";
                end;
                ICOutBoxPurchLine."IC Partner Code" := OutboxTransaction."IC Partner Code";
                ICOutBoxPurchLine."IC Transaction No." := OutboxTransaction."Transaction No.";
                if ICOutBoxPurchLine."IC Item Reference No." = '' then
                    ICOutBoxPurchLine."IC Item Reference No." := PurchLine."Item Reference No.";
                ICOutBoxPurchLine."Transaction Source" := OutboxTransaction."Transaction Source";
                ICOutBoxPurchLine."Currency Code" := ICOutBoxPurchHeader."Currency Code";
                DimMgt.CopyDocDimtoICDocDim(
                  DATABASE::"IC Outbox Purchase Line", ICOutBoxPurchLine."IC Transaction No.", ICOutBoxPurchLine."IC Partner Code", ICOutBoxPurchLine."Transaction Source",
                  ICOutBoxPurchLine."Line No.", PurchLine."Dimension Set ID");
                if PurchLine.Type = PurchLine.Type::" " then begin
                    ICOutBoxPurchLine."IC Partner Reference" := '';
                    ICOutBoxPurchLine."IC Item Reference No." := '';
                end;
                if ICOutBoxPurchLine.Insert(true) then begin
                    OnCreateOutboxPurchDocTransOnAfterICOutBoxPurchLineInsert(ICOutBoxPurchLine, PurchLine);
                    LinesCreated := true;
                end;
            until PurchLine.Next() = 0;

        if LinesCreated then begin
            ICOutBoxPurchHeader.Insert();
            if not Post then begin
                PurchHeader."IC Status" := PurchHeader."IC Status"::Pending;
                PurchHeader.Modify();
            end;
        end;
        OnBeforeICOutboxTransactionCreatedPurchDocTrans(PurchHeader, PurchLine, ICOutBoxPurchHeader, OutboxTransaction, LinesCreated, Post);
        OnInsertICOutboxPurchDocTransaction(OutboxTransaction);
    end;

    procedure CreateOutboxJnlLine(TransactionNo: Integer; TransactionSource: Option "Rejected by Current Company"," Created by Current Company"; TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJB', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK2', ICMapping.GetFeatureTelemetryName(), 'Creating Outbox Journal Line');

        GetGLSetup();
        if ((TempGenJnlLine."Bal. Account Type" in
             [TempGenJnlLine."Bal. Account Type"::Customer, TempGenJnlLine."Bal. Account Type"::Vendor, TempGenJnlLine."Bal. Account Type"::"IC Partner"]) and
            (TempGenJnlLine."Bal. Account No." <> '')) or
           ((TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::"G/L Account") and (TempGenJnlLine."IC Account No." <> '')) or
           ((TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::"Bank Account") and (TempGenJnlLine."IC Account No." <> ''))
        then
            RunExchangeAccGLJournalLine(TransactionNo, TempGenJnlLine);
        if (TempGenJnlLine."Account Type" in [TempGenJnlLine."Account Type"::Customer, TempGenJnlLine."Account Type"::Vendor, TempGenJnlLine."Account Type"::"IC Partner"]) and
           (TempGenJnlLine."Account No." <> '')
        then
            InsertOutboxJnlLine(TempGenJnlLine, TransactionNo, TransactionSource, false);

        if TempGenJnlLine."IC Account No." <> '' then
            InsertOutboxJnlLine(TempGenJnlLine, TransactionNo, TransactionSource, true);
    end;

    local procedure RunExchangeAccGLJournalLine(TransactionNo: Integer; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
        CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", TempGenJnlLine);

        OnAfterRunExchangeAccGLJournalLine(TempGenJnlLine, TransactionNo);
    end;

    local procedure InsertOutboxJnlLine(TempGenJnlLine: Record "Gen. Journal Line" temporary; TransactionNo: Integer; TransactionSource: Option "Rejected by Current Company"," Created by Current Company"; BalancingLine: Boolean)
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        GetGLSetup();
        ICOutboxJnlLine.Init();
        ICOutboxJnlLine."Transaction No." := TransactionNo;
        ICOutboxJnlLine."IC Partner Code" := TempGenJnlLine."IC Partner Code";
        ICOutboxJnlLine."Transaction Source" := TransactionSource;
        ICOutboxJnlLine.Description := TempGenJnlLine.Description;
        ICOutboxJnlLine."Currency Code" := TempGenJnlLine."Currency Code";
        ICOutboxJnlLine.Quantity := TempGenJnlLine.Quantity;
        ICOutboxJnlLine."Document No." := TempGenJnlLine."Document No.";
        if BalancingLine then begin
            ICOutboxJnlLine."Line No." := TempGenJnlLine."Line No.";
            if TempGenJnlLine."IC Account Type" = TempGenJnlLine."IC Account Type"::"G/L Account" then
                ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::"G/L Account";
            if TempGenJnlLine."IC Account Type" = TempGenJnlLine."IC Account Type"::"Bank Account" then
                ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::"Bank Account";
            ICOutboxJnlLine."Account No." := TempGenJnlLine."IC Account No.";
            ICOutboxJnlLine.Amount := -TempGenJnlLine.Amount;
            ICOutboxJnlLine."VAT Amount" := TempGenJnlLine."Bal. VAT Amount";
        end else begin
            ICOutboxJnlLine."Line No." := 0;
            case TempGenJnlLine."Account Type" of
                TempGenJnlLine."Account Type"::Customer:
                    ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::Customer;
                TempGenJnlLine."Account Type"::Vendor:
                    ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::Vendor;
                TempGenJnlLine."Account Type"::"IC Partner":
                    ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::"IC Partner";
            end;
            ICOutboxJnlLine."Account No." := TempGenJnlLine."Account No.";
            ICOutboxJnlLine.Amount := TempGenJnlLine.Amount;
            ICOutboxJnlLine."VAT Amount" := TempGenJnlLine."VAT Amount";
            ICOutboxJnlLine."Due Date" := TempGenJnlLine."Due Date";
            ICOutboxJnlLine."Payment Discount %" := TempGenJnlLine."Payment Discount %";
            ICOutboxJnlLine."Payment Discount Date" := TempGenJnlLine."Pmt. Discount Date";
        end;
        DimMgt.CopyJnlLineDimToICJnlDim(
          DATABASE::"IC Outbox Jnl. Line", TransactionNo, TempGenJnlLine."IC Partner Code",
          ICOutboxJnlLine."Transaction Source", ICOutboxJnlLine."Line No.", TempGenJnlLine."Dimension Set ID");
        OnInsertOutboxJnlLineOnBeforeICOutboxJnlLineInsert(ICOutboxJnlLine, TempGenJnlLine);
        ICOutboxJnlLine.Insert();
        OnInsertICOutboxJnlLine(ICOutboxJnlLine, TempGenJnlLine);
    end;

    procedure TranslateICGLAccount(ICAccNo: Code[30]): Code[20]
    var
        ICGLAcc: Record "IC G/L Account";
    begin
        ICGLAcc.Get(ICAccNo);
        exit(ICGLAcc."Map-to G/L Acc. No.");
    end;

    procedure TranslateICPartnerToVendor(ICPartnerCode: Code[20]): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        exit(ICPartner."Vendor No.");
    end;

    procedure TranslateICPartnerToCustomer(ICPartnerCode: Code[20]): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        exit(ICPartner."Customer No.");
    end;

    local procedure TranslateICBankAccount(ICAccNo: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(ICAccNo);
        exit(BankAccount."No.");
    end;

    procedure CreateJournalLines(InboxTransaction: Record "IC Inbox Transaction"; InboxJnlLine: Record "IC Inbox Jnl. Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; GenJnlTemplate: Record "Gen. Journal Template")
    var
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        InOutBoxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        TempInOutBoxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary;
        HandledInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        ICSetup: Record "IC Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJC', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK3', ICMapping.GetFeatureTelemetryName(), 'Creating Journal Lines');

        IsHandled := false;
        OnBeforeCreateJournalLines(InboxTransaction, InboxJnlLine, TempGenJnlLine, GenJnlTemplate, IsHandled);
        if not IsHandled then begin
            GetGLSetup();
            ICSetup.Get();
            if InboxTransaction."Transaction Source" = InboxTransaction."Transaction Source"::"Created by Partner" then begin
                GenJnlLine2.Init();
                GenJnlLine2."Journal Template Name" := TempGenJnlLine."Journal Template Name";
                GenJnlLine2."Journal Batch Name" := TempGenJnlLine."Journal Batch Name";
                if ICSetup."Auto. Send Transactions" then begin
                    GenJnlBatch.Get(GenJnlLine2."Journal Template Name", GenJnlLine2."Journal Batch Name");
                    GenJnlLine2."Posting No. Series" := GenJnlBatch."Posting No. Series";
                end;
                if TempGenJnlLine."Posting Date" <> 0D then
                    GenJnlLine2."Posting Date" := TempGenJnlLine."Posting Date"
                else
                    GenJnlLine2."Posting Date" := InboxTransaction."Posting Date";
                GenJnlLine2."Document Type" := InboxTransaction."Document Type";
                GenJnlLine2."Document No." := TempGenJnlLine."Document No.";
                GenJnlLine2."Source Code" := GenJnlTemplate."Source Code";
                GenJnlLine2."Line No." := TempGenJnlLine."Line No." + 10000;
                case InboxJnlLine."Account Type" of
                    InboxJnlLine."Account Type"::"G/L Account":
                        begin
                            GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"G/L Account";
                            GenJnlLine2.Validate("Account No.", TranslateICGLAccount(InboxJnlLine."Account No."));
                        end;
                    InboxJnlLine."Account Type"::Customer:
                        begin
                            GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::Customer;
                            GenJnlLine2.Validate("Account No.", TranslateICPartnerToCustomer(InboxJnlLine."IC Partner Code"));
                        end;
                    InboxJnlLine."Account Type"::Vendor:
                        begin
                            GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::Vendor;
                            GenJnlLine2.Validate("Account No.", TranslateICPartnerToVendor(InboxJnlLine."IC Partner Code"));
                        end;
                    InboxJnlLine."Account Type"::"IC Partner":
                        begin
                            GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"IC Partner";
                            GenJnlLine2.Validate("Account No.", InboxJnlLine."IC Partner Code");
                        end;
                    InboxJnlLine."Account Type"::"Bank Account":
                        begin
                            GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"Bank Account";
                            GenJnlLine2.Validate("Account No.", TranslateICBankAccount(InboxJnlLine."Account No."));
                        end;
                end;
                if InboxJnlLine.Description <> '' then
                    GenJnlLine2.Description := InboxJnlLine.Description;
                if InboxJnlLine."Currency Code" = GLSetup."LCY Code" then
                    InboxJnlLine."Currency Code" := '';
                GenJnlLine2.Validate("Currency Code", InboxJnlLine."Currency Code");
                GenJnlLine2.Validate(Amount, InboxJnlLine.Amount);
                if (GenJnlLine2."VAT Amount" <> InboxJnlLine."VAT Amount") and
                   (GenJnlLine2."VAT Amount" <> 0) and (InboxJnlLine."VAT Amount" <> 0)
                then
                    GenJnlLine2.Validate("VAT Amount", InboxJnlLine."VAT Amount");
                GenJnlLine2."Due Date" := InboxJnlLine."Due Date";
                GenJnlLine2.Validate("Payment Discount %", InboxJnlLine."Payment Discount %");
                GenJnlLine2.Validate("Pmt. Discount Date", InboxJnlLine."Payment Discount Date");
                GenJnlLine2.Quantity := InboxJnlLine.Quantity;
                GenJnlLine2."IC Direction" := TempGenJnlLine."IC Direction"::Incoming;
                GenJnlLine2."IC Partner Transaction No." := InboxJnlLine."Transaction No.";
                GenJnlLine2."External Document No." := InboxJnlLine."Document No.";
                OnBeforeInsertGenJnlLine(GenJnlLine2, InboxJnlLine);
                GenJnlLine2.Insert();
                InOutBoxJnlLineDim.SetRange("Table ID", DATABASE::"IC Inbox Jnl. Line");
                InOutBoxJnlLineDim.SetRange("Transaction No.", InboxTransaction."Transaction No.");
                InOutBoxJnlLineDim.SetRange("Line No.", InboxJnlLine."Line No.");
                InOutBoxJnlLineDim.SetRange("IC Partner Code", InboxTransaction."IC Partner Code");
                TempInOutBoxJnlLineDim.DeleteAll();
                DimMgt.CopyICJnlDimToICJnlDim(InOutBoxJnlLineDim, TempInOutBoxJnlLineDim);
                GenJnlLine2."Dimension Set ID" := DimMgt.CreateDimSetIDFromICJnlLineDim(TempInOutBoxJnlLineDim);
                DimMgt.UpdateGlobalDimFromDimSetID(GenJnlLine2."Dimension Set ID", GenJnlLine2."Shortcut Dimension 1 Code",
                  GenJnlLine2."Shortcut Dimension 2 Code");
                OnCreateJournalLinesOnBeforeModify(GenJnlLine2, InboxJnlLine);
                GenJnlLine2.Modify();
                HandledInboxJnlLine.TransferFields(InboxJnlLine);
                HandledInboxJnlLine.Insert();
                TempGenJnlLine."Line No." := GenJnlLine2."Line No.";
            end;
        end;
        OnAfterCreateJournalLines(GenJnlLine2);
    end;

    procedure CreateSalesDocument(ICInboxSalesHeader: Record "IC Inbox Sales Header"; ReplacePostingDate: Boolean; PostingDate: Date)
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        SalesHeader: Record "Sales Header";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJD', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK4', ICMapping.GetFeatureTelemetryName(), 'Creating Sales Document');

        IsHandled := false;
        OnBeforeCreateSalesDocument(ICInboxSalesHeader, ReplacePostingDate, PostingDate, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.Init();
        SalesHeader."No." := '';
        SalesHeader."Document Type" := ICInboxSalesHeader."Document Type";
        OnCreateSalesDocumentOnBeforeSalesHeaderInsert(SalesHeader, ICInboxSalesHeader);
        SalesHeader.Insert(true);

        UpdateSalesHeader(SalesHeader, ICInboxSalesHeader, ReplacePostingDate, PostingDate, ICDocDim);

        HandledICInboxSalesHeader.TransferFields(ICInboxSalesHeader);
        HandledICInboxSalesHeader.Insert();
        if ICDocDim.Find('-') then
            DimMgt.MoveICDocDimtoICDocDim(
                ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Header", ICInboxSalesHeader."Transaction Source");

        ICInboxSalesLine.SetRange("IC Transaction No.", ICInboxSalesHeader."IC Transaction No.");
        ICInboxSalesLine.SetRange("IC Partner Code", ICInboxSalesHeader."IC Partner Code");
        ICInboxSalesLine.SetRange("Transaction Source", ICInboxSalesHeader."Transaction Source");
        OnCreateSalesDocumentOnAfterICInboxSalesLineSetFilters(ICInboxSalesLine, ICInboxSalesHeader);
        if ICInboxSalesLine.Find('-') then
            repeat
                CreateSalesLines(SalesHeader, ICInboxSalesLine);
                HandledICInboxSalesLine.TransferFields(ICInboxSalesLine);
                OnBeforeHandledICInboxSalesLineInsert(HandledICInboxSalesLine, ICInboxSalesLine);
                HandledICInboxSalesLine.Insert();
                DimMgt.SetICDocDimFilters(
                    ICDocDim, DATABASE::"IC Inbox Sales Line", ICInboxSalesLine."IC Transaction No.",
                    ICInboxSalesLine."IC Partner Code", ICInboxSalesLine."Transaction Source", ICInboxSalesLine."Line No.");
                if ICDocDim.Find('-') then
                    DimMgt.MoveICDocDimtoICDocDim(
                        ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Line", ICInboxSalesLine."Transaction Source");
            until ICInboxSalesLine.Next() = 0;

        OnAfterCreateSalesDocument(SalesHeader, ICInboxSalesHeader, HandledICInboxSalesHeader);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; ICInboxSalesHeader: Record "IC Inbox Sales Header"; ReplacePostingDate: Boolean; PostingDate: Date; var ICDocDim: Record "IC Document Dimension")
    var
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesHeader(SalesHeader, ICInboxSalesHeader, ICDocDim, ReplacePostingDate, PostingDate);
        if not IsHandled then begin
            SalesHeader.Validate("IC Direction", SalesHeader."IC Direction"::Incoming);
            SalesHeader.Validate("Sell-to Customer No.", ICInboxSalesHeader."Sell-to Customer No.");
            if SalesHeader."Bill-to Customer No." <> ICInboxSalesHeader."Bill-to Customer No." then
                SalesHeader.Validate("Bill-to Customer No.", ICInboxSalesHeader."Bill-to Customer No.");
            SalesHeader."External Document No." := ICInboxSalesHeader."No.";
            SalesHeader."IC Reference Document No." := ICInboxSalesHeader."No.";
            SalesHeader."Ship-to Name" := ICInboxSalesHeader."Ship-to Name";
            SalesHeader."Ship-to Address" := ICInboxSalesHeader."Ship-to Address";
            SalesHeader."Ship-to Address 2" := ICInboxSalesHeader."Ship-to Address 2";
            SalesHeader."Ship-to City" := ICInboxSalesHeader."Ship-to City";
            SalesHeader."Ship-to Post Code" := ICInboxSalesHeader."Ship-to Post Code";
            SalesHeader."Ship-to County" := ICInboxSalesHeader."Ship-to County";
            SalesHeader."Ship-to Country/Region Code" := ICInboxSalesHeader."Ship-to Country/Region Code";
            SalesHeader."Ship-to Phone No." := ICInboxSalesHeader."Ship-to Phone No.";
            if ReplacePostingDate then
                SalesHeader.Validate("Posting Date", PostingDate)
            else
                if ICInboxSalesHeader."Posting Date" <> 0D then
                    SalesHeader.Validate("Posting Date", ICInboxSalesHeader."Posting Date");
            GetCurrency(ICInboxSalesHeader."Currency Code");
            SalesHeader.Validate("Currency Code", ICInboxSalesHeader."Currency Code");
            SalesHeader.Validate("Document Date", ICInboxSalesHeader."Document Date");
            SalesHeader.Validate("Prices Including VAT", ICInboxSalesHeader."Prices Including VAT");
            SalesHeader.Modify();
            OnCreateSalesDocumentOnAfterSalesHeaderFirstModify(SalesHeader);
            SalesHeader.Validate("Due Date", ICInboxSalesHeader."Due Date");
            SalesHeader.Validate("Payment Discount %", ICInboxSalesHeader."Payment Discount %");
            SalesHeader.Validate("Pmt. Discount Date", ICInboxSalesHeader."Pmt. Discount Date");
            SalesHeader.Validate("Requested Delivery Date", ICInboxSalesHeader."Requested Delivery Date");
            SalesHeader.Validate("Promised Delivery Date", ICInboxSalesHeader."Promised Delivery Date");
            SalesHeader."Shortcut Dimension 1 Code" := '';
            SalesHeader."Shortcut Dimension 2 Code" := '';
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then // Received sales orders can be sent back when posting as an invoice
                SalesHeader."Send IC Document" := true;

            OnCreateSalesDocumentOnBeforeSetICDocDimFilters(SalesHeader, ICInboxSalesHeader);
            DimMgt.SetICDocDimFilters(
                ICDocDim, DATABASE::"IC Inbox Sales Header", ICInboxSalesHeader."IC Transaction No.",
                ICInboxSalesHeader."IC Partner Code", ICInboxSalesHeader."Transaction Source", 0);

            DimensionSetIDArr[1] := SalesHeader."Dimension Set ID";
            DimensionSetIDArr[2] := DimMgt.CreateDimSetIDFromICDocDim(ICDocDim);
            SalesHeader."Dimension Set ID" :=
                DimMgt.GetCombinedDimensionSetID(
                    DimensionSetIDArr, SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code");
            DimMgt.UpdateGlobalDimFromDimSetID(
                SalesHeader."Dimension Set ID", SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code");
            OnCreateSalesDocumentOnBeforeSalesHeaderModify(SalesHeader, ICInboxSalesHeader, ICDocDim);
            SalesHeader.Modify();
        end;
    end;

    procedure CreateSalesLines(SalesHeader: Record "Sales Header"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    var
        SalesLine: Record "Sales Line";
        ICDocDim: Record "IC Document Dimension";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJE', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK5', ICMapping.GetFeatureTelemetryName(), 'Creating Sales Lines');

        IsHandled := false;
        OnBeforeCreateSalesLines(SalesHeader, ICInboxSalesLine, IsHandled);
        if not IsHandled then begin
            SalesLine.Init();
            SalesLine.TransferFields(ICInboxSalesLine);
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." := ICInboxSalesLine."Line No.";

            OnCreateSalesLinesOnBeforefterAssignTypeAndNo(SalesLine, ICInboxSalesLine);
            case ICInboxSalesLine."IC Partner Ref. Type" of
                "IC Partner Reference Type"::"Common Item No.":
                    begin
                        SalesLine.Type := SalesLine.Type::Item;
                        SalesLine."No." := GetItemFromCommonItem(ICInboxSalesLine."IC Partner Reference");
                        if SalesLine."No." <> '' then
                            SalesLine.Validate("No.", SalesLine."No.")
                        else
                            SalesLine."No." := ICInboxSalesLine."IC Partner Reference";
                    end;
                "IC Partner Reference Type"::"Cross reference":
                    begin
                        SalesLine.Validate(Type, SalesLine.Type::Item);
                        SalesLine.Validate("Item Reference No.", ICInboxSalesLine."IC Item Reference No.");
                    end;
                "IC Partner Reference Type"::Item:
                    begin
                        SalesLine.Validate(Type, SalesLine.Type::Item);
                        SalesLine."No." :=
                            GetItemFromItemRef(
                                ICInboxSalesLine."IC Partner Reference", "Item Reference Type"::Customer, SalesHeader."Sell-to Customer No.", SalesLine.GetDateForCalculations());
                        if SalesLine."No." <> '' then
                            SalesLine.Validate("No.", SalesLine."No.")
                        else
                            SalesLine."No." := ICInboxSalesLine."IC Partner Reference";
                    end;
                "IC Partner Reference Type"::"Vendor Item No.":
                    begin
                        SalesLine.Validate(Type, SalesLine.Type::Item);
                        SalesLine."No." :=
                            GetItemFromItemRef(
                                ICInboxSalesLine."IC Item Reference No.", "Item Reference Type"::Customer, SalesHeader."Sell-to Customer No.", SalesLine.GetDateForCalculations());
                        if SalesLine."No." <> '' then
                            SalesLine.Validate("No.", SalesLine."No.")
                        else
                            SalesLine."No." := CopyStr(ICInboxSalesLine."IC Item Reference No.", 1, MaxStrLen(SalesLine."No."));
                    end;
                "IC Partner Reference Type"::"G/L Account":
                    begin
                        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
                        SalesLine.Validate("No.", TranslateICGLAccount(ICInboxSalesLine."IC Partner Reference"));
                    end;
                "IC Partner Reference Type"::"Charge (Item)":
                    begin
                        SalesLine.Type := SalesLine.Type::"Charge (Item)";
                        SalesLine.Validate("No.", ICInboxSalesLine."IC Partner Reference");
                    end;
                else
                    OnCreateSalesLinesOnICPartnerRefTypeCaseElse(SalesLine, SalesHeader, ICInboxSalesLine);
            end;

            OnCreateSalesLinesOnAfterValidateNo(SalesLine, SalesHeader, ICInboxSalesLine);

            SalesLine."Currency Code" := SalesHeader."Currency Code";
            if (SalesLine.Type <> SalesLine.Type::" ") and (ICInboxSalesLine.Quantity <> 0) then begin
                ValidateQuantityFromICInboxSalesLine(SalesLine, ICInboxSalesLine);
                IsHandled := false;
                OnCreateSalesLinesOnBeforeValidateUnitOfMeasureCode(SalesLine, ICInboxSalesLine, IsHandled);
                if not IsHandled then
                    SalesLine.Validate("Unit of Measure Code", ICInboxSalesLine."Unit of Measure Code");
                IsHandled := false;
                OnCreateSalesLinesOnBeforeCalcPriceAndAmounts(SalesHeader, SalesLine, IsHandled);
                if not IsHandled then begin
                    SalesLine.Validate("Unit Price", ICInboxSalesLine."Unit Price");
                    SalesLine."Amount Including VAT" := ICInboxSalesLine."Amount Including VAT";
                    SalesLine."VAT Difference" := ICInboxSalesLine."VAT Difference";
                    SalesLine.Validate("Line Discount %", ICInboxSalesLine."Line Discount %");
                    SalesLine.Validate("Inv. Discount Amount", ICInboxSalesLine."Inv. Discount Amount");
                    SalesLine.UpdateAmounts();
                end;
                ValidateSalesLineDeliveryDates(SalesLine, ICInboxSalesLine);
                UpdateSalesLineICPartnerReference(SalesLine, SalesHeader, ICInboxSalesLine);
            end;
            SalesLine.Description := ICInboxSalesLine.Description;
            SalesLine."Description 2" := ICInboxSalesLine."Description 2";
            SalesLine."Shortcut Dimension 1 Code" := '';
            SalesLine."Shortcut Dimension 2 Code" := '';
            SalesLine.Insert(true);
            SalesLine.Validate("Qty. to Assemble to Order");
            if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine.Reserve = SalesLine.Reserve::Always) then
                SalesLine.AutoReserve();

            DimMgt.SetICDocDimFilters(
              ICDocDim, DATABASE::"IC Inbox Sales Line", ICInboxSalesLine."IC Transaction No.",
              ICInboxSalesLine."IC Partner Code", ICInboxSalesLine."Transaction Source", ICInboxSalesLine."Line No.");
            DimensionSetIDArr[1] := SalesLine."Dimension Set ID";
            DimensionSetIDArr[2] := DimMgt.CreateDimSetIDFromICDocDim(ICDocDim);

            SalesLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(
                DimensionSetIDArr, SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
            DimMgt.UpdateGlobalDimFromDimSetID(
              SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
            OnAfterCreateSalesLines(ICInboxSalesLine, SalesLine, SalesHeader);
            SalesLine.Modify();
        end;
    end;

    local procedure ValidateQuantityFromICInboxSalesLine(var SalesLine: Record "Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityFromICInboxSalesLine(SalesLine, ICInboxSalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate(Quantity, ICInboxSalesLine.Quantity)
    end;

    local procedure ValidateSalesLineDeliveryDates(var SalesLine: Record "Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateSalesLineDeliveryDates(SalesLine, ICInboxSalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate("Requested Delivery Date", ICInboxSalesLine."Requested Delivery Date");
        SalesLine.Validate("Promised Delivery Date", ICInboxSalesLine."Promised Delivery Date");
    end;

    procedure CreatePurchDocument(ICInboxPurchHeader: Record "IC Inbox Purchase Header"; ReplacePostingDate: Boolean; PostingDate: Date)
    var
        ICInboxPurchLine: Record "IC Inbox Purchase Line";
        PurchHeader: Record "Purchase Header";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJF', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK6', ICMapping.GetFeatureTelemetryName(), 'Creating Purchase Document');

        IsHandled := false;
        OnBeforeCreatePurchDocument(ICInboxPurchHeader, ReplacePostingDate, PostingDate, IsHandled, PurchHeader, HandledICInboxPurchHeader);
        if IsHandled then
            exit;

        PurchHeader.Init();
        PurchHeader."No." := '';
        PurchHeader."Document Type" := ICInboxPurchHeader."Document Type";
        OnCreatePurchDocumentOnBeforePurchHeaderInsert(PurchHeader, ICInboxPurchHeader);
        PurchHeader.Insert(true);

        UpdatePurchaseHeader(PurchHeader, ICInboxPurchHeader, ICDocDim, ReplacePostingDate, PostingDate);

        HandledICInboxPurchHeader.TransferFields(ICInboxPurchHeader);
        HandledICInboxPurchHeader.Insert();
        if ICDocDim.Find('-') then
            DimMgt.MoveICDocDimtoICDocDim(
                ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Header", ICInboxPurchHeader."Transaction Source");

        ICInboxPurchLine.SetRange("IC Transaction No.", ICInboxPurchHeader."IC Transaction No.");
        ICInboxPurchLine.SetRange("IC Partner Code", ICInboxPurchHeader."IC Partner Code");
        ICInboxPurchLine.SetRange("Transaction Source", ICInboxPurchHeader."Transaction Source");
        OnCreatePurchDocumentOnAfterICInboxPurchLineSetFilters(ICInboxPurchLine, ICInboxPurchHeader);
        if ICInboxPurchLine.Find('-') then
            repeat
                CreatePurchLines(PurchHeader, ICInboxPurchLine);
                HandledICInboxPurchLine.TransferFields(ICInboxPurchLine);
                OnCreatePurchDocumentOnBeforeHandledICInboxPurchLineInsert(ICInboxPurchLine, HandledICInboxPurchLine);
                HandledICInboxPurchLine.Insert();

                DimMgt.SetICDocDimFilters(
                    ICDocDim, DATABASE::"IC Inbox Purchase Line", ICInboxPurchLine."IC Transaction No.",
                    ICInboxPurchLine."IC Partner Code", ICInboxPurchLine."Transaction Source", ICInboxPurchLine."Line No.");
                if ICDocDim.Find('-') then
                    DimMgt.MoveICDocDimtoICDocDim(
                        ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Line", ICInboxPurchLine."Transaction Source");
            until ICInboxPurchLine.Next() = 0;

        OnAfterCreatePurchDocument(PurchHeader, ICInboxPurchHeader, HandledICInboxPurchHeader);
    end;

    local procedure UpdatePurchaseHeader(var PurchHeader: Record "Purchase Header"; ICInboxPurchHeader: Record "IC Inbox Purchase Header"; var ICDocDim: Record "IC Document Dimension"; ReplacePostingDate: Boolean; PostingDate: Date)
    var
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchaseHeader(PurchHeader, ICInboxPurchHeader, ICDocDim, ReplacePostingDate, PostingDate);
        if not IsHandled then begin
            PurchHeader.Validate("IC Direction", PurchHeader."IC Direction"::Incoming);
            PurchHeader.Validate("Buy-from Vendor No.", ICInboxPurchHeader."Buy-from Vendor No.");
            if ICInboxPurchHeader."Pay-to Vendor No." <> PurchHeader."Pay-to Vendor No." then
                PurchHeader.Validate("Pay-to Vendor No.", ICInboxPurchHeader."Pay-to Vendor No.");
            case ICInboxPurchHeader."Document Type" of
                ICInboxPurchHeader."Document Type"::Order, ICInboxPurchHeader."Document Type"::"Return Order":
                    PurchHeader."Vendor Order No." := ICInboxPurchHeader."No.";
                ICInboxPurchHeader."Document Type"::Invoice:
                    PurchHeader."Vendor Invoice No." := ICInboxPurchHeader."No.";
                ICInboxPurchHeader."Document Type"::"Credit Memo":
                    PurchHeader."Vendor Cr. Memo No." := ICInboxPurchHeader."No.";
            end;
            PurchHeader."IC Reference Document No." := ICInboxPurchHeader."No.";
            PurchHeader."Your Reference" := ICInboxPurchHeader."Your Reference";
            PurchHeader."Ship-to Name" := ICInboxPurchHeader."Ship-to Name";
            PurchHeader."Ship-to Address" := ICInboxPurchHeader."Ship-to Address";
            PurchHeader."Ship-to Address 2" := ICInboxPurchHeader."Ship-to Address 2";
            PurchHeader."Ship-to City" := ICInboxPurchHeader."Ship-to City";
            PurchHeader."Ship-to Post Code" := ICInboxPurchHeader."Ship-to Post Code";
            PurchHeader."Ship-to County" := ICInboxPurchHeader."Ship-to County";
            PurchHeader."Ship-to Country/Region Code" := ICInboxPurchHeader."Ship-to Country/Region Code";
            PurchHeader."Ship-to Phone No." := ICInboxPurchHeader."Ship-to Phone No.";
            PurchHeader."Vendor Order No." := ICInboxPurchHeader."Vendor Order No.";
            if ReplacePostingDate then
                PurchHeader.Validate("Posting Date", PostingDate)
            else
                if ICInboxPurchHeader."Posting Date" <> 0D then
                    PurchHeader.Validate("Posting Date", ICInboxPurchHeader."Posting Date");
            GetCurrency(ICInboxPurchHeader."Currency Code");
            PurchHeader.Validate("Currency Code", ICInboxPurchHeader."Currency Code");
            PurchHeader.Validate("Document Date", ICInboxPurchHeader."Document Date");
            PurchHeader.Validate("Requested Receipt Date", ICInboxPurchHeader."Requested Receipt Date");
            PurchHeader.Validate("Promised Receipt Date", ICInboxPurchHeader."Promised Receipt Date");
            PurchHeader.Validate("Prices Including VAT", ICInboxPurchHeader."Prices Including VAT");
            PurchHeader.Validate("Due Date", ICInboxPurchHeader."Due Date");
            PurchHeader.Validate("Payment Discount %", ICInboxPurchHeader."Payment Discount %");
            PurchHeader.Validate("Pmt. Discount Date", ICInboxPurchHeader."Pmt. Discount Date");
            PurchHeader."Shortcut Dimension 1 Code" := '';
            PurchHeader."Shortcut Dimension 2 Code" := '';

            OnCreatePurchDocumentOnBeforeSetICDocDimFilters(PurchHeader, ICInboxPurchHeader);
            DimMgt.SetICDocDimFilters(
                ICDocDim, DATABASE::"IC Inbox Purchase Header", ICInboxPurchHeader."IC Transaction No.",
                ICInboxPurchHeader."IC Partner Code", ICInboxPurchHeader."Transaction Source", 0);

            DimensionSetIDArr[1] := PurchHeader."Dimension Set ID";
            DimensionSetIDArr[2] := DimMgt.CreateDimSetIDFromICDocDim(ICDocDim);
            PurchHeader."Dimension Set ID" :=
                DimMgt.GetCombinedDimensionSetID(
                DimensionSetIDArr, PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code");
            DimMgt.UpdateGlobalDimFromDimSetID(
                PurchHeader."Dimension Set ID", PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code");
            OnCreatePurchDocumentOnBeforePurchHeaderModify(PurchHeader, ICInboxPurchHeader);
            PurchHeader.Modify();
        end;
    end;

    procedure CreatePurchLines(PurchHeader: Record "Purchase Header"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    var
        PurchLine: Record "Purchase Line";
        ICDocDim: Record "IC Document Dimension";
        Currency: Record Currency;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        Precision: Decimal;
        Precision2: Decimal;
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJG', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK7', ICMapping.GetFeatureTelemetryName(), 'Creating Purchase Lines');

        IsHandled := false;
        OnBeforeCreatePurchLines(PurchHeader, ICInboxPurchLine, IsHandled);
        if not IsHandled then begin
            PurchLine.Init();
            PurchLine.TransferFields(ICInboxPurchLine);
            OnCreatePurchLinesOnAfterTransferFields(PurchLine, ICInboxPurchLine);

            PurchLine."Document Type" := PurchHeader."Document Type";
            PurchLine."Document No." := PurchHeader."No.";
            PurchLine."Line No." := ICInboxPurchLine."Line No.";
            PurchLine.Insert(true);
            PurchLine."Receipt No." := '';
            PurchLine."Return Shipment No." := '';

            OnCreatePurchLinesOnBeforeAssignTypeAndNo(PurchLine, ICInboxPurchLine);
            case ICInboxPurchLine."IC Partner Ref. Type" of
                "IC Partner Reference Type"::"Common Item No.":
                    begin
                        PurchLine.Type := PurchLine.Type::Item;
                        PurchLine."No." := GetItemFromCommonItem(ICInboxPurchLine."IC Partner Reference");
                        if PurchLine."No." <> '' then
                            PurchLine.Validate("No.", PurchLine."No.")
                        else
                            PurchLine."No." := ICInboxPurchLine."IC Partner Reference";
                    end;
                "IC Partner Reference Type"::Item:
                    begin
                        PurchLine.Validate(Type, PurchLine.Type::Item);
                        PurchLine."No." :=
                            GetItemFromItemRef(
                                ICInboxPurchLine."IC Partner Reference", "Item Reference Type"::Vendor, PurchHeader."Buy-from Vendor No.", PurchLine.GetDateForCalculations());
                        if PurchLine."No." <> '' then
                            PurchLine.Validate("No.", PurchLine."No.")
                        else
                            PurchLine."No." := ICInboxPurchLine."IC Partner Reference";
                    end;
                "IC Partner Reference Type"::"G/L Account":
                    begin
                        PurchLine.Validate(Type, PurchLine.Type::"G/L Account");
                        PurchLine.Validate("No.", TranslateICGLAccount(ICInboxPurchLine."IC Partner Reference"));
                    end;
                "IC Partner Reference Type"::"Charge (Item)":
                    begin
                        PurchLine.Type := PurchLine.Type::"Charge (Item)";
                        PurchLine.Validate("No.", ICInboxPurchLine."IC Partner Reference");
                    end;
                "IC Partner Reference Type"::"Cross reference":
                    begin
                        PurchLine.Validate(Type, PurchLine.Type::Item);
                        PurchLine.Validate("Item Reference No.", ICInboxPurchLine."IC Item Reference No.");
                    end;
                else
                    OnCreatePurchLinesOnICPartnerRefTypeCaseElse(PurchLine, PurchHeader, ICInboxPurchLine);
            end;
            OnCreatePurchLinesOnAfterValidateNo(PurchLine, PurchHeader, ICInboxPurchLine);
            PurchLine."Currency Code" := PurchHeader."Currency Code";
            if (PurchLine.Type <> PurchLine.Type::" ") and (ICInboxPurchLine.Quantity <> 0) then begin
                if Currency.Get(PurchHeader."Currency Code") then begin
                    Precision := Currency."Unit-Amount Rounding Precision";
                    Precision2 := Currency."Amount Rounding Precision"
                end else begin
                    GLSetup.Get();
                    if GLSetup."Unit-Amount Rounding Precision" <> 0 then
                        Precision := GLSetup."Unit-Amount Rounding Precision"
                    else
                        Precision := 0.01;
                    if GLSetup."Amount Rounding Precision" <> 0 then
                        Precision2 := GLSetup."Amount Rounding Precision"
                    else
                        Precision2 := 0.01;
                end;
                PurchLine.Validate(Quantity, ICInboxPurchLine.Quantity);
                PurchLine.Validate("Unit of Measure Code", ICInboxPurchLine."Unit of Measure Code");
                PurchLine.Description := ICInboxPurchLine.Description;
                PurchLine."Description 2" := ICInboxPurchLine."Description 2";
                IsHandled := false;
                OnCreatePurchLinesOnBeforeCalcPriceAndAmounts(PurchHeader, PurchLine, IsHandled);
                if not IsHandled then begin
                    PurchLine.Validate("Direct Unit Cost", ICInboxPurchLine."Direct Unit Cost");
                    PurchLine."Amount Including VAT" := ICInboxPurchLine."Amount Including VAT";
                    PurchLine.Validate("Line Discount Amount", ICInboxPurchLine."Line Discount Amount");
                    PurchLine.Validate("Inv. Discount Amount", ICInboxPurchLine."Inv. Discount Amount");
                    PurchLine."VAT Base Amount" := Round(ICInboxPurchLine."Amount Including VAT" / (1 + (PurchLine."VAT %" / 100)), Precision2);
                    PurchLine."VAT Difference" := ICInboxPurchLine."VAT Difference";
                    if PurchHeader."Prices Including VAT" then
                        PurchLine."Line Amount" := ICInboxPurchLine."Amount Including VAT"
                    else
                        PurchLine."Line Amount" := ICInboxPurchLine."Line Amount";
                end;
                PurchLine.Validate("Requested Receipt Date", ICInboxPurchLine."Requested Receipt Date");
                PurchLine.Validate("Promised Receipt Date", ICInboxPurchLine."Promised Receipt Date");
                PurchLine."Line Discount %" := ICInboxPurchLine."Line Discount %";
                PurchLine."Receipt No." := ICInboxPurchLine."Receipt No.";
                PurchLine."Receipt Line No." := ICInboxPurchLine."Receipt Line No.";
                PurchLine."Return Shipment No." := ICInboxPurchLine."Return Shipment No.";
                PurchLine."Return Shipment Line No." := ICInboxPurchLine."Return Shipment Line No.";
                UpdatePurchLineICPartnerReference(PurchLine, PurchHeader, ICInboxPurchLine);
                UpdatePurchLineReceiptShipment(PurchLine);
            end;
            PurchLine."Shortcut Dimension 1 Code" := '';
            PurchLine."Shortcut Dimension 2 Code" := '';

            OnCreatePurchLinesOnAfterAssignPurchLineFields(PurchLine, ICInboxPurchLine, PurchHeader);

            DimMgt.SetICDocDimFilters(
              ICDocDim, DATABASE::"IC Inbox Purchase Line", ICInboxPurchLine."IC Transaction No.",
              ICInboxPurchLine."IC Partner Code", ICInboxPurchLine."Transaction Source", ICInboxPurchLine."Line No.");
            DimensionSetIDArr[1] := PurchLine."Dimension Set ID";
            DimensionSetIDArr[2] := DimMgt.CreateDimSetIDFromICDocDim(ICDocDim);
            PurchLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(
                DimensionSetIDArr, PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code");
            DimMgt.UpdateGlobalDimFromDimSetID(
              PurchLine."Dimension Set ID", PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code");

            OnCreatePurchLinesOnBeforeModify(PurchLine, ICInboxPurchLine);
            PurchLine.Modify();
            OnCreatePurchLinesOnAfterModify(PurchLine, ICInboxPurchLine);
        end;

        OnAfterCreatePurchLines(ICInboxPurchLine, PurchLine);
    end;

    procedure CreateHandledInbox(InboxTransaction: Record "IC Inbox Transaction")
    var
        HandledInboxTransaction: Record "Handled IC Inbox Trans.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJH', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK8', ICMapping.GetFeatureTelemetryName(), 'Creating Handled Inbox');

        HandledInboxTransaction.Init();
        HandledInboxTransaction."Transaction No." := InboxTransaction."Transaction No.";
        HandledInboxTransaction."IC Partner Code" := InboxTransaction."IC Partner Code";
        HandledInboxTransaction."IC Source Type" := InboxTransaction."IC Source Type";
        HandledInboxTransaction."Document Type" := InboxTransaction."Document Type";
        HandledInboxTransaction."Document No." := InboxTransaction."Document No.";
        HandledInboxTransaction."Posting Date" := InboxTransaction."Posting Date";
        HandledInboxTransaction."Transaction Source" := InboxTransaction."Transaction Source";
        HandledInboxTransaction."Document Date" := InboxTransaction."Document Date";

        case InboxTransaction."Line Action" of
            InboxTransaction."Line Action"::"Return to IC Partner":
                HandledInboxTransaction."Transaction Source" := HandledInboxTransaction."Transaction Source"::"Returned by Partner";
            InboxTransaction."Line Action"::Accept:
                if InboxTransaction."Transaction Source" = InboxTransaction."Transaction Source"::"Created by Partner" then
                    HandledInboxTransaction."Transaction Source" := HandledInboxTransaction."Transaction Source"::"Created by Partner"
                else
                    HandledInboxTransaction."Transaction Source" := HandledInboxTransaction."Transaction Source"::"Returned by Partner";
        end;
        OnBeforeHandledInboxTransactionInsert(HandledInboxTransaction, InboxTransaction);
        HandledInboxTransaction.Insert();
    end;

    procedure IsSalesHeaderFromIncomingIC(var SalesHeader: Record "Sales Header"): Boolean
    begin
        exit(
            (SalesHeader."IC Direction" = SalesHeader."IC Direction"::Incoming) and
            (SalesHeader."IC Reference Document No." <> '') and
            (SalesHeader."Sell-to IC Partner Code" <> '')
        );
    end;

    procedure IsPurchaseHeaderFromIncomingIC(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        exit(
            (PurchaseHeader."IC Direction" = PurchaseHeader."IC Direction"::Incoming) and
            (PurchaseHeader."IC Reference Document No." <> '') and
            (PurchaseHeader."Buy-from IC Partner Code" <> '')
        );
    end;

    procedure ShowDuplicateICDocumentWarning(var PurchaseHeader: Record "Purchase Header")
    begin
        ShowDuplicateICDocumentWarning(PurchaseHeader, DuplicateICDocumentMsg);
    end;

    procedure ShowDuplicateICDocumentWarning(var PurchaseHeader: Record "Purchase Header"; WarningMsg: Text)
    var
        Notification: Notification;
        DocumentType: Text;
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                DocumentType := 'order';
            PurchaseHeader."Document Type"::Invoice:
                DocumentType := 'invoice';
            else
                exit;
        end;
        Notification.Message(StrSubstNo(WarningMsg, DocumentType, PurchaseHeader."No."));
        Notification.Send();
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RejectAcceptedPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
    begin
        if not GetHandledInboxTransaction(PurchaseHeader, HandledICInboxTrans) then
            Error(TransactionCantBeFoundErr);
        PurchaseHeader.Delete(true);
        RecreateInboxTransactionAndReturn(HandledICInboxTrans);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RejectAcceptedSalesHeader(var SalesHeader: Record "Sales Header")
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRejectAcceptedSalesHeader(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if not GetHandledInboxTransaction(SalesHeader, HandledICInboxTrans) then
            Error(TransactionCantBeFoundErr);
        SalesHeader.Delete(true);
        RecreateInboxTransactionAndReturn(HandledICInboxTrans);
    end;

    local procedure RecreateInboxTransactionAndReturn(var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        TransactionNo: Integer;
        ICPartnerCode: Code[20];
        TransactionSource: Option "Returned by Partner","Created by Partner";
        DocumentType: Enum "IC Transaction Document Type";
    begin
        GetICInboxKeys(HandledICInboxTrans, TransactionNo, ICPartnerCode, TransactionSource, DocumentType);
        RecreateInboxTransaction(HandledICInboxTrans, false);
        ICInboxTransaction.Get(TransactionNo, ICPartnerCode, TransactionSource, DocumentType);
        ICInboxTransaction."Line Action" := ICInboxTransaction."Line Action"::"Return to IC Partner";
        ICInboxTransaction.Modify();
        Report.RunModal(Report::"Complete IC Inbox Action", false, false, ICInboxTransaction);
    end;

    local procedure GetICInboxKeys(var HandledICInboxTrans: Record "Handled IC Inbox Trans."; var TransactionNo: Integer; var ICPartnerCode: Code[20]; var TransactionSource: Option "Returned by Partner","Created by Partner"; var DocumentType: Enum "IC Transaction Document Type")
    begin
        TransactionNo := HandledICInboxTrans."Transaction No.";
        ICPartnerCode := HandledICInboxTrans."IC Partner Code";
        TransactionSource := HandledICInboxTrans."Transaction Source";
        DocumentType := HandledICInboxTrans."Document Type";
    end;

    local procedure GetHandledInboxTransaction(var SalesHeader: Record "Sales Header"; var HandledICInboxTrans: Record "Handled IC Inbox Trans."): Boolean
    var
        HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        ICTransactionDocumentType: Enum "IC Transaction Document Type";
    begin
        // To get the corresponding Handled Inbox transaction of a Sales Header, we first
        // find the Handled Inbox Sales Header and then use its Transaction No. to
        // find the Handled Inbox Transaction.

        // Filters from the primary key of HandledICInboxSalesHeader
        HandledICInboxSalesHeader.SetRange("IC Partner Code", SalesHeader."Sell-to IC Partner Code");
        HandledICInboxSalesHeader.SetRange("Transaction Source", HandledICInboxSalesHeader."Transaction Source"::"Created by Partner");
        // Filters from the primary key of SalesHeader
        HandledICInboxSalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        // Other filters in Sales Header that should be set by UpdateSalesHeader (we cannot take into account manual modifications by the user)
        HandledICInboxSalesHeader.SetRange("No.", SalesHeader."IC Reference Document No."); // We could also use SalesHeader."External Document No.", but I'm uptaking the fix from PR 134226

        // We consider the latest Transaction matching these filters
        HandledICInboxSalesHeader.SetCurrentKey("IC Transaction No.");
        HandledICInboxSalesHeader.SetAscending("IC Transaction No.", false);
        if not HandledICInboxSalesHeader.FindFirst() then
            exit(false);

        // Enums for Document Type between Sales and Transactions are incompatible
        case HandledICInboxSalesHeader."Document Type" of
            HandledICInboxSalesHeader."Document Type"::Order:
                ICTransactionDocumentType := ICTransactionDocumentType::Order;
            HandledICInboxSalesHeader."Document Type"::Invoice:
                ICTransactionDocumentType := ICTransactionDocumentType::Invoice;
            HandledICInboxSalesHeader."Document Type"::"Credit Memo":
                ICTransactionDocumentType := ICTransactionDocumentType::"Credit Memo";
            HandledICInboxSalesHeader."Document Type"::"Return Order":
                ICTransactionDocumentType := ICTransactionDocumentType::"Return Order";
        end;

        if not HandledICInboxTrans.Get(HandledICInboxSalesHeader."IC Transaction No.", HandledICInboxSalesHeader."IC Partner Code", HandledICInboxSalesHeader."Transaction Source", ICTransactionDocumentType) then
            exit(false);
        exit(HandledICInboxTrans.Status = HandledICInboxTrans.Status::Accepted); // We verify that the Handled Transaction is marked as accepted
    end;

    local procedure GetHandledInboxTransaction(var PurchaseHeader: Record "Purchase Header"; var HandledICInboxTrans: Record "Handled IC Inbox Trans."): Boolean
    var
        HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        ICTransactionDocumentType: Enum "IC Transaction Document Type";
    begin
        // To get the corresponding Handled Inbox transaction of a Sales Header, we first
        // find the Handled Inbox Sales Header and then use its Transaction No. to
        // find the Handled Inbox Transaction.

        // Filters from the primary key of HandledICInboxPurchaseHeader
        HandledICInboxPurchHeader.SetRange("IC Partner Code", PurchaseHeader."Buy-from IC Partner Code");
        HandledICInboxPurchHeader.SetRange("Transaction Source", HandledICInboxPurchHeader."Transaction Source"::"Created by Partner");
        // Filters from the primary key of PurchaseHeader
        HandledICInboxPurchHeader.SetRange("Document Type", PurchaseHeader."Document Type");
        // Other filters in Purchase Header that should be set by UpdatePurchaseHeader (we cannot take into account manual modifications by the user)
        HandledICInboxPurchHeader.SetRange("No.", PurchaseHeader."IC Reference Document No."); // We could also use PurchaseHeader."Vendor Order No."/"Vendor Invoice No."/"Vendor Cr. Memo No." depending on Document Type

        // We consider the latest Transaction matching these filters
        HandledICInboxPurchHeader.SetCurrentKey("IC Transaction No.");
        HandledICInboxPurchHeader.SetAscending("IC Transaction No.", false);
        if not HandledICInboxPurchHeader.FindFirst() then
            exit(false);

        // Enums for Document Type between Purchases and Transactions are incompatible
        case HandledICInboxPurchHeader."Document Type" of
            HandledICInboxPurchHeader."Document Type"::Order:
                ICTransactionDocumentType := ICTransactionDocumentType::Order;
            HandledICInboxPurchHeader."Document Type"::Invoice:
                ICTransactionDocumentType := ICTransactionDocumentType::Invoice;
            HandledICInboxPurchHeader."Document Type"::"Credit Memo":
                ICTransactionDocumentType := ICTransactionDocumentType::"Credit Memo";
            HandledICInboxPurchHeader."Document Type"::"Return Order":
                ICTransactionDocumentType := ICTransactionDocumentType::"Return Order";
        end;

        if not HandledICInboxTrans.Get(HandledICInboxPurchHeader."IC Transaction No.", HandledICInboxPurchHeader."IC Partner Code", HandledICInboxPurchHeader."Transaction Source", ICTransactionDocumentType) then
            exit(false);
        exit(HandledICInboxTrans.Status = HandledICInboxTrans.Status::Accepted); // We verify that the Handled Transaction is marked as accepted
    end;


    procedure RecreateInboxTransaction(var HandledInboxTransaction: Record "Handled IC Inbox Trans.")
    begin
        RecreateInboxTransaction(HandledInboxTransaction, true);
    end;

    procedure RecreateInboxTransaction(var HandledInboxTransaction: Record "Handled IC Inbox Trans."; Confirm: Boolean)
    var
        HandledInboxTransaction2: Record "Handled IC Inbox Trans.";
        HandledInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        InboxTransaction: Record "IC Inbox Transaction";
        InboxJnlLine: Record "IC Inbox Jnl. Line";
        ICCommentLine: Record "IC Comment Line";
        HandledInboxSalesHdr: Record "Handled IC Inbox Sales Header";
        InboxSalesHdr: Record "IC Inbox Sales Header";
        HandledInboxSalesLine: Record "Handled IC Inbox Sales Line";
        InboxSalesLine: Record "IC Inbox Sales Line";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HandledInboxPurchHdr: Record "Handled IC Inbox Purch. Header";
        InboxPurchHdr: Record "IC Inbox Purchase Header";
        HandledInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        InboxPurchLine: Record "IC Inbox Purchase Line";
        ICIOMgt: Codeunit ICInboxOutboxMgt;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        FeatureTelemetry.LogUptake('0000IJI', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IK9', ICMapping.GetFeatureTelemetryName(), 'Recreate Inbox Transaction');

        if not (HandledInboxTransaction.Status in [HandledInboxTransaction.Status::Accepted, HandledInboxTransaction.Status::Cancelled]) then
            Error(Text005, HandledInboxTransaction.FieldCaption(Status), HandledInboxTransaction.Status::Accepted, HandledInboxTransaction.Status::Cancelled);

        if Confirm then
            if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
                exit;

        HandledInboxTransaction2 := HandledInboxTransaction;
        HandledInboxTransaction2.LockTable();
        InboxTransaction.LockTable();
        InboxTransaction.Init();
        InboxTransaction."Transaction No." := HandledInboxTransaction2."Transaction No.";
        InboxTransaction."IC Partner Code" := HandledInboxTransaction2."IC Partner Code";
        InboxTransaction."IC Source Type" := HandledInboxTransaction2."IC Source Type";
        InboxTransaction."Document Type" := HandledInboxTransaction2."Document Type";
        InboxTransaction."Document No." := HandledInboxTransaction2."Document No.";
        InboxTransaction."Posting Date" := HandledInboxTransaction2."Posting Date";
        InboxTransaction."Transaction Source" := InboxTransaction."Transaction Source"::"Created by Partner";
        InboxTransaction."Transaction Source" := HandledInboxTransaction2."Transaction Source";
        InboxTransaction."Document Date" := HandledInboxTransaction2."Document Date";
        InboxTransaction."IC Account Type" := HandledInboxTransaction2."IC Account Type";
        InboxTransaction."IC Account No." := HandledInboxTransaction2."IC Account No.";
        InboxTransaction."Source Line No." := HandledInboxTransaction2."Source Line No.";
        OnRecreateInboxTransactionOnBeforeInboxTransactionInsert(InboxTransaction, HandledInboxTransaction2, HandledInboxTransaction);
        InboxTransaction.Insert();
        case InboxTransaction."IC Source Type" of
            InboxTransaction."IC Source Type"::Journal:
                begin
                    HandledInboxJnlLine.LockTable();
                    InboxJnlLine.LockTable();
                    HandledInboxJnlLine.SetRange("Transaction No.", HandledInboxTransaction2."Transaction No.");
                    HandledInboxJnlLine.SetRange("IC Partner Code", HandledInboxTransaction2."IC Partner Code");
                    if HandledInboxJnlLine.Find('-') then
                        repeat
                            InboxJnlLine.Init();
                            InboxJnlLine.TransferFields(HandledInboxJnlLine);
                            InboxJnlLine.Insert();
                            ICIOMgt.MoveICJnlDimToHandled(DATABASE::"Handled IC Inbox Jnl. Line", DATABASE::"IC Inbox Jnl. Line",
                                HandledInboxTransaction."Transaction No.", HandledInboxTransaction."IC Partner Code",
                                false, 0);
                        until HandledInboxJnlLine.Next() = 0;
                    HandleICComments(ICCommentLine."Table Name"::"Handled IC Inbox Transaction",
                        ICCommentLine."Table Name"::"IC Inbox Transaction", HandledInboxTransaction2."Transaction No.",
                        HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source");
                    HandledInboxTransaction.Delete(true);
                    Commit();
                end;
            InboxTransaction."IC Source Type"::"Sales Document":
                begin
                    if HandledInboxSalesHdr.Get(HandledInboxTransaction2."Transaction No.",
                            HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source")
                    then begin
                        InboxSalesHdr.TransferFields(HandledInboxSalesHdr);
                        OnRecreateInboxTransactionOnBeforeInboxSalesHdrInsert(InboxSalesHdr, HandledInboxSalesHdr);
                        InboxSalesHdr.Insert();

                        ICDocDim.Reset();
                        DimMgt.SetICDocDimFilters(
                            ICDocDim, DATABASE::"Handled IC Inbox Sales Header", HandledInboxTransaction2."Transaction No.",
                            HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source", 0);
                        if ICDocDim.Find('-') then
                            DimMgt.MoveICDocDimtoICDocDim(
                                ICDocDim, ICDocDim2, DATABASE::"IC Inbox Sales Header", InboxSalesHdr."Transaction Source");
                        HandledInboxSalesLine.SetRange("IC Transaction No.", HandledInboxTransaction2."Transaction No.");
                        HandledInboxSalesLine.SetRange("IC Partner Code", HandledInboxTransaction2."IC Partner Code");
                        HandledInboxSalesLine.SetRange("Transaction Source", HandledInboxTransaction2."Transaction Source");
                        if HandledInboxSalesLine.Find('-') then
                            repeat
                                InboxSalesLine.TransferFields(HandledInboxSalesLine);
                                OnBeforeInboxSalesLineInsert(InboxSalesLine, HandledInboxSalesLine);
                                InboxSalesLine.Insert();

                                ICDocDim.Reset();
                                DimMgt.SetICDocDimFilters(
                                    ICDocDim, DATABASE::"Handled IC Inbox Sales Line", HandledInboxTransaction2."Transaction No.",
                                    HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source",
                                    HandledInboxSalesLine."Line No.");
                                if ICDocDim.Find('-') then
                                    DimMgt.MoveICDocDimtoICDocDim(
                                        ICDocDim, ICDocDim2, DATABASE::"IC Inbox Sales Line", InboxSalesLine."Transaction Source");
                                HandledInboxSalesLine.Delete(true);
                            until HandledInboxSalesLine.Next() = 0;
                    end;
                    HandleICComments(ICCommentLine."Table Name"::"Handled IC Inbox Transaction",
                        ICCommentLine."Table Name"::"IC Inbox Transaction", HandledInboxTransaction2."Transaction No.",
                        HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source");
                    OnRecreateInboxTransactionOnBeforeDeleteSalesHeader(HandledInboxSalesHdr, HandledInboxTransaction2);
                    HandledInboxSalesHdr.Delete(true);
                    HandledInboxTransaction.Delete(true);
                    Commit();
                end;
            InboxTransaction."IC Source Type"::"Purchase Document":
                begin
                    if HandledInboxPurchHdr.Get(HandledInboxTransaction2."Transaction No.",
                            HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source")
                    then begin
                        InboxPurchHdr.TransferFields(HandledInboxPurchHdr);
                        OnRecreateInboxTransactionOnBeforeInboxPurchHdrInsert(InboxPurchHdr, HandledInboxPurchHdr);
                        InboxPurchHdr.Insert();

                        ICDocDim.Reset();
                        DimMgt.SetICDocDimFilters(
                            ICDocDim, DATABASE::"Handled IC Inbox Purch. Header", HandledInboxTransaction2."Transaction No.",
                            HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source", 0);
                        if ICDocDim.Find('-') then
                            DimMgt.MoveICDocDimtoICDocDim(
                                ICDocDim, ICDocDim2, DATABASE::"IC Inbox Purchase Header", InboxPurchHdr."Transaction Source");
                        HandledInboxPurchLine.SetRange("IC Transaction No.", HandledInboxTransaction2."Transaction No.");
                        HandledInboxPurchLine.SetRange("IC Partner Code", HandledInboxTransaction2."IC Partner Code");
                        HandledInboxPurchLine.SetRange("Transaction Source", HandledInboxTransaction2."Transaction Source");
                        if HandledInboxPurchLine.Find('-') then
                            repeat
                                InboxPurchLine.TransferFields(HandledInboxPurchLine);
                                OnRecreateInboxTransactionOnBeforeInboxPurchLineInsert(InboxPurchLine, HandledInboxPurchLine);
                                InboxPurchLine.Insert();

                                ICDocDim.Reset();
                                DimMgt.SetICDocDimFilters(
                                    ICDocDim, DATABASE::"Handled IC Inbox Purch. Line", HandledInboxTransaction2."Transaction No.",
                                    HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source",
                                    HandledInboxPurchLine."Line No.");
                                if ICDocDim.Find('-') then
                                    DimMgt.MoveICDocDimtoICDocDim(
                                        ICDocDim, ICDocDim2, DATABASE::"IC Inbox Purchase Line", InboxPurchLine."Transaction Source");
                                HandledInboxPurchLine.Delete(true);
                            until HandledInboxPurchLine.Next() = 0;
                    end;
                    HandleICComments(ICCommentLine."Table Name"::"Handled IC Inbox Transaction",
                        ICCommentLine."Table Name"::"IC Inbox Transaction", HandledInboxTransaction2."Transaction No.",
                        HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source");
                    OnRecreateInboxTransactionOnBeforeDeletePurchHeader(HandledInboxPurchHdr, HandledInboxTransaction2);
                    HandledInboxPurchHdr.Delete(true);
                    HandledInboxTransaction.Delete(true);
                end;
        end;
    end;

    procedure RecreateOutboxTransaction(var HandledOutboxTransaction: Record "Handled IC Outbox Trans.")
    var
        HandledOutboxTransaction2: Record "Handled IC Outbox Trans.";
        HandledOutboxJnlLine: Record "Handled IC Outbox Jnl. Line";
        OutboxTransaction: Record "IC Outbox Transaction";
        OutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICCommentLine: Record "IC Comment Line";
        HandledOutboxSalesHdr: Record "Handled IC Outbox Sales Header";
        OutboxSalesHdr: Record "IC Outbox Sales Header";
        HandledOutboxSalesLine: Record "Handled IC Outbox Sales Line";
        OutboxSalesLine: Record "IC Outbox Sales Line";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HandledOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        OutboxPurchHdr: Record "IC Outbox Purchase Header";
        HandledOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
        OutboxPurchLine: Record "IC Outbox Purchase Line";
        ICIOMgt: Codeunit ICInboxOutboxMgt;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        FeatureTelemetry.LogUptake('0000IJJ', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKA', ICMapping.GetFeatureTelemetryName(), 'Recreate Outbox Transaction');

        if not (HandledOutboxTransaction.Status in [HandledOutboxTransaction.Status::"Sent to IC Partner", HandledOutboxTransaction.Status::Cancelled]) then
            Error(Text005, HandledOutboxTransaction.FieldCaption(Status), HandledOutboxTransaction.Status::"Sent to IC Partner", HandledOutboxTransaction.Status::Cancelled);

        if ConfirmManagement.GetResponseOrDefault(Text000, true) then begin
            HandledOutboxTransaction2 := HandledOutboxTransaction;
            HandledOutboxTransaction2.LockTable();
            OutboxTransaction.LockTable();
            OutboxTransaction.Init();
            OutboxTransaction."Transaction No." := HandledOutboxTransaction2."Transaction No.";
            OutboxTransaction."IC Partner Code" := HandledOutboxTransaction2."IC Partner Code";
            OutboxTransaction."IC Source Type" := HandledOutboxTransaction2."IC Source Type";
            OutboxTransaction."Document Type" := HandledOutboxTransaction2."Document Type";
            OutboxTransaction."Document No." := HandledOutboxTransaction2."Document No.";
            OutboxTransaction."Posting Date" := HandledOutboxTransaction2."Posting Date";
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
            OutboxTransaction."Transaction Source" := HandledOutboxTransaction2."Transaction Source";
            OutboxTransaction."Document Date" := HandledOutboxTransaction2."Document Date";
            OutboxTransaction."IC Account Type" := HandledOutboxTransaction2."IC Account Type";
            OutboxTransaction."IC Account No." := HandledOutboxTransaction2."IC Account No.";
            OutboxTransaction."Source Line No." := HandledOutboxTransaction2."Source Line No.";
            OnRecreateOutboxTransactionOnBeforeOutboxTransactionInsert(OutboxTransaction, HandledOutboxTransaction2, HandledOutboxTransaction);
            OutboxTransaction.Insert();
            case OutboxTransaction."IC Source Type" of
                OutboxTransaction."IC Source Type"::Journal:
                    begin
                        HandledOutboxJnlLine.LockTable();
                        OutboxJnlLine.LockTable();
                        HandledOutboxJnlLine.SetRange("Transaction No.", HandledOutboxTransaction2."Transaction No.");
                        HandledOutboxJnlLine.SetRange("IC Partner Code", HandledOutboxTransaction2."IC Partner Code");
                        if HandledOutboxJnlLine.Find('-') then
                            repeat
                                OutboxJnlLine.Init();
                                OutboxJnlLine.TransferFields(HandledOutboxJnlLine);
                                OutboxJnlLine.Insert();
                                ICIOMgt.MoveICJnlDimToHandled(DATABASE::"Handled IC Outbox Jnl. Line", DATABASE::"IC Outbox Jnl. Line",
                                  HandledOutboxTransaction."Transaction No.", HandledOutboxTransaction."IC Partner Code",
                                  false, 0);
                            until HandledOutboxJnlLine.Next() = 0;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Outbox Transaction",
                          ICCommentLine."Table Name"::"IC Outbox Transaction", HandledOutboxTransaction2."Transaction No.",
                          HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source");
                        HandledOutboxTransaction.Delete(true);
                        Commit();
                    end;
                OutboxTransaction."IC Source Type"::"Sales Document":
                    begin
                        if HandledOutboxSalesHdr.Get(HandledOutboxTransaction2."Transaction No.",
                             HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source")
                        then begin
                            OutboxSalesHdr.TransferFields(HandledOutboxSalesHdr);
                            OutboxSalesHdr.Insert();
                            ICDocDim.Reset();
                            DimMgt.SetICDocDimFilters(
                              ICDocDim, DATABASE::"Handled IC Outbox Sales Header", HandledOutboxTransaction2."Transaction No.",
                              HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source", 0);
                            if ICDocDim.Find('-') then
                                DimMgt.MoveICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"IC Outbox Sales Header", OutboxSalesHdr."Transaction Source");
                            HandledOutboxSalesLine.SetRange("IC Transaction No.", HandledOutboxTransaction2."Transaction No.");
                            HandledOutboxSalesLine.SetRange("IC Partner Code", HandledOutboxTransaction2."IC Partner Code");
                            HandledOutboxSalesLine.SetRange("Transaction Source", HandledOutboxTransaction2."Transaction Source");
                            if HandledOutboxSalesLine.Find('-') then
                                repeat
                                    OutboxSalesLine.TransferFields(HandledOutboxSalesLine);
                                    OnRecreateOutboxTransactionOnBeforeOutboxSalesLineInsert(OutboxSalesLine, HandledOutboxSalesLine);
                                    OutboxSalesLine.Insert();
                                    ICDocDim.Reset();
                                    DimMgt.SetICDocDimFilters(
                                      ICDocDim, DATABASE::"Handled IC Outbox Sales Line", HandledOutboxTransaction2."Transaction No.",
                                      HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source",
                                      HandledOutboxSalesLine."Line No.");
                                    if ICDocDim.Find('-') then
                                        DimMgt.MoveICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"IC Outbox Sales Line", OutboxSalesLine."Transaction Source");
                                    HandledOutboxSalesLine.Delete(true);
                                until HandledOutboxSalesLine.Next() = 0;
                        end;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Outbox Transaction",
                          ICCommentLine."Table Name"::"IC Outbox Transaction", HandledOutboxTransaction2."Transaction No.",
                          HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source");
                        OnRecreateOutboxTransactionOnBeforeDeleteSalesHeader(HandledOutboxSalesHdr, HandledOutboxTransaction2);
                        HandledOutboxSalesHdr.Delete(true);
                        HandledOutboxTransaction.Delete(true);
                    end;
                OutboxTransaction."IC Source Type"::"Purchase Document":
                    begin
                        if HandledOutboxPurchHdr.Get(HandledOutboxTransaction2."Transaction No.",
                             HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source")
                        then begin
                            OutboxPurchHdr.TransferFields(HandledOutboxPurchHdr);
                            OnRecreateOutboxTransactionOnBeforeOutboxPurchHdrInsert(OutboxPurchHdr, HandledOutboxPurchHdr);
                            OutboxPurchHdr.Insert();

                            ICDocDim.Reset();
                            DimMgt.SetICDocDimFilters(
                              ICDocDim, DATABASE::"Handled IC Outbox Purch. Hdr", HandledOutboxTransaction2."Transaction No.",
                              HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source", 0);
                            if ICDocDim.Find('-') then
                                DimMgt.MoveICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"IC Outbox Purchase Header", OutboxPurchHdr."Transaction Source");
                            HandledOutboxPurchLine.SetRange("IC Transaction No.", HandledOutboxTransaction2."Transaction No.");
                            HandledOutboxPurchLine.SetRange("IC Partner Code", HandledOutboxTransaction2."IC Partner Code");
                            HandledOutboxPurchLine.SetRange("Transaction Source", HandledOutboxTransaction2."Transaction Source");
                            if HandledOutboxPurchLine.Find('-') then
                                repeat
                                    OutboxPurchLine.TransferFields(HandledOutboxPurchLine);
                                    OnRecreateOutboxTransactionOnBeforeOutboxPurchLineInsert(OutboxPurchLine, HandledOutboxPurchLine);
                                    OutboxPurchLine.Insert();

                                    ICDocDim.Reset();
                                    DimMgt.SetICDocDimFilters(
                                      ICDocDim, DATABASE::"Handled IC Outbox Purch. Line", HandledOutboxTransaction2."Transaction No.",
                                      HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source",
                                      HandledOutboxPurchLine."Line No.");
                                    if ICDocDim.Find('-') then
                                        DimMgt.MoveICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"IC Outbox Purchase Line", OutboxPurchLine."Transaction Source");
                                    HandledOutboxPurchLine.Delete(true);
                                until HandledOutboxPurchLine.Next() = 0;
                        end;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Outbox Transaction",
                          ICCommentLine."Table Name"::"IC Outbox Transaction", HandledOutboxTransaction2."Transaction No.",
                          HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source");
                        OnRecreateOutboxTransactionOnBeforeDeletePurchHeader(HandledOutboxPurchHdr, HandledOutboxTransaction2);
                        HandledOutboxPurchHdr.Delete(true);
                        HandledOutboxTransaction.Delete(true);
                    end;
            end;
        end
    end;

    procedure ForwardToOutBox(InboxTransaction: Record "IC Inbox Transaction")
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        OutboxJnlLine: Record "IC Outbox Jnl. Line";
        InboxJnlLine: Record "IC Inbox Jnl. Line";
        OutboxSalesHdr: Record "IC Outbox Sales Header";
        OutboxSalesLine: Record "IC Outbox Sales Line";
        InboxSalesHdr: Record "IC Inbox Sales Header";
        InboxSalesLine: Record "IC Inbox Sales Line";
        OutboxPurchHdr: Record "IC Outbox Purchase Header";
        OutboxPurchLine: Record "IC Outbox Purchase Line";
        InboxPurchHdr: Record "IC Inbox Purchase Header";
        InboxPurchLine: Record "IC Inbox Purchase Line";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HndlInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        HndlInboxSalesHdr: Record "Handled IC Inbox Sales Header";
        HndlInboxSalesLine: Record "Handled IC Inbox Sales Line";
        HndlInboxPurchHdr: Record "Handled IC Inbox Purch. Header";
        HndlInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        ICJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        ICJnlLineDim2: Record "IC Inbox/Outbox Jnl. Line Dim.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJK', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKB', ICMapping.GetFeatureTelemetryName(), 'Forwarding to OutBox');

        OutboxTransaction.Init();
        OutboxTransaction."Transaction No." := InboxTransaction."Transaction No.";
        OutboxTransaction."IC Partner Code" := InboxTransaction."IC Partner Code";
        OutboxTransaction."IC Source Type" := InboxTransaction."IC Source Type";
        OutboxTransaction."Document Type" := InboxTransaction."Document Type";
        OutboxTransaction."Document No." := InboxTransaction."Document No.";
        OutboxTransaction."Posting Date" := InboxTransaction."Posting Date";
        OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Rejected by Current Company";
        OutboxTransaction."Document Date" := InboxTransaction."Document Date";
        OnForwardToOutBoxOnBeforeOutboxTransactionInsert(OutboxTransaction, InboxTransaction);
        OutboxTransaction.Insert();
        case InboxTransaction."IC Source Type" of
            InboxTransaction."IC Source Type"::Journal:
                begin
                    InboxJnlLine.SetRange("Transaction No.", InboxTransaction."Transaction No.");
                    InboxJnlLine.SetRange("IC Partner Code", InboxTransaction."IC Partner Code");
                    InboxJnlLine.SetRange("Transaction Source", InboxTransaction."Transaction Source");
                    if InboxJnlLine.Find('-') then
                        repeat
                            OutboxJnlLine.TransferFields(InboxJnlLine);
                            OutboxJnlLine."Transaction Source" := OutboxTransaction."Transaction Source";
                            OutboxJnlLine.Insert();
                            HndlInboxJnlLine.TransferFields(InboxJnlLine);
                            HndlInboxJnlLine.Insert();

                            ICJnlLineDim.SetRange("Table ID", DATABASE::"IC Inbox Jnl. Line");
                            ICJnlLineDim.SetRange("Transaction No.", InboxJnlLine."Transaction No.");
                            ICJnlLineDim.SetRange("IC Partner Code", InboxJnlLine."IC Partner Code");
                            ICJnlLineDim.SetRange("Line No.", InboxJnlLine."Line No.");
                            if ICJnlLineDim.Find('-') then
                                repeat
                                    ICJnlLineDim2 := ICJnlLineDim;
                                    ICJnlLineDim2."Table ID" := DATABASE::"IC Outbox Jnl. Line";
                                    ICJnlLineDim2."Transaction Source" := OutboxJnlLine."Transaction Source";
                                    ICJnlLineDim2.Insert();
                                until ICJnlLineDim.Next() = 0;

                        until InboxJnlLine.Next() = 0;
                end;
            InboxTransaction."IC Source Type"::"Sales Document":
                begin
                    if InboxSalesHdr.Get(InboxTransaction."Transaction No.", InboxTransaction."IC Partner Code", InboxTransaction."Transaction Source") then begin
                        OutboxSalesHdr.TransferFields(InboxSalesHdr);
                        OutboxSalesHdr."Transaction Source" := OutboxTransaction."Transaction Source";
                        OutboxSalesHdr.Insert();
                        ICDocDim.Reset();
                        DimMgt.SetICDocDimFilters(
                          ICDocDim, DATABASE::"IC Inbox Sales Header", InboxTransaction."Transaction No.", InboxTransaction."IC Partner Code", InboxTransaction."Transaction Source", 0);
                        if ICDocDim.Find('-') then
                            DimMgt.CopyICDocDimtoICDocDim(
                              ICDocDim, ICDocDim2, DATABASE::"IC Outbox Sales Header", OutboxSalesHdr."Transaction Source");
                        HndlInboxSalesHdr.TransferFields(InboxSalesHdr);
                        HndlInboxSalesHdr.Insert();
                        if ICDocDim.Find('-') then
                            DimMgt.MoveICDocDimtoICDocDim(
                              ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Header", InboxSalesHdr."Transaction Source");
                        InboxSalesLine.SetRange("IC Transaction No.", InboxTransaction."Transaction No.");
                        InboxSalesLine.SetRange("IC Partner Code", InboxTransaction."IC Partner Code");
                        InboxSalesLine.SetRange("Transaction Source", InboxTransaction."Transaction Source");
                        if InboxSalesLine.Find('-') then
                            repeat
                                OutboxSalesLine.TransferFields(InboxSalesLine);
                                OutboxSalesLine."Transaction Source" := OutboxTransaction."Transaction Source";
                                OutboxSalesLine.Insert();
                                ICDocDim.Reset();
                                DimMgt.SetICDocDimFilters(
                                  ICDocDim, DATABASE::"IC Inbox Sales Line", InboxTransaction."Transaction No.", InboxTransaction."IC Partner Code", InboxTransaction."Transaction Source",
                                  OutboxSalesLine."Line No.");
                                if ICDocDim.Find('-') then
                                    DimMgt.CopyICDocDimtoICDocDim(
                                      ICDocDim, ICDocDim2, DATABASE::"IC Outbox Sales Line", OutboxSalesLine."Transaction Source");
                                HndlInboxSalesLine.TransferFields(InboxSalesLine);
                                OnForwardToOutBoxOnBeforeHndlInboxSalesLineInsert(HndlInboxSalesLine, InboxSalesLine);
                                HndlInboxSalesLine.Insert();

                                if ICDocDim.Find('-') then
                                    DimMgt.MoveICDocDimtoICDocDim(
                                      ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Line", InboxSalesLine."Transaction Source");
                            until InboxSalesLine.Next() = 0;
                    end;
                    OnAfterForwardToOutBoxSalesDoc(InboxTransaction, OutboxTransaction);
                end;
            InboxTransaction."IC Source Type"::"Purchase Document":
                begin
                    if InboxPurchHdr.Get(InboxTransaction."Transaction No.", InboxTransaction."IC Partner Code", InboxTransaction."Transaction Source") then begin
                        OutboxPurchHdr.TransferFields(InboxPurchHdr);
                        OutboxPurchHdr."Transaction Source" := OutboxTransaction."Transaction Source";
                        OutboxPurchHdr.Insert();
                        ICDocDim.Reset();
                        DimMgt.SetICDocDimFilters(
                          ICDocDim, DATABASE::"IC Inbox Purchase Header", InboxTransaction."Transaction No.", InboxTransaction."IC Partner Code", InboxTransaction."Transaction Source", 0);
                        if ICDocDim.Find('-') then
                            DimMgt.CopyICDocDimtoICDocDim(
                              ICDocDim, ICDocDim2, DATABASE::"IC Outbox Purchase Header", OutboxPurchHdr."Transaction Source");
                        HndlInboxPurchHdr.TransferFields(InboxPurchHdr);
                        HndlInboxPurchHdr.Insert();
                        if ICDocDim.Find('-') then
                            DimMgt.MoveICDocDimtoICDocDim(
                              ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Header", InboxPurchHdr."Transaction Source");
                        InboxPurchLine.SetRange("IC Transaction No.", InboxTransaction."Transaction No.");
                        InboxPurchLine.SetRange("IC Partner Code", InboxTransaction."IC Partner Code");
                        InboxPurchLine.SetRange("Transaction Source", InboxTransaction."Transaction Source");
                        if InboxPurchLine.Find('-') then
                            repeat
                                OutboxPurchLine.TransferFields(InboxPurchLine);
                                OutboxPurchLine."Transaction Source" := OutboxTransaction."Transaction Source";
                                OutboxPurchLine.Insert();
                                ICDocDim.Reset();
                                DimMgt.SetICDocDimFilters(
                                  ICDocDim, DATABASE::"IC Inbox Purchase Line", InboxTransaction."Transaction No.", InboxTransaction."IC Partner Code", InboxTransaction."Transaction Source",
                                  OutboxPurchLine."Line No.");
                                if ICDocDim.Find('-') then
                                    DimMgt.CopyICDocDimtoICDocDim(
                                      ICDocDim, ICDocDim2, DATABASE::"IC Outbox Purchase Line", OutboxPurchLine."Transaction Source");
                                HndlInboxPurchLine.TransferFields(InboxPurchLine);
                                OnForwardToOutBoxOnBeforeHndlInboxPurchLineInsert(HndlInboxPurchLine, InboxPurchLine);
                                HndlInboxPurchLine.Insert();
                                if ICDocDim.Find('-') then
                                    DimMgt.MoveICDocDimtoICDocDim(
                                      ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Line", InboxPurchLine."Transaction Source");
                            until InboxPurchLine.Next() = 0;
                    end;
                    OnAfterForwardToOutBoxPurchDoc(InboxTransaction, OutboxTransaction);
                end;
        end;
        InsertICCommentLinesAsRejectedOutboxTransaction(InboxTransaction);
    end;

    local procedure InsertICCommentLinesAsRejectedOutboxTransaction(ICInboxTransaction: Record "IC Inbox Transaction")
    var
        ICCommentLine: Record "IC Comment Line";
        ICCommentLine2: Record "IC Comment Line";
    begin
        ICCommentLine.SetRange("Table Name", ICCommentLine."Table Name"::"Handled IC Inbox Transaction");
        ICCommentLine.SetRange("Transaction No.", ICInboxTransaction."Transaction No.");
        ICCommentLine.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        if ICCommentLine.Find('-') then
            repeat
                ICCommentLine2 := ICCommentLine;
                ICCommentLine2."Table Name" := ICCommentLine."Table Name"::"IC Outbox Transaction";
                ICCommentLine2."Transaction Source" := ICCommentLine."Transaction Source"::Rejected;
                ICCommentLine2.Insert();
            until ICCommentLine.Next() = 0;
    end;

    procedure GetCompanyInfo()
    begin
        if not CompanyInfoFound then
            CompanyInfo.Get();
        CompanyInfoFound := true;
    end;

    procedure GetGLSetup()
    begin
        if not GLSetupFound then
            GLSetup.Get();
        GLSetupFound := true;
    end;

    procedure GetCurrency(var CurrencyCode: Code[20])
    begin
        GetGLSetup();
        if CurrencyCode = GLSetup."LCY Code" then
            CurrencyCode := '';
    end;

    procedure GetItemFromCommonItem(CommonItemNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("Common Item No.");
        Item.SetRange("Common Item No.", CommonItemNo);
        if not Item.FindFirst() then
            Error(NoItemForCommonItemErr, CommonItemNo);
        exit(Item."No.");
    end;


    procedure GetItemFromItemRef(RefNo: Code[50]; RefType: Enum "Item Reference Type"; RefTypeNo: Code[20]; ToDate: Date): Code[20]
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemVendor: Record "Item Vendor";
    begin
        if Item.Get(RefNo) then
            exit(Item."No.");

        ItemReference.SetCurrentKey("Reference No.", "Reference Type", "Reference Type No.");
        ItemReference.SetRange("Reference Type", RefType);
        ItemReference.SetRange("Reference Type No.", RefTypeNo);
        ItemReference.SetRange("Reference No.", RefNo);
        if ToDate <> 0D then begin
            ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        if ItemReference.FindFirst() then
            exit(ItemReference."Item No.");

        if RefType = "Item Reference Type"::Vendor then begin
            ItemVendor.SetCurrentKey("Vendor No.", "Vendor Item No.");
            ItemVendor.SetRange("Vendor No.", RefTypeNo);
            ItemVendor.SetRange("Vendor Item No.", RefNo);
            if ItemVendor.FindFirst() then
                exit(ItemVendor."Item No.")
        end;
        exit('');
    end;

    local procedure GetCustInvRndgAccNo(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Invoice Rounding Account");
    end;

    procedure HandleICComments(TableName: Option; NewTableName: Option; TransactionNo: Integer; ICPartner: Code[20]; TransactionSource: Option)
    var
        ICCommentLine: Record "IC Comment Line";
        TempICCommentLine: Record "IC Comment Line" temporary;
    begin
        ICCommentLine.SetRange("Table Name", TableName);
        ICCommentLine.SetRange("Transaction No.", TransactionNo);
        ICCommentLine.SetRange("IC Partner Code", ICPartner);
        if ICCommentLine.Find('-') then begin
            repeat
                TempICCommentLine := ICCommentLine;
                ICCommentLine.Delete();
                TempICCommentLine."Table Name" := NewTableName;
                TempICCommentLine."Transaction Source" := TransactionSource;
                TempICCommentLine.Insert();
            until ICCommentLine.Next() = 0;
            if TempICCommentLine.Find('-') then
                repeat
                    ICCommentLine := TempICCommentLine;
                    ICCommentLine.Insert();
                until TempICCommentLine.Next() = 0;
        end;
    end;

    procedure OutboxTransToInbox(var ICOutboxTrans: Record "IC Outbox Transaction"; var ICInboxTrans: Record "IC Inbox Transaction"; FromICPartnerCode: Code[20])
    var
        TempAllPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary;
        TempAllPartnerHandledICInboxTrans: Record "Handled IC Inbox Trans." temporary;
        ICPartnerCodeList: List of [Text];
    begin
        OutboxTransToInboxOptimized(ICOutboxTrans, ICInboxTrans, FromICPartnerCode, ICPartnerCodeList, TempAllPartnerICInboxTransaction, TempAllPartnerHandledICInboxTrans);
    end;

    procedure OutboxTransToInboxOptimized(var ICOutboxTrans: Record "IC Outbox Transaction"; var ICInboxTrans: Record "IC Inbox Transaction"; FromICPartnerCode: Code[20]; var ICPartnerCodeList: List of [Text]; var TempAllPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary; var TempAllPartnerHandledICInboxTrans: Record "Handled IC Inbox Trans." temporary)
    var
        TempPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary;
        TempPartnerHandledICInboxTrans: Record "Handled IC Inbox Trans." temporary;
        ICPartner: Record "IC Partner";
        ICSetup: Record "IC Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICDataExchange: Interface "IC Data Exchange";
    begin
        FeatureTelemetry.LogUptake('0000IJL', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKC', ICMapping.GetFeatureTelemetryName(), 'Outbox Transaction to Inbox');

        ICInboxTrans."Transaction No." := ICOutboxTrans."Transaction No.";
        ICInboxTrans."IC Partner Code" := FromICPartnerCode;
        ICInboxTrans."Transaction Source" := ICOutboxTrans."Transaction Source";
        ICInboxTrans."Document Type" := ICOutboxTrans."Document Type";
        case ICOutboxTrans."IC Source Type" of
            ICOutboxTrans."IC Source Type"::Journal:
                ICInboxTrans."IC Source Type" := ICInboxTrans."IC Source Type"::Journal;
            ICOutboxTrans."IC Source Type"::"Sales Document":
                ICInboxTrans."IC Source Type" := ICInboxTrans."IC Source Type"::"Purchase Document";
            ICOutboxTrans."IC Source Type"::"Purchase Document":
                ICInboxTrans."IC Source Type" := ICInboxTrans."IC Source Type"::"Sales Document";
        end;
        ICInboxTrans."Document No." := ICOutboxTrans."Document No.";
        ICInboxTrans."Original Document No." := ICOutboxTrans."Document No.";
        ICInboxTrans."Posting Date" := ICOutboxTrans."Posting Date";
        ICInboxTrans."Document Date" := ICOutboxTrans."Document Date";
        ICInboxTrans."Line Action" := ICInboxTrans."Line Action"::"No Action";
        ICInboxTrans."IC Account Type" := ICOutboxTrans."IC Account Type";
        ICInboxTrans."IC Account No." := ICOutboxTrans."IC Account No.";
        ICInboxTrans."Source Line No." := ICOutboxTrans."Source Line No.";

        GetCompanyInfo();
        ICSetup.Get();
        if ICSetup."IC Partner Code" = ICInboxTrans."IC Partner Code" then
            ICPartner.Get(ICOutboxTrans."IC Partner Code")
        else
            ICPartner.Get(ICInboxTrans."IC Partner Code");

        ICDataExchange := ICPartner."Data Exchange Type";
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Database then
            if not ICPartnerCodeList.Contains(ICInboxTrans."IC Partner Code") then begin
                ICDataExchange.GetICPartnerHandledICInboxTransaction(ICPartner, TempPartnerHandledICInboxTrans);
                if TempPartnerHandledICInboxTrans.FindSet() then
                    repeat
                        TempAllPartnerHandledICInboxTrans.Init();
                        TempAllPartnerHandledICInboxTrans.TransferFields(TempPartnerHandledICInboxTrans);
                        TempAllPartnerHandledICInboxTrans.Insert();
                    until TempPartnerHandledICInboxTrans.Next() = 0;

                ICDataExchange.GetICPartnerICInboxTransaction(ICPartner, TempPartnerICInboxTransaction);
                if TempPartnerICInboxTransaction.FindSet() then
                    repeat
                        TempAllPartnerICInboxTransaction.Init();
                        TempAllPartnerICInboxTransaction.TransferFields(TempPartnerICInboxTransaction);
                        TempAllPartnerICInboxTransaction.Insert();
                    until TempPartnerICInboxTransaction.Next() = 0;
                ICPartnerCodeList.Add(ICInboxTrans."IC Partner Code");
            end;

        if TempAllPartnerICInboxTransaction.Get(
             ICInboxTrans."Transaction No.", ICInboxTrans."IC Partner Code",
             ICInboxTrans."Transaction Source", ICInboxTrans."Document Type")
        then
            Error(
              Text004, ICInboxTrans."Transaction No.", ICInboxTrans.FieldCaption("IC Partner Code"),
              ICInboxTrans."IC Partner Code", TempPartnerICInboxTransaction.TableCaption());

        if TempAllPartnerHandledICInboxTrans.Get(
             ICInboxTrans."Transaction No.", ICInboxTrans."IC Partner Code",
             ICInboxTrans."Transaction Source", ICInboxTrans."Document Type")
        then
            Error(
              Text004, ICInboxTrans."Transaction No.", ICInboxTrans.FieldCaption("IC Partner Code"),
              ICInboxTrans."IC Partner Code", TempPartnerHandledICInboxTrans.TableCaption());

        OnBeforeICInboxTransInsert(ICInboxTrans, ICOutboxTrans);
        ICInboxTrans.Insert();
        OnAfterICInboxTransInsert(ICInboxTrans, ICOutboxTrans);
    end;

    procedure OutboxJnlLineToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxJnlLine: Record "IC Outbox Jnl. Line"; var ICInboxJnlLine: Record "IC Inbox Jnl. Line")
    var
        ICSetup: Record "IC Setup";
        LocalICPartner: Record "IC Partner";
        TempPartnerICPartner: Record "IC Partner" temporary;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICDataExchange: Interface "IC Data Exchange";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOutboxJnlLineToInbox(ICInboxTrans, ICOutboxJnlLine, ICInboxJnlLine, LocalICPartner, IsHandled);
        if IsHandled then
            exit;

        FeatureTelemetry.LogUptake('0000IJM', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKD', ICMapping.GetFeatureTelemetryName(), 'Outbox Journal Line to Inbox');

        GetGLSetup();
        ICSetup.Get();
        ICInboxJnlLine."Transaction No." := ICInboxTrans."Transaction No.";
        ICInboxJnlLine."IC Partner Code" := ICInboxTrans."IC Partner Code";
        ICInboxJnlLine."Transaction Source" := ICInboxTrans."Transaction Source";
        ICInboxJnlLine."Line No." := ICOutboxJnlLine."Line No.";

        if ICOutboxJnlLine."IC Partner Code" = ICSetup."IC Partner Code" then begin
            LocalICPartner.Get(ICInboxTrans."IC Partner Code");
            TempPartnerICPartner := LocalICPartner;
        end
        else begin
            LocalICPartner.Get(ICOutboxJnlLine."IC Partner Code");
            LocalICPartner.TestField("Inbox Type", LocalICPartner."Inbox Type"::Database);
            ICDataExchange := LocalICPartner."Data Exchange Type";
            ICDataExchange.GetICPartnerFromICPartner(LocalICPartner, ICInboxJnlLine."IC Partner Code", TempPartnerICPartner);
        end;

        case ICOutboxJnlLine."Account Type" of
            ICOutboxJnlLine."Account Type"::"G/L Account":
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::"G/L Account";
                    ICInboxJnlLine."Account No." := ICOutboxJnlLine."Account No.";
                end;
            ICOutboxJnlLine."Account Type"::Vendor:
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::Customer;
                    TempPartnerICPartner.TestField("Customer No.");
                    ICInboxJnlLine."Account No." := TempPartnerICPartner."Customer No.";
                end;
            ICOutboxJnlLine."Account Type"::Customer:
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::Vendor;
                    TempPartnerICPartner.TestField("Vendor No.");
                    ICInboxJnlLine."Account No." := TempPartnerICPartner."Vendor No.";
                end;
            ICOutboxJnlLine."Account Type"::"IC Partner":
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::"IC Partner";
                    ICInboxJnlLine."Account No." := ICInboxJnlLine."IC Partner Code";
                end;
            ICOutboxJnlLine."Account Type"::"Bank Account":
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::"Bank Account";
                    ICInboxJnlLine."Account No." := ICOutboxJnlLine."Account No.";
                end;
        end;
        ICInboxJnlLine.Amount := -ICOutboxJnlLine.Amount;
        ICInboxJnlLine.Description := ICOutboxJnlLine.Description;
        ICInboxJnlLine."VAT Amount" := -ICOutboxJnlLine."VAT Amount";
        if ICOutboxJnlLine."Currency Code" = GLSetup."LCY Code" then
            ICInboxJnlLine."Currency Code" := ''
        else
            ICInboxJnlLine."Currency Code" := ICOutboxJnlLine."Currency Code";
        ICInboxJnlLine."Due Date" := ICOutboxJnlLine."Due Date";
        ICInboxJnlLine."Payment Discount %" := ICOutboxJnlLine."Payment Discount %";
        ICInboxJnlLine."Payment Discount Date" := ICOutboxJnlLine."Payment Discount Date";
        ICInboxJnlLine.Quantity := -ICOutboxJnlLine.Quantity;
        ICInboxJnlLine."Document No." := ICOutboxJnlLine."Document No.";
        OnOutboxJnlLineToInboxOnBeforeICInboxJnlLineInsert(ICInboxJnlLine, ICOutboxJnlLine);
        ICInboxJnlLine.Insert();
    end;

    procedure OutboxSalesHdrToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICInboxPurchHeader: Record "IC Inbox Purchase Header")
    var
        ICSetup: Record "IC Setup";
        LocalICPartner: Record "IC Partner";
        TempPartnerICPartner: Record "IC Partner" temporary;
        Vendor: Record Vendor;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICDataExchange: Interface "IC Data Exchange";
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJN', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKE', ICMapping.GetFeatureTelemetryName(), 'Outbox Sales Header to Inbox');

        IsHandled := false;
        OnBeforeOutboxSalesHdrToInbox(ICInboxTrans, ICOutboxSalesHeader, ICInboxPurchHeader, LocalICPartner, IsHandled);
        if IsHandled then
            exit;

        ICSetup.Get();
        if ICOutboxSalesHeader."IC Partner Code" = ICSetup."IC Partner Code" then begin
            LocalICPartner.Get(ICInboxTrans."IC Partner Code");
            TempPartnerICPartner := LocalICPartner;
        end
        else begin
            LocalICPartner.Get(ICOutboxSalesHeader."IC Partner Code");
            LocalICPartner.TestField("Inbox Type", LocalICPartner."Inbox Type"::Database);
            LocalICPartner.TestField("Inbox Details");
            ICDataExchange := LocalICPartner."Data Exchange Type";
            ICDataExchange.GetICPartnerFromICPartner(LocalICPartner, ICInboxTrans."IC Partner Code", TempPartnerICPartner);
        end;
        if TempPartnerICPartner."Vendor No." = '' then
            Error(Text001, TempPartnerICPartner.TableCaption(), TempPartnerICPartner.Code, Vendor.TableCaption(), ICOutboxSalesHeader."IC Partner Code");

        ICInboxPurchHeader."IC Transaction No." := ICInboxTrans."Transaction No.";
        ICInboxPurchHeader."IC Partner Code" := ICInboxTrans."IC Partner Code";
        ICInboxPurchHeader."Transaction Source" := ICInboxTrans."Transaction Source";
        ICInboxPurchHeader."Document Type" := ICOutboxSalesHeader."Document Type";
        ICInboxPurchHeader."No." := ICOutboxSalesHeader."No.";
        ICInboxPurchHeader."Ship-to Name" := ICOutboxSalesHeader."Ship-to Name";
        ICInboxPurchHeader."Ship-to Address" := ICOutboxSalesHeader."Ship-to Address";
        ICInboxPurchHeader."Ship-to Address 2" := ICOutboxSalesHeader."Ship-to Address 2";
        ICInboxPurchHeader."Ship-to City" := ICOutboxSalesHeader."Ship-to City";
        ICInboxPurchHeader."Ship-to Post Code" := ICOutboxSalesHeader."Ship-to Post Code";
        ICInboxPurchHeader."Ship-to County" := ICOutboxSalesHeader."Ship-to County";
        ICInboxPurchHeader."Ship-to Country/Region Code" := ICOutboxSalesHeader."Ship-to Country/Region Code";
        ICInboxPurchHeader."Ship-to Phone No." := ICOutboxSalesHeader."Ship-to Phone No.";
        ICInboxPurchHeader."Posting Date" := ICOutboxSalesHeader."Posting Date";
        ICInboxPurchHeader."Due Date" := ICOutboxSalesHeader."Due Date";
        ICInboxPurchHeader."Payment Discount %" := ICOutboxSalesHeader."Payment Discount %";
        ICInboxPurchHeader."Pmt. Discount Date" := ICOutboxSalesHeader."Pmt. Discount Date";
        ICInboxPurchHeader."Currency Code" := ICOutboxSalesHeader."Currency Code";
        ICInboxPurchHeader."Document Date" := ICOutboxSalesHeader."Document Date";
        ICInboxPurchHeader."Buy-from Vendor No." := TempPartnerICPartner."Vendor No.";
        ICInboxPurchHeader."Pay-to Vendor No." := TempPartnerICPartner."Vendor No.";
        ICInboxPurchHeader."Vendor Invoice No." := ICOutboxSalesHeader."No.";
        ICInboxPurchHeader."Vendor Order No." := ICOutboxSalesHeader."Order No.";
        ICInboxPurchHeader."Vendor Cr. Memo No." := ICOutboxSalesHeader."No.";
        ICInboxPurchHeader."Your Reference" := ICOutboxSalesHeader."External Document No.";
        ICInboxPurchHeader."Sell-to Customer No." := ICOutboxSalesHeader."Sell-to Customer No.";
        ICInboxPurchHeader."Expected Receipt Date" := ICOutboxSalesHeader."Requested Delivery Date";
        ICInboxPurchHeader."Requested Receipt Date" := ICOutboxSalesHeader."Requested Delivery Date";
        ICInboxPurchHeader."Promised Receipt Date" := ICOutboxSalesHeader."Promised Delivery Date";
        ICInboxPurchHeader."Prices Including VAT" := ICOutboxSalesHeader."Prices Including VAT";
        OnBeforeICInboxPurchHeaderInsert(ICInboxPurchHeader, ICOutboxSalesHeader);
        ICInboxPurchHeader.Insert();
        OnAfterICInboxPurchHeaderInsert(ICInboxPurchHeader, ICOutboxSalesHeader);
    end;

    procedure OutboxSalesLineToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxSalesLine: Record "IC Outbox Sales Line"; var ICInboxPurchLine: Record "IC Inbox Purchase Line")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJO', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKF', ICMapping.GetFeatureTelemetryName(), 'Outbox Sales Line to Inbox');

        ICInboxPurchLine."IC Transaction No." := ICInboxTrans."Transaction No.";
        ICInboxPurchLine."IC Partner Code" := ICInboxTrans."IC Partner Code";
        ICInboxPurchLine."Transaction Source" := ICInboxTrans."Transaction Source";
        ICInboxPurchLine."Line No." := ICOutboxSalesLine."Line No.";
        ICInboxPurchLine."Document Type" := ICOutboxSalesLine."Document Type";
        ICInboxPurchLine."Document No." := ICOutboxSalesLine."Document No.";
        ICInboxPurchLine."IC Partner Ref. Type" := ICOutboxSalesLine."IC Partner Ref. Type";
        ICInboxPurchLine."IC Partner Reference" := ICOutboxSalesLine."IC Partner Reference";
        ICInboxPurchLine."IC Item Reference No." := ICOutboxSalesLine."IC Item Reference No.";
        ICInboxPurchLine.Description := ICOutboxSalesLine.Description;
        ICInboxPurchLine."Description 2" := ICOutboxSalesLine."Description 2";
        ICInboxPurchLine.Quantity := ICOutboxSalesLine.Quantity;
        ICInboxPurchLine."Direct Unit Cost" := ICOutboxSalesLine."Unit Price";
        ICInboxPurchLine."Line Discount Amount" := ICOutboxSalesLine."Line Discount Amount";
        ICInboxPurchLine."Amount Including VAT" := ICOutboxSalesLine."Amount Including VAT";
        ICInboxPurchLine."Job No." := ICOutboxSalesLine."Job No.";
        ICInboxPurchLine."VAT Base Amount" := ICOutboxSalesLine."VAT Base Amount";
        ICInboxPurchLine."VAT Difference" := ICOutboxSalesLine."VAT Difference";
        ICInboxPurchLine."Unit Cost" := ICOutboxSalesLine."Unit Price";
        ICInboxPurchLine."Line Amount" := ICOutboxSalesLine."Line Amount";
        ICInboxPurchLine.Amount := ICOutboxSalesLine.Amount;
        ICInboxPurchLine."Inv. Discount Amount" := ICOutboxSalesLine."Inv. Discount Amount";
        ICInboxPurchLine."Line Discount %" := ICOutboxSalesLine."Line Discount %";
        ICInboxPurchLine."Unit of Measure Code" := ICOutboxSalesLine."Unit of Measure Code";
        ICInboxPurchLine."Requested Receipt Date" := ICOutboxSalesLine."Requested Delivery Date";
        ICInboxPurchLine."Promised Receipt Date" := ICOutboxSalesLine."Promised Delivery Date";
        ICInboxPurchLine."Receipt No." := ICOutboxSalesLine."Shipment No.";
        ICInboxPurchLine."Receipt Line No." := ICOutboxSalesLine."Shipment Line No.";
        ICInboxPurchLine."Return Shipment No." := ICOutboxSalesLine."Return Receipt No.";
        ICInboxPurchLine."Return Shipment Line No." := ICOutboxSalesLine."Return Receipt Line No.";
        OnBeforeICInboxPurchLineInsert(ICInboxPurchLine, ICOutboxSalesLine);
        ICInboxPurchLine.Insert();
        OnAfterICInboxPurchLineInsert(ICInboxPurchLine, ICOutboxSalesLine);
    end;

    procedure OutboxICCommentLineToInbox(var ICInboxTransaction: Record "IC Inbox Transaction" temporary; OutgoingICCommentLine: Record "IC Comment Line"; var NewICCommentLine: Record "IC Comment Line" temporary)
    begin
        NewICCommentLine.TransferFields(OutgoingICCommentLine, true);
        NewICCommentLine."IC Partner Code" := ICInboxTransaction."IC Partner Code";
        NewICCommentLine."Table Name" := NewICCommentLine."Table Name"::"IC Inbox Transaction";
        NewICCommentLine.Insert();
    end;

    procedure OutboxPurchHdrToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxPurchHeader: Record "IC Outbox Purchase Header"; var ICInboxSalesHeader: Record "IC Inbox Sales Header")
    var
        ICSetup: Record "IC Setup";
        LocalICPartner: Record "IC Partner";
        TempPartnerICPartner: Record "IC Partner" temporary;
        Customer: Record Customer;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICDataExchange: Interface "IC Data Exchange";
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000IJP', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKG', ICMapping.GetFeatureTelemetryName(), 'Outbox Purchase Header to Inbox');
        ICSetup.Get();
        IsHandled := false;
        OnBeforeOutboxPurchHdrToInboxProcedure(ICInboxTrans, ICOutboxPurchHeader, ICInboxSalesHeader, ICSetup, IsHandled, LocalICPartner, TempPartnerICPartner);
        if not IsHandled then
            if ICOutboxPurchHeader."IC Partner Code" = ICSetup."IC Partner Code" then begin
                LocalICPartner.Get(ICInboxTrans."IC Partner Code");
                TempPartnerICPartner := LocalICPartner;
            end
            else begin
                LocalICPartner.Get(ICOutboxPurchHeader."IC Partner Code");
                LocalICPartner.TestField("Inbox Type", LocalICPartner."Inbox Type"::Database);
                LocalICPartner.TestField("Inbox Details");
                ICDataExchange := LocalICPartner."Data Exchange Type";
                ICDataExchange.GetICPartnerFromICPartner(LocalICPartner, ICInboxTrans."IC Partner Code", TempPartnerICPartner);
            end;
        if TempPartnerICPartner."Customer No." = '' then
            Error(Text001, TempPartnerICPartner.TableCaption(), TempPartnerICPartner.Code, Customer.TableCaption(), ICOutboxPurchHeader."IC Partner Code");

        ICInboxSalesHeader."IC Transaction No." := ICInboxTrans."Transaction No.";
        ICInboxSalesHeader."IC Partner Code" := ICInboxTrans."IC Partner Code";
        ICInboxSalesHeader."Transaction Source" := ICInboxTrans."Transaction Source";
        ICInboxSalesHeader."Document Type" := ICOutboxPurchHeader."Document Type";
        ICInboxSalesHeader."No." := ICOutboxPurchHeader."No.";
        ICInboxSalesHeader."Ship-to Name" := ICOutboxPurchHeader."Ship-to Name";
        ICInboxSalesHeader."Ship-to Address" := ICOutboxPurchHeader."Ship-to Address";
        ICInboxSalesHeader."Ship-to Address 2" := ICOutboxPurchHeader."Ship-to Address 2";
        ICInboxSalesHeader."Ship-to City" := ICOutboxPurchHeader."Ship-to City";
        ICInboxSalesHeader."Ship-to Post Code" := ICOutboxPurchHeader."Ship-to Post Code";
        ICInboxSalesHeader."Ship-to County" := ICOutboxPurchHeader."Ship-to County";
        ICInboxSalesHeader."Ship-to Country/Region Code" := ICOutboxPurchHeader."Ship-to Country/Region Code";
        ICInboxSalesHeader."Ship-to Phone No." := ICOutboxPurchHeader."Ship-to Phone No.";
        ICInboxSalesHeader."Posting Date" := ICOutboxPurchHeader."Posting Date";
        ICInboxSalesHeader."Due Date" := ICOutboxPurchHeader."Due Date";
        ICInboxSalesHeader."Payment Discount %" := ICOutboxPurchHeader."Payment Discount %";
        ICInboxSalesHeader."Pmt. Discount Date" := ICOutboxPurchHeader."Pmt. Discount Date";
        ICInboxSalesHeader."Currency Code" := ICOutboxPurchHeader."Currency Code";
        ICInboxSalesHeader."Document Date" := ICOutboxPurchHeader."Document Date";
        ICInboxSalesHeader."Sell-to Customer No." := TempPartnerICPartner."Customer No.";
        ICInboxSalesHeader."Bill-to Customer No." := TempPartnerICPartner."Customer No.";
        ICInboxSalesHeader."Prices Including VAT" := ICOutboxPurchHeader."Prices Including VAT";
        ICInboxSalesHeader."Requested Delivery Date" := ICOutboxPurchHeader."Requested Receipt Date";
        ICInboxSalesHeader."Promised Delivery Date" := ICOutboxPurchHeader."Promised Receipt Date";
        OnBeforeICInboxSalesHeaderInsert(ICInboxSalesHeader, ICOutboxPurchHeader);
        ICInboxSalesHeader.Insert();
        OnAfterICInboxSalesHeaderInsert(ICInboxSalesHeader, ICOutboxPurchHeader);
    end;

    procedure OutboxPurchLineToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxPurchLine: Record "IC Outbox Purchase Line"; var ICInboxSalesLine: Record "IC Inbox Sales Line")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJQ', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKH', ICMapping.GetFeatureTelemetryName(), 'Outbox Purchase Line to Inbox');

        ICInboxSalesLine."IC Transaction No." := ICInboxTrans."Transaction No.";
        ICInboxSalesLine."IC Partner Code" := ICInboxTrans."IC Partner Code";
        ICInboxSalesLine."Transaction Source" := ICInboxTrans."Transaction Source";
        ICInboxSalesLine."Line No." := ICOutboxPurchLine."Line No.";
        ICInboxSalesLine."Document Type" := ICOutboxPurchLine."Document Type";
        ICInboxSalesLine."Document No." := ICOutboxPurchLine."Document No.";
        if ICOutboxPurchLine."IC Partner Ref. Type" = ICOutboxPurchLine."IC Partner Ref. Type"::"Vendor Item No." then
            ICInboxSalesLine."IC Partner Ref. Type" := ICInboxSalesLine."IC Partner Ref. Type"::Item
        else
            ICInboxSalesLine."IC Partner Ref. Type" := ICOutboxPurchLine."IC Partner Ref. Type";
        ICInboxSalesLine."IC Partner Reference" := ICOutboxPurchLine."IC Partner Reference";
        ICInboxSalesLine."IC Item Reference No." := ICOutboxPurchLine."IC Item Reference No.";
        ICInboxSalesLine.Description := ICOutboxPurchLine.Description;
        ICInboxSalesLine."Description 2" := ICOutboxPurchLine."Description 2";
        ICInboxSalesLine.Quantity := ICOutboxPurchLine.Quantity;
        ICInboxSalesLine."Line Discount Amount" := ICOutboxPurchLine."Line Discount Amount";
        ICInboxSalesLine."Amount Including VAT" := ICOutboxPurchLine."Amount Including VAT";
        ICInboxSalesLine.Amount := ICOutboxPurchLine.Amount;
        ICInboxSalesLine."Inv. Discount Amount" := ICOutboxPurchLine."Inv. Discount Amount";
        ICInboxSalesLine."Job No." := ICOutboxPurchLine."Job No.";
        ICInboxSalesLine."VAT Base Amount" := ICOutboxPurchLine."VAT Base Amount";
        ICInboxSalesLine."VAT Difference" := ICOutboxPurchLine."VAT Difference";
        ICInboxSalesLine."Unit Price" := ICOutboxPurchLine."Direct Unit Cost";
        ICInboxSalesLine."Line Amount" := ICOutboxPurchLine."Line Amount";
        ICInboxSalesLine."Line Discount %" := ICOutboxPurchLine."Line Discount %";
        ICInboxSalesLine."Unit of Measure Code" := ICOutboxPurchLine."Unit of Measure Code";
        ICInboxSalesLine."Requested Delivery Date" := ICOutboxPurchLine."Requested Receipt Date";
        ICInboxSalesLine."Promised Delivery Date" := ICOutboxPurchLine."Promised Receipt Date";
        OnBeforeICInboxSalesLineInsert(ICInboxSalesLine, ICOutboxPurchLine);
        ICInboxSalesLine.Insert();
        OnAfterICInboxSalesLineInsert(ICInboxSalesLine, ICOutboxPurchLine);
    end;

    /// <summary>
    /// Transfers ic outbox transaction dimensions to ic inbox transaction dimensions.
    /// </summary>
    /// <param name="ICInboxJnlLine">Ic transaction that is being processed. </param>
    /// <param name="ICOutboxJnlLineDim">Source ic outbox journal line. </param>
    /// <param name="ICInboxJnlLineDim">Destination ic inbox journal line. </param>
    /// <param name="ICInboxTableID">Number of record table. </param>
    procedure OutboxJnlLineDimToInbox(var ICInboxJnlLine: Record "IC Inbox Jnl. Line"; var ICOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."; var ICInboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."; ICInboxTableID: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJR', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKI', ICMapping.GetFeatureTelemetryName(), 'Outbox Journal Line Dimensions to Inbox');

        ICInboxJnlLineDim := ICOutboxJnlLineDim;
        ICInboxJnlLineDim."Table ID" := ICInboxTableID;
        ICInboxJnlLineDim."IC Partner Code" := ICInboxJnlLine."IC Partner Code";
        ICInboxJnlLineDim."Transaction Source" := ICInboxJnlLine."Transaction Source";
        ICInboxJnlLineDim.Insert();
    end;

    /// <summary>
    /// Transfers ic outbox document dimensions to ic inbox document dimensions.
    /// </summary>
    /// <param name="ICOutboxDocDim">Source ic outbox document dimensions. </param>
    /// <param name="ICInboxDocDim">Destination ic inbox document dimensions. </param>
    /// <param name="InboxTableID">Destination table number. </param>
    /// <param name="InboxICPartnerCode">Ic partner code. </param>
    /// <param name="InboxTransSource">Source of transaction 'Rejected by Current Company' or 'Created by Current Company'. </param>
    procedure OutboxDocDimToInbox(var ICOutboxDocDim: Record "IC Document Dimension"; var ICInboxDocDim: Record "IC Document Dimension"; InboxTableID: Integer; InboxICPartnerCode: Code[20]; InboxTransSource: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJS', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKJ', ICMapping.GetFeatureTelemetryName(), 'Outbox Document Dimensions to Inbox');

        ICInboxDocDim := ICOutboxDocDim;
        ICInboxDocDim."Table ID" := InboxTableID;
        ICInboxDocDim."IC Partner Code" := InboxICPartnerCode;
        ICInboxDocDim."Transaction Source" := InboxTransSource;
        ICInboxDocDim.Insert();
    end;

    /// <summary>
    /// Moves ic journal line dimensions to handled ic journal dimensions.
    /// </summary>
    /// <param name="TableID">Source table number. </param>
    /// <param name="NewTableID">Destination table number. </param>
    /// <param name="TransactionNo">Number of transaction that is being processed. </param>
    /// <param name="ICPartner">Ic partner code. </param>
    /// <param name="LineNoFilter">If 'true' parameter LineNo will be used.</param>
    /// <param name="LineNo">Line number of processed dimension.</param>
    procedure MoveICJnlDimToHandled(TableID: Integer; NewTableID: Integer; TransactionNo: Integer; ICPartner: Code[20]; LineNoFilter: Boolean; LineNo: Integer)
    var
        InOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        TempInOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJT', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKK', ICMapping.GetFeatureTelemetryName(), 'Move IC Journal Dimension');

        InOutboxJnlLineDim.SetRange("Table ID", TableID);
        InOutboxJnlLineDim.SetRange("Transaction No.", TransactionNo);
        InOutboxJnlLineDim.SetRange("IC Partner Code", ICPartner);
        if LineNoFilter then
            InOutboxJnlLineDim.SetRange("Line No.", LineNo);
        if InOutboxJnlLineDim.Find('-') then begin
            repeat
                TempInOutboxJnlLineDim := InOutboxJnlLineDim;
                InOutboxJnlLineDim.Delete();
                TempInOutboxJnlLineDim."Table ID" := NewTableID;
                TempInOutboxJnlLineDim.Insert();
            until InOutboxJnlLineDim.Next() = 0;
            if TempInOutboxJnlLineDim.Find('-') then
                repeat
                    InOutboxJnlLineDim := TempInOutboxJnlLineDim;
                    InOutboxJnlLineDim.Insert();
                until TempInOutboxJnlLineDim.Next() = 0;
        end;
    end;

    local procedure MoveICDocDimToHandled(FromTableID: Integer; ToTableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer)
    var
        ICDocDim: Record "IC Document Dimension";
        HandledICDocDim: Record "IC Document Dimension";
    begin
        ICDocDim.SetRange("Table ID", FromTableID);
        ICDocDim.SetRange("Transaction No.", TransactionNo);
        ICDocDim.SetRange("IC Partner Code", PartnerCode);
        ICDocDim.SetRange("Transaction Source", TransactionSource);
        ICDocDim.SetRange("Line No.", LineNo);
        if ICDocDim.Find('-') then
            repeat
                HandledICDocDim.TransferFields(ICDocDim, true);
                HandledICDocDim."Table ID" := ToTableID;
                HandledICDocDim.Insert();
                ICDocDim.Delete();
            until ICDocDim.Next() = 0;
    end;

    /// <summary>
    /// Moves ic outbox documents to handled ic outbox documents.
    /// </summary>
    /// <param name="ICOutboxTrans">Ic outbox transaction that is being processed. </param>
    procedure MoveOutboxTransToHandledOutbox(var ICOutboxTrans: Record "IC Outbox Transaction")
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        HandledICOutboxJnlLine: Record "Handled IC Outbox Jnl. Line";
        ICOutboxSalesHdr: Record "IC Outbox Sales Header";
        HandledICOutboxSalesHdr: Record "Handled IC Outbox Sales Header";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line";
        ICOutboxPurchHdr: Record "IC Outbox Purchase Header";
        HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        ICOutboxPurchLine: Record "IC Outbox Purchase Line";
        HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
        ICInOutJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        HandledICInOutJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        ICCommentLine: Record "IC Comment Line";
        HandledICCommentLine: Record "IC Comment Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJU', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IKL', ICMapping.GetFeatureTelemetryName(), 'Move Outbox Transaction to Handled Outbox');

        ICOutboxJnlLine.SetRange("Transaction No.", ICOutboxTrans."Transaction No.");
        if ICOutboxJnlLine.Find('-') then
            repeat
                HandledICOutboxJnlLine.TransferFields(ICOutboxJnlLine, true);
                HandledICOutboxJnlLine.Insert();
                ICInOutJnlLineDim.SetRange("Table ID", DATABASE::"IC Outbox Jnl. Line");
                ICInOutJnlLineDim.SetRange("Transaction No.", ICOutboxJnlLine."Transaction No.");
                ICInOutJnlLineDim.SetRange("IC Partner Code", ICOutboxJnlLine."IC Partner Code");
                ICInOutJnlLineDim.SetRange("Transaction Source", ICOutboxJnlLine."Transaction Source");
                ICInOutJnlLineDim.SetRange("Line No.", ICOutboxJnlLine."Line No.");
                if ICInOutJnlLineDim.Find('-') then
                    repeat
                        HandledICInOutJnlLineDim := ICInOutJnlLineDim;
                        HandledICInOutJnlLineDim."Table ID" := DATABASE::"Handled IC Outbox Jnl. Line";
                        HandledICInOutJnlLineDim.Insert();
                        ICInOutJnlLineDim.Delete();
                    until ICInOutJnlLineDim.Next() = 0;
                ICOutboxJnlLine.Delete();
            until ICOutboxJnlLine.Next() = 0;

        ICOutboxSalesHdr.SetRange("IC Transaction No.", ICOutboxTrans."Transaction No.");
        if ICOutboxSalesHdr.Find('-') then
            repeat
                HandledICOutboxSalesHdr.Init();
                HandledICOutboxSalesHdr.TransferFields(ICOutboxSalesHdr, true);
                HandledICOutboxSalesHdr.Insert();
                OnAfterHandledICOutboxSalesHdrInsert(HandledICOutboxSalesHdr, ICOutboxSalesHdr);
                MoveICDocDimToHandled(
                  DATABASE::"IC Outbox Sales Header", DATABASE::"Handled IC Outbox Sales Header", ICOutboxSalesHdr."IC Transaction No.",
                  ICOutboxSalesHdr."IC Partner Code", ICOutboxSalesHdr."Transaction Source", 0);

                ICOutboxSalesLine.SetRange("IC Transaction No.", ICOutboxSalesHdr."IC Transaction No.");
                ICOutboxSalesLine.SetRange("IC Partner Code", ICOutboxSalesHdr."IC Partner Code");
                ICOutboxSalesLine.SetRange("Transaction Source", ICOutboxSalesHdr."Transaction Source");
                if ICOutboxSalesLine.Find('-') then
                    repeat
                        HandledICOutboxSalesLine.TransferFields(ICOutboxSalesLine, true);
                        OnBeforeHandledICOutboxSalesLineInsert(HandledICOutboxSalesLine, ICOutboxSalesLine);
                        HandledICOutboxSalesLine.Insert();

                        MoveICDocDimToHandled(
                            DATABASE::"IC Outbox Sales Line", DATABASE::"Handled IC Outbox Sales Line", ICOutboxSalesHdr."IC Transaction No.",
                            ICOutboxSalesHdr."IC Partner Code", ICOutboxSalesHdr."Transaction Source", ICOutboxSalesLine."Line No.");
                        OnMoveOutboxTransToHandledOutboxOnBeforeICOutboxSalesLineDelete(ICOutboxSalesLine, HandledICOutboxSalesLine);
                        ICOutboxSalesLine.Delete();
                    until ICOutboxSalesLine.Next() = 0;
                ICOutboxSalesHdr.Delete();
            until ICOutboxSalesHdr.Next() = 0;

        ICOutboxPurchHdr.SetRange("IC Transaction No.", ICOutboxTrans."Transaction No.");
        if ICOutboxPurchHdr.Find('-') then
            repeat
                HandledICOutboxPurchHdr.Init();
                HandledICOutboxPurchHdr.TransferFields(ICOutboxPurchHdr, true);
                HandledICOutboxPurchHdr.Insert();
                OnAfterHandledICOutboxPurchHdrInsert(HandledICOutboxPurchHdr, ICOutboxPurchHdr);

                MoveICDocDimToHandled(
                  DATABASE::"IC Outbox Purchase Header", DATABASE::"Handled IC Outbox Purch. Hdr", ICOutboxPurchHdr."IC Transaction No.",
                  ICOutboxPurchHdr."IC Partner Code", ICOutboxPurchHdr."Transaction Source", 0);

                ICOutboxPurchLine.SetRange("IC Transaction No.", ICOutboxPurchHdr."IC Transaction No.");
                ICOutboxPurchLine.SetRange("IC Partner Code", ICOutboxPurchHdr."IC Partner Code");
                ICOutboxPurchLine.SetRange("Transaction Source", ICOutboxPurchHdr."Transaction Source");
                if ICOutboxPurchLine.Find('-') then
                    repeat
                        HandledICOutboxPurchLine.TransferFields(ICOutboxPurchLine, true);
                        OnBeforeHandledICOutboxPurchLineInsert(HandledICOutboxPurchLine, ICOutboxPurchLine);
                        HandledICOutboxPurchLine.Insert();

                        MoveICDocDimToHandled(
                          DATABASE::"IC Outbox Purchase Line", DATABASE::"Handled IC Outbox Purch. Line", ICOutboxPurchHdr."IC Transaction No.",
                          ICOutboxPurchHdr."IC Partner Code", ICOutboxPurchHdr."Transaction Source", ICOutboxPurchLine."Line No.");
                        OnMoveOutboxTransToHandledOutboxOnBeforeICOutboxPurchLineDelete(ICOutboxPurchLine, HandledICOutboxPurchLine);
                        ICOutboxPurchLine.Delete();
                    until ICOutboxPurchLine.Next() = 0;
                ICOutboxPurchHdr.Delete();
            until ICOutboxPurchHdr.Next() = 0;

        OnMoveOutboxTransToHandledOutboxOnBeforeHandledICOutboxTransTransferFields(HandledICOutboxTrans, ICOutboxTrans);
        HandledICOutboxTrans.TransferFields(ICOutboxTrans, true);
        HandledICOutboxTrans."IC Source Type" := ICOutboxTrans."IC Source Type";
        OnMoveOutboxTransToHandledOutboxOnAfterHandledICOutboxTransTransferFields(HandledICOutboxTrans, ICOutboxTrans);

        case ICOutboxTrans."Line Action" of
            ICOutboxTrans."Line Action"::"Send to IC Partner":
                if ICOutboxTrans."Transaction Source" = ICOutboxTrans."Transaction Source"::"Created by Current Company" then
                    HandledICOutboxTrans.Status := HandledICOutboxTrans.Status::"Sent to IC Partner"
                else
                    HandledICOutboxTrans.Status := HandledICOutboxTrans.Status::"Rejection Sent to IC Partner";
            ICOutboxTrans."Line Action"::Cancel:
                HandledICOutboxTrans.Status := HandledICOutboxTrans.Status::Cancelled;
        end;
        HandledICOutboxTrans.Insert();
        ICOutboxTrans.Delete();

        ICCommentLine.SetRange("Table Name", ICCommentLine."Table Name"::"IC Outbox Transaction");
        ICCommentLine.SetRange("Transaction No.", ICOutboxTrans."Transaction No.");
        ICCommentLine.SetRange("IC Partner Code", ICOutboxTrans."IC Partner Code");
        ICCommentLine.SetRange("Transaction Source", ICOutboxTrans."Transaction Source");
        if ICCommentLine.Find('-') then
            repeat
                HandledICCommentLine := ICCommentLine;
                HandledICCommentLine."Table Name" := HandledICCommentLine."Table Name"::"Handled IC Outbox Transaction";
                HandledICCommentLine.Insert();
                ICCommentLine.Delete();
            until ICCommentLine.Next() = 0;
    end;

    /// <summary>
    /// Creates ic document dimensions with provided 'DimSetID'.
    /// </summary>
    /// <param name="ICDocDim">Ic Document dimensions that are created. </param>
    /// <param name="DimSetID">Dimension set id of a given document. </param>
    /// <param name="TableNo">Table number of document in process. </param>
    procedure CreateICDocDimFromPostedDocDim(ICDocDim: Record "IC Document Dimension"; DimSetID: Integer; TableNo: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        DimSetEntry.Reset();
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet() then
            repeat
                ICDocDim."Table ID" := TableNo;
                ICDocDim."Dimension Code" := DimMgt.ConvertDimtoICDim(DimSetEntry."Dimension Code");
                ICDocDim."Dimension Value Code" :=
                  DimMgt.ConvertDimValuetoICDimVal(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                if (ICDocDim."Dimension Code" <> '') and (ICDocDim."Dimension Value Code" <> '') then
                    ICDocDim.Insert();
            until DimSetEntry.Next() = 0;
    end;

    /// <summary>
    /// Retrieves purchase receipt lines for purchase lines that have been received and not invoiced.
    /// </summary>
    /// <param name="PurchRcptLine">Retrieved purchase receipt lines. </param>
    /// <param name="PurchaseLineSource">Source purchase line. </param>
    /// <returns>Returns 'true' if found, otherwise 'false'. </returns>
    procedure FindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLineSource: Record "Purchase Line") Found: Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReceiptLine(PurchRcptLine, PurchaseLineSource, Found, IsHandled);
        if IsHandled then
            exit(Found);

        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLineSource."Receipt No.") then
            exit(false);

        PurchRcptLine.SetCurrentKey("Qty. Rcd. Not Invoiced");
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineSource."Receipt Line No.");
        PurchRcptLine.SetRange(Type, PurchaseLineSource.Type);
        PurchRcptLine.SetRange("No.", PurchaseLineSource."No.");
        PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>%1', 0);
        if PurchRcptLine.FindSet() then
            repeat
                PurchaseLine.SetCurrentKey("Document Type", "Receipt No.");
                PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
                PurchaseLine.SetRange("Receipt No.", PurchRcptLine."Document No.");
                PurchaseLine.SetRange("Receipt Line No.", PurchRcptLine."Line No.");
                PurchaseLine.SetRange(Type, PurchaseLineSource.Type);
                PurchaseLine.SetRange("No.", PurchaseLineSource."No.");
                PurchaseLine.CalcSums(Quantity);
                if Abs(PurchRcptLine."Qty. Rcd. Not Invoiced" - PurchaseLine.Quantity) >= Abs(PurchaseLineSource.Quantity) then
                    exit(true);
            until PurchRcptLine.Next() = 0;
        exit(false);
    end;

    procedure FindShipmentLine(var ReturnShptLine: Record "Return Shipment Line"; PurchaseLineSource: Record "Purchase Line"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", PurchaseLineSource."Return Shipment No.") then
            exit(false);

        ReturnShptLine.SetCurrentKey("Return Qty. Shipped Not Invd.");
        ReturnShptLine.SetRange("Return Order No.", PurchaseHeader."No.");
        ReturnShptLine.SetRange("Return Order Line No.", PurchaseLineSource."Return Shipment Line No.");
        ReturnShptLine.SetRange(Type, PurchaseLineSource.Type);
        ReturnShptLine.SetRange("No.", PurchaseLineSource."No.");
        ReturnShptLine.SetFilter("Return Qty. Shipped Not Invd.", '<>%1', 0);
        if ReturnShptLine.FindSet() then
            repeat
                PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
                PurchaseLine.SetRange("Return Shipment No.", ReturnShptLine."Document No.");
                PurchaseLine.SetRange("Return Shipment Line No.", ReturnShptLine."Line No.");
                PurchaseLine.SetRange(Type, PurchaseLineSource.Type);
                PurchaseLine.SetRange("No.", PurchaseLineSource."No.");
                PurchaseLine.CalcSums(Quantity);
                if Abs(ReturnShptLine."Return Qty. Shipped Not Invd." - PurchaseLine.Quantity) >= Abs(PurchaseLineSource.Quantity) then
                    exit(true);
            until ReturnShptLine.Next() = 0;
        exit(false);
    end;

    local procedure FindRoundingSalesInvLine(DocumentNo: Code[20]): Integer
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        if SalesInvoiceLine.FindLast() then
            if SalesInvoiceLine.Type = SalesInvoiceLine.Type::"G/L Account" then
                if SalesInvoiceLine."No." <> '' then
                    if SalesInvoiceLine."No." = GetCustInvRndgAccNo(SalesInvoiceLine."Bill-to Customer No.") then
                        exit(SalesInvoiceLine."Line No.");
        exit(0);
    end;

    local procedure FindRoundingSalesCrMemoLine(DocumentNo: Code[20]): Integer
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        if SalesCrMemoLine.FindLast() then
            if SalesCrMemoLine.Type = SalesCrMemoLine.Type::"G/L Account" then
                if SalesCrMemoLine."No." <> '' then
                    if SalesCrMemoLine."No." = GetCustInvRndgAccNo(SalesCrMemoLine."Bill-to Customer No.") then
                        exit(SalesCrMemoLine."Line No.");
        exit(0);
    end;

    local procedure UpdateSalesLineICPartnerReference(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    var
        ICPartner: Record "IC Partner";
        ItemReference: Record "Item Reference";
        GLAccount: Record "G/L Account";
        ToDate: Date;
    begin
        if (ICInboxSalesLine."IC Partner Ref. Type" <> ICInboxSalesLine."IC Partner Ref. Type"::"G/L Account") and
               (ICInboxSalesLine."IC Partner Ref. Type" <> ICInboxSalesLine."IC Partner Ref. Type"::" ") and
               (ICInboxSalesLine."IC Partner Ref. Type" <> ICInboxSalesLine."IC Partner Ref. Type"::"Charge (Item)") and
               (ICInboxSalesLine."IC Partner Ref. Type" <> ICInboxSalesLine."IC Partner Ref. Type"::"Cross reference")
        then begin
            ICPartner.Get(SalesHeader."Sell-to IC Partner Code");
            case ICPartner."Outbound Sales Item No. Type" of
                ICPartner."Outbound Sales Item No. Type"::"Common Item No.":
                    SalesLine.Validate("IC Partner Ref. Type", ICInboxSalesLine."IC Partner Ref. Type"::"Common Item No.");
                ICPartner."Outbound Sales Item No. Type"::"Internal No.":
                    begin
                        SalesLine."IC Partner Ref. Type" := ICInboxSalesLine."IC Partner Ref. Type"::Item;
                        SalesLine."IC Partner Reference" := ICInboxSalesLine."IC Partner Reference";
                    end;
                ICPartner."Outbound Sales Item No. Type"::"Cross Reference":
                    begin
                        SalesLine.Validate("IC Partner Ref. Type", ICInboxSalesLine."IC Partner Ref. Type"::"Cross reference");
                        ItemReference.SetRange("Reference Type", "Item Reference Type"::Customer);
                        ItemReference.SetRange("Reference Type No.", SalesHeader."Sell-to Customer No.");
                        ItemReference.SetRange("Item No.", ICInboxSalesLine."IC Item Reference No.");
                        ToDate := SalesLine.GetDateForCalculations();
                        if ToDate <> 0D then begin
                            ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
                            ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
                        end;
                        if ItemReference.FindFirst() then
                            SalesLine."IC Item Reference No." := ItemReference."Reference No.";
                    end;
            end;
        end else begin
            SalesLine."IC Partner Ref. Type" := ICInboxSalesLine."IC Partner Ref. Type";
            if ICInboxSalesLine."IC Partner Ref. Type" <> ICInboxSalesLine."IC Partner Ref. Type"::"G/L Account" then begin
                SalesLine."IC Partner Reference" := ICInboxSalesLine."IC Partner Reference";
                SalesLine."IC Item Reference No." := ICInboxSalesLine."IC Item Reference No.";
            end else
                if GLAccount.Get(TranslateICGLAccount(ICInboxSalesLine."IC Partner Reference")) then
                    SalesLine."IC Partner Reference" := GLAccount."Default IC Partner G/L Acc. No";
        end;
    end;

    /// <summary>
    /// Updates ic partner reference information on created purchase line from ic inbox purchase line.
    /// </summary>
    /// <param name="PurchaseLine">Destination purchase document line. </param>
    /// <param name="PurchaseHeader">Processed purchase document header. </param>
    /// <param name="ICInboxPurchLine">Source ic inbox purchase line. </param>
    /// <remarks>Changes made to purchase document line 'PurchaseLine' are not saved to database. </remarks>
    procedure UpdatePurchLineICPartnerReference(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    var
        ICPartner: Record "IC Partner";
        ItemReference: Record "Item Reference";
        GLAccount: Record "G/L Account";
        ToDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchLineICPartnerReference(PurchaseLine, PurchaseHeader, ICInboxPurchLine, IsHandled);
        if IsHandled then
            exit;

        if (ICInboxPurchLine."IC Partner Ref. Type" <> ICInboxPurchLine."IC Partner Ref. Type"::"G/L Account") and
               (ICInboxPurchLine."IC Partner Ref. Type" <> ICInboxPurchLine."IC Partner Ref. Type"::" ") and
               (ICInboxPurchLine."IC Partner Ref. Type" <> ICInboxPurchLine."IC Partner Ref. Type"::"Charge (Item)") and
               (ICInboxPurchLine."IC Partner Ref. Type" <> ICInboxPurchLine."IC Partner Ref. Type"::"Cross Reference")
        then begin
            ICPartner.Get(PurchaseHeader."Buy-from IC Partner Code");
            case ICPartner."Outbound Purch. Item No. Type" of
                ICPartner."Outbound Purch. Item No. Type"::"Common Item No.":
                    PurchaseLine.Validate("IC Partner Ref. Type", ICInboxPurchLine."IC Partner Ref. Type"::"Common Item No.");
                ICPartner."Outbound Purch. Item No. Type"::"Internal No.":
                    begin
                        PurchaseLine."IC Partner Ref. Type" := ICInboxPurchLine."IC Partner Ref. Type"::Item;
                        PurchaseLine."IC Partner Reference" := ICInboxPurchLine."IC Partner Reference";
                    end;
                ICPartner."Outbound Purch. Item No. Type"::"Cross Reference":
                    begin
                        PurchaseLine.Validate("IC Partner Ref. Type", ICInboxPurchLine."IC Partner Ref. Type"::"Cross reference");
                        ItemReference.SetRange("Reference Type", "Item Reference Type"::Vendor);
                        ItemReference.SetRange("Reference Type No.", PurchaseHeader."Buy-from Vendor No.");
                        ItemReference.SetRange("Item No.", ICInboxPurchLine."IC Item Reference No.");
                        ToDate := PurchaseLine.GetDateForCalculations();
                        if ToDate <> 0D then begin
                            ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
                            ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
                        end;
                        if ItemReference.FindFirst() then
                            PurchaseLine."IC Item Reference No." := ItemReference."Reference No.";
                    end;
                ICPartner."Outbound Purch. Item No. Type"::"Vendor Item No.":
                    begin
                        PurchaseLine."IC Partner Ref. Type" := ICInboxPurchLine."IC Partner Ref. Type"::"Vendor Item No.";
                        PurchaseLine."IC Item Reference No." := PurchaseLine."Vendor Item No.";
                        // TODO
                    end;
            end;
        end else begin
            PurchaseLine."IC Partner Ref. Type" := ICInboxPurchLine."IC Partner Ref. Type";
            if ICInboxPurchLine."IC Partner Ref. Type" <> ICInboxPurchLine."IC Partner Ref. Type"::"G/L Account" then begin
                PurchaseLine."IC Partner Reference" := ICInboxPurchLine."IC Partner Reference";
                PurchaseLine."IC Item Reference No." := ICInboxPurchLine."IC Item Reference No.";
            end else
                if GLAccount.Get(TranslateICGLAccount(ICInboxPurchLine."IC Partner Reference")) then
                    PurchaseLine."IC Partner Reference" := GLAccount."Default IC Partner G/L Acc. No";
        end;
    end;

    /// <summary>
    /// Updates purchase line information based on purchase receipt line or return shipment line for given purchase line if exists.
    /// </summary>
    /// <param name="PurchaseLine">Source purchase line. </param>
    /// <remarks>If either purchase receipt line or return shipment line is found, item tracking information will be transferred if exists. 
    /// Changes made to purchase document line 'PurchaseLine' are not saved to database. </remarks>
    procedure UpdatePurchLineReceiptShipment(var PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        PurchaseOrderLine: Record "Purchase Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OrderDocumentNo: Code[20];
        IsHandled: Boolean;
    begin
        if FindReceiptLine(PurchRcptLine, PurchaseLine) then begin
            OrderDocumentNo := PurchaseLine."Receipt No.";
            PurchaseLine."Location Code" := PurchRcptLine."Location Code";
            PurchaseLine."Receipt No." := PurchRcptLine."Document No.";
            PurchaseLine."Receipt Line No." := PurchRcptLine."Line No.";
            IsHandled := false;
            OnUpdatePurchLineReceiptShipmentOnBeforeCopyHandledItemTrkgToPurchLine(PurchaseLine, IsHandled);
            if not IsHandled then
                if PurchaseOrderLine.Get(PurchaseOrderLine."Document Type"::Order, OrderDocumentNo, PurchaseLine."Receipt Line No.") then
                    ItemTrackingMgt.CopyHandledItemTrkgToPurchLineWithLineQty(PurchaseOrderLine, PurchaseLine);
        end else begin
            PurchaseLine."Receipt No." := '';
            PurchaseLine."Receipt Line No." := 0;
        end;

        if FindShipmentLine(ReturnShptLine, PurchaseLine) then begin
            OrderDocumentNo := PurchaseLine."Return Shipment No.";
            PurchaseLine."Location Code" := ReturnShptLine."Location Code";
            PurchaseLine."Return Shipment No." := ReturnShptLine."Document No.";
            PurchaseLine."Return Shipment Line No." := ReturnShptLine."Line No.";
            IsHandled := false;
            OnUpdatePurchLineReceiptShipmentOnBeforeCopyHandledItemTrkgToInvLine(PurchaseLine, IsHandled);
            if not IsHandled then
                if PurchaseOrderLine.Get(
                    PurchaseOrderLine."Document Type"::"Return Order", OrderDocumentNo, PurchaseLine."Return Shipment Line No.")
                then
                    ItemTrackingMgt.CopyHandledItemTrkgToInvLine(PurchaseOrderLine, PurchaseLine);
        end else begin
            PurchaseLine."Return Shipment No." := '';
            PurchaseLine."Return Shipment Line No." := 0;
        end;
    end;

    local procedure UpdateICOutboxSalesLineReceiptShipment(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateICOutboxSalesLineReceiptShipment(ICOutboxSalesLine, ICOutboxSalesHeader, IsHandled);
        if IsHandled then
            exit;

        case ICOutboxSalesLine."Document Type" of
            ICOutboxSalesLine."Document Type"::Order,
              ICOutboxSalesLine."Document Type"::Invoice:
                if ICOutboxSalesLine."Shipment No." = '' then begin
                    ICOutboxSalesLine."Shipment No." := CopyStr(ICOutboxSalesHeader."External Document No.", 1, MaxStrLen(ICOutboxSalesLine."Shipment No."));
                    ICOutboxSalesLine."Shipment Line No." := ICOutboxSalesLine."Line No.";
                end else
                    if SalesShipmentHeader.Get(ICOutboxSalesLine."Shipment No.") then
                        ICOutboxSalesLine."Shipment No." := CopyStr(SalesShipmentHeader."External Document No.", 1, MaxStrLen(ICOutboxSalesLine."Shipment No."));
            ICOutboxSalesLine."Document Type"::"Credit Memo",
              ICOutboxSalesLine."Document Type"::"Return Order":
                if ICOutboxSalesLine."Return Receipt No." = '' then begin
                    ICOutboxSalesLine."Return Receipt No." := CopyStr(ICOutboxSalesHeader."External Document No.", 1, MaxStrLen(ICOutboxSalesLine."Return Receipt No."));
                    ICOutboxSalesLine."Return Receipt Line No." := ICOutboxSalesLine."Line No.";
                end else
                    if ReturnReceiptHeader.Get(ICOutboxSalesLine."Return Receipt No.") then
                        ICOutboxSalesLine."Return Receipt No." := CopyStr(ReturnReceiptHeader."External Document No.", 1, MaxStrLen(ICOutboxSalesLine."Return Receipt No."));
        end;
    end;

    local procedure AssignCurrencyCodeInOutBoxDoc(var CurrencyCode: Code[10]; ICPartnerCode: Code[20])
    var
        TempAnotherCompGLSetup: Record "General Ledger Setup" temporary;
        ICPartner: Record "IC Partner";
        ICDataExchange: Interface "IC Data Exchange";
    begin
        if CurrencyCode = '' then begin
            ICPartner.Get(ICPartnerCode);
            if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Database then begin
                GetGLSetup();
                ICDataExchange := ICPartner."Data Exchange Type";
                ICDataExchange.GetICPartnerGeneralLedgerSetup(ICPartner, TempAnotherCompGLSetup);
                TempAnotherCompGLSetup.Get();
                if GLSetup."LCY Code" <> TempAnotherCompGLSetup."LCY Code" then
                    CurrencyCode := GLSetup."LCY Code";
            end;
            if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"File Location" then begin
                GetGLSetup();
                CurrencyCode := GLSetup.GetCurrencyCode('');
            end;
        end;
    end;

    local procedure AssignCountryCode(ICPartnerCode: Code[20]; var OriginalCountryCode: Code[10])
    var
        TempCompanyInformation: Record "Company Information" temporary;
        ICPartner: Record "IC Partner";
        ICDataExchange: Interface "IC Data Exchange";
    begin
        if OriginalCountryCode <> '' then
            exit;
        ICPartner.Get(ICPartnerCode);
        if ICPartner."Country/Region Code" <> '' then begin
            OriginalCountryCode := ICPartner."Country/Region Code";
            exit;
        end;
        if ICPartner."Inbox Type" <> ICPartner."Inbox Type"::Database then
            exit;

        ICDataExchange := ICPartner."Data Exchange Type";
        ICDataExchange.GetICPartnerCompanyInformation(ICPartner, TempCompanyInformation);

        if not TempCompanyInformation.Get() then
            exit;

        OriginalCountryCode := TempCompanyInformation."Country/Region Code";
    end;

    local procedure CheckICSalesDocumentAlreadySent(SalesHeader: Record "Sales Header")
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICSalesDocumentAlreadySent(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Sales Document");
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::"Credit Memo":
                HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::"Credit Memo");
            SalesHeader."Document Type"::Invoice:
                HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Invoice);
            SalesHeader."Document Type"::Order:
                HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Order);
            SalesHeader."Document Type"::"Return Order":
                HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::"Return Order");
            else
                exit;
        end;
        HandledICOutboxTrans.SetRange("Document No.", SalesHeader."No.");

        if HandledICOutboxTrans.FindFirst() then
            if not ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(
                    TransactionAlreadyExistsInOutboxHandledQst, HandledICOutboxTrans."Document Type",
                    HandledICOutboxTrans."Document No.", HandledICOutboxTrans."IC Partner Code"),
                true)
            then
                Error('');
    end;

    local procedure CheckICPurchaseDocumentAlreadySent(PurchaseHeader: Record "Purchase Header")
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckICPurchaseDocumentAlreadySent(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Purchase Document");
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::"Credit Memo":
                HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::"Credit Memo");
            PurchaseHeader."Document Type"::Invoice:
                HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Invoice);
            PurchaseHeader."Document Type"::Order:
                HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Order);
            PurchaseHeader."Document Type"::"Return Order":
                HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::"Return Order");
            else
                exit;
        end;
        HandledICOutboxTrans.SetRange("Document No.", PurchaseHeader."No.");

        if HandledICOutboxTrans.FindFirst() then
            if not ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(
                    TransactionAlreadyExistsInOutboxHandledQst, HandledICOutboxTrans."Document Type",
                    HandledICOutboxTrans."Document No.", HandledICOutboxTrans."IC Partner Code"),
                true)
            then
                Error('');
    end;

    procedure CheckPermissionToSendICTransaction(var SalesHeader: Record "Sales Header")
    var
        ICSetup: Record "IC Setup";
        ICPartner: Record "IC Partner";
        Customer: Record "Customer";
        TempRegisteredPartner: Record "IC Partner" temporary;
        ICDataExchange: Interface "IC Data Exchange";
    begin
        // Should the IC-document be sent?
        if not (SalesHeader.Invoice and SalesHeader."Send IC Document") then
            exit;

        // Is the Document type Order or Invoice?
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]) then
            exit;

        // Do we auto send IC-transactions?
        if not ICSetup.Get() then
            exit;
        if not ICSetup."Auto. Send Transactions" then
            exit;

        // Does the partner auto accept the transaction?
        if not Customer.Get(SalesHeader."Bill-to Customer No.") then
            exit;
        if not ICPartner.Get(Customer."IC Partner Code") then
            exit;
        ICDataExchange := ICPartner."Data Exchange Type";
        ICDataExchange.GetICPartnerFromICPartner(ICPartner, TempRegisteredPartner);
        if not TempRegisteredPartner."Auto. Accept Transactions" then
            exit;

        // Check if user can schedule tasks
        if not TaskScheduler.CanCreateTask() then
            Error(PermissionToAutoAcceptICDocsErr)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxSalesDocTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxSalesInvTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxSalesCrMemoTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxPurchDocTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxJnlLine(var ICOutboxJnlLine: Record "IC Outbox Jnl. Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOutboxJnlLineOnBeforeICOutboxJnlLineInsert(var ICOutboxJnlLine: Record "IC Outbox Jnl. Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesDocument(var SalesHeader: Record "Sales Header"; ICInboxSalesHeader: Record "IC Inbox Sales Header"; HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesLines(ICInboxSalesLine: Record "IC Inbox Sales Line"; var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchLines(ICInboxPurchLine: Record "IC Inbox Purchase Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateJournalLines(var GenJnlLine2: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterForwardToOutBoxSalesDoc(var ICInboxTransaction: Record "IC Inbox Transaction"; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterForwardToOutBoxPurchDoc(var ICInboxTransaction: Record "IC Inbox Transaction"; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandledICOutboxSalesHdrInsert(var HandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandledICOutboxPurchHdrInsert(var HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr"; var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxPurchHeaderInsert(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxPurchLineInsert(var ICInboxPurchaseLine: Record "IC Inbox Purchase Line"; ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxSalesHeaderInsert(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxSalesLineInsert(var ICInboxSalesLine: Record "IC Inbox Sales Line"; ICOutboxPurchaseLine: Record "IC Outbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxTransInsert(var ICInboxTransaction: Record "IC Inbox Transaction"; ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunExchangeAccGLJournalLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; TransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxPurchDocTransOnAfterTransferFieldsFromPurchHeader(var ICOutboxPurchHeader: Record "IC Outbox Purchase Header"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesCrMemoTransOnAfterICOutBoxSalesHeaderInsert(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxPurchDocTransOnAfterPurchLineSetFilters(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesInvTransOnAfterICOutBoxSalesHeaderInsert(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJournalLinesOnBeforeModify(var GenJournalLine: Record "Gen. Journal Line"; ICInboxJnlLine: Record "IC Inbox Jnl. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICPurchaseDocumentAlreadySent(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICSalesDocumentAlreadySent(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOutboxPurchDocTrans(PurchaseHeader: Record "Purchase Header"; Rejection: Boolean; Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOutboxSalesCrMemoTrans(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJournalLines(InboxTransaction: Record "IC Inbox Transaction"; InboxJnlLine: Record "IC Inbox Jnl. Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; GenJnlTemplate: Record "Gen. Journal Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLineSource: Record "Purchase Line"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; ICInboxJnlLine: Record "IC Inbox Jnl. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxPurchHeaderInsert(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxPurchLineInsert(var ICInboxPurchaseLine: Record "IC Inbox Purchase Line"; ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxSalesHeaderInsert(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxSalesLineInsert(var ICInboxSalesLine: Record "IC Inbox Sales Line"; ICOutboxPurchaseLine: Record "IC Outbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxTransInsert(var ICInboxTransaction: Record "IC Inbox Transaction"; ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendPurchDoc(var PurchHeader: Record "Purchase Header"; var Post: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendSalesDoc(var SalesHeader: Record "Sales Header"; var Post: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateICOutboxSalesLineReceiptShipment(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSalesLineDeliveryDates(var SalesLine: Record "Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityFromICInboxSalesLine(var SalesLine: Record "Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesInvTransOnAfterTransferFieldsFromSalesInvHeader(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; SalesInvHdr: Record "Sales Invoice Header"; ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesInvTransOnBeforeOutboxTransactionInsert(var OutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesCrMemoTransOnAfterTransferFieldsFromSalesCrMemoHeader(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; SalesCrMemoHdr: Record "Sales Cr.Memo Header"; ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesCrMemoTransOnBeforeOutboxTransactionInsert(var OutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICOutboxTransactionCreatedSalesDocTrans(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; LinesCreated: Boolean; Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICOutboxTransactionCreatedSalesInvTrans(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICOutboxTransactionCreatedSalesCrMemoTrans(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICOutboxTransactionCreatedPurchDocTrans(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; LinesCreated: Boolean; Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICOutboxSalesLineInsert(var HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line"; ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICOutboxPurchLineInsert(var HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line"; ICOutboxPurchLine: Record "IC Outbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInboxSalesLineInsert(var ICInboxSalesLine: Record "IC Inbox Sales Line"; HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOutBoxTransactionInsert(var ICOutboxTransaction: Record "IC Outbox Transaction"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchLineICPartnerReference(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ICInboxPurchLine: Record "IC Inbox Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxJnlTransactionOnBeforeOutboxJnlTransactionInsert(var OutboxJnlTransaction: Record "IC Outbox Transaction"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxPurchDocTransOnAfterICOutBoxPurchLineInsert(var ICOutboxPurchaseLine: Record "IC Outbox Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesCrMemoTransOnBeforeICOutBoxSalesLineInsert(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesDocTransOnAfterICOutBoxSalesLineInsert(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesInvTransOnBeforeICOutBoxSalesLineInsert(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; SalesInvLine: Record "Sales Invoice Line"; ICOutBoxSalesHeader: Record "IC Outbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocumentOnBeforeHandledICInboxPurchLineInsert(ICInboxPurchLine: Record "IC Inbox Purchase Line"; var HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocumentOnBeforePurchHeaderInsert(var PurchaseHeader: Record "Purchase Header"; ICInboxPurchaseHeader: Record "IC Inbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesDocumentOnAfterSalesHeaderFirstModify(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesDocumentOnBeforeSetICDocDimFilters(var SalesHeader: Record "Sales Header"; var ICInboxSalesHeader: Record "IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesDocumentOnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; ICInboxSalesHeader: Record "IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLinesOnAfterValidateNo(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchLinesOnAfterValidateNo(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ICInboxPurchaseLine: Record "IC Inbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForwardToOutBoxOnBeforeHndlInboxPurchLineInsert(var HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForwardToOutBoxOnBeforeHndlInboxSalesLineInsert(var HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForwardToOutBoxOnBeforeOutboxTransactionInsert(var ICOutboxTransaction: Record "IC Outbox Transaction"; ICInboxTransaction: Record "IC Inbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeDeleteSalesHeader(HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header"; var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeDeletePurchHeader(HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header"; var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeInboxPurchHdrInsert(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeInboxPurchLineInsert(var ICInboxPurchaseLine: Record "IC Inbox Purchase Line"; HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeInboxSalesHdrInsert(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeInboxTransactionInsert(var ICInboxTransaction: Record "IC Inbox Transaction"; HandledICInboxTrans: Record "Handled IC Inbox Trans."; var HandledInboxTransaction: Record "Handled IC Inbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeDeleteSalesHeader(HandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header"; var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeDeletePurchHeader(HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr"; var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeOutboxPurchHdrInsert(var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header"; HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeOutboxPurchLineInsert(var ICOutboxPurchaseLine: Record "IC Outbox Purchase Line"; HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeOutboxSalesLineInsert(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeOutboxTransactionInsert(var ICOutboxTransaction: Record "IC Outbox Transaction"; HandledICOutboxTrans: Record "Handled IC Outbox Trans."; var HandledOutboxTransaction: Record "Handled IC Outbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICOutBoxSalesLineInsert(var SalesLine: Record "Sales Line"; var ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICOutBoxSalesHeaderTransferFields(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchDocument(ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ReplacePostingDate: Boolean; PostingDate: Date; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header"; var HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesDocument(ICInboxSalesHeader: Record "IC Inbox Sales Header"; ReplacePostingDate: Boolean; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOutboxSalesDocTrans(SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOutboxSalesInvTrans(SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICInboxSalesLineInsert(var HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledInboxTransactionInsert(var HandledICInboxTrans: Record "Handled IC Inbox Trans."; ICInboxTransaction: Record "IC Inbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOutboxPurchHdrToInboxProcedure(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxPurchHeader: Record "IC Outbox Purchase Header"; var ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICSetup: Record "IC Setup"; var IsHandled: Boolean; var ICPartner: Record "IC Partner"; var TempPartnerICPartner: Record "IC Partner" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOutboxSalesHdrToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICInboxPurchHeader: Record "IC Inbox Purchase Header"; var ICPartner: Record "IC Partner"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesDocumentOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; ICInboxSalesHeader: Record "IC Inbox Sales Header"; var ICDocDim: Record "IC Document Dimension")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocumentOnBeforeSetICDocDimFilters(var PurchHeader: Record "Purchase Header"; var ICInboxPurchHeader: Record "IC Inbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocumentOnBeforePurchHeaderModify(var PurchHeader: Record "Purchase Header"; ICInboxPurchHeader: Record "IC Inbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLinesOnBeforefterAssignTypeAndNo(var SalesLine: Record "Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchLinesOnBeforeAssignTypeAndNo(var PurchaseLine: Record "Purchase Line"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchLinesOnAfterTransferFields(var PurchaseLine: Record "Purchase Line"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchLinesOnAfterAssignPurchLineFields(var PurchaseLine: Record "Purchase Line"; ICInboxPurchLine: Record "IC Inbox Purchase Line"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchLinesOnAfterModify(var PurchaseLine: Record "Purchase Line"; ICInboxPurchLine: Record "IC Inbox Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchLinesOnBeforeModify(var PurchaseLine: Record "Purchase Line"; ICInboxPurchLine: Record "IC Inbox Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchLinesOnICPartnerRefTypeCaseElse(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLinesOnICPartnerRefTypeCaseElse(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveOutboxTransToHandledOutboxOnAfterHandledICOutboxTransTransferFields(var HandledICOutboxTrans: Record "Handled IC Outbox Trans."; var ICOutboxTrans: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxPurchDocTransOnBeforeOutboxTransactionInsert(var OutboxTransaction: Record "IC Outbox Transaction"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveOutboxTransToHandledOutboxOnBeforeHandledICOutboxTransTransferFields(var HandledICOutboxTrans: Record "Handled IC Outbox Trans."; var ICOutboxTrans: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveOutboxTransToHandledOutboxOnBeforeICOutboxPurchLineDelete(ICOutboxPurchLine: Record "IC Outbox Purchase Line"; HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveOutboxTransToHandledOutboxOnBeforeICOutboxSalesLineDelete(ICOutboxSalesLine: Record "IC Outbox Sales Line"; HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOutboxJnlLineToInboxOnBeforeICInboxJnlLineInsert(var ICInboxJnlLine: Record "IC Inbox Jnl. Line"; var ICOutboxJnlLine: Record "IC Outbox Jnl. Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendPurchDocOnBeforeReleasePurchDocument(var PurchaseHeader: Record "Purchase Header"; var Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendSalesDocOnBeforeReleaseSalesDocument(var SalesHeader: Record "Sales Header"; var Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendSalesDocOnbeforeTestSendICDocument(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLinesOnBeforeCalcPriceAndAmounts(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchLinesOnBeforeCalcPriceAndAmounts(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLinesOnBeforeValidateUnitOfMeasureCode(var SalesLine: Record "Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesHeader(var SalesHeader: Record "Sales Header"; ICInboxSalesHeader: Record "IC Inbox Sales Header"; var ICDocDim: Record "IC Document Dimension"; ReplacePostingDate: Boolean; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchaseHeader(var PurchHeader: Record "Purchase Header"; ICInboxPurchHeader: Record "IC Inbox Purchase Header"; var ICDocDim: Record "IC Document Dimension"; ReplacePostingDate: Boolean; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesDocumentOnAfterICInboxSalesLineSetFilters(var ICInboxSalesLine: Record "IC Inbox Sales Line"; ICInboxSalesHeader: Record "IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocumentOnAfterICInboxPurchLineSetFilters(var ICInboxPurchLine: Record "IC Inbox Purchase Line"; ICInboxPurchHeader: Record "IC Inbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesLines(SalesHeader: Record "Sales Header"; var ICInboxSalesLine: Record "IC Inbox Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchLines(PurchHeader: Record "Purchase Header"; var ICInboxPurchLine: Record "IC Inbox Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLineReceiptShipmentOnBeforeCopyHandledItemTrkgToPurchLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLineReceiptShipmentOnBeforeCopyHandledItemTrkgToInvLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendPurchDoc(var PurchaseHeader: Record "Purchase Header"; var Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendSalesDoc(var SalesHeader: Record "Sales Header"; var Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRejectAcceptedSalesHeader(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOutboxJnlLineToInbox(var ICInboxTransaction: Record "IC Inbox Transaction"; var ICOutboxJnlLine: Record "IC Outbox Jnl. Line"; var ICInboxJnlLine: Record "IC Inbox Jnl. Line"; var ICPartner: Record "IC Partner"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesDocTransOnBeforeLoop(var SalesLine: Record "Sales Line")
    begin
    end;
}