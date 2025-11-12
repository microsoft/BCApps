// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using System.Reflection;
using System.Upgrade;
using Microsoft.API.Upgrade;

codeunit 5497 "Graph Mgt - Purch Order Buffer"
{
    trigger OnRun()
    begin
    end;

    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.';
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';
        CannotInsertALineThatAlreadyExistsErr: Label 'You cannot insert a line because a line already exists.';
        CannotModifyALineThatDoesntExistErr: Label 'You cannot modify a line that does not exist.';

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromPurchaseHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseHeader(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if IsBackgroundPosting(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromPurchaseHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        if not PurchaseOrderEntityBuffer.Get(Rec."No.") then
            exit;
        PurchaseOrderEntityBuffer.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch - Calc Disc. By Type", 'OnAfterResetRecalculateInvoiceDisc', '', false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var PurchaseHeader: Record "Purchase Header")
    begin
        if not CheckValidRecord(PurchaseHeader) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(PurchaseHeader.SystemId) then
            exit;

        InsertOrModifyFromPurchaseHeader(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        UpdateCompletelyReceived(Rec);
        ModifyTotalsPurchaseLine(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseLine(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        UpdateCompletelyReceived(Rec);
        ModifyTotalsPurchaseLine(Rec, Rec."Recalculate Invoice Disc.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        UpdateCompletelyReceived(Rec);

        PurchaseLine.SetRange("Document No.", Rec."Document No.");
        PurchaseLine.SetRange("Document Type", Rec."Document Type");
        PurchaseLine.SetRange("Recalculate Invoice Disc.", true);

        if PurchaseLine.FindFirst() then begin
            ModifyTotalsPurchaseLine(PurchaseLine, true);
            exit;
        end;

        PurchaseLine.SetRange("Recalculate Invoice Disc.");

        if PurchaseLine.IsEmpty() then
            BlankTotals(Rec."Document No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Calc.Discount", 'OnAfterCalcPurchaseDiscount', '', false, false)]
    local procedure OnAfterCalculatePurchaseDiscountOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        if not CheckValidRecord(PurchaseHeader) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(PurchaseHeader.SystemId) then
            exit;

        InsertOrModifyFromPurchaseHeader(PurchaseHeader);
    end;

    procedure PropagateOnInsert(var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        DocTypeFieldRef: FieldRef;
    begin
        if PurchaseOrderEntityBuffer.IsTemporary() or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        TargetRecordRef.Open(DATABASE::"Purchase Header");

        DocTypeFieldRef := TargetRecordRef.Field(PurchaseHeader.FieldNo("Document Type"));
        DocTypeFieldRef.Value(PurchaseHeader."Document Type"::Order);

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, PurchaseOrderEntityBuffer, TargetRecordRef);

        // SetTable does not transfer globals, which will affect the logic in OnInsert trigger. We have to insert here and modify latter.
        TargetRecordRef.Insert(true);

        PurchaseHeader.Get(TargetRecordRef.RecordId());
        SetShipToAddress(PurchaseHeader, PurchaseOrderEntityBuffer);
        PurchaseHeader.CopyBuyFromAddressToPayToAddress();
        PurchaseHeader.Modify(true);

        PurchaseOrderEntityBuffer."No." := PurchaseHeader."No.";
        PurchaseOrderEntityBuffer.Get(PurchaseOrderEntityBuffer."No.");
    end;

    procedure PropagateOnModify(var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        Exists: Boolean;
    begin
        if PurchaseOrderEntityBuffer.IsTemporary() or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        Exists := PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderEntityBuffer."No.");
        if Exists then
            TargetRecordRef.GetTable(PurchaseHeader)
        else
            TargetRecordRef.Open(DATABASE::"Purchase Header");

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, PurchaseOrderEntityBuffer, TargetRecordRef);

        TargetRecordRef.SetTable(PurchaseHeader);
        PurchaseHeader.CopyBuyFromAddressToPayToAddress();

        if Exists then
            PurchaseHeader.Modify(true)
        else
            PurchaseHeader.Insert(true);
    end;

    procedure PropagateOnDelete(var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseOrderEntityBuffer.IsTemporary() or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderEntityBuffer."No.");
        PurchaseHeader.Delete(true);
    end;

    procedure UpdateBufferTableRecords()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        if PurchaseHeader.FindSet() then
            repeat
                InsertOrModifyFromPurchaseHeader(PurchaseHeader);
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until PurchaseHeader.Next() = 0;

        if PurchaseOrderEntityBuffer.FindSet(true) then
            repeat
                if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderEntityBuffer."No.") then begin
                    PurchaseOrderEntityBuffer.Delete(true);
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
                end;
            until PurchaseOrderEntityBuffer.Next() = 0;
    end;

    procedure InsertOrModifyFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        RecordExists: Boolean;
    begin
        PurchaseOrderEntityBuffer.LockTable();
        RecordExists := PurchaseOrderEntityBuffer.Get(PurchaseHeader."No.");

        PurchaseOrderEntityBuffer.TransferFields(PurchaseHeader, true);
        PurchaseOrderEntityBuffer.Id := PurchaseHeader.SystemId;
        SetStatusOptionFromPurchaseHeader(PurchaseHeader, PurchaseOrderEntityBuffer);
        AssignTotalsFromPurchaseHeader(PurchaseHeader, PurchaseOrderEntityBuffer);
        PurchaseOrderEntityBuffer.UpdateReferencedRecordIds();

        if RecordExists then
            PurchaseOrderEntityBuffer.Modify(true)
        else
            PurchaseOrderEntityBuffer.Insert(true);
    end;

    local procedure SetShipToAddress(var PurchaseHeader: Record "Purchase Header"; PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer")
    begin
        if PurchaseOrderEntityBuffer."Ship-to Name" <> '' then
            PurchaseHeader."Ship-to Name" := PurchaseOrderEntityBuffer."Ship-to Name";
        if PurchaseOrderEntityBuffer."Ship-to Address" <> '' then
            PurchaseHeader."Ship-to Address" := PurchaseOrderEntityBuffer."Ship-to Address";
        if PurchaseOrderEntityBuffer."Ship-to Address 2" <> '' then
            PurchaseHeader."Ship-to Address 2" := PurchaseOrderEntityBuffer."Ship-to Address 2";
        if PurchaseOrderEntityBuffer."Ship-to City" <> '' then
            PurchaseHeader."Ship-to City" := PurchaseOrderEntityBuffer."Ship-to City";
        if PurchaseOrderEntityBuffer."Ship-to Country/Region Code" <> '' then
            PurchaseHeader."Ship-to Country/Region Code" := PurchaseOrderEntityBuffer."Ship-to Country/Region Code";
        if PurchaseOrderEntityBuffer."Ship-to Post Code" <> '' then
            PurchaseHeader."Ship-to Post Code" := PurchaseOrderEntityBuffer."Ship-to Post Code";
        if PurchaseOrderEntityBuffer."Ship-to County" <> '' then
            PurchaseHeader."Ship-to County" := PurchaseOrderEntityBuffer."Ship-to County";
        if PurchaseOrderEntityBuffer."Ship-to Phone No." <> '' then
            PurchaseHeader."Ship-to Phone No." := PurchaseOrderEntityBuffer."Ship-to Phone No.";
    end;

    local procedure SetStatusOptionFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer")
    begin
        if PurchaseHeader.Status = PurchaseHeader.Status::"Pending Approval" then begin
            PurchaseOrderEntityBuffer.Status := PurchaseOrderEntityBuffer.Status::"In Review";
            exit;
        end;

        if (PurchaseHeader.Status = PurchaseHeader.Status::Released) or
           (PurchaseHeader.Status = PurchaseHeader.Status::"Pending Prepayment")
        then begin
            PurchaseOrderEntityBuffer.Status := PurchaseOrderEntityBuffer.Status::Open;
            exit;
        end;

        PurchaseOrderEntityBuffer.Status := PurchaseOrderEntityBuffer.Status::Draft;
    end;

    local procedure AssignTotalsFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");

        if not PurchaseLine.FindFirst() then begin
            BlankTotals(PurchaseLine."Document No.");
            exit;
        end;

        AssignTotalsFromPurchaseLine(PurchaseLine, PurchaseOrderEntityBuffer, PurchaseHeader);
    end;

    local procedure AssignTotalsFromPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer"; var PurchaseHeader: Record "Purchase Header")
    var
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if PurchaseLine."VAT Calculation Type" = PurchaseLine."VAT Calculation Type"::"Sales Tax" then begin
            PurchaseOrderEntityBuffer."Discount Applied Before Tax" := true;
            PurchaseOrderEntityBuffer."Prices Including VAT" := false;
        end else
            PurchaseOrderEntityBuffer."Discount Applied Before Tax" := not PurchaseHeader."Prices Including VAT";

        DocumentTotals.CalculatePurchaseTotals(TotalPurchaseLine, VATAmount, PurchaseLine);

        PurchaseOrderEntityBuffer."Invoice Discount Amount" := TotalPurchaseLine."Inv. Discount Amount";
        PurchaseOrderEntityBuffer.Amount := TotalPurchaseLine.Amount;
        PurchaseOrderEntityBuffer."Total Tax Amount" := VATAmount;
        PurchaseOrderEntityBuffer."Amount Including VAT" := TotalPurchaseLine."Amount Including VAT";
    end;

    local procedure BlankTotals(DocumentNo: Code[20])
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
    begin
        if not PurchaseOrderEntityBuffer.Get(DocumentNo) then
            exit;

        if CheckUpdatesDisabled(PurchaseOrderEntityBuffer.Id) then
            exit;

        PurchaseOrderEntityBuffer."Invoice Discount Amount" := 0;
        PurchaseOrderEntityBuffer."Total Tax Amount" := 0;

        PurchaseOrderEntityBuffer.Amount := 0;
        PurchaseOrderEntityBuffer."Amount Including VAT" := 0;
        PurchaseOrderEntityBuffer.Modify();
    end;

    local procedure CheckValidRecord(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.IsTemporary() then
            exit(false);

        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Order then
            exit(false);

        exit(true);
    end;

    local procedure CheckValidLineRecord(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if PurchaseLine.IsTemporary() or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit(false);

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then
            exit(false);

        exit(true);
    end;

    local procedure ModifyTotalsPurchaseLine(var PurchaseLine: Record "Purchase Line"; RecalculateInvoiceDiscount: Boolean)
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        PurchaseHeader: Record "Purchase Header";
    begin
        if not PurchaseOrderEntityBuffer.Get(PurchaseLine."Document No.") then
            exit;

        if not RecalculateInvoiceDiscount then
            exit;

        if not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
            exit;

        if CheckUpdatesDisabled(PurchaseHeader.SystemId) then
            exit;

        AssignTotalsFromPurchaseLine(PurchaseLine, PurchaseOrderEntityBuffer, PurchaseHeader);
        PurchaseOrderEntityBuffer.Modify(true);
    end;

    local procedure TransferPurchaseInvoiceLineAggregateToPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseLine: Record "Purchase Line"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        TypeHelper: Codeunit "Type Helper";
        PurchaseLineRecordRef: RecordRef;
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLineRecordRef.GetTable(PurchaseLine);

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, PurchInvLineAggregate, PurchaseLineRecordRef);

        PurchaseLineRecordRef.SetTable(PurchaseLine);
    end;

    procedure RedistributeInvoiceDiscounts(var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrderEntityBuffer."No.");
        PurchaseLine.SetRange("Recalculate Invoice Disc.", true);
        if PurchaseLine.FindFirst() then
            CODEUNIT.Run(CODEUNIT::"Purch - Calc Disc. By Type", PurchaseLine);

        PurchaseOrderEntityBuffer.Get(PurchaseOrderEntityBuffer."No.");
    end;

    procedure LoadLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; DocumentIdFilter: Text)
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedErr);

        PurchaseOrderEntityBuffer.SetFilter(Id, DocumentIdFilter);
        if not PurchaseOrderEntityBuffer.FindFirst() then
            exit;

        LoadPurchaseLines(PurchInvLineAggregate, PurchaseOrderEntityBuffer);
    end;

    local procedure LoadPurchaseLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrderEntityBuffer."No.");

        if PurchaseLine.FindSet(false) then
            repeat
                TransferFromPurchaseLine(PurchInvLineAggregate, PurchaseOrderEntityBuffer, PurchaseLine);
                PurchInvLineAggregate.Insert(true);
            until PurchaseLine.Next() = 0;
    end;

    local procedure TransferFromPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer"; var PurchaseLine: Record "Purchase Line")
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        Clear(PurchInvLineAggregate);
        PurchInvLineAggregate.TransferFields(PurchaseLine, true);
        PurchInvLineAggregate.Id :=
          SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(PurchaseOrderEntityBuffer.Id, PurchaseLine."Line No.");
        PurchInvLineAggregate.SystemId := PurchaseLine.SystemId;
        PurchInvLineAggregate."Document Id" := PurchaseOrderEntityBuffer.Id;
        PurchInvAggregator.SetTaxGroupIdAndCode(
            PurchInvLineAggregate,
            PurchaseLine."Tax Group Code",
            PurchaseLine."VAT Prod. Posting Group",
            PurchaseLine."VAT Identifier");
        PurchInvLineAggregate."VAT %" := PurchaseLine."VAT %";
        PurchInvLineAggregate."Tax Amount" := PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount";
        PurchInvLineAggregate.UpdateReferencedRecordIds();
        UpdateLineAmountsFromPurchaseLine(PurchInvLineAggregate, PurchaseLine);
        SetItemVariantId(PurchInvLineAggregate, PurchaseLine."No.", PurchaseLine."Variant Code");
    end;

    local procedure SetItemVariantId(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; ItemNo: Code[20]; VariantCode: Code[20])
    var
        ItemVariant: Record "Item Variant";
    begin
        if ItemVariant.Get(ItemNo, VariantCode) then
            PurchInvLineAggregate."Variant Id" := ItemVariant.SystemId;
    end;

    procedure PropagateInsertLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        PurchaseLine: Record "Purchase Line";
        LastUsedPurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchaseOrderEntityBuffer);

        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := PurchaseOrderEntityBuffer."No.";

        if PurchInvLineAggregate."Line No." = 0 then begin
            LastUsedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
            LastUsedPurchaseLine.SetRange("Document No.", PurchaseOrderEntityBuffer."No.");
            if LastUsedPurchaseLine.FindLast() then
                PurchInvLineAggregate."Line No." := LastUsedPurchaseLine."Line No." + 10000
            else
                PurchInvLineAggregate."Line No." := 10000;

            PurchaseLine."Line No." := PurchInvLineAggregate."Line No.";
        end else
            if PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseOrderEntityBuffer."No.", PurchInvLineAggregate."Line No.") then
                Error(CannotInsertALineThatAlreadyExistsErr);

        TransferPurchaseInvoiceLineAggregateToPurchaseLine(PurchInvLineAggregate, PurchaseLine, TempFieldBuffer);
        PurchaseLine.Insert(true);

        RedistributeInvoiceDiscounts(PurchaseOrderEntityBuffer);

        PurchaseLine.Find();
        TransferFromPurchaseLine(PurchInvLineAggregate, PurchaseOrderEntityBuffer, PurchaseLine);
    end;

    procedure PropagateModifyLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchaseOrderEntityBuffer);

        if not PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseOrderEntityBuffer."No.", PurchInvLineAggregate."Line No.") then
            Error(CannotModifyALineThatDoesntExistErr);

        TransferPurchaseInvoiceLineAggregateToPurchaseLine(PurchInvLineAggregate, PurchaseLine, TempFieldBuffer);

        PurchaseLine.Modify(true);

        RedistributeInvoiceDiscounts(PurchaseOrderEntityBuffer);

        PurchaseLine.Find();
        TransferFromPurchaseLine(PurchInvLineAggregate, PurchaseOrderEntityBuffer, PurchaseLine);
    end;

    procedure PropagateDeleteLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchaseOrderEntityBuffer);

        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseOrderEntityBuffer."No.", PurchInvLineAggregate."Line No.") then begin
            PurchaseLine.Delete(true);
            RedistributeInvoiceDiscounts(PurchaseOrderEntityBuffer);
        end;
    end;

    procedure DeleteOrphanedRecords()
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        PurchaseHeader: Record "Purchase Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if PurchaseOrderEntityBuffer.FindSet() then
            repeat
                if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderEntityBuffer."No.") then
                    PurchaseOrderEntityBuffer.Delete();
            until PurchaseOrderEntityBuffer.Next() = 0;

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDeletePurchaseOrdersOrphanedRecords()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDeletePurchaseOrdersOrphanedRecords());
    end;

    local procedure VerifyCRUDIsPossibleForLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer")
    var
        SearchPurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        DocumentIDFilter: Text;
    begin
        if IsNullGuid(PurchInvLineAggregate."Document Id") then begin
            DocumentIDFilter := PurchInvLineAggregate.GetFilter("Document Id");
            if DocumentIDFilter = '' then
                Error(DocumentIDNotSpecifiedErr);
            PurchaseOrderEntityBuffer.SetFilter(Id, DocumentIDFilter);
            if not PurchaseOrderEntityBuffer.FindFirst() then
                Error(DocumentDoesNotExistErr);
        end else begin
            PurchaseOrderEntityBuffer.SetRange(Id, PurchInvLineAggregate."Document Id");
            if not PurchaseOrderEntityBuffer.FindFirst() then
                Error(DocumentDoesNotExistErr);
        end;

        SearchPurchaseOrderEntityBuffer.Copy(PurchaseOrderEntityBuffer);
        if SearchPurchaseOrderEntityBuffer.Next() <> 0 then
            Error(MultipleDocumentsFoundForIdErr);
    end;

    local procedure UpdateCompletelyReceived(var PurchaseLine: Record "Purchase Line")
    var
        SearchPurchaseLine: Record "Purchase Line";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        CompletelyReceived: Boolean;
    begin
        SearchPurchaseLine.Copy(PurchaseLine);
        SearchPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        SearchPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        SearchPurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        SearchPurchaseLine.SetRange("Location Code", PurchaseLine."Location Code");
        SearchPurchaseLine.SetRange("Completely Received", false);

        CompletelyReceived := SearchPurchaseLine.IsEmpty();

        if not PurchaseOrderEntityBuffer.Get(PurchaseLine."Document No.") then
            exit;

        if CheckUpdatesDisabled(PurchaseOrderEntityBuffer.Id) then
            exit;

        if PurchaseOrderEntityBuffer."Completely Received" <> CompletelyReceived then begin
            PurchaseOrderEntityBuffer."Completely Received" := CompletelyReceived;
            PurchaseOrderEntityBuffer.Modify(true);
        end;
    end;

    local procedure UpdateLineAmountsFromPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchInvLineAggregate."Line Amount Excluding Tax" := PurchaseLine.GetLineAmountExclVAT();
        PurchInvLineAggregate."Line Amount Including Tax" := PurchaseLine.GetLineAmountInclVAT();
        PurchInvLineAggregate."Line Tax Amount" :=
          PurchInvLineAggregate."Line Amount Including Tax" - PurchInvLineAggregate."Line Amount Excluding Tax";
        UpdateInvoiceDiscountAmount(PurchInvLineAggregate);
    end;

    local procedure UpdateInvoiceDiscountAmount(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        if PurchInvLineAggregate."Prices Including Tax" then
            PurchInvLineAggregate."Inv. Discount Amount Excl. VAT" :=
              PurchInvLineAggregate."Line Amount Excluding Tax" - PurchInvLineAggregate.Amount
        else
            PurchInvLineAggregate."Inv. Discount Amount Excl. VAT" := PurchInvLineAggregate."Inv. Discount Amount";
    end;

    local procedure IsBackgroundPosting(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.IsTemporary() then
            exit(false);

        exit(PurchaseHeader."Job Queue Status" in [PurchaseHeader."Job Queue Status"::"Scheduled for Posting", PurchaseHeader."Job Queue Status"::Posting]);
    end;

    local procedure CheckUpdatesDisabled(RecSystemId: Guid): Boolean
    var
        DisableAggregateTableUpgrade: Codeunit "Disable Aggregate Table Update";
        UpdatesDisabled: Boolean;
    begin
        DisableAggregateTableUpgrade.OnGetAggregateTablesUpdateEnabled(UpdatesDisabled, Database::"Purchase Order Entity Buffer", RecSystemId);

        if UpdatesDisabled then
            exit(true);

        exit(false);
    end;
}