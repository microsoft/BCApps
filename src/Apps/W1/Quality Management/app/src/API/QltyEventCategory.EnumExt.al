// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.API;

using System.Integration;

/// <summary>
/// Used for external business events, such as power automate integration.
/// </summary>
enumextension 20403 QltyEventCategory extends EventCategory
{
    value(20400; QltyEventCategory)
    {
        Caption = 'Quality Management';
    }
}
