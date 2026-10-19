// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 6931 "Expense Vendor Matching"
{
    Access = Internal;
    Permissions = tabledata Vendor = rim;

    var
        VendorCreatedMsg: Label 'Vendor %1 has been created.', Comment = '%1 = Vendor No.';
        AlreadyApprovedErr: Label 'Expense Vendor %1 is already approved.', Comment = '%1 = Expense Vendor No.';
        NameRequiredErr: Label 'A name is required before the expense vendor can be approved.';
        RejectReasonRequiredErr: Label 'A rejection reason is required.';
        ApproveConfirmQst: Label 'Do you want to approve expense vendor %1 and create a new Business Central vendor?', Comment = '%1 = Expense Vendor No.';
        ApproveMatchedConfirmQst: Label 'Do you want to approve expense vendor %1 as matched to vendor %2?', Comment = '%1 = Expense Vendor No., %2 = Vendor No.';
        RejectConfirmQst: Label 'Do you want to reject expense vendor %1?', Comment = '%1 = Expense Vendor No.';
        RequestApprovalConfirmQst: Label 'Do you want to submit expense vendor %1 for approval?', Comment = '%1 = Expense Vendor No.';

    // -----------------------------------------------------------------------
    // Auto-matching: triggered when a new Expense record is inserted
    // -----------------------------------------------------------------------
    [EventSubscriber(ObjectType::Table, Database::Expense, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterExpenseInsert(var Rec: Record Expense; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        // Honor Insert(false) and other "no trigger" insert paths to avoid side effects.
        if not RunTrigger then
            exit;

        if Rec."Merchant Name" = '' then
            exit;

        FindOrCreateExpenseVendor(Rec);
    end;

    // -----------------------------------------------------------------------
    // Public procedures
    // -----------------------------------------------------------------------

    /// <summary>
    /// Tries to match the expense to an existing Business Central vendor or creates
    /// an Expense Vendor record for accountant review. Updates Expense."Expense Vendor No.".
    /// </summary>
    procedure FindOrCreateExpenseVendor(var Expense: Record Expense)
    var
        ExpenseVendor: Record "Expense Vendor";
    begin
        if Expense."Merchant Name" = '' then
            exit;
        if Expense."Expense Vendor No." <> '' then
            exit; // already linked

        // If a matching Expense Vendor record already exists (same merchant), reuse it
        if TryFindExpenseVendorByMerchantData(Expense, ExpenseVendor) then begin
            LinkExpenseToExpenseVendor(Expense, ExpenseVendor."No.");
            exit;
        end;

        // Try to auto-match to an existing BC Vendor
        if TryAutoMatchToVendor(Expense) then
            exit;

        // No match found – create an Expense Vendor for accountant review
        CreateExpenseVendorFromExpense(Expense);
    end;

    /// <summary>
    /// Submits the expense vendor for accountant approval (Unmatched/Rejected → Pending Approval).
    /// </summary>
    procedure RequestApproval(var ExpenseVendor: Record "Expense Vendor")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not (ExpenseVendor.Status in [ExpenseVendor.Status::Unmatched, ExpenseVendor.Status::Rejected]) then
            exit;

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RequestApprovalConfirmQst, ExpenseVendor."No."), true) then
            exit;

        if ExpenseVendor.Name = '' then
            Error(NameRequiredErr);
        ExpenseVendor.Status := ExpenseVendor.Status::"Pending Approval";
        ExpenseVendor.Modify(true);
    end;

    /// <summary>
    /// Approves the expense vendor. Creates a new BC Vendor if not yet matched, or confirms the existing match.
    /// </summary>
    procedure Approve(var ExpenseVendor: Record "Expense Vendor")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NewVendorNo: Code[20];
    begin
        if ExpenseVendor.Status = ExpenseVendor.Status::Approved then
            Error(AlreadyApprovedErr, ExpenseVendor."No.");

        ExpenseVendor.TestField(Name);

        if ExpenseVendor.Status = ExpenseVendor.Status::Matched then begin
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ApproveMatchedConfirmQst, ExpenseVendor."No.", ExpenseVendor."Vendor No."), true) then
                exit;
            NewVendorNo := ExpenseVendor."Vendor No.";
        end else begin
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ApproveConfirmQst, ExpenseVendor."No."), true) then
                exit;
            NewVendorNo := CreateVendor(ExpenseVendor);
            Message(VendorCreatedMsg, NewVendorNo);
        end;

        ExpenseVendor.Status := ExpenseVendor.Status::Approved;
        ExpenseVendor."Vendor No." := NewVendorNo;
        ExpenseVendor."Approved By" := CopyStr(UserId(), 1, MaxStrLen(ExpenseVendor."Approved By"));
        ExpenseVendor."Approval Date" := Today();
        ExpenseVendor."Rejection Reason" := '';
        ExpenseVendor.Modify(true);
    end;

    /// <summary>
    /// Rejects the expense vendor with a mandatory reason.
    /// </summary>
    procedure Reject(var ExpenseVendor: Record "Expense Vendor"; RejectReason: Text[250])
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if RejectReason = '' then
            Error(RejectReasonRequiredErr);

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RejectConfirmQst, ExpenseVendor."No."), true) then
            exit;

        ExpenseVendor.Status := ExpenseVendor.Status::Rejected;
        ExpenseVendor."Rejection Reason" := RejectReason;
        ExpenseVendor."Approved By" := '';
        ExpenseVendor."Approval Date" := 0D;
        ExpenseVendor.Modify(true);
    end;

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------

    local procedure TryFindExpenseVendorByMerchantData(var Expense: Record Expense; var ExpenseVendor: Record "Expense Vendor"): Boolean
    var
        VendorFound: Boolean;
    begin
        if Expense."Merchant Registration No." <> '' then begin
            ExpenseVendor.SetRange("Registration Number", Expense."Merchant Registration No.");
            if ExpenseVendor.FindFirst() then begin
                ExpenseVendor.Reset();
                VendorFound := true;
            end;
            ExpenseVendor.Reset();
        end;

        if (not VendorFound) and (Expense."Merchant VAT Registration No." <> '') then begin
            ExpenseVendor.SetRange("VAT Registration No.", Expense."Merchant VAT Registration No.");
            if ExpenseVendor.FindFirst() then begin
                ExpenseVendor.Reset();
                VendorFound := true;
            end;
            ExpenseVendor.Reset();
        end;

        exit(VendorFound);
    end;

    local procedure TryAutoMatchToVendor(var Expense: Record Expense): Boolean
    var
        Vendor: Record Vendor;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseVendor: Record "Expense Vendor";
        NoSeriesManagement: Codeunit "No. Series";
    begin
        if Expense."Merchant VAT Registration No." <> '' then begin
            Vendor.SetRange("VAT Registration No.", Expense."Merchant VAT Registration No.");
            if Vendor.FindFirst() then begin
                CreateMatchedExpenseVendor(Expense, Vendor, ExpenseAgentSetup, NoSeriesManagement, ExpenseVendor);
                exit(true);
            end;
            Vendor.Reset();
        end;

        if Expense."Merchant Name" <> '' then begin
            Vendor.SetRange(Name, CopyStr(Expense."Merchant Name", 1, MaxStrLen(Vendor.Name)));
            if Vendor.FindFirst() then begin
                CreateMatchedExpenseVendor(Expense, Vendor, ExpenseAgentSetup, NoSeriesManagement, ExpenseVendor);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure CreateMatchedExpenseVendor(var Expense: Record Expense; var Vendor: Record Vendor; var ExpenseAgentSetup: Record "Expense Agent Setup"; var NoSeriesManagement: Codeunit "No. Series"; var ExpenseVendor: Record "Expense Vendor")
    begin
        // Reuse existing Expense Vendor if already created for this BC Vendor
        ExpenseVendor.SetRange("Vendor No.", Vendor."No.");
        if not ExpenseVendor.FindFirst() then begin
            ExpenseAgentSetup.GetRecordOnce();
            ExpenseAgentSetup.TestField("Expense Vendor Nos.");
            ExpenseVendor.Init();
            ExpenseVendor."No." := NoSeriesManagement.GetNextNo(ExpenseAgentSetup."Expense Vendor Nos.", WorkDate(), true);
            ExpenseVendor."No. Series" := ExpenseAgentSetup."Expense Vendor Nos.";
            ExpenseVendor.Name := CopyStr(Vendor.Name, 1, MaxStrLen(ExpenseVendor.Name));
            ExpenseVendor."Registration Number" := CopyStr(Expense."Merchant Registration No.", 1, MaxStrLen(ExpenseVendor."Registration Number"));
            ExpenseVendor."VAT Registration No." := CopyStr(Vendor."VAT Registration No.", 1, MaxStrLen(ExpenseVendor."VAT Registration No."));
            ExpenseVendor."Vendor No." := Vendor."No.";
            ExpenseVendor.Status := ExpenseVendor.Status::Matched;
            ExpenseVendor.Insert();
        end;
        ExpenseVendor.Reset();

        LinkExpenseToExpenseVendor(Expense, ExpenseVendor."No.");
    end;

    local procedure CreateExpenseVendorFromExpense(var Expense: Record Expense)
    var
        ExpenseVendor: Record "Expense Vendor";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        NoSeriesManagement: Codeunit "No. Series";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.TestField("Expense Vendor Nos.");

        ExpenseVendor.Init();
        ExpenseVendor."No." := NoSeriesManagement.GetNextNo(ExpenseAgentSetup."Expense Vendor Nos.", WorkDate(), true);
        ExpenseVendor."No. Series" := ExpenseAgentSetup."Expense Vendor Nos.";
        ExpenseVendor.Name := CopyStr(Expense."Merchant Name", 1, MaxStrLen(ExpenseVendor.Name));
        ExpenseVendor."Registration Number" := CopyStr(Expense."Merchant Registration No.", 1, MaxStrLen(ExpenseVendor."Registration Number"));
        ExpenseVendor."VAT Registration No." := CopyStr(Expense."Merchant VAT Registration No.", 1, MaxStrLen(ExpenseVendor."VAT Registration No."));
        ExpenseVendor.Status := ExpenseVendor.Status::Unmatched;
        ExpenseVendor.Insert(false);

        LinkExpenseToExpenseVendor(Expense, ExpenseVendor."No.");
    end;

    local procedure LinkExpenseToExpenseVendor(var Expense: Record Expense; ExpenseVendorNo: Code[20])
    begin
        Expense."Expense Vendor No." := ExpenseVendorNo;
        Expense.Modify(false);
    end;

    local procedure CreateVendor(var ExpenseVendor: Record "Expense Vendor"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor.Insert(true);
        Vendor.Validate(Name, CopyStr(ExpenseVendor.Name, 1, MaxStrLen(Vendor.Name)));
        // Note: Registration No. field assignment skipped; set manually after creation if required.
        if ExpenseVendor."VAT Registration No." <> '' then
            Vendor.Validate("VAT Registration No.", CopyStr(ExpenseVendor."VAT Registration No.", 1, MaxStrLen(Vendor."VAT Registration No.")));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;
}
