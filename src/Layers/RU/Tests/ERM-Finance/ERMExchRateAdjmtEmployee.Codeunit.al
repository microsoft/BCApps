#if not CLEAN27
codeunit 134884 "ERM Exch. Rate Adjmt. Employee"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Not used.';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Exchange Rate] [Detailed Ledger Entry] [Purchase]
    end;
}
#endif
