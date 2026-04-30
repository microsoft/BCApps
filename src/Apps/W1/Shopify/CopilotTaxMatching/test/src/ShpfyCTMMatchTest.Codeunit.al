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
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        TaxAreaBuilder: Codeunit "Shpfy Tax Area Builder";
        CTMTestLibrary: Codeunit "Shpfy CTM Test Library";
        CTMVerify: Codeunit "Shpfy CTM Verify";
        Input: Codeunit "Test Input Json";
        Expected: Codeunit "Test Input Json";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        ResolvedTaxAreaCode: Code[20];
        TaxAreaWasCreated: Boolean;
        Result: Boolean;
        ExpectedResult: Boolean;
        ElementExists: Boolean;
    begin
        // Arrange
        CTMTestLibrary.CleanupTestData();
        Input := CTMTestLibrary.GetInput();

        Shop := CTMTestLibrary.SetupShop(Input.Element('setup').Element('shopSettings'));
        CTMTestLibrary.SetupTaxJurisdictions(Input.Element('setup'));
        SetupExistingData(CTMTestLibrary, Input.Element('setup'));
        OrderHeader := CTMTestLibrary.SetupOrder(Input.Element('setup'), Shop);

        // Act — real LLM call + tax area
        Result := CopilotTaxMatcher.MatchTaxLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog);
        if Result and (MatchedJurisdictions.Count() > 0) then
            TaxAreaBuilder.FindOrCreateTaxArea(OrderHeader, Shop, MatchedJurisdictions, ResolvedTaxAreaCode, TaxAreaWasCreated);

        // Log test output
        LogTestOutput(Input, OrderHeader, MatchedJurisdictions, Result);

        // Assert
        Expected := Input.Element('expected');

        Expected.ElementExists('matchResult', ElementExists);
        if ElementExists then begin
            ExpectedResult := Expected.Element('matchResult').ValueAsBoolean();
            LibraryAssert.AreEqual(ExpectedResult, Result, 'MatchTaxLines result');
        end;

        CTMVerify.VerifyFromExpected(Expected, OrderHeader);
    end;

    local procedure LogTestOutput(Input: Codeunit "Test Input Json"; OrderHeader: Record "Shpfy Order Header"; MatchedJurisdictions: List of [Code[10]]; Result: Boolean)
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
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
                OrderTaxLine.SetRange("Parent Id", OrderLine."Line Id");
                OrderTaxLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
                if OrderTaxLine.FindSet() then
                    repeat
                        Clear(TaxLineObj);
                        TaxLineObj.Add('parentId', OrderTaxLine."Parent Id");
                        TaxLineObj.Add('lineNo', OrderTaxLine."Line No.");
                        TaxLineObj.Add('title', OrderTaxLine.Title);
                        TaxLineObj.Add('jurisdictionCode', OrderTaxLine."Tax Jurisdiction Code");
                        MatchedArray.Add(TaxLineObj);
                    until OrderTaxLine.Next() = 0;
            until OrderLine.Next() = 0;

        AnswerJson.WriteTo(AnswerText);

        // Context = setup data
        ContextJson.Add('setup', Input.Element('setup').AsJsonToken());
        ContextJson.WriteTo(ContextText);

        AITTestContext.SetQueryResponse(QueryText, AnswerText, ContextText);
    end;

    local procedure SetupExistingData(var CTMTestLibrary: Codeunit "Shpfy CTM Test Library"; SetupInput: Codeunit "Test Input Json")
    var
        ElementExists: Boolean;
    begin
        SetupInput.ElementExists('existingTaxAreas', ElementExists);
        if ElementExists then
            CTMTestLibrary.SetupExistingTaxAreas(SetupInput.Element('existingTaxAreas'));

        SetupInput.ElementExists('existingTaxDetails', ElementExists);
        if ElementExists then
            CTMTestLibrary.SetupExistingTaxDetails(SetupInput.Element('existingTaxDetails'));

        CTMTestLibrary.SetupGLAccounts(SetupInput);
    end;

    var
        AITTestContext: Codeunit "AIT Test Context";
        LibraryAssert: Codeunit "Library Assert";
}
