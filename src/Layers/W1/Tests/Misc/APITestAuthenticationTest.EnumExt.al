// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

enumextension 139492 "API Test Authentication Test" extends "API Test Authentication"
{
    value(139492; Mock)
    {
        Implementation = "API Test Auth Provider" = "Mock API Test Auth Provider";
    }
}
