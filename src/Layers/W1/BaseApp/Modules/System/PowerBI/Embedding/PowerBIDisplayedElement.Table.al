namespace System.Integration.PowerBI;

/// <summary>
/// Saves a list of reports to be displayed for a user in each specific context.
/// </summary>
table 6312 "Power BI Displayed Element"
{
    Caption = 'Power BI Displayed Element';
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
            Description = 'Identifies a specific context (role center part, factbox, ...) where the selected elements will be displayed. Different parts in the same main page can have different contexts. The same way, parts in different pages that should show the same elements can share the same context.';
            DataClassification = CustomerContent;
        }
        field(3; ElementId; Text[2048])
        {
            Caption = 'Element ID';
            DataClassification = CustomerContent;
        }
        field(4; ElementType; Enum "Power BI Element Type")
        {
            Caption = 'Element Type';
            DataClassification = SystemMetadata;
        }
        field(10; ElementName; Text[200])
        {
            Caption = 'Element Name';
            DataClassification = CustomerContent;
        }
        field(11; ElementEmbedUrl; Text[2048])
        {
            Caption = 'Element Embed Url';
            DataClassification = CustomerContent;
        }
        field(20; WorkspaceID; Guid)
        {
            Caption = 'Workspace ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(21; WorkspaceName; Text[200])
        {
            Caption = 'Workspace Display Name';
            DataClassification = CustomerContent;
        }
        field(50; ReportPage; Text[200])
        {
            Caption = 'Report Page';
            Description = 'If this element is a report, specifies the name of the report page to show when the report is loaded.';
            DataClassification = CustomerContent;
        }
        field(51; ShowPanesInNormalMode; Boolean)
        {
            Caption = 'Show Panes in Normal Mode';
            Description = 'Specifies if the additional panes (such as the pane that allows changing report pages) are shown in the CardPart page that displays Power BI elements.';
            DataClassification = SystemMetadata;
        }
        field(52; ShowPanesInExpandedMode; Boolean)
        {
            Caption = 'Show Panes in Expanded Mode';
            Description = 'Specifies if the additional panes (such as the pane that allows changing report pages, or setting report filters) are shown in the Card page that displays expanded Power BI elements.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; UserSID, Context, ElementId, ElementType)
        {
            Clustered = true;
        }
    }

    var
        ReportVisualKeyTok: Label '%1|%2|%3', Locked = true, Comment = '%1=Report ID; %2=Page name; %3=Visual name';
        DashboardTileKeyTok: Label '%1|%2', Locked = true, Comment = '%1=Dashboard ID; %2=Dashboard tile ID';
        EmptyReportIdErr: Label 'The Power BI report ID cannot be empty.';
        EmptyPageOrVisualErr: Label 'The Power BI page name and visual name cannot be empty.';
        EmptyDashboardIdErr: Label 'The Power BI dashboard ID cannot be empty.';
        EmptyDashboardTileIdErr: Label 'The Power BI dashboard tile ID cannot be empty.';
        CharNotSupportedErr: Label 'The specified report page or report visual contains unsupported characters.';
        WrongKeyFormatErr: Label 'We cannot display your Power BI %1, because of a mismatch in the expected IDs (%2 IDs were provided, but we expected %3). Try again, or contact your %4 partner for guidance.', Comment = '%1, %3: two numbers, for example 1 and 3. %2: an element type, such as Dashboard or Report. %4: the product name, Business Central';

    procedure MakeReportKey(ReportId: Guid): Text[2048]
    begin
        if IsNullGuid(ReportId) then
            Error(EmptyReportIdErr);

        exit(Format(ReportId));
    end;

    procedure MakeDashboardKey(DashboardId: Guid): Text[2048]
    begin
        if IsNullGuid(DashboardId) then
            Error(EmptyDashboardIdErr);

        exit(Format(DashboardId));
    end;

    procedure MakeReportVisualKey(ReportId: Guid; PageName: Text[200]; VisualName: Text[200]): Text[2048]
    begin
        if IsNullGuid(ReportId) then
            Error(EmptyReportIdErr);

        if (PageName = '') or (VisualName = '') then
            Error(EmptyPageOrVisualErr);

        if PageName.Contains('|') or VisualName.Contains('|') then
            Error(CharNotSupportedErr);

        exit(StrSubstNo(ReportVisualKeyTok, Format(ReportId), PageName, VisualName));
    end;

    procedure MakeDashboardTileKey(DashboardId: Guid; TileId: Guid): Text[2048]
    begin
        if IsNullGuid(DashboardId) then
            Error(EmptyDashboardIdErr);

        if IsNullGuid(TileId) then
            Error(EmptyDashboardTileIdErr);

        exit(StrSubstNo(DashboardTileKeyTok, Format(DashboardId), Format(TileId)));
    end;

    procedure ParseReportKey(var ReportId: Guid)
    begin
        Rec.TestField(ElementType, Rec.ElementType::"Report");
        Evaluate(ReportId, Rec.ElementId);
    end;

    procedure ParseDashboardKey(var DashboardId: Guid)
    begin
        Rec.TestField(ElementType, Rec.ElementType::Dashboard);
        Evaluate(DashboardId, Rec.ElementId);
    end;

    procedure ParseReportVisualKey(var ReportId: Guid; var PageName: Text[200]; var VisualName: Text[200])
    var
        KeyParts: List of [Text];
    begin
        Rec.TestField(ElementType, Rec.ElementType::"Report Visual");
        KeyParts := Rec.ElementId.Split('|');

        if KeyParts.Count <> 3 then
            Error(WrongKeyFormatErr, Rec.ElementType, KeyParts.Count, 3, ProductName.Short());

        Evaluate(ReportId, KeyParts.Get(1));
        PageName := CopyStr(KeyParts.Get(2), 1, MaxStrLen(PageName));
        VisualName := CopyStr(KeyParts.Get(3), 1, MaxStrLen(VisualName));
    end;

    procedure ParseDashboardTileKey(var DashboardId: Guid; var TileId: Guid)
    var
        KeyParts: List of [Text];
    begin
        Rec.TestField(ElementType, Rec.ElementType::"Dashboard Tile");
        KeyParts := Rec.ElementId.Split('|');

        if KeyParts.Count <> 2 then
            Error(WrongKeyFormatErr, Rec.ElementType, KeyParts.Count, 2, ProductName.Short());

        Evaluate(DashboardId, KeyParts.Get(1));
        Evaluate(TileId, KeyParts.Get(2));
    end;

    internal procedure GetTelemetryDimensions() CustomDimensions: Dictionary of [Text, Text]
    var
        CurrentGlobalLanguage: Integer;
        ReportId: Guid;
        ReportPageName: Text[200];
        ReportVisualId: Text[200];
        DashboardId: Guid;
        DashboardTileId: Guid;
    begin
        CurrentGlobalLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        CustomDimensions.Add(Rec.FieldName(Context), Rec.Context);
        CustomDimensions.Add(Rec.FieldName(ElementType), Format(Rec.ElementType));

        case Rec.ElementType of
            "Power BI Element Type"::"Report":
                begin
                    Rec.ParseReportKey(ReportId);
                    CustomDimensions.Add('ReportId', ReportId);
                end;
            "Power BI Element Type"::"Report Visual":
                begin
                    Rec.ParseReportVisualKey(ReportId, ReportPageName, ReportVisualId);
                    CustomDimensions.Add('ReportId', ReportId);
                    CustomDimensions.Add('ReportPageName', ReportPageName);
                    CustomDimensions.Add('ReportVisualId', ReportVisualId);
                end;
            "Power BI Element Type"::Dashboard:
                begin
                    Rec.ParseDashboardKey(DashboardId);
                    CustomDimensions.Add('DashboardId', DashboardId);
                end;
            "Power BI Element Type"::"Dashboard Tile":
                begin
                    Rec.ParseDashboardTileKey(DashboardId, DashboardTileId);
                    CustomDimensions.Add('DashboardId', DashboardId);
                    CustomDimensions.Add('DashboardTileId', DashboardTileId);
                end;
        end;

        GlobalLanguage(CurrentGlobalLanguage);
    end;
}
