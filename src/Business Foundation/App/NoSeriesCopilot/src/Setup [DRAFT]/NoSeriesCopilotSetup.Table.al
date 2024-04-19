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

        field(5; "Tools System Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tools System Prompt';
        }

        field(10; "Tool 1 General Instr. Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 General Instructions Prompt';
        }
        field(11; "Tool 1 Limitations Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Limitations Prompt';
        }
        field(12; "Tool 1 Code Guideline Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Series Code Guideline Prompt';
        }

        field(13; "Tool 1 Descr. Guideline Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Series Description Guideline Prompt';
        }

        field(14; "Tool 1 Number Guideline Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Series Numbering Guideline Prompt';
        }
        field(15; "Tool 1 Output Examples Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Output Examples Prompt';
        }

        field(16; "Tool 1 Output Format Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Output Format Prompt';
        }
        field(17; "Tool 1 Custom Patterns Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Custom Patterns Prompt';
        }

        field(19; "Tool 1 Definition"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 1 Definition';
        }

        field(20; "Tool 2 General Instr. Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 General Instructions Prompt';
        }
        field(21; "Tool 2 Limitations Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Limitations Prompt';
        }
        field(22; "Tool 2 Code Guideline Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Series Code Guideline Prompt';
        }
        field(23; "Tool 2 Descr. Guideline Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Series Description Guideline Prompt';
        }
        field(24; "Tool 2 Number Guideline Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Series Numbering Guideline Prompt';
        }
        field(25; "Tool 2 Output Examples Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Output Examples Prompt';
        }
        field(26; "Tool 2 Output Format Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Output Format Prompt';
        }
        field(27; "Tool 2 Custom Patterns Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Custom Patterns Prompt';
        }
        field(29; "Tool 2 Definition"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Tool 2 Definition';
        }

        field(100; "No. Series Gen. System Prompt"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'No. Series Generation System Prompt';
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
    procedure GetNoSeriesGenerationSystemPromptFromIsolatedStorage() NoSeriesGenerationSystemPrompt: Text
    begin
        if not IsNullGuid(Rec."No. Series Gen. System Prompt") then
            if not IsolatedStorage.Get(Rec."No. Series Gen. System Prompt", DataScope::Module, NoSeriesGenerationSystemPrompt) then;

        exit(NoSeriesGenerationSystemPrompt);
    end;

    [NonDebuggable]
    procedure SetNoSeriesGenerationSystemPromptToIsolatedStorage(NoSeriesGenSystemPrompt: Text)
    var
        NewNoSeriesGenSystemPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."No. Series Gen. System Prompt") then
            if not IsolatedStorage.Delete(Rec."No. Series Gen. System Prompt", DataScope::Module) then;

        NewNoSeriesGenSystemPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewNoSeriesGenSystemPromptGuid, NoSeriesGenSystemPrompt, DataScope::Module);

        Rec."No. Series Gen. System Prompt" := NewNoSeriesGenSystemPromptGuid;
    end;

    [NonDebuggable]
    procedure GetToolsSystemPromptFromIsolatedStorage() ToolsSystemPrompt: Text
    begin
        if not IsNullGuid(Rec."Tools System Prompt") then
            if not IsolatedStorage.Get(Rec."Tools System Prompt", DataScope::Module, ToolsSystemPrompt) then;

        exit(ToolsSystemPrompt);
    end;

    [NonDebuggable]
    procedure SetToolsSystemPromptToIsolatedStorage(SystemPrompt: Text)
    var
        NewToolsSystemPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tools System Prompt") then
            if not IsolatedStorage.Delete(Rec."Tools System Prompt", DataScope::Module) then;

        NewToolsSystemPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewToolsSystemPromptGuid, SystemPrompt, DataScope::Module);

        Rec."Tools System Prompt" := NewToolsSystemPromptGuid;
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
    procedure GetTool1GeneralInstructionsPromptFromIsolatedStorage() Tool1GeneralInstrPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 General Instr. Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 General Instr. Prompt", DataScope::Module, Tool1GeneralInstrPrompt) then;

        exit(Tool1GeneralInstrPrompt);
    end;

    [NonDebuggable]
    procedure SetTool1GeneralInstructionsPromptToIsolatedStorage(Tool1GeneralInstrPrompt: Text)
    var
        NewTool1GeneralInstrPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 General Instr. Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 General Instr. Prompt", DataScope::Module) then;

        NewTool1GeneralInstrPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1GeneralInstrPromptGuid, Tool1GeneralInstrPrompt, DataScope::Module);

        Rec."Tool 1 General Instr. Prompt" := NewTool1GeneralInstrPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1LimitationsPromptFromIsolatedStorage() Tool1LimitationsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Limitations Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 Limitations Prompt", DataScope::Module, Tool1LimitationsPrompt) then;

        exit(Tool1LimitationsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool1LimitationsPromptToIsolatedStorage(Tool1LimitationsPrompt: Text)
    var
        NewTool1LimitationsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Limitations Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Limitations Prompt", DataScope::Module) then;

        NewTool1LimitationsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1LimitationsPromptGuid, Tool1LimitationsPrompt, DataScope::Module);

        Rec."Tool 1 Limitations Prompt" := NewTool1LimitationsPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1CodeGuidelinePromptFromIsolatedStorage() Tool1CodeGuidelinePrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Code Guideline Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 Code Guideline Prompt", DataScope::Module, Tool1CodeGuidelinePrompt) then;

        exit(Tool1CodeGuidelinePrompt);
    end;

    [NonDebuggable]
    procedure SetTool1CodeGuidelinePromptToIsolatedStorage(Tool1CodeGuidelinePrompt: Text)
    var
        NewTool1CodeGuidelinePromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Code Guideline Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Code Guideline Prompt", DataScope::Module) then;

        NewTool1CodeGuidelinePromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1CodeGuidelinePromptGuid, Tool1CodeGuidelinePrompt, DataScope::Module);

        Rec."Tool 1 Code Guideline Prompt" := NewTool1CodeGuidelinePromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1DescrGuidelinePromptFromIsolatedStorage() Tool1DescrGuidelinePrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Descr. Guideline Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 Descr. Guideline Prompt", DataScope::Module, Tool1DescrGuidelinePrompt) then;

        exit(Tool1DescrGuidelinePrompt);
    end;

    [NonDebuggable]
    procedure SetTool1DescrGuidelinePromptToIsolatedStorage(Tool1DescrGuidelinePrompt: Text)
    var
        NewTool1DescrGuidelinePromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Descr. Guideline Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Descr. Guideline Prompt", DataScope::Module) then;

        NewTool1DescrGuidelinePromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1DescrGuidelinePromptGuid, Tool1DescrGuidelinePrompt, DataScope::Module);

        Rec."Tool 1 Descr. Guideline Prompt" := NewTool1DescrGuidelinePromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1NumberGuidelinePromptFromIsolatedStorage() Tool1NumberGuidelinePrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Number Guideline Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 Number Guideline Prompt", DataScope::Module, Tool1NumberGuidelinePrompt) then;

        exit(Tool1NumberGuidelinePrompt);
    end;

    [NonDebuggable]
    procedure SetTool1NumberGuidelinePromptToIsolatedStorage(Tool1NumberGuidelinePrompt: Text)
    var
        NewTool1NumberGuidelinePromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Number Guideline Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Number Guideline Prompt", DataScope::Module) then;

        NewTool1NumberGuidelinePromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1NumberGuidelinePromptGuid, Tool1NumberGuidelinePrompt, DataScope::Module);

        Rec."Tool 1 Number Guideline Prompt" := NewTool1NumberGuidelinePromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1OutputExamplesPromptFromIsolatedStorage() Tool1OutputExamplesPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Output Examples Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 Output Examples Prompt", DataScope::Module, Tool1OutputExamplesPrompt) then;

        exit(Tool1OutputExamplesPrompt);
    end;

    [NonDebuggable]
    procedure SetTool1OutputExamplesPromptToIsolatedStorage(Tool1OutputExamplesPrompt: Text)
    var
        NewTool1OutputExamplesPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Output Examples Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Output Examples Prompt", DataScope::Module) then;

        NewTool1OutputExamplesPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1OutputExamplesPromptGuid, Tool1OutputExamplesPrompt, DataScope::Module);

        Rec."Tool 1 Output Examples Prompt" := NewTool1OutputExamplesPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1OutputFormatPromptFromIsolatedStorage() Tool1OutputFormatPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Output Format Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 Output Format Prompt", DataScope::Module, Tool1OutputFormatPrompt) then;

        exit(Tool1OutputFormatPrompt);
    end;

    [NonDebuggable]
    procedure SetTool1OutputFormatPromptToIsolatedStorage(Tool1OutputFormatPrompt: Text)
    var
        NewTool1OutputFormatPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Output Format Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Output Format Prompt", DataScope::Module) then;

        NewTool1OutputFormatPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1OutputFormatPromptGuid, Tool1OutputFormatPrompt, DataScope::Module);

        Rec."Tool 1 Output Format Prompt" := NewTool1OutputFormatPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool1CustomPatternsPromptFromIsolatedStorage() Tool1CustomPatternsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 1 Custom Patterns Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 1 Custom Patterns Prompt", DataScope::Module, Tool1CustomPatternsPrompt) then;

        exit(Tool1CustomPatternsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool1CustomPatternsPromptToIsolatedStorage(Tool1CustomPatternsPrompt: Text)
    var
        NewTool1CustomPatternsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 1 Custom Patterns Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 1 Custom Patterns Prompt", DataScope::Module) then;

        NewTool1CustomPatternsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool1CustomPatternsPromptGuid, Tool1CustomPatternsPrompt, DataScope::Module);

        Rec."Tool 1 Custom Patterns Prompt" := NewTool1CustomPatternsPromptGuid;
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
    procedure GetTool2GeneralInstructionsPromptFromIsolatedStorage() Tool2GeneralInstrPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 General Instr. Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 General Instr. Prompt", DataScope::Module, Tool2GeneralInstrPrompt) then;

        exit(Tool2GeneralInstrPrompt);
    end;

    [NonDebuggable]
    procedure SetTool2GeneralInstructionsPromptToIsolatedStorage(Tool2GeneralInstrPrompt: Text)
    var
        NewTool2GeneralInstrPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 General Instr. Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 General Instr. Prompt", DataScope::Module) then;

        NewTool2GeneralInstrPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool2GeneralInstrPromptGuid, Tool2GeneralInstrPrompt, DataScope::Module);

        Rec."Tool 2 General Instr. Prompt" := NewTool2GeneralInstrPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2LimitationsPromptFromIsolatedStorage() Tool2LimitationsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Limitations Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 Limitations Prompt", DataScope::Module, Tool2LimitationsPrompt) then;

        exit(Tool2LimitationsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool2LimitationsPromptToIsolatedStorage(Tool2LimitationsPrompt: Text)
    var
        NewTool2LimitationsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Limitations Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Limitations Prompt", DataScope::Module) then;

        NewTool2LimitationsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool2LimitationsPromptGuid, Tool2LimitationsPrompt, DataScope::Module);

        Rec."Tool 2 Limitations Prompt" := NewTool2LimitationsPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2CodeGuidelinePromptFromIsolatedStorage() Tool2CodeGuidelinePrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Code Guideline Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 Code Guideline Prompt", DataScope::Module, Tool2CodeGuidelinePrompt) then;

        exit(Tool2CodeGuidelinePrompt);
    end;

    [NonDebuggable]
    procedure SetTool2CodeGuidelinePromptToIsolatedStorage(Tool2CodeGuidelinePrompt: Text)
    var
        NewTool2CodeGuidelinePromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Code Guideline Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Code Guideline Prompt", DataScope::Module) then;

        NewTool2CodeGuidelinePromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool2CodeGuidelinePromptGuid, Tool2CodeGuidelinePrompt, DataScope::Module);

        Rec."Tool 2 Code Guideline Prompt" := NewTool2CodeGuidelinePromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2DescrGuidelinePromptFromIsolatedStorage() Tool2DescrGuidelinePrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Descr. Guideline Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 Descr. Guideline Prompt", DataScope::Module, Tool2DescrGuidelinePrompt) then;

        exit(Tool2DescrGuidelinePrompt);
    end;

    [NonDebuggable]
    procedure SetTool2DescrGuidelinePromptToIsolatedStorage(Tool2DescrGuidelinePrompt: Text)
    var
        NewTool2DescrGuidelinePromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Descr. Guideline Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Descr. Guideline Prompt", DataScope::Module) then;

        NewTool2DescrGuidelinePromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool2DescrGuidelinePromptGuid, Tool2DescrGuidelinePrompt, DataScope::Module);

        Rec."Tool 2 Descr. Guideline Prompt" := NewTool2DescrGuidelinePromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2NumberGuidelinePromptFromIsolatedStorage() Tool2NumberGuidelinePrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Number Guideline Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 Number Guideline Prompt", DataScope::Module, Tool2NumberGuidelinePrompt) then;

        exit(Tool2NumberGuidelinePrompt);
    end;

    [NonDebuggable]
    procedure SetTool2NumberGuidelinePromptToIsolatedStorage(Tool2NumberGuidelinePrompt: Text)
    var
        NewTool2NumberGuidelinePromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Number Guideline Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Number Guideline Prompt", DataScope::Module) then;

        NewTool2NumberGuidelinePromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool2NumberGuidelinePromptGuid, Tool2NumberGuidelinePrompt, DataScope::Module);

        Rec."Tool 2 Number Guideline Prompt" := NewTool2NumberGuidelinePromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2OutputExamplesPromptFromIsolatedStorage() Tool2OutputExamplesPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Output Examples Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 Output Examples Prompt", DataScope::Module, Tool2OutputExamplesPrompt) then;

        exit(Tool2OutputExamplesPrompt);
    end;

    [NonDebuggable]
    procedure SetTool2OutputExamplesPromptToIsolatedStorage(Tool2OutputExamplesPrompt: Text)
    var
        NewTool2OutputExamplesPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Output Examples Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Output Examples Prompt", DataScope::Module) then;

        NewTool2OutputExamplesPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool2OutputExamplesPromptGuid, Tool2OutputExamplesPrompt, DataScope::Module);

        Rec."Tool 2 Output Examples Prompt" := NewTool2OutputExamplesPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2OutputFormatPromptFromIsolatedStorage() Tool2OutputFormatPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Output Format Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 Output Format Prompt", DataScope::Module, Tool2OutputFormatPrompt) then;

        exit(Tool2OutputFormatPrompt);
    end;

    [NonDebuggable]
    procedure SetTool2OutputFormatPromptToIsolatedStorage(Tool2OutputFormatPrompt: Text)
    var
        NewTool2OutputFormatPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Output Format Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Output Format Prompt", DataScope::Module) then;

        NewTool2OutputFormatPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool2OutputFormatPromptGuid, Tool2OutputFormatPrompt, DataScope::Module);

        Rec."Tool 2 Output Format Prompt" := NewTool2OutputFormatPromptGuid;
    end;

    [NonDebuggable]
    procedure GetTool2CustomPatternsPromptFromIsolatedStorage() Tool2CustomPatternsPrompt: Text
    begin
        if not IsNullGuid(Rec."Tool 2 Custom Patterns Prompt") then
            if not IsolatedStorage.Get(Rec."Tool 2 Custom Patterns Prompt", DataScope::Module, Tool2CustomPatternsPrompt) then;

        exit(Tool2CustomPatternsPrompt);
    end;

    [NonDebuggable]
    procedure SetTool2CustomPatternsPromptToIsolatedStorage(Tool2CustomPatternsPrompt: Text)
    var
        NewTool2CustomPatternsPromptGuid: Guid;
    begin
        if not IsNullGuid(Rec."Tool 2 Custom Patterns Prompt") then
            if not IsolatedStorage.Delete(Rec."Tool 2 Custom Patterns Prompt", DataScope::Module) then;

        NewTool2CustomPatternsPromptGuid := CreateGuid();

        IsolatedStorage.Set(NewTool2CustomPatternsPromptGuid, Tool2CustomPatternsPrompt, DataScope::Module);

        Rec."Tool 2 Custom Patterns Prompt" := NewTool2CustomPatternsPromptGuid;
    end;
}