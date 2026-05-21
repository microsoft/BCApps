// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

/// <summary>
/// Post-Mapping codeunit for PEPPOL BIS 3.0 Data Exchange import.
/// Registered as PostMappingCodeunit on the header DataExchMapping in the V2 definitions.
/// Handles compound fields and document-level charges that cannot be expressed as
/// declarative field mappings in the Data Exchange Definition.
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
        EDocument := EDocumentRecordId;

        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        BuildEndpointIdentifiers(Rec, EDocumentPurchaseHeader);
        EDocumentPurchaseHeader.Modify();

        MapChargeLinesToStaging(EDocument, Rec);
    end;

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

    local procedure MapChargeLinesToStaging(EDocument: Record "E-Document"; DataExch: Record "Data Exch.")
    var
        DataExchField: Record "Data Exch. Field";
        DataExchColumnDef: Record "Data Exch. Column Def";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        GLSetup: Record "General Ledger Setup";
        CurrLineNo: Integer;
        DescColNo: Integer;
        AmountColNo: Integer;
        VATRateColNo: Integer;
        CurrencyColNo: Integer;
        IndicatorColNo: Integer;
        IsCharge: Boolean;
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

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Line Def Code", ChargeLineDefCodeTok);
        DataExchField.SetCurrentKey("Line No.", "Column No.");
        if not DataExchField.FindSet() then
            exit;

        GLSetup.GetRecordOnce();
        CurrLineNo := -1;
        IsCharge := false;
        repeat
            if CurrLineNo <> DataExchField."Line No." then begin
                if (CurrLineNo <> -1) and IsCharge then begin
                    ApplyLCYBlankConvention(EDocumentPurchaseLine."Currency Code", GLSetup);
                    EDocumentPurchaseLine.Insert();
                end;
                Clear(EDocumentPurchaseLine);
                EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
                EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocument."Entry No");
                EDocumentPurchaseLine.Quantity := 1;
                CurrLineNo := DataExchField."Line No.";
                IsCharge := false;
            end;

            case DataExchField."Column No." of
                DescColNo:
                    EDocumentPurchaseLine.Description := CopyStr(DataExchField.Value, 1, MaxStrLen(EDocumentPurchaseLine.Description));
                AmountColNo:
                    begin
                        if Evaluate(EDocumentPurchaseLine."Unit Price", DataExchField.Value, 9) then;
                        if Evaluate(EDocumentPurchaseLine."Sub Total", DataExchField.Value, 9) then;
                    end;
                VATRateColNo:
                    if Evaluate(EDocumentPurchaseLine."VAT Rate", DataExchField.Value, 9) then;
                CurrencyColNo:
                    EDocumentPurchaseLine."Currency Code" := CopyStr(DataExchField.Value, 1, MaxStrLen(EDocumentPurchaseLine."Currency Code"));
                IndicatorColNo:
                    IsCharge := LowerCase(DataExchField.Value) = 'true';
            end;
        until DataExchField.Next() = 0;

        if (CurrLineNo <> -1) and IsCharge then begin
            ApplyLCYBlankConvention(EDocumentPurchaseLine."Currency Code", GLSetup);
            EDocumentPurchaseLine.Insert();
        end;
    end;

    local procedure ApplyLCYBlankConvention(var CurrencyCode: Code[10]; GLSetup: Record "General Ledger Setup")
    begin
        if GLSetup."LCY Code" = CurrencyCode then
            CurrencyCode := '';
    end;

    var
        ChargeLineDefCodeTok: Label 'PEPPOLCHARGELINES', Locked = true;
}
