codeunit 117561 "Upd. Service Zone in Customer"
{

    trigger OnRun()
    begin
        Clear(Cust);
        if Cust.Find('-') then
            repeat
                case Cust."No." of
                    '10000':
                        begin
                            // Cust."Service Zone Code" := XM;
                            Cust."Service Zone Code" := XW;
                            Cust.Modify();
                        end;
                    '20000':
                        begin
                            Cust."Service Zone Code" := XN;
                            Cust.Modify();
                        end;
                    '30000':
                        begin
                            // Cust."Service Zone Code" := XN;
                            Cust."Service Zone Code" := XS;
                            Cust.Modify();
                        end;

                    '40000':
                        begin
                            // Cust."Service Zone Code" := XW;
                            Cust."Service Zone Code" := XS;
                            Cust.Modify();
                        end;
                    '50000':
                        begin
                            // Cust."Service Zone Code" := XSE;
                            Cust."Service Zone Code" := XN;
                            Cust.Modify();
                        end;
                    else
                        if Cust."Currency Code" <> '' then begin
                            Cust."Service Zone Code" := XX;
                            Cust.Modify();
                        end;
                end;
            until Cust.Next() = 0;
    end;

    var
        Cust: Record Customer;
        XN: Label 'N';
        XW: Label 'W';
        XX: Label 'X';
        XS: Label 'S';
}

