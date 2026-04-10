codeunit 136910 "Report Caption Subscriber"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        ReportCaption: Text;

    procedure SetCaption(NewReportCaption: Text)
    begin
        ReportCaption := NewReportCaption;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Service - Invoice", 'OnBeforeGetDocumentCaption', '', false, false)]
    local procedure OnBeforeGetServiceInvoiceCaption(ServiceInvoiceHeader: Record "Service Invoice Header"; var DocCaption: Text)
    begin
        DocCaption := ReportCaption;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Invoice", 'OnBeforeGetDocumentCaption', '', false, false)]
    local procedure OnBeforeGetStdSalesInvoiceCaption(SalesInvoiceHeader: Record "Sales Invoice Header"; var DocCaption: Text)
    begin
        DocCaption := ReportCaption;
    end;
}

