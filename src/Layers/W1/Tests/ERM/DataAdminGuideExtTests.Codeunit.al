codeunit 134142 "Data Admin. Guide Ext. Tests"
{
    Subtype = Normal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Page, Page::"Data Administration Guide", 'OnAfterLoadPages', '', false, false)]
    local procedure AddTestPagesOnAfterLoadPages(var GuidePages: List of [Enum "Data Administration Guide Page"]; var SkipTo: Dictionary of [Enum "Data Administration Guide Page", Enum "Data Administration Guide Page"]; var HideNext: List of [Enum "Data Administration Guide Page"])
    var
        DataAdministrationGuidePage: enum "Data Administration Guide Page";
    begin
        GuidePages.Insert(GuidePages.IndexOf(DataAdministrationGuidePage::Introduction) + 1, DataAdministrationGuidePage::TestGuidePage1); // insert after introduction
        GuidePages.Insert(GuidePages.IndexOf(DataAdministrationGuidePage::DateCompressionIntro), DataAdministrationGuidePage::TestGuidePage2); // insert before DateCompressionIntro

        SkipTo.Add(DataAdministrationGuidePage::TestGuidePage2, DataAdministrationGuidePage::Conclusion) // skip from TestGuidePage2 to DateCompressionRun
    end;

    [EventSubscriber(ObjectType::Page, Page::"Data Administration Guide", 'OnAfterUpdateControls', '', false, false)]
    local procedure MyProcedure(Sender: Page "Data Administration Guide"; CurrentPage: Enum "Data Administration Guide Page")
    begin
        Sender.ERMTestsSetCurrentPage(CurrentPage);
    end;
}