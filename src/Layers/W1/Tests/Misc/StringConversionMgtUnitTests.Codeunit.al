codeunit 132595 "StringConversionMgt Unit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [String Conversion] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveNonAlphaNumericCharacters()
    var
        StringConversionManagement: Codeunit StringConversionManagement;
    begin
        // [SCENARIO] The RemoveNonAlphaNumericCharacters function works as expected
        // [GIVEN] A string with non alpha numeric characters
        // [WHEN] The RemoveNonAlphaNumericCharacters function is called on the string
        // [THEN] All non alpha numeric characters have been removed
        Assert.AreEqual(
          'ThisisaTest',
          StringConversionManagement.RemoveNonAlphaNumericCharacters('This ! is @ a # Test.'),
          'RemoveNonAlphaNumericCharacters failed.');
    end;
}

