// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Identity;

/// <summary>
/// User plan experience. 
/// </summary>
enum 9005 "User Plan Experience"
{
    Extensible = false;

    /// <summary>
    /// Essentials plan.
    /// </summary>
    value(0; Essentials)
    {
        Caption = 'Essentials';
    }

    /// <summary>
    /// Premium plan.
    /// </summary>
    value(2; Premium)
    {
        Caption = 'Premium';
    }

    /// <summary>
    /// Basic plan.
    /// </summary>
    value(3; Basic)
    {
        Caption = 'Basic';
    }

    /// <summary>
    /// Other license type.
    /// </summary>
    value(10; Other)
    {
        Caption = 'Other';
    }
}