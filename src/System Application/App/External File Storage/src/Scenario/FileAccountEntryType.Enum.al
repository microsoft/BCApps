// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

enum 9453 "File Account Entry Type"
{
    Access = Internal;
    Extensible = false;

    value(0; Account) { }
    value(1; Scenario) { }
}