codeunit 161501 "Bank Directory"
{

    trigger OnRun()
    var
        NoOfRecsRead: Integer;
        NoOfRecsWritten: Integer;
    begin
        DemoDataSetup.Get();
        BankDirectory.ImportBankDirectoryDirect('localfiles\des_bcbankenstamm.txt', NoOfRecsRead, NoOfRecsWritten);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        BankDirectory: Record "Bank Directory";
}

