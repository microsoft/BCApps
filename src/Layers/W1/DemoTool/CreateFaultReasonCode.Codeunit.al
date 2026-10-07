codeunit 117018 "Create Fault Reason Code"
{

    trigger OnRun()
    begin
        InsertData(XDMO, XDamagedbyowner, true, true);
        InsertData(XME, XManufactureError, false, false);
    end;

    var
        XDMO: Label 'DMO';
        XDamagedbyowner: Label 'Damaged by owner';
        XME: Label 'ME';
        XManufactureError: Label 'Manufacture Error';

    procedure InsertData("Code": Text[250]; Description: Text[250]; "Exclude Warranty Discount": Boolean; "Exclude Contract Discount": Boolean)
    var
        FaultReasonCode: Record "Fault Reason Code";
    begin
        FaultReasonCode.Init();
        FaultReasonCode.Validate(Code, Code);
        FaultReasonCode.Validate(Description, Description);
        FaultReasonCode.Validate("Exclude Warranty Discount", "Exclude Warranty Discount");
        FaultReasonCode.Validate("Exclude Contract Discount", "Exclude Contract Discount");
        FaultReasonCode.Insert(true);
    end;
}

