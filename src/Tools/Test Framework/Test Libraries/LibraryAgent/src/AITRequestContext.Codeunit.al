namespace System.TestLibraries.Agents;

using System.Agents;

/// <summary>
/// Keeps execution state separate from the parsed query and per-turn result so callers can retain it across turns.
/// The sender uses this context to access the agent, carry forward the updated task, and resolve resources
/// without adding BC-specific parameters to the shared sender interface. Non-BC providers can use an empty
/// context without creating a dummy agent or task. Callers should own a separate instance per evaluation
/// and reset it before reuse to prevent state leaking between evaluations.
/// This codeunit does not create or persist agent tasks.
/// </summary>
codeunit 130566 "AIT Request Context"
{
    Access = Public;
    SingleInstance = false;

    var
        CurrentAgentTask: Record "Agent Task";
        CurrentResourceProvider: Interface IAgentTestResourceProvider;
        AgentUserSecurityId: Guid;
        LoadResources: Boolean;
        ProviderStates: JsonObject;

    procedure SetAgentUserSecurityId(NewAgentUserSecurityId: Guid)
    begin
        AgentUserSecurityId := NewAgentUserSecurityId;
    end;

    procedure GetAgentUserSecurityId(): Guid
    begin
        exit(AgentUserSecurityId);
    end;

    procedure SetAgentTask(AgentTask: Record "Agent Task")
    begin
        CurrentAgentTask := AgentTask;
    end;

    procedure GetAgentTask(var AgentTask: Record "Agent Task")
    begin
        AgentTask := CurrentAgentTask;
    end;

    procedure SetResourceProvider(ResourceProvider: Interface IAgentTestResourceProvider)
    begin
        CurrentResourceProvider := ResourceProvider;
        LoadResources := true;
    end;

    procedure GetResourceProvider(): Interface IAgentTestResourceProvider
    var
        NoOpResourceProvider: Codeunit "NoOp Agent Test Res. Provider";
    begin
        if not LoadResources then
            exit(NoOpResourceProvider);

        exit(CurrentResourceProvider);
    end;

    procedure GetLoadResources(): Boolean
    begin
        exit(LoadResources);
    end;

    procedure SetProviderState(Provider: Enum "AIT Request Provider"; State: JsonObject)
    var
        ProviderKey: Text;
    begin
        ProviderKey := Format(Provider.AsInteger(), 0, 9);
        if ProviderStates.Contains(ProviderKey) then
            ProviderStates.Replace(ProviderKey, State.Clone())
        else
            ProviderStates.Add(ProviderKey, State.Clone());
    end;

    procedure GetProviderState(Provider: Enum "AIT Request Provider"): JsonObject
    var
        State: JsonToken;
        EmptyState: JsonObject;
    begin
        if ProviderStates.Get(Format(Provider.AsInteger(), 0, 9), State) then
            exit(State.AsObject().Clone().AsObject());
        exit(EmptyState);
    end;

    procedure Reset()
    begin
        Clear(CurrentAgentTask);
        Clear(CurrentResourceProvider);
        Clear(AgentUserSecurityId);
        Clear(ProviderStates);
        LoadResources := false;
    end;
}