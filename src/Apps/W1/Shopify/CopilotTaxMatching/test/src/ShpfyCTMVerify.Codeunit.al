namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using System.TestLibraries.Utilities;
using System.TestTools.TestRunner;

codeunit 30492 "Shpfy CTM Verify"
{
    Access = Internal;

    internal procedure VerifyFromExpected(Expected: Codeunit "Test Input Json"; OrderHeader: Record "Shpfy Order Header")
    var
        ElementExists: Boolean;
    begin
        Expected.ElementExists('taxLineJurisdictions', ElementExists);
        if ElementExists then
            VerifyTaxLineJurisdictions(Expected.Element('taxLineJurisdictions'));

        Expected.ElementExists('allTaxLinesMatched', ElementExists);
        if ElementExists then
            if Expected.Element('allTaxLinesMatched').ValueAsBoolean() then
                VerifyAllTaxLinesMatched(OrderHeader);

        Expected.ElementExists('createdJurisdictionCountryRegion', ElementExists);
        if ElementExists then
            VerifyCreatedJurisdictionCountryRegion(OrderHeader, Expected.Element('createdJurisdictionCountryRegion').ValueAsText());

        Expected.ElementExists('reportToAllSame', ElementExists);
        if ElementExists then
            if Expected.Element('reportToAllSame').ValueAsBoolean() then
                VerifyReportToAllSame(OrderHeader);

        Expected.ElementExists('taxDetailExists', ElementExists);
        if ElementExists then
            VerifyTaxDetailExists(Expected.Element('taxDetailExists'), OrderHeader);

        Expected.ElementExists('taxDetailCount', ElementExists);
        if ElementExists then
            VerifyTaxDetailCount(Expected.Element('taxDetailCount'));

        Expected.ElementExists('taxAreaCode', ElementExists);
        if ElementExists then begin
            OrderHeader.Find();
            VerifyTaxAreaOnOrder(OrderHeader, Expected);
        end;

        Expected.ElementExists('taxAreaAssigned', ElementExists);
        if ElementExists then begin
            OrderHeader.Find();
            if Expected.Element('taxAreaAssigned').ValueAsBoolean() then
                LibraryAssert.AreNotEqual('', OrderHeader."Tax Area Code", 'Tax Area Code should be assigned')
            else
                LibraryAssert.AreEqual('', OrderHeader."Tax Area Code", 'Tax Area Code should be blank');
        end;

        Expected.ElementExists('taxLiable', ElementExists);
        if ElementExists then begin
            OrderHeader.Find();
            LibraryAssert.AreEqual(Expected.Element('taxLiable').ValueAsBoolean(), OrderHeader."Tax Liable", 'Order Tax Liable');
        end;

        Expected.ElementExists('existingTaxAreaKept', ElementExists);
        if ElementExists then begin
            OrderHeader.Find();
            LibraryAssert.AreEqual(
                CopyStr(Expected.Element('existingTaxAreaKept').ValueAsText(), 1, 20),
                OrderHeader."Tax Area Code",
                'Existing Tax Area Code should be preserved');
        end;

        Expected.ElementExists('orderUnchanged', ElementExists);
        if ElementExists then
            if Expected.Element('orderUnchanged').ValueAsBoolean() then
                VerifyOrderUnchanged(OrderHeader);

        Expected.ElementExists('createdJurisdictionDescriptionEqualsCode', ElementExists);
        if ElementExists then
            if Expected.Element('createdJurisdictionDescriptionEqualsCode').ValueAsBoolean() then
                VerifyCreatedJurisdictionDescriptionEqualsCode(OrderHeader);
    end;

    local procedure VerifyTaxLineJurisdictions(ExpectedArray: Codeunit "Test Input Json")
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ExpectedItem: Codeunit "Test Input Json";
        ParentId: BigInteger;
        LineNo: Integer;
        ElementExists: Boolean;
        i: Integer;
    begin
        for i := 0 to ExpectedArray.GetElementCount() - 1 do begin
            ExpectedItem := ExpectedArray.ElementAt(i);
            Evaluate(ParentId, ExpectedItem.Element('parentId').ValueAsText());
            Evaluate(LineNo, ExpectedItem.Element('lineNo').ValueAsText());

            LibraryAssert.IsTrue(OrderTaxLine.Get(ParentId, LineNo),
                StrSubstNo(TaxLineShouldExistLbl, ParentId, LineNo));

            ExpectedItem.ElementExists('jurisdictionCode', ElementExists);
            if ElementExists then
                LibraryAssert.AreEqual(
                    CopyStr(ExpectedItem.Element('jurisdictionCode').ValueAsText(), 1, 10),
                    OrderTaxLine."Tax Jurisdiction Code",
                    StrSubstNo(TaxLineJurisdictionCodeLbl, ParentId, LineNo));

            ExpectedItem.ElementExists('hasJurisdictionCode', ElementExists);
            if ElementExists then
                if ExpectedItem.Element('hasJurisdictionCode').ValueAsBoolean() then
                    LibraryAssert.AreNotEqual('', OrderTaxLine."Tax Jurisdiction Code",
                        StrSubstNo(TaxLineShouldHaveCodeLbl, ParentId, LineNo));
        end;
    end;

    local procedure VerifyAllTaxLinesMatched(OrderHeader: Record "Shpfy Order Header")
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
    begin
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                OrderTaxLine.SetRange("Parent Id", OrderLine."Line Id");
                if OrderTaxLine.FindSet() then
                    repeat
                        LibraryAssert.AreNotEqual('', OrderTaxLine."Tax Jurisdiction Code",
                            StrSubstNo(TaxLineShouldBeMatchedLbl, OrderTaxLine."Parent Id", OrderTaxLine."Line No."));
                    until OrderTaxLine.Next() = 0;
            until OrderLine.Next() = 0;
    end;

    local procedure VerifyCreatedJurisdictionCountryRegion(OrderHeader: Record "Shpfy Order Header"; ExpectedCountryRegion: Text)
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                OrderTaxLine.SetRange("Parent Id", OrderLine."Line Id");
                if OrderTaxLine.FindSet() then
                    repeat
                        if OrderTaxLine."Tax Jurisdiction Code" <> '' then
                            if TaxJurisdiction.Get(OrderTaxLine."Tax Jurisdiction Code") then
                                LibraryAssert.AreEqual(
                                    ExpectedCountryRegion,
                                    Format(TaxJurisdiction."Country/Region"),
                                    StrSubstNo(JurisdictionCountryRegionLbl, TaxJurisdiction.Code));
                    until OrderTaxLine.Next() = 0;
            until OrderLine.Next() = 0;
    end;

    local procedure VerifyReportToAllSame(OrderHeader: Record "Shpfy Order Header")
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        FirstReportTo: Code[10];
        FoundFirst: Boolean;
    begin
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                OrderTaxLine.SetRange("Parent Id", OrderLine."Line Id");
                if OrderTaxLine.FindSet() then
                    repeat
                        if OrderTaxLine."Tax Jurisdiction Code" <> '' then
                            if TaxJurisdiction.Get(OrderTaxLine."Tax Jurisdiction Code") then
                                if not FoundFirst then begin
                                    FirstReportTo := TaxJurisdiction."Report-to Jurisdiction";
                                    FoundFirst := true;
                                end else
                                    LibraryAssert.AreEqual(FirstReportTo, TaxJurisdiction."Report-to Jurisdiction",
                                        StrSubstNo(JurisdictionReportToLbl, TaxJurisdiction.Code));
                    until OrderTaxLine.Next() = 0;
            until OrderLine.Next() = 0;

        LibraryAssert.IsTrue(FoundFirst, 'At least one jurisdiction should have Report-to set');
    end;

    local procedure VerifyTaxDetailExists(ExpectedArray: Codeunit "Test Input Json"; OrderHeader: Record "Shpfy Order Header")
    var
        TaxDetail: Record "Tax Detail";
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ExpectedItem: Codeunit "Test Input Json";
        TaxGroupCode: Code[20];
        RatePct: Decimal;
        ExpectedEffectiveDate: Date;
        EffectiveDateExists: Boolean;
        i: Integer;
    begin
        for i := 0 to ExpectedArray.GetElementCount() - 1 do begin
            ExpectedItem := ExpectedArray.ElementAt(i);
            TaxGroupCode := CopyStr(ExpectedItem.Element('taxGroupCode').ValueAsText(), 1, MaxStrLen(TaxGroupCode));
            RatePct := ExpectedItem.Element('ratePct').ValueAsDecimal();

            ExpectedItem.ElementExists('effectiveDate', EffectiveDateExists);
            if EffectiveDateExists then
                Evaluate(ExpectedEffectiveDate, ExpectedItem.Element('effectiveDate').ValueAsText());

            // Find matched tax lines to get the jurisdiction code
            OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
            if OrderLine.FindSet() then
                repeat
                    OrderTaxLine.SetRange("Parent Id", OrderLine."Line Id");
                    OrderTaxLine.SetRange("Rate %", RatePct);
                    OrderTaxLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
                    if OrderTaxLine.FindFirst() then begin
                        TaxDetail.SetRange("Tax Jurisdiction Code", OrderTaxLine."Tax Jurisdiction Code");
                        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
                        TaxDetail.SetRange("Tax Below Maximum", RatePct);
                        LibraryAssert.IsTrue(TaxDetail.FindFirst(),
                            StrSubstNo(TaxDetailShouldExistLbl,
                                OrderTaxLine."Tax Jurisdiction Code", TaxGroupCode, RatePct));

                        if EffectiveDateExists then
                            LibraryAssert.AreEqual(ExpectedEffectiveDate, TaxDetail."Effective Date",
                                StrSubstNo(TaxDetailEffectiveDateLbl, OrderTaxLine."Tax Jurisdiction Code", TaxGroupCode));
                    end;
                until OrderLine.Next() = 0;
        end;
    end;

    local procedure VerifyCreatedJurisdictionDescriptionEqualsCode(OrderHeader: Record "Shpfy Order Header")
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        Checked: Boolean;
    begin
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                OrderTaxLine.SetRange("Parent Id", OrderLine."Line Id");
                OrderTaxLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
                if OrderTaxLine.FindSet() then
                    repeat
                        if TaxJurisdiction.Get(OrderTaxLine."Tax Jurisdiction Code") then begin
                            LibraryAssert.AreEqual(
                                Format(TaxJurisdiction.Code),
                                TaxJurisdiction.Description,
                                StrSubstNo(JurisdictionDescriptionEqualsCodeLbl, TaxJurisdiction.Code));
                            Checked := true;
                        end;
                    until OrderTaxLine.Next() = 0;
            until OrderLine.Next() = 0;

        LibraryAssert.IsTrue(Checked, 'At least one created jurisdiction should have been checked.');
    end;

    internal procedure VerifyTaxDetailCount(CountInput: Codeunit "Test Input Json")
    var
        TaxDetail: Record "Tax Detail";
        JurisdictionCode: Code[10];
        TaxGroupCode: Code[20];
        ExpectedCount: Integer;
    begin
        JurisdictionCode := CopyStr(CountInput.Element('jurisdictionCode').ValueAsText(), 1, MaxStrLen(JurisdictionCode));
        TaxGroupCode := CopyStr(CountInput.Element('taxGroupCode').ValueAsText(), 1, MaxStrLen(TaxGroupCode));
        Evaluate(ExpectedCount, CountInput.Element('count').ValueAsText());

        TaxDetail.SetRange("Tax Jurisdiction Code", JurisdictionCode);
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        LibraryAssert.AreEqual(ExpectedCount, TaxDetail.Count(),
            StrSubstNo(TaxDetailCountLbl, JurisdictionCode, TaxGroupCode));
    end;

    local procedure VerifyTaxAreaOnOrder(OrderHeader: Record "Shpfy Order Header"; Expected: Codeunit "Test Input Json")
    var
        ExpectedTaxAreaCode: Code[20];
    begin
        ExpectedTaxAreaCode := CopyStr(Expected.Element('taxAreaCode').ValueAsText(), 1, MaxStrLen(ExpectedTaxAreaCode));
        LibraryAssert.AreEqual(ExpectedTaxAreaCode, OrderHeader."Tax Area Code", 'Order Tax Area Code');
    end;

    internal procedure VerifyTaxAreaCreated(Expected: Codeunit "Test Input Json")
    var
        TaxArea: Record "Tax Area";
        TaxAreaCode: Code[20];
        ElementExists: Boolean;
    begin
        TaxAreaCode := CopyStr(Expected.Element('taxAreaCode').ValueAsText(), 1, MaxStrLen(TaxAreaCode));
        if TaxAreaCode = '' then
            exit;

        Expected.ElementExists('taxAreaCreated', ElementExists);
        if ElementExists and Expected.Element('taxAreaCreated').ValueAsBoolean() then begin
            LibraryAssert.IsTrue(TaxArea.Get(TaxAreaCode),
                StrSubstNo(TaxAreaShouldExistLbl, TaxAreaCode));

            Expected.ElementExists('taxAreaDescription', ElementExists);
            if ElementExists then
                LibraryAssert.AreEqual(
                    Expected.Element('taxAreaDescription').ValueAsText(),
                    TaxArea.Description,
                    'Tax Area Description');

            Expected.ElementExists('taxAreaCountryRegion', ElementExists);
            if ElementExists then
                LibraryAssert.AreEqual(
                    Expected.Element('taxAreaCountryRegion').ValueAsText(),
                    Format(TaxArea."Country/Region"),
                    'Tax Area Country/Region');
        end;
    end;

    internal procedure VerifyOrderUnchanged(OrderHeader: Record "Shpfy Order Header")
    begin
#pragma warning disable AA0181
        OrderHeader.Find();
#pragma warning restore AA0181
        LibraryAssert.AreEqual('', OrderHeader."Tax Area Code", 'Tax Area Code should be blank');
        LibraryAssert.IsFalse(OrderHeader."Tax Liable", 'Tax Liable should be false');
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        TaxLineShouldExistLbl: Label 'Tax line %1-%2 should exist', Locked = true;
        TaxLineJurisdictionCodeLbl: Label 'Tax line %1-%2 jurisdiction code', Locked = true;
        TaxLineShouldHaveCodeLbl: Label 'Tax line %1-%2 should have a jurisdiction code', Locked = true;
        TaxLineShouldBeMatchedLbl: Label 'Tax line %1-%2 should be matched', Locked = true;
        JurisdictionCountryRegionLbl: Label 'Jurisdiction %1 Country/Region', Locked = true;
        JurisdictionReportToLbl: Label 'Jurisdiction %1 Report-to should match first', Locked = true;
        TaxDetailShouldExistLbl: Label 'Tax Detail should exist for %1 / %2 / %3', Locked = true;
        TaxDetailEffectiveDateLbl: Label 'Tax Detail Effective Date for %1 / %2', Locked = true;
        TaxDetailCountLbl: Label 'Tax Detail count for %1/%2', Locked = true;
        TaxAreaShouldExistLbl: Label 'Tax Area %1 should exist', Locked = true;
        JurisdictionDescriptionEqualsCodeLbl: Label 'Auto-created jurisdiction %1 should have Description = Code', Locked = true;
}
