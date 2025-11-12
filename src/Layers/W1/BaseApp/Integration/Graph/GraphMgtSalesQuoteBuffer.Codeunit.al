// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Entity;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Reflection;
using Microsoft.API.Upgrade;

codeunit 5506 "Graph Mgt - Sales Quote Buffer"
{

    trigger OnRun()
    begin
    end;

    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        DocumentIDNotSpecifiedForLinesErr: Label 'You must specify a document id to get the lines.';
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';
        CannotInsertALineThatAlreadyExistsErr: Label 'You cannot insert a line because a line already exists.';
        CannotModifyALineThatDoesntExistErr: Label 'You cannot modify a line that does not exist.';
        SkipUpdateDiscounts: Boolean;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromSalesHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesHeader(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        InsertOrModifyFromSalesHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        if not SalesQuoteEntityBuffer.Get(Rec."No.") then
            exit;

        SalesQuoteEntityBuffer.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales - Calc Discount By Type", 'OnAfterResetRecalculateInvoiceDisc', '', false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var SalesHeader: Record "Sales Header")
    begin
        if not CheckValidRecord(SalesHeader) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(SalesHeader.SystemId) then
            exit;

        InsertOrModifyFromSalesHeader(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        ModifyTotalsSalesLine(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        ModifyTotalsSalesLine(Rec, Rec."Recalculate Invoice Disc.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        if CheckUpdatesDisabled(Rec.SystemId) then
            exit;

        SalesLine.SetRange("Document No.", Rec."Document No.");
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Recalculate Invoice Disc.", true);

        if SalesLine.FindFirst() then begin
            ModifyTotalsSalesLine(SalesLine, true);
            exit;
        end;

        SalesLine.SetRange("Recalculate Invoice Disc.");

        if not SalesLine.FindFirst() then
            BlankTotals(Rec."Document No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Calc. Discount", 'OnAfterCalcSalesDiscount', '', false, false)]
    local procedure OnAfterCalculateSalesDiscountOnSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        if not CheckValidRecord(SalesHeader) or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if CheckUpdatesDisabled(SalesHeader.SystemId) then
            exit;

        InsertOrModifyFromSalesHeader(SalesHeader);
    end;

    procedure PropagateOnInsert(var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesHeader: Record "Sales Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        DocTypeFieldRef: FieldRef;
    begin
        if SalesQuoteEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        TargetRecordRef.Open(DATABASE::"Sales Header");

        DocTypeFieldRef := TargetRecordRef.Field(SalesHeader.FieldNo("Document Type"));
        DocTypeFieldRef.Value(SalesHeader."Document Type"::Quote);

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesQuoteEntityBuffer, TargetRecordRef);
        SetStatusOptionToSalesHeader(TempFieldBuffer, SalesQuoteEntityBuffer, TargetRecordRef);

        // SetTable does not transfer globals, which will affect the logic in OnInsert trigger. We have to insert here and modify latter.
        TargetRecordRef.Insert(true);

        SalesHeader.Get(TargetRecordRef.RecordId());
        SalesHeader.CopySellToAddressToBillToAddress();
        SalesHeader.SetDefaultPaymentServices();
        SalesHeader.Modify(true);

        SalesQuoteEntityBuffer."No." := SalesHeader."No.";
        SalesQuoteEntityBuffer.Get(SalesQuoteEntityBuffer."No.");
    end;

    procedure PropagateOnModify(var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesHeader: Record "Sales Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        Exists: Boolean;
    begin
        if SalesQuoteEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        Exists := SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuoteEntityBuffer."No.");
        if Exists then
            TargetRecordRef.GetTable(SalesHeader)
        else
            TargetRecordRef.Open(DATABASE::"Sales Header");

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesQuoteEntityBuffer, TargetRecordRef);
        SetStatusOptionToSalesHeader(TempFieldBuffer, SalesQuoteEntityBuffer, TargetRecordRef);

        TargetRecordRef.SetTable(SalesHeader);
        SalesHeader.CopySellToAddressToBillToAddress();

        if Exists then
            SalesHeader.Modify(true)
        else begin
            SalesHeader.SetDefaultPaymentServices();
            SalesHeader.Insert(true);
        end;
    end;

    procedure PropagateOnDelete(var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesQuoteEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if not SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuoteEntityBuffer."No.") then begin
            GraphMgtGeneralTools.CleanAggregateWithoutParent(SalesQuoteEntityBuffer);
            exit;
        end;

        SalesHeader.Delete(true);
    end;

    procedure UpdateBufferTableRecords()
    var
        SalesHeader: Record "Sales Header";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        if SalesHeader.FindSet() then
            repeat
                InsertOrModifyFromSalesHeader(SalesHeader);
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until SalesHeader.Next() = 0;

        if SalesQuoteEntityBuffer.FindSet(true) then
            repeat
                if not SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuoteEntityBuffer."No.") then begin
                    SalesQuoteEntityBuffer.Delete(true);
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
                end;
            until SalesQuoteEntityBuffer.Next() = 0;
    end;

    local procedure InsertOrModifyFromSalesHeader(var SalesHeader: Record "Sales Header")
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        RecordExists: Boolean;
    begin
        SalesQuoteEntityBuffer.LockTable();
        RecordExists := SalesQuoteEntityBuffer.Get(SalesHeader."No.");

        SalesQuoteEntityBuffer.TransferFields(SalesHeader, true);
        SalesQuoteEntityBuffer.Id := SalesHeader.SystemId;
        SetStatusOptionFromSalesHeader(SalesHeader, SalesQuoteEntityBuffer);
        AssignTotalsFromSalesHeader(SalesHeader, SalesQuoteEntityBuffer);
        SalesQuoteEntityBuffer.UpdateReferencedRecordIds();

        if RecordExists then
            SalesQuoteEntityBuffer.Modify(true)
        else
            SalesQuoteEntityBuffer.Insert(true);
    end;

    local procedure SetStatusOptionFromSalesHeader(var SalesHeader: Record "Sales Header"; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    begin
        if SalesHeader."Quote Accepted" then begin
            SalesQuoteEntityBuffer.Status := SalesQuoteEntityBuffer.Status::Accepted;
            exit;
        end;

        if SalesHeader."Quote Sent to Customer" <> 0DT then begin
            SalesQuoteEntityBuffer.Status := SalesQuoteEntityBuffer.Status::Sent;
            exit;
        end;

        SalesQuoteEntityBuffer.Status := SalesQuoteEntityBuffer.Status::Draft;
    end;

    local procedure SetStatusOptionToSalesHeader(var TempFieldBuffer: Record "Field Buffer" temporary; SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer"; var TargetTableRecRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        TargetFieldRef: FieldRef;
    begin
        TempFieldBuffer.Reset();
        TempFieldBuffer.SetRange("Field ID", SalesQuoteEntityBuffer.FieldNo(Status));
        if not TempFieldBuffer.FindFirst() then
            exit;

        case SalesQuoteEntityBuffer.Status of
            SalesQuoteEntityBuffer.Status::Accepted:
                begin
                    // "Quote Accepted" = True
                    TargetFieldRef := TargetTableRecRef.Field(SalesHeader.FieldNo("Quote Accepted"));
                    TargetFieldRef.Validate(true);
                end;
            SalesQuoteEntityBuffer.Status::Sent:
                begin
                    // "Quote Accepted" = False
                    TargetFieldRef := TargetTableRecRef.Field(SalesHeader.FieldNo("Quote Accepted"));
                    TargetFieldRef.Validate(false);
                    // "Quote Sent to Customer" = TODAY
                    TargetFieldRef := TargetTableRecRef.Field(SalesHeader.FieldNo("Quote Sent to Customer"));
                    TargetFieldRef.Validate(CurrentDateTime);
                end;
            SalesQuoteEntityBuffer.Status::Draft:
                begin
                    // "Quote Accepted" = False
                    TargetFieldRef := TargetTableRecRef.Field(SalesHeader.FieldNo("Quote Accepted"));
                    TargetFieldRef.Validate(false);
                    // "Quote Sent to Customer" = TODAY
                    TargetFieldRef := TargetTableRecRef.Field(SalesHeader.FieldNo("Quote Sent to Customer"));
                    TargetFieldRef.Validate(0DT);
                end;
        end;
    end;

    local procedure AssignTotalsFromSalesHeader(var SalesHeader: Record "Sales Header"; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");

        if not SalesLine.FindFirst() then begin
            BlankTotals(SalesLine."Document No.");
            exit;
        end;

        AssignTotalsFromSalesLine(SalesLine, SalesQuoteEntityBuffer, SalesHeader);
    end;

    local procedure AssignTotalsFromSalesLine(var SalesLine: Record "Sales Line"; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer"; var SalesHeader: Record "Sales Header")
    var
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Sales Tax" then begin
            SalesQuoteEntityBuffer."Discount Applied Before Tax" := true;
            SalesQuoteEntityBuffer."Prices Including VAT" := false;
        end else
            SalesQuoteEntityBuffer."Discount Applied Before Tax" := not SalesHeader."Prices Including VAT";

        DocumentTotals.CalculateSalesTotals(TotalSalesLine, VATAmount, SalesLine);

        SalesQuoteEntityBuffer."Invoice Discount Amount" := TotalSalesLine."Inv. Discount Amount";
        SalesQuoteEntityBuffer."Subtotal Amount" := TotalSalesLine."Line Amount";
        SalesQuoteEntityBuffer.Amount := TotalSalesLine.Amount;
        SalesQuoteEntityBuffer."Total Tax Amount" := VATAmount;
        SalesQuoteEntityBuffer."Amount Including VAT" := TotalSalesLine."Amount Including VAT";
    end;

    local procedure BlankTotals(DocumentNo: Code[20])
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
    begin
        if not SalesQuoteEntityBuffer.Get(DocumentNo) then
            exit;

        if CheckUpdatesDisabled(SalesQuoteEntityBuffer.Id) then
            exit;

        SalesQuoteEntityBuffer."Invoice Discount Amount" := 0;
        SalesQuoteEntityBuffer."Total Tax Amount" := 0;
        SalesQuoteEntityBuffer."Subtotal Amount" := 0;

        SalesQuoteEntityBuffer.Amount := 0;
        SalesQuoteEntityBuffer."Amount Including VAT" := 0;
        SalesQuoteEntityBuffer.Modify();
    end;

    local procedure CheckValidRecord(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.IsTemporary then
            exit(false);

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Quote then
            exit(false);

        exit(true);
    end;

    local procedure CheckValidLineRecord(var SalesLine: Record "Sales Line"): Boolean
    begin
        if SalesLine.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit(false);

        if SalesLine."Document Type" <> SalesLine."Document Type"::Quote then
            exit(false);

        exit(true);
    end;

    local procedure ModifyTotalsSalesLine(var SalesLine: Record "Sales Line"; RecalculateInvoiceDiscount: Boolean)
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesHeader: Record "Sales Header";
    begin
        if not SalesQuoteEntityBuffer.Get(SalesLine."Document No.") then
            exit;

        if not RecalculateInvoiceDiscount then
            exit;

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;

        if CheckUpdatesDisabled(SalesHeader.SystemId) then
            exit;

        AssignTotalsFromSalesLine(SalesLine, SalesQuoteEntityBuffer, SalesHeader);
        SalesQuoteEntityBuffer.Modify(true);
    end;

    local procedure TransferSalesInvoiceLineAggregateToSalesLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesLine: Record "Sales Line"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        TypeHelper: Codeunit "Type Helper";
        SalesLineRecordRef: RecordRef;
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Quote;
        SalesLineRecordRef.GetTable(SalesLine);

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesInvoiceLineAggregate, SalesLineRecordRef);

        SalesLineRecordRef.SetTable(SalesLine);
    end;

    procedure RedistributeInvoiceDiscounts(var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", SalesQuoteEntityBuffer."No.");
        SalesLine.SetRange("Recalculate Invoice Disc.", true);
        if SalesLine.FindFirst() then
            CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", SalesLine);

        SalesQuoteEntityBuffer.Get(SalesQuoteEntityBuffer."No.");
    end;

    procedure LoadLines(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; DocumentIdFilter: Text)
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedForLinesErr);

        SalesQuoteEntityBuffer.SetFilter(Id, DocumentIdFilter);
        if not SalesQuoteEntityBuffer.FindFirst() then
            exit;

        LoadSalesLines(SalesInvoiceLineAggregate, SalesQuoteEntityBuffer);
    end;

    local procedure LoadSalesLines(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", SalesQuoteEntityBuffer."No.");

        if SalesLine.FindSet(false) then
            repeat
                TransferFromSalesLine(SalesInvoiceLineAggregate, SalesQuoteEntityBuffer, SalesLine);
                SalesInvoiceLineAggregate.Insert(true);
            until SalesLine.Next() = 0;
    end;

    local procedure TransferFromSalesLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer"; var SalesLine: Record "Sales Line")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        Clear(SalesInvoiceLineAggregate);
        SalesInvoiceLineAggregate.TransferFields(SalesLine, true);
        SalesInvoiceLineAggregate.Id :=
          SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(SalesQuoteEntityBuffer.Id, SalesLine."Line No.");
        SalesInvoiceLineAggregate.SystemId := SalesLine.SystemId;
        SalesInvoiceLineAggregate."Document Id" := SalesQuoteEntityBuffer.Id;
        SalesInvoiceAggregator.SetTaxGroupIdAndCode(
          SalesInvoiceLineAggregate,
          SalesLine."Tax Group Code",
          SalesLine."VAT Prod. Posting Group",
          SalesLine."VAT Identifier");
        SalesInvoiceLineAggregate."VAT %" := SalesLine."VAT %";
        SalesInvoiceLineAggregate."Tax Amount" := SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount";
        SalesInvoiceLineAggregate.SetDiscountValue();
        SalesInvoiceLineAggregate.UpdateReferencedRecordIds();
        UpdateLineAmountsFromSalesLine(SalesInvoiceLineAggregate, SalesLine);
        SalesInvoiceAggregator.SetItemVariantId(SalesInvoiceLineAggregate, SalesLine."No.", SalesLine."Variant Code");
    end;

    procedure PropagateInsertLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesLine: Record "Sales Line";
        LastUsedSalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesQuoteEntityBuffer);

        SalesLine."Document Type" := SalesLine."Document Type"::Quote;
        SalesLine."Document No." := SalesQuoteEntityBuffer."No.";

        if SalesInvoiceLineAggregate."Line No." = 0 then begin
            LastUsedSalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
            LastUsedSalesLine.SetRange("Document No.", SalesQuoteEntityBuffer."No.");
            if LastUsedSalesLine.FindLast() then
                SalesInvoiceLineAggregate."Line No." := LastUsedSalesLine."Line No." + 10000
            else
                SalesInvoiceLineAggregate."Line No." := 10000;

            SalesLine."Line No." := SalesInvoiceLineAggregate."Line No.";
        end else
            if SalesLine.Get(SalesLine."Document Type"::Quote, SalesQuoteEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then
                Error(CannotInsertALineThatAlreadyExistsErr);

        TransferSalesInvoiceLineAggregateToSalesLine(SalesInvoiceLineAggregate, SalesLine, TempFieldBuffer);
        SalesLine.Insert(true);

        if not SkipUpdateDiscounts then
            RedistributeInvoiceDiscounts(SalesQuoteEntityBuffer);

        SalesLine.Find();
        TransferFromSalesLine(SalesInvoiceLineAggregate, SalesQuoteEntityBuffer, SalesLine);
    end;

    procedure PropagateModifyLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesQuoteEntityBuffer);

        if not SalesLine.Get(SalesLine."Document Type"::Quote, SalesQuoteEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then
            Error(CannotModifyALineThatDoesntExistErr);

        TransferSalesInvoiceLineAggregateToSalesLine(SalesInvoiceLineAggregate, SalesLine, TempFieldBuffer);

        SalesLine.Modify(true);

        if not SkipUpdateDiscounts then
            RedistributeInvoiceDiscounts(SalesQuoteEntityBuffer);

        SalesLine.Find();
        TransferFromSalesLine(SalesInvoiceLineAggregate, SalesQuoteEntityBuffer, SalesLine);
    end;

    procedure PropagateDeleteLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate")
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesQuoteEntityBuffer);

        if SalesLine.Get(SalesLine."Document Type"::Quote, SalesQuoteEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then begin
            SalesLine.Delete(true);
            if not SkipUpdateDiscounts then
                RedistributeInvoiceDiscounts(SalesQuoteEntityBuffer);
        end;
    end;

    procedure PropagateMultipleLinesUpdate(var TempNewSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary)
    var
        TempCurrentSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesLine: Record "Sales Line";
        TempAllFieldBuffer: Record "Field Buffer" temporary;
    begin
        VerifyCRUDIsPossibleForLine(TempNewSalesInvoiceLineAggregate, SalesQuoteEntityBuffer);
        GetFieldSetBufferWithAllFieldsSet(TempAllFieldBuffer);

        if not TempNewSalesInvoiceLineAggregate.FindFirst() then begin
            SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
            SalesLine.SetRange("Document No.", SalesQuoteEntityBuffer."No.");
            SalesLine.DeleteAll(true);
            exit;
        end;

        LoadLines(TempCurrentSalesInvoiceLineAggregate, SalesQuoteEntityBuffer.Id);

        SkipUpdateDiscounts := true;

        // Remove deleted lines
        if TempCurrentSalesInvoiceLineAggregate.FindSet(true) then
            repeat
                if not TempNewSalesInvoiceLineAggregate.Get(SalesQuoteEntityBuffer.Id, TempCurrentSalesInvoiceLineAggregate."Line No.") then
                    PropagateDeleteLine(TempCurrentSalesInvoiceLineAggregate);
            until TempCurrentSalesInvoiceLineAggregate.Next() = 0;

        // Update Lines
        TempNewSalesInvoiceLineAggregate.FindFirst();

        repeat
            if not TempCurrentSalesInvoiceLineAggregate.Get(
                 TempNewSalesInvoiceLineAggregate."Document Id", TempNewSalesInvoiceLineAggregate."Line No.")
            then
                PropagateInsertLine(TempNewSalesInvoiceLineAggregate, TempAllFieldBuffer)
            else
                PropagateModifyLine(TempNewSalesInvoiceLineAggregate, TempAllFieldBuffer);
        until TempNewSalesInvoiceLineAggregate.Next() = 0;

        SalesQuoteEntityBuffer.Get(SalesQuoteEntityBuffer."No.");
    end;

    procedure GetFieldSetBufferWithAllFieldsSet(var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        DummySalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line No."), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo(Type), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Item Id"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("No."), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo(Description), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Tax Id"), TempFieldBuffer);

        if GeneralLedgerSetup.UseVat() then
            RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("VAT Prod. Posting Group"), TempFieldBuffer)
        else
            RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Tax Group Code"), TempFieldBuffer);

        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo(Quantity), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Unit Price"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line Discount Calculation"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line Discount Value"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line Discount Amount"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line Discount %"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Shipment Date"), TempFieldBuffer);
    end;

    local procedure RegisterFieldSet(FieldNo: Integer; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast() then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Sales Invoice Line Aggregate";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure VerifyCRUDIsPossibleForLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        SearchSalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        DocumentIDFilter: Text;
    begin
        if IsNullGuid(SalesInvoiceLineAggregate."Document Id") then begin
            DocumentIDFilter := SalesInvoiceLineAggregate.GetFilter("Document Id");
            if DocumentIDFilter = '' then
                Error(DocumentIDNotSpecifiedForLinesErr);
            SalesQuoteEntityBuffer.SetFilter(Id, DocumentIDFilter);
            if not SalesQuoteEntityBuffer.FindFirst() then
                Error(DocumentDoesNotExistErr);
        end else begin
            SalesQuoteEntityBuffer.SetRange(Id, SalesInvoiceLineAggregate."Document Id");
            if not SalesQuoteEntityBuffer.FindFirst() then
                Error(DocumentDoesNotExistErr);
        end;

        SearchSalesQuoteEntityBuffer.Copy(SalesQuoteEntityBuffer);
        if SearchSalesQuoteEntityBuffer.Next() <> 0 then
            Error(MultipleDocumentsFoundForIdErr);
    end;

    local procedure UpdateLineAmountsFromSalesLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesLine: Record "Sales Line")
    begin
        SalesInvoiceLineAggregate."Line Amount Excluding Tax" := SalesLine.GetLineAmountExclVAT();
        SalesInvoiceLineAggregate."Line Amount Including Tax" := SalesLine.GetLineAmountInclVAT();
        SalesInvoiceLineAggregate."Line Tax Amount" :=
          SalesInvoiceLineAggregate."Line Amount Including Tax" - SalesInvoiceLineAggregate."Line Amount Excluding Tax";
        UpdateInvoiceDiscountAmount(SalesInvoiceLineAggregate);
    end;

    local procedure UpdateInvoiceDiscountAmount(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate")
    begin
        if SalesInvoiceLineAggregate."Prices Including Tax" then
            SalesInvoiceLineAggregate."Inv. Discount Amount Excl. VAT" :=
              SalesInvoiceLineAggregate."Line Amount Excluding Tax" - SalesInvoiceLineAggregate.Amount
        else
            SalesInvoiceLineAggregate."Inv. Discount Amount Excl. VAT" := SalesInvoiceLineAggregate."Inv. Discount Amount";
    end;

    local procedure CheckUpdatesDisabled(RecSystemId: Guid): Boolean
    var
        DisableAggregateTableUpgrade: Codeunit "Disable Aggregate Table Update";
        UpdatesDisabled: Boolean;
    begin
        DisableAggregateTableUpgrade.OnGetAggregateTablesUpdateEnabled(UpdatesDisabled, Database::"Sales Quote Entity Buffer", RecSystemId);

        if UpdatesDisabled then
            exit(true);

        exit(false);
    end;
}

