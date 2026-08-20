// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using System.Log;

/// <summary>
/// Codeunit Shpfy TMA Activity Log (ID 30477).
/// Writes "Activity Log" entries (Type = AI) for each Tax Matching Agent decision so a
/// human can review what the AI did, with confidence, explanation, and a drill-back link.
/// Anchors per-tax-line entries on the Shpfy Order Tax Line and per-tax-area entries on
/// the Shpfy Order Header.
/// </summary>
codeunit 30477 "Shpfy TMA Activity Log"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        PerLineExplanationLbl: Label 'Matched Shopify tax line "%1" (%2%) to Tax Jurisdiction %3.', Comment = '%1 = tax line title, %2 = rate percentage, %3 = jurisdiction code';
        PerLineExplanationWithReasonLbl: Label 'Matched Shopify tax line "%1" (%2%) to Tax Jurisdiction %3. %4', Comment = '%1 = tax line title, %2 = rate percentage, %3 = jurisdiction code, %4 = LLM reason';
        PerLineConflictLbl: Label 'Matched Shopify tax line "%1" (%2%) to Tax Jurisdiction %3, but its rate differs from Business Central. %4', Comment = '%1 = tax line title, %2 = rate percentage, %3 = jurisdiction code, %4 = conflict reason';
        TaxAreaCreatedLbl: Label 'Created new Tax Area %1 from agent-matched jurisdictions: %2.', Comment = '%1 = tax area code, %2 = comma-separated jurisdictions';
        TaxAreaReusedLbl: Label 'Reused existing Tax Area %1 covering agent-matched jurisdictions: %2.', Comment = '%1 = tax area code, %2 = comma-separated jurisdictions';
        TaxJurisdictionTitleLbl: Label 'Tax Jurisdiction %1', Comment = '%1 = jurisdiction code';
        TaxAreaTitleLbl: Label 'Tax Area %1', Comment = '%1 = tax area code';
        PerLineMatchedMsg: Label 'Tax Matching Agent matched a Shopify tax line to a Tax Jurisdiction.', Locked = true;
        TaxAreaResolvedMsg: Label 'Tax Matching Agent resolved a Tax Area for a Shopify order.', Locked = true;
        JurisdictionCodeDimTok: Label 'JurisdictionCode', Locked = true;
        TaxAreaCodeDimTok: Label 'TaxAreaCode', Locked = true;

    procedure LogPerLineEntries(var OrderHeader: Record "Shpfy Order Header"; MatchLog: JsonArray)
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        ActivityLogBuilder: Codeunit "Activity Log Builder";
        TMARegister: Codeunit "Shpfy TMA Register";
        JurisdictionRef: RecordRef;
        MatchToken: JsonToken;
        MatchObj: JsonObject;
        ParentId: BigInteger;
        LineNo: Integer;
        JurisdictionCode: Code[10];
        Confidence: Text;
        Reason: Text;
        Explanation: Text;
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

            if not OrderTaxLine.Get(ParentId, LineNo) then
                continue;
            if not TaxJurisdiction.Get(JurisdictionCode) then
                continue;

            JurisdictionRef.GetTable(TaxJurisdiction);

            if GetBooleanField(MatchObj, 'conflict', false) then
                Explanation := StrSubstNo(PerLineConflictLbl, OrderTaxLine.Title, OrderTaxLine."Rate %", JurisdictionCode, Reason)
            else
                Explanation := BuildPerLineExplanation(OrderTaxLine, JurisdictionCode, Reason);

            ActivityLogBuilder
                .Init(Database::"Shpfy Order Tax Line", OrderTaxLine.FieldNo("Tax Jurisdiction Code"), OrderTaxLine.SystemId)
                .SetType(Enum::"Activity Log Type"::"AI")
                .SetConfidence(Confidence)
                .SetExplanation(Explanation)
                .SetReferenceSource(Page::"Tax Jurisdictions", JurisdictionRef)
                .SetReferenceTitle(StrSubstNo(TaxJurisdictionTitleLbl, JurisdictionCode))
                .Log();

            Session.LogMessage('0000UN0', PerLineMatchedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName(), JurisdictionCodeDimTok, JurisdictionCode);
        end;
    end;

    procedure LogTaxAreaEntry(var OrderHeader: Record "Shpfy Order Header"; TaxAreaCode: Code[20]; WasCreated: Boolean; Jurisdictions: List of [Code[10]])
    var
        TaxArea: Record "Tax Area";
        ActivityLogBuilder: Codeunit "Activity Log Builder";
        TMARegister: Codeunit "Shpfy TMA Register";
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

        Session.LogMessage('0000UN1', TaxAreaResolvedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName(), TaxAreaCodeDimTok, TaxAreaCode);
    end;

    local procedure BuildPerLineExplanation(OrderTaxLine: Record "Shpfy Order Tax Line"; JurisdictionCode: Code[10]; Reason: Text): Text
    begin
        if Reason <> '' then
            exit(StrSubstNo(PerLineExplanationWithReasonLbl, OrderTaxLine.Title, OrderTaxLine."Rate %", JurisdictionCode, Reason));
        exit(StrSubstNo(PerLineExplanationLbl, OrderTaxLine.Title, OrderTaxLine."Rate %", JurisdictionCode));
    end;

    local procedure FormatJurisdictions(Jurisdictions: List of [Code[10]]): Text
    var
        JurisdictionCode: Code[10];
        ResultBuilder: TextBuilder;
    begin
        foreach JurisdictionCode in Jurisdictions do begin
            if ResultBuilder.Length() > 0 then
                ResultBuilder.Append(', ');
            ResultBuilder.Append(JurisdictionCode);
        end;
        exit(ResultBuilder.ToText());
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

    local procedure GetBooleanField(Obj: JsonObject; FieldName: Text; DefaultValue: Boolean): Boolean
    var
        Token: JsonToken;
    begin
        if not Obj.Get(FieldName, Token) then
            exit(DefaultValue);
        if not Token.IsValue() then
            exit(DefaultValue);
        exit(Token.AsValue().AsBoolean());
    end;
}
