// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Environment.Configuration;

codeunit 10756 "SII Management"
{

    trigger OnRun()
    begin
    end;

    var
        DontAskAgainTxt: Label 'Don''t ask again';
        SiiNotificationNameTxt: Label 'Sii Setup Notification';
        SIIServiceNameTxt: Label 'SII Service';
        SIIBusinessSetupDescriptionTxt: Label 'Set up and enable the SII service.';
        SIIBusinessSetupKeywordsTxt: Label 'Finance,SII';
        SetupNotificationTxt: Label 'Do you want to setup SII Document Transmission?';
        YesTxt: Label 'Yes';
        NoSIIStateErr: Label 'The document has not been transmitted and hence has no status.';
        MarkAsNotAcceptedErr: Label 'Marked as not accepted by %1 on %2.', Comment = '%1 = user id;%2 = date time of mark';
        MarkAsAcceptedErr: Label 'Marked as accepted by %1 on %2.', Comment = '%1 = user id;%2 = date time of mark';

    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice", 'OnOpenPageEvent', '', false, false)]
    local procedure OnSalesInvoicePageOpen(var Rec: Record "Sales Header")
    begin
        CreateSetupNotification();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Invoice", 'OnOpenPageEvent', '', false, false)]
    local procedure OnPurchInvoicePageOpen(var Rec: Record "Purchase Header")
    begin
        CreateSetupNotification();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Credit Memo", 'OnOpenPageEvent', '', false, false)]
    local procedure OnSalesCreditMemoPageOpen(var Rec: Record "Sales Header")
    begin
        CreateSetupNotification();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Credit Memo", 'OnOpenPageEvent', '', false, false)]
    local procedure OnPurchCreditMemoPageOpen(var Rec: Record "Purchase Header")
    begin
        CreateSetupNotification();
    end;

    procedure IsSIISetupEnabled(): Boolean
    var
        SIISetup: Record "SII Setup";
    begin
        if not SIISetup.Get() then
            exit(false);
        exit(SIISetup.Enabled);
    end;

    local procedure CreateSetupNotification()
    var
        SetupNotification: Notification;
    begin
        if not ShowNotification() then
            exit;

        SetupNotification.Message := SetupNotificationTxt;
        SetupNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        SetupNotification.AddAction(YesTxt, CODEUNIT::"SII Management", 'OpenSIIVATSetup');
        SetupNotification.AddAction(DontAskAgainTxt, CODEUNIT::"SII Management", 'DeactivateSIISetupNotification');
        SetupNotification.Send();
    end;

    procedure OpenSIIVATSetup(SetupNotification: Notification)
    begin
        PAGE.Run(PAGE::"SII Setup");
    end;

    procedure DeactivateSIISetupNotification(var SetupNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
        NotificationGuid: Guid;
    begin
        NotificationGuid := SetupNotification.Id;
        if MyNotifications.Get(UserId, NotificationGuid) then begin
            MyNotifications.Validate(Enabled, false);
            MyNotifications.Modify();
        end else
            MyNotifications.InsertDefault(GetNotificationId(), SiiNotificationNameTxt, 'SII', false);
    end;

    local procedure ShowNotification(): Boolean
    var
        MyNotifications: Record "My Notifications";
        SIISetup: Record "SII Setup";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if CompanyInformationMgt.IsDemoCompany() then
            exit(false);
        if SIISetup.IsEnabled() then
            exit(false);
        exit(MyNotifications.IsEnabled(GetNotificationId()));
    end;

    local procedure GetNotificationId(): Text
    begin
        exit('C36C1441-6711-4878-9EB4-B8C8EAECD925');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure HandleRegisterBusinessSetup()
    var
        SIISetup: Record "SII Setup";
        GuidedExperience: Codeunit "Guided Experience";
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        if not SIISetup.Get() then begin
            SIISetup.Init();
            SIISetup.Insert(true);
        end;

        GuidedExperience.InsertManualSetup(
          SIIServiceNameTxt, CopyStr(SIIServiceNameTxt, 1, 50), SIIBusinessSetupDescriptionTxt, 5,
          ObjectType::Page, PAGE::"SII Setup", ManualSetupCategory::Service, SIIBusinessSetupKeywordsTxt);
    end;

    procedure GetSIIStyle(SIIState: Option Pending,Incorrect,Accepted,"Accepted With Errors","Communication Error",Failed,"Not Supported") StyleText: Text
    begin
        case SIIState of
            SIIState::Accepted:
                StyleText := 'Favorable';
            SIIState::"Accepted With Errors":
                StyleText := 'Ambiguous';
            SIIState::Failed,
          SIIState::Incorrect,
          SIIState::"Communication Error":
                StyleText := 'Unfavorable';
            else
                StyleText := 'Standard';
        end;
    end;

    procedure GetSalesIDType(CustNo: Code[20]; CorrectionType: Option; CorrDocNo: Code[20]): Integer
    var
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        CompanyInformation: Record "Company Information";
        SIIManagement: Codeunit "SII Management";
        CountryCode: Code[20];
        VATRegNo: Code[20];
    begin
        if CustNo = '' then
            exit(0);

        Cust.Get(CustNo);
        if (CorrectionType = SalesHeader."Correction Type"::Removal) and (CorrDocNo <> '') then begin
            CompanyInformation.Get();
            CountryCode := CompanyInformation."Country/Region Code";
            VATRegNo := CompanyInformation."VAT Registration No.";
        end else begin
            CountryCode := Cust."Country/Region Code";
            VATRegNo := Cust."VAT Registration No.";
        end;
        exit(
          SIIManagement.GetIDType(CountryCode, VATRegNo, Cust."Not in AEAT", SIIManagement.CustomerIsIntraCommunity(Cust."No.")));
    end;

    procedure GetPurchIDType(VendNo: Code[20]; CorrectionType: Option; CorrDocNo: Code[20]): Integer
    var
        Vend: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        SIIManagement: Codeunit "SII Management";
    begin
        if VendNo = '' then
            exit(0);

        Vend.Get(VendNo);
        if (CorrectionType = PurchaseHeader."Correction Type"::Removal) and (CorrDocNo <> '') then; // keep condition and parameters to avoid breaking changes of external function
        exit(
          SIIManagement.GetIDType(
            Vend."Country/Region Code", Vend."VAT Registration No.", false,
            SIIManagement.VendorIsIntraCommunity(Vend."No.")));
    end;

    procedure GetIDType(CountryCode: Code[20]; VATRegNo: Code[20]; IsNotInAEAT: Boolean; IsIntraCommunity: Boolean): Integer
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
    begin
        if SIIManagement.CountryAndVATRegNoAreLocal(CountryCode, VATRegNo) then begin
            if IsNotInAEAT then
                exit(SIIDocUploadState.IDType::"07-Not On The Census".AsInteger());
            exit(0);
        end;
        if IsIntraCommunity then
            exit(SIIDocUploadState.IDType::"02-VAT Registration No.".AsInteger());
        if IsNotInAEAT then
            exit(SIIDocUploadState.IDType::"07-Not On The Census".AsInteger());
        exit(SIIDocUploadState.IDType::"06-Other Probative Document".AsInteger());
    end;

    procedure GetVendFromLedgEntryByGLSetup(VendorLedgerEntry: Record "Vendor Ledger Entry"): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        case GeneralLedgerSetup."Bill-to/Sell-to VAT Calc." of
            GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.":
                exit(VendorLedgerEntry."Vendor No.");
            GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.":
                exit(VendorLedgerEntry."Buy-from Vendor No.");
        end;
    end;

    procedure GetCustFromLedgEntryByGLSetup(CustLedgerEntry: Record "Cust. Ledger Entry"): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        case GeneralLedgerSetup."Bill-to/Sell-to VAT Calc." of
            GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.":
                exit(CustLedgerEntry."Customer No.");
            GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.":
                exit(CustLedgerEntry."Sell-to Customer No.");
        end;
    end;

    procedure GetNoTaxablePurchAmount(var NoTaxableAmount: Decimal; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        exit(GetNoTaxablePurchAmount(NoTaxableAmount, SourceNo, DocumentType, DocumentNo, PostingDate, false));
    end;

    procedure GetNoTaxablePurchAmount(var NoTaxableAmount: Decimal; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date; IgnoreInSII: Boolean): Boolean
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        if NoTaxableEntriesExistPurchase(NoTaxableEntry, SourceNo, DocumentType, DocumentNo, PostingDate, IgnoreInSII) then begin
            NoTaxableEntry.CalcSums("Amount (LCY)");
            NoTaxableAmount := -NoTaxableEntry."Amount (LCY)";
            exit(true);
        end;
        exit(false);
    end;

    procedure GetNoTaxableSalesAmount(var NoTaxableAmount: Decimal; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date; IsService: Boolean; UseNoTaxableType: Boolean; IsLocalRule: Boolean): Boolean
    begin
        exit(GetNoTaxableSalesAmount(NoTaxableAmount, SourceNo, DocumentType, DocumentNo, PostingDate, IsService, UseNoTaxableType, IsLocalRule, false));
    end;

    procedure GetNoTaxableSalesAmount(var NoTaxableAmount: Decimal; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date; IsService: Boolean; UseNoTaxableType: Boolean; IsLocalRule: Boolean; IgnoreInSII: Boolean): Boolean
    var
        NoTaxableEntry: Record "No Taxable Entry";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        NoTaxableAmount := 0;

        IsHandled := false;
        OnBeforeGetNoTaxableSalesAmount(
            NoTaxableEntry, SourceNo, DocumentType, DocumentNo, PostingDate, IsService,
            UseNoTaxableType, IsLocalRule, NoTaxableAmount, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if NoTaxableEntriesExistSales(NoTaxableEntry, SourceNo, DocumentType, DocumentNo, PostingDate, IsService, UseNoTaxableType, IsLocalRule, IgnoreInSII) then begin
            NoTaxableEntry.CalcSums("Amount (LCY)");
            if DoNotReportNegativeLines() then
                case true of
                    (DocumentType = NoTaxableEntry."Document Type"::Invoice.AsInteger()) and (NoTaxableEntry."Amount (LCY)" > 0):
                        exit(false);
                    (DocumentType = NoTaxableEntry."Document Type"::"Credit Memo".AsInteger()) and (NoTaxableEntry."Amount (LCY)" < 0):
                        exit(false);
                end;
            NoTaxableAmount := -NoTaxableEntry."Amount (LCY)";
            exit(true);
        end;
        exit(false);
    end;

    procedure GetBaseImponibleACosteRegimeCode(): Text
    begin
        exit('06');
    end;

    procedure SIIStateDrilldown(var SIIDocUploadState: Record "SII Doc. Upload State")
    var
        SIIHistory: Record "SII History";
    begin
        if not SIIDocUploadState.FindFirst() then
            Error(NoSIIStateErr);
        SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
        SIIHistory.FindFirst();
        PAGE.Run(PAGE::"SII History", SIIHistory);
    end;

    procedure IsVATEntryCashFlowBased(VATEntry: Record "VAT Entry"): Boolean
    begin
        // to know if a payment VAT entry is cash based, we look at "Unrealized VAT Entry No."
        // to know if an invoice VAT entry is cash based, we look at "Unrealized Base"
        exit((VATEntry."Unrealized VAT Entry No." <> 0) or (VATEntry."Unrealized Base" <> 0));
    end;

    procedure IsDetailedLedgerCashFlowBased(DtldLedgerEntryRecRef: RecordRef): Boolean
    var
        LedgerEntryRecRef: RecordRef;
    begin
        GetLedgerFromDetailed(LedgerEntryRecRef, DtldLedgerEntryRecRef);
        exit(IsLedgerCashFlowBased(LedgerEntryRecRef));
    end;

    procedure IsLedgerCashFlowBased(LedgerEntryRecRef: RecordRef): Boolean
    var
        VATEntry: Record "VAT Entry";
        SourceLedgerEntryRecRef: RecordRef;
    begin
        // TRUE only in case of all VAT Entries are Cash Flow based
        SourceLedgerEntryRecRef.Get(LedgerEntryRecRef.RecordId);
        if IsBillLedgerEntryRecRef(SourceLedgerEntryRecRef) then
            if not FindInvoiceDocLedgerFromBillLedger(SourceLedgerEntryRecRef, SourceLedgerEntryRecRef) then
                exit(false);

        if not FindVatEntriesFromLedger(SourceLedgerEntryRecRef, VATEntry) then
            exit(false);

        repeat
            if not IsVATEntryCashFlowBased(VATEntry) then
                exit(false);
        until VATEntry.Next() = 0;

        exit(true);
    end;

    local procedure IsBillLedgerEntryRecRef(LedgerEntryRecRef: RecordRef): Boolean
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentTypeFieldRef: FieldRef;
    begin
        DocumentTypeFieldRef := LedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Document Type"));
        DummyCustLedgerEntry."Document Type" := DocumentTypeFieldRef.Value();
        exit(DummyCustLedgerEntry."Document Type" = DummyCustLedgerEntry."Document Type"::Bill);
    end;

    procedure IsIntracommunity(CountryRegionCode: Code[10]): Boolean
    var
        DummyCountryRegion: Record "Country/Region";
    begin
        if CountryIsLocal(CountryRegionCode) then
            exit(false);

        if CountryIsNorthernIreland(CountryRegionCode) then
            exit(true);

        // If EU Country/Region is not blank it means that the country IS in EU and it is NOT Spain (that means, Intracommunity).
        exit(DummyCountryRegion.EUCountryFound(CountryRegionCode));
    end;

    local procedure FindVatEntryFromDetailedLedger(DetailedLedgerEntryRecRef: RecordRef; var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"): Boolean
    var
        DummyDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TransNoFieldRef: FieldRef;
        DocNumberFieldRef: FieldRef;
        PostingDateFieldRef: FieldRef;
        TransactionNumber: Integer;
        DocNumber: Code[20];
        PostingDate: Date;
    begin
        // get transaction number from ledger rec ref
        TransNoFieldRef := DetailedLedgerEntryRecRef.Field(DummyDetailedCustLedgEntry.FieldNo("Transaction No."));
        TransactionNumber := TransNoFieldRef.Value();

        PostingDateFieldRef := DetailedLedgerEntryRecRef.Field(DummyDetailedCustLedgEntry.FieldNo("Posting Date"));
        PostingDate := PostingDateFieldRef.Value();

        DocNumberFieldRef := DetailedLedgerEntryRecRef.Field(DummyDetailedCustLedgEntry.FieldNo("Document No."));
        DocNumber := DocNumberFieldRef.Value();

        // search for the vat entry
        VATEntry.Reset();
        VATEntry.SetRange("Transaction No.", TransactionNumber);
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.SetRange("Document No.", DocNumber);

        if DocumentType <> DocumentType::" " then
            VATEntry.SetRange("Document Type", DocumentType);

        exit(VATEntry.FindFirst())
    end;

    procedure FindVatEntriesFromLedger(LedgerEntryRecRef: RecordRef; var VATEntry: Record "VAT Entry"): Boolean
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        SIISetup: Record "SII Setup";
        TransNoFieldRef: FieldRef;
        DocNumberFieldRef: FieldRef;
        PostingDateFieldRef: FieldRef;
        DocTypeFieldRef: FieldRef;
        TransactionNumber: Integer;
        DocNumber: Code[20];
        PostingDate: Date;
    begin
        // get transaction number from ledger rec ref
        TransNoFieldRef := LedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Transaction No."));
        TransactionNumber := TransNoFieldRef.Value();

        PostingDateFieldRef := LedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Posting Date"));
        PostingDate := PostingDateFieldRef.Value();

        DocNumberFieldRef := LedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Document No."));
        DocNumber := DocNumberFieldRef.Value();

        // search for the vat entry
        VATEntry.Reset();
        VATEntry.SetRange("Transaction No.", TransactionNumber);
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.SetRange("Document No.", DocNumber);
        VATEntry.SetRange("No Taxable Type", VATEntry."No Taxable Type"::" ");
        VATEntry.SetRange("Ignore In SII", false);
        SIISetup.Get();
        if SIISetup."Do Not Export Negative Lines" then begin
            DocTypeFieldRef := LedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Document Type"));
            Evaluate(DummyCustLedgerEntry."Document Type", Format(DocTypeFieldRef.Value));
            case LedgerEntryRecRef.Number() of
                DATABASE::"Cust. Ledger Entry":
                    case DummyCustLedgerEntry."Document Type" of
                        DummyCustLedgerEntry."Document Type"::Invoice:
                            VATEntry.SetFilter(Base, '<=%1', 0);
                        DummyCustLedgerEntry."Document Type"::"Credit Memo":
                            VATEntry.SetFilter(Base, '>=%1', 0);
                    end;
                DATABASE::"Vendor Ledger Entry":
                    case DummyCustLedgerEntry."Document Type" of
                        DummyCustLedgerEntry."Document Type"::Invoice:
                            VATEntry.SetFilter(Base, '>=%1', 0);
                        DummyCustLedgerEntry."Document Type"::"Credit Memo":
                            VATEntry.SetFilter(Base, '<=%1', 0);
                    end;
            end;
        end;
        exit(VATEntry.FindSet());
    end;

    procedure FindNoTaxableEntriesFromLedger(LedgerEntryRecRef: RecordRef; var NoTaxableEntry: Record "No Taxable Entry"): Boolean
    var
        SIISetup: Record "SII Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        SIISetup.Get();
        case LedgerEntryRecRef.Number of
            DATABASE::"Cust. Ledger Entry":
                begin
                    LedgerEntryRecRef.SetTable(CustLedgerEntry);
                    NoTaxableEntry.FilterNoTaxableEntry(
                      NoTaxableEntry.Type::Sale.AsInteger(), GetCustFromLedgEntryByGLSetup(CustLedgerEntry),
                      CustLedgerEntry."Document Type".AsInteger(), CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date", false);
                    if SIISetup."Do Not Export Negative Lines" then
                        case CustLedgerEntry."Document Type" of
                            CustLedgerEntry."Document Type"::Invoice:
                                NoTaxableEntry.SetFilter("Amount (LCY)", '<=%1', 0);
                            CustLedgerEntry."Document Type"::"Credit Memo":
                                NoTaxableEntry.SetFilter("Amount (LCY)", '>=%1', 0);
                        end;
                end;
            DATABASE::"Vendor Ledger Entry":
                begin
                    LedgerEntryRecRef.SetTable(VendorLedgerEntry);
                    NoTaxableEntry.FilterNoTaxableEntry(
                      NoTaxableEntry.Type::Purchase.AsInteger(), GetVendFromLedgEntryByGLSetup(VendorLedgerEntry),
                      VendorLedgerEntry."Document Type".AsInteger(), VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date", false);
                    if SIISetup."Do Not Export Negative Lines" then
                        case VendorLedgerEntry."Document Type" of
                            VendorLedgerEntry."Document Type"::Invoice:
                                NoTaxableEntry.SetFilter("Amount (LCY)", '>=%1', 0);
                            VendorLedgerEntry."Document Type"::"Credit Memo":
                                NoTaxableEntry.SetFilter("Amount (LCY)", '<=%1', 0);
                        end;
                end;
        end;
        NoTaxableEntry.SetRange("Ignore In SII", false);
        exit(NoTaxableEntry.FindSet());
    end;

    procedure FindOriginalLedgerFromDetailedPaymentLedger(PaymentDetailedLedgerEntryRecRef: RecordRef; var SalesDocLedgerEntryRecRefOut: RecordRef)
    var
        DummyDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentVATEntry: Record "VAT Entry";
        SalesDocVATEntry: Record "VAT Entry";
        DocTypeFieldRef: FieldRef;
        DocumentType: Enum "Gen. Journal Document Type";
    begin
        DocTypeFieldRef := PaymentDetailedLedgerEntryRecRef.Field(DummyDetailedCustLedgEntry.FieldNo("Document Type"));
        DocumentType := DocTypeFieldRef.Value();
        if DocumentType <> DummyDetailedCustLedgEntry."Document Type"::Payment then
            exit;

        FindVatEntryFromDetailedLedger(PaymentDetailedLedgerEntryRecRef, PaymentVATEntry, PaymentVATEntry."Document Type"::Payment);

        SalesDocVATEntry.Get(PaymentVATEntry."Unrealized VAT Entry No.");

        FindLedgerFromVatEntry(SalesDocLedgerEntryRecRefOut, SalesDocVATEntry);
    end;

    procedure FindOriginalLedgerFromPaymentLedger(PaymentLedgerEntryRecRef: RecordRef; var SalesDocLedgerEntryRecRefOut: RecordRef)
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentVATEntry: Record "VAT Entry";
        SalesDocVATEntry: Record "VAT Entry";
        DocTypeFieldRef: FieldRef;
        DocumentType: Enum "Gen. Journal Document Type";
    begin
        DocTypeFieldRef := PaymentLedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Document Type"));
        DocumentType := DocTypeFieldRef.Value();
        if DocumentType <> DummyCustLedgerEntry."Document Type"::Payment then
            exit;

        FindVatEntriesFromLedger(PaymentLedgerEntryRecRef, PaymentVATEntry);

        SalesDocVATEntry.Get(PaymentVATEntry."Unrealized VAT Entry No.");

        FindLedgerFromVatEntry(SalesDocLedgerEntryRecRefOut, SalesDocVATEntry);
    end;

    procedure FindVatEntriesReferringToDocLedger(InvoiceDocLedgerEntryRecRef: RecordRef; var PaymentVATEntry: Record "VAT Entry"): Boolean
    var
        SalesDocVATEntry: Record "VAT Entry";
    begin
        FindVatEntriesFromLedger(InvoiceDocLedgerEntryRecRef, SalesDocVATEntry);

        PaymentVATEntry.Reset();
        PaymentVATEntry.SetRange("Unrealized VAT Entry No.", SalesDocVATEntry."Entry No.");
        exit(PaymentVATEntry.FindSet());
    end;

    procedure FindDetailedPaymentApplicationLedgerFromLedger(PaymentDocLedgerEntryRecRef: RecordRef; var PaymentDetailedDocLedgerEntryRecRefOut: RecordRef; ApplicationDate: Date; DocNumber: Code[20]): Boolean
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        DummyDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryTypeFieldRef: FieldRef;
        DocNumberFieldRef: FieldRef;
        InitialDocTypeFieldRef: FieldRef;
        UnappliedFieldRef: FieldRef;
        PostingDateFieldRef: FieldRef;
        AppliedLedgerEntryNoFieldRef: FieldRef;
        AppliedLedgerEntry: Integer;
    begin
        // the detailed ledger entry should:

        // 1) have the application date
        PostingDateFieldRef := PaymentDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Posting Date"));
        PostingDateFieldRef.SetRange(ApplicationDate);

        // 2) have the doc number
        DocNumberFieldRef := PaymentDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Document No."));
        DocNumberFieldRef.SetRange(DocNumber);

        // 3) have the "Application" type
        EntryTypeFieldRef := PaymentDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Entry Type"));
        EntryTypeFieldRef.SetRange(DummyDetailedCustLedgEntry."Entry Type"::Application);

        // 4) refer to a payment entry "Payment" (we could also look for the "Invoice" one but Payment is probably better here - could apply to credit memos)
        InitialDocTypeFieldRef :=
          PaymentDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Initial Document Type"));
        InitialDocTypeFieldRef.SetRange(DummyDetailedCustLedgEntry."Initial Document Type"::Payment); // we want the application to the payment

        // 5) not be unapplied
        UnappliedFieldRef := PaymentDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo(Unapplied));
        UnappliedFieldRef.SetRange(false); // ignore unapplied entries

        // 6) refer to the given payment ledger entry
        AppliedLedgerEntryNoFieldRef := PaymentDocLedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Entry No."));
        AppliedLedgerEntry := AppliedLedgerEntryNoFieldRef.Value();
        AppliedLedgerEntryNoFieldRef :=
          PaymentDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Applied Cust. Ledger Entry No."));
        AppliedLedgerEntryNoFieldRef.SetFilter(Format(AppliedLedgerEntry));

        exit(PaymentDetailedDocLedgerEntryRecRefOut.FindFirst())
    end;

    procedure FindDetailedLedgerFromVatEntry(var InvoiceDetailedDocLedgerEntryRecRefOut: RecordRef; InvoiceDocVATEntry: Record "VAT Entry"): Boolean
    var
        DummyDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryTypeFieldRef: FieldRef;
        DocNumberFieldRef: FieldRef;
        InitialDocTypeFieldRef: FieldRef;
        UnappliedFieldRef: FieldRef;
        TransactionNbFieldRef: FieldRef;
        PostingDateFieldRef: FieldRef;
    begin
        PostingDateFieldRef := InvoiceDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Posting Date"));
        PostingDateFieldRef.SetRange(InvoiceDocVATEntry."Posting Date");

        DocNumberFieldRef := InvoiceDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Document No."));
        DocNumberFieldRef.SetRange(InvoiceDocVATEntry."Document No.");

        EntryTypeFieldRef := InvoiceDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Entry Type"));
        EntryTypeFieldRef.SetRange(DummyDetailedCustLedgEntry."Entry Type"::Application);

        InitialDocTypeFieldRef :=
          InvoiceDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Initial Document Type"));
        InitialDocTypeFieldRef.SetFilter('<>' + Format(DummyDetailedCustLedgEntry."Initial Document Type"::Payment)); // we want the application to the invoice, not the payment

        UnappliedFieldRef := InvoiceDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo(Unapplied));
        UnappliedFieldRef.SetRange(false); // ignore unapplied entries

        TransactionNbFieldRef := InvoiceDetailedDocLedgerEntryRecRefOut.Field(DummyDetailedCustLedgEntry.FieldNo("Transaction No."));
        TransactionNbFieldRef.SetRange(InvoiceDocVATEntry."Transaction No.");

        exit(InvoiceDetailedDocLedgerEntryRecRefOut.FindFirst())
    end;

    procedure FindLedgerFromVatEntry(var InvoiceDocLedgerEntryRecRefOut: RecordRef; InvoiceDocVATEntry: Record "VAT Entry")
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        TransNoFieldRef: FieldRef;
        DocNumberFieldRef: FieldRef;
        PostingDateFieldRef: FieldRef;
    begin
        // search for a ledger that has the transaction number of the vat entry
        PostingDateFieldRef := InvoiceDocLedgerEntryRecRefOut.Field(DummyCustLedgerEntry.FieldNo("Posting Date"));
        PostingDateFieldRef.SetRange(InvoiceDocVATEntry."Posting Date");

        DocNumberFieldRef := InvoiceDocLedgerEntryRecRefOut.Field(DummyCustLedgerEntry.FieldNo("Document No."));
        DocNumberFieldRef.SetRange(InvoiceDocVATEntry."Document No.");

        TransNoFieldRef := InvoiceDocLedgerEntryRecRefOut.Field(DummyCustLedgerEntry.FieldNo("Transaction No."));
        TransNoFieldRef.SetRange(InvoiceDocVATEntry."Transaction No.");
        InvoiceDocLedgerEntryRecRefOut.FindFirst();
    end;

    local procedure FindInvoiceDocLedgerFromBillLedger(var InvoiceDocLedgerEntryRecRef: RecordRef; BillLedgerEntryRecRef: RecordRef): Boolean
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        DocNumberFieldRef: FieldRef;
        DocTypeFieldRef: FieldRef;
        SourceDocNumberFieldRef: FieldRef;
    begin
        SourceDocNumberFieldRef := BillLedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Document No."));
        DocNumberFieldRef := InvoiceDocLedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Document No."));
        DocNumberFieldRef.SetRange(SourceDocNumberFieldRef.Value);

        DocTypeFieldRef := InvoiceDocLedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Document Type"));
        DocTypeFieldRef.SetFilter(Format(DummyCustLedgerEntry."Document Type"::Invoice));

        exit(InvoiceDocLedgerEntryRecRef.FindFirst())
    end;

    procedure FindPaymentDetailedCustomerLedgerEntries(var PaymentDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        PaymentDetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        PaymentDetailedCustLedgEntry.SetFilter(
          "Document Type", '%1|%2',
          PaymentDetailedCustLedgEntry."Document Type"::Payment, PaymentDetailedCustLedgEntry."Document Type"::Refund);
        PaymentDetailedCustLedgEntry.SetRange(Unapplied, false);
        exit(PaymentDetailedCustLedgEntry.FindSet());
    end;

    procedure FindPaymentDetailedVendorLedgerEntries(var PaymentDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        PaymentDetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        PaymentDetailedVendorLedgEntry.SetFilter(
          "Document Type", '%1|%2',
          PaymentDetailedVendorLedgEntry."Document Type"::Payment, PaymentDetailedVendorLedgEntry."Document Type"::Refund);
        PaymentDetailedVendorLedgEntry.SetRange(Unapplied, false);
        exit(PaymentDetailedVendorLedgEntry.FindSet());
    end;

    procedure NoTaxableEntriesExistPurchase(var NoTaxableEntry: Record "No Taxable Entry"; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        exit(NoTaxableEntriesExistPurchase(NoTaxableEntry, SourceNo, DocumentType, DocumentNo, PostingDate, false));
    end;

    procedure NoTaxableEntriesExistPurchase(var NoTaxableEntry: Record "No Taxable Entry"; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date; IgnoreInSII: Boolean): Boolean
    begin
        NoTaxableEntry.FilterNoTaxableEntry(NoTaxableEntry.Type::Purchase.AsInteger(), SourceNo, DocumentType, DocumentNo, PostingDate, false);
        NoTaxableEntry.SetRange("Not In 347", false);
        NoTaxableEntry.SetRange("Ignore In SII", IgnoreInSII);
        exit(not NoTaxableEntry.IsEmpty);
    end;

    procedure NoTaxableEntriesExistSales(var NoTaxableEntry: Record "No Taxable Entry"; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date; IsService: Boolean; UseNoTaxableType: Boolean; IsLocalRule: Boolean): Boolean
    begin
        exit(NoTaxableEntriesExistSales(NoTaxableEntry, SourceNo, DocumentType, DocumentNo, PostingDate, IsService, UseNoTaxableType, IsLocalRule, false));
    end;

    procedure NoTaxableEntriesExistSales(var NoTaxableEntry: Record "No Taxable Entry"; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date; IsService: Boolean; UseNoTaxableType: Boolean; IsLocalRule: Boolean; IgnoreInSII: Boolean): Boolean
    begin
        NoTaxableEntry.FilterNoTaxableEntry(NoTaxableEntry.Type::Sale.AsInteger(), SourceNo, DocumentType, DocumentNo, PostingDate, false);
        NoTaxableEntry.SetRange("EU Service", IsService);
        NoTaxableEntry.SetRange("Not In 347", false);
        NoTaxableEntry.SetRange("Ignore In SII", IgnoreInSII);
        if UseNoTaxableType then
            if IsLocalRule then
                NoTaxableEntry.SetRange(
                  "No Taxable Type", NoTaxableEntry."No Taxable Type"::"Non Taxable Due To Localization Rules")
            else
                NoTaxableEntry.SetFilter(
                  "No Taxable Type", '<>%1', NoTaxableEntry."No Taxable Type"::"Non Taxable Due To Localization Rules");
        exit(not NoTaxableEntry.IsEmpty);
    end;

    local procedure GetLedgerFromDetailed(var LedgerEntryRecRef: RecordRef; DtldLedgerEntryRecRef: RecordRef)
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        DummyDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryNoFieldRef: FieldRef;
        SourceEntryNoFieldRef: FieldRef;
    begin
        SourceEntryNoFieldRef := DtldLedgerEntryRecRef.Field(DummyDetailedCustLedgEntry.FieldNo("Cust. Ledger Entry No."));
        if DtldLedgerEntryRecRef.Number = DATABASE::"Detailed Cust. Ledg. Entry" then
            LedgerEntryRecRef.Open(DATABASE::"Cust. Ledger Entry", false)
        else
            LedgerEntryRecRef.Open(DATABASE::"Vendor Ledger Entry", false);
        EntryNoFieldRef := LedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo("Entry No."));
        EntryNoFieldRef.SetRange(SourceEntryNoFieldRef.Value);
        LedgerEntryRecRef.FindFirst();
    end;

    procedure DoesPaymentDetailedLedgerCloseInvoice(PaymentDetailedLedgerEntryRecRef: RecordRef; IsCustomerPayment: Boolean): Boolean
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceDocLedgerEntryRecRef: RecordRef;
        OpenFieldRef: FieldRef;
        IsLedgerEntryOpen: Boolean;
    begin
        if IsCustomerPayment then
            InvoiceDocLedgerEntryRecRef.Open(DATABASE::"Cust. Ledger Entry", false)
        else
            InvoiceDocLedgerEntryRecRef.Open(DATABASE::"Vendor Ledger Entry", false);

        FindOriginalLedgerFromDetailedPaymentLedger(PaymentDetailedLedgerEntryRecRef, InvoiceDocLedgerEntryRecRef);
        OpenFieldRef := InvoiceDocLedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo(Open));
        IsLedgerEntryOpen := OpenFieldRef.Value();
        exit(not IsLedgerEntryOpen);
    end;

    procedure DoesPaymentLedgerCloseInvoice(PaymentLedgerEntryRecRef: RecordRef; IsCustomerPayment: Boolean): Boolean
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceDocLedgerEntryRecRef: RecordRef;
        OpenFieldRef: FieldRef;
        IsLedgerEntryOpen: Boolean;
    begin
        if IsCustomerPayment then
            InvoiceDocLedgerEntryRecRef.Open(DATABASE::"Cust. Ledger Entry", false)
        else
            InvoiceDocLedgerEntryRecRef.Open(DATABASE::"Vendor Ledger Entry", false);

        FindOriginalLedgerFromPaymentLedger(PaymentLedgerEntryRecRef, InvoiceDocLedgerEntryRecRef);
        OpenFieldRef := InvoiceDocLedgerEntryRecRef.Field(DummyCustLedgerEntry.FieldNo(Open));
        IsLedgerEntryOpen := OpenFieldRef.Value();
        exit(not IsLedgerEntryOpen);
    end;

    procedure CountryIsLocal(CountryCode: Code[20]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryCode) then
            if (CountryRegion."ISO Code" = 'ES') then
                exit(true);

        exit((CountryCode = 'ES') or (CountryCode = ''));
    end;

    procedure CountryAndVATRegNoAreLocal(CountryCode: Code[20]; VATRegNo: Code[20]): Boolean
    begin
        exit(CountryIsLocal(CountryCode) or ((StrPos(VATRegNo, 'N') = 1) and not CharIsCapitalLetter(VATRegNo[2]))); // VAT Nos starting with 'N' are local, those with 'NL', 'NO', etc. are not.
    end;

    procedure IsDomesticCustomer(Customer: Record Customer): Boolean
    begin
        exit(CountryIsLocal(Customer."Country/Region Code") and (StrPos(Customer."VAT Registration No.", 'N') <> 1));
    end;

    procedure CustomerIsIntraCommunity(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        exit(IsIntracommunity(Customer."Country/Region Code"));
    end;

    procedure VendorIsIntraCommunity(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        exit(IsIntracommunity(Vendor."Country/Region Code"));
    end;

    procedure CombineOperationDescription(OperationDescription1: Text[250]; OperationDescription2: Text[250]; var Result: Text[500])
    begin
        Result := OperationDescription1 + OperationDescription2;
    end;

    procedure SplitOperationDescription(OperationDescription: Text[500]; var Part1: Text[250]; var Part2: Text[250])
    begin
        Part1 := '';
        Part2 := '';

        if OperationDescription = '' then
            exit;

        if StrLen(OperationDescription) > MaxStrLen(Part1) then begin
            Part1 := CopyStr(OperationDescription, 1, MaxStrLen(Part1));
            Part2 := CopyStr(OperationDescription, MaxStrLen(Part1) + 1, StrLen(OperationDescription) - MaxStrLen(Part1));
        end else
            Part1 := CopyStr(OperationDescription, 1, StrLen(OperationDescription));
    end;

    procedure CharIsCapitalLetter(Char: Char): Boolean
    begin
        exit(Char in ['A' .. 'Z']);
    end;

    procedure IsAllowedSalesInvType(InvType: Option): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        exit(InvType in [SalesInvoiceHeader."Invoice Type"::"F1 Invoice".AsInteger(),
                         SalesInvoiceHeader."Invoice Type"::"F2 Simplified Invoice".AsInteger(),
                         SalesInvoiceHeader."Invoice Type"::"F3 Invoice issued to replace simplified invoices".AsInteger(),
                         SalesInvoiceHeader."Invoice Type"::"F4 Invoice summary entry".AsInteger(),
                         SalesInvoiceHeader."Invoice Type"::"R1 Corrected Invoice".AsInteger(),
                         SalesInvoiceHeader."Invoice Type"::"R2 Corrected Invoice (Art. 80.3)".AsInteger(),
                         SalesInvoiceHeader."Invoice Type"::"R3 Corrected Invoice (Art. 80.4)".AsInteger(),
                         SalesInvoiceHeader."Invoice Type"::"R4 Corrected Invoice (Other)".AsInteger(),
                         SalesInvoiceHeader."Invoice Type"::"R5 Corrected Invoice in Simplified Invoices".AsInteger()]);
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Serv. SII Management', '27.0')]
    procedure IsAllowedServInvType(InvType: Option): Boolean
    var
        ServSIIManagement: Codeunit Microsoft.EServices.EDocument."Serv. SII Management";
    begin
        exit(ServSIIManagement.IsAllowedServInvType(InvType));
    end;
#endif

    procedure Run347DeclarationToGenerateCollectionsInCash()
    var
        Make347Declaration: Report "Make 347 Declaration";
    begin
        Make347Declaration.SetCollectionInCashMode(true);
        Make347Declaration.RunModal();
    end;

    procedure UpdateSIIInfoInSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Special Scheme Code" :=
          GetSalesSpecialSchemeCode(SalesHeader."Bill-to Customer No.", SalesHeader."VAT Country/Region Code");
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Serv. SII Management', '27.0')]
    procedure UpdateSIIInfoInServiceDoc(var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        ServSIIManagement: Codeunit Microsoft.EServices.EDocument."Serv. SII Management";
    begin
        ServSIIManagement.UpdateSIIInfoInServiceDoc(ServiceHeader);
    end;
#endif

    procedure GetSalesSpecialSchemeCode(BillToCustomerNo: Code[20]; VATCountryRegionCode: Code[10]): Enum "SII Sales Special Scheme Code"
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer: Record Customer;
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."VAT Cash Regime" then
            exit("SII Sales Special Scheme Code"::"07 Special Cash");
        if BillToCustomerNo <> '' then
            if Customer.Get(BillToCustomerNo) then begin
                if CountryIsLocal(VATCountryRegionCode) or
                   CustomerIsIntraCommunity(Customer."No.")
                then
                    exit("SII Sales Special Scheme Code"::"01 General");
                exit("SII Sales Special Scheme Code"::"02 Export");
            end;
    end;

    procedure UpdateSIIInfoInPurchDoc(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        if PurchaseHeader."Pay-to Vendor No." <> '' then
            if Vendor.Get(PurchaseHeader."Pay-to Vendor No.") then
                if VendorIsIntraCommunity(Vendor."No.") then
                    PurchaseHeader."Special Scheme Code" := PurchaseHeader."Special Scheme Code"::"09 Intra-Community Acquisition"
                else
                    PurchaseHeader."Special Scheme Code" := PurchaseHeader."Special Scheme Code"::"01 General";
    end;

    local procedure DoNotReportNegativeLines(): Boolean
    var
        SIISetup: Record "SII Setup";
    begin
        if not SIISetup.Get() then
            exit(false);
        exit(SIISetup."Do Not Export Negative Lines");
    end;

    procedure MarkAsAccepted(var SIIHistory: Record "SII History")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        if not SIIHistory.FindSet() then
            exit;

        repeat
            if SIIHistory.Status in [SIIHistory.Status::Accepted, SIIHistory.Status::"Accepted With Errors"] then
                SIIHistory.FieldError(Status);

            SIIDocUploadState.Get(SIIHistory."Document State Id");
            SIIDocUploadState.Validate(Status, SIIDocUploadState.Status::"Accepted With Errors");
            SIIDocUploadState.Validate("Accepted By User ID", UserId);
            SIIDocUploadState.Validate("Accepted Date Time", CurrentDateTime);
            SIIDocUploadState.Modify();

            SIIHistory.Status := SIIHistory.Status::"Accepted With Errors";
            SIIHistory."Error Message" := StrSubstNo(MarkAsAcceptedErr, UserId, CurrentDateTime);
            SIIHistory.Modify();
        until SIIHistory.Next() = 0;
    end;

    procedure MarkAsNotAccepted(var SIIHistory: Record "SII History")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        if not SIIHistory.FindSet() then
            exit;

        repeat
            if not (SIIHistory.Status in [SIIHistory.Status::Accepted, SIIHistory.Status::"Accepted With Errors"]) then
                SIIHistory.FieldError(Status);

            SIIDocUploadState.Get(SIIHistory."Document State Id");
            SIIDocUploadState.Validate(Status, SIIDocUploadState.Status::Failed);
            SIIDocUploadState.Validate("Accepted By User ID", '');
            SIIDocUploadState.Validate("Accepted Date Time", 0DT);
            SIIDocUploadState.Modify();

            SIIHistory.Status := SIIHistory.Status::Failed;
            SIIHistory."Error Message" := StrSubstNo(MarkAsNotAcceptedErr, UserId, CurrentDateTime);
            SIIHistory.Modify();
        until SIIHistory.Next() = 0;
    end;

    procedure CountryIsNorthernIreland(CountryCode: Code[20]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryCode = 'XI' then
            if CountryRegion.Get(CountryCode) then
                exit(CountryRegion."ISO Code" = '');
    end;

    procedure GetTaxPeriod(PostingDate: Date) TaxPeriod: Text
    var
        SIISetup: Record "SII Setup";
    begin
        SIISetup.Get();
        case SIISetup."Tax Period" of
            SIISetup."Tax Period"::Monthly:
                exit(Format(PostingDate, 0, '<Month,2>'));
            SIISetup."Tax Period"::Quarterly:
                exit(Format((Date2DMY(PostingDate, 2) - 1) div 3 + 1) + 'T');
            else
                OnGetTaxPeriodOnElse(TaxPeriod, PostingDate);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoTaxableSalesAmount(var NoTaxableEntry: Record "No Taxable Entry"; SourceNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; PostingDate: Date; IsService: Boolean; UseNoTaxableType: Boolean; IsLocalRule: Boolean; var NoTaxableAmount: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTaxPeriodOnElse(var TaxPeriod: Text; PostingDate: Date)
    begin
    end;
}

