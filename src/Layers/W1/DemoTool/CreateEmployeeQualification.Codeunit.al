codeunit 101602 "Create Employee Qualification"
{

    trigger OnRun()
    begin
        InsertData(
          XEH, XACCOUNTANT, 0D, 0D, EmployeeQualification.Type::External,
          XInternationalTradeGroup);
        InsertData(
          XEH, XFRENCH, 0D, 0D, EmployeeQualification.Type::External,
          XInternationalTradeGroup);

        InsertData(
          XOF, XACCOUNTANT, 0D, 0D, EmployeeQualification.Type::Internal,
          XCronusInternationalLtd);
        InsertData(
          XOF, XPROJECT, 0D, 0D, EmployeeQualification.Type::Internal,
          XCronusInternationalLtd);

        InsertData(
          XLT, XDESIGN, 0D, 0D, EmployeeQualification.Type::External,
          XWorldFamousDesigners);
        InsertData(
          XLT, XINTDESIGN, 0D, 0D, EmployeeQualification.Type::External,
          XWorldFamousDesigners);
        InsertData(
          XLT, XGERMAN, 0D, 0D, EmployeeQualification.Type::External,
          XWorldFamousDesigners);

        InsertData(
          XJO, XINTSALES, 0D, 0D, EmployeeQualification.Type::Internal,
          XCronusInternationalLtd);

        InsertData(
          XRB, XQUALITY, 0D, 0D, EmployeeQualification.Type::Internal,
          XCronusInternationalLtd);
        InsertData(
          XRB, XPROD, 0D, 0D, EmployeeQualification.Type::Internal,
          XCronusInternationalLtd);

        InsertData(
          XMH, XPROD, 0D, 0D, EmployeeQualification.Type::Internal,
          XCronusInternationalLtd);

        InsertData(
          XTD, XPROD, 0D, 0D, EmployeeQualification.Type::Internal,
          XCronusInternationalLtd);
    end;

    var
        EmployeeQualification: Record "Employee Qualification";
        "Line No.": Integer;
        "Old Employee No.": Code[20];
        XEH: Label 'EH';
        XACCOUNTANT: Label 'ACCOUNTANT';
        XInternationalTradeGroup: Label 'International Trade Group';
        XFRENCH: Label 'FRENCH';
        XOF: Label 'OF';
        XCronusInternationalLtd: Label 'Cronus International Ltd.';
        XPROJECT: Label 'PROJECT';
        XLT: Label 'LT';
        XWorldFamousDesigners: Label 'World Famous Designers';
        XDESIGN: Label 'DESIGN';
        XINTDESIGN: Label 'INTDESIGN';
        XGERMAN: Label 'GERMAN';
        XJO: Label 'JO';
        XINTSALES: Label 'INTSALES';
        XRB: Label 'RB';
        XQUALITY: Label 'QUALITY';
        XPROD: Label 'PROD';
        XMH: Label 'MH';
        XTD: Label 'TD';

    procedure InsertData("Employee No.": Code[20]; "Qualification Code": Code[10]; "From Date": Date; "To Date": Date; Type: Option External,Internal; "Institution/Company": Text[30])
    begin
        EmployeeQualification."Employee No." := "Employee No.";
        if "Old Employee No." = "Employee No." then
            "Line No." := "Line No." + 10000
        else
            "Line No." := 10000;
        "Old Employee No." := "Employee No.";
        EmployeeQualification."Line No." := "Line No.";
        EmployeeQualification.Validate("Qualification Code", "Qualification Code");
        EmployeeQualification."From Date" := "From Date";
        EmployeeQualification."To Date" := "To Date";
        EmployeeQualification.Type := Type;
        EmployeeQualification."Institution/Company" := "Institution/Company";
        EmployeeQualification.Insert();
    end;
}

