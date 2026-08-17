codeunit 122009 "Create New Employee Template"
{
    trigger OnRun()
    var
        EmployeeTempl: Record "Employee Templ.";
        Employee: Record Employee;
    begin
        InsertTemplate(EmployeeTempl, AdminCodeTxt, AdminDescTxt);
        InsertPostingInfo(EmployeeTempl);
        InsertOtherInfo(EmployeeTempl, Employee.Gender::Male);

        InsertTemplate(EmployeeTempl, ItCodeTxt, ItDescTxt);
        InsertPostingInfo(EmployeeTempl);
        InsertOtherInfo(EmployeeTempl, Employee.Gender::Female);
    end;

    var
        AdminCodeTxt: Label 'ADMINISTRATION', MaxLength = 20;
        AdminDescTxt: Label 'Administration staff', MaxLength = 100;
        ItCodeTxt: Label 'IT', MaxLength = 20;
        ItDescTxt: Label 'IT staff', MaxLength = 100;

    local procedure InsertTemplate(var EmployeeTempl: Record "Employee Templ."; Code: Code[20]; Description: Text[100])
    begin
        EmployeeTempl.Init();
        EmployeeTempl.Validate(Code, Code);
        EmployeeTempl.Validate(Description, Description);
        EmployeeTempl.Insert(true);
    end;

    local procedure InsertOtherInfo(var EmployeeTempl: Record "Employee Templ."; Gender: Enum "Employee Gender")
    begin
        EmployeeTempl.Validate(Gender, Gender);
        EmployeeTempl.Modify(true);
    end;

    local procedure InsertPostingInfo(var EmployeeTempl: Record "Employee Templ.")
    var
        EmployeePostingGroup: Record "Employee Posting Group";
        CreateEmployee: Codeunit "Create Employee";
    begin
        if EmployeePostingGroup.IsEmpty() then
            exit;

        EmployeeTempl.Validate("Employee Posting Group", CreateEmployee.EmployeePostingGroupCode());
        EmployeeTempl.Modify(true);
    end;
}