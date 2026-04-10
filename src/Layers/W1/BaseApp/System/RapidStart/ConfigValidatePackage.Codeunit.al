namespace System.IO;

codeunit 8621 "Config. Validate Package"
{
    TableNo = "Config. Package Table";

    trigger OnRun()
    var
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigPackageMgt.SetHideDialog(true);
        ConfigPackageMgt.ValidatePackageRelations(Rec, TempConfigPackageTable, true);
    end;
}

