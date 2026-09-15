codeunit 101411 "Create IC Dimension"
{
    // Create IC Dimension


    trigger OnRun()
    begin
        InsertData(XAREA, XAREAlc, false, XAREA);
        InsertData(XBUSINESSGROUP, XBusinessGrouplc, false, XBUSINESSGROUP);
        InsertData(XCUSTOMERGROUP, XCustomerGrouplc, false, XCUSTOMERGROUP);
    end;

    var
        XAREA: Label 'AREA';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XBusinessGrouplc: Label 'Business Group';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XCustomerGrouplc: Label 'Customer Group';
        XAREAlc: Label 'Area';

    procedure InsertData("Code": Code[20]; Name: Text[30]; Blocked: Boolean; "Map-to Dimension Code": Code[20])
    var
        ICDimension: Record "IC Dimension";
    begin
        ICDimension.Init();
        ICDimension.Code := Code;
        ICDimension.Name := Name;
        ICDimension.Blocked := Blocked;
        ICDimension.Validate("Map-to Dimension Code", "Map-to Dimension Code");
        ICDimension.Insert();
    end;
}

