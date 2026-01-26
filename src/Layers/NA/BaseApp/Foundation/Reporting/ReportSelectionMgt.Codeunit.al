// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Bank.Check;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reports;
using Microsoft.Inventory.Counting.Reports;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Transfer;
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

        OnAfterInitReportSelectionSales();
    end;

    procedure InitReportSelectionPurch()
    begin
        OnBeforeInitReportSelectionPurch();

        InitReportSelection("Report Selection Usage"::"P.Quote");
        InitReportSelection("Report Selection Usage"::"P.Blanket");
        InitReportSelection("Report Selection Usage"::"P.Order");
        InitReportSelection("Report Selection Usage"::"P.Invoice");
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

        OnAfterInitReportSelectionInvt();
    end;

    procedure InitReportSelectionBank()
    begin
        OnBeforeInitReportSelectionBank();

        InitReportSelection("Report Selection Usage"::"B.Stmt");
        InitReportSelection("Report Selection Usage"::"B.Recon.Test");
        InitReportSelection("Report Selection Usage"::"B.Check");
        InitReportSelection("Report Selection Usage"::"Posted Payment Reconciliation");

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
        InitReportSelection("Report Selection Usage"::"V.Remittance");

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
                InsertRepSelection("Report Selection Usage"::"Pro Forma S. Invoice", '1', REPORT::"Standard Sales - Pro Forma Inv");
            "Report Selection Usage"::"S.Invoice Draft":
                InsertRepSelection("Report Selection Usage"::"S.Invoice Draft", '1', REPORT::"Standard Sales - Draft Invoice");
            "Report Selection Usage"::"S.Quote":
                InsertRepSelection("Report Selection Usage"::"S.Quote", '1', REPORT::"Standard Sales - Quote");
            "Report Selection Usage"::"S.Blanket":
                InsertRepSelection("Report Selection Usage"::"S.Blanket", '1', REPORT::"Sales Blanket Order");
            "Report Selection Usage"::"S.Order":
                InsertRepSelection("Report Selection Usage"::"S.Order", '1', REPORT::"Standard Sales - Order Conf.");
            "Report Selection Usage"::"S.Work Order":
                InsertRepSelection("Report Selection Usage"::"S.Work Order", '1', REPORT::"Work Order");
            "Report Selection Usage"::"S.Invoice":
                InsertRepSelection("Report Selection Usage"::"S.Invoice", '1', REPORT::"Standard Sales - Invoice");
            "Report Selection Usage"::"S.Return":
                InsertRepSelection("Report Selection Usage"::"S.Return", '1', REPORT::"Return Authorization");
            "Report Selection Usage"::"S.Cr.Memo":
                InsertRepSelection("Report Selection Usage"::"S.Cr.Memo", '1', REPORT::"Standard Sales - Credit Memo");
            "Report Selection Usage"::"S.Shipment":
                InsertRepSelection("Report Selection Usage"::"S.Shipment", '1', REPORT::"Sales Shipment NA");
            "Report Selection Usage"::"S.Ret.Rcpt.":
                InsertRepSelection("Report Selection Usage"::"S.Ret.Rcpt.", '1', REPORT::"Return Receipt");
            "Report Selection Usage"::"S.Test":
                InsertRepSelection("Report Selection Usage"::"S.Test", '1', REPORT::"Sales Document - Test");
            "Report Selection Usage"::"P.Quote":
                InsertRepSelection("Report Selection Usage"::"P.Quote", '1', REPORT::"Purchase Quote NA");
            "Report Selection Usage"::"P.Blanket":
                InsertRepSelection("Report Selection Usage"::"P.Blanket", '1', REPORT::"Purchase Blanket Order");
            "Report Selection Usage"::"P.Order":
                InsertRepSelection("Report Selection Usage"::"P.Order", '1', REPORT::"Purchase Order");
            "Report Selection Usage"::"P.Invoice":
                InsertRepSelection("Report Selection Usage"::"P.Invoice", '1', REPORT::"Purchase Invoice NA");
            "Report Selection Usage"::"P.Return":
                InsertRepSelection("Report Selection Usage"::"P.Return", '1', REPORT::"Return Order");
            "Report Selection Usage"::"P.Cr.Memo":
                InsertRepSelection("Report Selection Usage"::"P.Cr.Memo", '1', REPORT::"Purchase Credit Memo NA");
            "Report Selection Usage"::"P.Receipt":
                InsertRepSelection("Report Selection Usage"::"P.Receipt", '1', REPORT::"Purchase Receipt NA");
            "Report Selection Usage"::"P.Ret.Shpt.":
                InsertRepSelection("Report Selection Usage"::"P.Ret.Shpt.", '1', REPORT::"Return Shipment");
            "Report Selection Usage"::"P.Test":
                InsertRepSelection("Report Selection Usage"::"P.Test", '1', REPORT::"Purchase Document - Test");
            "Report Selection Usage"::"B.Stmt":
                InsertRepSelection("Report Selection Usage"::"B.Stmt", '1', REPORT::"Bank Account Statement");
            "Report Selection Usage"::"B.Recon.Test":
                InsertRepSelection("Report Selection Usage"::"B.Recon.Test", '1', REPORT::"Bank Acc. Recon. - Test");
            "Report Selection Usage"::"B.Check":
                InsertRepSelection("Report Selection Usage"::"B.Check", '1', REPORT::Check);
            "Report Selection Usage"::Reminder:
                InsertRepSelection("Report Selection Usage"::Reminder, '1', REPORT::Reminder);
            "Report Selection Usage"::"Fin.Charge":
                InsertRepSelection("Report Selection Usage"::"Fin.Charge", '1', REPORT::"Finance Charge Memo");
            "Report Selection Usage"::"Rem.Test":
                InsertRepSelection("Report Selection Usage"::"Rem.Test", '1', REPORT::"Reminder - Test");
            "Report Selection Usage"::"F.C.Test":
                InsertRepSelection("Report Selection Usage"::"F.C.Test", '1', REPORT::"Finance Charge Memo - Test");
            "Report Selection Usage"::Inv1:
                InsertRepSelection("Report Selection Usage"::Inv1, '1', REPORT::"Transfer Order");
            "Report Selection Usage"::Inv2:
                InsertRepSelection("Report Selection Usage"::Inv2, '1', REPORT::"Transfer Shipment");
            "Report Selection Usage"::Inv3:
                InsertRepSelection("Report Selection Usage"::Inv3, '1', REPORT::"Transfer Receipt");
            "Report Selection Usage"::"Invt.Period Test":
                InsertRepSelection("Report Selection Usage"::"Invt.Period Test", '1', REPORT::"Close Inventory Period - Test");
            "Report Selection Usage"::"Phys.Invt.Order Test":
                InsertRepSelection("Report Selection Usage"::"Phys.Invt.Order Test", '1', REPORT::"Phys. Invt. Order - Test");
            "Report Selection Usage"::"Phys.Invt.Order":
                InsertRepSelection("Report Selection Usage"::"Phys.Invt.Order", '1', REPORT::"Phys. Invt. Order Diff. List");
            "Report Selection Usage"::"P.Phys.Invt.Order":
                InsertRepSelection("Report Selection Usage"::"P.Phys.Invt.Order", '1', REPORT::"Posted Phys. Invt. Order Diff.");
            "Report Selection Usage"::"Phys.Invt.Rec.":
                InsertRepSelection("Report Selection Usage"::"Phys.Invt.Rec.", '1', REPORT::"Phys. Invt. Recording");
            "Report Selection Usage"::"P.Phys.Invt.Rec.":
                InsertRepSelection("Report Selection Usage"::"P.Phys.Invt.Rec.", '1', REPORT::"Posted Phys. Invt. Recording");
            "Report Selection Usage"::"Asm.Order":
                InsertRepSelection("Report Selection Usage"::"Asm.Order", '1', REPORT::"Assembly Order");
            "Report Selection Usage"::"P.Asm.Order":
                InsertRepSelection("Report Selection Usage"::"P.Asm.Order", '1', REPORT::"Posted Assembly Order");
            "Report Selection Usage"::"S.Test Prepmt.":
                InsertRepSelection("Report Selection Usage"::"S.Test Prepmt.", '1', REPORT::"Sales Prepmt. Document Test");
            "Report Selection Usage"::"P.Test Prepmt.":
                InsertRepSelection("Report Selection Usage"::"P.Test Prepmt.", '1', REPORT::"Purchase Prepmt. Doc. - Test");
            "Report Selection Usage"::"S.Arch.Quote":
                InsertRepSelection("Report Selection Usage"::"S.Arch.Quote", '1', REPORT::"Archived Sales Quote");
            "Report Selection Usage"::"S.Arch.Order":
                InsertRepSelection("Report Selection Usage"::"S.Arch.Order", '1', REPORT::"Archived Sales Order");
            "Report Selection Usage"::"P.Arch.Quote":
                InsertRepSelection("Report Selection Usage"::"P.Arch.Quote", '1', REPORT::"Archived Purchase Quote");
            "Report Selection Usage"::"P.Arch.Order":
                InsertRepSelection("Report Selection Usage"::"P.Arch.Order", '1', REPORT::"Archived Purchase Order");
            "Report Selection Usage"::"P.Arch.Return":
                InsertRepSelection("Report Selection Usage"::"P.Arch.Return", '1', REPORT::"Arch.Purch. Return Order");
            "Report Selection Usage"::"S.Arch.Return":
                InsertRepSelection("Report Selection Usage"::"S.Arch.Return", '1', REPORT::"Arch. Sales Return Order");
            "Report Selection Usage"::"S.Arch.Blanket":
                InsertRepSelection("Report Selection Usage"::"S.Arch.Blanket", '1', REPORT::"Archived Blanket Sales Order");
            "Report Selection Usage"::"P.Arch.Blanket":
                InsertRepSelection("Report Selection Usage"::"P.Arch.Blanket", '1', REPORT::"Archived Blanket Purch. Order");
            "Report Selection Usage"::"S.Order Pick Instruction":
                InsertRepSelection("Report Selection Usage"::"S.Order Pick Instruction", '1', REPORT::"Pick Instruction");
            "Report Selection Usage"::"C.Statement":
                InsertRepSelection("Report Selection Usage"::"C.Statement", '1', REPORT::"Standard Statement");
            "Report Selection Usage"::"Posted Payment Reconciliation":
                InsertRepSelection("Report Selection Usage"::"Posted Payment Reconciliation", '1', REPORT::"Posted Payment Reconciliation");
            "Report Selection Usage"::"V.Remittance":
                InsertRepSelection("Report Selection Usage"::"V.Remittance", '1', REPORT::"Export Electronic Payments");
            "Report Selection Usage"::JQ:
                InsertRepSelection("Report Selection Usage"::JQ, '1', Report::"Job Quote");
            "Report Selection Usage"::"Job Task Quote":
                InsertRepSelection("Report Selection Usage"::"Job Task Quote", '1', Report::"Job Task Quote");
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

    local procedure InsertRepSelection(ReportUsage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(ReportUsage, Sequence) then begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportUsage;
            ReportSelections.Sequence := Sequence;
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;
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

