namespace System.Environment.Configuration;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.Posting;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;

codeunit 1508 "Notification Lifecycle Handler"
{

    trigger OnRun()
    begin
    end;

    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterSalesLineInsertSetRecId(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterSalesLineRenameUpdateRecId(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterSalesLineDeleteRecall(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterItemJournalInsertSetRecId(var Rec: Record "Item Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterItemJournalRenameUpdateRecId(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterItemJournalDeleteRecall(var Rec: Record "Item Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterTransferLineInsertSetRecId(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterTransferLineRenameUpdateRecId(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterTransferLineDeleteRecall(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterJobPlanningLineInsertSetRecId(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterJobPlanningLineRenameUpdateRecId(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterJobPlanningLineDeleteRecall(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assembly Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterAssemblyLineInsertSetRecId(var Rec: Record "Assembly Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assembly Line", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterAssemblyLineRenameUpdateRecId(var Rec: Record "Assembly Line"; var xRec: Record "Assembly Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assembly Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterAssemblyLineDeleteRecall(var Rec: Record "Assembly Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterSalesHeaderInsertSetRecId(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterPurchaseHeaderInsertSetRecId(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterGenJnlLineInsertSetRecId(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cust-Check Cr. Limit", 'OnNewCheckRemoveCustomerNotifications', '', false, false)]
    local procedure OnCustCheckCrLimitCheckRecallNotifs(RecId: RecordID; RecallCreditOverdueNotif: Boolean)
    var
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        if NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          RecId, CustCheckCrLimit.GetCreditLimitNotificationId(), false);
        if RecallCreditOverdueNotif then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              RecId, CustCheckCrLimit.GetOverdueBalanceNotificationId(), false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnBeforeValidateEvent', 'Entry Type', false, false)]
    local procedure OnItemJournalLineUpdateEntryTypeRecallItemNotif(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec."Entry Type" <> Rec."Entry Type"::Sale) and
           (xRec."Entry Type" <> Rec."Entry Type") and (CurrFieldNo = Rec.FieldNo("Entry Type"))
        then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnItemJournalLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeValidateEvent', 'Type', false, false)]
    local procedure OnSalesLineUpdateTypeRecallItemNotif(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Type <> Rec.Type::Item) and (xRec.Type <> Rec.Type) and (CurrFieldNo = Rec.FieldNo(Type)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnSalesLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnTransferLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnBeforeValidateEvent', 'Type', false, false)]
    local procedure OnJobPlanningLineUpdateTypeRecallItemNotif(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Type <> Rec.Type::Item) and (xRec.Type <> Rec.Type) and (CurrFieldNo = Rec.FieldNo(Type)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnBeforeValidateEvent', 'Line Type', false, false)]
    local procedure OnJobPlanningLineUpdateLineTypeRecallItemNotif(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec."Line Type" = Rec."Line Type"::Billable) and
           (xRec."Line Type" <> Rec."Line Type") and (CurrFieldNo = Rec.FieldNo("Line Type"))
        then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnJobPlanningLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assembly Line", 'OnBeforeValidateEvent', 'Unit of Measure Code', false, false)]
    local procedure OnAssemblyLineUpdateUnitOfMeasureCodeRecallItemNotif(var Rec: Record "Assembly Line"; var xRec: Record "Assembly Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (xRec."Unit of Measure Code" <> Rec."Unit of Measure Code") and (CurrFieldNo = Rec.FieldNo("Unit of Measure Code")) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assembly Line", 'OnBeforeValidateEvent', 'Type', false, false)]
    local procedure OnAssemblyLineUpdateTypeRecallItemNotif(var Rec: Record "Assembly Line"; var xRec: Record "Assembly Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (Rec.Type <> Rec.Type::Item) and (xRec.Type <> Rec.Type) and (CurrFieldNo = Rec.FieldNo(Type)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assembly Line", 'OnBeforeValidateEvent', 'Quantity per', false, false)]
    local procedure OnAssemblyLineUpdateQuantityRecallItemNotif(var Rec: Record "Assembly Line"; var xRec: Record "Assembly Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled() then
            exit;

        if (xRec."Quantity per" <> Rec."Quantity per") and (CurrFieldNo = Rec.FieldNo("Quantity per")) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), Rec."Line No." = 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforeSalesPost(var Sender: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
        NotificationLifecycleMgt.DisableSubscribers();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterSalesPost(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePurchPost(var Sender: Codeunit "Purch.-Post"; var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
        NotificationLifecycleMgt.DisableSubscribers();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure OnAfterPurchPost(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", 'OnBeforePost', '', false, false)]
    local procedure OnBeforeAssemblyPost(var AssemblyHeader: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.DisableSubscribers();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", 'OnAfterPost', '', false, false)]
    local procedure OnAfterAssemblyPost(var AssemblyHeader: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Quote", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesQuote(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Quote", 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseSalesQuote(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesOrder(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order", 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseSalesOrder(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesInvoice(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice", 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseSalesInvoice(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Credit Memo", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesCreditMemo(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Credit Memo", 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseSalesCreditMemo(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Quote", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseQuote(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Quote", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePurchaseQuote(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseOrder(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePurchaseOrder(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Invoice", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseInvoice(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Invoice", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePurchaseInvoice(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Credit Memo", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseCreditMemo(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Credit Memo", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePurchaseCreditMemo(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Assembly Order", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenAssemblyOrder(var Rec: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Assembly Order", 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseAssemblyOrder(var Rec: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Assembly Quote", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenAssemplyQuote(var Rec: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Assembly Quote", 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseAssemplyQuote(var Rec: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Journal Lines", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenItemJournalLine(var Rec: Record "Item Journal Line")
    begin
        NotificationLifecycleMgt.EnableSubscribers();
    end;
}

