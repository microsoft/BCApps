#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

using System.Environment.Configuration;

enumextension 12106 "Feature - Business Activity IT" extends "Feature To Update"
{
    value(12106; BusinessActivityCodeIT)
    {
        Implementation = "Feature Data Update" = "Business Activity Feature IT";
        ObsoleteState = Pending;
        ObsoleteReason = 'Business Activity Code will always be enabled in version 33.0.';
        ObsoleteTag = '30.0';
    }
}
#endif
