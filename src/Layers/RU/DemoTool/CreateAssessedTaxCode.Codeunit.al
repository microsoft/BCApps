codeunit 163416 "Create Assessed Tax Code"
{

    trigger OnRun()
    begin
        InsertData('0001', XDescription1, '77', 2.2, '', '', 0, '', 0);
        InsertData('0002', XDescription2, '77', 2.1, '2010221', '2010224', 0, '2010231', 0);
        InsertData('0003', XDescription3, '26', 2, '2010231', '2010224', 10, '', 0);
        InsertData('0004', XDescription4, '26', 2, '2010221', '2010224', 100, '', 1);
    end;

    var
        ATCode: Record "Assessed Tax Code";
        XDescription1: Label 'Asset Tax Code No. 1';
        XDescription2: Label 'Asset Tax Code No. 2';
        XDescription3: Label 'Asset Tax Code No. 3';
        XDescription4: Label 'Asset Tax Code No. 4';

    procedure InsertData("Code": Code[20]; Description: Text[30]; "Region Code": Code[2]; "Rate %": Decimal; "Dec. Rate Tax Allowance Code": Code[7]; "Dec. Amount Tax Allowance Code": Code[7]; "Decreasing Amount": Decimal; "Exemption Tax Allowance Code": Code[7]; "Decreasing Amount Type": Option Percent,Amount)
    begin
        ATCode.Init();
        ATCode.Code := Code;
        ATCode.Description := Description;
        ATCode."Region Code" := "Region Code";
        ATCode."Rate %" := "Rate %";
        ATCode.Validate("Dec. Rate Tax Allowance Code", "Dec. Rate Tax Allowance Code");
        ATCode.Validate("Dec. Amount Tax Allowance Code", "Dec. Amount Tax Allowance Code");
        ATCode."Decreasing Amount" := "Decreasing Amount";
        ATCode.Validate("Exemption Tax Allowance Code", "Exemption Tax Allowance Code");
        ATCode."Decreasing Amount Type" := "Decreasing Amount Type";
        ATCode.Insert();
    end;
}

