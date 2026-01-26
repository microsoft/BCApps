codeunit 101122 "Create Assessee Code"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();

        InsertData('AOP', XAOP, "Assessee Type"::Others);
        InsertData('BOI', XBOI, "Assessee Type"::Others);
        InsertData('COM', XCOM, "Assessee Type"::Company);
        InsertData('HUF', XHUF, "Assessee Type"::Others);
        InsertData('IND', XIND, "Assessee Type"::Others);
        InsertData('NRI', XNRI, "Assessee Type"::Others);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XAOP: Label 'Association of Persons';
        XBOI: Label 'Body Of Individuals';
        XCOM: Label 'Company';
        XHUF: Label 'Hindu Undivided Family';
        XIND: Label 'Individual';
        XNRI: Label 'Non Resident Indian';

    procedure InsertMiniAppData()
    begin
        AddAssesseeForMini();
    end;

    local procedure AddAssesseeForMini()
    begin
        DemoDataSetup.Get();
        InsertData('AOP', XAOP, "Assessee Type"::Others);
        InsertData('BOI', XBOI, "Assessee Type"::Others);
        InsertData('COM', XCOM, "Assessee Type"::Company);
        InsertData('HUF', XHUF, "Assessee Type"::Others);
        InsertData('IND', XIND, "Assessee Type"::Others);
        InsertData('NRI', XNRI, "Assessee Type"::Others);
    end;

    procedure InsertData(Code: Code[20]; Description: Text[50]; AssesseeType: Enum "Assessee Type")
    var
        AssesseeCode: Record "Assessee Code";
    begin
        AssesseeCode.Init();
        AssesseeCode.Validate(Code, Code);
        AssesseeCode.Validate(Description, Description);
        AssesseeCode.Validate(Type, AssesseeType);
        AssesseeCode.Insert();
    end;
}