codeunit 132807 "Removed Tables Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupReferencesToRemovedTables()
    begin
        InsertChangeLogSetupReferences();
    end;

    local procedure InsertChangeLogSetupReferences()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        // Insert references to removed tables
        ChangeLogSetupTable."Table No." := 132805; // "Table State Obsolete Removed"
        ChangeLogSetupTable.Insert();

        // Insert references to non-removed tables
        ChangeLogSetupTable."Table No." := Database::Customer;
        ChangeLogSetupTable.Insert();

        ChangeLogSetupTable."Table No." := Database::Item;
        ChangeLogSetupTable.Insert();
    end;
}