// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

enum 7789 "AOAI Policy"
{
    Extensible = false;
    Access = Internal;

    /// <summary>
    /// Low harms severity with XPIA detection enabled
    /// </summary>
    value(1; "ConservativeWithXPIA")
    {
    }

    /// <summary>
    /// Low harms severity with XPIA detection disabled
    /// </summary>
    value(2; "Conservative")
    {
    }

    /// <summary>
    /// Medium harms severity with XPIA detection enabled
    /// </summary>
    value(3; "MediumWithXPIA")
    {
    }

    /// <summary>
    /// Medium harms severity with XPIA detection disabled
    /// </summary>
    value(4; "Default")
    {
    }
}