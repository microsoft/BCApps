codeunit 101903 "Localized Create Demo Data"
{

    trigger OnRun()
    begin
    end;

    var
        XDEFAULT: Label 'DEFAULT', Comment = 'Template Name';
        XDefaultDomiciliationJournal: Label 'Default Domiciliation Journal';
        XDOMJNL: Label 'DOMJNL', Comment = 'Source Code';
        XDomiciliationJournal: Label 'Domiciliation Journal';

    procedure CreateDataBeforeActions()
    begin
    end;

    procedure CreateDataAfterActions()
    begin
    end;

    procedure CreateEvaluationData()
    begin
    end;

    procedure CreateExtendedData()
    begin
        CreateDefaultDomiciliationJnl();
    end;

    local procedure CreateDefaultDomiciliationJnl()
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        BankAccount: Record "Bank Account";
        DomJnlTemplate: Record "Domiciliation Journal Template";
    begin
        SourceCode.Init();
        SourceCode.Code := XDOMJNL;
        SourceCode.Description := XDomiciliationJournal;
        SourceCode.Insert();

        SourceCodeSetup.Get();
        SourceCodeSetup."Domiciliation Journal" := SourceCode.Code;
        SourceCodeSetup.Modify();

        BankAccount.FindFirst();
        DomJnlTemplate.Init();
        DomJnlTemplate.Name := XDEFAULT;
        DomJnlTemplate.Description := XDefaultDomiciliationJournal;
        DomJnlTemplate."Page ID" := PAGE::"Domiciliation Journal";
        DomJnlTemplate."Test Report ID" := REPORT::"Domiciliation Journal - Test";
        DomJnlTemplate."Bank Account No." := BankAccount."No.";
        DomJnlTemplate."Source Code" := SourceCode.Code;
        DomJnlTemplate.Insert(true);
    end;
}

