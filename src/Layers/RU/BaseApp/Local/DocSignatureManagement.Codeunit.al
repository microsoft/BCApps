#pragma warning disable AA0247
codeunit 12420 "Doc. Signature Management"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must define Employee with type %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DefaultSignSetup: Record "Default Signature Setup";
        DocSign: Record "Document Signature";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You must define %1 in %2 for %3=%4.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure MoveDocSignToPostedDocSign(var FromDocSign: Record "Document Signature"; FromTableID: Integer; FromDocType: Integer; FromDocNo: Code[20]; ToTableID: Integer; ToDocNo: Code[20])
    var
        ToPostedDocSign: Record "Posted Document Signature";
    begin
        FromDocSign.SetRange("Table ID", FromTableID);
        FromDocSign.SetRange("Document Type", FromDocType);
        FromDocSign.SetRange("Document No.", FromDocNo);
        if FromDocSign.FindSet() then
            repeat
                ToPostedDocSign.Init();
                ToPostedDocSign."Table ID" := ToTableID;
                if FromTableID = DATABASE::"FA Document Header" then
                    ToPostedDocSign."Document Type" := FromDocType
                else
                    ToPostedDocSign."Document Type" := 0;
                ToPostedDocSign."Document No." := ToDocNo;
                ToPostedDocSign."Employee Type" := FromDocSign."Employee Type";
                ToPostedDocSign."Employee No." := FromDocSign."Employee No.";
                ToPostedDocSign."Employee Name" := FromDocSign."Employee Name";
                ToPostedDocSign."Employee Job Title" := FromDocSign."Employee Job Title";
                ToPostedDocSign."Employee Org. Unit" := FromDocSign."Employee Org. Unit";
                ToPostedDocSign."Warrant Description" := FromDocSign."Warrant Description";
                ToPostedDocSign."Warrant No." := FromDocSign."Warrant No.";
                ToPostedDocSign."Warrant Date" := FromDocSign."Warrant Date";
                ToPostedDocSign.Insert();
            until FromDocSign.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SetDefaults(TableID: Integer; DocType: Integer; DocNo: Code[20])
    var
        DocSign: Record "Document Signature";
    begin
        DocSign.SetRange("Table ID", TableID);
        DocSign.SetRange("Document Type", DocType);
        DocSign.SetRange("Document No.", DocNo);
        if not DocSign.IsEmpty() then
            exit;
        DefaultSignSetup.SetRange("Table ID", TableID);
        DefaultSignSetup.SetRange("Document Type", DocType);
        if DefaultSignSetup.FindSet() then
            repeat
                DocSign.Init();
                DocSign."Table ID" := DefaultSignSetup."Table ID";
                DocSign."Document Type" := DefaultSignSetup."Document Type";
                DocSign."Document No." := DocNo;
                DocSign."Employee Type" := DefaultSignSetup."Employee Type";
                if DefaultSignSetup."Employee No." <> '' then
                    DocSign.Validate("Employee No.", DefaultSignSetup."Employee No.");
                DocSign."Warrant Description" := DefaultSignSetup."Warrant Description";
                DocSign."Warrant No." := DefaultSignSetup."Warrant No.";
                DocSign."Warrant Date" := DefaultSignSetup."Warrant Date";
                DocSign.Insert();
            until DefaultSignSetup.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetDocSign(var DocSign: Record "Document Signature"; TableID: Integer; DocType: Integer; DocNo: Code[20]; EmpType: Integer; Check: Boolean)
    var
        SignExists: Boolean;
    begin
        DocSign.Init();
        SignExists := DocSign.Get(TableID, DocType, DocNo, EmpType);
        if Check then
            if SignExists and (DocSign."Employee Name" = '') or (not SignExists) then begin
                DocSign."Employee Type" := EmpType;
                if IsMandatory(TableID, DocType, EmpType) then
                    Error(Text000, DocSign."Employee Type");
            end;
    end;

    [Scope('OnPrem')]
    procedure GetPostedDocSign(var PostedDocSign: Record "Posted Document Signature"; TableID: Integer; DocType: Integer; DocNo: Code[20]; EmpType: Integer; Check: Boolean)
    var
        SignExists: Boolean;
    begin
        PostedDocSign.Init();
        SignExists := PostedDocSign.Get(TableID, DocType, DocNo, EmpType);
        if Check and (PostedDocSign."Employee Name" = '') or (not SignExists) then begin
            PostedDocSign."Employee Type" := EmpType;
            if IsMandatory(TableID, DocType, EmpType) then
                Error(Text000, PostedDocSign."Employee Type");
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertDefault(TableID: Integer; DocType: Integer; EmpType: Option Director,Accountant,Cashier,ApprovedBy,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Comm1,Comm2,Comm3,StoredBy; EmpNo: Code[20]; WarrantDesc: Text[30]; WarrantNo: Text[20]; WarrantDate: Date; Mandatory2: Boolean)
    begin
        DefaultSignSetup.Init();
        DefaultSignSetup."Table ID" := TableID;
        DefaultSignSetup."Document Type" := DocType;
        DefaultSignSetup."Employee Type" := EmpType;
        if EmpNo <> '' then
            DefaultSignSetup.Validate("Employee No.", EmpNo);
        DefaultSignSetup."Warrant Description" := WarrantDesc;
        DefaultSignSetup."Warrant No." := WarrantNo;
        DefaultSignSetup."Warrant Date" := WarrantDate;
        DefaultSignSetup.Mandatory := Mandatory2;
        DefaultSignSetup.Insert();
    end;

    [Scope('OnPrem')]
    procedure IsMandatory(TableID: Integer; DocType: Integer; EmpType: Option Director,Accountant,Cashier,ApprovedBy,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Comm1,Comm2,Comm3,StoredBy): Boolean
    begin
        if DefaultSignSetup.Get(TableID, DocType, EmpType) then
            exit(DefaultSignSetup.Mandatory);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure DeleteDocSign(TableID: Integer; DocType: Integer; DocNo: Code[20])
    begin
        DocSign.SetRange("Table ID", TableID);
        DocSign.SetRange("Document Type", DocType);
        DocSign.SetRange("Document No.", DocNo);
        DocSign.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CheckDocSignatures(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20])
    var
        DocumentSignature: Record "Document Signature";
    begin
        DefaultSignSetup.Reset();
        DefaultSignSetup.SetRange("Table ID", TableID);
        DefaultSignSetup.SetRange("Document Type", DocumentType);
        DefaultSignSetup.SetRange(Mandatory, true);
        if DefaultSignSetup.FindSet() then
            repeat
                if not DocumentSignature.Get(TableID, DocumentType, DocumentNo, DefaultSignSetup."Employee Type") or
                   (DocumentSignature."Employee No." = '')
                then
                    Error(
                      Text001,
                      DocumentSignature.FieldCaption("Employee No."),
                      DocumentSignature.TableCaption(),
                      DocumentSignature.FieldCaption("Employee Type"),
                      DefaultSignSetup."Employee Type");
            until DefaultSignSetup.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure DeletePostedDocSign(TableID: Integer; DocNo: Code[20])
    var
        PostedDocSign: Record "Posted Document Signature";
    begin
        PostedDocSign.Reset();
        PostedDocSign.SetRange("Table ID", TableID);
        PostedDocSign.SetRange("Document No.", DocNo);
        PostedDocSign.DeleteAll();
    end;
}

