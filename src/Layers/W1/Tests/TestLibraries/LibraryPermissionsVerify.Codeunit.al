codeunit 132216 "Library - Permissions Verify"
{

    trigger OnRun()
    begin
    end;

    var
        UserDoesNotHavePermissionSetErr: Label 'User %1 does not have permission set %2 in company %3.', Comment = '%1=user name, %2=permission set code, %3 = company name.';
        MissingPermissionErr: Label 'You do not have %1  permissions on TableData %2.';
        SupplementalPermissionErr: Label 'Supplemental permissions %1 given on TableData %2.';
        Assert: Codeunit Assert;

    procedure UserHasPermissionSet(UserID: Guid; PermissionSetCode: Code[20])
    begin
        UserHasPermissionSetInCompany(UserID, PermissionSetCode, CompanyName);
    end;

    procedure UserHasPermissionSetInCompany(UserID: Guid; PermissionSetCode: Code[20]; Company: Text[30])
    var
        AccessControl: Record "Access Control";
        User: Record User;
    begin
        User.Get(UserID);
        AccessControl.SetRange("User Security ID", UserID);
        AccessControl.SetRange("Role ID", PermissionSetCode);
        AccessControl.SetRange("Company Name", Company);
        if not AccessControl.FindFirst() then
            Error(UserDoesNotHavePermissionSetErr, User."Full Name", PermissionSetCode, Company);
    end;

    procedure CreateRecWithRelatedFields(RecordRef: RecordRef)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        RecordId: RecordID;
        RelatedRecordRef: RecordRef;
        RelatedRecordId: RecordID;
    begin
        RecordRef.Init();
        RecordRef.Insert(true);

        RecordId := RecordRef.RecordId;
        TableRelationsMetadata.SetRange("Table ID", RecordId.TableNo);
        TableRelationsMetadata.SetFilter("Field No.", '<>%1&<>%2',
            TableRelationsMetadata.FieldNo(SystemCreatedBy),
            TableRelationsMetadata.FieldNo(SystemModifiedBy));

        TableRelationsMetadata.FindSet();
        repeat
            if TableRelationsMetadata."Related Table ID" < 2000000000 then begin
                RelatedRecordRef.Open(TableRelationsMetadata."Related Table ID");
                RelatedRecordId := RelatedRecordRef.RecordId;
                if RelatedRecordId.TableNo <> RecordId.TableNo then begin
                    RelatedRecordRef.DeleteAll();
                    RelatedRecordRef.Init();
                    RelatedRecordRef.Insert();
                end;
                RelatedRecordRef.Close();
            end;
        until TableRelationsMetadata.Next() = 0;

        RecordRef.Close();
        Commit();
    end;

    [Scope('OnPrem')]
    procedure CheckReadAccessToRelatedTables(var ExcludedTables: DotNet GenericList1; RecordRef: RecordRef)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        RelatedRecordRef: RecordRef;
        RelatedRecordId: RecordID;
        RecordId: RecordID;
    begin
        TableRelationsMetadata.Init();
        RecordId := RecordRef.RecordId;
        TableRelationsMetadata.SetRange("Table ID", RecordId.TableNo);
        TableRelationsMetadata.SetFilter("Field No.", '<>%1&<>%2',
            TableRelationsMetadata.FieldNo(SystemCreatedBy),
            TableRelationsMetadata.FieldNo(SystemModifiedBy));
        if TableRelationsMetadata.FindSet() then
            repeat
                RelatedRecordRef.Open(TableRelationsMetadata."Related Table ID");
                RelatedRecordId := RelatedRecordRef.RecordId;
                if not ExcludedTables.Contains(RelatedRecordId.TableNo) then
                    VerifyReadPermissionTrue(RelatedRecordRef.Number);
                RelatedRecordRef.Close();
            until TableRelationsMetadata.Next() = 0;
    end;

    procedure VerifyReadPermissionTrue(TableNo: Integer)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);
        RecordRef.FindFirst();
        Assert.IsTrue(RecordRef.ReadPermission, StrSubstNo(MissingPermissionErr, 'Read', Format(RecordRef.Caption)));
    end;

    procedure VerifyReadPermissionFalse(TableNo: Integer)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);
        asserterror RecordRef.FindFirst();
        Assert.ExpectedError(StrSubstNo(MissingPermissionErr, Format(RecordRef.Caption)))
    end;

    procedure VerifyWritePermissionTrue(RecordRef: RecordRef)
    begin
        RecordRef.Init();
        RecordRef.Insert(true);
        RecordRef.Delete(true);
    end;

    procedure VerifyWritePermissionFalse(RecordRef: RecordRef)
    begin
        RecordRef.Init();

        asserterror RecordRef.Insert(true);
        Assert.IsFalse(RecordRef.WritePermission, StrSubstNo(SupplementalPermissionErr, 'Insert', Format(RecordRef.Caption)));

        asserterror RecordRef.Delete(true);
        Assert.IsFalse(RecordRef.WritePermission, StrSubstNo(SupplementalPermissionErr, 'Delete', Format(RecordRef.Caption)));
    end;
}

