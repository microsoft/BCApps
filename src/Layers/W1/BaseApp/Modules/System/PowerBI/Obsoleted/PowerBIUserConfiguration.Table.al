#if not CLEANSCHEMA26 
namespace System.Integration.PowerBI;

/// <summary>
/// Persists the first report to be displayed to a user, depending on the page and profile/role they are using.
/// </summary>
table 6304 "Power BI User Configuration"
{
    Caption = 'Power BI User Configuration';
    ReplicateData = false;
    ObsoleteReason = 'Use table Power BI Context Settings instead. The new table does not require Profile ID, and supports multiple types of embedded elements.';
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Page ID"; Text[50])
        {
            Caption = 'Page ID';
            DataClassification = SystemMetadata;
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(3; "Profile ID"; Code[30])
        {
            Caption = 'Profile ID';
            DataClassification = CustomerContent;
        }
        field(5; "Selected Report ID"; Guid)
        {
            Caption = 'Selected Report ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(10; "Lock to first visual"; Boolean)
        {
            Caption = 'Lock to first visual';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Page ID", "User Security ID", "Profile ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CreateOrReadForCurrentUser(PageId: Text[50])
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        IsHandled: Boolean;
    begin
        OnBeforeCreateOrReadUserConfigEntry(Rec, PageId, IsHandled);
        if IsHandled then
            exit;

        Reset();

        if not Get(PageId, UserSecurityId(), PowerBIServiceMgt.GetEnglishContext()) then begin
            "Page ID" := PageId;
            "User Security ID" := UserSecurityId();
            "Profile ID" := PowerBIServiceMgt.GetEnglishContext();
            OnCreateOrReadUserConfigEntryOnBeforePowerBIUserConfigurationInsert(Rec);
            Insert(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrReadUserConfigEntryOnBeforePowerBIUserConfigurationInsert(var PowerBIUserConfiguration: Record "Power BI User Configuration")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOrReadUserConfigEntry(var PowerBIUserConfiguration: Record "Power BI User Configuration"; PageID: Text; var IsHandled: Boolean)
    begin
    end;
}

#endif