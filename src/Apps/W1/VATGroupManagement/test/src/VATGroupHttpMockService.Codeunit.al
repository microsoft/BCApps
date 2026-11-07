codeunit 139747 "VAT Group Http Mock Service"
{

    procedure HandleRequest(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage)
    var
        VATReportSetup: Record "VAT Report Setup";
        TypeHelper: Codeunit "Type Helper";
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
        if Request.Path.Contains('/vatGroupSubmissionStatus') then begin
            HandleSubmissionStatusFromData(Request, Response);
            exit;
        end;
        if Request.Path.Contains('/$batch') then begin
            VATReportSetup.Get();
            if VATReportSetup."Group Representative Company" = 'VAT Group Repr Test Company' then
                Handle('status_batch_released.json', Response, 200)
            else
                HandleBatchStatusFromData(Response);
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
        if Request.Path.Contains('/api/microsoft/vatgroup/v1.0/companies(name=''' + TypeHelper.UriEscapeDataString(CompanyName()) + ''')/vatGroupSubmissions') then begin
            HandleSubmissionFromData(Response);
            exit;
        end;

        // Default response for unhandled requests
        Response.HttpStatusCode := 404;
    end;

    local procedure HandleSubmissionStatusFromData(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage)
    var
        TypeHelper: Codeunit "Type Helper";
        FilterValue: Text;
        No: Text;
        MemberId: Guid;
        Position: Integer;
    begin
        if not Request.Path.Contains('''' + TypeHelper.UriEscapeDataString(CompanyName()) + '''') then begin
            Response.HttpStatusCode := 404;
            exit;
        end;

        FilterValue := Request.QueryParameters.Get('$filter');
        Position := StrPos(FilterValue, 'no eq ''') + 7;
        No := CopyStr(FilterValue, Position, StrPos(CopyStr(FilterValue, Position), '''') - 1);
        Position := StrPos(FilterValue, 'groupMemberId eq ') + 17;
        Evaluate(MemberId, CopyStr(FilterValue, Position, 36));

        Response.Content.WriteFrom(GetSubmissionStatusFromData(CopyStr(No, 1, 20), MemberId));
        Response.HttpStatusCode := 200;
    end;

    local procedure HandleSubmissionFromData(var Response: TestHttpResponseMessage)
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        if not VATGroupApprovedMember.Get(VATReportSetup."Group Member ID") then begin
            Response.HttpStatusCode := 400;
            exit;
        end;

        Handle('200_blanked.json', Response, 200);
    end;

    local procedure HandleBatchStatusFromData(var Response: TestHttpResponseMessage)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        ResponsesArray: JsonArray;
        ResponsesJson: JsonObject;
        ResponseItem: JsonObject;
        BodyJson: JsonObject;
        BodyText: Text;
        RequestId: Integer;
    begin
        VATReportSetup.Get();

        VATReportHeader.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::"VAT Return");
        VATReportHeader.SetRange(Status, VATReportHeader.Status::Submitted);
        VATReportHeader.SetRange("VAT Report Version", 'VATGROUP');
        VATReportHeader.SetFilter("VAT Group Status", '%1|%2|%3|%4|%5|%6', '', 'Open', 'Released', 'Submitted', 'Pending', 'Cannot update');
        if VATReportHeader.FindSet() then
            repeat
                RequestId += 1;
                Clear(ResponseItem);
                ResponseItem.Add('id', RequestId);
                if VATReportSetup."Group Representative Company" = CompanyName() then begin
                    ResponseItem.Add('status', 200);
                    BodyJson.ReadFrom(GetSubmissionStatusFromData(VATReportHeader."No.", VATReportSetup."Group Member ID"));
                    ResponseItem.Add('body', BodyJson);
                end else
                    ResponseItem.Add('status', 404);
                ResponsesArray.Add(ResponseItem);
            until VATReportHeader.Next() = 0;

        ResponsesJson.Add('responses', ResponsesArray);
        ResponsesJson.WriteTo(BodyText);
        Response.Content.WriteFrom(BodyText);
        Response.HttpStatusCode := 200;
    end;

    local procedure GetSubmissionStatusFromData(No: Code[20]; MemberId: Guid) BodyText: Text
    var
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATReportHeader: Record "VAT Report Header";
        BodyJson: JsonObject;
        ValuesJsonArray: JsonArray;
        ValueJson: JsonObject;
    begin
        VATGroupSubmissionHeader.SetCurrentKey("Submitted On");
        VATGroupSubmissionHeader.SetRange("No.", No);
        VATGroupSubmissionHeader.SetRange("Group Member ID", MemberId);
        VATGroupSubmissionHeader.Ascending(false);
        if VATGroupSubmissionHeader.FindSet() then
            repeat
                if VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", VATGroupSubmissionHeader."VAT Group Return No.") then begin
                    ValueJson.Add('no', No);
                    ValueJson.Add('status', Format(VATReportHeader.Status));
                    ValuesJsonArray.Add(ValueJson);
                    break;
                end;
            until VATGroupSubmissionHeader.Next() = 0;

        BodyJson.Add('value', ValuesJsonArray);
        BodyJson.WriteTo(BodyText);
    end;

    local procedure Handle(ResourceText: Text; var Response: TestHttpResponseMessage; StatusCode: Integer)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        Response.HttpStatusCode := StatusCode;
    end;

}