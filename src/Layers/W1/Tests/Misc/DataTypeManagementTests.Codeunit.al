codeunit 135002 "Data Type Management Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Data Type Management]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetRecordRef()
    var
        CustRec: Record Customer;
        DataTypeManagement: Codeunit "Data Type Management";
        CustRecordRef: RecordRef;
        ResultRecordRefRec: RecordRef;
        ResultRecordRefRecRef: RecordRef;
        ResultRecordRefRecID: RecordRef;
        CustRecordID: RecordID;
    begin
        // [SCENARIO] GetRecordRef accepts parameter of types: Record, RecordRef, RecordID
        // [GIVEN] A Record, a RecordRef and a RecordID
        CustRec.FindFirst();
        CustRecordRef.GetTable(CustRec);
        CustRecordID := CustRecordRef.RecordId;

        // [WHEN] The GetRecordRef function is called with either of these three types
        DataTypeManagement.GetRecordRef(CustRec, ResultRecordRefRec);
        DataTypeManagement.GetRecordRef(CustRecordRef, ResultRecordRefRecRef);
        DataTypeManagement.GetRecordRef(CustRecordID, ResultRecordRefRecID);

        // [THEN] The same RecordRef is returned
        Assert.AreEqual(Format(ResultRecordRefRec), Format(ResultRecordRefRecRef), '');
        Assert.AreEqual(Format(ResultRecordRefRecRef), Format(ResultRecordRefRecID), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetRecordRefAndFieldRef()
    var
        CompanyInformationRec: Record "Company Information";
        DataTypeManagement: Codeunit "Data Type Management";
        CIRecordRef: RecordRef;
        ResultRecordRefRec: RecordRef;
        ResultRecordRefRecRef: RecordRef;
        ResultRecordRefRecID: RecordRef;
        ResultFieldRefRec: FieldRef;
        ResultFieldRefRecRef: FieldRef;
        ResultFieldRefRecID: FieldRef;
        CIRecordID: RecordID;
    begin
        // [SCENARIO] GetRecordRefAndFieldRef accepts parameter of types: Record, RecordRef, RecordID
        // [GIVEN] A Record, a RecordRef and a RecordID
        CompanyInformationRec.Get();
        CIRecordRef.GetTable(CompanyInformationRec);
        CIRecordID := CIRecordRef.RecordId;

        // [WHEN] The GetRecordRefAndFieldRef function is called with either of these three types
        DataTypeManagement.GetRecordRefAndFieldRef(CompanyInformationRec,
          CompanyInformationRec.FieldNo(Name), ResultRecordRefRec, ResultFieldRefRec);
        DataTypeManagement.GetRecordRefAndFieldRef(CIRecordRef,
          CompanyInformationRec.FieldNo(Name), ResultRecordRefRecRef, ResultFieldRefRecRef);
        DataTypeManagement.GetRecordRefAndFieldRef(CIRecordID,
          CompanyInformationRec.FieldNo(Name), ResultRecordRefRecID, ResultFieldRefRecID);

        // [THEN] The same FieldRef is returned
        Assert.AreEqual(Format(ResultFieldRefRec), Format(ResultFieldRefRecRef), '');
        Assert.AreEqual(Format(ResultFieldRefRecRef), Format(ResultFieldRefRecID), '');
    end;
}

