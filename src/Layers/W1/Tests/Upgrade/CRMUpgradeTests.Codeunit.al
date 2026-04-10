codeunit 135959 "CRM Upgrade Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Backup/Restore Permissions]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateUpgradeIntegrationTableMappingFilterForOpportunities()
    var
        UPGIntegrationTableMapping: Record "UPG-Integration Table Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Opportunity: Record Opportunity;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        UprgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
        OldTableFilter: Text;
        NewTableFilter: Text;
        DefaultTableFilter: Text;
    begin
        if not UprgradeStatus.UpgradeTriggered() then
            exit;

        if UprgradeStatus.UpgradeTagPresentBeforeUpgrade(
            UpgradeTagDefinitions.GetIntegrationTableMappingFilterForOpportunitiesUpgradeTag()) then
            exit;

        if not UPGIntegrationTableMapping.Get('OPPORTUNITY') then
            exit;

        if not IntegrationTableMapping.Get('OPPORTUNITY') then
            exit;

        OldTableFilter := UPGIntegrationTableMapping.GetTableFilter();
        NewTableFilter := IntegrationTableMapping.GetTableFilter();
        if OldTableFilter = '' then begin
            Opportunity.SetFilter(Status, '%1|%2', Opportunity.Status::"Not Started", Opportunity.Status::"In Progress");
            DefaultTableFilter := CRMSetupDefaults.GetTableFilterFromView(Database::Opportunity, Opportunity.TableCaption(), Opportunity.GetView());
            Assert.AreEqual(DefaultTableFilter, NewTableFilter, 'Expected Table Filter for OPPORTUNITY mapping has default value');
        end else
            Assert.AreEqual(OldTableFilter, NewTableFilter, 'Expected Table Filter for OPPORTUNITY mapping is not changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateUpgradeIntegrationFieldMappingForOpportunities()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        UprgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UprgradeStatus.UpgradeTriggered() then
            exit;

        if UprgradeStatus.UpgradeTagPresentBeforeUpgrade(
            UpgradeTagDefinitions.GetIntegrationFieldMappingForOpportunitiesUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Name, 'OPPORTUNITY');
        IntegrationTableMapping.SetRange("Table ID", Database::Opportunity);
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Opportunity");
        if IntegrationTableMapping.FindFirst() then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange("Field No.", Opportunity.FieldNo("Contact Company No."));
            IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMOpportunity.FieldNo(ParentAccountId));
            Assert.IsFalse(IntegrationFieldMapping.IsEmpty(), 'Integration Field Mapping between Contact Company No. and ParentAccountId does not exist');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateUpgradeIntegrationFieldMappingForContacts()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TempContact: Record Contact temporary;
        UprgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UprgradeStatus.UpgradeTriggered() then
            exit;

        if UprgradeStatus.UpgradeTagPresentBeforeUpgrade(
            UpgradeTagDefinitions.GetIntegrationFieldMappingForContactsUpgradeTag()) then
            exit;

        IntegrationTableMapping.SetRange(Name, 'CONTACT');
        IntegrationTableMapping.SetRange("Table ID", Database::Contact);
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Contact");
        if IntegrationTableMapping.FindFirst() then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange("Field No.", TempContact.FieldNo(Type));
            IntegrationFieldMapping.SetRange("Integration Table Field No.", 0);
            IntegrationFieldMapping.SetRange(Direction, IntegrationFieldMapping.Direction::FromIntegrationTable);
            IntegrationFieldMapping.SetRange("Transformation Direction", IntegrationFieldMapping."Transformation Direction"::FromIntegrationTable);
            if IntegrationFieldMapping.FindFirst() then
                Assert.AreEqual('Person', IntegrationFieldMapping."Constant Value", 'Constant Value for CONTACT.Type mapping is incorrect');
        end;
    end;
}