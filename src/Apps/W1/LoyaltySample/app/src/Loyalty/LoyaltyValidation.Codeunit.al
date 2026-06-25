namespace Microsoft.Sample.Loyalty;

codeunit 50107 "Loyalty Validation"
{
    procedure ValidateRedemption(LoyaltyMember: Record "Loyalty Member"; PointsToRedeem: Integer)
    begin
        if PointsToRedeem > LoyaltyMember."Points Balance" then
            Error('You cannot redeem more than %1 points.', LoyaltyMember."Points Balance");
    end;

    procedure ValidateMemberExists(MemberNo: Code[20])
    var
        LoyaltyMember: Record "Loyalty Member";
    begin
        if not LoyaltyMember.Get(MemberNo) then
            Error('Member %1 was not found. Open the Loyalty Members page to create it.', MemberNo);
    end;

    procedure EnsureBucketInitialized(BucketId: Integer; IsInitialized: Boolean)
    begin
        if not IsInitialized then
            Error('Unexpected state: loyalty ledger bucket %1 is not initialized.', BucketId);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure ValidateAllMembers()
    var
        LoyaltyMember: Record "Loyalty Member";
    begin
        if LoyaltyMember.FindSet() then
            repeat
                if LoyaltyMember."Email Address" = '' then
                    Error('Member %1 has no e-mail address.', LoyaltyMember."No.");
            until LoyaltyMember.Next() = 0;
    end;

    procedure ValidateBalances()
    var
        LoyaltyMember: Record "Loyalty Member";
        ErrorText: Text;
    begin
        if LoyaltyMember.FindSet() then
            repeat
                if LoyaltyMember."Points Balance" < 0 then
                    ErrorText += StrSubstNo('Member %1 has a negative balance.\n', LoyaltyMember."No.");
            until LoyaltyMember.Next() = 0;
        if ErrorText <> '' then
            Error(ErrorText);
    end;
}
