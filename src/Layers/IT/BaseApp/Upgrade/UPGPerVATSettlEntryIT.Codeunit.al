#pragma warning disable AA0247
#if not CLEAN27
codeunit 104153 "UPG Per. VAT Settl. Entry IT"
{
    Subtype = Upgrade;
    ObsoleteReason = 'This upgrade is only needed for older versions, new versions will not contain the table to move data from.';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;



}
#endif
