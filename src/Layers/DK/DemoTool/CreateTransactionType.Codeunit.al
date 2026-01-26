codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', 'Almindeligt køb og salg, bortset fra direkte handel med private forbrugere');
        InsertData('12', 'Almindeligt køb og salg, bortset fra direkte handel med private forbrugere');
        InsertData('21', 'Returforsendelse af varer');
        InsertData('22', 'Ombytning af returnerede varer');
        InsertData('23', 'Ombytning af ikke-returnerede varer');
        InsertData('31', 'Flytning af varer til, fra og mellem lagre (bor. fra call-off stock og konsig.)');
        InsertData('32', 'Lev.af varer til salg eft.besig.eller på prøve (inkl. call-off stock og konsig.)');
        InsertData('33', 'Finansiel leasing1');
        InsertData('34', 'Varetr., som indebærer ejerskifte uden fin.mod.(fx nødhjælp eller anden støtte)');
        InsertData('41', 'Varen forventes at returnere til det oprindelige afsendelsesland efter forarbej.');
        InsertData('42', 'Varen forventes ikke at returnere til det oprindelige afsendels.efter forarbej.');
        InsertData('51', 'Varen returnerer til det oprindelige afsendelsesland efter forarbejdning');
        InsertData('52', 'Varen returnerer ikke til det oprindelige afsendelsesland efter forarbejdning');
        InsertData('72', 'Tran.af var.fra en medl.til en anden medl.for at henf.var.und.eksp.i denne medl.');
        InsertData('80', 'Modtagelse/levering af byggemat.og udstyr omfattet af en bygge-og anlægskontrakt');
        InsertData('91', 'Udlejning, lån og operationel leasing med varighed over 24 måneder');
        InsertData('99', 'Transaktioner, som ikke kan klassificeres under andre koder');
    end;

    var
        "Transaction Type": Record "Transaction Type";

    [Scope('OnPrem')]
    procedure InsertData("Code": Code[10]; Description: Text[80])
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, Description);
        "Transaction Type".Insert();
    end;
}

