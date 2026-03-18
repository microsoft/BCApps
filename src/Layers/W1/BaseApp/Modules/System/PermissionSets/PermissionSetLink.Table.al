namespace System.Security.AccessControl;

table 9802 "Permission Set Link"
{
    Caption = 'Permission Set Link';
    DataPerCompany = false;
    Permissions = TableData "Permission Set Link" = rmd;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Permission Set ID"; Code[20])
        {
            Caption = 'Permission Set ID';
            DataClassification = SystemMetadata;
#pragma warning disable AL0432
            TableRelation = "Permission Set"."Role ID";
#pragma warning restore AL0432
        }
        field(2; "Linked Permission Set ID"; Code[20])
        {
            Caption = 'Linked Permission Set ID';
            DataClassification = SystemMetadata;
            TableRelation = "Tenant Permission Set"."Role ID";
        }
        field(3; "Source Hash"; Text[250])
        {
            Caption = 'Source Hash';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Permission Set ID", "Linked Permission Set ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SourceHashHasChanged(): Boolean
    begin
        MarkWithChangedSource();
        exit(not IsEmpty);
    end;

    procedure UpdateSourceHashesOnAllLinks()
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        PermissionManager: Codeunit "Permission Manager";
    begin
        if FindSet() then
            repeat
                MetadataPermissionSet.SetRange("Role ID", Rec."Permission Set ID");
                if MetadataPermissionSet.FindFirst() then begin
                    "Source Hash" := PermissionManager.GenerateHashForPermissionSet(MetadataPermissionSet."Role ID");
                    Modify();
                end else
                    Delete();
            until Next() = 0;
    end;

    procedure MarkWithChangedSource()
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        PermissionManager: Codeunit "Permission Manager";
        SourceChanged: Boolean;
    begin
        if FindSet() then
            repeat
                SourceChanged := false;
                MetadataPermissionSet.SetRange("Role ID", Rec."Permission Set ID");
                if MetadataPermissionSet.FindFirst() then
                    SourceChanged := "Source Hash" <> PermissionManager.GenerateHashForPermissionSet(MetadataPermissionSet."Role ID")
                else
                    SourceChanged := true;
                if SourceChanged then
                    Mark(true);
            until Next() = 0;
        MarkedOnly(true);
    end;

    procedure GetSourceForLinkedPermissionSet(LinkedPermissionSetId: Code[20]): Code[20]
    begin
        SetRange("Linked Permission Set ID", LinkedPermissionSetId);
        if FindFirst() then
            exit("Permission Set ID");
    end;
}

