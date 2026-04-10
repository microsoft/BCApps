// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Setup;

/// <summary>
/// Implements posting group change validation and processing for customer, vendor, and employee posting groups.
/// Handles validation logic when posting groups are modified in documents and journal lines.
/// </summary>
/// <remarks>
/// Core implementation of posting group change validation ensuring data integrity and proper setup requirements.
/// Validates posting group changes across sales headers, purchase headers, general journal lines, and finance charge memos.
/// Integrates with substitute posting group setup to support alternative posting group configurations.
/// Extensible through the posting group change method interface for custom validation scenarios.
/// </remarks>
codeunit 960 "Posting Group Change" implements "Posting Group Change Method"
{
    var
        CannotChangePostingGroupErr: Label 'You cannot change the value %1 to %2 because %3 has not been filled in.', Comment = '%1 = old posting group; %2 = new posting group; %3 = tablecaption of Subst. Vendor/Customer Posting Group';

    /// <summary>
    /// Changes posting group with validation based on document type and substitute posting group setup.
    /// </summary>
    /// <param name="NewPostingGroup">New posting group code to apply</param>
    /// <param name="OldPostingGroup">Current posting group code</param>
    /// <param name="SourceRecordVar">Source record variant containing the posting group field</param>
    procedure ChangePostingGroup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; SourceRecordVar: Variant)
    var
        SourceRecordRef: RecordRef;
    begin
        if OldPostingGroup = NewPostingGroup then
            exit;

        SourceRecordRef.GetTable(SourceRecordVar);
        case SourceRecordRef.Number of
            Database::"Sales Header":
                CheckPostingGroupChangeInSalesHeader(NewPostingGroup, OldPostingGroup);
            Database::"Purchase Header":
                CheckPostingGroupChangeInPurchaseHeader(NewPostingGroup, OldPostingGroup);
            Database::"Gen. Journal Line":
                CheckPostingGroupChangeInGenJnlLine(NewPostingGroup, OldPostingGroup, SourceRecordVar);
            Database::"Finance Charge Memo Header":
                CheckPostingGroupChangeInFinChrgMemoHeader(NewPostingGroup, OldPostingGroup);
        end;

        OnAfterChangePostingGroup(SourceRecordRef, NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInSalesHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChange(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInPurchaseHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckVendorPostingGroupChange(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInGenJnlLine(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; GenJournalLine: Record "Gen. Journal Line")
    begin
        case GenJournalLine."Account Type" of
            GenJournalLine."Account Type"::Customer:
                CheckCustomerPostingGroupChangeAndCustomer(NewPostingGroup, OldPostingGroup, GenJournalLine."Account No.");
            GenJournalLine."Account Type"::Vendor:
                CheckVendorPostingGroupChangeAndVendor(NewPostingGroup, OldPostingGroup, GenJournalLine."Account No.");
            GenJournalLine."Account Type"::Employee:
                CheckEmployeePostingGroupChangeAndEmployee(NewPostingGroup, OldPostingGroup, GenJournalLine."Account No.");
            else
                GenJournalLine.FieldError(GenJournalLine."Account Type");
        end;
    end;

    local procedure CheckPostingGroupChangeInFinChrgMemoHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChange(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckCustomerPostingGroupChange(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChangeAndCustomer(NewPostingGroup, OldPostingGroup, '');
    end;

    local procedure CheckVendorPostingGroupChange(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckVendorPostingGroupChangeAndVendor(NewPostingGroup, OldPostingGroup, '');
    end;

    local procedure CheckCustomerPostingGroupChangeAndCustomer(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; CustomerNo: Code[20])
    begin
        CheckAllowChangeSalesSetup();
        if not HasCustomerSamePostingGroup(NewPostingGroup, CustomerNo) then
            CheckCustomerPostingGroupSubstSetup(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckVendorPostingGroupChangeAndVendor(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; VendorNo: Code[20])
    begin
        CheckAllowChangePurchaseSetup();
        if not HasVendorSamePostingGroup(NewPostingGroup, VendorNo) then
            CheckVendorPostingGroupSubstSetup(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckEmployeePostingGroupChangeAndEmployee(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; EmployeeNo: Code[20])
    begin
        CheckAllowChangeHRSetup();
        if not HasEmployeeSamePostingGroup(NewPostingGroup, EmployeeNo) then
            CheckEmployeePostingGroupSubstSetup(NewPostingGroup, OldPostingGroup);
    end;

    procedure CheckCustomerPostingGroupSubstSetup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    var
        AltCustomerPostingGroup: Record "Alt. Customer Posting Group";
    begin
        if not AltCustomerPostingGroup.Get(OldPostingGroup, NewPostingGroup) then
            Error(CannotChangePostingGroupErr, OldPostingGroup, NewPostingGroup, AltCustomerPostingGroup.TableCaption());
    end;

    /// <summary>
    /// Checks vendor posting group substitute setup before allowing posting group change.
    /// </summary>
    /// <param name="NewPostingGroup">New vendor posting group code</param>
    /// <param name="OldPostingGroup">Current vendor posting group code</param>
    procedure CheckVendorPostingGroupSubstSetup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    var
        AltVendorPostingGroup: Record "Alt. Vendor Posting Group";
    begin
        if not AltVendorPostingGroup.Get(OldPostingGroup, NewPostingGroup) then
            Error(CannotChangePostingGroupErr, OldPostingGroup, NewPostingGroup, AltVendorPostingGroup.TableCaption());
    end;

    /// <summary>
    /// Checks employee posting group substitute setup before allowing posting group change.
    /// </summary>
    /// <param name="NewPostingGroup">New employee posting group code</param>
    /// <param name="OldPostingGroup">Current employee posting group code</param>
    procedure CheckEmployeePostingGroupSubstSetup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    var
        AltEmployeePostingGroup: Record "Alt. Employee Posting Group";
    begin
        if not AltEmployeePostingGroup.Get(OldPostingGroup, NewPostingGroup) then
            Error(CannotChangePostingGroupErr, OldPostingGroup, NewPostingGroup, AltEmployeePostingGroup.TableCaption());
    end;

    /// <summary>
    /// Checks if sales and receivables setup allows multiple posting groups before changing customer posting groups.
    /// </summary>
    procedure CheckAllowChangeSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Allow Multiple Posting Groups");
        SalesReceivablesSetup.TestField("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
    end;


    /// <summary>
    /// Checks if purchases and payables setup allows multiple posting groups before changing vendor posting groups.
    /// </summary>
    procedure CheckAllowChangePurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("Allow Multiple Posting Groups");
        PurchasesPayablesSetup.TestField("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
    end;

    /// <summary>
    /// Checks if human resources setup allows multiple posting groups before changing employee posting groups.
    /// </summary>
    procedure CheckAllowChangeHRSetup()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("Allow Multiple Posting Groups");
        HumanResourcesSetup.TestField("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
    end;

    /// <summary>
    /// Checks if a customer already has the same posting group to avoid unnecessary validation.
    /// </summary>
    /// <param name="NewPostingGroup">New customer posting group code</param>
    /// <param name="CustomerNo">Customer number to check</param>
    /// <returns>True if customer already has the new posting group</returns>
    procedure HasCustomerSamePostingGroup(NewPostingGroup: Code[20]; CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(NewPostingGroup = Customer."Customer Posting Group");
        exit(false);
    end;

    /// <summary>
    /// Checks if a vendor already has the same posting group to avoid unnecessary validation.
    /// </summary>
    /// <param name="NewPostingGroup">New vendor posting group code</param>
    /// <param name="VendorNo">Vendor number to check</param>
    /// <returns>True if vendor already has the new posting group</returns>
    procedure HasVendorSamePostingGroup(NewPostingGroup: Code[20]; VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(NewPostingGroup = Vendor."Vendor Posting Group");
        exit(false);
    end;

    /// <summary>
    /// Checks if an employee already has the same posting group to avoid unnecessary validation.
    /// </summary>
    /// <param name="NewPostingGroup">New employee posting group code</param>
    /// <param name="EmployeeNo">Employee number to check</param>
    /// <returns>True if employee already has the new posting group</returns>
    procedure HasEmployeeSamePostingGroup(NewPostingGroup: Code[20]; EmployeeNo: Code[20]): Boolean
    var
        Employee: Record Employee;
    begin
        if Employee.Get(EmployeeNo) then
            exit(NewPostingGroup = Employee."Employee Posting Group");
        exit(false);
    end;

    /// <summary>
    /// Integration event raised after changing posting group to allow custom processing.
    /// </summary>
    /// <param name="SourceRecordRef">Record reference of the source record with changed posting group</param>
    /// <param name="NewPostingGroup">New posting group code that was applied</param>
    /// <param name="OldPostingGroup">Previous posting group code</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterChangePostingGroup(SourceRecordRef: RecordRef; NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
    end;
}
