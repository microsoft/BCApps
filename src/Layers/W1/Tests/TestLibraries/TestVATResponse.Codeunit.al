codeunit 132445 "Test VAT Response"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    begin
        Status := Status::Accepted;
        Modify(true);
    end;
}