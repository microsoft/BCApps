/// <summary>
/// This is temporary table to store the endpoint and secret key for the number series copilot.
/// Should be removed once the number series copilot is fully integrated with the system.
/// Shoulbe replaced with the Azure Key Vault storage.
/// </summary>
table 9200 "No. Series Copilot Setup"
{
    Description = 'Number Series Copilot Setup';

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';

        }

        field(2; Endpoint; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Endpoint';
        }

        field(3; Deployment; Text[250])
        {
            Caption = 'Deployment';
        }

        field(4; "Secret Key"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Secret';
        }

        field(5; "System Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'System Prompt';
        }
        field(6; "Tools Definition"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tools Definition';
        }

        field(7; "Tool 1 Output Format"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Output Format';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    procedure GetEndpoint() Endpoint: Text[250]
    var
        Rec: Record "No. Series Copilot Setup";
    begin
        Rec.Get();
        Rec.TestField(Rec.Endpoint);
        exit(Rec.Endpoint);
    end;

    procedure GetDeployment() Deployment: Text[250]
    var
        Rec: Record "No. Series Copilot Setup";
    begin
        Rec.Get();
        Rec.TestField(Rec.Deployment);
        exit(Rec.Deployment);
    end;


    [NonDebuggable]
    procedure GetSecretKeyFromIsolatedStorage() SecretKey: Text
    begin
        if not IsNullGuid(Rec."Secret Key") then
            if not IsolatedStorage.Get(Rec."Secret Key", DataScope::Module, SecretKey) then;

        exit(SecretKey);
    end;

    [NonDebuggable]
    procedure SetSecretKeyToIsolatedStorage(SecretKey: Text)
    var
        NewSecretGuid: Guid;
    begin
        if not IsNullGuid(Rec."Secret Key") then
            if not IsolatedStorage.Delete(Rec."Secret Key", DataScope::Module) then;

        NewSecretGuid := CreateGuid();

        IsolatedStorage.Set(NewSecretGuid, SecretKey, DataScope::Module);

        Rec."Secret Key" := NewSecretGuid;
    end;

    [NonDebuggable]
    procedure GetSystemPromptFromIsolatedStorage() SystemPrompt: Text
    begin
        if not IsNullGuid(Rec."System Prompt") then
            if not IsolatedStorage.Get(Rec."System Prompt", DataScope::Module, SystemPrompt) then;

        exit(SystemPrompt);
    end;

    [NonDebuggable]
    procedure SetSystemPromptToIsolatedStorage(SystemPrompt: Text)
    var
        NewSystemPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."System Prompt") then
            if not IsolatedStorage.Delete(Rec."System Prompt", DataScope::Module) then;

        NewSystemPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewSystemPromptGuid, SystemPrompt, DataScope::Module);

        Rec."System Prompt" := NewSystemPromptGuid;
    end;

    [NonDebuggable]
    procedure GetToolsDefinitionFromIsolatedStorage() FunctionsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tools Definition") then
            if not IsolatedStorage.Get(Rec."Tools Definition", DataScope::Module, FunctionsPrompt) then;

        exit(FunctionsPrompt);
    end;

    [NonDebuggable]
    procedure SetToolsDefinitionToIsolatedStorage(FunctionsPrompt: Text)
    var
        NewFunctionsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tools Definition") then
            if not IsolatedStorage.Delete(Rec."Tools Definition", DataScope::Module) then;

        NewFunctionsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewFunctionsPromptGuid, FunctionsPrompt, DataScope::Module);

        Rec."Tools Definition" := NewFunctionsPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1OutputFormatFromIsolatedStorage() Tool1OutputFormat: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Output Format") then
            if not IsolatedStorage.Get(Rec."Tool 1 Output Format", DataScope::Module, Tool1OutputFormat) then;

        exit(Tool1OutputFormat);
    end;

    [NonDebuggable]
    procedure SetTool1OutputFormatToIsolatedStorage(Tool1OutputFormat: Text)
    var
        NewTool1OutputFormatGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Output Format") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Output Format", DataScope::Module) then;

        NewTool1OutputFormatGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1OutputFormatGuid, Tool1OutputFormat, DataScope::Module);

        Rec."Tool 1 Output Format" := NewTool1OutputFormatGuid;
    end;
}