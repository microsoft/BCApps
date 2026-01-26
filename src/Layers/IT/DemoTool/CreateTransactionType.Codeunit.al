codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', 'Vend./acq.a titolo def., fatta ecc. per gli sc.dir.con con.priv.o da par.di que.');
        InsertData('12', 'Scambi diretti con consum. privati o da parte di questi (comp. la vend. a dist.)');
        InsertData('21', 'Restituzione di merci');
        InsertData('22', 'Sostituzione di merci restituite');
        InsertData('23', 'Sostituzione (ad esempio in garanzia) di merci non restituite');
        InsertData('31', 'Mov. da/verso un deposito (esclusi i regimi call-off stock e consig. stock)');
        InsertData('32', 'Sped.in vis. o in prova a fini di vend. (inc.i reg.calloff stock e consig.stock)');
        InsertData('33', 'Leasing finanziario');
        InsertData('34', 'Transazioni che comportano un trasferimento della proprietà senza corrisp. fin.');
        InsertData('41', 'Merci che devono ritornare nello Stato membro iniziale o nel paese esportatore');
        InsertData('42', 'Merci che non devono ritornare nello Stato membro iniziale o nel paese esportat.');
        InsertData('51', 'Merci che ritornano nello Stato membro iniziale o nel paese esportatore');
        InsertData('52', 'Merci che non ritornano nello Stato membro iniziale o nel paese esportatore');
        InsertData('71', 'Imm.in lib.prat.di merci in uno Stato mem.con succ.esport.verso un altro St.mem.');
        InsertData('72', 'Tras. di merci da uno St.membro a un al. St.mem.per sott.le merci al reg.di esp.');
        InsertData('91', 'Locazione, prestito e leasing operativo per un periodo superiore a 24 mesi');
        InsertData('99', 'Altra');
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

