namespace Microsoft.FabricExport;

table 9102 "Fabric Config Package"
{
    Caption = 'Fabric Config Package';
    Access = Internal;
    DataPerCompany = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; Version; Code[10])
        {
            Caption = 'Version';
            DataClassification = SystemMetadata;
        }
        field(4; Active; Boolean)
        {
            Caption = 'Active';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(5; "Activated On"; DateTime)
        {
            Caption = 'Activated On';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6; "Activated By"; Code[50])
        {
            Caption = 'Activated By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(7; "Last Activated Version"; Code[10])
        {
            Caption = 'Last Activated Version';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    var
        ActivePackageDeleteErr: Label 'Config package ''%1'' is active. Deactivate it before deleting.', Comment = '%1 = package code';

    trigger OnDelete()
    var
        PackageLine: Record "Fabric Config Package Line";
    begin
        if Active then
            Error(ActivePackageDeleteErr, "Code");

        PackageLine.SetRange("Package Code", "Code");
        PackageLine.DeleteAll(true);
    end;
}
