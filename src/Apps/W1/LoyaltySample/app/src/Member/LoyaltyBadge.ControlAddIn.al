namespace Microsoft.Sample.Loyalty;

controladdin "Loyalty Badge"
{
    Scripts = 'src/Member/LoyaltyBadge.js';
    StartupScript = 'src/Member/LoyaltyBadge.js';

    RequestedHeight = 80;
    RequestedWidth = 240;

    procedure RenderBadge(MemberName: Text; Email: Text; Tier: Text);
}
