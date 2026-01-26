codeunit 143000 "Library - AU Localization"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure EnableGSTSetup(EnableGST: Boolean; FullGSTOnPrepayment: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable GST (Australia)", EnableGST);
        GLSetup.Validate("Full GST on Prepayment", FullGSTOnPrepayment);
        GLSetup.Validate("GST Report", EnableGST);
        if EnableGST then
            GLSetup.Validate("Adjustment Mandatory", false);
        GLSetup.Modify(true);
    end;
}

