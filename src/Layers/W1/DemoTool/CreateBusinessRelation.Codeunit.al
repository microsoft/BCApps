codeunit 101553 "Create Business Relation"
{

    trigger OnRun()
    begin
        InsertData(XACCOUNT, XAccountant);
        InsertData(XATHOR, XAuthorities);
        InsertData(XBANK, XBankAccount);
        InsertData(XCUST, XCustomer);
        InsertData(XJOB, XJobandtempagent);
        InsertData(XLAW, XLawyer);
        InsertData(XPRESS, XPressnewsandmedia);
        InsertData(XPROS, XProspectiveCustomer);
        InsertData(XTRAVEL, XTravelagencies);
        InsertData(XVEND, XVendor);
        InsertData(XEmp, XEmployee);
    end;

    var
        "Business Relation": Record "Business Relation";
        XACCOUNT: Label 'ACCOUNT';
        XAccountant: Label 'Accountant';
        XATHOR: Label 'ATHOR';
        XAuthorities: Label 'Authorities';
        XBANK: Label 'BANK';
        XBankAccount: Label 'Bank Account';
        XCUST: Label 'CUST';
        XCustomer: Label 'Customer';
        XJOB: Label 'JOB';
        XJobandtempagent: Label 'Job and temp agent';
        XLAW: Label 'LAW';
        XLawyer: Label 'Lawyer';
        XPRESS: Label 'PRESS';
        XPressnewsandmedia: Label 'Press, news and media';
        XPROS: Label 'PROS';
        XProspectiveCustomer: Label 'Prospective Customer';
        XTRAVEL: Label 'TRAVEL';
        XTravelagencies: Label 'Travel agencies';
        XVEND: Label 'VEND';
        XVendor: Label 'Vendor';
        XEmp: Label 'EMP';
        XEmployee: Label 'Employee';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Business Relation".Init();
        "Business Relation".Validate(Code, Code);
        "Business Relation".Validate(Description, Description);
        "Business Relation".Insert();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(XBANK, XBankAccount);
        InsertData(XCUST, XCustomer);
        InsertData(XVEND, XVendor);
        InsertData(XEmp, XEmployee);
    end;
}

