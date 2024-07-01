// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Azure.Storage.Files;

using System.Azure.Storage;

/// <summary>
/// Provides common authorization functionality for using Azure storage accounts in tests for Azure Storage Services.
/// </summary>
codeunit 132518 "AFS Get Test Storage Auth."
{
    Access = Internal;

    var
        AFSInitTestStorage: Codeunit "AFS Init. Test Storage";

    procedure GetDefaultAccountSAS(): Interface "Storage Service Authorization"
    begin
        exit(GetDefaultAccountSAS(AFSInitTestStorage.GetAccessKey()));
    end;

    procedure GetDefaultAccountSAS(AccountKey: Text): Interface "Storage Service Authorization"
    var
        StorageServiceAuthorization: Codeunit "Storage Service Authorization";
    begin
        exit(GetDefaultAccountSAS(AccountKey, StorageServiceAuthorization.GetDefaultAPIVersion()));
    end;

    procedure GetSharedKeyAuthorization(AccountKey: Text): Interface "Storage Service Authorization"
    var
        StorageServiceAuthorization: Codeunit "Storage Service Authorization";
        SecretAccountKey: SecretText;
    begin
        SecretAccountKey := AccountKey;
        exit(StorageServiceAuthorization.CreateSharedKey(SecretAccountKey));
    end;

    procedure GetDefaultAccountSAS(AccountKey: Text; APIVersion: Enum "Storage Service API Version"): Interface "Storage Service Authorization"
    var
        StorageServiceAuthorization: Codeunit "Storage Service Authorization";
        SignedServices: List of [Enum "SAS Service Type"];
        SignedPermissions: List of [Enum "SAS Permission"];
        SignedResources: List of [Enum "SAS Resource Type"];
        SignedExpiry: DateTime;
        Second: Integer;
        SecretAccountKey: SecretText;
    begin
        SecretAccountKey := AccountKey;
        Second := 1000;
        SignedExpiry := CurrentDateTime() + (60 * Second);

        SignedServices.Add(Enum::"SAS Service Type"::File);
        SignedPermissions.AddRange(Enum::"SAS Permission"::Create, Enum::"SAS Permission"::Write,
            Enum::"SAS Permission"::Delete, Enum::"SAS Permission"::List, Enum::"SAS Permission"::Read
        );
        SignedResources.AddRange(Enum::"SAS Resource Type"::Object, Enum::"SAS Resource Type"::Container);

        exit(StorageServiceAuthorization.CreateAccountSAS(
            SecretAccountKey,
            APIVersion,
            SignedServices,
            SignedResources,
            SignedPermissions,
            SignedExpiry
        ));
    end;
}