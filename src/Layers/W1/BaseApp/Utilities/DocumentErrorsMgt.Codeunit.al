// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Utilities;

codeunit 9070 "Document Errors Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    var
        TempModifiedSalesLine: Record "Sales Line" temporary;
        TempModifiedPurchaseLine: Record "Purchase Line" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        GlobalSalesOrderPage: Page "Sales Order";
        GlobalSalesInvoicePage: Page "Sales Invoice";
        GlobalSalesCreditMemoPage: Page "Sales Credit Memo";
        GlobalSalesReturnOrderPage: Page "Sales Return Order";
        GlobalPurchaseInvoicePage: Page "Purchase Invoice";
        GlobalPurchaseOrderPage: Page "Purchase Order";
        GlobalPurchaseCreditMemoPage: Page "Purchase Credit Memo";
        GlobalPurchaseReturnOrderPage: Page "Purchase Return Order";
        FullDocumentCheck: Boolean;
        EnableBackgroundValidationNotificationTxt: Label 'Enable Data Check';
        EnableBackgroundValidationNotificationDescriptionTxt: Label 'Notify me that Business Central can validate data in documents and journals while I''m working. Messages are shown in the Document Check FactBox.';
        EnableShowDocumentCheckFactboxNotificationTxt: Label 'Show the Document Check FactBox';
        EnableShowDocumentCheckFactboxNotificationDescriptionTxt: Label 'Start validating data in documents and journals while you work. Messages are shown in the Document Check FactBox.';
        NotificationMsg: Label 'Start validating data in documents and journals while you work. Messages are shown in the Document Check FactBox.';
        DontShowAgainTxt: Label 'Don''t show again';
        EnableThisForMeTxt: Label 'Enable this for me';
        NothingToPostErr: Label 'There is nothing to post because the document does not contain a quantity or amount.';

    procedure GetNothingToPostErrorMsg(): Text
    begin
        exit(NothingToPostErr);
    end;

    procedure GetModifiedSalesLineNo() LineNo: Integer
    begin
        LineNo := TempModifiedSalesLine."Line No.";
        Clear(TempModifiedSalesLine);
    end;

    procedure GetModifiedPurchaseLineNo() LineNo: Integer
    begin
        LineNo := TempModifiedPurchaseLine."Line No.";
        Clear(TempModifiedPurchaseLine);
    end;

    procedure SetModifiedSalesLine(var SalesLine: Record "Sales Line")
    begin
        TempModifiedSalesLine := SalesLine;
    end;

    procedure SetModifiedPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        TempModifiedPurchaseLine := PurchaseLine;
    end;

    procedure SetFullDocumentCheck(NewFullDocumentCheck: Boolean)
    begin
        FullDocumentCheck := NewFullDocumentCheck;
    end;

    procedure GetFullDocumentCheck(): Boolean
    begin
        exit(FullDocumentCheck);
    end;

    procedure SetErrorMessages(var SourceTempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Copy(SourceTempErrorMessage, true);
    end;

    procedure GetErrorMessages(var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        NewTempErrorMessage.Copy(TempErrorMessage, true);
    end;

    procedure BackgroundValidationEnabled(): Boolean
    begin
        if not BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then
            exit(false);

        if IsShowDocumentCheckFactboxNotificationEnabled() then
            exit(true);

        exit(false);
    end;

    procedure CheckShowEnableBackgrValidationNotification(): Boolean
    begin
        if not BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then
            exit(false);

        CheckInitNotifications();

        if not IsBackgroundValidationNotificationEnabled() then
            exit(false);

        if IsShowDocumentCheckFactboxNotificationEnabled() then
            exit(false);

        SendEnableBackgroundValidationNotification();
        exit(true);
    end;

    local procedure SendEnableBackgroundValidationNotification()
    var
        BackgroundValidationNotification: Notification;
    begin
        BackgroundValidationNotification.Id := GetEnableBackgroundValidationNotificationID();
        if BackgroundValidationNotification.Recall() then;

        BackgroundValidationNotification.Message(NotificationMsg);
        BackgroundValidationNotification.Scope(NotificationScope::LocalScope);
        BackgroundValidationNotification.AddAction(EnableThisForMeTxt, Codeunit::"Document Errors Mgt.", 'EnableShowDocumentCheckFactbox');
        BackgroundValidationNotification.AddAction(DontShowAgainTxt, Codeunit::"Document Errors Mgt.", 'DontShowAgainEnableBackgroundValidationNotification');
        BackgroundValidationNotification.Send();
    end;

    procedure EnableShowDocumentCheckFactbox(Notification: Notification)
    begin
        EnableShowDocumentCheckFactboxNotification();
        DisableBackgroundValidationNotification();
    end;

    procedure DontShowAgainEnableBackgroundValidationNotification(Notification: Notification)
    begin
        DisableBackgroundValidationNotification();
    end;

    procedure DisableBackgroundValidationNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.SetStatus(GetEnableBackgroundValidationNotificationID(), false) then
            MyNotifications.InsertDefault(
              GetEnableBackgroundValidationNotificationID(), EnableBackgroundValidationNotificationTxt, EnableBackgroundValidationNotificationDescriptionTxt, false);
    end;

    procedure EnableBackgroundValidationNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.SetStatus(GetEnableBackgroundValidationNotificationID(), true) then
            MyNotifications.InsertDefault(
                GetEnableBackgroundValidationNotificationID(), EnableBackgroundValidationNotificationTxt, EnableBackgroundValidationNotificationDescriptionTxt, true);
    end;

    procedure EnableShowDocumentCheckFactboxNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.SetStatus(GetShowDocumentCheckFactboxNotificationID(), true) then
            MyNotifications.InsertDefault(
              GetShowDocumentCheckFactboxNotificationID(), EnableShowDocumentCheckFactboxNotificationTxt, EnableShowDocumentCheckFactboxNotificationDescriptionTxt, true);
    end;

    procedure DisableShowDocumentCheckFactboxNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.SetStatus(GetShowDocumentCheckFactboxNotificationID(), false) then
            MyNotifications.InsertDefault(
              GetShowDocumentCheckFactboxNotificationID(), EnableShowDocumentCheckFactboxNotificationTxt, EnableShowDocumentCheckFactboxNotificationDescriptionTxt, false);
    end;

    procedure IsBackgroundValidationNotificationEnabled(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        exit(InstructionMgt.IsMyNotificationEnabled(GetEnableBackgroundValidationNotificationID()));
    end;

    procedure IsShowDocumentCheckFactboxNotificationEnabled(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        exit(InstructionMgt.IsMyNotificationEnabled(GetShowDocumentCheckFactboxNotificationID()));
    end;

    procedure GetEnableBackgroundValidationNotificationID(): Guid
    begin
        exit('1ab28806-432f-46cc-844e-85b0fc36f883');
    end;

    procedure GetShowDocumentCheckFactboxNotificationID(): Guid
    begin
        exit('34171d17-3e54-4f70-bd63-a5e0df1031e7');
    end;

    local procedure CheckInitNotifications()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Get(UserId, GetEnableBackgroundValidationNotificationID()) then
            EnableBackgroundValidationNotification();
        if not MyNotifications.Get(UserId, GetShowDocumentCheckFactboxNotificationID()) then
            DisableShowDocumentCheckFactboxNotification();
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then
            CheckInitNotifications();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesOrderSubform(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalSalesOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesInvoiceSubform(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalSalesInvoicePage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Cr. Memo Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesCrMemoSubform(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalSalesCreditMemoPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Return Order Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesReturnOrderSubform(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalSalesReturnOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordSalesOrder(var Sender: Page "Sales Order"; var SalesHeader: Record "Sales Header")
    begin
        if BackgroundValidationEnabled() then
            GlobalSalesOrderPage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordSalesInvoice(var Sender: Page "Sales Invoice"; var SalesHeader: Record "Sales Header")
    begin
        if BackgroundValidationEnabled() then
            GlobalSalesInvoicePage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Credit Memo", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordSalesCreditMemo(var Sender: Page "Sales Credit Memo"; var SalesHeader: Record "Sales Header")
    begin
        if BackgroundValidationEnabled() then
            GlobalSalesCreditMemoPage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Return Order", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordSalesReturnOrder(var Sender: Page "Sales Return Order"; var SalesHeader: Record "Sales Header")
    begin
        if BackgroundValidationEnabled() then
            GlobalSalesReturnOrderPage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesOrder(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalSalesOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesInvoice(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalSalesInvoicePage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Credit Memo", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesCreditMemo(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalSalesCreditMemoPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Return Order", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesReturnOrder(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalSalesReturnOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Doc. Check Factbox", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordSalesDocCheckFactbox(var Rec: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforeOnAfterGetCurrRecordSalesDocCheckFactbox(Rec, IsHandled);
        if IsHandled then
            exit;

        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            case Rec."Document Type" of
                "Sales Document Type"::Invoice:
                    GlobalSalesInvoicePage.RunBackgroundCheck();
                "Sales Document Type"::Order:
                    GlobalSalesOrderPage.RunBackgroundCheck();
                "Sales Document Type"::"Credit Memo":
                    GlobalSalesCreditMemoPage.RunBackgroundCheck();
                "Sales Document Type"::"Return Order":
                    GlobalSalesReturnOrderPage.RunBackgroundCheck();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseOrderSubform(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalPurchaseOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purch. Invoice Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseInvoiceSubform(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalPurchaseOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purch. Cr. Memo Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseCrMemoSubform(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalPurchaseOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Return Order Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseReturnOrderSubform(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalPurchaseOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordPurchaseOrder(var Sender: Page "Purchase Order"; var PurchaseHeader: Record "Purchase Header")
    begin
        if BackgroundValidationEnabled() then
            GlobalPurchaseOrderPage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Invoice", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordPurchaseInvoice(var Sender: Page "Purchase Invoice"; var PurchaseHeader: Record "Purchase Header")
    begin
        if BackgroundValidationEnabled() then
            GlobalPurchaseInvoicePage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Credit Memo", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordPurchaseCreditMemo(var Sender: Page "Purchase Credit Memo"; var PurchaseHeader: Record "Purchase Header")
    begin
        if BackgroundValidationEnabled() then
            GlobalPurchaseCreditMemoPage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Return Order", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordPurchaseReturnOrder(var Sender: Page "Purchase Return Order"; var PurchaseHeader: Record "Purchase Header")
    begin
        if BackgroundValidationEnabled() then
            GlobalPurchaseReturnOrderPage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseOrder(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalPurchaseOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Invoice", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseInvoice(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalPurchaseInvoicePage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Credit Memo", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseCreditMemo(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalPurchaseCreditMemoPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Return Order", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseReturnOrder(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; var AllowModify: Boolean)
    begin
        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            GlobalPurchaseReturnOrderPage.RunBackgroundCheck();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purch. Doc. Check Factbox", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordPurchDocCheckFactbox(var Rec: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforeOnAfterGetCurrRecordPurchDocCheckFactbox(Rec, IsHandled);
        if IsHandled then
            exit;

        if BackgroundValidationEnabled() then begin
            SetFullDocumentCheck(true);
            case Rec."Document Type" of
                "Purchase Document Type"::Invoice:
                    GlobalPurchaseInvoicePage.RunBackgroundCheck();
                "Purchase Document Type"::Order:
                    GlobalPurchaseOrderPage.RunBackgroundCheck();
                "Purchase Document Type"::"Credit Memo":
                    GlobalPurchaseCreditMemoPage.RunBackgroundCheck();
                "Purchase Document Type"::"Return Order":
                    GlobalPurchaseReturnOrderPage.RunBackgroundCheck();
            end;
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnAfterGetCurrRecordPurchDocCheckFactbox(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnAfterGetCurrRecordSalesDocCheckFactbox(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}
