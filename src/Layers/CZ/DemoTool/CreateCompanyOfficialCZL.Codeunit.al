codeunit 163528 "Create Company Official CZL"
{

    trigger OnRun()
    begin
        InsertData(XOF);
        InsertData(XEH);
        InsertData(XRB);
    end;

    var
        CompanyOfficialCZL: Record "Company Official CZL";
        XEH: Label 'EH';
        XOF: Label 'OF';
        XRB: Label 'RB';

    procedure InsertData(EmployeeNo: Code[20])
    begin
        CompanyOfficialCZL.Init();
        CompanyOfficialCZL."No." := '';
        CompanyOfficialCZL.Validate("Employee No.", EmployeeNo);
        CompanyOfficialCZL.Insert(true);
    end;
}

