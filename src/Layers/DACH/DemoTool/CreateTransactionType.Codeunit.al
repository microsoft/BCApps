codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', 'Endgültiger Verkauf/Kauf, ausg. direkter Handel mit/durch private Verbraucher');
        InsertData('12', 'Direkter Handel mit/durch private(n) Verbraucher(n) (einschließlich Fernverkauf)');
        InsertData('21', 'Rücksendung von Waren');
        InsertData('22', 'Ersatz für zurückgesandte Waren');
        InsertData('23', 'Ersatz (z.B. wegen Garantie) für nicht zurückgesandte Waren');
        InsertData('31', 'Beförderun. in/aus ein(em) Lager (ausg. Auslieferungs- und Konsig., sowie Komm.)');
        InsertData('32', 'Ansichts- oder Probesendungen (einsch. Auslieferungs- und Konsig., sowie Komm.)');
        InsertData('33', 'Finanzierungsleasing (Mietkauf)');
        InsertData('34', 'Geschäfte mit Eigentumsübertragung ohne finanz. Gegenleistung, einsch. Tausch.');
        InsertData('41', 'Waren, die voraussichtlich in das ursprüngliche Ausfuhrland zurückgelangen');
        InsertData('42', 'Waren, die voraussichtlich nicht in das ursprüngliche Ausfuhrland zurückgelangen');
        InsertData('51', 'Waren, die in das ursprüngliche Ausfuhrland zurückgelangen');
        InsertData('52', 'Waren, die nicht in das ursprüngliche Ausfuhrland zurückgelangen');
        InsertData('67', 'Warensendung zur oder nach Reparatur');
        InsertData('68', 'Zolllagerverkehr für ausländische Rechnung');
        InsertData('69', 'Sonstige vorüb. Warenv. bis ein. 24 Mon. und and. von der stat. Anm. Bef. Waren');
        InsertData('71', 'Über.von Waren in den zoll.frei.Verk.in ein.Mitg.mit ansch.Ausf.in ein.and.Mitg.');
        InsertData('72', 'Verb.von Waren aus einem Mitg.in einen and.Mitg.zur Über.der Waren in das Ausf.');
        InsertData('81', 'Gesch.mit Lief.von Baumat.und tech.Ausr.im Rahmen von Hoch-oder Tiefbau-arbeiten');
        InsertData('91', 'Miete, Leihe und Operate Leasing über mehr als 24 Monate');
        InsertData('99', 'Sonstige Warenverkehre, nicht anderweitig erfasst');
    end;

    var
        "Transaction Type": Record "Transaction Type";

    procedure InsertData("Code": Code[10]; Description: Text[80])
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, Description);
        "Transaction Type".Insert();
    end;
}

