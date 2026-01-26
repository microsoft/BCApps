codeunit 160807 "Create SAF-T Media"
{

    trigger OnRun()
    begin
        InsertDataToSystemTable('General_Ledger_Standard_Accounts_2_character.xml');
        InsertDataToSystemTable('General_Ledger_Standard_Accounts_4_character.xml');
        InsertDataToSystemTable('KA_Grouping_Category_Code.xml');
        InsertDataToSystemTable('RF-1167_Grouping_Category_Code.xml');
        InsertDataToSystemTable('RF-1175_Grouping_Category_Code.xml');
        InsertDataToSystemTable('RF-1323_Grouping_Category_Code.xml');
        InsertDataToSystemTable('Standard_Tax_Codes.xml');
    end;

    local procedure InsertDataToSystemTable(FileName: Text[50])
    var
        MediaResources: Record "Media Resources";
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
    begin
        if MediaResources.Get(FileName) then begin
            MediaResources.Delete();
            Commit();
        end;

        MediaResourcesMgt.InsertBLOBFromFile('localfiles\', FileName);
    end;
}

