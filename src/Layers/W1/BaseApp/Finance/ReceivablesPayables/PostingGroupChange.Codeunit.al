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

codeunit 960 "Posting Group Change" implements "Posting Group Change Method"
{
    var
        CannotChangePostingGroupErr: Label 'You cannot change the value %1 to %2 because %3 has not been filled in.', Comment = '%1 = old posting group; %2 = new posting group; %3 = tablecaption of Subst. Vendor/Customer Posting Group';

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

    procedure CheckVendorPostingGroupSubstSetup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    var
        AltVendorPostingGroup: Record "Alt. Vendor Posting Group";
    begin
        if not AltVendorPostingGroup.Get(OldPostingGroup, NewPostingGroup) then
            Error(CannotChangePostingGroupErr, OldPostingGroup, NewPostingGroup, AltVendorPostingGroup.TableCaption());
    end;

    procedure CheckEmployeePostingGroupSubstSetup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    var
        AltEmployeePostingGroup: Record "Alt. Employee Posting Group";
    begin
        if not AltEmployeePostingGroup.Get(OldPostingGroup, NewPostingGroup) then
            Error(CannotChangePostingGroupErr, OldPostingGroup, NewPostingGroup, AltEmployeePostingGroup.TableCaption());
    end;

    procedure CheckAllowChangeSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Allow Multiple Posting Groups");
        SalesReceivablesSetup.TestField("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure CheckAllowChangeServiceSetup() in codeunit "Serv. Posting Group Change"', '25.0')]
    procedure CheckAllowChangeServiceSetup()
    var
        ServiceMgtSetup: Record Microsoft.Service.Setup."Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.TestField("Allow Multiple Posting Groups");
        ServiceMgtSetup.TestField("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
    end;
#endif

    procedure CheckAllowChangePurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("Allow Multiple Posting Groups");
        PurchasesPayablesSetup.TestField("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
    end;

    procedure CheckAllowChangeHRSetup()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("Allow Multiple Posting Groups");
        HumanResourcesSetup.TestField("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
    end;

    procedure HasCustomerSamePostingGroup(NewPostingGroup: Code[20]; CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(NewPostingGroup = Customer."Customer Posting Group");
        exit(false);
    end;

    procedure HasVendorSamePostingGroup(NewPostingGroup: Code[20]; VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(NewPostingGroup = Vendor."Vendor Posting Group");
        exit(false);
    end;

    procedure HasEmployeeSamePostingGroup(NewPostingGroup: Code[20]; EmployeeNo: Code[20]): Boolean
    var
        Employee: Record Employee;
    begin
        if Employee.Get(EmployeeNo) then
            exit(NewPostingGroup = Employee."Employee Posting Group");
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangePostingGroup(SourceRecordRef: RecordRef; NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
    end;
}

