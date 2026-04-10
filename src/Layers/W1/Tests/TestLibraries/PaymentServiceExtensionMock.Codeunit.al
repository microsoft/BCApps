codeunit 132472 "Payment Service Extension Mock"
{
    EventSubscriberInstance = Manual;
    Subtype = Normal;
    TableNo = "Payment Reporting Argument";

    trigger OnRun()
    begin
        GenerateHyperlink(Rec);
    end;

    var
        TempAccountPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TestServiceTemplateKeyTok: Label 'TESTSERVICE01';
        TestServiceFormatTok: Label 'http://www.testservice.com/test.apsx?%1&%2&%3', Locked = true;
        TestCaptionTxt: Label 'Click To Pay';

    procedure GetCodeunitID(): Integer
    begin
        exit(CODEUNIT::"Payment Service Extension Mock");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Payment Service Setup", 'OnRegisterPaymentServiceProviders', '', false, false)]
    local procedure MockRegisterTemplate(var PaymentServiceSetup: Record "Payment Service Setup")
    var
        CurrentNo: Text[50];
    begin
        PaymentServiceSetup.SetFilter("Management Codeunit ID", '=%1', CODEUNIT::"Payment Service Extension Mock");

        if not TempTemplatePaymentServiceSetup.FindSet() then
            exit;

        CurrentNo := TestServiceTemplateKeyTok;
        repeat
            PaymentServiceSetup.TransferFields(TempTemplatePaymentServiceSetup);
            PaymentServiceSetup."No." := CurrentNo;
            PaymentServiceSetup.Insert(true);
            CurrentNo := IncStr(CurrentNo);
        until TempTemplatePaymentServiceSetup.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Payment Service Setup", 'OnCreatePaymentService', '', false, false)]
    local procedure MockNewAccount(var PaymentServiceSetup: Record "Payment Service Setup")
    var
        Customer: Record Customer;
        LastNo: Text;
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), PaymentServiceSetup.Name, 'Name was not set correctly');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), PaymentServiceSetup.Description, 'Name was not set correctly');
        TempAccountPaymentServiceSetup.Reset();
        LastNo := TestServiceTemplateKeyTok;

        if TempAccountPaymentServiceSetup.FindLast() then
            LastNo := TempAccountPaymentServiceSetup."No.";
        Clear(TempAccountPaymentServiceSetup);

        TempAccountPaymentServiceSetup.TransferFields(PaymentServiceSetup);
        TempAccountPaymentServiceSetup."No." := IncStr(LastNo);
        TempAccountPaymentServiceSetup.Enabled := LibraryVariableStorage.DequeueBoolean();
        LibrarySales.CreateCustomer(Customer);
        TempAccountPaymentServiceSetup."Setup Record ID" := Customer.RecordId;
        TempAccountPaymentServiceSetup."Always Include on Documents" := LibraryVariableStorage.DequeueBoolean();
        TempAccountPaymentServiceSetup.Insert(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Payment Service Setup", 'OnRegisterPaymentServices', '', false, false)]
    local procedure MockRegisterAccount(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
        PaymentServiceSetup.SetFilter("Management Codeunit ID", '=%1', CODEUNIT::"Payment Service Extension Mock");

        TempAccountPaymentServiceSetup.Reset();
        if not TempAccountPaymentServiceSetup.FindSet() then
            exit;

        repeat
            PaymentServiceSetup.TransferFields(TempAccountPaymentServiceSetup);
            PaymentServiceSetup.Insert(true);
        until TempAccountPaymentServiceSetup.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure MockRegisterServiceConnections(var ServiceConnection: Record "Service Connection")
    begin
        if TempAccountPaymentServiceSetup.FindSet() then
            repeat
                if TempAccountPaymentServiceSetup.Enabled then
                    ServiceConnection.Status := ServiceConnection.Status::Enabled
                else
                    ServiceConnection.Status := ServiceConnection.Status::Disabled;

                ServiceConnection.InsertServiceConnection(
                  ServiceConnection, TempAccountPaymentServiceSetup."Setup Record ID", TempAccountPaymentServiceSetup.Description,
                  '', TempAccountPaymentServiceSetup."Setup Page ID");
            until TempAccountPaymentServiceSetup.Next() = 0;
    end;

    procedure AssertQueuesEmpty()
    begin
        LibraryVariableStorage.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    procedure EnqueueForMockEvent(Variable: Variant)
    begin
        LibraryVariableStorage.Enqueue(Variable);
    end;

    procedure SetPaymentServiceAccounts(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        SetPaymentServiceTempTable(TempPaymentServiceSetup, TempAccountPaymentServiceSetup);
    end;

    procedure SetPaymentServiceTemplates(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        SetPaymentServiceTempTable(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
    end;

    procedure GetPaymentServiceTemplates(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        TempPaymentServiceSetup.Copy(TempTemplatePaymentServiceSetup, true);
    end;

    local procedure SetPaymentServiceTempTable(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; var TempBufferPaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        TempBufferPaymentServiceSetup.DeleteAll();
        if not TempPaymentServiceSetup.FindSet() then
            exit;

        repeat
            TempBufferPaymentServiceSetup.TransferFields(TempPaymentServiceSetup);
            TempBufferPaymentServiceSetup.Insert(true);
        until TempPaymentServiceSetup.Next() = 0;

        TempPaymentServiceSetup.FindFirst();
    end;

    procedure EmptyTempPaymentServiceTables()
    begin
        TempAccountPaymentServiceSetup.Reset();
        TempTemplatePaymentServiceSetup.Reset();

        TempAccountPaymentServiceSetup.DeleteAll();
        TempTemplatePaymentServiceSetup.DeleteAll();
    end;

    local procedure GenerateHyperlink(var PaymentReportingArgument: Record "Payment Reporting Argument")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentRecordRef: RecordRef;
        Uri: DotNet Uri;
        TargetURL: Text;
    begin
        DataTypeManagement.GetRecordRef(PaymentReportingArgument."Document Record ID", DocumentRecordRef);

        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocumentRecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.CalcFields("Amount Including VAT");

                    TargetURL := StrSubstNo(TestServiceFormatTok, SalesInvoiceHeader."No.",
                        Format(SalesInvoiceHeader."Amount Including VAT", 0, 9),
                        PaymentReportingArgument.GetCurrencyCode(SalesInvoiceHeader."Currency Code"));

                    PaymentReportingArgument.SetTargetURL(Uri.EscapeUriString(TargetURL));
                    PaymentReportingArgument."URL Caption" := TestCaptionTxt;
                    PaymentReportingArgument.Modify(true);
                end;
        end;
    end;
}

