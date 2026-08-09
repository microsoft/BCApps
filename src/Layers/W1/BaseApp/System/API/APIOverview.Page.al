namespace Microsoft.API;

using System.Reflection;

page 812 "API Overview"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'api,integration,endpoint,publisher';
    SourceTable = "API Overview Buffer";
    SourceTableTemporary = true;
    Caption = 'API Overview';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutTitle = 'Explore APIs in your environment';
    AboutText = 'This page lists all APIs available in this environment. Filter by publisher, group, or version, open an endpoint URL, and validate your integration setup.';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Description; Rec.Description)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the API page or query.';
                }
                field("Object Type"; Rec."Object Type")
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies whether the API is implemented as an API page (supports read and write operations) or as an API query (read-only set of data).';
                }
                field("Object ID"; Rec."Object ID")
                {
                    Caption = 'ID';
                    ToolTip = 'Specifies the object ID of the underlying API page or query. Use this when troubleshooting integrations together with a developer.';
                }
                field("API Publisher"; Rec."API Publisher")
                {
                    Caption = 'API Publisher';
                    ToolTip = 'Specifies the publisher segment of the API URL. The publisher identifies who owns the API and is part of the route used by external systems.';
                }
                field("API Group"; Rec."API Group")
                {
                    Caption = 'API Group';
                    ToolTip = 'Specifies the group segment of the API URL. Use the API group to scope integrations to a related set of endpoints.';
                }
                field("Entity Name"; Rec."Entity Name")
                {
                    Caption = 'Entity';
                    ToolTip = 'Specifies the entity that the API exposes. The entity name appears in the API URL and helps identify the originating solution.';
                }
                field("API Version"; Rec."API Version")
                {
                    Caption = 'API Version';
                    ToolTip = 'Specifies the version segment of the API URL. Choosing the right version ensures compatibility when integrating with external systems.';
                }
                field("API URL"; GetApiUrl(Rec))
                {
                    Caption = 'API URL';
                    Editable = false;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the full URL of the API endpoint in this environment. Choose the link to open the endpoint, for example to inspect its metadata or test a request.';
                }
            }
        }
    }

    views
    {
        view("API Pages")
        {
            Caption = 'API Pages';
            Filters = where("Object Type" = const(Page));
        }
        view("API Queries")
        {
            Caption = 'API Queries';
            Filters = where("Object Type" = const(Query));
        }
        view(APIv2)
        {
            Caption = 'API v2.0';
            Filters = where("API Version" = const('v2.0'));
        }
        view(MicrosoftAPIs)
        {
            Caption = 'Microsoft APIs';
            Filters = where("API Publisher" = const('microsoft'));
        }
        view(CustomAPIs)
        {
            Caption = 'Custom APIs';
            Filters = where("API Publisher" = filter('<>''''&<>microsoft'));
        }
    }

    trigger OnOpenPage()
    begin
        LoadAPIs();
    end;

    local procedure LoadAPIs()
    var
        TempAPILine: Record "API Overview Buffer" temporary;
        PageMetadata: Record "Page Metadata";
        QueryMetadata: Record "Query Metadata";
        LineNo: Integer;
        EntryNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        if PageMetadata.FindSet() then
            repeat
                LineNo += 1;
                TempAPILine.Init();
                TempAPILine."Entry No." := LineNo;
                TempAPILine."Object Type" := TempAPILine."Object Type"::Page;
                TempAPILine."Object ID" := PageMetadata.ID;
                TempAPILine.Description := PageMetadata.Name;
                TempAPILine."Entity Name" := PageMetadata.EntityName;
                TempAPILine."API Publisher" := PageMetadata.APIPublisher;
                TempAPILine."API Group" := PageMetadata.APIGroup;
                TempAPILine."API Version" := PageMetadata.APIVersion;
                TempAPILine.Insert();
            until PageMetadata.Next() = 0;

        QueryMetadata.SetFilter(EntityName, '<>%1', '');
        if QueryMetadata.FindSet() then
            repeat
                LineNo += 1;
                TempAPILine.Init();
                TempAPILine."Entry No." := LineNo;
                TempAPILine."Object Type" := TempAPILine."Object Type"::Query;
                TempAPILine."Object ID" := QueryMetadata.ID;
                TempAPILine.Description := QueryMetadata.Name;
                TempAPILine."Entity Name" := QueryMetadata.EntityName;
                TempAPILine."API Publisher" := QueryMetadata.APIPublisher;
                TempAPILine."API Group" := QueryMetadata.APIGroup;
                TempAPILine."API Version" := QueryMetadata.APIVersion;
                TempAPILine.Insert();
            until QueryMetadata.Next() = 0;

        TempAPILine.SetCurrentKey("API Publisher", "API Group", Description);
        if TempAPILine.FindSet() then
            repeat
                EntryNo += 1;
                Rec := TempAPILine;
                Rec."Entry No." := EntryNo;
                Rec.Insert();
            until TempAPILine.Next() = 0;

        if Rec.FindFirst() then;
    end;

    local procedure GetApiUrl(APIBuffer: Record "API Overview Buffer"): Text
    begin
        case APIBuffer."Object Type" of
            APIBuffer."Object Type"::Page:
                exit(GetUrl(ClientType::Api, CompanyName(), ObjectType::Page, APIBuffer."Object ID"));
            APIBuffer."Object Type"::Query:
                exit(GetUrl(ClientType::Api, CompanyName(), ObjectType::Query, APIBuffer."Object ID"));
        end;
    end;
}
