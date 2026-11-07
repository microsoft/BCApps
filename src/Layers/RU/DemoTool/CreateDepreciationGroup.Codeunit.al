codeunit 163401 "Create Depreciation Group"
{

    trigger OnRun()
    begin
        InsertData('1', StrSubstNo(Text001, 1, 2));
        InsertData('2', StrSubstNo(Text002, 2, 3));
        InsertData('3', StrSubstNo(Text002, 3, 5));
        InsertData('4', StrSubstNo(Text002, 5, 7));
        InsertData('5', StrSubstNo(Text002, 7, 10));
        InsertData('6', StrSubstNo(Text002, 10, 15));
        InsertData('7', StrSubstNo(Text002, 15, 20));
        InsertData('8', StrSubstNo(Text002, 20, 25));
        InsertData('9', StrSubstNo(Text002, 25, 30));
        InsertData('10', StrSubstNo(Text003, 30));
    end;

    var
        DepreciationGroup: Record "Depreciation Group";
        Text001: Label 'From %1 to %2 years incl.';
        Text002: Label 'Above %1 to %2 years incl.';
        Text003: Label 'Above %1 years';

    procedure InsertData("Code": Code[20]; Description: Text[250])
    begin
        DepreciationGroup.Init();
        DepreciationGroup.Code := Code;
        DepreciationGroup.Description := Description;
        if DepreciationGroup.Insert() then;
    end;
}

