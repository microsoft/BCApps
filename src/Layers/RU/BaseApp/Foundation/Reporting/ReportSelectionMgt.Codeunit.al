// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Bank.Reports;
using Microsoft.Inventory.Counting.Reports;
using Microsoft.Inventory.Reports;
using Microsoft.Projects.Project.Reports;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Reports;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Setup;

codeunit 1901 "Report Selection Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure InitReportSelectionSales()
    begin
        OnBeforeInitReportSelectionSales();

        InitReportSelection("Report Selection Usage"::"Pro Forma S. Invoice");
        InitReportSelection("Report Selection Usage"::"S.Invoice Draft");
        InitReportSelection("Report Selection Usage"::"S.Quote");
        InitReportSelection("Report Selection Usage"::"S.Blanket");
        InitReportSelection("Report Selection Usage"::"S.Order");
        InitReportSelection("Report Selection Usage"::"S.Work Order");
        InitReportSelection("Report Selection Usage"::"S.Invoice");
        InitReportSelection("Report Selection Usage"::"S.Return");
        InitReportSelection("Report Selection Usage"::"S.Cr.Memo");
        InitReportSelection("Report Selection Usage"::"S.Shipment");
        InitReportSelection("Report Selection Usage"::"S.Ret.Rcpt.");
        InitReportSelection("Report Selection Usage"::"S.Test");
        InitReportSelection("Report Selection Usage"::"S.Test Prepmt.");
        InitReportSelection("Report Selection Usage"::"S.Arch.Quote");
        InitReportSelection("Report Selection Usage"::"S.Arch.Order");
        InitReportSelection("Report Selection Usage"::"S.Arch.Return");
        InitReportSelection("Report Selection Usage"::"S.Arch.Blanket");
        InitReportSelection("Report Selection Usage"::"S.Order Pick Instruction");
        InitReportSelection("Report Selection Usage"::USI);
        InitReportSelection("Report Selection Usage"::USCM);
        InitReportSelection("Report Selection Usage"::UCSD);
        InitReportSelection("Report Selection Usage"::CSI);
        InitReportSelection("Report Selection Usage"::CSCM);

        OnAfterInitReportSelectionSales();
    end;

    procedure InitReportSelectionPurch()
    begin
        OnBeforeInitReportSelectionPurch();

        InitReportSelection("Report Selection Usage"::"P.Quote");
        InitReportSelection("Report Selection Usage"::"P.Blanket");
        InitReportSelection("Report Selection Usage"::"P.Order");
        InitReportSelection("Report Selection Usage"::"P.Invoice");
        InitReportSelection("Report Selection Usage"::"P.Self Billing Invoice");
        InitReportSelection("Report Selection Usage"::"P.Return");
        InitReportSelection("Report Selection Usage"::"P.Cr.Memo");
        InitReportSelection("Report Selection Usage"::"P.Receipt");
        InitReportSelection("Report Selection Usage"::"P.Ret.Shpt.");
        InitReportSelection("Report Selection Usage"::"P.Test");
        InitReportSelection("Report Selection Usage"::"P.Test Prepmt.");
        InitReportSelection("Report Selection Usage"::"P.Arch.Quote");
        InitReportSelection("Report Selection Usage"::"P.Arch.Order");
        InitReportSelection("Report Selection Usage"::"P.Arch.Return");
        InitReportSelection("Report Selection Usage"::"P.Arch.Blanket");
        InitReportSelection("Report Selection Usage"::UPI);
        InitReportSelection("Report Selection Usage"::UPCM);
        InitReportSelection("Report Selection Usage"::UAS);
        InitReportSelection("Report Selection Usage"::AS);

        OnAfterInitReportSelectionPurch();
    end;

    procedure InitReportSelectionInvt()
    begin
        OnBeforeInitReportSelectionInvt();

        InitReportSelection("Report Selection Usage"::Inv1);
        InitReportSelection("Report Selection Usage"::Inv2);
        InitReportSelection("Report Selection Usage"::Inv3);
        InitReportSelection("Report Selection Usage"::"Invt.Period Test");
        InitReportSelection("Report Selection Usage"::"Phys.Invt.Order Test");
        InitReportSelection("Report Selection Usage"::"Phys.Invt.Order");
        InitReportSelection("Report Selection Usage"::"P.Phys.Invt.Order");
        InitReportSelection("Report Selection Usage"::"Phys.Invt.Rec.");
        InitReportSelection("Report Selection Usage"::"P.Phys.Invt.Rec.");
        InitReportSelection("Report Selection Usage"::"Asm.Order");
        InitReportSelection("Report Selection Usage"::"P.Asm.Order");
        InitReportSelection("Report Selection Usage"::"Inventory Shipment");
        InitReportSelection("Report Selection Usage"::"P.Inventory Shipment");
        InitReportSelection("Report Selection Usage"::"Inventory Receipt");
        InitReportSelection("Report Selection Usage"::"P.Inventory Receipt");
        InitReportSelection("Report Selection Usage"::PIJ);
        InitReportSelection("Report Selection Usage"::IRJ);

        OnAfterInitReportSelectionInvt();
    end;

    procedure InitReportSelectionBank()
    begin
        OnBeforeInitReportSelectionBank();

        InitReportSelection("Report Selection Usage"::"B.Stmt");
        InitReportSelection("Report Selection Usage"::"B.Recon.Test");
        InitReportSelection("Report Selection Usage"::"B.Check");
        InitReportSelection("Report Selection Usage"::"Posted Payment Reconciliation");
        InitReportSelection("Report Selection Usage"::CB);
        InitReportSelection("Report Selection Usage"::UCI);
        InitReportSelection("Report Selection Usage"::UCO);
        InitReportSelection("Report Selection Usage"::CI);
        InitReportSelection("Report Selection Usage"::CO);

        OnAfterInitReportSelectionBank();
    end;

    procedure InitReportSelectionCust()
    begin
        OnBeforeInitReportSelectionCust();

        InitReportSelection("Report Selection Usage"::Reminder);
        InitReportSelection("Report Selection Usage"::"Fin.Charge");
        InitReportSelection("Report Selection Usage"::"Rem.Test");
        InitReportSelection("Report Selection Usage"::"F.C.Test");
        InitReportSelection("Report Selection Usage"::"C.Statement");

        OnAfterInitReportSelectionCust();
    end;

    procedure InitReportSelectionServ()
    begin
        OnBeforeInitReportSelectionServ();

        OnAfterInitReportSelectionServ();
    end;

    procedure InitReportSelectionProd()
    begin
        OnBeforeInitReportSelectionProd();

        OnAfterInitReportSelectionProd();
    end;

    procedure InitReportSelectionWhse()
    begin
        OnBeforeInitReportSelectionWhse();

        InitReportSelectionWhse("Report Selection Warehouse Usage"::Pick);
        InitReportSelectionWhse("Report Selection Warehouse Usage"::"Put-away");
        InitReportSelectionWhse("Report Selection Warehouse Usage"::Movement);
        InitReportSelectionWhse("Report Selection Warehouse Usage"::"Invt. Pick");
        InitReportSelectionWhse("Report Selection Warehouse Usage"::"Invt. Put-away");
        InitReportSelectionWhse("Report Selection Warehouse Usage"::"Invt. Movement");
        InitReportSelectionWhse("Report Selection Warehouse Usage"::Receipt);
        InitReportSelectionWhse("Report Selection Warehouse Usage"::"Posted Receipt");
        InitReportSelectionWhse("Report Selection Warehouse Usage"::Shipment);
        InitReportSelectionWhse("Report Selection Warehouse Usage"::"Posted Shipment");

        OnAfterInitReportSelectionWhse();
    end;

    procedure InitReportSelectionFixedAssets()
    begin
        InitReportSelection("Report Selection Usage"::UFAW);
        InitReportSelection("Report Selection Usage"::FAW);
        InitReportSelection("Report Selection Usage"::UFAM);
        InitReportSelection("Report Selection Usage"::FAM);
        InitReportSelection("Report Selection Usage"::UFAR);
        InitReportSelection("Report Selection Usage"::FAR);
        InitReportSelection("Report Selection Usage"::FARJ);
        InitReportSelection("Report Selection Usage"::FAJ);
    end;

    procedure InitReportSelectionJob()
    begin
        OnBeforeInitReportSelectionJobs();
        InitReportSelection("Report Selection Usage"::JQ);
        InitReportSelection("Report Selection Usage"::"Job Task Quote");
        OnAfterInitReportSelectionJobs();
    end;

    procedure InitReportSelection(ReportUsage: Enum "Report Selection Usage")
    begin
        case ReportUsage of
            "Report Selection Usage"::"Pro Forma S. Invoice":
                InsertRepSelection("Report Selection Usage"::"Pro Forma S. Invoice", '1', REPORT::"Standard Sales - Pro Forma Inv", true, false, true);
            "Report Selection Usage"::"S.Invoice Draft":
                InsertRepSelection("Report Selection Usage"::"S.Invoice Draft", '1', REPORT::"Standard Sales - Draft Invoice", true, false, true);
            "Report Selection Usage"::"S.Quote":
                InsertRepSelection("Report Selection Usage"::"S.Quote", '1', REPORT::"Standard Sales - Quote", true, false, true);
            "Report Selection Usage"::"S.Blanket":
                InsertRepSelection("Report Selection Usage"::"S.Blanket", '1', REPORT::"Blanket Sales Order", true, false, true);
            "Report Selection Usage"::"S.Order":
                begin
                    InsertRepSelection("Report Selection Usage"::"S.Order", '1', REPORT::"Standard Sales - Order Conf.", false, false, true);
                    InsertRepSelection("Report Selection Usage"::"S.Order", '2', REPORT::"Order Proforma-Invoice (A)", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Order", '3', REPORT::"Order Factura-Invoice (A)", false, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Order", '4', REPORT::"Order Item Shipment TORG-12", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Order", '5', REPORT::"Order Item Waybill 1-T", false, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Order", '6', REPORT::"Sales Shipment M-15", false, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Order", '7', REPORT::"Pick Instruction", false, false, true);
                end;
            "Report Selection Usage"::"S.Work Order":
                InsertRepSelection("Report Selection Usage"::"S.Work Order", '1', REPORT::"Work Order", true, false, true);
            "Report Selection Usage"::"S.Invoice":
                begin
                    InsertRepSelection("Report Selection Usage"::"S.Invoice", '2', REPORT::"Posted Factura-Invoice (A)", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Invoice", '3', REPORT::"Posted Inv. Shipment TORG-12", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Invoice", '4', REPORT::"Posted Inv. Item Waybill 1-T", false, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Invoice", '5', REPORT::"Posted Sales Shipment M-15", false, false, false);
                end;
            "Report Selection Usage"::"S.Return":
                begin
                    InsertRepSelection("Report Selection Usage"::"S.Return", '1', REPORT::"Return Order Confirmation", true, false, true);
                    InsertRepSelection("Report Selection Usage"::"S.Return", '2', REPORT::"Order Proforma-Invoice (A)", true, false, true);
                    InsertRepSelection("Report Selection Usage"::"S.Return", '3', REPORT::"Order Factura-Invoice (A)", false, false, true);
                    InsertRepSelection("Report Selection Usage"::"S.Return", '4', REPORT::"Order Item Shipment TORG-12", true, false, true);
                    InsertRepSelection("Report Selection Usage"::"S.Return", '5', REPORT::"Order Item Waybill 1-T", false, false, true);
                    InsertRepSelection("Report Selection Usage"::"S.Return", '6', REPORT::"Sales Shipment M-15", false, false, true);
                end;
            "Report Selection Usage"::"S.Cr.Memo":
                begin
                    InsertRepSelection("Report Selection Usage"::"S.Cr.Memo", '1', REPORT::"Standard Sales - Credit Memo", false, false, true);
                    InsertRepSelection("Report Selection Usage"::"S.Cr.Memo", '2', REPORT::"Posted Cr. M. Factura-Invoice", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Cr.Memo", '3', REPORT::"Posted Cr. M. Shipment TORG-12", false, false, false);
                end;
            "Report Selection Usage"::"S.Shipment":
                begin
                    InsertRepSelection("Report Selection Usage"::"S.Shipment", '1', REPORT::"Sales - Shipment", false, false, true);
                    InsertRepSelection("Report Selection Usage"::"S.Shipment", '2', REPORT::"Posted Ship. Shipment TORG-12", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"S.Shipment", '3', REPORT::"Posted Ship. Item Waybill 1-T", false, false, false);
                end;
            "Report Selection Usage"::"S.Ret.Rcpt.":
                InsertRepSelection("Report Selection Usage"::"S.Ret.Rcpt.", '1', REPORT::"Sales - Return Receipt", true, false, true);
            "Report Selection Usage"::"S.Test":
                InsertRepSelection("Report Selection Usage"::"S.Test", '1', REPORT::"Sales Document - Test", true, false, true);
            "Report Selection Usage"::"P.Quote":
                InsertRepSelection("Report Selection Usage"::"P.Quote", '1', REPORT::"Purchase - Quote", true, false, true);
            "Report Selection Usage"::"P.Blanket":
                InsertRepSelection("Report Selection Usage"::"P.Blanket", '1', REPORT::"Blanket Purchase Order", true, false, true);
            "Report Selection Usage"::"P.Order":
                begin
                    InsertRepSelection("Report Selection Usage"::"P.Order", '1', REPORT::Order, true, false, true);
                    InsertRepSelection("Report Selection Usage"::"P.Order", '2', REPORT::"Purchase Receipt M-4", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"P.Order", '3', REPORT::"Purch. FA Receipt FA-14", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"P.Order", '4', REPORT::"Act Items Receipt M-7", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"P.Order", '5', REPORT::"Items Receipt Act TORG-1", false, false, false);
                    InsertRepSelection("Report Selection Usage"::"P.Order", '6', REPORT::"Receipt Deviations TORG-2", false, true, false);
                end;
            "Report Selection Usage"::"P.Invoice":
                begin
                    InsertRepSelection("Report Selection Usage"::"P.Invoice", '1', REPORT::"Posted Purchase Receipt M-4", true, false, false);
                    InsertRepSelection("Report Selection Usage"::"P.Invoice", '2', REPORT::"Posted Purch. FA Receipt FA-14", false, false, false);
                    InsertRepSelection("Report Selection Usage"::"P.Invoice", '3', REPORT::"Pstd. Purch. Factura-Invoice", false, false, false);
                end;
            "Report Selection Usage"::"P.Self Billing Invoice":
                InsertRepSelection("Report Selection Usage"::"P.Self Billing Invoice", '1', REPORT::"Self Billing Invoice", true, false, false);
            "Report Selection Usage"::"P.Return":
                InsertRepSelection("Report Selection Usage"::"P.Return", '1', REPORT::"Return Order", true, false, true);
            "Report Selection Usage"::"P.Cr.Memo":
                InsertRepSelection("Report Selection Usage"::"P.Cr.Memo", '1', REPORT::"Purchase - Credit Memo", true, false, true);
            "Report Selection Usage"::"P.Receipt":
                InsertRepSelection("Report Selection Usage"::"P.Receipt", '1', REPORT::"Purchase - Receipt", true, false, true);
            "Report Selection Usage"::"P.Ret.Shpt.":
                InsertRepSelection("Report Selection Usage"::"P.Ret.Shpt.", '1', REPORT::"Purchase - Return Shipment", true, false, true);
            "Report Selection Usage"::"P.Test":
                InsertRepSelection("Report Selection Usage"::"P.Test", '1', REPORT::"Purchase Document - Test", true, false, true);
            "Report Selection Usage"::"B.Stmt":
                InsertRepSelection("Report Selection Usage"::"B.Stmt", '1', REPORT::"Bank Account Statement", true, false, true);
            "Report Selection Usage"::"B.Recon.Test":
                InsertRepSelection("Report Selection Usage"::"B.Recon.Test", '1', REPORT::"Bank Acc. Recon. - Test", true, false, true);
            "Report Selection Usage"::"B.Check":
                InsertRepSelection("Report Selection Usage"::"B.Check", '1', REPORT::"Bank Payment Order", true, false, true);
            "Report Selection Usage"::Reminder:
                InsertRepSelection("Report Selection Usage"::Reminder, '1', REPORT::Reminder, true, false, true);
            "Report Selection Usage"::"Fin.Charge":
                InsertRepSelection("Report Selection Usage"::"Fin.Charge", '1', REPORT::"Finance Charge Memo", true, false, true);
            "Report Selection Usage"::"Rem.Test":
                InsertRepSelection("Report Selection Usage"::"Rem.Test", '1', REPORT::"Reminder - Test", true, false, true);
            "Report Selection Usage"::"F.C.Test":
                InsertRepSelection("Report Selection Usage"::"F.C.Test", '1', REPORT::"Finance Charge Memo - Test", true, false, true);
            "Report Selection Usage"::Inv1:
                begin
                    InsertRepSelection("Report Selection Usage"::Inv1, '1', REPORT::"Transfer Order TORG-13", true, false, false);
                    InsertRepSelection("Report Selection Usage"::Inv1, '2', REPORT::"Shipment Request M-11", false, false, false);
                end;
            "Report Selection Usage"::Inv2:
                begin
                    InsertRepSelection("Report Selection Usage"::Inv2, '1', REPORT::"Transfer Shipment TORG-13", true, false, false);
                    InsertRepSelection("Report Selection Usage"::Inv2, '2', REPORT::"Shipment Request M-11", false, false, true);
                end;
            "Report Selection Usage"::Inv3:
                begin
                    InsertRepSelection("Report Selection Usage"::Inv3, '1', REPORT::"Transfer Receipt TORG-13", true, false, false);
                    InsertRepSelection("Report Selection Usage"::Inv3, '2', REPORT::"Shipment Request M-11", false, false, true);
                end;
            "Report Selection Usage"::"Invt.Period Test":
                InsertRepSelection("Report Selection Usage"::"Invt.Period Test", '1', REPORT::"Close Inventory Period - Test", true, false, true);
            "Report Selection Usage"::"Phys.Invt.Order Test":
                InsertRepSelection("Report Selection Usage"::"Phys.Invt.Order Test", '1', REPORT::"Phys. Invt. Order - Test", true, false, true);
            "Report Selection Usage"::"Phys.Invt.Order":
                InsertRepSelection("Report Selection Usage"::"Phys.Invt.Order", '1', REPORT::"Phys. Invt. Order Diff. List", true, false, true);
            "Report Selection Usage"::"P.Phys.Invt.Order":
                InsertRepSelection("Report Selection Usage"::"P.Phys.Invt.Order", '1', REPORT::"Posted Phys. Invt. Order Diff.", true, false, true);
            "Report Selection Usage"::"Phys.Invt.Rec.":
                InsertRepSelection("Report Selection Usage"::"Phys.Invt.Rec.", '1', REPORT::"Phys. Invt. Recording", true, false, true);
            "Report Selection Usage"::"P.Phys.Invt.Rec.":
                InsertRepSelection("Report Selection Usage"::"P.Phys.Invt.Rec.", '1', REPORT::"Posted Phys. Invt. Recording", true, false, true);
            "Report Selection Usage"::"Asm.Order":
                InsertRepSelection("Report Selection Usage"::"Asm.Order", '1', REPORT::"Assembly Order", true, false, true);
            "Report Selection Usage"::"P.Asm.Order":
                InsertRepSelection("Report Selection Usage"::"P.Asm.Order", '1', REPORT::"Posted Assembly Order", true, false, true);
            "Report Selection Usage"::"S.Test Prepmt.":
                InsertRepSelection("Report Selection Usage"::"S.Test Prepmt.", '1', REPORT::"Sales Prepmt. Document Test", true, false, true);
            "Report Selection Usage"::"P.Test Prepmt.":
                InsertRepSelection("Report Selection Usage"::"P.Test Prepmt.", '1', REPORT::"Purchase Prepmt. Doc. - Test", true, false, true);
            "Report Selection Usage"::"S.Arch.Quote":
                InsertRepSelection("Report Selection Usage"::"S.Arch.Quote", '1', REPORT::"Archived Sales Quote", true, false, true);
            "Report Selection Usage"::"S.Arch.Order":
                InsertRepSelection("Report Selection Usage"::"S.Arch.Order", '1', REPORT::"Archived Sales Order", true, false, true);
            "Report Selection Usage"::"P.Arch.Quote":
                InsertRepSelection("Report Selection Usage"::"P.Arch.Quote", '1', REPORT::"Archived Purchase Quote", true, false, true);
            "Report Selection Usage"::"P.Arch.Order":
                InsertRepSelection("Report Selection Usage"::"P.Arch.Order", '1', REPORT::"Archived Purchase Order", true, false, true);
            "Report Selection Usage"::"P.Arch.Return":
                InsertRepSelection("Report Selection Usage"::"P.Arch.Return", '1', REPORT::"Arch.Purch. Return Order", true, false, true);
            "Report Selection Usage"::"S.Arch.Return":
                InsertRepSelection("Report Selection Usage"::"S.Arch.Return", '1', REPORT::"Arch. Sales Return Order", true, false, true);
            "Report Selection Usage"::"S.Arch.Blanket":
                InsertRepSelection("Report Selection Usage"::"S.Arch.Blanket", '1', REPORT::"Archived Blanket Sales Order", true, false, true);
            "Report Selection Usage"::"P.Arch.Blanket":
                InsertRepSelection("Report Selection Usage"::"P.Arch.Blanket", '1', REPORT::"Archived Blanket Purch. Order", true, false, true);
            "Report Selection Usage"::"S.Order Pick Instruction":
                InsertRepSelection("Report Selection Usage"::"S.Order Pick Instruction", '1', REPORT::"Pick Instruction", true, false, true);
            "Report Selection Usage"::"C.Statement":
                InsertRepSelection("Report Selection Usage"::"C.Statement", '1', REPORT::"Standard Statement", true, false, true);
            "Report Selection Usage"::"Posted Payment Reconciliation":
                InsertRepSelection("Report Selection Usage"::"Posted Payment Reconciliation", '1', REPORT::"Posted Payment Reconciliation", true, false, true);
            "Report Selection Usage"::USI:
                begin
                    InsertRepSelection("Report Selection Usage"::USI, '1', REPORT::"Order Proforma-Invoice (A)", true, false, true);
                    InsertRepSelection("Report Selection Usage"::USI, '2', REPORT::"Order Factura-Invoice (A)", false, false, true);
                    InsertRepSelection("Report Selection Usage"::USI, '3', REPORT::"Order Item Shipment TORG-12", true, false, true);
                    InsertRepSelection("Report Selection Usage"::USI, '4', REPORT::"Order Item Waybill 1-T", false, false, true);
                    InsertRepSelection("Report Selection Usage"::USI, '5', REPORT::"Sales Shipment M-15", false, false, true);
                end;
            "Report Selection Usage"::USCM:
                InsertRepSelection("Report Selection Usage"::USCM, '1', REPORT::"Order Factura-Invoice (A)", false, false, true);
            "Report Selection Usage"::UCSD:
                InsertRepSelection("Report Selection Usage"::UCSD, '1', REPORT::"Sales Corr. Factura-Invoice", true, false, false);
            "Report Selection Usage"::CSI:
                InsertRepSelection("Report Selection Usage"::CSI, '1', REPORT::"Pstd. Sales Corr. Fact. Inv.", true, false, false);
            "Report Selection Usage"::CSCM:
                InsertRepSelection("Report Selection Usage"::CSCM, '1', REPORT::"Pstd. Sales Corr. Cr. M. Fact.", true, false, false);
            "Report Selection Usage"::UPI:
                begin
                    InsertRepSelection("Report Selection Usage"::UPI, '1', REPORT::"Purchase Receipt M-4", true, false, true);
                    InsertRepSelection("Report Selection Usage"::UPI, '2', REPORT::"Purch. FA Receipt FA-14", true, false, true);
                    InsertRepSelection("Report Selection Usage"::UPI, '3', REPORT::"Act Items Receipt M-7", true, false, true);
                    InsertRepSelection("Report Selection Usage"::UPI, '4', REPORT::"Items Receipt Act TORG-1", false, false, true);
                end;
            "Report Selection Usage"::UPCM:
                InsertRepSelection("Report Selection Usage"::UPCM, '1', REPORT::"Act Items Receipt M-7", true, false, true);
            "Report Selection Usage"::UAS:
                InsertRepSelection("Report Selection Usage"::UAS, '1', REPORT::"Advance Statement", true, false, false);
            "Report Selection Usage"::AS:
                InsertRepSelection("Report Selection Usage"::AS, '1', REPORT::"Posted Advance Statement", true, false, false);
            "Report Selection Usage"::"Inventory Shipment":
                InsertRepSelection("Report Selection Usage"::"Inventory Shipment", '1', REPORT::"Item Write-off act TORG-16", false, false, false);
            "Report Selection Usage"::"P.Inventory Shipment":
                InsertRepSelection("Report Selection Usage"::"P.Inventory Shipment", '1', REPORT::"Posted Item Write-off TORG-16", false, false, false);
            "Report Selection Usage"::"Inventory Receipt":
                begin
                    InsertRepSelection("Report Selection Usage"::"Inventory Receipt", '1', REPORT::"Act Items Receipt M-7", true, false, true);
                    InsertRepSelection("Report Selection Usage"::"Inventory Receipt", '2', REPORT::"Items Receipt Act TORG-1", false, false, true);
                    InsertRepSelection("Report Selection Usage"::"Inventory Receipt", '3', REPORT::"Receipt Deviations TORG-2", false, true, true);
                end;
            "Report Selection Usage"::"P.Inventory Receipt":
                begin
                    InsertRepSelection("Report Selection Usage"::"P.Inventory Receipt", '1', REPORT::"Act Items Receipt M-7", true, false, true);
                    InsertRepSelection("Report Selection Usage"::"P.Inventory Receipt", '2', REPORT::"Items Receipt Act TORG-1", false, false, true);
                    InsertRepSelection("Report Selection Usage"::"P.Inventory Receipt", '3', REPORT::"Receipt Deviations TORG-2", false, true, true);
                end;
            "Report Selection Usage"::PIJ:
                begin
                    InsertRepSelection("Report Selection Usage"::PIJ, '1', REPORT::"Phys. Inventory Form INV-3", false, false, false);
                    InsertRepSelection("Report Selection Usage"::PIJ, '2', REPORT::"Phys. Inventory Form INV-19", false, false, false);
                end;
            "Report Selection Usage"::IRJ:
                begin
                    InsertRepSelection("Report Selection Usage"::IRJ, '1', REPORT::"Item Reclass. TORG-13", true, false, false);
                    InsertRepSelection("Report Selection Usage"::IRJ, '2', REPORT::"Shipment Request M-11", false, false, true);
                end;
            "Report Selection Usage"::CB:
                InsertRepSelection("Report Selection Usage"::CB, '1', REPORT::"Cash Report CO-4", true, false, false);
            "Report Selection Usage"::UCI:
                InsertRepSelection("Report Selection Usage"::UCI, '1', REPORT::"Cash Ingoing Order", true, false, false);
            "Report Selection Usage"::UCO:
                InsertRepSelection("Report Selection Usage"::UCO, '1', REPORT::"Cash Outgoing Order", true, false, false);
            "Report Selection Usage"::CI:
                InsertRepSelection("Report Selection Usage"::CI, '1', REPORT::"Posted Cash Ingoing Order", true, false, false);
            "Report Selection Usage"::CO:
                InsertRepSelection("Report Selection Usage"::CO, '1', REPORT::"Posted Cash Outgoing Order", true, false, false);
            "Report Selection Usage"::UFAW:
                begin
                    InsertRepSelection("Report Selection Usage"::UFAW, '1', REPORT::"FA Write-off Act FA-4", true, false, false);
                    InsertRepSelection("Report Selection Usage"::UFAW, '2', REPORT::"FA Writeoff Act FA-4a", true, false, false);
                end;
            "Report Selection Usage"::FAW:
                begin
                    InsertRepSelection("Report Selection Usage"::FAW, '1', REPORT::"FA Posted Writeoff Act FA-4", true, false, false);
                    InsertRepSelection("Report Selection Usage"::FAW, '2', REPORT::"Posted FA Writeoff Act FA-4a", true, false, false);
                end;
            "Report Selection Usage"::UFAM:
                begin
                    InsertRepSelection("Report Selection Usage"::UFAM, '1', REPORT::"FA Movement FA-2", true, false, false);
                    InsertRepSelection("Report Selection Usage"::UFAM, '2', REPORT::"FA Movement FA-3", true, false, false);
                    InsertRepSelection("Report Selection Usage"::UFAM, '3', REPORT::"FA Movement FA-15", true, false, false);
                end;
            "Report Selection Usage"::FAM:
                begin
                    InsertRepSelection("Report Selection Usage"::FAM, '1', REPORT::"FA Posted Movement FA-2", true, false, false);
                    InsertRepSelection("Report Selection Usage"::FAM, '2', REPORT::"FA Posted Movement FA-3", true, false, false);
                    InsertRepSelection("Report Selection Usage"::FAM, '3', REPORT::"Posted FA Movement FA-15", true, false, false);
                end;
            "Report Selection Usage"::UFAR:
                InsertRepSelection("Report Selection Usage"::UFAR, '1', REPORT::"FA Release Act FA-1", true, false, false);
            "Report Selection Usage"::FAR:
                InsertRepSelection("Report Selection Usage"::FAR, '1', REPORT::"FA Posted Release Act FA-1", true, false, false);
            "Report Selection Usage"::FARJ:
                begin
                    InsertRepSelection("Report Selection Usage"::FARJ, '1', REPORT::"FA Phys. Inventory INV-1", true, false, false);
                    InsertRepSelection("Report Selection Usage"::FARJ, '2', REPORT::"FA Comparative Sheet INV-18", false, false, false);
                end;
            "Report Selection Usage"::FAJ:
                begin
                    InsertRepSelection("Report Selection Usage"::FAJ, '1', REPORT::"FA Phys. Inventory INV-1a", true, true, false);
                    InsertRepSelection("Report Selection Usage"::FAJ, '2', REPORT::"Inventory for Deferrals INV-11", false, true, false);
                    InsertRepSelection("Report Selection Usage"::FAJ, '3', REPORT::"FA Comparative Sheet INV-18", true, false, true);
                    InsertRepSelection("Report Selection Usage"::FAJ, '4', REPORT::"FA Phys. Inventory INV-1", false, false, true);
                end;
            "Report Selection Usage"::JQ:
                InsertRepSelection("Report Selection Usage"::JQ, '1', Report::"Job Quote", true, false, true);
            "Report Selection Usage"::"Job Task Quote":
                InsertRepSelection("Report Selection Usage"::"Job Task Quote", '1', Report::"Job Task Quote", true, false, true);
            else
                OnInitReportUsage(ReportUsage.AsInteger());
        end;
    end;

    procedure InitReportSelectionWhse(ReportUsage: Enum "Report Selection Warehouse Usage")
    begin
        case ReportUsage of
            "Report Selection Warehouse Usage"::Pick:
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::Pick, '1', REPORT::"Picking List");
            "Report Selection Warehouse Usage"::"Put-away":
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::"Put-away", '1', REPORT::"Put-away List");
            "Report Selection Warehouse Usage"::Movement:
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::Movement, '1', REPORT::"Movement List");
            "Report Selection Warehouse Usage"::"Invt. Pick":
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::"Invt. Pick", '1', REPORT::"Picking List");
            "Report Selection Warehouse Usage"::"Invt. Put-away":
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::"Invt. Put-away", '1', REPORT::"Put-away List");
            "Report Selection Warehouse Usage"::"Invt. Movement":
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::"Invt. Movement", '1', REPORT::"Movement List");
            "Report Selection Warehouse Usage"::Receipt:
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::Receipt, '1', REPORT::"Whse. - Receipt");
            "Report Selection Warehouse Usage"::"Posted Receipt":
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::"Posted Receipt", '1', REPORT::"Whse. - Posted Receipt");
            "Report Selection Warehouse Usage"::Shipment:
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::Shipment, '1', REPORT::"Whse. - Shipment");
            "Report Selection Warehouse Usage"::"Posted Shipment":
                InsertReportSelectionWhse("Report Selection Warehouse Usage"::"Posted Shipment", '1', REPORT::"Whse. - Posted Shipment");
            else
                OnInitReportUsageWhse(ReportUsage.AsInteger());
        end;
    end;

    local procedure InsertRepSelection(ReportUsage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer; Default: Boolean; ExcelExport: Boolean; UseForEmailAttachment: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(ReportUsage, Sequence) then begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportUsage;
            ReportSelections.Sequence := Sequence;
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Default := Default;
            ReportSelections."Excel Export" := ExcelExport;
            ReportSelections."Use for Email Attachment" := UseForEmailAttachment;
            ReportSelections.Insert();
        end;
    end;

    procedure ReportSelectionsExist(ReportSelectionUsage: Enum "Report Selection Usage"; ReportID: Integer): Boolean
    var
        ReportSelections: Record "Report Selections";
    begin
        if ReportSelections.Get(ReportSelectionUsage, '1') then
            exit(ReportSelections."Report ID" = ReportID);
        exit(false);
    end;

    procedure UpdateReportSelection(ReportUsage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        if ReportSelections.Get(ReportUsage, Sequence) then begin
            ReportSelections.Validate("Report ID", ReportID);
            ReportSelections.Modify();
        end;
    end;

    procedure InsertReportSelectionWhse(ReportUsage: Enum "Report Selection Warehouse Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertRepSelectionWhse(ReportUsage, Sequence, ReportID, IsHandled);
        if IsHandled then
            exit;
        if not ReportSelectionWhse.Get(ReportUsage, Sequence) then begin
            ReportSelectionWhse.Init();
            ReportSelectionWhse.Usage := ReportUsage;
            ReportSelectionWhse.Sequence := Sequence;
            ReportSelectionWhse."Report ID" := ReportID;
            ReportSelectionWhse.Insert();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionSales()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionPurch()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionInvt()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionBank()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionCust()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionServ()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionProd()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionWhse()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionJobs()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionSales()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionPurch()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionInvt()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionBank()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionCust()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionServ()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionProd()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionWhse()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionJobs()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitReportUsage(ReportUsage: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitReportUsageWhse(ReportUsage: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRepSelectionWhse(ReportUsage: Enum "Report Selection Warehouse Usage"; Sequence: Code[10]; ReportID: Integer; var IsHandled: Boolean)
    begin
    end;
}

