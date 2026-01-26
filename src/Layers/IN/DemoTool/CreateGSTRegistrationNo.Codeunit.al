codeunit 120551 "Create GST Registration No"
{
    trigger OnRun()

    begin
        DemoDataSetup.Get();
        InsertData(
            XGSTReg1Z1, XDesc1Z1, XStateCode, false);
        InsertData(
            XGSTReg1Z2, XDesc1Z2, XStateCode, false);
        InsertData(
            XGSTReg1Z3, XDesc1Z3, XStateCode, false);
        InsertData(
            XGSTReg1Z4, XDesc1Z4, XStateCode, true);
        InsertData(
            XGSTReg1Z5, XDesc1Z5, XStateCode2, false);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GSTRegNo: Record "GST Registration Nos.";
        XGSTReg1Z1: Label '07COMPA0007I1Z1';
        XDesc1Z1: Label '07COMPA0007I1Z1';
        XGSTReg1Z2: Label '07COMPA0007I1Z2';
        XDesc1Z2: Label '07COMPA0007I1Z2';
        XGSTReg1Z3: Label '07COMPA0007I1Z3';
        XDesc1Z3: Label '07COMPA0007I1Z3';
        XGSTReg1Z4: Label '07COMPA0007I1Z4';
        XDesc1Z4: Label '07COMPA0007I1Z4';
        XStateCode: Label 'DL';
        XGSTReg1Z5: Label '06COMPA0007I1Z1';
        XDesc1Z5: Label '06COMPA0007I1Z1';
        XStateCode2: Label 'HR';

    procedure InsertData("No.": Code[20]; Descrip: Text[50]; StateGSTRegNo: Code[10]; InputServDist: boolean)
    begin
        DemoDataSetup.Get();
        GSTRegNo.Init();
        GSTRegNo.Code := "No.";
        GSTRegNo."State Code" := StateGSTRegNo;
        GSTRegNo.Description := Descrip;
        GSTRegNo."Input Service Distributor" := InputServDist;
        GSTRegNo.Insert();
    end;
}