// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

enum 5397 "CDS Transformation Direction"
{
    Extensible = false;

    value(0; "ToIntegrationTable") { Caption = 'To Integration Table'; }
    value(1; "FromIntegrationTable") { Caption = 'From Integration Table'; }
}