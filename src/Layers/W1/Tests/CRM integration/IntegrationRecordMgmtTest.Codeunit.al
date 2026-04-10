codeunit 139167 "Integration Record Mgmt. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Integration Record]
    end;

    var
        Assert: Codeunit Assert;
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";


    [Test]
    [Scope('OnPrem')]
    procedure CannotFindRecordIdByIntegrationTableUid()
    var
        Customer: Record Customer;
        CustomerRecordId: RecordID;
        IntegrationTableUid: Guid;
    begin
        Initialize();

        // Setup customer, integration record but no crm integration record
        IntegrationTableUid := CreateGuid();
        LibrarySales.CreateCustomer(Customer);

        // Execute
        IntegrationRecordManagement.FindRecordIdByIntegrationTableUid(
          TABLECONNECTIONTYPE::CRM,
          IntegrationTableUid, DATABASE::Customer, CustomerRecordId);

        // Validate recordid does not match
        Assert.IsFalse(Customer.RecordId = CustomerRecordId, 'Expected the Record ID to match the customer record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotFindIntegrationTableUidByRecordId()
    var
        Customer: Record Customer;
        CustomerIntegrationTableUidVariant: Variant;
        IntegrationTableUid: Guid;
        CustomerIntegrationTableUid: Guid;
    begin
        Initialize();

        // Setup customer, integration record but no crm integration record
        IntegrationTableUid := CreateGuid();
        LibrarySales.CreateCustomer(Customer);

        // Execute
        IntegrationRecordManagement.FindIntegrationTableUIdByRecordId(TABLECONNECTIONTYPE::CRM,
          Customer.RecordId, CustomerIntegrationTableUidVariant);

        // Validate integration table uid is not found - variant cannot be assigned to guid
        Assert.IsFalse(CustomerIntegrationTableUidVariant.IsGuid, 'Did not expect to find a integration table uid');
        asserterror CustomerIntegrationTableUid := CustomerIntegrationTableUidVariant;
    end;

    local procedure Initialize()
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
    end;
}

