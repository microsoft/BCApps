// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Assembly.Document;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;

codeunit 229 "Document-Print"
{

    trigger OnRun()
    begin
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";

    procedure EmailSalesHeader(SalesHeader: Record "Sales Header")
    begin
        DoPrintSalesHeader(SalesHeader, true);
    end;

    procedure PrintSalesHeader(SalesHeader: Record "Sales Header")
    begin
        DoPrintSalesHeader(SalesHeader, false);
    end;

    procedure PrintSalesHeaderToDocumentAttachment(var SalesHeader: Record "Sales Header");
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := SalesHeader.Count() = 1;
        if SalesHeader.FindSet() then
            repeat
                DoPrintSalesHeaderToDocumentAttachment(SalesHeader, ShowNotificationAction);
            until SalesHeader.Next() = 0;
    end;

    local procedure DoPrintSalesHeaderToDocumentAttachment(SalesHeader: Record "Sales Header"; ShowNotificationAction: Boolean);
    var
        ReportUsage: Enum "Report Selection Usage";
        IsHandled: Boolean;
    begin
        ReportUsage := GetSalesDocTypeUsage(SalesHeader);

        SalesHeader.SetRecFilter();
        CalcSalesDisc(SalesHeader);

        IsHandled := false;
        OnDoPrintSalesHeaderToDocumentAttachmentOnBeforeRunSaveAsDocumentAttachment(SalesHeader, ReportUsage.AsInteger(), ShowNotificationAction, IsHandled);
        if not IsHandled then
            RunSaveAsDocumentAttachment(ReportUsage.AsInteger(), SalesHeader, SalesHeader."No.", SalesHeader.GetBillToNo(), ShowNotificationAction);
    end;

    local procedure RunSaveAsDocumentAttachment(ReportUsage: Integer; RecordVariant: Variant; DocumentNo: Code[20]; AccountNo: Code[20]; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunSaveAsDocumentAttachment(ReportUsage, RecordVariant, ShowNotificationAction, IsHandled);
        if IsHandled then
            exit;

        ReportSelections.SaveAsDocumentAttachment(ReportUsage, RecordVariant, DocumentNo, AccountNo, ShowNotificationAction);
    end;

    procedure PrintSalesInvoiceToDocumentAttachment(var SalesHeader: Record "Sales Header"; SalesInvoicePrintToAttachmentOption: Integer)
    begin
        case "Sales Invoice Print Option".FromInteger(SalesInvoicePrintToAttachmentOption) of
            "Sales Invoice Print Option"::"Draft Invoice":
                PrintSalesHeaderToDocumentAttachment(SalesHeader);
            "Sales Invoice Print Option"::"Pro Forma Invoice":
                PrintProformaSalesInvoiceToDocumentAttachment(SalesHeader);
        end;
        OnAfterPrintSalesInvoiceToDocumentAttachment(SalesHeader, SalesInvoicePrintToAttachmentOption);
    end;

    procedure GetSalesInvoicePrintToAttachmentOption(SalesHeader: Record "Sales Header"): Integer
    var
        StrMenuText: Text;
        PrintOptionCaption: Text;
        i: Integer;
    begin
        foreach i in "Sales Invoice Print Option".Ordinals() do begin
            PrintOptionCaption := Format("Sales Invoice Print Option".FromInteger(i));
            if StrMenuText = '' then
                StrMenuText := PrintOptionCaption
            else
                StrMenuText := StrMenuText + ',' + PrintOptionCaption;
        end;
        exit(StrMenu(StrMenuText));
    end;

    procedure PrintSalesOrderToDocumentAttachment(var SalesHeader: Record "Sales Header"; SalesOrderPrintToAttachmentOption: Integer)
    var
        Usage: Option "Order Confirmation","Work Order","Pick Instruction";
    begin
        case "Sales Order Print Option".FromInteger(SalesOrderPrintToAttachmentOption) of
            "Sales Order Print Option"::"Order Confirmation":
                PrintSalesOrderToAttachment(SalesHeader, Usage::"Order Confirmation");
            "Sales Order Print Option"::"Pro Forma Invoice":
                PrintProformaSalesInvoiceToDocumentAttachment(SalesHeader);
            "Sales Order Print Option"::"Work Order":
                PrintSalesOrderToAttachment(SalesHeader, Usage::"Work Order");
            "Sales Order Print Option"::"Pick Instruction":
                PrintSalesOrderToAttachment(SalesHeader, Usage::"Pick Instruction");
        end;
        OnAfterPrintSalesOrderToDocumentAttachment(SalesHeader, SalesOrderPrintToAttachmentOption);
    end;

    procedure GetSalesOrderPrintToAttachmentOption(SalesHeader: Record "Sales Header"): Integer
    var
        StrMenuText: Text;
        PrintOptionCaption: Text;
        i: Integer;
    begin
        foreach i in "Sales Order Print Option".Ordinals() do begin
            PrintOptionCaption := Format("Sales Order Print Option".FromInteger(i));
            if StrMenuText = '' then
                StrMenuText := PrintOptionCaption
            else
                StrMenuText := StrMenuText + ',' + PrintOptionCaption;
        end;
        exit(StrMenu(StrMenuText));
    end;

    procedure PrintProformaSalesInvoiceToDocumentAttachment(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.FindSet() then
            repeat
                DoPrintProformaSalesInvoiceToDocumentAttachment(SalesHeader, SalesHeader.Count() = 1)
            until SalesHeader.Next() = 0;
    end;

    local procedure DoPrintProformaSalesInvoiceToDocumentAttachment(SalesHeader: Record "Sales Header"; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        SalesHeader.SetRecFilter();
        CalcSalesDisc(SalesHeader);
        IsHandled := false;
        OnDoPrintProformaSalesInvoiceToDocumentAttachmentOnBeforeRunSaveAsDocumentAttachment(SalesHeader, ReportSelections.Usage::"Pro Forma S. Invoice".AsInteger(), ShowNotificationAction, IsHandled);
        if not IsHandled then
            RunSaveAsDocumentAttachment(ReportSelections.Usage::"Pro Forma S. Invoice".AsInteger(), SalesHeader, SalesHeader."No.", SalesHeader.GetBillToNo(), ShowNotificationAction);
    end;

    procedure PrintSalesOrderToAttachment(var SalesHeader: Record "Sales Header"; Usage: Option "Order Confirmation","Work Order","Pick Instruction")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := SalesHeader.Count() = 1;
        if SalesHeader.FindSet() then
            repeat
                DoPrintSalesOrderToAttachment(SalesHeader, Usage, ShowNotificationAction);
            until SalesHeader.Next() = 0;
    end;

    local procedure DoPrintSalesOrderToAttachment(SalesHeader: Record "Sales Header"; Usage: Option "Order Confirmation","Work Order","Pick Instruction"; ShowNotificationAction: Boolean)
    var
        ReportUsage: Enum "Report Selection Usage";
        IsHandled: Boolean;
    begin
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit;

        ReportUsage := GetSalesOrderUsage(Usage);

        SalesHeader.SetRange("No.", SalesHeader."No.");
        CalcSalesDisc(SalesHeader);
        IsHandled := false;
        OnDoPrintSalesOrderToAttachmentOnBeforeRunSaveAsDocumentAttachment(SalesHeader, ReportUsage.AsInteger(), ShowNotificationAction, IsHandled);
        if not IsHandled then
            RunSaveAsDocumentAttachment(ReportUsage.AsInteger(), SalesHeader, SalesHeader."No.", SalesHeader.GetBillToNo(), ShowNotificationAction);
    end;

    local procedure DoPrintSalesHeader(SalesHeader: Record "Sales Header"; SendAsEmail: Boolean)
    var
        ReportSelections: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
    begin
        ReportUsage := GetSalesDocTypeUsage(SalesHeader);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        CalcSalesDisc(SalesHeader);
        OnBeforeDoPrintSalesHeader(SalesHeader, ReportUsage.AsInteger(), SendAsEmail, IsPrinted);
        if IsPrinted then
            exit;

        if SendAsEmail then
            ReportSelections.SendEmailToCust(
                ReportUsage.AsInteger(), SalesHeader, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), true, SalesHeader.GetBillToNo())
        else
            ReportSelections.PrintForCust(ReportUsage, SalesHeader, SalesHeader.FieldNo("Bill-to Customer No."));

        OnAfterDoPrintSalesHeader(SalesHeader, SendAsEmail);
    end;

    procedure EmailPurchHeader(PurchaseHeader: Record "Purchase Header")
    begin
        DoPrintPurchHeader(PurchaseHeader, true);
    end;

    procedure PrintPurchHeader(PurchHeader: Record "Purchase Header")
    begin
        DoPrintPurchHeader(PurchHeader, false);
    end;

    local procedure DoPrintPurchHeader(PurchHeader: Record "Purchase Header"; SendAsEmail: Boolean)
    var
        ReportSelections: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
    begin
        ReportUsage := GetPurchDocTypeUsage(PurchHeader);

        PurchHeader.SetRange("Document Type", PurchHeader."Document Type");
        PurchHeader.SetRange("No.", PurchHeader."No.");
        CalcPurchDisc(PurchHeader);
        OnBeforeDoPrintPurchHeader(PurchHeader, ReportUsage.AsInteger(), SendAsEmail, IsPrinted);
        if IsPrinted then
            exit;

        if SendAsEmail then
            ReportSelections.SendEmailToVendor(
                ReportUsage.AsInteger(), PurchHeader, PurchHeader."No.", PurchHeader.GetDocTypeTxt(), true, PurchHeader."Buy-from Vendor No.")
        else
            ReportSelections.PrintWithDialogForVend(ReportUsage, PurchHeader, true, PurchHeader.FieldNo("Buy-from Vendor No."));

        OnAfterDoPrintPurchaseHeader(PurchHeader, SendAsEmail);
    end;

    procedure PrintPurchaseHeaderToDocumentAttachment(var PurchaseHeader: Record "Purchase Header");
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := PurchaseHeader.Count() = 1;
        if PurchaseHeader.FindSet() then
            repeat
                DoPrintPurchaseHeaderToDocumentAttachment(PurchaseHeader, ShowNotificationAction);
            until PurchaseHeader.Next() = 0;
    end;

    local procedure DoPrintPurchaseHeaderToDocumentAttachment(PurchaseHeader: Record "Purchase Header"; ShowNotificationAction: Boolean)
    var
        ReportUsage: Enum "Report Selection Usage";
        IsHandled: Boolean;
    begin
        ReportUsage := GetPurchDocTypeUsage(PurchaseHeader);

        PurchaseHeader.SetRecFilter();
        CalcPurchDisc(PurchaseHeader);
        IsHandled := false;
        OnDoPrintPurchaseHeaderToDocumentAttachmentOnBeforeRunSaveAsDocumentAttachment(PurchaseHeader, ReportUsage.AsInteger(), ShowNotificationAction, IsHandled);
        if not IsHandled then
            RunSaveAsDocumentAttachment(ReportUsage.AsInteger(), PurchaseHeader, PurchaseHeader."No.", PurchaseHeader."Pay-to Vendor No.", ShowNotificationAction);
    end;

    procedure PrintBankAccStmt(BankAccStmt: Record "Bank Account Statement")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        BankAccStmt.SetRecFilter();
        OnBeforePrintBankAccStmt(BankAccStmt, IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.PrintReport(ReportSelections.Usage::"B.Stmt", BankAccStmt);
    end;

    procedure PrintPostedPaymentReconciliation(PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        PostedPaymentReconHdr.SetRecFilter();
        OnBeforePrintPostedPaymentReconciliation(PostedPaymentReconHdr, IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.PrintReport(ReportSelections.Usage::"Posted Payment Reconciliation", PostedPaymentReconHdr);
    end;

    procedure PrintCheck(var NewGenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        IsPrinted := false;
        OnBeforePrintCheckProcedure(NewGenJnlLine, GenJnlLine, IsPrinted);
        if IsPrinted then
            exit;

        GenJnlLine.Copy(NewGenJnlLine);
        GenJnlLine.OnCheckGenJournalLinePrintCheckRestrictions();
        IsPrinted := false;
        OnBeforePrintCheck(GenJnlLine, IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.PrintReport(ReportSelections.Usage::"B.Check", GenJnlLine);
    end;

    procedure PrintTransferHeader(TransHeader: Record "Transfer Header")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        TransHeader.SetRange("No.", TransHeader."No.");
        OnBeforePrintTransferHeader(TransHeader, IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.PrintReport(ReportSelections.Usage::Inv1, TransHeader);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure PrintServiceContract in codeunit Serv. Report Management', '25.0')]
    procedure PrintServiceContract(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header")
    var
        ServDocumentPrint: Codeunit "Serv. Document Print";
    begin
        ServDocumentPrint.PrintServiceContract(ServiceContractHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure PrintServiceHeader in codeunit Serv. Report Management', '25.0')]
    procedure PrintServiceHeader(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        ServDocumentPrint: Codeunit "Serv. Document Print";
    begin
        ServDocumentPrint.PrintServiceHeader(ServiceHeader);
    end;
#endif

    procedure PrintAsmHeader(AsmHeader: Record "Assembly Header")
    var
        ReportSelections: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
    begin
        ReportUsage := GetAsmHeaderDocTypeUsage(AsmHeader);

        AsmHeader.SetRange("Document Type", AsmHeader."Document Type");
        AsmHeader.SetRange("No.", AsmHeader."No.");
        OnBeforePrintAsmHeader(AsmHeader, ReportUsage.AsInteger(), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.PrintReport(ReportUsage, AsmHeader);
    end;

    procedure PrintSalesOrder(SalesHeader: Record "Sales Header"; Usage: Option "Order Confirmation","Work Order","Pick Instruction")
    var
        ReportSelection: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessPrintSalesOrder(SalesHeader, Usage, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit;

        ReportUsage := GetSalesOrderUsage(Usage);

        SalesHeader.SetRecFilter();
        CalcSalesDisc(SalesHeader);
        OnBeforePrintSalesOrder(SalesHeader, ReportUsage.AsInteger(), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.PrintWithDialogForCust(
            ReportUsage, SalesHeader, GuiAllowed, SalesHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintSalesHeaderArch(SalesHeaderArch: Record "Sales Header Archive")
    var
        ReportSelection: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
    begin
        ReportUsage := GetSalesArchDocTypeUsage(SalesHeaderArch);

        SalesHeaderArch.SetRecFilter();
        OnBeforePrintSalesHeaderArch(SalesHeaderArch, ReportUsage.AsInteger(), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.PrintForCust(
            ReportUsage, SalesHeaderArch, SalesHeaderArch.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintPurchHeaderArch(PurchHeaderArch: Record "Purchase Header Archive")
    var
        ReportSelection: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
    begin
        ReportUsage := GetPurchArchDocTypeUsage(PurchHeaderArch);

        PurchHeaderArch.SetRecFilter();
        OnBeforePrintPurchHeaderArch(PurchHeaderArch, ReportUsage.AsInteger(), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.PrintWithDialogForVend(
            ReportUsage, PurchHeaderArch, true, PurchHeaderArch.FieldNo("Buy-from Vendor No."));
    end;

    procedure PrintProformaSalesInvoice(SalesHeader: Record "Sales Header")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        SalesHeader.SetRecFilter();
        OnBeforePrintProformaSalesInvoice(SalesHeader, ReportSelections.Usage::"Pro Forma S. Invoice".AsInteger(), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.PrintForCust(
            ReportSelections.Usage::"Pro Forma S. Invoice", SalesHeader, SalesHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintInvtOrderTest(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Phys.Invt.Order Test");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PhysInvtOrderHeader);
            until ReportSelections.Next() = 0;
    end;

    procedure PrintInvtOrder(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Phys.Invt.Order");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PhysInvtOrderHeader);
            until ReportSelections.Next() = 0;
    end;

    procedure PrintPostedInvtOrder(PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PstdPhysInvtOrderHdr.SetRange("No.", PstdPhysInvtOrderHdr."No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Phys.Invt.Order");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PstdPhysInvtOrderHdr);
            until ReportSelections.Next() = 0;
    end;

    procedure PrintInvtRecording(PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PhysInvtRecordHeader.SetRange("Order No.", PhysInvtRecordHeader."Order No.");
        PhysInvtRecordHeader.SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Phys.Invt.Rec.");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PhysInvtRecordHeader);
            until ReportSelections.Next() = 0;
    end;

    procedure PrintPostedInvtRecording(PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PstdPhysInvtRecordHdr.SetRange("Order No.", PstdPhysInvtRecordHdr."Order No.");
        PstdPhysInvtRecordHdr.SetRange("Recording No.", PstdPhysInvtRecordHdr."Recording No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Phys.Invt.Rec.");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PstdPhysInvtRecordHdr);
            until ReportSelections.Next() = 0;
    end;

    procedure PrintInvtDocument(var NewInvtDocHeader: Record "Invt. Document Header"; ShowRequestPage: Boolean)
    var
        InvtDocHeader: Record "Invt. Document Header";
        ReportSelections: Record "Report Selections";
    begin
        InvtDocHeader.Copy(NewInvtDocHeader);
        InvtDocHeader.SetRecFilter();

        case InvtDocHeader."Document Type" of
            InvtDocHeader."Document Type"::Receipt:
                ReportSelections.SetRange(Usage, ReportSelections.Usage::"Inventory Receipt");
            InvtDocHeader."Document Type"::Shipment:
                ReportSelections.SetRange(Usage, ReportSelections.Usage::"Inventory Shipment");
        end;
        ReportSelections.SetFilter("Report ID", '<>0');

        CheckNoReportSelectionThrowError(ReportSelections, InvtDocHeader);

        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestPage, false, InvtDocHeader);
            until ReportSelections.Next() = 0;
    end;

    procedure PrintInvtReceipt(NewInvtReceiptHeader: Record "Invt. Receipt Header"; ShowRequestPage: Boolean)
    var
        ReportSelections: Record "Report Selections";
        InvtReceiptHeader: Record "Invt. Receipt Header";
    begin
        InvtReceiptHeader.Copy(NewInvtReceiptHeader);
        InvtReceiptHeader.SetRecFilter();

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Inventory Receipt");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestPage, false, InvtReceiptHeader);
            until ReportSelections.Next() = 0;
    end;

    procedure PrintInvtShipment(NewInvtShipmentHeader: Record "Invt. Shipment Header"; ShowRequestPage: Boolean)
    var
        ReportSelections: Record "Report Selections";
        InvtShipmentHeader: Record "Invt. Shipment Header";
    begin
        InvtShipmentHeader.Copy(NewInvtShipmentHeader);
        InvtShipmentHeader.SetRecFilter();

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Inventory Shipment");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestPage, false, InvtShipmentHeader);
            until ReportSelections.Next() = 0;
    end;

    procedure PrintDirectTransfer(NewDirectTransHeader: Record "Direct Trans. Header"; ShowRequestPage: Boolean)
    var
        ReportSelections: Record "Report Selections";
        DirectTransHeader: Record "Direct Trans. Header";
    begin
        DirectTransHeader.Copy(NewDirectTransHeader);
        DirectTransHeader.SetRecFilter();

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Direct Transfer");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet() then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestPage, false, DirectTransHeader);
            until ReportSelections.Next() = 0;
    end;

    procedure GetSalesDocTypeUsage(SalesHeader: Record "Sales Header") ReportSelectionUsage: Enum "Report Selection Usage"
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesDocTypeUsage(SalesHeader, ReportSelectionUsage, IsHandled);
        if IsHandled then
            exit(ReportSelectionUsage);

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                exit(ReportSelections.Usage::"S.Quote");
            SalesHeader."Document Type"::"Blanket Order":
                exit(ReportSelections.Usage::"S.Blanket");
            SalesHeader."Document Type"::Order:
                exit(ReportSelections.Usage::"S.Order");
            SalesHeader."Document Type"::"Return Order":
                exit(ReportSelections.Usage::"S.Return");
            SalesHeader."Document Type"::Invoice:
                exit(ReportSelections.Usage::"S.Invoice Draft");
            SalesHeader."Document Type"::"Credit Memo":
                exit(ReportSelections.Usage::"S.Invoice Draft");
            else begin
                IsHandled := false;
                OnGetSalesDocTypeUsageElseCase(SalesHeader, TypeUsage, IsHandled);
                if IsHandled then
                    exit("Report Selection Usage".FromInteger(TypeUsage));
                Error('');
            end;
        end;
    end;

    procedure GetPurchDocTypeUsage(PurchHeader: Record "Purchase Header") ReportSelectionUsage: Enum "Report Selection Usage"
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchDocTypeUsage(PurchHeader, ReportSelectionUsage, IsHandled);
        if IsHandled then
            exit(ReportSelectionUsage);

        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Quote:
                exit(ReportSelections.Usage::"P.Quote");
            PurchHeader."Document Type"::"Blanket Order":
                exit(ReportSelections.Usage::"P.Blanket");
            PurchHeader."Document Type"::Order:
                exit(ReportSelections.Usage::"P.Order");
            PurchHeader."Document Type"::"Return Order":
                exit(ReportSelections.Usage::"P.Return");
            else begin
                IsHandled := false;
                OnGetPurchDocTypeUsageElseCase(PurchHeader, TypeUsage, IsHandled);
                if IsHandled then
                    exit("Report Selection Usage".FromInteger(TypeUsage));
                Error('');
            end;
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Serv. Report Management ', '25.0')]
    procedure GetServContractTypeUsage(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header"): Enum "Report Selection Usage"
    var
        ServDocumentPrint: Codeunit "Serv. Document Print";
    begin
        exit(ServDocumentPrint.GetServContractTypeUsage(ServiceContractHeader));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Serv. Report Management ', '25.0')]
    procedure GetServHeaderDocTypeUsage(ServiceHeader: Record Microsoft.Service.Document."Service Header"): Enum "Report Selection Usage"
    var
        ServDocumentPrint: Codeunit "Serv. Document Print";
    begin
        exit(ServDocumentPrint.GetServHeaderDocTypeUsage(ServiceHeader));
    end;
#endif

    procedure GetAsmHeaderDocTypeUsage(AsmHeader: Record "Assembly Header"): Enum "Report Selection Usage"
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case AsmHeader."Document Type" of
            AsmHeader."Document Type"::Quote,
            AsmHeader."Document Type"::"Blanket Order",
            AsmHeader."Document Type"::Order:
                exit(ReportSelections.Usage::"Asm.Order");
            else begin
                IsHandled := false;
                OnGetAsmHeaderTypeUsageElseCase(AsmHeader, TypeUsage, IsHandled);
                if IsHandled then
                    exit("Report Selection Usage".FromInteger(TypeUsage));
                Error('');
            end;
        end;
    end;

    procedure GetSalesOrderUsage(Usage: Option "Order Confirmation","Work Order","Pick Instruction") Result: Enum "Report Selection Usage"
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        case Usage of
            Usage::"Order Confirmation":
                exit(ReportSelections.Usage::"S.Order");
            Usage::"Work Order":
                exit(ReportSelections.Usage::"S.Work Order");
            Usage::"Pick Instruction":
                exit(ReportSelections.Usage::"S.Order Pick Instruction");
            else
                IsHandled := false;
                OnGetSalesOrderUsageElseCase(Usage, Result, IsHandled);
                if not IsHandled then
                    Error('');
        end;
    end;

    procedure GetSalesArchDocTypeUsage(SalesHeaderArchive: Record "Sales Header Archive"): Enum "Report Selection Usage"
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case SalesHeaderArchive."Document Type" of
            SalesHeaderArchive."Document Type"::Quote:
                exit(ReportSelections.Usage::"S.Arch.Quote");
            SalesHeaderArchive."Document Type"::Order:
                exit(ReportSelections.Usage::"S.Arch.Order");
            SalesHeaderArchive."Document Type"::"Return Order":
                exit(ReportSelections.Usage::"S.Arch.Return");
            SalesHeaderArchive."Document Type"::"Blanket Order":
                exit(ReportSelections.Usage::"S.Arch.Blanket");
            else begin
                IsHandled := false;
                OnGetSalesArchDocTypeUsageElseCase(SalesHeaderArchive, TypeUsage, IsHandled);
                if IsHandled then
                    exit("Report Selection Usage".FromInteger(TypeUsage));
                Error('');
            end;
        end
    end;

    procedure GetPurchArchDocTypeUsage(PurchHeaderArchive: Record "Purchase Header Archive"): Enum "Report Selection Usage"
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case PurchHeaderArchive."Document Type" of
            PurchHeaderArchive."Document Type"::Quote:
                exit(ReportSelections.Usage::"P.Arch.Quote");
            PurchHeaderArchive."Document Type"::Order:
                exit(ReportSelections.Usage::"P.Arch.Order");
            PurchHeaderArchive."Document Type"::"Return Order":
                exit(ReportSelections.Usage::"P.Arch.Return");
            PurchHeaderArchive."Document Type"::"Blanket Order":
                exit(ReportSelections.Usage::"P.Arch.Blanket");
            else begin
                IsHandled := false;
                OnGetPurchArchDocTypeUsageElseCase(PurchHeaderArchive, TypeUsage, IsHandled);
                if IsHandled then
                    exit("Report Selection Usage".FromInteger(TypeUsage));
                Error('');
            end;
        end;
    end;

    procedure CalcSalesDisc(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcSalesDisc(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if SalesSetup."Calc. Inv. Discount" then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.FindFirst();
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
            Commit();
        end;
    end;

    procedure CalcPurchDisc(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPurchDisc(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get();
        if PurchSetup."Calc. Inv. Discount" then begin
            PurchLine.Reset();
            PurchLine.SetRange("Document Type", PurchHeader."Document Type");
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            PurchLine.FindFirst();
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
            PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
            Commit();
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Serv. Report Management', '25.0')]
    procedure CalcServDisc(var ServHeader: Record Microsoft.Service.Document."Service Header")
    var
        ServDocumentPrint: Codeunit "Serv. Document Print";
    begin
        ServDocumentPrint.CalcServDisc(ServHeader);
    end;
#endif

    local procedure CheckNoReportSelectionThrowError(var ReportSelections: Record "Report Selections"; InvtDocumentHeader: Record "Invt. Document Header")
    var
        NoReportSelectionErrorInfo: ErrorInfo;
        NoReportSelectionTitleLbl: Label 'Report ID not selected';
        NoReportSelectionMessageLbl: Label 'For printing the document, a report must be selected. Please select a report and try again.';
        OpenReportSelectionInventoryLbl: Label 'Open Report Selection - Inventory';
    begin
        if not ReportSelections.IsEmpty then
            exit;
        NoReportSelectionErrorInfo.ErrorType(ErrorType::Client);
        NoReportSelectionErrorInfo.Verbosity(Verbosity::Error);
        NoReportSelectionErrorInfo.RecordId(InvtDocumentHeader.RecordId);
        NoReportSelectionErrorInfo.TableId(Database::"Invt. Document Header");
        NoReportSelectionErrorInfo.Title(NoReportSelectionTitleLbl);
        NoReportSelectionErrorInfo.Message(NoReportSelectionMessageLbl);
        NoReportSelectionErrorInfo.AddAction(OpenReportSelectionInventoryLbl, Codeunit::"Document-Print", 'OpenReportSelectionInventory');
        Error(NoReportSelectionErrorInfo);
    end;

    procedure OpenReportSelectionInventory(NoReportSelectionErrorInfo: ErrorInfo)
    var
        ReportSelections: Record "Report Selections";
        InvtDocumentHeader: Record "Invt. Document Header";
        ReportSelectionInventory: Page "Report Selection - Inventory";
    begin
        case NoReportSelectionErrorInfo.TableId of
            Database::"Invt. Document Header":
                begin
                    InvtDocumentHeader.Get(NoReportSelectionErrorInfo.RecordId);

                    case InvtDocumentHeader."Document Type" of
                        InvtDocumentHeader."Document Type"::Receipt:
                            ReportSelections.SetRange(Usage, ReportSelections.Usage::"Inventory Receipt");
                        InvtDocumentHeader."Document Type"::Shipment:
                            ReportSelections.SetRange(Usage, ReportSelections.Usage::"Inventory Shipment");
                    end;
                end;
        end;

        ReportSelectionInventory.SetTableView(ReportSelections);
        ReportSelectionInventory.RunModal();
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Serv. Report Management ', '25.0')]
    procedure PrintServiceHeaderToDocumentAttachment(var ServiceHeader: Record Microsoft.Service.Document."Service Header");
    var
        ServDocumentPrint: Codeunit "Serv. Document Print";
    begin
        ServDocumentPrint.PrintServiceHeaderToDocumentAttachment(ServiceHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Serv. Report Management ', '25.0')]
    procedure PrintServiceContractToDocumentAttachment(var ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header");
    var
        ServDocumentPrint: Codeunit "Serv. Document Print";
    begin
        ServDocumentPrint.PrintServiceContractToDocumentAttachment(ServiceContractHeader);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterDoPrintSalesHeader(var SalesHeader: Record "Sales Header"; SendAsEmail: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDoPrintPurchaseHeader(var PurchHeader: Record "Purchase Header"; SendAsEmail: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintSalesInvoiceToDocumentAttachment(var SalesHeader: Record "Sales Header"; SalesInvoicePrintToAttachmentOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintSalesOrderToDocumentAttachment(var SalesHeader: Record "Sales Header"; SalesOrderPrintToAttachmentOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesDisc(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeCalcServDisc(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
        OnBeforeCalcServDisc(ServiceHeader, IsHandled);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. Report Management', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcServDisc(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPurchDisc(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchDocTypeUsage(PurchaseHeader: Record "Purchase Header"; var ReportSelectionUsage: Enum "Report Selection Usage"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesDocTypeUsage(SalesHeader: Record "Sales Header"; var ReportSelectionUsage: Enum "Report Selection Usage"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintSalesHeader(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; SendAsEmail: Boolean; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintPurchHeader(var PurchHeader: Record "Purchase Header"; ReportUsage: Integer; SendAsEmail: Boolean; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintBankAccStmt(var BankAccountStatement: Record "Bank Account Statement"; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPostedPaymentReconciliation(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr"; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintCheck(var GenJournalLine: Record "Gen. Journal Line"; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintCheckProcedure(var NewGenJnlLine: Record "Gen. Journal Line"; var GenJournalLine: Record "Gen. Journal Line"; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintTransferHeader(var TransferHeader: Record "Transfer Header"; var IsPrinted: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforePrintServiceContract(var ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
        OnBeforePrintServiceContract(ServiceContractHeader, ReportUsage, IsPrinted);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. Report Management', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintServiceContract(var ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforePrintServiceHeader(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
        OnBeforePrintServiceHeader(ServiceHeader, ReportUsage, IsPrinted);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. Report Management', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintServiceHeader(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintAsmHeader(var AssemblyHeader: Record "Assembly Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintSalesOrder(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintSalesHeaderArch(var SalesHeaderArchive: Record "Sales Header Archive"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPurchHeaderArch(var PurchaseHeaderArchive: Record "Purchase Header Archive"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintProformaSalesInvoice(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunSaveAsDocumentAttachment(ReportUsage: Integer; RecordVariant: Variant; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAsmHeaderTypeUsageElseCase(AssemblyHeader: Record "Assembly Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchDocTypeUsageElseCase(PurchaseHeader: Record "Purchase Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesDocTypeUsageElseCase(SalesHeader: Record "Sales Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnGetServHeaderDocTypeUsageElseCase(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
        OnGetServHeaderDocTypeUsageElseCase(ServiceHeader, TypeUsage, IsHandled);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. Report Management', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetServHeaderDocTypeUsageElseCase(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnGetServContractTypeUsageElseCase(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
        OnGetServContractTypeUsageElseCase(ServiceContractHeader, TypeUsage, IsHandled);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. Report Management', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetServContractTypeUsageElseCase(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesArchDocTypeUsageElseCase(SalesHeaderArchive: Record "Sales Header Archive"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchArchDocTypeUsageElseCase(PurchaseHeaderArchive: Record "Purchase Header Archive"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesOrderUsageElseCase(Usage: Option; var Result: Enum "Report Selection Usage"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoPrintSalesHeaderToDocumentAttachmentOnBeforeRunSaveAsDocumentAttachment(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoPrintProformaSalesInvoiceToDocumentAttachmentOnBeforeRunSaveAsDocumentAttachment(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoPrintSalesOrderToAttachmentOnBeforeRunSaveAsDocumentAttachment(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoPrintPurchaseHeaderToDocumentAttachmentOnBeforeRunSaveAsDocumentAttachment(var PurchaseHeader: Record "Purchase Header"; ReportUsage: Integer; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessPrintSalesOrder(var SalesHeader: Record "Sales Header"; Usage: Option "Order Confirmation","Work Order","Pick Instruction"; var IsHandled: Boolean)
    begin
    end;
}

