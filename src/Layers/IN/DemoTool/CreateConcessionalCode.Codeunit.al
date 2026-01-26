codeunit 101123 "Create Concessional Code"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();

        InsertData('A', XA);
        InsertData('B', XB);
        InsertData('C', XC);
        InsertData('T', XT);
        InsertData('Y', XY);
        InsertData('S', XS);
        InsertData('Z', XZ);
        InsertData('R', XR);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XA: Label 'Lower/no deduction Sec 197';
        XB: Label 'No deduction Sec 197A';
        XC: Label 'Non-availability of PAN.';
        XT: Label 'Transporter Transaction.';
        XY: Label 'Not exceeded threshold limit.';
        XS: Label 'Software acquired Sec 194J.';
        XZ: Label 'Payment under Sec 197A (1F).';
        XR: Label 'Deduction Sec 194A.';


    procedure InsertMiniAppData()
    begin
        AddCOncessionalCodeForMini();
    end;

    local procedure AddCOncessionalCodeForMini()
    begin
        DemoDataSetup.Get();
        InsertData('A', XA);
        InsertData('B', XB);
        InsertData('C', XC);
        InsertData('T', XT);
        InsertData('Y', XY);
        InsertData('S', XS);
        InsertData('Z', XZ);
        InsertData('R', XR);
    end;

    procedure InsertData(Code: Code[20]; Description: Text[50])
    var
        ConcessionalCode: Record "Concessional Code";
    begin
        ConcessionalCode.Init();
        ConcessionalCode.Validate(Code, Code);
        ConcessionalCode.Validate(Description, Description);
        ConcessionalCode.Insert();
    end;
}