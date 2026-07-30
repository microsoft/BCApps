// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;
using System.Integration;
using System.Telemetry;
using System.Utilities;

codeunit 6905 "Import Expense User"
{
    Access = Internal;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ProgressWindow: Dialog;
        ImportedCount: Integer;
        UpdatedCount: Integer;
        SkippedCount: Integer;
        CreateEmployees: Boolean;
        EmployeeTemplateCode: Code[20];
        CanImportExpenseUsersQst: Label 'Do you want to import employees of your organization as expense users?';
        CanImportEmployeesQst: Label 'Do you want to add all active employees from this company as expense users?';
        CouldNotAcquireAccessTokenErr: Label 'Could not acquire access token to import expense users.';
        ImportSummaryMsg: Label 'Import completed.\\Imported: %1\Updated: %2\Skipped: %3', Comment = '%1 - Number of imported expense users, %2 - Number of updated expense users, %3 - Number of skipped expense users';
        ImportExpenseUserCountWithTotalLbl: Label 'Importing #1############# #2###### out of #3#######', Comment = '#1############# = Type, #2###### = Number of imported expense users, #3####### = Total number of expense users to import';
        ImportExpenseUserCountWithoutTotalLbl: Label 'Importing #1############# #2######', Comment = '#1############# = Type, #2###### = Number of imported expense users';
        MethodGetTok: Label 'GET', Locked = true;
        GraphURLPathLbl: Label '/v1.0/users?$filter=userType eq ''Member''', Locked = true;
        GraphCountURLPathLbl: Label '/v1.0/users/$count?$filter=userType eq ''Member''', Locked = true;
        BearerLbl: Label 'Bearer %1', Comment = '%1 = Access Token', Locked = true;
        AuthorizationHeaderNameTxt: Label 'Authorization', Locked = true;
        ConsistencyLevelLbl: Label 'ConsistencyLevel', Locked = true;
        ConsistencyLevelValueLbl: Label 'eventual', Locked = true;
        ValueLbl: Label 'value', Locked = true;
        NextLinkLbl: Label '@odata.nextLink', Locked = true;
        HttpErrorLbl: Label 'HTTP error %1 (%2).', Comment = '%1 = HTTP Status Code, %2 = HTTP Reason Phrase', Locked = true;
        NoCreatedMsg: Label 'Number of expense users created: %1', Comment = '%1 = Number of created expense users';
        ContinueToImportManyQst: Label 'You are about to import %1 expense users. Do you want to continue?', Comment = '%1 = Number of created expense users';
        EmployeeTemplateNotSelectedErr: Label 'No employee template was selected. Please select an employee template to create employees for expense users.';
        GraphUnexpectedHostLbl: Label 'Unexpected host: this is not a Graph URL.', Locked = true;
        GraphMissingValueArrayLbl: Label 'Graph response missing expected "value" array.', Locked = true;
        GraphEmployeeCountFailedLbl: Label 'Failed to retrieve employee count from Graph API.', Locked = true;
        GraphCountParseFailedLbl: Label 'Graph $count response could not be parsed as integer.', Locked = true;
        GraphSendingRequestLbl: Label 'Sending graph request for a batch of employees.', Locked = true;
        TelemetryCategoryLbl: Label 'Import expense users', Locked = true;

    procedure AddExistingEmployees(AskFirst: Boolean)
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ConfirmManagement: Codeunit "Confirm Management";
        i: Integer;
    begin
        if AskFirst then
            if not ConfirmManagement.GetResponseOrDefault(CanImportEmployeesQst, true) then
                exit;

        Employee.SetRange(Status, Employee.Status::Active);
        if Employee.FindSet() then
            repeat
                ExpenseUser.SetRange("Employee No.", Employee."No.");
                if ExpenseUser.IsEmpty() then begin
                    ExpenseUser.Init();
                    ExpenseUser."No." := '';
                    ExpenseUser."Employee No." := Employee."No.";
                    ExpenseUser.Name := Employee."First Name" + ' ' + Employee."Last Name";
                    if Employee."Company E-Mail" <> '' then
                        ExpenseUser."E-mail" := Employee."Company E-Mail"
                    else
                        ExpenseUser."E-mail" := Employee."E-Mail";
                    ExpenseUser."Job Title" := Employee."Job Title";
                    ExpenseUser.Insert(true);
                    i += 1;
                end;
            until Employee.Next() = 0;
        Message(NoCreatedMsg, i);
    end;

    procedure ImportExpenseUsers()
    var
        ExpenseGraphClient: Codeunit "Expense OAuth Client";
        AccessToken: SecretText;
    begin
        if not PromptForImport() then
            exit;

        ExpenseGraphClient.GetAccessToken(AccessToken);
        if AccessToken.IsEmpty() then
            Error(CouldNotAcquireAccessTokenErr);

        ImportExpenseUsersFromGraph(AccessToken);
    end;

    local procedure PromptForImport(): Boolean
    var
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        ConfirmManagement: Codeunit "Confirm Management";
        ImportExpenseUserRequest: Page "Import Expense User Request";
    begin
        ExpenseAgentSetup.GetRecordOnce();

        if (not ExpenseAgentSetup."Create Emp. for Expense Users") or
           (not GuiAllowed) or
           (not EmployeeTemplMgt.IsEnabled())
        then
            exit(ConfirmManagement.GetResponseOrDefault(CanImportExpenseUsersQst, true));

        if ImportExpenseUserRequest.RunModal() <> Action::OK then
            exit(false);

        ImportExpenseUserRequest.GetValues(CreateEmployees, EmployeeTemplateCode);

        if CreateEmployees and (EmployeeTemplateCode = '') then
            if EmployeeTemplMgt.TemplatesAreNotEmpty() then
                Error(EmployeeTemplateNotSelectedErr);

        exit(true);
    end;

    local procedure ImportExpenseUsersFromGraph(AccessToken: SecretText)
    var
        NextBatchUrl: Text;
        TotalCount: Integer;
        BatchCount: Integer;
    begin
        TotalCount := GetEmployeesCountFromGraph(AccessToken);
        NextBatchUrl := GetGraphBaseUrl() + GraphURLPathLbl;

        ImportedCount := 0;
        UpdatedCount := 0;
        SkippedCount := 0;
        BatchCount := 0;

        if TotalCount > 1000 then
            if GuiAllowed() then
                if not Confirm(ContinueToImportManyQst, false, TotalCount) then
                    exit;

        OpenImportDialog(0, TotalCount);

        repeat
            NextBatchUrl := ProcessBatch(AccessToken, NextBatchUrl);
            BatchCount += 1;
        until (NextBatchUrl = '') or (BatchCount >= MaxBatchIterations());

        CloseDialog();
        Message(ImportSummaryMsg, ImportedCount, UpdatedCount, SkippedCount);
    end;

    local procedure ProcessBatch(AccessToken: SecretText; CurrentBatchUrl: Text): Text
    var
        EmployeesResponse: JsonObject;
        ValuesToken: JsonToken;
    begin
        if not HasGraphHost(CurrentBatchUrl) then begin
            FeatureTelemetry.LogError('0000UTQ', ExpenseAgentSetup.GetFeatureName(), TelemetryCategoryLbl, GraphUnexpectedHostLbl);
            exit('');
        end;

        EmployeesResponse := GetEmployeesResponseFromGraph(AccessToken, CurrentBatchUrl);

        if not EmployeesResponse.Get(ValueLbl, ValuesToken) then begin
            FeatureTelemetry.LogError('0000UTR', ExpenseAgentSetup.GetFeatureName(), TelemetryCategoryLbl, GraphMissingValueArrayLbl);
            exit(GetNextBatchUrl(EmployeesResponse));
        end;

        ReadOrganizationUsers(ValuesToken.AsArray());
        exit(GetNextBatchUrl(EmployeesResponse));
    end;

    local procedure HasGraphHost(UrlToCheck: Text): Boolean
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        UrlHelper: Codeunit "Url Helper";
        SystemGraphUrl: Text;
    begin
        if WebRequestHelper.IsValidUri(UrlToCheck) then begin
            SystemGraphUrl := UrlHelper.GetGraphUrl();

            if WebRequestHelper.GetHostNameFromUrl(UrlToCheck) = WebRequestHelper.GetHostNameFromUrl(SystemGraphUrl) then
                exit(true);
        end;

        exit(false);
    end;

    local procedure GetNextBatchUrl(GraphResponse: JsonObject) NextBatchUrl: Text
    var
        NextLinkJson: JsonToken;
    begin
        if GraphResponse.Get(NextLinkLbl, NextLinkJson) then
            NextBatchUrl := NextLinkJson.AsValue().AsText();
    end;

    local procedure MaxBatchIterations(): Integer
    begin
        // This is purposely set to a high number just to avoid infinite loops.
        exit(10000);
    end;

    local procedure GetGraphBaseUrl(): Text
    var
        UrlHelper: Codeunit "URL Helper";
    begin
        exit(DelChr(UrlHelper.GetGraphUrl(), '>', '/'));
    end;

    local procedure CreateGraphGetRequest(AccessToken: SecretText; Url: Text; var HttpRequestMessage: HttpRequestMessage)
    var
        Headers: HttpHeaders;
    begin
        HttpRequestMessage.Method := MethodGetTok;
        HttpRequestMessage.SetRequestUri(Url);
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add(AuthorizationHeaderNameTxt, SecretText.SecretStrSubstNo(BearerLbl, AccessToken));
    end;

    local procedure GetEmployeesResponseFromGraph(AccessToken: SecretText; FullGraphUrl: Text) JObject: JsonObject
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
    begin
        FeatureTelemetry.LogUsage('0000UTU', ExpenseAgentSetup.GetFeatureName(), GraphSendingRequestLbl);

        CreateGraphGetRequest(AccessToken, FullGraphUrl, HttpRequestMessage);
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error(HttpErrorLbl, HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        HttpResponseMessage.Content.ReadAs(ResponseText);
        JObject.ReadFrom(ResponseText);
    end;

    local procedure GetEmployeesCountFromGraph(AccessToken: SecretText) TotalCount: Integer
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        ResponseText: Text;
    begin
        CreateGraphGetRequest(AccessToken, GetGraphBaseUrl() + GraphCountURLPathLbl, HttpRequestMessage);
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add(ConsistencyLevelLbl, ConsistencyLevelValueLbl);

        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            FeatureTelemetry.LogError('0000UTS', ExpenseAgentSetup.GetFeatureName(), TelemetryCategoryLbl, GraphEmployeeCountFailedLbl);
            exit(0);
        end;

        HttpResponseMessage.Content.ReadAs(ResponseText);
        if not Evaluate(TotalCount, ResponseText) then begin
            FeatureTelemetry.LogError('0000UTT', ExpenseAgentSetup.GetFeatureName(), TelemetryCategoryLbl, GraphCountParseFailedLbl);
            exit(0);
        end;
    end;

    local procedure ReadOrganizationUsers(ValuesArray: JsonArray)
    var
        JToken: JsonToken;
    begin
        foreach JToken in ValuesArray do begin
            ReadOrganizationUser(JToken.AsObject());
            UpdateImportCountDialog(ImportedCount + UpdatedCount + SkippedCount);
        end;
    end;

    local procedure ReadOrganizationUser(UserObject: JsonObject)
    var
        ExpenseUser: Record "Expense User";
        UserToken: JsonToken;
        property: Text;
    begin
        ExpenseUser := GetExpenseUser(UserObject);

        if ExpenseUser."Employee No." <> '' then begin
            SkippedCount += 1;
            exit;
        end;

        foreach property in UserObject.Keys do
            case property of
                'displayName':
                    begin
                        UserObject.Get(property, UserToken);
                        if not (UserToken.AsValue().IsNull()) then
                            ExpenseUser.Name := CopyStr(UserToken.AsValue().AsText(), 1, MaxStrLen(ExpenseUser.Name));
                    end;
                'mail':
                    begin
                        UserObject.Get(property, UserToken);
                        if not (UserToken.AsValue().IsNull()) then
                            ExpenseUser."E-mail" := CopyStr(UserToken.AsValue().AsText(), 1, MaxStrLen(ExpenseUser."E-mail"));
                    end;
            end;

        UpdateExpenseUser(ExpenseUser);
    end;

    local procedure UpdateExpenseUser(var ExpenseUser: Record "Expense User")
    var
        EmployeeNo: Code[20];
    begin
        if ExpenseUser."E-mail" <> '' then begin
            EmployeeNo := GetEmployeeNoFromEmail(ExpenseUser."E-mail");
            if EmployeeNo <> '' then
                ExpenseUser.Validate("Employee No.", EmployeeNo);
        end;

        CreateEmployee(ExpenseUser);

        if ExpenseUser."Can Approve" then
            ExpenseUser.UpdateApprovalUserId();

        if ExpenseUser."No." = '' then begin
            ExpenseUser.Insert(true);
            ImportedCount += 1;
        end else begin
            ExpenseUser.Modify(true);
            UpdatedCount += 1;
        end;
    end;

    local procedure GetExpenseUser(UserObject: JsonObject): Record "Expense User"
    var
        ExpenseUser: Record "Expense User";
        UserToken: JsonToken;
        Id: Guid;
    begin
        UserObject.Get('id', UserToken);
        Id := UserToken.AsValue().AsText();

        ExpenseUser.SetRange("Entra Id", Id);
        if ExpenseUser.FindFirst() then
            exit(ExpenseUser);

        ExpenseUser.Init();
        ExpenseUser."Entra Id" := Id;
        exit(ExpenseUser);
    end;

    internal procedure GetEmployeeNoFromEmail(EmailId: Text[80]): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee.SetRange("Company E-Mail", EmailId);
        if Employee.FindFirst() then
            exit(Employee."No.");
    end;

    local procedure CreateEmployee(var ExpenseUser: Record "Expense User")
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not CreateEmployees then
            exit;

        if ExpenseUser."Employee No." <> '' then
            exit;

        if ExpenseUser."Name" = '' then
            exit;

        if ExpenseUser."E-mail" = '' then
            exit;

        ExpenseUser.SetSkipOverwriteFromEmployee(true);

        if EmployeeTemplateCode <> '' then begin
            EmployeeTempl.Get(EmployeeTemplateCode);
            ExpenseUser.Validate("Employee No.", ExpenseUser.CreateEmployee(EmployeeTempl, true));
        end else
            ExpenseUser.Validate("Employee No.", ExpenseUser.CreateEmployee(EmployeeTempl, false));

        ExpenseUser.SetSkipOverwriteFromEmployee(false);
    end;

    local procedure OpenImportDialog(CurrentExpenseUserCount: Integer; MaximumExpenseUsers: Integer)
    var
        ExpenseUser: Record "Expense User";
        TypeLabel: Text;
    begin
        if not GuiAllowed() then
            exit;

        TypeLabel := ExpenseUser.TableCaption();

        if MaximumExpenseUsers = 0 then
            ProgressWindow.Open(ImportExpenseUserCountWithoutTotalLbl, TypeLabel, CurrentExpenseUserCount)
        else
            ProgressWindow.Open(ImportExpenseUserCountWithTotalLbl, TypeLabel, CurrentExpenseUserCount, MaximumExpenseUsers);
    end;

    local procedure UpdateImportCountDialog(CurrentExpenseUserCount: Integer)
    begin
        if not GuiAllowed() then
            exit;

        ProgressWindow.Update(2, CurrentExpenseUserCount);
    end;

    local procedure CloseDialog()
    begin
        if not GuiAllowed() then
            exit;

        ProgressWindow.Close();
    end;
}