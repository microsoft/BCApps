codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', 'Vente/achat pur et simple excepté le commerce direct avec/par des consomm.privés');
        InsertData('12', 'Commerce direct avec/par des consomm. privés (y compris la vente à distance)');
        InsertData('21', 'Retour de biens');
        InsertData('22', 'Remplacement de biens retournés');
        InsertData('23', 'Remplacement (par exemple sous garantie) pour des biens non retournés');
        InsertData('31', 'Mouvem. vers/depuis un entrepôt (à l’exc. des rappels et des stocks en consig.)');
        InsertData('32', 'Fourn. pour vente à vue ou après essai (y comp.les rappels et stocks en consig.)');
        InsertData('33', 'Crédit-bail');
        InsertData('34', 'Transactions impliquant le transfert de propriété sans compensation financière');
        InsertData('41', 'Biens supposés retourner dans l’État membre/pays d’exportation initial');
        InsertData('42', 'Biens non* supposés retourner dans l’État membre/pays d’exportation initial');
        InsertData('51', 'Biens retournant dans l’État membre/pays d’exportation initial');
        InsertData('52', 'Biens ne retournant pas dans l’État membre/pays d’exportation initial');
        InsertData('71', 'Mise en libre circ. de biens dans un État membre avec exp. ultér. vers un autre');
        InsertData('72', 'Trans.de biens d’un État mem.vers un au.en vue de pl.les b.sous le rég.de l’exp.');
        InsertData('91', 'Location, prêt et location-achat d’une durée supérieure à 24 mois');
        InsertData('99', 'Autres');
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

