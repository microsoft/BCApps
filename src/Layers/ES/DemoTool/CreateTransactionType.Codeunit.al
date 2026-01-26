codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', 'Compra o venta sin restricc., excepto el comercio directo con o por cons. part.');
        InsertData('12', 'Comercio directo con o por consum. partic. (incluida la venta a distancia)');
        InsertData('21', 'Devolución de bienes');
        InsertData('22', 'Sustitución de bienes devueltos');
        InsertData('23', 'Sustitución de bienes no devueltos (por ejemplo, en garantía)');
        InsertData('31', 'Mov. hacia o desde un almacén (excluidas las existencias de reserva y en cons.)');
        InsertData('32', 'Sum. para la venta previa aprob. o prueba (inc. las exist. de reser. y en cons.)');
        InsertData('33', 'Arrendamiento financiero');
        InsertData('34', 'Transacciones que implican transferencia de propiedad sin compensación financ.');
        InsertData('41', 'Bienes destinados a regresar al Estado miembro o país de exportación inicial');
        InsertData('42', 'Bienes no destinados a regresar al Estado miembro o país de exportación inicial');
        InsertData('51', 'Bienes de regreso al Estado miembro o país de exportación inicial');
        InsertData('52', 'Bienes no de regreso al Estado miembro o país de exportación inicial');
        InsertData('71', 'Desp. a libre práct. de bienes en un Est.miem. con post.export. a otro Est.miem.');
        InsertData('72', 'Transp. de bienes de un Est.miembro a otro para ponerlos en régimen de export.');
        InsertData('80', 'Transacc. que impl.el suministro de mat.de cons./eq. técn. en el marco de contr.');
        InsertData('91', 'Alquiler, préstamo y arrendamiento operativo superior a veinticuatro meses');
        InsertData('99', 'Otras');
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

