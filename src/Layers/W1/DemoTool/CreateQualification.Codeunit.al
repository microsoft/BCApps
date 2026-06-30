codeunit 101601 "Create Qualification"
{

    trigger OnRun()
    begin
        InsertData(XDESIGN, XDesigner);
        InsertData(XINTDESIGN, XInteriorDesigner);
        InsertData(XPROJECT, XProjectManager);
        InsertData(XQUALITY, XQualityManager);
        InsertData(XACCOUNTANT, XAccountantlc);
        InsertData(XINTSALES, XInternationalSales);
        InsertData(XPROD, XProductionManager);
        InsertData(XFRENCH, XFluentinFrench);
        InsertData(XGERMAN, XFluentinGerman);
    end;

    var
        Qualification: Record Qualification;
        XDESIGN: Label 'DESIGN';
        XDesigner: Label 'Designer';
        XINTDESIGN: Label 'INTDESIGN';
        XInteriorDesigner: Label 'Interior Designer';
        XPROJECT: Label 'PROJECT';
        XProjectManager: Label 'Project Manager';
        XQUALITY: Label 'QUALITY';
        XQualityManager: Label 'Quality Manager';
        XACCOUNTANT: Label 'ACCOUNTANT';
        XAccountantlc: Label 'Accountant';
        XINTSALES: Label 'INTSALES';
        XInternationalSales: Label 'International Sales';
        XPROD: Label 'PROD';
        XProductionManager: Label 'Production Manager';
        XFRENCH: Label 'FRENCH';
        XFluentinFrench: Label 'Fluent in French';
        XGERMAN: Label 'GERMAN';
        XFluentinGerman: Label 'Fluent in German';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        Qualification.Code := Code;
        Qualification.Description := Description;
        Qualification.Insert();
    end;
}

