namespace System.AI;

using System.Security.Encryption;
using System.Utilities;

table 2020 "Image Analysis Setup"
{
    Caption = 'Image Analysis Setup';
    DataPerCompany = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(4; "Api Uri"; Text[250])
        {
            Caption = 'Api Uri';

            trigger OnValidate()
            begin
                ValidateApiUri();
            end;
        }
        field(5; "Api Key Key"; Guid)
        {
            Caption = 'Api Key Key';
            ExtendedDatatype = Masked;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

        TooManyCallsErr: Label 'Sorry, you''ll have to wait until the start of the next %2. You can analyze %1 images per %2, and you''ve already hit the limit.', Comment = '%1 is the number of calls per time unit allowed, %2 is the time unit duration (year, month, day, or hour)';
        InvalidApiUriErr: Label 'The Api Uri must be a valid Uri for Cognitive Services.';
        DoYouWantURICorrectedQst: Label 'The API URI must end with "/analyze." Should we add that for you?';

    [Scope('OnPrem')]
    procedure Increment()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
    begin
        GetSingleInstance();
        if (not GetApiKeyAsSecret().IsEmpty()) and ("Api Uri" <> '') then
            exit; // unlimited access for user's own service

        AzureAIUsage.IncrementTotalProcessingTime(AzureAIService::"Computer Vision", 1);
    end;

    procedure IsUsageLimitReached(var UsageLimitError: Text; MaxCallsPerPeriod: Integer; PeriodType: Option Year,Month,Day,Hour): Boolean
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";

    begin
        if (not GetApiKeyAsSecret().IsEmpty()) and ("Api Uri" <> '') then
            exit(false); // unlimited access for user's own service

        if AzureAIUsage.IsLimitReached(AzureAIService::"Computer Vision", MaxCallsPerPeriod) then begin
            UsageLimitError := StrSubstNo(TooManyCallsErr, Format(MaxCallsPerPeriod), LowerCase(Format(PeriodType)));
            exit(true);
        end;

        exit(false);
    end;

    procedure ValidateApiUri()
    var
        Uri: DotNet Uri;
    begin
        if "Api Uri" <> '' then begin
            "Api Uri" := DelChr("Api Uri", '>', ' /');
            // For security reasons we are making sure its a cognitive services URI that is being inserted
            Uri := Uri.Uri("Api Uri");
            if not (Uri.Host.EndsWith('.microsoft.com') or Uri.Host.EndsWith('.azure.com')) or (Uri.Scheme <> 'https') then
                Error(InvalidApiUriErr);
        end;

        if not GuiAllowed then
            exit;
        if StrPos(LowerCase("Api Uri"), '/vision/') = 0 then
            exit;

        // Uri must end in /analyze if it is the default vision URI
        if not EndsInAnalyze("Api Uri") then
            if Confirm(DoYouWantURICorrectedQst) then
                "Api Uri" += '/analyze';
    end;

    local procedure EndsInAnalyze(ApiUri: Text): Boolean
    var
        Regex: Codeunit Regex;
    begin
        exit(Regex.IsMatch(LowerCase(ApiUri), '/analyze$'));
    end;

    [Scope('OnPrem')]
    procedure SetApiKey(ApiKey: SecretText)
    begin
        if IsNullGuid("Api Key Key") then
            "Api Key Key" := CreateGuid();

        IsolatedStorageManagement.Set("Api Key Key", ApiKey, DATASCOPE::Company);
    end;


    [Scope('OnPrem')]
    procedure GetApiKeyAsSecret(): SecretText
    var
        Value: SecretText;
    begin
        IsolatedStorageManagement.Get("Api Key Key", DATASCOPE::Company, Value);
        exit(Value);
    end;

    procedure GetSingleInstance()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}