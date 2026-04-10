namespace System.Integration.PowerBI;

/// <summary>
/// Persists the user settings for a specific Power BI context (e.g. which visual to display).
/// </summary>
table 6314 "Power BI Context Settings"
{
    Caption = 'Power BI Context Settings';
    ReplicateData = false;
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; UserSID; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; Context; Text[50])
        {
            Caption = 'Context';
            DataClassification = SystemMetadata;
            Description = 'Identifies a specific context (role center part, factbox, ...) where the settings will apply. Different parts in the same main page can have different contexts. The same way, parts in different pages that should behave the same can share the same context.';
        }
        field(10; SelectedElementId; Text[2048])
        {
            Caption = 'Selected Element ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(11; SelectedElementType; Enum "Power BI Element Type")
        {
            Caption = 'Selected Element ID';
            DataClassification = SystemMetadata;
        }
        field(20; LockToSelectedElement; Boolean)
        {
            Caption = 'Lock To Selected Element';
            Description = 'Specifies whether the user is disallowed to change the displayed element (report/dashboard/...) for this context. It will be locked to the Selected Element (or to the first element for the context, if no selected element is specified).';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; UserSID, Context)
        {
            Clustered = true;
        }
    }

    procedure CreateOrUpdateSelectedElement(InputPowerBIDisplayedElement: Record "Power BI Displayed Element")
    begin
        Rec.CreateOrReadForCurrentUser(InputPowerBIDisplayedElement.Context);
        if (Rec.SelectedElementId <> InputPowerBIDisplayedElement.ElementId) or (Rec.SelectedElementType <> InputPowerBIDisplayedElement.ElementType) then begin
            Rec.SelectedElementId := InputPowerBIDisplayedElement.ElementId;
            Rec.SelectedElementType := InputPowerBIDisplayedElement.ElementType;
            Rec.Modify(true);
        end;
    end;

    procedure CreateOrReadForCurrentUser(InputContext: Text[50])
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreateOrReadContextSettings(Rec, InputContext, IsHandled);

        if IsHandled then
            exit;

        if not Rec.Get(UserSecurityId(), InputContext) then begin
            Rec.Init();
            Rec.Context := InputContext;
            Rec.UserSID := UserSecurityID();

            OnCreateOrReadContextSettingsOnBeforeInsert(Rec);

            Rec.Insert(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrReadContextSettingsOnBeforeInsert(var PowerBIContextSettings: Record "Power BI Context Settings")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOrReadContextSettings(var PowerBIContextSettings: Record "Power BI Context Settings"; PageID: Text; var IsHandled: Boolean)
    begin
    end;
}
