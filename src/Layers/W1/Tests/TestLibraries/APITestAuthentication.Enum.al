// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

/// <summary>
/// Specifies the authentication provider used for API test requests.
/// </summary>
enum 131023 "API Test Authentication" implements "API Test Auth Provider"
{
    Extensible = true;
    DefaultImplementation = "API Test Auth Provider" = "No API Test Auth Provider";

    value(0; None)
    {
        Caption = 'None';
        Implementation = "API Test Auth Provider" = "No API Test Auth Provider";
    }
    value(1; "Microsoft Test Environment")
    {
        Caption = 'Microsoft Test Environment';
        Implementation = "API Test Auth Provider" = "Microsoft Test Auth Provider";
    }
}
