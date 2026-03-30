namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using System.TestLibraries.Utilities;
using System.TestTools.TestRunner;

/// <summary>
/// Codeunit Shpfy CTM Tax Area Test (ID 30495).
/// Data-driven tests for Tax Area finding/creation.
/// Bound to CTM-TS-TaxArea.yaml via XML suite.
/// </summary>
codeunit 30495 "Shpfy CTM Tax Area Test"
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;
    Access = Internal;

    [Test]
    procedure FindOrCreateTaxArea()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        TaxAreaBuilder: Codeunit "Shpfy Tax Area Builder";
        TestLib: Codeunit "Shpfy CTM Test Library";
        Verify: Codeunit "Shpfy CTM Verify";
        Input: Codeunit "Test Input Json";
        Expected: Codeunit "Test Input Json";
        JurisdictionCodesInput: Codeunit "Test Input Json";
        JurisdictionCodes: List of [Code[10]];
        Result: Boolean;
        ElementExists: Boolean;
        i: Integer;
    begin
        // Arrange
        TestLib.CleanupTestData();
        Input := TestLib.GetInput();

        Shop := TestLib.SetupShop(Input.Element('setup').Element('shopSettings'));

        // Set up jurisdictions needed for tax area lines
        TestLib.SetupTaxJurisdictions(Input.Element('setup'));

        // Set up existing tax areas
        Input.Element('setup').ElementExists('existingTaxAreas', ElementExists);
        if ElementExists then
            TestLib.SetupExistingTaxAreas(Input.Element('setup').Element('existingTaxAreas'));

        // Create order header
        OrderHeader := TestLib.SetupOrder(Input.Element('setup'), Shop);

        // Build jurisdiction codes list
        JurisdictionCodesInput := Input.Element('setup').Element('jurisdictionCodes');
        for i := 0 to JurisdictionCodesInput.GetElementCount() - 1 do
            JurisdictionCodes.Add(CopyStr(JurisdictionCodesInput.ElementAt(i).ValueAsText(), 1, 10));

        // Ensure all jurisdiction records exist
        EnsureJurisdictionsExist(JurisdictionCodes);

        // Act
        Result := TaxAreaBuilder.FindOrCreateTaxArea(OrderHeader, Shop, JurisdictionCodes);

        // Assert
        Expected := Input.Element('expected');

        Expected.ElementExists('taxAreaCreated', ElementExists);
        if ElementExists then begin
            if Expected.Element('taxAreaCode').ValueAsText() = '' then
                LibraryAssert.IsFalse(Result, 'FindOrCreateTaxArea should return false')
            else
                LibraryAssert.IsTrue(Result, 'FindOrCreateTaxArea should return true');
        end;

        Expected.ElementExists('taxAreaCode', ElementExists);
        if ElementExists then begin
            OrderHeader.Find();
            LibraryAssert.AreEqual(
                CopyStr(Expected.Element('taxAreaCode').ValueAsText(), 1, 20),
                OrderHeader."Tax Area Code",
                'Order Tax Area Code');
        end;

        Expected.ElementExists('taxLiable', ElementExists);
        if ElementExists then begin
            OrderHeader.Find();
            LibraryAssert.AreEqual(Expected.Element('taxLiable').ValueAsBoolean(), OrderHeader."Tax Liable", 'Order Tax Liable');
        end;

        Verify.VerifyTaxAreaCreated(Expected);
    end;

    local procedure EnsureJurisdictionsExist(JurisdictionCodes: List of [Code[10]])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        JurisdictionCode: Code[10];
    begin
        foreach JurisdictionCode in JurisdictionCodes do
            if not TaxJurisdiction.Get(JurisdictionCode) then begin
                TaxJurisdiction.Init();
                TaxJurisdiction.Code := JurisdictionCode;
                TaxJurisdiction.Description := JurisdictionCode;
                TaxJurisdiction.Insert(true);
            end;
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
}
