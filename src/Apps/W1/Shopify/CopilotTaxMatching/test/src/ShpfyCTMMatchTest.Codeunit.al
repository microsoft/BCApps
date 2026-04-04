namespace Microsoft.Integration.Shopify;

using System.TestLibraries.Utilities;
using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

/// <summary>
/// Codeunit Shpfy CTM Match Test (ID 30494).
/// Data-driven tests: real LLM call via MatchTaxLines, then FindOrCreateTaxArea.
/// </summary>
codeunit 30494 "Shpfy CTM Match Test"
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;
    Access = Internal;

    [Test]
    procedure MatchTaxLines()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        Matcher: Codeunit "Shpfy Copilot Tax Matcher";
        TaxAreaBuilder: Codeunit "Shpfy Tax Area Builder";
        TestLib: Codeunit "Shpfy CTM Test Library";
        Verify: Codeunit "Shpfy CTM Verify";
        Input: Codeunit "Test Input Json";
        Expected: Codeunit "Test Input Json";
        MatchedJurisdictions: List of [Code[10]];
        Result: Boolean;
        ExpectedResult: Boolean;
        ElementExists: Boolean;
    begin
        // Arrange
        TestLib.CleanupTestData();
        Input := TestLib.GetInput();

        Shop := TestLib.SetupShop(Input.Element('setup').Element('shopSettings'));
        TestLib.SetupTaxJurisdictions(Input.Element('setup'));
        SetupExistingData(TestLib, Input.Element('setup'));
        OrderHeader := TestLib.SetupOrder(Input.Element('setup'), Shop);

        // Act — real LLM call + tax area
        Result := Matcher.MatchTaxLines(OrderHeader, Shop, MatchedJurisdictions);
        if Result and (MatchedJurisdictions.Count() > 0) then
            TaxAreaBuilder.FindOrCreateTaxArea(OrderHeader, Shop, MatchedJurisdictions);

        // Log test output
        LogTestOutput(Input, OrderHeader, MatchedJurisdictions, Result);

        // Assert
        Expected := Input.Element('expected');

        Expected.ElementExists('matchResult', ElementExists);
        if ElementExists then begin
            ExpectedResult := Expected.Element('matchResult').ValueAsBoolean();
            LibraryAssert.AreEqual(ExpectedResult, Result, 'MatchTaxLines result');
        end;

        Verify.VerifyFromExpected(Expected, OrderHeader);
    end;

    local procedure LogTestOutput(Input: Codeunit "Test Input Json"; OrderHeader: Record "Shpfy Order Header"; MatchedJurisdictions: List of [Code[10]]; Result: Boolean)
    var
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        AnswerJson: JsonObject;
        ContextJson: JsonObject;
        MatchedArray: JsonArray;
        TaxLineObj: JsonObject;
        JurisdictionCode: Code[10];
        QueryText: Text;
        AnswerText: Text;
        ContextText: Text;
    begin
        // Query = test description
        QueryText := Input.Element('description').ValueAsText();

        // Answer = matched jurisdictions + tax lines result
        AnswerJson.Add('matchResult', Result);
        foreach JurisdictionCode in MatchedJurisdictions do
            MatchedArray.Add(JurisdictionCode);
        AnswerJson.Add('matchedJurisdictions', MatchedArray);

#pragma warning disable AA0181
        OrderHeader.Find();
#pragma warning restore AA0181
        AnswerJson.Add('taxAreaCode', OrderHeader."Tax Area Code");
        AnswerJson.Add('taxLiable', OrderHeader."Tax Liable");

        // Add matched tax line details
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                TaxLine.SetRange("Parent Id", OrderLine."Line Id");
                TaxLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
                if TaxLine.FindSet() then
                    repeat
                        Clear(TaxLineObj);
                        TaxLineObj.Add('parentId', TaxLine."Parent Id");
                        TaxLineObj.Add('lineNo', TaxLine."Line No.");
                        TaxLineObj.Add('title', TaxLine.Title);
                        TaxLineObj.Add('jurisdictionCode', TaxLine."Tax Jurisdiction Code");
                        MatchedArray.Add(TaxLineObj);
                    until TaxLine.Next() = 0;
            until OrderLine.Next() = 0;

        AnswerJson.WriteTo(AnswerText);

        // Context = setup data
        ContextJson.Add('setup', Input.Element('setup').AsJsonToken());
        ContextJson.WriteTo(ContextText);

        AITTestContext.SetQueryResponse(QueryText, AnswerText, ContextText);
    end;

    local procedure SetupExistingData(var TestLib: Codeunit "Shpfy CTM Test Library"; SetupInput: Codeunit "Test Input Json")
    var
        ElementExists: Boolean;
    begin
        SetupInput.ElementExists('existingTaxAreas', ElementExists);
        if ElementExists then
            TestLib.SetupExistingTaxAreas(SetupInput.Element('existingTaxAreas'));

        SetupInput.ElementExists('existingTaxDetails', ElementExists);
        if ElementExists then
            TestLib.SetupExistingTaxDetails(SetupInput.Element('existingTaxDetails'));
    end;

    var
        AITTestContext: Codeunit "AIT Test Context";
        LibraryAssert: Codeunit "Library Assert";
}
