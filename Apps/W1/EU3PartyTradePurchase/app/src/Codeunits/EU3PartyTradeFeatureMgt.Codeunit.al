#if not CLEAN23
codeunit 4881 "EU3 Party Trade Feature Mgt."
{
    Permissions = TableData "Feature Key" = rm;
    ObsoleteState = Pending;
    ObsoleteReason = 'The codeunit contains functions to help upgrade in countries where the feature existed in Base Application.';
    ObsoleteTag = '23.0';
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure IsEnabled(): Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        exit(FeatureManagementFacade.IsEnabled(FeatureKeyIdTok));
    end;

    procedure GetFeatureKeyId(): Text
    begin
        exit(FeatureKeyIdTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEnabled(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    var
        FeatureKeyIdTok: Label 'EU3PartyTradePurchase', Locked = true;
}
#endif