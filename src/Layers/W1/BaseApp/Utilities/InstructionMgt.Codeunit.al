// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Purchases.History;
using System.Environment.Configuration;
using System.Security.User;

codeunit 1330 "Instruction Mgt."
{
    Permissions = TableData "My Notifications" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WarnUnpostedDocumentsTxt: Label 'Warn about unposted documents.';
        WarnUnpostedDocumentsDescriptionTxt: Label 'Show warning when you close a document that you have not posted.';
        ConfirmAfterPostingDocumentsTxt: Label 'Confirm after posting documents.';
        ConfirmAfterPostingDocumentsDescriptionTxt: Label 'Show warning when you post a document where you can choose to view the posted document.';
        ConfirmPostingAfterWorkingDateTxt: Label 'Confirm posting after the working date.';
        ConfirmPostingAfterWorkingDateDescriptionTxt: Label 'Show warning when you post entries where the posting date is after the working date.';
        MarkBookingAsInvoicedWarningTxt: Label 'Confirm marking booking as invoiced.';
        MarkBookingAsInvoicedWarningDescriptionTxt: Label 'Show warning when you mark a Booking appointment as invoiced.';
        OfficeUpdateNotificationTxt: Label 'Notify user of Outlook add-in update.';
        OfficeUpdateNotificationDescriptionTxt: Label 'Ask user to update their Outlook add-in when an update is available.';
        AutomaticLineItemsDialogNotificationTxt: Label 'Discover line items in Outlook add-in';
        AutomaticLineItemsDialogNotificationDescriptionTxt: Label 'Scan the email body for potential line items when you create documents in the Outlook add-in.';
        ClosingUnreleasedOrdersNotificationTxt: Label 'Warn about unreleased orders.';
        ClosingProductionBOMRoutingsNotificationTxt: Label 'Warn about non-certified production BOMs and Routings';
        ClosingUnreleasedOrdersNotificationDescriptionTxt: Label 'Show a warning when you close an order that requires warehouse handling but has not been released.';
        ClosingNoncertifiedProductionBOMRoutingNotificationDescriptionTxt: Label 'Show a warning when you close an non-certified production BOMs or routing.';
        ClosingUnreleasedOrdersConfirmQst: Label 'The document has not been released.\Are you sure you want to exit?';
        ClosingNoncertifiedProductionBOMRoutingConfirmQst: Label 'The Production BOM or routing has not been certified. Are you sure you want to exit?';
        DefaultDimPrioritiesMissingTxt: Label 'Notify user about missing Default Dimension Priorities.';
        DefaultDimPrioritiesMissingDescriptionTxt: Label 'Show notification when Default Dimension Priorities are not defined, and then header dimension will have priority over lines default dimensions.';

    procedure ShowConfirm(ConfirmQst: Text; InstructionType: Code[50]): Boolean
    begin
        if GuiAllowed and IsEnabled(InstructionType) then begin
            Commit();
            exit(Confirm(ConfirmQst));
        end;

        exit(true);
    end;

    procedure ShowConfirmUnreleased(): Boolean
    begin
        exit(ShowConfirm(ClosingUnreleasedOrdersConfirmQst, ClosingUnreleasedOrdersCode()));
    end;

    procedure ShowConfirmNonCertified(): Boolean
    begin
        exit(ShowConfirm(ClosingNoncertifiedProductionBOMRoutingConfirmQst, ClosingNonCertifiedProductionBOMROUTINGCode()));
    end;

    procedure DisableMessageForCurrentUser(InstructionType: Code[50])
    var
        UserPreference: Record "User Preference";
    begin
        UserPreference.DisableInstruction(InstructionType);
    end;

    procedure EnableMessageForCurrentUser(InstructionType: Code[50])
    var
        UserPreference: Record "User Preference";
    begin
        UserPreference.EnableInstruction(InstructionType);
    end;

    procedure IsEnabled(InstructionType: Code[50]) Result: Boolean
    var
        UserPreference: Record "User Preference";
    begin
        Result := not UserPreference.Get(UserId, InstructionType);

        OnAfterIsEnabled(InstructionType, Result);
    end;

    procedure IsUnpostedEnabledForRecord(RecVariant: Variant) Enabled: Boolean
    var
        MyNotifications: Record "My Notifications";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsUnpostedEnabledForRecord(RecVariant, Enabled, IsHandled);
        if not IsHandled then
            Enabled := MyNotifications.IsEnabledForRecord(GetClosingUnpostedDocumentNotificationId(), RecVariant);
    end;

    procedure IsMyNotificationEnabled(NotificationID: Guid): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Get(UserId, NotificationID) then
            exit(false);

        exit(MyNotifications.Enabled);
    end;

    procedure CreateMissingMyNotificationsWithDefaultState(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
        PageMyNotifications: Page "My Notifications";
    begin
        if not MyNotifications.Get(UserId, NotificationID) then
            PageMyNotifications.InitializeNotificationsWithDefaultState();
    end;

    procedure ShowPostedConfirmationMessageCode(): Code[50]
    begin
        exit('SHOWPOSTEDCONFIRMATIONMESSAGE');
    end;

    procedure QueryPostOnCloseCode(): Code[50]
    begin
        exit('QUERYPOSTONCLOSE');
    end;

    procedure OfficeUpdateNotificationCode(): Code[50]
    begin
        exit('OFFICEUPDATENOTIFICATION');
    end;

    procedure GetDefaultDimPrioritiesTxt(): Text[128]
    begin
        exit(DefaultDimPrioritiesMissingTxt);
    end;

    procedure GetDefaultDimPrioritiesDescriptionTxt(): Text
    begin
        exit(DefaultDimPrioritiesMissingDescriptionTxt);
    end;

    procedure PostingAfterWorkingDateNotAllowedCode(): Code[50]
    begin
        exit('POSTINGAFTERCURRENTCALENDARDATENOTALLOWED');
    end;

    procedure ClosingUnreleasedOrdersCode(): Code[50]
    begin
        exit('CLOSINGUNRELEASEDORDERS');
    end;

    procedure ClosingNonCertifiedProductionBOMROUTINGCode(): Code[50]
    begin
        exit('CLOSINGNONCERTIFIEDPRODUCTIONBOMORROUTING');
    end;

    procedure DefaultDimPrioritiesCode(): Code[50]
    begin
        exit('DEFAULTDIMPRIORITIES');
    end;

    procedure MarkBookingAsInvoicedWarningCode(): Code[50]
    begin
        exit('MARKBOOKINGASINVOICEDWARNING');
    end;

    procedure AutomaticLineItemsDialogCode(): Code[50]
    begin
        exit('AUTOMATICALLYCREATELINEITEMSFROMOUTLOOK');
    end;

    procedure GetClosingUnpostedDocumentNotificationId(): Guid
    begin
        exit('612A2701-4BBB-4C5B-B4C0-629D96B60644');
    end;

    procedure GetDocumentTypeInvoiceFilter(): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        exit(SalesHeader.GetView(false));
    end;

    procedure GetOpeningPostedDocumentNotificationId(): Guid
    begin
        exit('0C6ED8F1-7408-4352-8DD1-B9F17332607D');
    end;

    procedure GetMarkBookingAsInvoicedWarningNotificationId(): Guid
    begin
        exit('413A3221-D47F-4FBF-8822-0029AB41F9A6');
    end;

    procedure GetOfficeUpdateNotificationId(): Guid
    begin
        exit('882980DE-C2F6-4D4F-BF39-BB3A9FE3D7DA');
    end;

    procedure GetPostingAfterWorkingDateNotificationId(): Guid
    begin
        exit('F76D6004-5EC5-4DEA-B14D-71B2AEB53ACF');
    end;

    procedure GetClosingUnreleasedOrdersNotificationId(): Guid
    begin
        exit('F76D6004-3FD8-2ABC-B14D-61B2AEB53ACF');
    end;

    procedure GetDefaultDimPrioritiesNotificationId(): Guid
    begin
        exit('69CE42D9-0580-4907-8BC9-0EEB59DA96C9');
    end;

    procedure GetAutomaticLineItemsDialogNotificationId(): Guid
    begin
        exit('7FFD2619-BCEF-48F1-B5D1-469DCE5E6631');
    end;

    procedure GetClosingProductionBOMNotificationId(): Guid
    begin
        exit('FD2DAEAA-71CA-48D6-BEBA-E3BF3509D7FA');
    end;

    procedure InsertDefaultUnpostedDoucumentNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        OnBeforeInsertDefaultUnpostedDoucumentNotification(MyNotifications);
        MyNotifications.InsertDefaultWithTableNumAndFilter(GetClosingUnpostedDocumentNotificationId(),
          WarnUnpostedDocumentsTxt,
          WarnUnpostedDocumentsDescriptionTxt,
          DATABASE::"Sales Header",
          GetDocumentTypeInvoiceFilter());
    end;

    procedure ShowPostedDocument(RecVariant: Variant; CalledFromPageId: Integer)
    var
        RecRef: RecordRef;
        PageId: Integer;
    begin
        if not RecVariant.IsRecord then
            exit;

        RecRef.GetTable(RecVariant);
        case RecRef.Number of
            DataBase::"Sales Invoice Header":
                PageId := Page::"Posted Sales Invoice";
            DataBase::"Sales Cr.Memo Header":
                PageId := Page::"Posted Sales Credit Memo";
            DataBase::"Purch. Inv. Header":
                PageId := Page::"Posted Purchase Invoice";
            DataBase::"Purch. Cr. Memo Hdr.":
                PageId := Page::"Posted Purchase Credit Memo";
        end;
        OnShowPostedDocumentOnBeforePageRun(RecVariant, CalledFromPageId, PageId);
        Page.Run(PageId, RecVariant);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        InsertDefaultUnpostedDoucumentNotification();
        MyNotifications.InsertDefault(GetOpeningPostedDocumentNotificationId(),
          ConfirmAfterPostingDocumentsTxt,
          ConfirmAfterPostingDocumentsDescriptionTxt,
          IsEnabled(ShowPostedConfirmationMessageCode()));
        MyNotifications.InsertDefault(GetPostingAfterWorkingDateNotificationId(),
          ConfirmPostingAfterWorkingDateTxt,
          ConfirmPostingAfterWorkingDateDescriptionTxt,
          IsEnabled(PostingAfterWorkingDateNotAllowedCode()));
        MyNotifications.InsertDefault(GetMarkBookingAsInvoicedWarningNotificationId(),
          MarkBookingAsInvoicedWarningTxt,
          MarkBookingAsInvoicedWarningDescriptionTxt,
          IsEnabled(MarkBookingAsInvoicedWarningCode()));
        MyNotifications.InsertDefault(GetAutomaticLineItemsDialogNotificationId(),
          AutomaticLineItemsDialogNotificationTxt,
          AutomaticLineItemsDialogNotificationDescriptionTxt,
          IsEnabled(AutomaticLineItemsDialogCode()));
        MyNotifications.InsertDefault(GetOfficeUpdateNotificationId(),
          OfficeUpdateNotificationTxt,
          OfficeUpdateNotificationDescriptionTxt,
          IsEnabled(OfficeUpdateNotificationCode()));
        MyNotifications.InsertDefault(GetClosingUnreleasedOrdersNotificationId(),
          ClosingUnreleasedOrdersNotificationTxt,
          ClosingUnreleasedOrdersNotificationDescriptionTxt,
          IsEnabled(ClosingUnreleasedOrdersCode()));
        MyNotifications.InsertDefault(GetDefaultDimPrioritiesNotificationId(),
          DefaultDimPrioritiesMissingTxt,
          DefaultDimPrioritiesMissingDescriptionTxt,
          IsEnabled(DefaultDimPrioritiesCode()));
        MyNotifications.InsertDefault(GetClosingProductionBOMNotificationId(),
          ClosingProductionBOMRoutingsNotificationTxt,
          ClosingNoncertifiedProductionBOMRoutingNotificationDescriptionTxt,
          IsEnabled(ClosingNonCertifiedProductionBOMROUTINGCode()));
    end;

    [EventSubscriber(ObjectType::Table, Database::"My Notifications", 'OnAfterIsNotificationEnabled', '', false, false)]
    local procedure OnAfterIsNotificationEnabled(NotificationId: Guid)
    var
        MyNotifications: Record "My Notifications";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if MyNotifications.WritePermission then
            if NotificationId = InstructionMgt.GetClosingUnpostedDocumentNotificationId() then
                InstructionMgt.InsertDefaultUnpostedDoucumentNotification();
    end;

    [EventSubscriber(ObjectType::Table, Database::"My Notifications", 'OnStateChanged', '', false, false)]
    local procedure OnStateChanged(NotificationId: Guid; NewEnabledState: Boolean)
    begin
        case NotificationId of
            GetClosingUnpostedDocumentNotificationId():
                if NewEnabledState then
                    EnableMessageForCurrentUser(QueryPostOnCloseCode())
                else
                    DisableMessageForCurrentUser(QueryPostOnCloseCode());
            GetOpeningPostedDocumentNotificationId():
                if NewEnabledState then
                    EnableMessageForCurrentUser(ShowPostedConfirmationMessageCode())
                else
                    DisableMessageForCurrentUser(ShowPostedConfirmationMessageCode());
            GetAutomaticLineItemsDialogNotificationId():
                if NewEnabledState then
                    EnableMessageForCurrentUser(AutomaticLineItemsDialogCode())
                else
                    DisableMessageForCurrentUser(AutomaticLineItemsDialogCode());
            GetPostingAfterWorkingDateNotificationId():
                if NewEnabledState then
                    EnableMessageForCurrentUser(PostingAfterWorkingDateNotAllowedCode())
                else
                    DisableMessageForCurrentUser(PostingAfterWorkingDateNotAllowedCode());
            GetClosingUnreleasedOrdersNotificationId():
                if NewEnabledState then
                    EnableMessageForCurrentUser(ClosingUnreleasedOrdersCode())
                else
                    DisableMessageForCurrentUser(ClosingUnreleasedOrdersCode());
            GetDefaultDimPrioritiesNotificationId():
                if NewEnabledState then
                    EnableMessageForCurrentUser(DefaultDimPrioritiesCode())
                else
                    DisableMessageForCurrentUser(DefaultDimPrioritiesCode());
            GetClosingProductionBOMNotificationId():
                if NewEnabledState then
                    EnableMessageForCurrentUser(ClosingNonCertifiedProductionBOMROUTINGCode())
                else
                    DisableMessageForCurrentUser(ClosingNonCertifiedProductionBOMROUTINGCode());
        end;
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeIsUnpostedEnabledForRecord(RecVariant: Variant; var Enabled: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(InstructionType: Code[50]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertDefaultUnpostedDoucumentNotification(var MyNotifications: Record "My Notifications")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowPostedDocumentOnBeforePageRun(RecVariant: Variant; CalledFromPageId: Integer; var PageId: Integer)
    begin
    end;
}

