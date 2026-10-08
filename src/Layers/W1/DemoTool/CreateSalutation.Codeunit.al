codeunit 101568 "Create Salutation"
{

    trigger OnRun()
    begin
        InsertData(XCOMPANY, XCompan);
        InsertData(XF, XFemaleMarriedorUnmarried);
        InsertData(XFMAR, XFemaleMarried);
        InsertData(XFUMAR, XFemaleUnmarried);
        InsertData(XM, XMaleMarriedorUnmarried);
        InsertData(XFJOB, XFemaleJobtitle);
        InsertData(XMJOB, XMaleJobtitle);
        InsertData(XUNISEX, XUnise);
    end;

    var
        Salutation: Record Salutation;
        XCOMPANY: Label 'COMPANY';
        XCompan: Label 'Company';
        XF: Label 'F';
        XFemaleMarriedorUnmarried: Label 'Female Married or Unmarried';
        XFMAR: Label 'F-MAR';
        XFemaleMarried: Label 'Female - Married';
        XFUMAR: Label 'F-UMAR';
        XFemaleUnmarried: Label 'Female - Unmarried';
        XM: Label 'M';
        XMaleMarriedorUnmarried: Label 'Male Married or Unmarried';
        XFJOB: Label 'F-JOB';
        XFemaleJobtitle: Label 'Female - Job title';
        XMJOB: Label 'M-JOB';
        XMaleJobtitle: Label 'Male - Jobtitle';
        XUNISEX: Label 'UNISEX';
        XUnise: Label 'Unisex';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        Salutation.Init();
        Salutation.Validate(Code, Code);
        Salutation.Validate(Description, Description);
        Salutation.Insert();
    end;
}

