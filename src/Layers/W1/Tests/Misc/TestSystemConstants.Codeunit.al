codeunit 139095 "Test System Constants"
{
    // Make sure that the version number substitution logic that we have in our build system does not break.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Application System Constants] [System] [Help and Support]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeRoleCenterFromMySettings()
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        CheckNotEmptyNotPlaceholder(ApplicationSystemConstants.ApplicationBuild());
        CheckNotEmptyNotPlaceholder(ApplicationSystemConstants.ApplicationVersion());
        CheckNotEmptyNotPlaceholder(ApplicationSystemConstants.OriginalApplicationVersion());
        CheckNotEmptyNotPlaceholder(ApplicationSystemConstants.BuildBranch());
        CheckNotEmptyNotPlaceholder(ApplicationSystemConstants.PlatformFileVersion());
        CheckNotEmptyNotPlaceholder(ApplicationSystemConstants.PlatformProductVersion());
    end;

    local procedure CheckNotEmptyNotPlaceholder(valueOfTheConstant: text)
    begin
        Assert.AreNotEqual(valueOfTheConstant, '', 'The placeholder was substituted with an empty value.');
        Assert.AreNotEqual(1, StrPos(valueOfTheConstant, '!'), StrSubstNo('The placeholder has not been populated: %1.', valueOfTheConstant));
    end;
}
