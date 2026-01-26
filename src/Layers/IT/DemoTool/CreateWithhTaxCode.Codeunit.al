codeunit 161304 "Create Withh. Tax Code"
{

    trigger OnRun()
    begin
        InsertData(XxADMINISTRATORS, '1041', XxB, XAdministratorCompensation, WithholdCode."770 Form"::"770/SC", false, false, '5620');
        InsertData(XxCOLLCOORD, '1041', XxE, XFreeLanceCompensation, WithholdCode."770 Form"::"770/SC",
                   false, false, '5620');
        InsertData(XxOCCAS, '1040', XxR, XOneTimeFreeLanceCompensation, WithholdCode."770 Form"::"770/SC", false, false, '5620');
        InsertData(XxPROFESS, '1040', XxA, XArtistsAndProfCompensation, WithholdCode."770 Form"::"770/SC",
                   false, false, '5620');
        InsertData(XxPROFFINPS, '1040', XxA, XWithHoldTaxForArtistsAndProf, WithholdCode."770 Form"::"770/SC",
                   false, false, '5620');
        InsertData(XSoleAgComm20PERC, '1038', XxA, X20PERCTaxableCommissForSoleAg, WithholdCode."770 Form"::"770/SE",
                   false, false, '5630');
        InsertData(XSoleAgComm50PERC, '1038', XxA, X50PERCTaxableCommissForSoleAg, WithholdCode."770 Form"::"770/SE",
                   false, false, '5630');
        InsertData(XAgentComm20PERC, '1038', XxB, X20PERCTaxableCommissForAg, WithholdCode."770 Form"::"770/SE",
                   false, false, '5630');
        InsertData(XAgentComm50PERC, '1038', XxB, X50PERCTaxableCommissForAg, WithholdCode."770 Form"::"770/SE",
                   false, false, '5630');
    end;

    var
        XxADMINISTRATORS: Label 'ADMINISTRATORS';
        XxB: Label 'B';
        XAdministratorCompensation: Label 'Administrator compensation';
        XxCOLLCOORD: Label 'COLL COORD';
        XxE: Label 'E';
        XFreeLanceCompensation: Label 'Free-Lance compensation';
        XxOCCAS: Label 'OCCAS';
        XxR: Label 'R';
        XOneTimeFreeLanceCompensation: Label 'One-time free-lance compensation';
        XxPROFESS: Label 'PROFESS';
        XxA: Label 'A';
        XArtistsAndProfCompensation: Label 'Artists and professionals compensation';
        XxPROFFINPS: Label 'PROFF INPS';
        XWithHoldTaxForArtistsAndProf: Label 'WithHolding Tax liable for artists and profession.';
        XSoleAgComm20PERC: Label 'SOLE AG. COMM. - 20%';
        X20PERCTaxableCommissForSoleAg: Label '20% Taxable Commissions for sole agents';
        XSoleAgComm50PERC: Label 'SOLE AG. COMM. - 50%';
        X50PERCTaxableCommissForSoleAg: Label '50% Taxable Commissions for sole agents';
        XAgentComm20PERC: Label 'AGENT COMM. - 20%';
        X20PERCTaxableCommissForAg: Label '20% Taxable Commissions for agents';
        XAgentComm50PERC: Label 'AGENT COMM. - 50%';
        X50PERCTaxableCommissForAg: Label '50% Taxable Commissions for agents';
        WithholdCode: Record "Withhold Code";

    procedure InsertData("Code": Code[20]; TaxCode: Text[4]; "770Code": Text[1]; Description: Text[50]; "770Form": Option; SourceWithholdingTax: Boolean; RecipientMayReportIncome: Boolean; WithholdingTaxesPayableAcc: Code[20])
    begin
        WithholdCode.Init();
        WithholdCode.Validate(Code, Code);
        WithholdCode.Validate("Tax Code", TaxCode);
        WithholdCode.Validate("770 Code", "770Code");
        WithholdCode.Validate(Description, Description);
        WithholdCode.Validate("770 Form", "770Form");
        WithholdCode.Validate("Source-Withholding Tax", SourceWithholdingTax);
        WithholdCode.Validate("Recipient May Report Income", RecipientMayReportIncome);
        WithholdCode.Validate("Withholding Taxes Payable Acc.", WithholdingTaxesPayableAcc);
        WithholdCode.Insert();
    end;
}

