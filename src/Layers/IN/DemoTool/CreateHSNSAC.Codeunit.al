codeunit 120549 "Create HSN/SAC"
{
    trigger OnRun()

    begin
        DemoDataSetup.Get();
        InsertData(
            XHSNGroup0988, XHSNCode0988001, XHSNCode0988001, HSNSACType::HSN);
        InsertData(
            XHSNGroup0988, XHSNCode0988002, XHSNCode0988002, HSNSACType::HSN);
        InsertData(
            XHSNGroup0989, XHSNCode0989001, XHSNCode0989001, HSNSACType::HSN);
        InsertData(
            XHSNGroup0989, XHSNCode0989002, XHSNCode0989002, HSNSACType::HSN);
        InsertData(
            XHSNGroup2089, XHSNCode2089001, XHSNCode2089001, HSNSACType::SAC);
        InsertData(
            XHSNGroup2090, XHSNCode2090001, XHSNCode2090001, HSNSACType::SAC);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        HSNSAC: Record "HSN/SAC";
        HSNSACType: Enum "GST Goods And Services Type";
        XHSNGroup0988: Label '0988';
        XHSNGroup0989: Label '0989';
        XHSNGroup2089: Label '2089';
        XHSNGroup2090: Label '2090';
        XHSNCode0988001: Label '0988001';
        XHSNCode0988002: Label '0988002';
        XHSNCode0989001: Label '0989001';
        XHSNCode0989002: Label '0989002';
        XHSNCode2089001: Label '2089001';
        XHSNCode2090001: Label '2090001';


    procedure InsertData(GSTGroupCode: Code[10]; HSNSACCode: code[10]; Descrip: Text[50]; HSType: Enum "GST Goods And Services Type");
    begin
        DemoDataSetup.Get();
        HSNSAC.Init();
        HSNSAC.Validate("GST Group Code", GSTGroupCode);
        HSNSAC.Validate(Code, HSNSACCode);
        HSNSAC.Validate(Description, Descrip);
        HSNSAC.Type := HSType;
        HSNSAC.Insert();
    end;
}
