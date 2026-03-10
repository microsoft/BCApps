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
            VerifyTaxLineJurisdictions(Expected.Element('taxLineJurisdictions'), OrderHeader);

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
    end;

    local procedure VerifyTaxLineJurisdictions(ExpectedArray: Codeunit "Test Input Json"; OrderHeader: Record "Shpfy Order Header")
    var
        TaxLine: Record "Shpfy Order Tax Line";
        ExpectedItem: Codeunit "Test Input Json";
        ParentId: BigInteger;
        LineNo: Integer;
        ExpectedCode: Code[10];
        ElementExists: Boolean;
        i: Integer;
    begin
        for i := 0 to ExpectedArray.GetElementCount() - 1 do begin
            ExpectedItem := ExpectedArray.ElementAt(i);
            Evaluate(ParentId, ExpectedItem.Element('parentId').ValueAsText());
            Evaluate(LineNo, ExpectedItem.Element('lineNo').ValueAsText());

            LibraryAssert.IsTrue(TaxLine.Get(ParentId, LineNo),
                StrSubstNo('Tax line %1-%2 should exist', ParentId, LineNo));

            ExpectedItem.ElementExists('jurisdictionCode', ElementExists);
            if ElementExists then
                LibraryAssert.AreEqual(
                    CopyStr(ExpectedItem.Element('jurisdictionCode').ValueAsText(), 1, 10),
                    TaxLine."Tax Jurisdiction Code",
                    StrSubstNo('Tax line %1-%2 jurisdiction code', ParentId, LineNo));

            ExpectedItem.ElementExists('hasJurisdictionCode', ElementExists);
            if ElementExists then
                if ExpectedItem.Element('hasJurisdictionCode').ValueAsBoolean() then
                    LibraryAssert.AreNotEqual('', TaxLine."Tax Jurisdiction Code",
                        StrSubstNo('Tax line %1-%2 should have a jurisdiction code', ParentId, LineNo));
        end;
    end;

    local procedure VerifyAllTaxLinesMatched(OrderHeader: Record "Shpfy Order Header")
    var
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
    begin
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                TaxLine.SetRange("Parent Id", OrderLine."Line Id");
                if TaxLine.FindSet() then
                    repeat
                        LibraryAssert.AreNotEqual('', TaxLine."Tax Jurisdiction Code",
                            StrSubstNo('Tax line %1-%2 should be matched', TaxLine."Parent Id", TaxLine."Line No."));
                    until TaxLine.Next() = 0;
            until OrderLine.Next() = 0;
    end;

    local procedure VerifyCreatedJurisdictionCountryRegion(OrderHeader: Record "Shpfy Order Header"; ExpectedCountryRegion: Text)
    var
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                TaxLine.SetRange("Parent Id", OrderLine."Line Id");
                if TaxLine.FindSet() then
                    repeat
                        if TaxLine."Tax Jurisdiction Code" <> '' then
                            if TaxJurisdiction.Get(TaxLine."Tax Jurisdiction Code") then
                                LibraryAssert.AreEqual(
                                    ExpectedCountryRegion,
                                    Format(TaxJurisdiction."Country/Region"),
                                    StrSubstNo('Jurisdiction %1 Country/Region', TaxJurisdiction.Code));
                    until TaxLine.Next() = 0;
            until OrderLine.Next() = 0;
    end;

    local procedure VerifyReportToAllSame(OrderHeader: Record "Shpfy Order Header")
    var
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        FirstReportTo: Code[10];
        FoundFirst: Boolean;
    begin
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                TaxLine.SetRange("Parent Id", OrderLine."Line Id");
                if TaxLine.FindSet() then
                    repeat
                        if TaxLine."Tax Jurisdiction Code" <> '' then
                            if TaxJurisdiction.Get(TaxLine."Tax Jurisdiction Code") then begin
                                if not FoundFirst then begin
                                    FirstReportTo := TaxJurisdiction."Report-to Jurisdiction";
                                    FoundFirst := true;
                                end else
                                    LibraryAssert.AreEqual(FirstReportTo, TaxJurisdiction."Report-to Jurisdiction",
                                        StrSubstNo('Jurisdiction %1 Report-to should match first', TaxJurisdiction.Code));
                            end;
                    until TaxLine.Next() = 0;
            until OrderLine.Next() = 0;

        LibraryAssert.IsTrue(FoundFirst, 'At least one jurisdiction should have Report-to set');
    end;

    local procedure VerifyTaxDetailExists(ExpectedArray: Codeunit "Test Input Json"; OrderHeader: Record "Shpfy Order Header")
    var
        TaxDetail: Record "Tax Detail";
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        ExpectedItem: Codeunit "Test Input Json";
        TaxGroupCode: Code[20];
        RatePct: Decimal;
        i: Integer;
    begin
        for i := 0 to ExpectedArray.GetElementCount() - 1 do begin
            ExpectedItem := ExpectedArray.ElementAt(i);
            TaxGroupCode := CopyStr(ExpectedItem.Element('taxGroupCode').ValueAsText(), 1, MaxStrLen(TaxGroupCode));
            RatePct := ExpectedItem.Element('ratePct').ValueAsDecimal();

            // Find matched tax lines to get the jurisdiction code
            OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
            if OrderLine.FindSet() then
                repeat
                    TaxLine.SetRange("Parent Id", OrderLine."Line Id");
                    TaxLine.SetRange("Rate %", RatePct);
                    TaxLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
                    if TaxLine.FindFirst() then begin
                        TaxDetail.SetRange("Tax Jurisdiction Code", TaxLine."Tax Jurisdiction Code");
                        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
                        TaxDetail.SetRange("Tax Below Maximum", RatePct);
                        LibraryAssert.IsTrue(TaxDetail.FindFirst(),
                            StrSubstNo('Tax Detail should exist for %1 / %2 / %3',
                                TaxLine."Tax Jurisdiction Code", TaxGroupCode, RatePct));
                    end;
                until OrderLine.Next() = 0;
        end;
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
            StrSubstNo('Tax Detail count for %1/%2', JurisdictionCode, TaxGroupCode));
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
                StrSubstNo('Tax Area %1 should exist', TaxAreaCode));

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
        OrderHeader.Find();
        LibraryAssert.AreEqual('', OrderHeader."Tax Area Code", 'Tax Area Code should be blank');
        LibraryAssert.IsFalse(OrderHeader."Tax Liable", 'Tax Liable should be false');
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
}
