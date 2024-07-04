/// <summary>
/// This is temporary table to store the endpoint and secret key for the number series copilot.
/// Should be removed once the number series copilot is fully integrated with the system.
/// Shoulbe replaced with the Azure Key Vault storage.
/// </summary>

namespace Microsoft.Foundation.NoSeries;

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
            DataClassification = CustomerContent;
            Caption = 'Deployment';
        }

        field(4; "Secret Key"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Secret';
        }

        field(5; "Tools Selection Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tools Selection Prompt';
        }

        field(10; "Tool 1 Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Prompt';
        }

        field(11; "Tool 1 Definition"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Definition';
        }

        field(20; "Tool 2 Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Prompt';
        }
        field(21; "Tool 2 Definition"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Definition';
        }
        field(31; "Tool 3 Definition"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 3 Definition';
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
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        NoSeriesCopilotSetup.Get();
        NoSeriesCopilotSetup.TestField(NoSeriesCopilotSetup.Endpoint);
        exit(NoSeriesCopilotSetup.Endpoint);
    end;

    procedure GetDeployment() Deployment: Text[250]
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        NoSeriesCopilotSetup.Get();
        NoSeriesCopilotSetup.TestField(NoSeriesCopilotSetup.Deployment);
        exit(NoSeriesCopilotSetup.Deployment);
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
    procedure GetToolsSelectionPromptFromIsolatedStorage() ToolsSelectionPrompt: Text
    begin
        if not IsNullGuid(Rec."Tools Selection Prompt") then
            if not IsolatedStorage.Get(Rec."Tools Selection Prompt", DataScope::Module, ToolsSelectionPrompt) then;

        exit(ToolsSelectionPrompt);
    end;

    [NonDebuggable]
    procedure SetToolsSelectionPromptToIsolatedStorage(ToolsSelectionPrompt: Text)
    var
        NewToolsSelectionPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tools Selection Prompt") then
            if not IsolatedStorage.Delete(Rec."Tools Selection Prompt", DataScope::Module) then;

        NewToolsSelectionPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewToolsSelectionPromptGuid, ToolsSelectionPrompt, DataScope::Module);

        Rec."Tools Selection Prompt" := NewToolsSelectionPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1PromptFromIsolatedStorage() FunctionsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 Prompt", DataScope::Module, FunctionsPrompt) then;

        exit(FunctionsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool1PromptToIsolatedStorage(FunctionsPrompt: Text)
    var
        NewFunctionsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Prompt", DataScope::Module) then;

        NewFunctionsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewFunctionsPromptGuid, FunctionsPrompt, DataScope::Module);

        Rec."Tool 1 Prompt" := NewFunctionsPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1DefinitionFromIsolatedStorage() FunctionsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Definition") then
            if not IsolatedStorage.Get(Rec."Tool 1 Definition", DataScope::Module, FunctionsPrompt) then;

        exit(FunctionsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool1DefinitionToIsolatedStorage(FunctionsPrompt: Text)
    var
        NewFunctionsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Definition") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Definition", DataScope::Module) then;

        NewFunctionsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewFunctionsPromptGuid, FunctionsPrompt, DataScope::Module);

        Rec."Tool 1 Definition" := NewFunctionsPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2PromptFromIsolatedStorage() FunctionsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 Prompt", DataScope::Module, FunctionsPrompt) then;

        exit(FunctionsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool2PromptToIsolatedStorage(FunctionsPrompt: Text)
    var
        NewFunctionsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Prompt", DataScope::Module) then;

        NewFunctionsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewFunctionsPromptGuid, FunctionsPrompt, DataScope::Module);

        Rec."Tool 2 Prompt" := NewFunctionsPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2DefinitionFromIsolatedStorage() FunctionsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Definition") then
            if not IsolatedStorage.Get(Rec."Tool 2 Definition", DataScope::Module, FunctionsPrompt) then;

        exit(FunctionsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool2DefinitionToIsolatedStorage(FunctionsPrompt: Text)
    var
        NewFunctionsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Definition") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Definition", DataScope::Module) then;

        NewFunctionsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewFunctionsPromptGuid, FunctionsPrompt, DataScope::Module);

        Rec."Tool 2 Definition" := NewFunctionsPromptGuid;
    end;


    [NonDebuggable]
    procedure GetTool3DefinitionFromIsolatedStorage() FunctionsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 3 Definition") then
            if not IsolatedStorage.Get(Rec."Tool 3 Definition", DataScope::Module, FunctionsPrompt) then;

        exit(FunctionsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool3DefinitionToIsolatedStorage(FunctionsPrompt: Text)
    var
        NewFunctionsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 3 Definition") then
            if not IsolatedStorage.Delete(Rec."Tool 3 Definition", DataScope::Module) then;

        NewFunctionsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewFunctionsPromptGuid, FunctionsPrompt, DataScope::Module);

        Rec."Tool 3 Definition" := NewFunctionsPromptGuid;
    end;

    [NonDebuggable]
    procedure ImportFromTextFile(var ImportedText: Text)
    var
        FileName: Text;
        InStr: InStream;
        TextLine: Text;
    begin
        if not UploadIntoStream('', '', 'Text files (*.txt)|*.txt', FileName, InStr) then
            exit;

        InStr.ResetPosition();
        while not InStr.EOS do begin
            InStr.Read(TextLine);
            ImportedText += TextLine;
        end;
    end;
}