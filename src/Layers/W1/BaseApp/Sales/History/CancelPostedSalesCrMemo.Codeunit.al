// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 1339 "Cancel Posted Sales Cr. Memo"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        UnapplyEntries(Rec);
        CreateCopyDocument(Rec, SalesHeader);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
        SetTrackInfoForCancellation(Rec);

        Commit();
    end;

    var
        AlreadyCancelledErr: Label 'You cannot cancel this posted sales credit memo because it has already been cancelled.';
        NotCorrectiveDocErr: Label 'You cannot cancel this posted sales credit memo because it is not a corrective document.';
        CustomerIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because customer %1 is blocked.', Comment = '%1 = Customer name';
        ItemIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        ItemVariantIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because item variant %1 for item %2 %3 is blocked.', Comment = '%1 - Item Variant Code, %2 = Item No. %3 = Item Description';
        AccountIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        NoFreeInvoiceNoSeriesCancelErr: Label 'You cannot cancel this posted sales credit memo because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreePostInvSeriesCancelErr: Label 'You cannot cancel this posted sales credit memo because no unused posted invoice numbers are available. \\You must extend the range of the number series for posted invoices.';
        PostingNotAllowedCancelErr: Label 'You cannot cancel this posted sales credit memo because it was posted in a posting period that is closed.';
        InvalidDimCodeCancelErr: Label 'You cannot cancel this posted sales credit memo because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being cancelled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCombinationCancelErr: Label 'You cannot cancel this posted sales credit memo because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombHeaderCancelErr: Label 'You cannot cancel this posted sales credit memo because the combination of dimensions on the credit memo is blocked.';
        ExternalDocCancelErr: Label 'You cannot cancel this posted sales credit memo because the external document number is required on the credit memo.';
        InventoryPostClosedCancelErr: Label 'You cannot cancel this posted sales credit memo because the inventory period is already closed.';
        PostingCreditMemoFailedOpenPostedInvQst: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is posted. Do you want to open the posted invoice?', Comment = '%1 = error text';
        PostingCreditMemoFailedOpenInvQst: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is created but not posted. Do you want to open the invoice?', Comment = '%1 = error text';
        CreatingInvFailedNothingCreatedErr: Label 'Canceling the credit memo failed because of the following error: \\%1.', Comment = '%1 = error text';
        ErrorType: Option CustomerBlocked,ItemBlocked,AccountBlocked,IsAppliedIncorrectly,IsUnapplied,IsCanceled,IsCorrected,SerieNumInv,SerieNumPostInv,FromOrder,PostingNotAllowed,DimErr,DimCombErr,DimCombHeaderErr,ExtDocErr,InventoryPostClosed,ItemVariantBlocked;
        UnappliedErr: Label 'You cannot cancel this posted sales credit memo because it is fully or partially applied.\\To reverse an applied sales credit memo, you must manually unapply all applied entries.';
        NotAppliedCorrectlyErr: Label 'You cannot cancel this posted sales credit memo because it is not fully applied to an invoice.';

    procedure CancelPostedCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);
        if not CODEUNIT.Run(CODEUNIT::"Cancel Posted Sales Cr. Memo", SalesCrMemoHeader) then begin
            SalesInvHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
            if SalesInvHeader.FindFirst() then begin
                if Confirm(StrSubstNo(PostingCreditMemoFailedOpenPostedInvQst, GetLastErrorText)) then begin
                    IsHandled := false;
                    OnBeforeShowPostedSalesInvoice(SalesInvHeader, IsHandled);
                    if not IsHandled then
                        PageManagement.PageRun(SalesInvHeader);
                end
            end else begin
                SalesHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
                if SalesHeader.FindFirst() then begin
                    if Confirm(StrSubstNo(PostingCreditMemoFailedOpenInvQst, GetLastErrorText)) then begin
                        IsHandled := false;
                        OnBeforeShowSalesInvoice(SalesHeader, IsHandled);
                        if not IsHandled then
                            PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
                    end
                end else
                    Error(CreatingInvFailedNothingCreatedErr, GetLastErrorText);
            end;
            exit(false);
        end;
        exit(true);
    end;

    local procedure CreateCopyDocument(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header")
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        Clear(SalesHeader);
        SalesHeader."No." := '';
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        OnCreateCopyDocumentOnBeforeSalesHeaderInsert(SalesHeader, SalesCrMemoHeader);
        SalesHeader.Insert(true);
        CopyDocMgt.SetPropertiesForInvoiceCorrection(false);
        CopyDocMgt.CopySalesDocForCrMemoCancelling(SalesCrMemoHeader."No.", SalesHeader);
        OnAfterCreateCopyDocument(SalesCrMemoHeader, SalesHeader);
    end;

    procedure TestCorrectCrMemoIsAllowed(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestCorrectCrMemoIsAllowed(SalesCrMemoHeader, IsHandled);
        if not IsHandled then begin
            TestIfPostingIsAllowed(SalesCrMemoHeader);
            TestIfCustomerIsBlocked(SalesCrMemoHeader, SalesCrMemoHeader."Sell-to Customer No.");
            TestIfCustomerIsBlocked(SalesCrMemoHeader, SalesCrMemoHeader."Bill-to Customer No.");
            TestIfInvoiceIsCorrectedOnce(SalesCrMemoHeader);
            TestIfCrMemoIsCorrectiveDoc(SalesCrMemoHeader);
            TestCustomerDimension(SalesCrMemoHeader, SalesCrMemoHeader."Bill-to Customer No.");
            TestDimensionOnHeader(SalesCrMemoHeader);
            TestSalesLines(SalesCrMemoHeader);
            TestIfAnyFreeNumberSeries(SalesCrMemoHeader);
            TestExternalDocument(SalesCrMemoHeader);
            TestInventoryPostingClosed(SalesCrMemoHeader);
        end;

        OnAfterTestCorrectCrMemoIsAllowed(SalesCrMemoHeader);
    end;

    local procedure SetTrackInfoForCancellation(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        SalesInvHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
        if SalesInvHeader.FindLast() then
            CancelledDocument.InsertSalesCrMemoToInvCancelledDocument(SalesCrMemoHeader."No.", SalesInvHeader."No.");
    end;

    local procedure TestDimensionOnHeader(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if not DimensionManagement.CheckDimIDComb(SalesCrMemoHeader."Dimension Set ID") then
            ErrorHelperHeader(ErrorType::DimCombHeaderErr, SalesCrMemoHeader);
    end;

    local procedure TestIfCustomerIsBlocked(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        if Customer.Blocked in [Customer.Blocked::Invoice, Customer.Blocked::All] then
            ErrorHelperHeader(ErrorType::CustomerBlocked, SalesCrMemoHeader);
    end;

    local procedure TestIfAppliedCorrectly(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PartiallyApplied: Boolean;
    begin
        CustLedgEntry.CalcFields(Amount, "Remaining Amount");
        OnTestIfAppliedCorrectlyOnAfterCalcAmounts(CustLedgEntry);
        PartiallyApplied :=
          ((CustLedgEntry.Amount <> CustLedgEntry."Remaining Amount") and (CustLedgEntry."Remaining Amount" <> 0));
        if (CalcDtldCustLedgEntryCount(DetailedCustLedgEntry."Entry Type"::"Initial Entry", CustLedgEntry."Entry No.") <> 1) or
           (not (CalcDtldCustLedgEntryCount(DetailedCustLedgEntry."Entry Type"::Application, CustLedgEntry."Entry No.") in [0, 1])) or
           AnyDtldCustLedgEntriesExceptInitialAndApplicaltionExists(CustLedgEntry."Entry No.") or
           PartiallyApplied
        then
            ErrorHelperHeader(ErrorType::IsAppliedIncorrectly, SalesCrMemoHeader);
    end;

    local procedure TestIfUnapplied(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestIfUnapplied(SalesCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        SalesCrMemoHeader.CalcFields("Remaining Amount");
        if SalesCrMemoHeader."Amount Including VAT" <> -SalesCrMemoHeader."Remaining Amount" then
            ErrorHelperHeader(ErrorType::IsUnapplied, SalesCrMemoHeader);
    end;

    local procedure TestCustomerDimension(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        Customer.Get(CustNo);
        TableID[1] := DATABASE::Customer;
        No[1] := Customer."No.";
        if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesCrMemoHeader."Dimension Set ID") then
            ErrorHelperAccount(ErrorType::DimErr, Customer."No.", Customer.TableCaption(), Customer."No.", Customer.Name);
    end;

    local procedure TestSalesLines(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.Find('-') then
            repeat
                if not IsCommentLine(SalesCrMemoLine) then begin
                    if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then begin
                        Item.Get(SalesCrMemoLine."No.");

                        if Item.Blocked then
                            ErrorHelperLine(ErrorType::ItemBlocked, SalesCrMemoLine);
                        if SalesCrMemoLine."Variant Code" <> '' then begin
                            ItemVariant.SetLoadFields(Blocked);
                            if ItemVariant.Get(SalesCrMemoLine."No.", SalesCrMemoLine."Variant Code") and ItemVariant.Blocked then
                                ErrorHelperLine(ErrorType::ItemVariantBlocked, SalesCrMemoLine);
                        end;

                        TableID[1] := DATABASE::Item;
                        No[1] := SalesCrMemoLine."No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesCrMemoLine."Dimension Set ID") then
                            ErrorHelperAccount(ErrorType::DimErr, No[1], Item.TableCaption(), Item."No.", Item.Description);

                        if Item.Type = Item.Type::Inventory then
                            TestInventoryPostingSetup(SalesCrMemoLine);
                    end;

                    TestGenPostingSetup(SalesCrMemoLine);
                    TestCustomerPostingGroup(SalesCrMemoLine, SalesCrMemoHeader."Customer Posting Group");
                    TestVATPostingSetup(SalesCrMemoLine);

                    if not DimensionManagement.CheckDimIDComb(SalesCrMemoLine."Dimension Set ID") then
                        ErrorHelperLine(ErrorType::DimCombErr, SalesCrMemoLine);
                end;
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then
            ErrorHelperAccount(ErrorType::AccountBlocked, AccountNo, GLAccount.TableCaption(), '', '');
        TableID[1] := DATABASE::"G/L Account";
        No[1] := AccountNo;

        if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then begin
            Item.Get(SalesCrMemoLine."No.");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesCrMemoLine."Dimension Set ID") then
                ErrorHelperAccount(ErrorType::DimErr, AccountNo, GLAccount.TableCaption(), Item."No.", Item.Description);
        end;
    end;

    local procedure TestIfInvoiceIsCorrectedOnce(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if CancelledDocument.FindSalesCancelledCrMemo(SalesCrMemoHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrected, SalesCrMemoHeader);
    end;

    local procedure TestIfCrMemoIsCorrectiveDoc(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CancelledDocument: Record "Cancelled Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestIfCrMemoIsCorrectiveDoc(SalesCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        if not CancelledDocument.FindSalesCorrectiveCrMemo(SalesCrMemoHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCanceled, SalesCrMemoHeader);
    end;

    local procedure TestIfPostingIsAllowed(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(SalesCrMemoHeader."Posting Date") then
            ErrorHelperHeader(ErrorType::PostingNotAllowed, SalesCrMemoHeader);
    end;

    local procedure TestIfAnyFreeNumberSeries(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PostingDate: Date;
        PostingNoSeries: Code[20];
    begin
        PostingDate := WorkDate();
        SalesReceivablesSetup.Get();

        if not TryPeekNextNo(SalesReceivablesSetup."Invoice Nos.", PostingDate) then
            ErrorHelperHeader(ErrorType::SerieNumInv, SalesCrMemoHeader);

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            GenJournalTemplate.Get(SalesReceivablesSetup."S. Invoice Template Name");
            PostingNoSeries := GenJournalTemplate."Posting No. Series"
        end else
            PostingNoSeries := SalesReceivablesSetup."Posted Invoice Nos.";
        if not TryPeekNextNo(PostingNoSeries, PostingDate) then
            ErrorHelperHeader(ErrorType::SerieNumPostInv, SalesCrMemoHeader);
    end;

    [TryFunction]
    local procedure TryPeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date)
    var
        NoSeries: Codeunit "No. Series";
    begin
        if NoSeries.PeekNextNo(NoSeriesCode, UsageDate) = '' then
            Error('');
    end;

    local procedure TestExternalDocument(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if (SalesCrMemoHeader."External Document No." = '') and SalesReceivablesSetup."Ext. Doc. No. Mandatory" then
            ErrorHelperHeader(ErrorType::ExtDocErr, SalesCrMemoHeader);
    end;

    local procedure TestInventoryPostingClosed(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        InventoryPeriod: Record "Inventory Period";
    begin
        InventoryPeriod.SetRange(Closed, true);
        InventoryPeriod.SetFilter("Ending Date", '>=%1', SalesCrMemoHeader."Posting Date");
        if InventoryPeriod.FindFirst() then
            ErrorHelperHeader(ErrorType::InventoryPostClosed, SalesCrMemoHeader);
    end;

    local procedure TestGenPostingSetup(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        Item: Record Item;
    begin
        if SalesCrMemoLine."VAT Calculation Type" = SalesCrMemoLine."VAT Calculation Type"::"Sales Tax" then
            exit;

        GenPostingSetup.Get(SalesCrMemoLine."Gen. Bus. Posting Group", SalesCrMemoLine."Gen. Prod. Posting Group");
        GenPostingSetup.TestField("Sales Account");
        TestGLAccount(GenPostingSetup."Sales Account", SalesCrMemoLine);
        GenPostingSetup.TestField("Sales Credit Memo Account");
        TestGLAccount(GenPostingSetup."Sales Credit Memo Account", SalesCrMemoLine);
        GenPostingSetup.TestField("Sales Line Disc. Account");
        TestGLAccount(GenPostingSetup."Sales Line Disc. Account", SalesCrMemoLine);
        if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then begin
            Item.Get(SalesCrMemoLine."No.");
            if Item.IsInventoriableType() then
                TestGLAccount(GenPostingSetup.GetCOGSAccount(), SalesCrMemoLine);
        end;
    end;

    local procedure TestCustomerPostingGroup(SalesCrMemoLine: Record "Sales Cr.Memo Line"; CustomerPostingGr: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGr);
        CustomerPostingGroup.TestField("Receivables Account");
        TestGLAccount(CustomerPostingGroup."Receivables Account", SalesCrMemoLine);
    end;

    local procedure TestVATPostingSetup(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group");
        if VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Sales Tax" then begin
            VATPostingSetup.TestField("Sales VAT Account");
            TestGLAccount(VATPostingSetup."Sales VAT Account", SalesCrMemoLine);
        end;
    end;

    local procedure TestInventoryPostingSetup(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestInventoryPostingSetup(SalesCrMemoLine, IsHandled);
        if IsHandled then
            exit;

        InventoryPostingSetup.Get(SalesCrMemoLine."Location Code", SalesCrMemoLine."Posting Group");
        InventoryPostingSetup.TestField("Inventory Account");
        TestGLAccount(InventoryPostingSetup."Inventory Account", SalesCrMemoLine);
    end;

    local procedure UnapplyEntries(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        FindCustLedgEntry(CustLedgEntry, SalesCrMemoHeader."No.");
        TestIfAppliedCorrectly(SalesCrMemoHeader, CustLedgEntry);
        if CustLedgEntry.Open then
            exit;

        FindDetailedApplicationEntry(DetailedCustLedgEntry, CustLedgEntry);
        ApplyUnapplyParameters."Document No." := DetailedCustLedgEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DetailedCustLedgEntry."Posting Date";
        CustEntryApplyPostedEntries.PostUnApplyCustomer(DetailedCustLedgEntry, ApplyUnapplyParameters);
        TestIfUnapplied(SalesCrMemoHeader);
    end;

    local procedure FindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; DocNo: Code[20])
    begin
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast();
    end;

    local procedure FindDetailedApplicationEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
        DetailedCustLedgEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure AnyDtldCustLedgEntriesExceptInitialAndApplicaltionExists(CustLedgEntryNo: Integer): Boolean
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetFilter(
          "Entry Type", '<>%1&<>%2', DetailedCustLedgEntry."Entry Type"::"Initial Entry", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        exit(not DetailedCustLedgEntry.IsEmpty);
    end;

    local procedure CalcDtldCustLedgEntryCount(EntryType: Enum "Detailed CV Ledger Entry Type"; CustLedgEntryNo: Integer): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        exit(DetailedCustLedgEntry.Count);
    end;

    local procedure IsCommentLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"): Boolean
    begin
        exit((SalesCrMemoLine.Type = SalesCrMemoLine.Type::" ") or (SalesCrMemoLine."No." = ''));
    end;

    local procedure ErrorHelperHeader(ErrorOption: Option; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Customer: Record Customer;
    begin
        case ErrorOption of
            ErrorType::CustomerBlocked:
                begin
                    Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
                    Error(CustomerIsBlockedCancelErr, Customer.Name);
                end;
            ErrorType::IsAppliedIncorrectly:
                Error(NotAppliedCorrectlyErr);
            ErrorType::IsUnapplied:
                Error(UnappliedErr);
            ErrorType::IsCorrected:
                Error(AlreadyCancelledErr);
            ErrorType::IsCanceled:
                Error(NotCorrectiveDocErr);
            ErrorType::SerieNumInv:
                Error(NoFreeInvoiceNoSeriesCancelErr);
            ErrorType::SerieNumPostInv:
                Error(NoFreePostInvSeriesCancelErr);
            ErrorType::PostingNotAllowed:
                Error(PostingNotAllowedCancelErr);
            ErrorType::ExtDocErr:
                Error(ExternalDocCancelErr);
            ErrorType::InventoryPostClosed:
                Error(InventoryPostClosedCancelErr);
            ErrorType::DimCombHeaderErr:
                Error(InvalidDimCombHeaderCancelErr);
        end
    end;

    local procedure ErrorHelperLine(ErrorOption: Option; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        Item: Record Item;
    begin
        case ErrorOption of
            ErrorType::ItemBlocked:
                begin
                    Item.Get(SalesCrMemoLine."No.");
                    Error(ItemIsBlockedCancelErr, Item."No.", Item.Description);
                end;
            ErrorType::ItemVariantBlocked:
                begin
                    Item.SetLoadFields(Description);
                    Item.Get(SalesCrMemoLine."No.");
                    Error(ItemVariantIsBlockedCancelErr, SalesCrMemoLine."Variant Code", Item."No.", Item.Description);
                end;
            ErrorType::DimCombErr:
                Error(InvalidDimCombinationCancelErr, SalesCrMemoLine."No.", SalesCrMemoLine.Description);
        end
    end;

    local procedure ErrorHelperAccount(ErrorOption: Option; AccountNo: Code[20]; AccountCaption: Text; No: Code[20]; Name: Text)
    begin
        case ErrorOption of
            ErrorType::AccountBlocked:
                Error(AccountIsBlockedCancelErr, AccountCaption, AccountNo);
            ErrorType::DimErr:
                Error(InvalidDimCodeCancelErr, AccountCaption, AccountNo, No, Name);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCopyDocument(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestCorrectCrMemoIsAllowed(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestInventoryPostingSetup(SalesCrMemoLine: Record "Sales Cr.Memo Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCopyDocumentOnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestIfUnapplied(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesInvoice(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestCorrectCrMemoIsAllowed(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestIfCrMemoIsCorrectiveDoc(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestIfAppliedCorrectlyOnAfterCalcAmounts(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}
