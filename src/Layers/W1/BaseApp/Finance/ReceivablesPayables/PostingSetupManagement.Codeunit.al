// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Utilities;

/// <summary>
/// Manages validation and setup of posting group accounts and configurations for financial transactions.
/// Provides comprehensive validation of G/L account setup in posting groups with error messaging and notification handling.
/// </summary>
/// <remarks>
/// Core validation engine for posting group account completeness across customer, vendor, item, and other posting groups.
/// Integrates with error message management and notification systems for setup guidance.
/// Supports various transaction types including sales, purchases, inventory, and fixed assets.
/// Extensible through validation events for custom posting group requirements and account verification.
/// </remarks>
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

    /// <summary>
    /// Validates that the receivables account is configured in the specified customer posting group.
    /// Sends notification if the receivables account is missing and notifications are enabled.
    /// </summary>
    /// <param name="PostingGroup">Customer posting group code to validate</param>
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

    /// <summary>
    /// Validates that the payables account is configured in the specified vendor posting group.
    /// Sends notification if the payables account is missing and notifications are enabled.
    /// </summary>
    /// <param name="PostingGroup">Vendor posting group code to validate</param>
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

    /// <summary>
    /// Checks if sales account is properly configured in general posting setup.
    /// Validates sales account setup and sends notification if configuration is missing.
    /// </summary>
    /// <param name="GenBusGroupCode">General business posting group code</param>
    /// <param name="GenProdGroupCode">General product posting group code</param>
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

    /// <summary>
    /// Checks if purchase account is properly configured in general posting setup.
    /// Validates purchase account setup and sends notification if configuration is missing.
    /// </summary>
    /// <param name="GenBusGroupCode">General business posting group code</param>
    /// <param name="GenProdGroupCode">General product posting group code</param>
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

    /// <summary>
    /// Checks if Cost of Goods Sold account is properly configured in general posting setup.
    /// Validates COGS account setup and sends notification if configuration is missing.
    /// </summary>
    /// <param name="GenBusGroupCode">General business posting group code</param>
    /// <param name="GenProdGroupCode">General product posting group code</param>
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

    /// <summary>
    /// Checks if sales VAT account is properly configured in VAT posting setup.
    /// Validates sales VAT account setup and sends notification if configuration is missing.
    /// </summary>
    /// <param name="VATBusGroupCode">VAT business posting group code</param>
    /// <param name="VATProdGroupCode">VAT product posting group code</param>
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

    /// <summary>
    /// Checks if purchase VAT account is properly configured in VAT posting setup.
    /// Validates purchase VAT account setup and sends notification if configuration is missing.
    /// </summary>
    /// <param name="VATBusGroupCode">VAT business posting group code</param>
    /// <param name="VATProdGroupCode">VAT product posting group code</param>
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

    /// <summary>
    /// Checks if inventory account is properly configured in inventory posting setup.
    /// Validates inventory account setup and sends notification if configuration is missing.
    /// </summary>
    /// <param name="LocationCode">Location code for inventory posting</param>
    /// <param name="PostingGroup">Inventory posting group code</param>
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

    /// <summary>
    /// Gets the unique notification ID for posting setup notifications.
    /// Returns the GUID used to identify posting setup notification messages.
    /// </summary>
    /// <returns>GUID for posting setup notifications</returns>
    procedure GetPostingSetupNotificationID(): Guid
    begin
        exit('7c2a2ca8-bdf7-4428-b520-ed17887ff30c');
    end;

    /// <summary>
    /// Confirms posting operation when posting date is after working date.
    /// Shows confirmation dialog and manages instruction settings for future confirmations.
    /// </summary>
    /// <param name="ConfirmQst">Question text to display in confirmation dialog</param>
    /// <param name="PostingDate">Posting date to validate against working date</param>
    /// <returns>True if user confirms posting, false otherwise</returns>
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

    /// <summary>
    /// Checks if posting setup notifications are enabled for the current user.
    /// Returns notification setting status for posting setup validation warnings.
    /// </summary>
    /// <returns>True if notifications are enabled, false otherwise</returns>
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

    /// <summary>
    /// Sends notification for missing customer posting group account configuration.
    /// Displays user notification when customer posting group account setup is incomplete.
    /// </summary>
    /// <param name="CustomerPostingGroup">Customer posting group with missing account</param>
    /// <param name="FieldCaption">Field caption for the missing account</param>
    procedure SendCustPostingGroupNotification(CustomerPostingGroup: Record "Customer Posting Group"; FieldCaption: Text)
    begin
        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, CustomerPostingGroup.TableCaption()),
          SetupMissingAccountTxt, 'ShowCustomerPostingGroups', CustomerPostingGroup.Code, '');
    end;

    /// <summary>
    /// Sends notification for missing vendor posting group account configuration.
    /// Displays user notification when vendor posting group account setup is incomplete.
    /// </summary>
    /// <param name="VendorPostingGroup">Vendor posting group with missing account</param>
    /// <param name="FieldCaption">Field caption for the missing account</param>
    procedure SendVendPostingGroupNotification(VendorPostingGroup: Record "Vendor Posting Group"; FieldCaption: Text)
    begin
        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, VendorPostingGroup.TableCaption()),
          SetupMissingAccountTxt, 'ShowVendorPostingGroups', VendorPostingGroup.Code, '');
    end;

    /// <summary>
    /// Sends notification for missing inventory posting setup account configuration.
    /// Displays user notification when inventory posting setup account is incomplete.
    /// </summary>
    /// <param name="InvtPostingSetup">Inventory posting setup with missing account</param>
    /// <param name="FieldCaption">Field caption for the missing account</param>
    procedure SendInvtPostingSetupNotification(InvtPostingSetup: Record "Inventory Posting Setup"; FieldCaption: Text)
    begin
        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, InvtPostingSetup.TableCaption()),
          SetupMissingAccountTxt, 'ShowInventoryPostingSetup',
          InvtPostingSetup."Invt. Posting Group Code", InvtPostingSetup."Location Code");
    end;

    /// <summary>
    /// Sends notification for missing general posting setup account configuration.
    /// Displays user notification when general posting setup account is incomplete.
    /// </summary>
    /// <param name="GenPostingSetup">General posting setup with missing account</param>
    /// <param name="FieldCaption">Field caption for the missing account</param>
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

    /// <summary>
    /// Logs field error for VAT posting setup configuration issues.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record with the error</param>
    /// <param name="FieldNumber">Field number that has the error</param>
    procedure LogVATPostingSetupFieldError(VATPostingSetup: Record "VAT Posting Setup"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VATPostingSetup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    /// <summary>
    /// Logs field error for general posting setup configuration issues.
    /// </summary>
    /// <param name="GenPostingSetup">General posting setup record with the error</param>
    /// <param name="FieldNumber">Field number that has the error</param>
    procedure LogGenPostingSetupFieldError(GenPostingSetup: Record "General Posting Setup"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GenPostingSetup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    /// <summary>
    /// Logs field error for inventory posting setup configuration issues.
    /// </summary>
    /// <param name="InventoryPostingSetup">Inventory posting setup record with the error</param>
    /// <param name="FieldNumber">Field number that has the error</param>
    procedure LogInventoryPostingSetupFieldError(InventoryPostingSetup: Record "Inventory Posting Setup"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(InventoryPostingSetup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    /// <summary>
    /// Logs field error for customer posting group configuration issues.
    /// </summary>
    /// <param name="CustomerPostingGroup">Customer posting group record with the error</param>
    /// <param name="FieldNumber">Field number that has the error</param>
    procedure LogCustPostingGroupFieldError(CustomerPostingGroup: Record "Customer Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustomerPostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    /// <summary>
    /// Logs field error for vendor posting group configuration issues.
    /// </summary>
    /// <param name="VendorPostingGroup">Vendor posting group record with the error</param>
    /// <param name="FieldNumber">Field number that has the error</param>
    procedure LogVendPostingGroupFieldError(VendorPostingGroup: Record "Vendor Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VendorPostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    /// <summary>
    /// Logs field error for employee posting group configuration issues.
    /// </summary>
    /// <param name="EmployeePostingGroup">Employee posting group record with the error</param>
    /// <param name="FieldNumber">Field number that has the error</param>
    procedure LogEmplPostingGroupFieldError(EmployeePostingGroup: Record "Employee Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(EmployeePostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    /// <summary>
    /// Logs field error for job posting group configuration issues.
    /// </summary>
    /// <param name="JobPostingGroup">Job posting group record with the error</param>
    /// <param name="FieldNumber">Field number that has the error</param>
    procedure LogJobPostingGroupFieldError(JobPostingGroup: Record "Job Posting Group"; FieldNumber: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(JobPostingGroup);

        LogContextFieldError(RecRef, FieldNumber);
    end;

    /// <summary>
    /// Logs field error for fixed asset posting group configuration issues.
    /// </summary>
    /// <param name="FAPostingGroup">Fixed asset posting group record with the error</param>
    /// <param name="FieldNumber">Field number that has the error</param>
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

    /// <summary>
    /// Sends notification for missing VAT posting setup configuration.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record with missing account</param>
    /// <param name="FieldCaption">Caption of the missing field</param>
    procedure SendVATPostingSetupNotification(VATPostingSetup: Record "VAT Posting Setup"; FieldCaption: Text)
    begin
        if not IsPostingSetupNotificationEnabled() then
            exit;

        SendPostingSetupNotification(
          StrSubstNo(MissingAccountTxt, FieldCaption, VATPostingSetup.TableCaption()),
          SetupMissingAccountTxt, 'ShowVATPostingSetup',
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    /// <summary>
    /// Shows customer posting groups page from setup notification.
    /// </summary>
    /// <param name="SetupNotification">Notification containing posting group information</param>
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

    /// <summary>
    /// Shows vendor posting groups page from setup notification.
    /// </summary>
    /// <param name="SetupNotification">Notification containing posting group information</param>
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

    /// <summary>
    /// Shows inventory posting setup page from setup notification.
    /// </summary>
    /// <param name="SetupNotification">Notification containing posting setup information</param>
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

    /// <summary>
    /// Shows general posting setup page from setup notification.
    /// </summary>
    /// <param name="SetupNotification">Notification containing posting setup information</param>
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

    /// <summary>
    /// Shows VAT posting setup page from setup notification.
    /// </summary>
    /// <param name="SetupNotification">Notification containing VAT posting setup information</param>
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

    /// <summary>
    /// Integration event raised before checking inventory posting setup inventory account.
    /// </summary>
    /// <param name="LocationCode">Location code for inventory posting setup</param>
    /// <param name="PostingGroup">Inventory posting group code</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvtPostingSetupInventoryAccount(var LocationCode: Code[10]; var PostingGroup: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking VAT posting setup sales account.
    /// </summary>
    /// <param name="VATBusGroupCode">VAT business posting group code</param>
    /// <param name="VATProdGroupCode">VAT product posting group code</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVATPostingSetupSalesAccount(VATBusGroupCode: Code[20]; VATProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking general posting setup COGS account.
    /// </summary>
    /// <param name="GenBusGroupCode">General business posting group code</param>
    /// <param name="GenProdGroupCode">General product posting group code</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenPostingSetupCOGSAccount(var GenBusGroupCode: Code[20]; var GenProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking VAT posting setup purchase account.
    /// </summary>
    /// <param name="VATBusGroupCode">VAT business posting group code</param>
    /// <param name="VATProdGroupCode">VAT product posting group code</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVATPostingSetupPurchAccount(var VATBusGroupCode: Code[20]; var VATProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking general posting setup sales account.
    /// </summary>
    /// <param name="GenBusGroupCode">General business posting group code</param>
    /// <param name="GenProdGroupCode">General product posting group code</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenPostingSetupSalesAccount(var GenBusGroupCode: Code[20]; var GenProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking customer posting group receivables account.
    /// </summary>
    /// <param name="PostingGroup">Customer posting group code</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustPostingGroupReceivablesAccount(var PostingGroup: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking vendor posting group payables account.
    /// </summary>
    /// <param name="PostingGroup">Vendor posting group code</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVendPostingGroupPayablesAccount(var PostingGroup: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before confirming posting after working date.
    /// </summary>
    /// <param name="ConfirmQst">Confirmation question text</param>
    /// <param name="PostingDate">Posting date to validate</param>
    /// <param name="Result">Confirmation result</param>
    /// <param name="IsHandled">Set to true to skip standard confirmation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostingAfterWorkingDate(var ConfirmQst: Text; var PostingDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking general posting setup purchase account.
    /// </summary>
    /// <param name="GenBusGroupCode">General business posting group code</param>
    /// <param name="GenProdGroupCode">General product posting group code</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenPostingSetupPurchAccount(var GenBusGroupCode: Code[20]; var GenProdGroupCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before sending general posting setup notification.
    /// </summary>
    /// <param name="GenPostingSetup">General posting setup record</param>
    /// <param name="FieldCaption">Caption of the missing field</param>
    /// <param name="IsHandled">Set to true to skip standard notification</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendGenPostingSetupNotification(GenPostingSetup: Record "General Posting Setup"; FieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
}

