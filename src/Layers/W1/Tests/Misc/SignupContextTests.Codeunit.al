codeunit 132859 "Signup Context Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SignupContextKnownValues()
    var
        Assert: Codeunit Assert;
        SignupContextName: Text;
    begin
        foreach SignupContextName in Enum::"Signup Context".Names() do
            Assert.IsTrue(SignupContextName in [' ', 'Viral Signup', 'Test Value', 'Test Value 2', 'Shopify'], 'Unknown signup context. Please update the list of known signup contexts. See the comment in the test for more details.')
        // When you add a new signup context you have to:
        // - extend the enum
        // - ensure the if's and cases on the enum are updated
        //   - in baseapp where we set up the checklist
        //   - in shopify where we set up the checklist
        // - update this test
        // - update this comment if the process changes
    end;
}
