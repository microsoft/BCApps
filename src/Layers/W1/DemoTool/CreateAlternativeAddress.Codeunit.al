codeunit 101616 "Create Alternative Address"
{

    trigger OnRun()
    begin
        InsertData(XMH, XSTATIONED, X19MortlakeRoad, CreatePostCode.Convert('GB-EH16 8JS'), X441315596051);
        ModifyEmployee(XMH, XSTATIONED, 19950102D, 19950131D);
        InsertData(XEH, XSUMMER, X77LincolnAvenue, 'US-FL 37125', X12383544687);
        ModifyEmployee(XEH, XSUMMER, 19940701D, 19940721D);
    end;

    var
        AlternativeAddress: Record "Alternative Address";
        Employee: Record Employee;
        CreatePostCode: Codeunit "Create Post Code";
        XMH: Label 'MH';
        XSTATIONED: Label 'STATIONED';
        X19MortlakeRoad: Label '19 Mortlake Road';
        X441315596051: Label '+44 131 559 6051';
        XEH: Label 'EH';
        XSUMMER: Label 'SUMMER';
        X77LincolnAvenue: Label '77 Lincoln Avenue';
        X12383544687: Label '+1 238 354 4687';

    procedure InsertData(EmployeeNo: Code[20]; "Code": Code[10]; Address: Text[30]; PostCode: Code[20]; PhoneNo: Text[30])
    var
        EmployeeName: Text[30];
    begin
        Employee.Get(EmployeeNo);
        EmployeeName := Employee."Last Name";
        AlternativeAddress."Employee No." := EmployeeNo;
        AlternativeAddress.Code := Code;
        AlternativeAddress.Name := EmployeeName;
        AlternativeAddress.Address := Address;
        AlternativeAddress."Post Code" := CreatePostCode.FindPostCode(PostCode);
        AlternativeAddress.City := CreatePostCode.FindCity(PostCode);
        AlternativeAddress."Phone No." := PhoneNo;
        AlternativeAddress.Insert();
    end;

    procedure ModifyEmployee(EmployeeNo: Code[20]; "Code": Code[10]; StartDate: Date; EndDate: Date)
    begin
        Employee.Get(EmployeeNo);
        Employee."Alt. Address Code" := Code;
        Employee."Alt. Address Start Date" := StartDate;
        Employee."Alt. Address End Date" := EndDate;
        Employee.Modify();
    end;
}

