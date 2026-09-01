codeunit 101343 "Create Dimension Combination"
{

    trigger OnRun()
    begin
        InsertDimCombination(XBUSINESSGROUP, XSALESCAMPAIGN, 0);
        InsertDimValueCombination(XBUSINESSGROUP, XOFFICE, XSALESCAMPAIGN, XWINTER);
        InsertDimValueCombination(XBUSINESSGROUP, XINDUSTRIAL, XSALESCAMPAIGN, XWINTER);
        InsertDimCombination(XCUSTOMERGROUP, XPROJECT, 1);
        InsertDimCombination(XBUSINESSGROUP, XCUSTOMERGROUP, 0);
        InsertDimValueCombination(XBUSINESSGROUP, XHOME, XCUSTOMERGROUP, XINSTITUTION);
    end;

    var
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XOFFICE: Label 'OFFICE';
        XWINTER: Label 'WINTER';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XPROJECT: Label 'PROJECT';
        XHOME: Label 'HOME';
        XINSTITUTION: Label 'INSTITUTION';
        XINDUSTRIAL: Label 'INDUSTRIAL';

    procedure InsertDimCombination("Dimension 1 Code": Code[20]; "Dimension 2 Code": Code[20]; "Combination Restriction": Option)
    var
        "Dimension Combination": Record "Dimension Combination";
    begin
        "Dimension Combination".Init();
        "Dimension Combination".Validate("Dimension 1 Code", "Dimension 1 Code");
        "Dimension Combination".Validate("Dimension 2 Code", "Dimension 2 Code");
        "Dimension Combination".Validate("Combination Restriction", "Combination Restriction");
        "Dimension Combination".Insert();
    end;

    procedure InsertDimValueCombination("Dimension 1 Code": Code[20]; "Dimension 1 Value Code": Code[20]; "Dimension 2 Code": Code[20]; "Dimension 2 Value Code": Code[20])
    var
        "Dimension Value Combination": Record "Dimension Value Combination";
    begin
        "Dimension Value Combination".Init();
        "Dimension Value Combination".Validate("Dimension 1 Code", "Dimension 1 Code");
        "Dimension Value Combination".Validate("Dimension 1 Value Code", "Dimension 1 Value Code");
        "Dimension Value Combination".Validate("Dimension 2 Code", "Dimension 2 Code");
        "Dimension Value Combination".Validate("Dimension 2 Value Code", "Dimension 2 Value Code");
        "Dimension Value Combination".Insert();
    end;
}

