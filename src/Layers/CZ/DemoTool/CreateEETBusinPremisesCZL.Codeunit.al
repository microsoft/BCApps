codeunit 163540 "Create EET Busin. Premises CZL"
{

    trigger OnRun()
    begin
        InsertData(XEETBP, XBusinessPremisesForEET, X181);
    end;

    var
        XEETBP: Label 'EETBP';
        XBusinessPremisesForEET: Label 'Business premises for EET';
        X181: Label '181', Locked = true;
        EETBusinessPremisesCZL: Record "EET Business Premises CZL";

    procedure InsertData("Code": Code[10]; Description: Text[50]; Identification: Code[6])
    begin
        EETBusinessPremisesCZL.Init();
        EETBusinessPremisesCZL.Code := Code;
        EETBusinessPremisesCZL.Description := Description;
        EETBusinessPremisesCZL.Identification := Identification;
        EETBusinessPremisesCZL.Insert();
    end;
}

