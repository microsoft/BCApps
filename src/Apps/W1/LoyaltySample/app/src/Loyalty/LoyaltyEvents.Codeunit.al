namespace Microsoft.Sample.Loyalty;

codeunit 50108 "Loyalty Events"
{
    procedure RecalculateMember(var LoyaltyMember: Record "Loyalty Member")
    var
        IsHandled: Boolean;
    begin
        OnBeforeRecalculate(LoyaltyMember, IsHandled);
        DoRecalculate(LoyaltyMember);
    end;

    procedure CalculateTotal(var LoyaltyMember: Record "Loyalty Member")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotal(LoyaltyMember, IsHandled);
        if IsHandled then
            exit;
        DoRecalculate(LoyaltyMember);
        OnAfterCalculateTotal(LoyaltyMember);
    end;

    procedure ProcessTiers(var LoyaltyMember: Record "Loyalty Member")
    var
        IsHandled: Boolean;
    begin
        OnBeforeValidateTier(LoyaltyMember, IsHandled);
        if IsHandled then
            exit;

        OnBeforeApplyTier(LoyaltyMember, IsHandled);
        if IsHandled then
            exit;
    end;

    procedure PostPointConsumption(var LoyaltyMember: Record "Loyalty Member")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostPoints(LoyaltyMember, IsHandled);
        if IsHandled then
            exit;
        CreatePointLedgerEntry(LoyaltyMember);
        LoyaltyMember."Points Balance" := 0;
        LoyaltyMember.Modify();
        OnAfterPostPoints(LoyaltyMember);
    end;

    procedure NotifyMembers(var LoyaltyMember: Record "Loyalty Member")
    begin
        if LoyaltyMember.FindSet() then
            repeat
                OnMemberNotified(LoyaltyMember);
            until LoyaltyMember.Next() = 0;
    end;

    local procedure DoRecalculate(var LoyaltyMember: Record "Loyalty Member")
    begin
    end;

    local procedure CreatePointLedgerEntry(var LoyaltyMember: Record "Loyalty Member")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculate(var LoyaltyMember: Record "Loyalty Member"; var IsHandled: Boolean)
    begin
        LoyaltyMember."Points Balance" := 0;
        if LoyaltyMember."Loyalty Tier" = LoyaltyMember."Loyalty Tier"::Platinum then
            LoyaltyMember."Points Balance" := 100;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotal(var LoyaltyMember: Record "Loyalty Member"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateTotal(var LoyaltyMember: Record "Loyalty Member")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTier(var LoyaltyMember: Record "Loyalty Member"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTier(var LoyaltyMember: Record "Loyalty Member"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPoints(var LoyaltyMember: Record "Loyalty Member"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPoints(var LoyaltyMember: Record "Loyalty Member")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMemberNotified(var LoyaltyMember: Record "Loyalty Member")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure MemberAuditEvent(RecRef: RecordRef; DocNo: Code[20]; Amt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildBuffer(var PointBuffer: Record "Loyalty Point Entry" temporary)
    begin
    end;
}
