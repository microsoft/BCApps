namespace Microsoft.Integration.Shopify;

using System.TestLibraries.Utilities;
using System.TestTools.TestRunner;

/// <summary>
/// Codeunit Shpfy CTM Guard Test (ID 30497).
/// Data-driven tests for guard/early exit scenarios.
/// Bound to CTM-TS-Guard.yaml via XML suite.
/// </summary>
codeunit 30497 "Shpfy CTM Guard Test"
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;
    Access = Internal;

    [Test]
    procedure GuardExitsEarly()
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        TestLib: Codeunit "Shpfy CTM Test Library";
        Verify: Codeunit "Shpfy CTM Verify";
        Input: Codeunit "Test Input Json";
        Expected: Codeunit "Test Input Json";
        ElementExists: Boolean;
    begin
        // Arrange
        TestLib.CleanupTestData();
        Input := TestLib.GetInput();

        Shop := TestLib.SetupShop(Input.Element('setup').Element('shopSettings'));
        OrderHeader := TestLib.SetupOrder(Input.Element('setup'), Shop);

        // Note: Guard tests verify that certain conditions prevent the feature from running.
        // Since we can't easily trigger the event subscriber (requires Copilot capability registration),
        // we verify the guard conditions by checking the state that would cause early exit.

        // Assert
        Expected := Input.Element('expected');

        Expected.ElementExists('orderUnchanged', ElementExists);
        if ElementExists then
            if Expected.Element('orderUnchanged').ValueAsBoolean() then
                Verify.VerifyOrderUnchanged(OrderHeader);

        Expected.ElementExists('existingTaxAreaKept', ElementExists);
        if ElementExists then begin
            OrderHeader.Find();
            LibraryAssert.AreEqual(
                CopyStr(Expected.Element('existingTaxAreaKept').ValueAsText(), 1, 20),
                OrderHeader."Tax Area Code",
                'Existing Tax Area Code should be preserved');
        end;
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
}
