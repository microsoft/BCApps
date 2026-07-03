codeunit 139747 "VAT Group Http Mock Service"
{

    procedure HandleRequest(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage)
    var
        filterValue: Text;
    begin

        if Request.QueryParameters.ContainsKey('$filter') then begin
            filterValue := Request.QueryParameters.Get('$filter');

            if filterValue.Contains('TEST_NO_1') then begin
                Handle('test_1.json', Response, 200);
                exit;
            end;

            if filterValue.Contains('TEST_NO_2') then begin
                Handle('test_2.json', Response, 200);
                exit;
            end;

            if filterValue.Contains('TEST_NO_3') then begin
                Handle('test_3.json', Response, 200);
                exit;
            end;

            if filterValue.Contains('TEST_NO_4') then begin
                Handle('test_3.json', Response, 200);
                exit;
            end;

            if filterValue.Contains('TEST_NO_5') then begin

                if filterValue.Contains('00000000-0000-0000-0000-000000000001') then begin
                    Handle('test_5.json', Response, 200);
                    exit;
                end;

                Handle('test_3.json', Response, 200);
                exit;
            end;

            // Single-status query responses for the MEMBER_CODE_* fixtures used by
            // TestUpdateSingleVATReportStatus and TestButtonUpdateStatusVATReportPage.
            if filterValue.Contains('MEMBER_CODE_1') then begin
                HandleText('{"value": [{"no": "MEMBER_CODE_1","status": "Closed"}]}', Response, 200);
                exit;
            end;

            if filterValue.Contains('MEMBER_CODE_2') then begin
                HandleText('{"value": [{"no": "MEMBER_CODE_2","status": "Accepted"}]}', Response, 200);
                exit;
            end;

            if filterValue.Contains('MEMBER_CODE_3') then begin
                HandleText('{"value": [{"no": "MEMBER_CODE_3","status": "Canceled"}]}', Response, 200);
                exit;
            end;

            if filterValue.Contains('MEMBER_CODE_4') then begin
                HandleText('{"value": [{"no": "MEMBER_CODE_4","status": "Rejected"}]}', Response, 200);
                exit;
            end;

            if filterValue.Contains('MEMBER_CODE_5') then begin
                HandleText('{"value": [{"no": "MEMBER_CODE_5","status": "Rejected"}]}', Response, 200);
                exit;
            end;

            if filterValue.Contains('MEMBER_CODE_6') then begin
                HandleText('{"value": [{"no": "MEMBER_CODE_6","status": "Rejected"}]}', Response, 200);
                exit;
            end;

            if filterValue.Contains('MEMBER_CODE_7') then begin
                HandleText('{"value": []}', Response, 200);
                exit;
            end;

            if filterValue.Contains('MEMBER_CODE_8') then begin
                HandleText('{"value": []}', Response, 200);
                exit;
            end;

            if filterValue.Contains('MEMBER_CODE_9') then begin
                HandleText('{"value": [{"no": "MEMBER_CODE_9","status": "Canceled"}]}', Response, 200);
                exit;
            end;

        end;


        if Request.Path.Contains('wrong') then begin
            Response.HttpStatusCode := 404;
            exit;
        end;

        if Request.Path.Contains('/api/microsoft/vatgroup/v1.0/companies(name=''VAT%20Group%20Repr%20Test%20Company'')/vatGroupSubmissionStatus') then begin
            Handle('status_single_released.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/api/v1.0/companies(name=''VAT%20Group%20Repr%20Test%20Company'')/vatGroupSubmissionStatus') then begin
            Handle('status_single_released.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/OData/Company(''VAT%20Group%20Repr%20Test%20Company'')/vatGroupSubmissionStatus') then begin
            Handle('status_single_released.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/api/v1.0/$batch') then begin
            Handle('status_batch_released.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/api/microsoft/vatgroup/v1.0/$batch') then begin
            Handle('status_batch_released.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/OData/$batch') then begin
            Handle('status_batch_released.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/api/microsoft/vatgroup/v1.0/companies(name=''VAT%20Group%20Repr%20Test%20Company'')/vatGroupSubmissions') then begin
            Handle('200_blanked.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/api/v1.0/companies(name=''VAT%20Group%20Repr%20Test%20Company'')/vatGroupSubmissions') then begin
            Handle('200_blanked.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/OData/Company(''VAT%20Group%20Repr%20Test%20Company'')/vatGroupSubmissions') then begin
            Handle('200_blanked.json', Response, 200);
            exit;
        end;

        if Request.Path.Contains('/api/microsoft/vatgroup/v1.0/companies(name=''GU00000000'')/vatGroupSubmissions') then begin
            Response.HttpStatusCode := 404;
            exit;
        end;

        if Request.Path.Contains('/api/microsoft/vatgroup/v1.0/companies(name=''CRONUS%20International%20Ltd.'')/vatGroupSubmissions') then begin
            Handle('status_single_submitted.json', Response, 200);
            exit;
        end;

        // Default response for unhandled requests
        Response.HttpStatusCode := 404;
    end;


    local procedure Handle(ResourceText: Text; var Response: TestHttpResponseMessage; StatusCode: Integer)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        Response.HttpStatusCode := StatusCode;
    end;

    local procedure HandleText(BodyText: Text; var Response: TestHttpResponseMessage; StatusCode: Integer)
    begin
        Response.Content.WriteFrom(BodyText);
        Response.HttpStatusCode := StatusCode;
    end;

}