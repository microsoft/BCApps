codeunit 101577 "Create Segment Line"
{

    trigger OnRun()
    begin
        InsertData(0, XSM10001, XCUST, '', '', '');
        InsertData(1, XSM10001, '', '010101..', '', '');

        InsertData(0, XSM10002, '', '', XCUSTOMER, '20000');
        InsertData(1, XSM10002, '', '', XCOMPANY, '100000|110000');

        InsertData(0, XSM10003, XPRESS, '', '', '');

        InsertData(0, XSM10004, XCUST, '', '', '');
    end;

    var
        XSM10001: Label 'SM10001';
        XSM10002: Label 'SM10002';
        XSM10003: Label 'SM10003';
        XCUST: Label 'CUST';
        XCUSTOMER: Label 'CUSTOMER';
        XCOMPANY: Label 'COMPANY';
        XPRESS: Label 'PRESS';
        XSM10004: Label 'SM10004';

    procedure InsertData(Functionality: Option Add,Reduce,Refine; SegmentNo: Code[20]; BusinessRelationCode: Code[10]; ValueEntryPostingDateFilter: Text[30]; ProfileQuestionCode: Code[10]; ProfileQuestionCodeLineFilter: Text[30])
    var
        SegmentHeader: Record "Segment Header";
        ContactBusinessRelation: Record "Contact Business Relation";
        ValueEntry: Record "Value Entry";
        ContactProfileAnswer: Record "Contact Profile Answer";
        AddContacts: Report "Add Contacts";
        ReduceContacts: Report "Remove Contacts - Reduce";
        RefineContacts: Report "Remove Contacts - Refine";
    begin
        SegmentHeader.SetRange("No.", SegmentNo);

        ContactBusinessRelation.SetFilter("Business Relation Code", BusinessRelationCode);

        ValueEntry.SetFilter("Posting Date", ValueEntryPostingDateFilter);

        ContactProfileAnswer.SetFilter("Profile Questionnaire Code", ProfileQuestionCode);
        ContactProfileAnswer.SetFilter("Line No.", ProfileQuestionCodeLineFilter);

        case Functionality of
            Functionality::Add:
                begin
                    AddContacts.SetTableView(SegmentHeader);
                    AddContacts.SetTableView(ContactBusinessRelation);
                    AddContacts.SetTableView(ValueEntry);
                    AddContacts.SetTableView(ContactProfileAnswer);
                    AddContacts.UseRequestPage(false);
                    AddContacts.RunModal();
                end;
            Functionality::Reduce:
                begin
                    ReduceContacts.SetTableView(SegmentHeader);
                    ReduceContacts.SetTableView(ContactBusinessRelation);
                    ReduceContacts.SetTableView(ValueEntry);
                    ReduceContacts.SetTableView(ContactProfileAnswer);
                    ReduceContacts.UseRequestPage(false);
                    ReduceContacts.RunModal();
                end;
            Functionality::Refine:
                begin
                    RefineContacts.SetTableView(SegmentHeader);
                    RefineContacts.SetTableView(ContactBusinessRelation);
                    RefineContacts.SetTableView(ValueEntry);
                    RefineContacts.SetTableView(ContactProfileAnswer);
                    RefineContacts.UseRequestPage(false);
                    RefineContacts.RunModal();
                end;
        end;
    end;

    procedure CreateEvaluationData()
    begin
        InsertData(0, XSM10001, XCUST, '', '', '');
        InsertData(1, XSM10001, '', '010101..', '', '');

        InsertData(0, XSM10002, '', '', XCUSTOMER, '20000');
        InsertData(1, XSM10002, '', '', XCOMPANY, '100000|110000');

        InsertData(0, XSM10004, XCUST, '', '', '');
    end;
}

