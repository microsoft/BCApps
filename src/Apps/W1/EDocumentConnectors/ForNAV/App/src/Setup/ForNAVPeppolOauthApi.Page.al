// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

page 6411 "ForNAV Peppol Oauth API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    EntityName = 'peppolOauthForNav';
    EntitySetName = 'peppolOauthsForNav';
    APIGroup = 'peppol';
    APIVersion = 'v1.0';
    SourceTable = "ForNAV Peppol Setup";
    SourceTableTemporary = true;
    DelayedInsert = true;
    Caption = 'ForNavPeppolOauth';
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(primaryKey; Rec.PK)
                {
                    ApplicationArea = All;
                }
                field(clientId; Rec."Client Id")
                {
                    ApplicationArea = All;
                }
                field(tenantId; tenantId)
                {
                    ApplicationArea = All;
                }
                field(clientSecret; ClientSecret)
                {
                    ApplicationArea = All;
                }
                field(expires; SecretValidTo)
                {
                    ApplicationArea = All;
                }
                field(scope; Scope)
                {
                    ApplicationArea = All;
                }
                field(endpoint; Endpoint)
                {
                    ApplicationArea = All;
                }
                field(hash; Hash)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    var
        [NonDebuggable]
        ClientSecret: Text;
        Scope: Text;
        TenantId: Text;
        Hash: Text;
        SecretValidTo: DateTime;
        Endpoint: Text[20];

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Process();
    end;

    [NonDebuggable]
    local procedure Process()
    var
        Setup: Record "ForNAV Peppol Setup";
        PeppolCrypto: Codeunit "ForNAV Peppol Crypto";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        Setup.FindFirst();
        PeppolCrypto.TestHash(Hash, Rec."Client Id", ClientSecret);
        Setup.Validate("Client Id", Rec."Client Id");
        PeppolOauth.ValidateSecret(ClientSecret);
        PeppolOauth.ValidateSecretValidTo(SecretValidTo);
        PeppolOauth.ValidateForNAVTenantID(TenantId);
        PeppolOauth.ValidateScope(Scope);
        PeppolOauth.ValidateEndpoint(Endpoint, false);
        Setup.Modify(true);
    end;
}