namespace Microsoft.API.Webhooks;

using Microsoft.Utilities;
using System.Integration;

page 5462 "API Routes"
{
    APIGroup = 'runtime';
    APIPublisher = 'microsoft';
    DelayedInsert = true;
    Editable = false;
    EntityName = 'apiRoutes';
    EntitySetName = 'apiRoutes';
    Extensible = false;
    ODataKeyFields = "Value Long";
    PageType = API;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(route; Rec."Value Long")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        ApiWebhookEntity: Record "Api Webhook Entity";
        Route: Text;
        View: Text;
        I: Integer;
    begin
        if Initialized then
            exit(true);

        View := Rec.GetView();
        Rec.Reset();

        if not ApiWebhookEntity.FindSet() then
            exit(false);

        repeat
            Route := CopyStr(GetRoute(ApiWebhookEntity), 1, MaxStrLen(Rec."Value Long"));
            Rec.SetRange("Value Long", Route);
            if Rec.IsEmpty() then begin
                I += 1;
                Rec.ID := I;
                Rec."Value Long" := Route;
                Rec.Insert();
            end;
        until ApiWebhookEntity.Next() = 0;

        Rec.SetView(View);
        Rec.FindFirst();
        Initialized := true;
        exit(true);
    end;

    var
        Initialized: Boolean;

    local procedure GetRoute(var ApiWebhookEntity: Record "Api Webhook Entity"): Text
    begin
        if (ApiWebhookEntity.Publisher <> '') and (ApiWebhookEntity.Group <> '') then
            exit(StrSubstNo('%1/%2/%3',
                ApiWebhookEntity.Publisher, ApiWebhookEntity.Group, ApiWebhookEntity.Version));
        exit(ApiWebhookEntity.Version);
    end;
}
