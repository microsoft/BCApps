codeunit 101603 "Create Relative"
{

    trigger OnRun()
    begin
        InsertData(XWIFE, XWifelc);
        InsertData(XHUSBAND, XHusbandlc);
        InsertData(XCHILD1, XFirstChild);
        InsertData(XCHILD2, XSecondChild);
        InsertData(XCHILD3, XThirdChild);
        InsertData(XMOTHER, XMotherlc);
        InsertData(XFATHER, XFatherlc);
        InsertData(XNEXT, XNextofKin);
    end;

    var
        Relation: Record Relative;
        XWIFE: Label 'WIFE';
        XWifelc: Label 'Wife';
        XHUSBAND: Label 'HUSBAND';
        XHusbandlc: Label 'Husband';
        XCHILD1: Label 'CHILD1';
        XFirstChild: Label 'First Child';
        XCHILD2: Label 'CHILD2';
        XSecondChild: Label 'Second Child';
        XCHILD3: Label 'CHILD3';
        XThirdChild: Label 'Third Child';
        XMOTHER: Label 'MOTHER';
        XMotherlc: Label 'Mother';
        XFATHER: Label 'FATHER';
        XFatherlc: Label 'Father';
        XNEXT: Label 'NEXT';
        XNextofKin: Label 'Next of Kin';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        Relation.Code := Code;
        Relation.Description := Description;
        Relation.Insert();
    end;
}

