codeunit 118854 "Create Miniform Header"
{

    trigger OnRun()
    begin
        InsertData('LOGIN', XLogin, 4, MiniformHeader."Form Type"::Card, true, 7705, 'MAINMENU');
        InsertData('LOGOFF', XLogoff, 4, MiniformHeader."Form Type"::"Selection List", false, 7706, '');
        InsertData('MAINMENU', XMainMenuList, 6, MiniformHeader."Form Type"::"Selection List", false, 7707, '');
        InsertData('PHYSICALINV', XPhysicalInventoryJournal, 1, MiniformHeader."Form Type"::"Data List Input", false, 7713, '');
        InsertData('WHSEACTLINES', XSelectedWhseActivityLine, 1, MiniformHeader."Form Type"::"Data List Input", false, 7711, '');
        InsertData('WHSEBATCHLIST', XSelectionListWhseJournal, 3, MiniformHeader."Form Type"::"Data List", false, 7712, 'PHYSICALINV');
        InsertData('WHSEMOVELIST', XSelectionListWhseActivity, 3, MiniformHeader."Form Type"::"Data List", false, 7710, 'WHSEACTLINES');
        InsertData('WHSEPICKLIST', XSelectionListWhseActivity, 3, MiniformHeader."Form Type"::"Data List", false, 7708, 'WHSEACTLINES');
        InsertData('WHSEPUTLIST', XSelectionListWhseActivity, 6, MiniformHeader."Form Type"::"Data List", false, 7709, 'WHSEACTLINES');
    end;

    var
        MiniformHeader: Record "Miniform Header";
        XLogin: Label 'Login';
        XLogoff: Label 'Logoff';
        XMainMenuList: Label 'Main Menu List';
        XPhysicalInventoryJournal: Label 'Physical Inventory Journal';
        XSelectedWhseActivityLine: Label 'Selected Whse. Activity Line';
        XSelectionListWhseJournal: Label 'Selection List Whse. Journal';
        XSelectionListWhseActivity: Label 'Selection List Whse. Activity';

    procedure InsertData("Code": Code[20]; Description: Text[30]; NoOfRecords: Integer; FormType: Option; StartMiniform: Boolean; HandlingCodeunit: Integer; NextMiniform: Code[20])
    begin
        MiniformHeader.Init();
        MiniformHeader.Validate(Code, Code);
        MiniformHeader.Validate(Description, Description);
        MiniformHeader.Validate("No. of Records in List", NoOfRecords);
        MiniformHeader.Validate("Form Type", FormType);
        MiniformHeader."Start Miniform" := StartMiniform;
        MiniformHeader.Validate("Handling Codeunit", HandlingCodeunit);
        MiniformHeader."Next Miniform" := NextMiniform;
        MiniformHeader.Insert(true);
    end;
}

