// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Utilities;
using Microsoft.HumanResources.Employee;

codeunit 48 PostingSetupManagement
{

    trigger OnRun()
    begin
    end;

    var
        MyNotifications: Record "My Notifications";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        MissingAccountTxt: Label '%1 is missing in %2.', Comment = '%1 = Field caption, %2 = Table caption';
        SetupMissingAccountTxt: Label 'Set up missing account';
        MissingAccountNotificationTxt: Label 'G/L Account is missing in posting group or setup.';
        MissingAccountNotificationDescriptionTxt: Label 'Show a warning when required G/L Account is missing in posting group or setup.';
        NotAllowedToPostAfterWorkingDateErr: Label 'Cannot post because one or more transactions have dates after the working date.';

    procedure CheckCustPostingGroupReceivablesAccount(PostingGroup: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCustPostingGroupReceivablesAccount(PostingGroup, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() then
            exit;

        if not CustomerPostingGroup.Get(PostingGroup) then
            exit;

        if CustomerPostingGroup."Receivables Account" = '' then
            SendCustPostingGroupNotification(CustomerPostingGroup, CustomerPostingGroup.FieldCaption("Receivables Account"));
    end;

    procedure CheckVendPostingGroupPayablesAccount(PostingGroup: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVendPostingGroupPayablesAccount(PostingGroup, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() then
            exit;

        if not VendorPostingGroup.Get(PostingGroup) then
            exit;

        if VendorPostingGroup."Payables Account" = '' then
            SendVendPostingGroupNotification(VendorPostingGroup, VendorPostingGroup.FieldCaption("Payables Account"));
    end;

    procedure CheckGenPostingSetupSalesAccount(GenBusGroupCode: Code[20]; GenProdGroupCode: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGenPostingSetupSalesAccount(GenBusGroupCode, GenProdGroupCode, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() then
            exit;

        if not GenPostingSetup.Get(GenBusGroupCode, GenProdGroupCode) then
            if not CreateGenPostingSetup(GenBusGroupCode, GenProdGroupCode) then
                exit;

        if GenPostingSetup."Sales Account" = '' then
            SendGenPostingSetupNotification(GenPostingSetup, GenPostingSetup.FieldCaption("Sales Account"));
    end;

    procedure CheckGenPostingSetupPurchAccount(GenBusGroupCode: Code[20]; GenProdGroupCode: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGenPostingSetupPurchAccount(GenBusGroupCode, GenProdGroupCode, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() then
            exit;

        if not GenPostingSetup.Get(GenBusGroupCode, GenProdGroupCode) then
            if not CreateGenPostingSetup(GenBusGroupCode, GenProdGroupCode) then
                exit;

        if GenPostingSetup."Purch. Account" = '' then
            SendGenPostingSetupNotification(GenPostingSetup, GenPostingSetup.FieldCaption("Purch. Account"));
    end;

    procedure CheckGenPostingSetupCOGSAccount(GenBusGroupCode: Code[20]; GenProdGroupCode: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGenPostingSetupCOGSAccount(GenBusGroupCode, GenProdGroupCode, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() then
            exit;

        if not GenPostingSetup.Get(GenBusGroupCode, GenProdGroupCode) then
            if not CreateGenPostingSetup(GenBusGroupCode, GenProdGroupCode) then
                exit;

        if GenPostingSetup."COGS Account" = '' then
            SendGenPostingSetupNotification(GenPostingSetup, GenPostingSetup.FieldCaption("COGS Account"));
    end;

    procedure CheckVATPostingSetupSalesAccount(VATBusGroupCode: Code[20]; VATProdGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVATPostingSetupSalesAccount(VATBusGroupCode, VATProdGroupCode, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() then
            exit;

        if not VATPostingSetup.Get(VATBusGroupCode, VATProdGroupCode) then
            CreateVATPostingSetup(VATBusGroupCode, VATProdGroupCode);

        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Sales Tax" then
            exit;

        if VATPostingSetup."Sales VAT Account" = '' then
            SendVATPostingSetupNotification(VATPostingSetup, VATPostingSetup.FieldCaption("Sales VAT Account"));
    end;

    procedure CheckVATPostingSetupPurchAccount(VATBusGroupCode: Code[20]; VATProdGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVATPostingSetupPurchAccount(VATBusGroupCode, VATProdGroupCode, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() then
            exit;

        if not VATPostingSetup.Get(VATBusGroupCode, VATProdGroupCode) then
            CreateVATPostingSetup(VATBusGroupCode, VATProdGroupCode);

        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Sales Tax" then
            exit;

        if VATPostingSetup."Purchase VAT Account" = '' then
            SendVATPostingSetupNotification(VATPostingSetup, VATPostingSetup.FieldCaption("Purchase VAT Account"));
    end;

    procedure CheckInvtPostingSetupInventoryAccount(LocationCode: Code[10]; PostingGroup: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        InventoryPostingSetup2: Record "Inventory Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInvtPostingSetupInventoryAccount(LocationCode, PostingGroup, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() or not InventoryPostingSetup2.WritePermission() then
            exit;

        if not InventoryPostingSetup.Get(LocationCode, PostingGroup) then
            CreateInvtPostingSetup(LocationCode, PostingGroup);

        if InventoryPostingSetup."Inventory Account" = '' then
            SendInvtPostingSetupNotification(InventoryPostingSetup, InventoryPostingSetup.FieldCaption("Inventory Account"));
    end;

    procedure GetPostingSetupNotificationID(): Guid
    begin
        exit('7c2a2ca8-bdf7-4428-b520-ed17887ff30c');
    end;

    procedure ConfirmPostingAfterWorkingDate(ConfirmQst: Text; PostingDate: Date): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        InstructionMgt: Codeunit "Instruction Mgt.";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeConfirmPostingAfterWorkingDate(ConfirmQst, PostingDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if AccountingPeriod.IsEmpty() then
            exit(true);
        if GuiAllowed and
           InstructionMgt.IsMyNotificationEnabled(InstructionMgt.GetPostingAfterWorkingDateNotificationId())
        then
            if PostingDate > WorkDate() then begin
                if Confirm(ConfirmQst, false) then
                    exit(true);
                Error(NotAllowedToPostAfterWorkingDateErr);
            end;
    end;

    local procedure CreateGenPostingSetup(GenBusGroupCode: Code[20]; GenProdGroupCode: Code[20]): Boolean
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        if GenProdGroupCode = '' then
            exit(false);
        GenPostingSetup.Init();
        GenPostingSetup.Validate("Gen. Bus. Posting Group", GenBusGroupCode);
        GenPostingSetup.Validate("Gen. Prod. Posting Group", GenProdGroupCode);
        GenPostingSetup.Blocked := true;
        GenPostingSetup.Insert();
        exit(true);
    end;

    local procedure CreateVATPostingSetup(VATBusGroupCode: Code[20]; VATProdGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusGroupCode);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProdGroupCode);
        VATPostingSetup.Blocked := true;
        VATPostingSetup.Insert();
    end;

    local procedure CreateInvtPostingSetup(LocationCode: Code[10]; PostingGroupCode: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Location Code", LocationCode);
        InventoryPostingSetup.Validate("Invt. Posting Group Code", PostingGroupCode);
        InventoryPostingSetup.Insert();
    end;

    procedure IsPostingSetupNotificationEnabled(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        exit(InstructionMgt.IsMyNotificationEnabled(GetPostingSetupNotificationID()));
    end;

    local procedure SendPostingSetupNotification(NotificationMsg: Text; ActionMsg: Text; ActionName: Text; GroupCode1: Code[20]; GroupCode2: Code[20])
    var
        SendNotification: Notification;
    begin
        SendNotification.Id := CreateGuid();
        SendNotification.Message(NotificationMsg);
        SendNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        SendNotification.SetData('GroupCode1', GroupCode1);
        if GroupCode2 <> '' then
            SendNotification.SetData('GroupCode2', GroupCode2);
        SendNotification.AddAction(ActionMsg, CODEUNIT::PostingSetupManagement, ActionName);
        SendNotification.Send();
    end;

    procedure SendCustPostingGroupNotification(CustomerPostingGroup: Record "Customer Posting Group"; FieldCaption: Text)
    begin
        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, CustomerPostingGroup.TableCaption()),
          SetupMissingAccountTxt, 'ShowCustomerPostingGroups', CustomerPostingGroup.Code, '');
    end;

    procedure SendVendPostingGroupNotification(VendorPostingGroup: Record "Vendor Posting Group"; FieldCaption: Text)
    begin
        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, VendorPostingGroup.TableCaption()),
          SetupMissingAccountTxt, 'ShowVendorPostingGroups', VendorPostingGroup.Code, '');
    end;

    procedure SendInvtPostingSetupNotification(InvtPostingSetup: Record "Inventory Posting Setup"; FieldCaption: Text)
    begin
        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, InvtPostingSetup.TableCaption()),
          SetupMissingAccountTxt, 'ShowInventoryPostingSetup',
          InvtPostingSetup."Invt. Posting Group Code", InvtPostingSetup."Location Code");
    end;

    procedure SendGenPostingSetupNotification(GenPostingSetup: Record "General Posting Setup"; FieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendGenPostingSetupNotification(GenPostingSetup, FieldCaption, IsHandled);
        if IsHandled then
            exit;

        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, GenPostingSetup.TableCaption()),
          SetupMissingAccountTxt, 'ShowGenPostingSetup',
          GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
    end;

    procedure LogVATPostingSetupFieldError(VATPostingSetup: Record "VAT Posting Setup"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VATPostingSetup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    procedure LogGenPostingSetupFieldError(GenPostingSetup: Record "General Posting Setup"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GenPostingSetup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    procedure LogInventoryPostingSetupFieldError(InventoryPostingSetup: Record "Inventory Posting Setup"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(InventoryPostingSetup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    procedure LogCustPostingGroupFieldError(CustomerPostingGroup: Record "Customer Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustomerPostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    procedure LogVendPostingGroupFieldError(VendorPostingGroup: Record "Vendor Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VendorPostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    procedure LogEmplPostingGroupFieldError(EmployeePostingGroup: Record "Employee Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(EmployeePostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    procedure LogJobPostingGroupFieldError(JobPostingGroup: Record "Job Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(JobPostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    procedure LogFAPostingGroupFieldError(FAPostingGroup: Record "FA Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(FAPostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    local procedure LogContextFieldError(var RecRef: RecordRef; FieldNumber: Integer)
    var
        FldRef: FieldRef;
    begin
        FldRef := RecRef.Field(FieldNumber);

        ErrorMessageMgt.LogContextFieldError(
              0, StrSubstNo(MissingAccountTxt, FldRef.Caption, GetRecordIdDescription(RecRef)),
              RecRef.RecordId, FieldNumber,
              ForwardLinkMgt.GetHelpCodeForEmptyPostingSetupAccount());
    end;

    local procedure GetRecordIdDescription(RecRef: RecordRef): Text
    begin
        RecRef.Reset();
        RecRef.SetRecFilter();
        exit(RecRef.Caption() + ' ' + RecRef.GetFilters());
    end;

    procedure SendVATPostingSetupNotification(VATPostingSetup: Record "VAT Posting Setup"; FieldCaption: Text)
    begin
        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, VATPostingSetup.TableCaption()),
          SetupMissingAccountTxt, 'ShowVATPostingSetup',
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    procedure ShowCustomerPostingGroups(SetupNotification: Notification)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerPostingGroups: Page "Customer Posting Groups";
        PostingGroupCode: Code[20];
    begin
        Clear(CustomerPostingGroups);
        PostingGroupCode := SetupNotification.GetData('GroupCode1');
        if PostingGroupCode <> '' then begin
            CustomerPostingGroup.Get(PostingGroupCode);
            CustomerPostingGroups.SetRecord(CustomerPostingGroup);
        end;
        CustomerPostingGroups.SetTableView(CustomerPostingGroup);
        CustomerPostingGroups.RunModal();
    end;

    procedure ShowVendorPostingGroups(SetupNotification: Notification)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroups: Page "Vendor Posting Groups";
        PostingGroupCode: Code[20];
    begin
        Clear(VendorPostingGroups);
        PostingGroupCode := SetupNotification.GetData('GroupCode1');
        if PostingGroupCode <> '' then begin
            VendorPostingGroup.Get(PostingGroupCode);
            VendorPostingGroups.SetRecord(VendorPostingGroup);
        end;
        VendorPostingGroups.SetTableView(VendorPostingGroup);
        VendorPostingGroups.RunModal();
    end;

    procedure ShowInventoryPostingSetup(SetupNotification: Notification)
    var
        InventoryPostingSetupRec: Record "Inventory Posting Setup";
        InventoryPostingSetupPage: Page "Inventory Posting Setup";
        PostingGroupCode: Code[20];
        LocationCode: Code[10];
    begin
        Clear(InventoryPostingSetupPage);
        PostingGroupCode := SetupNotification.GetData('GroupCode1');
        LocationCode := SetupNotification.GetData('GroupCode2');
        if PostingGroupCode <> '' then begin
            InventoryPostingSetupRec.Get(LocationCode, PostingGroupCode);
            InventoryPostingSetupPage.SetRecord(InventoryPostingSetupRec);
        end;
        InventoryPostingSetupPage.SetTableView(InventoryPostingSetupRec);
        InventoryPostingSetupPage.RunModal();
    end;

    procedure ShowGenPostingSetup(SetupNotification: Notification)
    var
        GenPostingSetupRec: Record "General Posting Setup";
        GenPostingSetupPage: Page "General Posting Setup";
        BusPostingGroupCode: Code[20];
        ProdPostingGroupCode: Code[20];
    begin
        Clear(GenPostingSetupPage);
        BusPostingGroupCode := SetupNotification.GetData('GroupCode1');
        ProdPostingGroupCode := SetupNotification.GetData('GroupCode2');
        if ProdPostingGroupCode <> '' then begin
            GenPostingSetupRec.Get(BusPostingGroupCode, ProdPostingGroupCode);
            GenPostingSetupPage.SetRecord(GenPostingSetupRec);
        end;
        GenPostingSetupPage.SetTableView(GenPostingSetupRec);
        GenPostingSetupPage.RunModal();
    end;

    procedure ShowVATPostingSetup(SetupNotification: Notification)
    var
        VATPostingSetupRec: Record "VAT Posting Setup";
        VATPostingSetupPage: Page "VAT Posting Setup";
        BusPostingGroupCode: Code[20];
        ProdPostingGroupCode: Code[20];
    begin
        Clear(VATPostingSetupPage);
        BusPostingGroupCode := SetupNotification.GetData('GroupCode1');
        ProdPostingGroupCode := SetupNotification.GetData('GroupCode2');
        if ProdPostingGroupCode <> '' then begin
            VATPostingSetupRec.Get(BusPostingGroupCode, ProdPostingGroupCode);
            VATPostingSetupPage.SetRecord(VATPostingSetupRec);
        end;
        VATPostingSetupPage.SetTableView(VATPostingSetupRec);
        VATPostingSetupPage.RunModal();
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    begin
        MyNotifications.InsertDefault(
          GetPostingSetupNotificationID(), MissingAccountNotificationTxt, MissingAccountNotificationDescriptionTxt, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvtPostingSetupInventoryAccount(var LocationCode: Code[10]; var PostingGroup: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVATPostingSetupSalesAccount(VATBusGroupCode: Code[20]; VATProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenPostingSetupCOGSAccount(var GenBusGroupCode: Code[20]; var GenProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVATPostingSetupPurchAccount(var VATBusGroupCode: Code[20]; var VATProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenPostingSetupSalesAccount(var GenBusGroupCode: Code[20]; var GenProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustPostingGroupReceivablesAccount(var PostingGroup: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVendPostingGroupPayablesAccount(var PostingGroup: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostingAfterWorkingDate(var ConfirmQst: Text; var PostingDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenPostingSetupPurchAccount(var GenBusGroupCode: Code[20]; var GenProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendGenPostingSetupNotification(GenPostingSetup: Record "General Posting Setup"; FieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
}

