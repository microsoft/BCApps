codeunit 161306 "Create Contribution Code"
{

    trigger OnRun()
    begin
        InsertData(XxCONPROV, XWithHoldTaxCompensation10PERC, '5820', '8750', ContributionCode."Contribution Type"::INPS);
        InsertData(XxCPAV, XSocialSecContribForLawyers, '5820', '8750', ContributionCode."Contribution Type"::INPS);
        InsertData(XxNOPROV, XWithHoldTaxCompensation12PERC, '5820', '8750', ContributionCode."Contribution Type"::INPS);
    end;

    var
        XxCONPROV: Label 'CONPROV';
        XWithHoldTaxCompensation10PERC: Label 'WithHolding Tax liable compensation - 10%';
        XxCPAV: Label 'CPAV';
        XSocialSecContribForLawyers: Label 'Social Security Contrib. for Lawyers';
        XxNOPROV: Label 'NOPROV';
        XWithHoldTaxCompensation12PERC: Label 'WithHolding Tax liable compensation - 12%';
        ContributionCode: Record "Contribution Code";

    procedure InsertData("Code": Code[20]; Description: Text[50]; SocialSecurityPayableAcc: Code[20]; SocialSecurityChargesAcc: Code[20]; ContributionType: Option)
    begin
        ContributionCode.Init();
        ContributionCode.Validate(Code, Code);
        ContributionCode.Validate(Description, Description);
        ContributionCode.Validate("Social Security Payable Acc.", SocialSecurityPayableAcc);
        ContributionCode.Validate("Social Security Payable Acc.", SocialSecurityChargesAcc);
        ContributionCode.Validate("Contribution Type", ContributionType);
        ContributionCode.Insert();
    end;
}

