namespace System.IO;

codeunit 5433 "Automation - Apply RSPackage"
{
    TableNo = "Config. Package";

    trigger OnRun()
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        Rec.Validate("Apply Status", Rec."Apply Status"::InProgress);
        Clear(Rec."Apply Error");
        Rec.Modify(true);

        ConfigPackageTable.SetRange("Package Code", Rec.Code);
        ConfigPackageMgt.SetHideDialog(true);
        ConfigPackageMgt.ApplyPackage(Rec, ConfigPackageTable, true);

        // refreshing the record as ApplyPackage updated the Configuration package with the number of records in the package, etc.
        Rec.Find();
        Rec.Validate("Apply Status", Rec."Apply Status"::Completed);
        Rec.Modify(true);
        Commit();
    end;
}

