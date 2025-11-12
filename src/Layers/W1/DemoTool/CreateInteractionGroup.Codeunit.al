codeunit 101563 "Create Interaction Group"
{

    trigger OnRun()
    begin
        InsertData(XLETTER, XLetters);
        InsertData(XMEETING, XMeetings);
        InsertData(XPHONE, XTelephoneconversations);
        InsertData(XSYSTEM, XSystemGeneratedEntries);
        InsertData(XDOC, XDocuments);
        InsertData(XSALES, XSalesDocuments);
        InsertData(XSERVICE, XServiceDocuments);
        InsertData(XPURCHASES, XPurchaseDocuments);
    end;

    var
        "Interaction Group": Record "Interaction Group";
        XLETTER: Label 'LETTER';
        XLetters: Label 'Letters';
        XMEETING: Label 'MEETING';
        XMeetings: Label 'Meetings';
        XPHONE: Label 'PHONE';
        XTelephoneconversations: Label 'Telephone conversations';
        XSYSTEM: Label 'SYSTEM';
        XSystemGeneratedEntries: Label 'System Generated Entries';
        XDOC: Label 'DOC';
        XDocuments: Label 'Documents';
        XSALES: Label 'SALES';
        XSalesDocuments: Label 'Sales Documents';
        XSERVICE: Label 'SERVICE';
        XServiceDocuments: Label 'Service Documents';
        XPURCHASES: Label 'PURCHASES';
        XPurchaseDocuments: Label 'Purchase Documents';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Interaction Group".Init();
        "Interaction Group".Validate(Code, Code);
        "Interaction Group".Validate(Description, Description);
        "Interaction Group".Insert();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(XLETTER, XLetters);
        InsertData(XSYSTEM, XSystemGeneratedEntries);
        InsertData(XMEETING, XMeetings);
        InsertData(XPHONE, XTelephoneconversations);
        InsertData(XSALES, XSalesDocuments);
        InsertData(XPURCHASES, XPurchaseDocuments);
    end;
}

