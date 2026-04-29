namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using System.Log;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy CT Activity Log (ID 30477).
/// Writes "Activity Log" entries (Type = AI) for each Copilot tax matching decision so a
/// human can review what the AI did, with confidence, explanation, and a drill-back link.
/// Anchors per-tax-line entries on the Shpfy Order Tax Line and per-tax-area entries on
/// the Shpfy Order Header.
/// </summary>
codeunit 30477 "Shpfy CT Activity Log"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure LogPerLineEntries(var OrderHeader: Record "Shpfy Order Header"; MatchLog: JsonArray)
    var
        TaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        ActivityLogBuilder: Codeunit "Activity Log Builder";
        ShpfyCopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        JurisdictionRef: RecordRef;
        MatchToken: JsonToken;
        MatchObj: JsonObject;
        ParentId: BigInteger;
        LineNo: Integer;
        JurisdictionCode: Code[10];
        Confidence: Text;
        Reason: Text;
    begin
        foreach MatchToken in MatchLog do begin
            MatchObj := MatchToken.AsObject();

            if not GetBigIntegerField(MatchObj, 'parentId', ParentId) then
                continue;
            if not GetIntegerField(MatchObj, 'lineNo', LineNo) then
                continue;

            JurisdictionCode := CopyStr(GetTextField(MatchObj, 'jurisdictionCode'), 1, MaxStrLen(JurisdictionCode));
            Confidence := GetTextField(MatchObj, 'confidence');
            Reason := GetTextField(MatchObj, 'reason');

            if not TaxLine.Get(ParentId, LineNo) then
                continue;
            if not TaxJurisdiction.Get(JurisdictionCode) then
                continue;

            JurisdictionRef.GetTable(TaxJurisdiction);

            ActivityLogBuilder
                .Init(Database::"Shpfy Order Tax Line", TaxLine.FieldNo("Tax Jurisdiction Code"), TaxLine.SystemId)
                .SetType(Enum::"Activity Log Type"::"AI")
                .SetConfidence(Confidence)
                .SetExplanation(BuildPerLineExplanation(TaxLine, JurisdictionCode, Reason))
                .SetReferenceSource(Page::"Tax Jurisdictions", JurisdictionRef)
                .SetReferenceTitle(StrSubstNo(TaxJurisdictionTitleLbl, JurisdictionCode))
                .Log();

            FeatureTelemetry.LogUptake('0000SHI', ShpfyCopilotTaxRegister.FeatureName(), Enum::"Feature Uptake Status"::Used);
        end;
    end;

    procedure LogTaxAreaEntry(var OrderHeader: Record "Shpfy Order Header"; TaxAreaCode: Code[20]; WasCreated: Boolean; Jurisdictions: List of [Code[10]])
    var
        TaxArea: Record "Tax Area";
        ActivityLogBuilder: Codeunit "Activity Log Builder";
        ShpfyCopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TaxAreaRef: RecordRef;
        Confidence: Text;
        Explanation: Text;
    begin
        if TaxAreaCode = '' then
            exit;
        if not TaxArea.Get(TaxAreaCode) then
            exit;

        TaxAreaRef.GetTable(TaxArea);

        if WasCreated then
            Confidence := 'Medium'
        else
            Confidence := 'High';

        if WasCreated then
            Explanation := StrSubstNo(TaxAreaCreatedLbl, TaxAreaCode, FormatJurisdictions(Jurisdictions))
        else
            Explanation := StrSubstNo(TaxAreaReusedLbl, TaxAreaCode, FormatJurisdictions(Jurisdictions));

        ActivityLogBuilder
            .Init(Database::"Shpfy Order Header", OrderHeader.FieldNo("Tax Area Code"), OrderHeader.SystemId)
            .SetType(Enum::"Activity Log Type"::"AI")
            .SetConfidence(Confidence)
            .SetExplanation(Explanation)
            .SetReferenceSource(Page::"Tax Area", TaxAreaRef)
            .SetReferenceTitle(StrSubstNo(TaxAreaTitleLbl, TaxAreaCode))
            .Log();

        FeatureTelemetry.LogUptake('0000SHJ', ShpfyCopilotTaxRegister.FeatureName(), Enum::"Feature Uptake Status"::Used);
    end;

    local procedure BuildPerLineExplanation(TaxLine: Record "Shpfy Order Tax Line"; JurisdictionCode: Code[10]; Reason: Text): Text
    begin
        if Reason <> '' then
            exit(StrSubstNo(PerLineExplanationWithReasonLbl, TaxLine.Title, TaxLine."Rate %", JurisdictionCode, Reason));
        exit(StrSubstNo(PerLineExplanationLbl, TaxLine.Title, TaxLine."Rate %", JurisdictionCode));
    end;

    local procedure FormatJurisdictions(Jurisdictions: List of [Code[10]]) Result: Text
    var
        JurisdictionCode: Code[10];
    begin
        foreach JurisdictionCode in Jurisdictions do begin
            if Result <> '' then
                Result += ', ';
            Result += JurisdictionCode;
        end;
    end;

    local procedure GetTextField(Obj: JsonObject; FieldName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Obj.Get(FieldName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetBigIntegerField(Obj: JsonObject; FieldName: Text; var Value: BigInteger): Boolean
    var
        Token: JsonToken;
    begin
        if not Obj.Get(FieldName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        Value := Token.AsValue().AsBigInteger();
        exit(true);
    end;

    local procedure GetIntegerField(Obj: JsonObject; FieldName: Text; var Value: Integer): Boolean
    var
        Token: JsonToken;
    begin
        if not Obj.Get(FieldName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        Value := Token.AsValue().AsInteger();
        exit(true);
    end;

    var
        PerLineExplanationLbl: Label 'Matched Shopify tax line "%1" (%2%) to Tax Jurisdiction %3.', Comment = '%1 = tax line title, %2 = rate percentage, %3 = jurisdiction code';
        PerLineExplanationWithReasonLbl: Label 'Matched Shopify tax line "%1" (%2%) to Tax Jurisdiction %3. %4', Comment = '%1 = tax line title, %2 = rate percentage, %3 = jurisdiction code, %4 = LLM reason';
        TaxAreaCreatedLbl: Label 'Created new Tax Area %1 from Copilot-matched jurisdictions: %2.', Comment = '%1 = tax area code, %2 = comma-separated jurisdictions';
        TaxAreaReusedLbl: Label 'Reused existing Tax Area %1 covering Copilot-matched jurisdictions: %2.', Comment = '%1 = tax area code, %2 = comma-separated jurisdictions';
        TaxJurisdictionTitleLbl: Label 'Tax Jurisdiction %1', Comment = '%1 = jurisdiction code';
        TaxAreaTitleLbl: Label 'Tax Area %1', Comment = '%1 = tax area code';
}
