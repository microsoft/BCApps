// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Token Dev Tools (ID 30440).
/// TEMPORARY manual-testing aid for the expiring offline access token migration (slice 637954).
/// It exposes the internal "Shpfy Registered Store New" token metadata and provides actions to force
/// token states (near-expiry, expired refresh token, legacy non-expiring) and to invoke the on-demand
/// orchestrator and the scheduled backstop. DELETE THIS PAGE BEFORE SHIPPING.
/// </summary>
page 30440 "Shpfy Token Dev Tools"
{
    Caption = 'Shopify Token Dev Tools';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Shpfy Registered Store New";
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Stores)
            {
                field(Store; Rec.Store)
                {
                    Caption = 'Store';
                    Editable = false;
                    ToolTip = 'Specifies the Shopify store URL.';
                }
                field(HasAccessToken; HasAccessTokenValue)
                {
                    Caption = 'Has Access Token';
                    Editable = false;
                    ToolTip = 'Specifies whether an access token is stored for this store.';
                }
                field(HasRefreshToken; HasRefreshTokenValue)
                {
                    Caption = 'Has Refresh Token';
                    Editable = false;
                    ToolTip = 'Specifies whether a refresh token is stored (i.e. the store uses an expiring token).';
                }
                field("Token Expires At"; Rec."Token Expires At")
                {
                    ToolTip = 'Specifies when the access token expires. Zero means a non-expiring (legacy) token.';
                }
                field("Refresh Token Expires At"; Rec."Refresh Token Expires At")
                {
                    ToolTip = 'Specifies when the refresh token expires. Zero means unknown/non-expiring.';
                }
                field("Requested Scope"; Rec."Requested Scope")
                {
                    Editable = false;
                    ToolTip = 'Specifies the scopes requested for this store.';
                }
                field("Actual Scope"; Rec."Actual Scope")
                {
                    Editable = false;
                    ToolTip = 'Specifies the scopes granted for this store.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetAccessTokenExpired)
            {
                Caption = 'Force Access Token Expired';
                ApplicationArea = All;
                Image = Timesheet;
                ToolTip = 'Sets the access token expiry to now so the next API call refreshes it (path C4).';

                trigger OnAction()
                begin
                    Rec."Token Expires At" := CurrentDateTime();
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(SetAccessTokenNearExpiry)
            {
                Caption = 'Force Access Token Near Expiry';
                ApplicationArea = All;
                Image = Timesheet;
                ToolTip = 'Sets the access token expiry to one minute from now, inside the 5-minute refresh buffer (path C4).';

                trigger OnAction()
                begin
                    Rec."Token Expires At" := OffsetNow(60000);
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(SetRefreshTokenExpired)
            {
                Caption = 'Force Refresh Token Expired';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Sets both expiries to the past so a refresh is attempted but short-circuits to the reconnect error (paths D7, H18).';

                trigger OnAction()
                begin
                    Rec."Token Expires At" := OffsetNow(-60000);
                    Rec."Refresh Token Expires At" := OffsetNow(-86400000);
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(EnsureValidToken)
            {
                Caption = 'Run Ensure Valid Access Token';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Invokes the on-demand orchestrator for the selected store (migrate-if-legacy / refresh-if-near-expiry).';

                trigger OnAction()
                var
                    AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
                    BeforeExpiresAt: DateTime;
                    BeforeHadRefreshToken: Boolean;
                    ChangedMsg: Label 'Done. Token Expires At: %1. Refresh Token Expires At: %2. Has Refresh Token: %3.', Comment = '%1 = token expiry, %2 = refresh token expiry, %3 = has refresh token';
                    NoChangeMsg: Label 'No change. The Shopify token exchange/refresh did not produce an expiring token. Check telemetry 0000QK1 (migrated) / 0000QK2 (migration failed) / 0000QK4 (refreshed). Verify: (1) the store has a real, valid access token, (2) the Shopify app is configured to issue EXPIRING tokens (otherwise expiring=1 is ignored and no expiry is returned), and (3) the extension is allowed to make HTTP requests.';
                begin
                    BeforeExpiresAt := Rec."Token Expires At";
                    BeforeHadRefreshToken := Rec.HasRefreshToken();

                    AuthenticationMgt.EnsureValidAccessToken(Rec.Store);
                    Commit();
                    CurrPage.Update(false);

                    if Rec.Get(Rec.Store) then;
                    if (Rec."Token Expires At" <> BeforeExpiresAt) or (Rec.HasRefreshToken() <> BeforeHadRefreshToken) then
                        Message(ChangedMsg, Rec."Token Expires At", Rec."Refresh Token Expires At", Rec.HasRefreshToken())
                    else
                        Message(NoChangeMsg);
                end;
            }
            action(RunBackstopJob)
            {
                Caption = 'Run Backstop Job (All Shops)';
                ApplicationArea = All;
                Image = Job;
                ToolTip = 'Runs the scheduled token refresh backstop across all enabled shops (paths G15-G17).';

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"Shpfy Token Refresh");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        HasAccessTokenValue: Boolean;
        HasRefreshTokenValue: Boolean;

    trigger OnAfterGetRecord()
    begin
        HasAccessTokenValue := not Rec.GetAccessToken().IsEmpty();
        HasRefreshTokenValue := Rec.HasRefreshToken();
    end;

    local procedure OffsetNow(Milliseconds: BigInteger): DateTime
    var
        Offset: Duration;
    begin
        Offset := Milliseconds;
        exit(CurrentDateTime() + Offset);
    end;
}
