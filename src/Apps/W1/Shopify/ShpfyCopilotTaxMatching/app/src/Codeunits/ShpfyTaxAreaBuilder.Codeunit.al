namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

/// <summary>
/// Codeunit Shpfy Tax Area Builder (ID 30472).
/// Finds or creates a Tax Area containing exactly the matched jurisdictions.
/// </summary>
codeunit 30472 "Shpfy Tax Area Builder"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure FindOrCreateTaxArea(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; JurisdictionCodes: List of [Code[10]]): Boolean
    var
        TaxAreaCode: Code[20];
    begin
        if JurisdictionCodes.Count() = 0 then
            exit(false);

        TaxAreaCode := FindExactTaxArea(JurisdictionCodes);

        if TaxAreaCode = '' then begin
            if not Shop."Auto Create Tax Areas" then
                exit(false);
            TaxAreaCode := CreateTaxArea(OrderHeader, Shop, JurisdictionCodes);
        end;

        if TaxAreaCode = '' then
            exit(false);

        OrderHeader."Tax Area Code" := TaxAreaCode;
        OrderHeader."Tax Liable" := true;
        OrderHeader.Modify();
        exit(true);
    end;

    local procedure FindExactTaxArea(JurisdictionCodes: List of [Code[10]]): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TargetCount: Integer;
        LineCount: Integer;
        AllMatch: Boolean;
        JurisdictionCode: Code[10];
    begin
        TargetCount := JurisdictionCodes.Count();

        if TaxArea.FindSet() then
            repeat
                TaxAreaLine.Reset();
                TaxAreaLine.SetRange("Tax Area", TaxArea.Code);
                LineCount := TaxAreaLine.Count();

                if LineCount = TargetCount then begin
                    AllMatch := true;
                    foreach JurisdictionCode in JurisdictionCodes do begin
                        TaxAreaLine.SetRange("Tax Jurisdiction Code", JurisdictionCode);
                        if TaxAreaLine.IsEmpty() then begin
                            AllMatch := false;
                            break;
                        end;
                        TaxAreaLine.SetRange("Tax Jurisdiction Code");
                    end;

                    if AllMatch then
                        exit(TaxArea.Code);
                end;
            until TaxArea.Next() = 0;

        exit('');
    end;

    local procedure CreateTaxArea(OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; JurisdictionCodes: List of [Code[10]]): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        JurisdictionCode: Code[10];
        TaxAreaCode: Code[20];
        DescriptionText: Text;
        CalcOrder: Integer;
    begin
        TaxAreaCode := GenerateTaxAreaCode(Shop."Tax Area Naming Pattern", GetLowestLevelJurisdiction(JurisdictionCodes));
        if TaxAreaCode = '' then
            exit('');

        // Build description from jurisdiction descriptions
        foreach JurisdictionCode in JurisdictionCodes do begin
            if DescriptionText <> '' then
                DescriptionText += '+';
            if TaxJurisdiction.Get(JurisdictionCode) then
                DescriptionText += TaxJurisdiction.Description
            else
                DescriptionText += JurisdictionCode;
        end;

        TaxArea.Init();
        TaxArea.Code := TaxAreaCode;
        TaxArea.Description := CopyStr('Shopify - ' + DescriptionText, 1, MaxStrLen(TaxArea.Description));
        Evaluate(TaxArea."Country/Region", OrderHeader."Ship-to Country/Region Code");
        TaxArea.Insert(true);

        CalcOrder := 0;
        foreach JurisdictionCode in JurisdictionCodes do begin
            CalcOrder += 1;
            TaxAreaLine.Init();
            TaxAreaLine."Tax Area" := TaxAreaCode;
            TaxAreaLine."Tax Jurisdiction Code" := JurisdictionCode;
            TaxAreaLine."Calculation Order" := CalcOrder;
            TaxAreaLine.Insert(true);
        end;

        exit(TaxAreaCode);
    end;

    local procedure GetLowestLevelJurisdiction(JurisdictionCodes: List of [Code[10]]): Code[10]
    begin
        // Last jurisdiction = highest calculation order = most specific (e.g. city-level)
        exit(JurisdictionCodes.Get(JurisdictionCodes.Count()));
    end;

    local procedure GenerateTaxAreaCode(NamingPattern: Text[20]; LowestJurisdictionCode: Code[10]): Code[20]
    var
        TaxArea: Record "Tax Area";
        CandidateCode: Code[20];
        Suffix: Integer;
    begin
        // Try without suffix first, e.g. "SHPFY-NYCTAX"
        CandidateCode := CopyStr(NamingPattern + LowestJurisdictionCode, 1, MaxStrLen(CandidateCode));
        if not TaxArea.Get(CandidateCode) then
            exit(CandidateCode);

        // If taken, add suffix: "SHPFY-NYCTAX-2", "SHPFY-NYCTAX-3", ...
        Suffix := 2;
        repeat
            CandidateCode := CopyStr(NamingPattern + LowestJurisdictionCode + '-' + Format(Suffix), 1, MaxStrLen(CandidateCode));
            if not TaxArea.Get(CandidateCode) then
                exit(CandidateCode);
            Suffix += 1;
        until Suffix > 999;

        exit('');
    end;
}
