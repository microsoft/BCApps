// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.IO;

/// <summary>
/// Post-Mapping codeunit for PEPPOL BIS 3.0 Data Exchange import.
/// Registered as PostMappingCodeunit on the header DataExchMapping in the V2 definitions.
/// Runs inside ProcessDataExchange after the DataHandlingCodeunit (1214) has populated
/// Intermediate Data Import. Handles two things:
///
///   1. Compound header fields (schemeID:value endpoint identifier) that cannot be
///      expressed as a declarative field mapping.
///
///   2. Document-level AllowanceCharge elements (PEPPOLCHARGELINES line def): writes
///      them directly into Intermediate Data Import with Record Nos. above the existing
///      invoice/credit-note lines, so the generic MapIntermediateToLines bridge picks
///      them up in the correct order.
/// </summary>
codeunit 6408 "E-Doc. PEPPOL DX Post-Mapping"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentRecordId: RecordId;
    begin
        EDocumentRecordId := Rec."Related Record";
        EDocument := EDocumentRecordId.GetRecord();

        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        BuildEndpointIdentifiers(Rec, EDocumentPurchaseHeader);
        EDocumentPurchaseHeader.Modify();

        WriteChargeLinesToIntermediate(Rec);
    end;

    #region Endpoint Identifiers

    local procedure BuildEndpointIdentifiers(DataExch: Record "Data Exch."; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        DataExchField: Record "Data Exch. Field";
        DataExchColumnDef: Record "Data Exch. Column Def";
        EndpointValue: Text;
        EndpointScheme: Text;
        ValueColNo: Integer;
        SchemeColNo: Integer;
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange(Name, 'CustomerEndpointID');
        if DataExchColumnDef.FindFirst() then
            ValueColNo := DataExchColumnDef."Column No.";

        DataExchColumnDef.SetRange(Name, 'CustomerEndpointSchemeID');
        if DataExchColumnDef.FindFirst() then
            SchemeColNo := DataExchColumnDef."Column No.";

        if (ValueColNo = 0) or (SchemeColNo = 0) then
            exit;

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Column No.", ValueColNo);
        if DataExchField.FindFirst() then
            EndpointValue := DataExchField.Value;

        DataExchField.SetRange("Column No.", SchemeColNo);
        if DataExchField.FindFirst() then
            EndpointScheme := DataExchField.Value;

        if (EndpointValue <> '') and (EndpointScheme <> '') then
            EDocumentPurchaseHeader."Customer Company Id" :=
                CopyStr(EndpointScheme + ':' + EndpointValue, 1, MaxStrLen(EDocumentPurchaseHeader."Customer Company Id"));
    end;

    #endregion Endpoint Identifiers

    #region Charge Lines via Intermediate

    /// <summary>
    /// Reads PEPPOLCHARGELINES Data Exch. Field records and writes charge line data
    /// into Intermediate Data Import (Table ID 6101) with Record Nos. above the existing
    /// invoice/credit-note lines. The generic MapIntermediateToLines bridge then processes
    /// them in Record No. order, placing charge lines after invoice lines.
    /// </summary>
    local procedure WriteChargeLinesToIntermediate(DataExch: Record "Data Exch.")
    var
        DataExchField: Record "Data Exch. Field";
        DataExchColumnDef: Record "Data Exch. Column Def";
        IntermediateDataImport: Record "Intermediate Data Import";
        DescColNo: Integer;
        AmountColNo: Integer;
        VATRateColNo: Integer;
        CurrencyColNo: Integer;
        IndicatorColNo: Integer;
        ParentRecordNo: Integer;
        NextRecordNo: Integer;
        CurrLineNo: Integer;
        IsCharge: Boolean;
        Description: Text[100];
        Amount: Text[250];
        VATRate: Text[250];
        CurrencyCode: Text[250];
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", ChargeLineDefCodeTok);
        DataExchColumnDef.SetRange(Name, 'ChargeDescription');
        if DataExchColumnDef.FindFirst() then DescColNo := DataExchColumnDef."Column No.";
        DataExchColumnDef.SetRange(Name, 'ChargeAmount');
        if DataExchColumnDef.FindFirst() then AmountColNo := DataExchColumnDef."Column No.";
        DataExchColumnDef.SetRange(Name, 'ChargeVATRate');
        if DataExchColumnDef.FindFirst() then VATRateColNo := DataExchColumnDef."Column No.";
        DataExchColumnDef.SetRange(Name, 'ChargeCurrencyCode');
        if DataExchColumnDef.FindFirst() then CurrencyColNo := DataExchColumnDef."Column No.";
        DataExchColumnDef.SetRange(Name, 'ChargeIndicator');
        if DataExchColumnDef.FindFirst() then IndicatorColNo := DataExchColumnDef."Column No.";

        if DescColNo = 0 then
            exit;

        // Find the header's intermediate Record No. to use as Parent Record No. for lines.
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", Database::"E-Document Purchase Header");
        IntermediateDataImport.SetRange("Parent Record No.", 0);
        if not IntermediateDataImport.FindFirst() then
            exit;
        ParentRecordNo := IntermediateDataImport."Record No.";

        // Start charge lines after all existing purchase line intermediate records.
        IntermediateDataImport.SetRange("Table ID", Database::"E-Document Purchase Line");
        IntermediateDataImport.SetRange("Parent Record No.");
        if IntermediateDataImport.FindLast() then
            NextRecordNo := IntermediateDataImport."Record No." + 1
        else
            NextRecordNo := 1;

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Line Def Code", ChargeLineDefCodeTok);
        DataExchField.SetCurrentKey("Line No.", "Column No.");
        if not DataExchField.FindSet() then
            exit;

        CurrLineNo := -1;
        IsCharge := false;
        repeat
            if CurrLineNo <> DataExchField."Line No." then begin
                if (CurrLineNo <> -1) and IsCharge then
                    InsertChargeLineIntermediate(DataExch."Entry No.", NextRecordNo, ParentRecordNo,
                        Description, Amount, VATRate, CurrencyCode);
                CurrLineNo := DataExchField."Line No.";
                IsCharge := false;
                Clear(Description);
                Clear(Amount);
                Clear(VATRate);
                Clear(CurrencyCode);
            end;

            case DataExchField."Column No." of
                DescColNo:
                    Description := CopyStr(DataExchField.Value, 1, MaxStrLen(Description));
                AmountColNo:
                    Amount := DataExchField.Value;
                VATRateColNo:
                    VATRate := DataExchField.Value;
                CurrencyColNo:
                    CurrencyCode := DataExchField.Value;
                IndicatorColNo:
                    IsCharge := LowerCase(DataExchField.Value) = 'true';
            end;
        until DataExchField.Next() = 0;

        if (CurrLineNo <> -1) and IsCharge then
            InsertChargeLineIntermediate(DataExch."Entry No.", NextRecordNo, ParentRecordNo,
                Description, Amount, VATRate, CurrencyCode);
    end;

    local procedure InsertChargeLineIntermediate(DataExchNo: Integer; var NextRecordNo: Integer; ParentRecordNo: Integer; Description: Text[100]; Amount: Text[250]; VATRate: Text[250]; CurrencyCode: Text[250])
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        InsertIntermediateField(DataExchNo, NextRecordNo, ParentRecordNo,
            EDocumentPurchaseLine.FieldNo(Quantity), '1');
        if Description <> '' then
            InsertIntermediateField(DataExchNo, NextRecordNo, ParentRecordNo,
                EDocumentPurchaseLine.FieldNo(Description), Description);
        if Amount <> '' then begin
            InsertIntermediateField(DataExchNo, NextRecordNo, ParentRecordNo,
                EDocumentPurchaseLine.FieldNo("Unit Price"), Amount);
            InsertIntermediateField(DataExchNo, NextRecordNo, ParentRecordNo,
                EDocumentPurchaseLine.FieldNo("Sub Total"), Amount);
        end;
        if VATRate <> '' then
            InsertIntermediateField(DataExchNo, NextRecordNo, ParentRecordNo,
                EDocumentPurchaseLine.FieldNo("VAT Rate"), VATRate);
        if CurrencyCode <> '' then
            InsertIntermediateField(DataExchNo, NextRecordNo, ParentRecordNo,
                EDocumentPurchaseLine.FieldNo("Currency Code"), CurrencyCode);
        NextRecordNo += 1;
    end;

    local procedure InsertIntermediateField(DataExchNo: Integer; RecordNo: Integer; ParentRecordNo: Integer; FieldId: Integer; Value: Text)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.Init();
        IntermediateDataImport.Validate("Data Exch. No.", DataExchNo);
        IntermediateDataImport.Validate("Table ID", Database::"E-Document Purchase Line");
        IntermediateDataImport.Validate("Record No.", RecordNo);
        IntermediateDataImport.Validate("Field ID", FieldId);
        IntermediateDataImport.Validate("Parent Record No.", ParentRecordNo);
        IntermediateDataImport.SetValueWithoutModifying(Value);
        IntermediateDataImport.Insert(true);
    end;

    #endregion Charge Lines via Intermediate

    var
        ChargeLineDefCodeTok: Label 'PEPPOLCHARGELINES', Locked = true;
}
