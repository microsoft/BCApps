
codeunit 101227 "Create TCS NOC"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('A', XA, false);
        InsertData('B', XB, false);
        InsertData('C', XC, false);
        InsertData('D', XD, false);
        InsertData('E', XE, false);
        InsertData('F', XF, false);
        InsertData('G', XG, false);
        InsertData('H', XH, false);
        InsertData('I', XI, false);
        InsertData('L', XL, false);
        InsertData('M', XM, false);
        InsertData('1H', X1H, true);

        CreateTCSPostingSetup('A', DMY2Date(1, 1, 2010), '5971');
        CreateTCSPostingSetup('B', DMY2Date(1, 1, 2010), '5972');
        CreateTCSPostingSetup('C', DMY2Date(1, 1, 2010), '5973');
        CreateTCSPostingSetup('D', DMY2Date(1, 1, 2010), '5974');
        CreateTCSPostingSetup('E', DMY2Date(1, 1, 2010), '5975');
        CreateTCSPostingSetup('F', DMY2Date(1, 1, 2010), '5976');
        CreateTCSPostingSetup('G', DMY2Date(1, 1, 2010), '5977');
        CreateTCSPostingSetup('H', DMY2Date(1, 1, 2010), '5978');
        CreateTCSPostingSetup('I', DMY2Date(1, 1, 2010), '5979');
        CreateTCSPostingSetup('1H', DMY2Date(1, 10, 2020), '5978');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XA: Label 'Alcoholic liquor for human consumption';
        XB: Label 'Timber obtained under a forest lease';
        XC: Label 'Timber obtained under any mode other than forest lease';
        XD: Label 'Any other forest product not being timber or tendu leave';
        XE: Label 'Scrap';
        XF: Label 'Parking Lot';
        XG: Label 'Toll Plaza';
        XH: Label 'Mining and Quarrying';
        XI: Label 'Tendu leaves';
        XL: Label 'Sale of Motor vehicle';
        XM: Label 'Sale in cash of any goods (other than bullion/jewelry)';
        X1H: Label 'U/S 206 - 1H';

    procedure InsertMiniAppData()
    begin
        AddTCSNOCForMini();
    end;

    local procedure AddTCSNOCForMini()
    begin
        DemoDataSetup.Get();
        InsertData('A', XA, false);
        InsertData('B', XB, false);
        InsertData('C', XC, false);
        InsertData('D', XD, false);
        InsertData('E', XE, false);
        InsertData('F', XF, false);
        InsertData('G', XG, false);
        InsertData('H', XH, false);
        InsertData('I', XI, false);
        InsertData('L', XL, false);
        InsertData('M', XM, false);
        InsertData('1H', X1H, true);

        CreateTCSPostingSetup('A', DMY2Date(1, 4, 2019), '5971');
        CreateTCSPostingSetup('B', DMY2Date(1, 4, 2019), '5972');
        CreateTCSPostingSetup('C', DMY2Date(1, 4, 2019), '5973');
        CreateTCSPostingSetup('D', DMY2Date(1, 4, 2019), '5974');
        CreateTCSPostingSetup('E', DMY2Date(1, 4, 2019), '5975');
        CreateTCSPostingSetup('F', DMY2Date(1, 4, 2019), '5976');
        CreateTCSPostingSetup('G', DMY2Date(1, 4, 2019), '5977');
        CreateTCSPostingSetup('H', DMY2Date(1, 4, 2019), '5978');
        CreateTCSPostingSetup('I', DMY2Date(1, 4, 2019), '5979');
        CreateTCSPostingSetup('1H', DMY2Date(1, 10, 2020), '5978');
    end;

    procedure InsertData(Code: Code[20]; Description: Text[100]; TCSOnReceipt: Boolean)
    var
        TCSNOC: Record "TCS Nature Of Collection";
    begin
        TCSNOC.Init();
        TCSNOC.Validate("Code", Code);
        TCSNOC.Validate(Description, copystr(Description, 1, 30));
        TCSNOC.Validate("TCS On Recpt. Of Pmt.", TCSOnReceipt);
        TCSNOC.Insert();
    end;

    local procedure CreateTCSPostingSetup(NOC: Code[20]; EffectiveDate: Date; TCSAccount: Code[20])
    var
        TCSPostingSetup: Record "TCS Posting Setup";
    begin
        TCSPostingSetup.Init();
        TCSPostingSetup.Validate("TCS Nature of Collection", NOC);
        TCSPostingSetup.Validate("Effective Date", EffectiveDate);
        TCSPostingSetup."TCS Account No." := TCSAccount;
        TCSPostingSetup.Insert();
    end;

    procedure CreateAllowedTCSNOC(
      CustomerCode: Code[20];
      NOC: Code[20];
      Default: Boolean;
      ThresholdOverlook: Boolean;
      SurchargeOverlook: Boolean)
    var
        AllowedNOC: Record "Allowed NOC";
    begin
        AllowedNOC.Init();
        AllowedNOC."Customer No." := CustomerCode;
        AllowedNOC."TCS Nature of Collection" := NOC;
        AllowedNOC."Default NOC" := Default;
        AllowedNOC."Threshold Overlook" := ThresholdOverlook;
        AllowedNOC."Surcharge Overlook" := SurchargeOverlook;
        AllowedNOC.Insert();
    end;

    procedure CreateTCSCustomerConcessionalCode(
     CustomerCode: Code[20];
     NOC: Code[20];
     ConcessionalCode: Code[20];
     CertificateNo: Code[20])
    var
        CustomerConcenssionalCode: Record "Customer Concessional Code";
    begin
        CustomerConcenssionalCode.Init();
        CustomerConcenssionalCode."Customer No." := CustomerCode;
        CustomerConcenssionalCode."TCS Nature of Collection" := NOC;
        CustomerConcenssionalCode."Concessional Code" := ConcessionalCode;
        CustomerConcenssionalCode."Concessional Form No." := CertificateNo;
        CustomerConcenssionalCode.Insert();
    end;
}