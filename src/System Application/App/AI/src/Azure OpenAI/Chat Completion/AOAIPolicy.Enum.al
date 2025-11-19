// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

enum 7787 "AOAI Policy"
{
    Extensible = false;
    Access = Internal;

    /// <summary>
    /// Requests containing harms with a low severity are blocked and XPIA detection is enabled.
    /// </summary>
    value(1; "ConservativeWithXPIA")
    {
    }

    /// <summary>
    /// Requests containing harms with a low severity are blocked.
    /// </summary>
    value(2; "ConservativeWithoutXPIA")
    {
    }

    /// <summary>
    /// Requests containing harms with a medium severity are blocked and XPIA detection is enabled.
    /// </summary>
    value(3; "MediumWithXPIA")
    {
    }

    /// <summary>
    /// Requests containing harms with a medium severity are blocked.
    /// This is not the default policy that we recommend but rather this is the Default AOAI policy (Policy ID : 0 ) in CAPI
    /// </summary>
    value(4; "Default")
    {
    }

}